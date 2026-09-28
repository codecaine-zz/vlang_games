module main

import math
import rand

const world_w = 800
const world_h = 700

const bunker_cols = 12
const bunker_rows = 10
const bunker_block_sz = 5

pub enum AlienType {
	squid
	crab
	octopus
}

pub enum GameState {
	ready
	playing
	wave_clear
	game_over
}

pub struct Alien {
pub mut:
	x             f64
	y             f64
	row           int
	col           int
	kind          AlienType
	alive         bool = true
	frame         int
	exploding     bool
	explode_timer f64
}

pub struct Bullet {
pub mut:
	x         f64
	y         f64
	dy        f64
	is_player bool
	kind      int
	alive     bool = true
}

pub struct BunkerShield {
pub mut:
	x     f64
	y     f64
	grid  [][]bool // true = solid, false = eroded
}

pub fn new_bunker_shield(x f64, y f64) BunkerShield {
	mut g := [][]bool{len: bunker_rows, init: []bool{len: bunker_cols, init: true}}
	// Carve top-left and top-right curved arch
	g[0][0] = false
	g[0][1] = false
	g[1][0] = false
	g[0][bunker_cols - 1] = false
	g[0][bunker_cols - 2] = false
	g[1][bunker_cols - 1] = false

	// Carve bottom arch tunnel
	for r in 6 .. bunker_rows {
		for c in 4 .. 8 {
			g[r][c] = false
		}
	}
	return BunkerShield{
		x:    x
		y:    y
		grid: g
	}
}

pub struct UFO {
pub mut:
	x          f64
	y          f64
	dx         f64
	active     bool
	score_val  int
	show_score bool
	show_timer f64
}

pub struct Player {
pub mut:
	x             f64
	y             f64
	w             f64 = 44.0
	h             f64 = 24.0
	speed         f64 = 300.0
	alive         bool = true
	respawn_timer f64
}

pub struct SpaceInvadersGame {
pub mut:
	aliens          [][]Alien
	aliens_alive    int
	march_dir       int = 1 // 1 = right, -1 = left
	march_timer     f64
	march_interval  f64 = 0.8
	beat_idx        int
	shields         []BunkerShield
	bullets         []Bullet
	player          Player
	ufo             UFO
	ufo_timer       f64 = 20.0
	score           int
	high_score      int = 5000
	lives           int = 3
	wave            int = 1
	state           GameState = .ready
	alien_fire_rate f64 = 1.2
	alien_fire_tm   f64
}

pub fn new_space_invaders_game() SpaceInvadersGame {
	mut game := SpaceInvadersGame{}
	game.init_game()
	return game
}

pub fn (mut g SpaceInvadersGame) init_game() {
	g.score = 0
	g.lives = 3
	g.wave = 1
	g.init_wave(1)
}

pub fn (mut g SpaceInvadersGame) init_wave(wave int) {
	g.wave = wave
	g.bullets.clear()
	g.state = .playing
	g.march_dir = 1
	g.beat_idx = 0
	g.march_interval = math.max(0.75 - f64(wave - 1) * 0.08, 0.25)
	g.march_timer = 0.0

	// Player cannon setup
	g.player = Player{
		x:             f64(world_w / 2 - 22)
		y:             f64(world_h - 75)
		alive:         true
		respawn_timer: 0.0
	}

	// 55 Aliens in 5 rows x 11 cols
	g.aliens = [][]Alien{len: 5}
	start_x := 100.0
	start_y := 120.0 + f64(math.min(wave - 1, 4)) * 15.0

	for r in 0 .. 5 {
		kind := if r == 0 {
			AlienType.squid
		} else if r <= 2 {
			AlienType.crab
		} else {
			AlienType.octopus
		}
		mut row_aliens := []Alien{cap: 11}
		for c in 0 .. 11 {
			row_aliens << Alien{
				x:     start_x + f64(c * 52)
				y:     start_y + f64(r * 40)
				row:   r
				col:   c
				kind:  kind
				alive: true
				frame: 0
			}
		}
		g.aliens[r] = row_aliens
	}
	g.aliens_alive = 55

	// Init 4 bunker shields
	g.shields.clear()
	spacing := 160.0
	bunker_start := 100.0
	for i in 0 .. 4 {
		bx := bunker_start + f64(i) * spacing
		by := f64(world_h - 170)
		g.shields << new_bunker_shield(bx, by)
	}

	g.ufo = UFO{
		x:          -80.0
		y:          75.0
		dx:         120.0
		active:     false
		score_val:  0
		show_score: false
	}
	g.ufo_timer = 18.0 + f64(rand.intn(10) or { 5 })
}

pub fn (mut g SpaceInvadersGame) fire_player_bullet() bool {
	if !g.player.alive || g.state != .playing {
		return false
	}
	// Only 1 active player bullet allowed simultaneously for authentic classic gameplay
	for b in g.bullets {
		if b.is_player && b.alive {
			return false
		}
	}
	g.bullets << Bullet{
		x:         g.player.x + g.player.w / 2.0 - 2.0
		y:         g.player.y - 8.0
		dy:        -650.0
		is_player: true
		kind:      0
		alive:     true
	}
	return true
}

pub fn (mut g SpaceInvadersGame) fire_alien_bullet() {
	if g.aliens_alive == 0 || g.state != .playing {
		return
	}
	// Pick random active column
	mut live_cols := []int{}
	for c in 0 .. 11 {
		for r := 4; r >= 0; r-- {
			if g.aliens[r][c].alive {
				live_cols << c
				break
			}
		}
	}
	if live_cols.len == 0 {
		return
	}
	chosen_c := live_cols[rand.intn(live_cols.len) or { 0 }]

	// Find bottom-most alien in this column
	mut shooter_r := -1
	for r := 4; r >= 0; r-- {
		if g.aliens[r][chosen_c].alive {
			shooter_r = r
			break
		}
	}
	if shooter_r >= 0 {
		al := g.aliens[shooter_r][chosen_c]
		g.bullets << Bullet{
			x:         al.x + 18.0
			y:         al.y + 28.0
			dy:        280.0 + f64(g.wave * 20)
			is_player: false
			kind:      rand.intn(3) or { 0 }
			alive:     true
		}
	}
}

pub struct UpdateEvents {
pub mut:
	march_beat       bool
	beat_idx         int
	alien_exploded   bool
	player_exploded  bool
	ufo_siren        bool
	ufo_bonus        bool
	ufo_bonus_val    int
}

pub fn (mut g SpaceInvadersGame) update(dt f64, move_left bool, move_right bool) UpdateEvents {
	mut ev := UpdateEvents{}

	if g.state != .playing {
		return ev
	}

	// Player movement
	if g.player.alive {
		if move_left {
			g.player.x -= g.player.speed * dt
			if g.player.x < 30.0 {
				g.player.x = 30.0
			}
		}
		if move_right {
			g.player.x += g.player.speed * dt
			if g.player.x > f64(world_w - 74) {
				g.player.x = f64(world_w - 74)
			}
		}
	} else {
		g.player.respawn_timer -= dt
		if g.player.respawn_timer <= 0.0 {
			if g.lives > 0 {
				g.player.alive = true
				g.player.x = f64(world_w / 2 - 22)
			} else {
				g.state = .game_over
			}
		}
	}

	// Alien march timing
	g.march_timer += dt
	// Dynamic march speed acceleration based on remaining aliens
	ratio := f64(g.aliens_alive) / 55.0
	current_march_speed := math.max(0.06, g.march_interval * ratio)

	if g.march_timer >= current_march_speed {
		g.march_timer = 0.0
		ev.march_beat = true
		ev.beat_idx = g.beat_idx
		g.beat_idx = (g.beat_idx + 1) % 4

		// Check if any alien reaches the boundary
		mut hit_edge := false
		step_x := f64(g.march_dir * 14)

		for r in 0 .. 5 {
			for c in 0 .. 11 {
				if g.aliens[r][c].alive {
					next_x := g.aliens[r][c].x + step_x
					if next_x < 35.0 || next_x > f64(world_w - 75) {
						hit_edge = true
						break
					}
				}
			}
			if hit_edge {
				break
			}
		}

		if hit_edge {
			g.march_dir = -g.march_dir
			// Drop down
			for r in 0 .. 5 {
				for c in 0 .. 11 {
					if g.aliens[r][c].alive {
						g.aliens[r][c].y += 22.0
						g.aliens[r][c].frame = 1 - g.aliens[r][c].frame
						// Check invasion threshold
						if g.aliens[r][c].y >= g.player.y - 10.0 {
							g.lives = 0
							g.state = .game_over
							ev.player_exploded = true
						}
					}
				}
			}
		} else {
			// Step sideways
			for r in 0 .. 5 {
				for c in 0 .. 11 {
					if g.aliens[r][c].alive {
						g.aliens[r][c].x += step_x
						g.aliens[r][c].frame = 1 - g.aliens[r][c].frame
					}
				}
			}
		}
	}

	// Update alien explosions
	for r in 0 .. 5 {
		for c in 0 .. 11 {
			if g.aliens[r][c].exploding {
				g.aliens[r][c].explode_timer -= dt
				if g.aliens[r][c].explode_timer <= 0.0 {
					g.aliens[r][c].exploding = false
				}
			}
		}
	}

	// Alien firing
	g.alien_fire_tm += dt
	fire_thresh := math.max(0.6, g.alien_fire_rate - f64(g.wave) * 0.1)
	if g.alien_fire_tm >= fire_thresh {
		g.alien_fire_tm = 0.0
		g.fire_alien_bullet()
	}

	// UFO Saucer Logic
	if !g.ufo.active && !g.ufo.show_score {
		g.ufo_timer -= dt
		if g.ufo_timer <= 0.0 {
			g.ufo.active = true
			if rand.intn(2) or { 0 } == 0 {
				g.ufo.x = -60.0
				g.ufo.dx = 140.0
			} else {
				g.ufo.x = f64(world_w + 60)
				g.ufo.dx = -140.0
			}
		}
	} else if g.ufo.active {
		g.ufo.x += g.ufo.dx * dt
		ev.ufo_siren = true
		if (g.ufo.dx > 0 && g.ufo.x > f64(world_w + 80)) || (g.ufo.dx < 0 && g.ufo.x < -80.0) {
			g.ufo.active = false
			g.ufo_timer = 20.0 + f64(rand.intn(15) or { 10 })
		}
	} else if g.ufo.show_score {
		g.ufo.show_timer -= dt
		if g.ufo.show_timer <= 0.0 {
			g.ufo.show_score = false
			g.ufo_timer = 20.0 + f64(rand.intn(15) or { 10 })
		}
	}

	// Update Bullets & Collisions
	for mut b in g.bullets {
		if !b.alive {
			continue
		}
		b.y += b.dy * dt

		// Out of bounds
		if b.y < 50.0 || b.y > f64(world_h - 20) {
			b.alive = false
			continue
		}

		// Player bullet hits
		if b.is_player {
			// Check UFO hit
			if g.ufo.active && b.x >= g.ufo.x && b.x <= g.ufo.x + 48.0 && b.y >= g.ufo.y && b.y <= g.ufo.y + 24.0 {
				b.alive = false
				g.ufo.active = false
				scores := [50, 100, 150, 300]
				bonus := scores[rand.intn(scores.len) or { 0 }]
				g.ufo.score_val = bonus
				g.ufo.show_score = true
				g.ufo.show_timer = 1.0
				g.score += bonus
				if g.score > g.high_score {
					g.high_score = g.score
				}
				ev.ufo_bonus = true
				ev.ufo_bonus_val = bonus
				continue
			}

			// Check alien hit
			mut hit_alien := false
			for r in 0 .. 5 {
				for c in 0 .. 11 {
					mut al := &g.aliens[r][c]
					if al.alive && b.x >= al.x && b.x <= al.x + 36.0 && b.y >= al.y && b.y <= al.y + 28.0 {
						al.alive = false
						al.exploding = true
						al.explode_timer = 0.2
						b.alive = false
						g.aliens_alive--
						pts := match al.kind {
							.squid { 30 }
							.crab { 20 }
							.octopus { 10 }
						}
						g.score += pts
						if g.score > g.high_score {
							g.high_score = g.score
						}
						ev.alien_exploded = true
						hit_alien = true
						break
					}
				}
				if hit_alien {
					break
				}
			}

			if g.aliens_alive == 0 {
				g.state = .wave_clear
			}
		} else {
			// Alien bullet hits player
			if g.player.alive && b.x >= g.player.x && b.x <= g.player.x + g.player.w && b.y >= g.player.y && b.y <= g.player.y + g.player.h {
				b.alive = false
				g.player.alive = false
				g.player.respawn_timer = 1.8
				g.lives--
				ev.player_exploded = true
				continue
			}
		}

		// Bunker shields erosion collision
		for mut s in g.shields {
			if b.x >= s.x && b.x <= s.x + f64(bunker_cols * bunker_block_sz) &&
				b.y >= s.y && b.y <= s.y + f64(bunker_rows * bunker_block_sz) {
				grid_c := int((b.x - s.x) / f64(bunker_block_sz))
				grid_r := int((b.y - s.y) / f64(bunker_block_sz))
				if grid_r >= 0 && grid_r < bunker_rows && grid_c >= 0 && grid_c < bunker_cols {
					if s.grid[grid_r][grid_c] {
						// Erode hit block and adjacent crater
						s.grid[grid_r][grid_c] = false
						if grid_r > 0 { s.grid[grid_r - 1][grid_c] = false }
						if grid_r < bunker_rows - 1 { s.grid[grid_r + 1][grid_c] = false }
						if grid_c > 0 { s.grid[grid_r][grid_c - 1] = false }
						if grid_c < bunker_cols - 1 { s.grid[grid_r][grid_c + 1] = false }
						b.alive = false
						break
					}
				}
			}
		}
	}

	// Filter dead bullets
	mut alive_bullets := []Bullet{cap: g.bullets.len}
	for b in g.bullets {
		if b.alive {
			alive_bullets << b
		}
	}
	g.bullets = alive_bullets.clone()

	return ev
}
