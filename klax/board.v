module main

import rand

pub const klax_lanes = 5
pub const bin_size = 5
pub const max_paddle_tiles = 5
pub const max_tile_types = 5 // 1: Red, 2: Blue, 3: Green, 4: Yellow, 5: Magenta
pub const wild_tile_type = 6 // Wild / Blinking tile

pub enum GameState {
	playing
	clearing
	wave_cleared
	game_over
}

pub enum WaveGoalType {
	klaxes
	diagonals
	points
	tiles_cleared
	horizontals
}

pub struct RampTile {
pub mut:
	lane     int // 0..4
	progress f64 // 0.0 (top of ramp) to 1.0 (reaches paddle)
	tile_type int
	speed    f64 // units per second
}

pub struct KlaxMatch {
pub:
	positions []Pos
	is_diagonal bool
	is_horizontal bool
	count int
}

pub struct Pos {
pub:
	r int
	c int
}

pub struct KlaxGame {
pub mut:
	bin            [5][5]int // 0 is empty. Row 0 is top, Row 4 is bottom
	paddle_lane    int = 2   // 0..4
	paddle_tiles   []int     // Top tile is at index len - 1
	ramp_tiles     []RampTile
	state          GameState = .playing
	score          int
	high_score     int
	wave           int = 1
	drops_left     int = 3
	max_drops      int = 3
	goal_type      WaveGoalType = .klaxes
	goal_target    int = 3
	goal_progress  int
	spawn_timer    f64
	clear_timer    f64
	clearing_pos   []Pos
	combo_count    int
	tiles_cleared_total int
}

pub fn new_klax_game() KlaxGame {
	mut g := KlaxGame{}
	g.init_wave(1)
	return g
}

pub fn (mut g KlaxGame) init_wave(wave_num int) {
	g.wave = wave_num
	g.paddle_tiles.clear()
	g.ramp_tiles.clear()
	g.bin = [5][5]int{}
	g.state = .playing
	g.combo_count = 0
	g.goal_progress = 0
	g.drops_left = 3
	g.spawn_timer = 0.5

	match wave_num % 5 {
		1 {
			g.goal_type = .klaxes
			g.goal_target = 3 + wave_num / 5
		}
		2 {
			g.goal_type = .diagonals
			g.goal_target = 3 + wave_num / 5
		}
		3 {
			g.goal_type = .points
			g.goal_target = 10000 * wave_num
		}
		4 {
			g.goal_type = .tiles_cleared
			g.goal_target = 15 + wave_num * 2
		}
		0 {
			g.goal_type = .horizontals
			g.goal_target = 3 + wave_num / 5
		}
		else {
			g.goal_type = .klaxes
			g.goal_target = 5
		}
	}
}

pub fn (mut g KlaxGame) spawn_tile() {
	lane := rand.int_in_range(0, klax_lanes) or { 2 }
	// 8% chance of wild tile
	mut t_type := rand.int_in_range(1, max_tile_types + 1) or { 1 }
	if rand.int_in_range(0, 12) or { 0 } == 0 {
		t_type = wild_tile_type
	}

	speed := 0.22 + f64(g.wave) * 0.02

	g.ramp_tiles << RampTile{
		lane:      lane
		progress:  0.0
		tile_type: t_type
		speed:     speed
	}
}

pub fn (mut g KlaxGame) move_paddle(dir int) {
	new_lane := g.paddle_lane + dir
	if new_lane >= 0 && new_lane < klax_lanes {
		g.paddle_lane = new_lane
	}
}

// Flip top tile from paddle into 5x5 Bin
pub fn (mut g KlaxGame) flip_tile() bool {
	if g.paddle_tiles.len == 0 || g.state != .playing {
		return false
	}
	tile := g.paddle_tiles.pop()
	c := g.paddle_lane

	// Find bottom-most empty slot in column c
	mut target_r := -1
	for r := bin_size - 1; r >= 0; r-- {
		if g.bin[r][c] == 0 {
			target_r = r
			break
		}
	}

	if target_r == -1 {
		// Bin column is full! Tile drops off and loses a drop
		g.drops_left--
		if g.drops_left <= 0 {
			g.state = .game_over
		}
		return false
	}

	g.bin[target_r][c] = tile
	g.check_bin_matches()
	return true
}

// Push top tile from paddle back onto conveyor ramp
pub fn (mut g KlaxGame) push_tile_up() bool {
	if g.paddle_tiles.len == 0 || g.state != .playing {
		return false
	}
	tile := g.paddle_tiles.pop()
	g.ramp_tiles << RampTile{
		lane:      g.paddle_lane
		progress:  0.85
		tile_type: tile
		speed:     -0.6 // Moves backwards up the ramp
	}
	return true
}

fn tiles_match(t1 int, t2 int) bool {
	if t1 == 0 || t2 == 0 {
		return false
	}
	if t1 == wild_tile_type || t2 == wild_tile_type {
		return true
	}
	return t1 == t2
}

fn get_dominant_type(t1 int, t2 int, t3 int) int {
	if t1 != wild_tile_type { return t1 }
	if t2 != wild_tile_type { return t2 }
	if t3 != wild_tile_type { return t3 }
	return 1
}

// Find horizontal, vertical, and diagonal Klaxes in the 5x5 bin
pub fn (mut g KlaxGame) check_bin_matches() bool {
	mut matched := [5][5]bool{}
	mut found := false
	mut klax_matches := []KlaxMatch{}

	// Horizontal 3+
	for r in 0 .. bin_size {
		for c in 0 .. bin_size - 2 {
			t1 := g.bin[r][c]
			t2 := g.bin[r][c + 1]
			t3 := g.bin[r][c + 2]
			if t1 != 0 && t2 != 0 && t3 != 0 {
				dom := get_dominant_type(t1, t2, t3)
				if tiles_match(t1, dom) && tiles_match(t2, dom) && tiles_match(t3, dom) {
					matched[r][c] = true
					matched[r][c + 1] = true
					matched[r][c + 2] = true
					found = true
					mut pos := [Pos{r: r, c: c}, Pos{r: r, c: c + 1}, Pos{r: r, c: c + 2}]
					mut k := c + 3
					for k < bin_size && tiles_match(g.bin[r][k], dom) {
						matched[r][k] = true
						pos << Pos{r: r, c: k}
						k++
					}
					klax_matches << KlaxMatch{positions: pos, is_horizontal: true, count: pos.len}
				}
			}
		}
	}

	// Vertical 3+
	for c in 0 .. bin_size {
		for r in 0 .. bin_size - 2 {
			t1 := g.bin[r][c]
			t2 := g.bin[r + 1][c]
			t3 := g.bin[r + 2][c]
			if t1 != 0 && t2 != 0 && t3 != 0 {
				dom := get_dominant_type(t1, t2, t3)
				if tiles_match(t1, dom) && tiles_match(t2, dom) && tiles_match(t3, dom) {
					matched[r][c] = true
					matched[r + 1][c] = true
					matched[r + 2][c] = true
					found = true
					mut pos := [Pos{r: r, c: c}, Pos{r: r + 1, c: c}, Pos{r: r + 2, c: c}]
					mut k := r + 3
					for k < bin_size && tiles_match(g.bin[k][c], dom) {
						matched[k][c] = true
						pos << Pos{r: k, c: c}
						k++
					}
					klax_matches << KlaxMatch{positions: pos, count: pos.len}
				}
			}
		}
	}

	// Diagonal down-right 3+
	for r in 0 .. bin_size - 2 {
		for c in 0 .. bin_size - 2 {
			t1 := g.bin[r][c]
			t2 := g.bin[r + 1][c + 1]
			t3 := g.bin[r + 2][c + 2]
			if t1 != 0 && t2 != 0 && t3 != 0 {
				dom := get_dominant_type(t1, t2, t3)
				if tiles_match(t1, dom) && tiles_match(t2, dom) && tiles_match(t3, dom) {
					matched[r][c] = true
					matched[r + 1][c + 1] = true
					matched[r + 2][c + 2] = true
					found = true
					mut pos := [Pos{r: r, c: c}, Pos{r: r + 1, c: c + 1}, Pos{r: r + 2, c: c + 2}]
					mut kr := r + 3
					mut kc := c + 3
					for kr < bin_size && kc < bin_size && tiles_match(g.bin[kr][kc], dom) {
						matched[kr][kc] = true
						pos << Pos{r: kr, c: kc}
						kr++
						kc++
					}
					klax_matches << KlaxMatch{positions: pos, is_diagonal: true, count: pos.len}
				}
			}
		}
	}

	// Diagonal down-left 3+
	for r in 0 .. bin_size - 2 {
		for c in 2 .. bin_size {
			t1 := g.bin[r][c]
			t2 := g.bin[r + 1][c - 1]
			t3 := g.bin[r + 2][c - 2]
			if t1 != 0 && t2 != 0 && t3 != 0 {
				dom := get_dominant_type(t1, t2, t3)
				if tiles_match(t1, dom) && tiles_match(t2, dom) && tiles_match(t3, dom) {
					matched[r][c] = true
					matched[r + 1][c - 1] = true
					matched[r + 2][c - 2] = true
					found = true
					mut pos := [Pos{r: r, c: c}, Pos{r: r + 1, c: c - 1}, Pos{r: r + 2, c: c - 2}]
					mut kr := r + 3
					mut kc := c - 3
					for kr < bin_size && kc >= 0 && tiles_match(g.bin[kr][kc], dom) {
						matched[kr][kc] = true
						pos << Pos{r: kr, c: kc}
						kr++
						kc--
					}
					klax_matches << KlaxMatch{positions: pos, is_diagonal: true, count: pos.len}
				}
			}
		}
	}

	if found {
		mut pos_list := []Pos{}
		for r in 0 .. bin_size {
			for c in 0 .. bin_size {
				if matched[r][c] {
					pos_list << Pos{r: r, c: c}
				}
			}
		}
		g.clearing_pos = pos_list
		g.combo_count++

		// Scoring & goals
		for km in klax_matches {
			base_pts := if km.is_diagonal { 5000 } else if km.is_horizontal { 1000 } else { 50 }
			pts := base_pts * g.combo_count * (km.count - 2)
			g.score += pts
			if g.score > g.high_score {
				g.high_score = g.score
			}

			// Goal tracking
			match g.goal_type {
				.klaxes { g.goal_progress++ }
				.diagonals { if km.is_diagonal { g.goal_progress++ } }
				.horizontals { if km.is_horizontal { g.goal_progress++ } }
				.points { g.goal_progress = g.score }
				.tiles_cleared {}
			}
		}

		g.state = .clearing
		g.clear_timer = 0.35
		return true
	}
	return false
}

// Clear matched positions from bin and apply gravity
pub fn (mut g KlaxGame) apply_clearing() {
	count := g.clearing_pos.len
	for pos in g.clearing_pos {
		g.bin[pos.r][pos.c] = 0
	}
	g.clearing_pos.clear()
	g.tiles_cleared_total += count
	if g.goal_type == .tiles_cleared {
		g.goal_progress += count
	}

	// Gravity settle in bin
	for c in 0 .. bin_size {
		mut write_r := bin_size - 1
		for r := bin_size - 1; r >= 0; r-- {
			if g.bin[r][c] != 0 {
				if r != write_r {
					g.bin[write_r][c] = g.bin[r][c]
					g.bin[r][c] = 0
				}
				write_r--
			}
		}
	}

	// Check if wave goal reached
	if g.goal_progress >= g.goal_target {
		g.state = .wave_cleared
		return
	}

	// Check if settling triggered cascade Klaxes
	if !g.check_bin_matches() {
		g.combo_count = 0
		g.state = .playing
	}
}

pub fn (mut g KlaxGame) update(dt f64) {
	match g.state {
		.playing {
			// Spawn timer
			g.spawn_timer -= dt
			if g.spawn_timer <= 0 {
				g.spawn_tile()
				g.spawn_timer = 1.8 - f64(g.wave) * 0.08
				if g.spawn_timer < 0.6 {
					g.spawn_timer = 0.6
				}
			}

			// Update ramp tiles
			mut active_tiles := []RampTile{}
			for mut tile in g.ramp_tiles {
				tile.progress += tile.speed * dt

				// Check if pushed back off top of ramp
				if tile.progress < 0.0 {
					continue
				}

				// Check if reached paddle
				if tile.progress >= 1.0 {
					if tile.lane == g.paddle_lane && g.paddle_tiles.len < max_paddle_tiles {
						// Caught by paddle!
						g.paddle_tiles << tile.tile_type
					} else {
						// Missed! Tile drops off conveyor
						g.drops_left--
						if g.drops_left <= 0 {
							g.state = .game_over
							return
						}
					}
				} else {
					active_tiles << tile
				}
			}
			g.ramp_tiles = active_tiles
		}
		.clearing {
			g.clear_timer -= dt
			if g.clear_timer <= 0 {
				g.apply_clearing()
			}
		}
		.wave_cleared {}
		.game_over {}
	}
}
