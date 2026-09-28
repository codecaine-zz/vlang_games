module main

import rand

pub const grid_size = 10

pub const cell_empty = 0
pub const cell_ship = 1
pub const cell_miss = 2
pub const cell_hit = 3
pub const cell_sunk = 4

pub enum GamePhase {
	placement
	battle
	game_over
}

pub struct Ship {
pub mut:
	name       string
	size       int
	x          int = -1
	y          int = -1
	horizontal bool = true
	hits       int
	is_sunk    bool
	placed     bool
}

pub struct Grid {
pub mut:
	cells [10][10]int
	ships []Ship
}

pub fn new_grid() Grid {
	mut g := Grid{}
	g.ships << Ship{ name: 'Aircraft Carrier', size: 5 }
	g.ships << Ship{ name: 'Battleship', size: 4 }
	g.ships << Ship{ name: 'Cruiser', size: 3 }
	g.ships << Ship{ name: 'Submarine', size: 3 }
	g.ships << Ship{ name: 'Destroyer', size: 2 }
	return g
}

pub fn (g Grid) can_place(size int, x int, y int, horizontal bool) bool {
	if horizontal {
		if x < 0 || x + size > grid_size || y < 0 || y >= grid_size {
			return false
		}
		for i in 0 .. size {
			if g.cells[y][x + i] != cell_empty {
				return false
			}
		}
	} else {
		if x < 0 || x >= grid_size || y < 0 || y + size > grid_size {
			return false
		}
		for i in 0 .. size {
			if g.cells[y + i][x] != cell_empty {
				return false
			}
		}
	}
	return true
}

pub fn (mut g Grid) place_ship(idx int, x int, y int, horizontal bool) bool {
	if idx < 0 || idx >= g.ships.len {
		return false
	}
	size := g.ships[idx].size
	if !g.can_place(size, x, y, horizontal) {
		return false
	}

	// Clear old placement if already placed
	if g.ships[idx].placed {
		old_x := g.ships[idx].x
		old_y := g.ships[idx].y
		old_h := g.ships[idx].horizontal
		for i in 0 .. size {
			if old_h {
				g.cells[old_y][old_x + i] = cell_empty
			} else {
				g.cells[old_y + i][old_x] = cell_empty
			}
		}
	}

	g.ships[idx].x = x
	g.ships[idx].y = y
	g.ships[idx].horizontal = horizontal
	g.ships[idx].placed = true

	for i in 0 .. size {
		if horizontal {
			g.cells[y][x + i] = cell_ship
		} else {
			g.cells[y + i][x] = cell_ship
		}
	}
	return true
}

pub fn (mut g Grid) auto_place_all() {
	// Reset cells
	for y in 0 .. grid_size {
		for x in 0 .. grid_size {
			g.cells[y][x] = cell_empty
		}
	}

	for i in 0 .. g.ships.len {
		g.ships[i].placed = false
		size := g.ships[i].size
		mut placed := false
		for !placed {
			h := rand.f64() < 0.5
			x := if h { rand.int_in_range(0, grid_size - size + 1) or { 0 } } else { rand.int_in_range(0, grid_size) or { 0 } }
			y := if h { rand.int_in_range(0, grid_size) or { 0 } } else { rand.int_in_range(0, grid_size - size + 1) or { 0 } }
			if g.can_place(size, x, y, h) {
				g.place_ship(i, x, y, h)
				placed = true
			}
		}
	}
}

pub struct BattleshipGame {
pub mut:
	p1_grid              Grid
	p2_grid              Grid
	phase                GamePhase = .placement
	current_turn         int = 1 // 1: P1, 2: P2 / AI
	is_two_player        bool
	selected_ship_idx    int
	place_horizontal     bool = true
	cursor_gx            int
	cursor_gy            int
	ai_target_queue      [][]int
	radar_left_p1        int = 1
	radar_active         bool
	radar_revealed       [][]int
	radar_timer          f64
	ai_delay_timer       f64
	status_message       string
	winner               int // 1 or 2
	sound_event          string
	shots_fired_p1       int
	shots_hit_p1         int
}

pub fn new_battleship_game(is_2p bool) BattleshipGame {
	mut g := BattleshipGame{
		p1_grid:       new_grid()
		p2_grid:       new_grid()
		is_two_player: is_2p
	}
	g.reset()
	return g
}

pub fn (mut g BattleshipGame) reset() {
	g.p1_grid = new_grid()
	g.p2_grid = new_grid()
	g.phase = .placement
	g.current_turn = 1
	g.selected_ship_idx = 0
	g.place_horizontal = true
	g.cursor_gx = 0
	g.cursor_gy = 0
	g.ai_target_queue.clear()
	g.radar_left_p1 = 1
	g.radar_active = false
	g.radar_revealed.clear()
	g.winner = 0
	g.shots_fired_p1 = 0
	g.shots_hit_p1 = 0
	g.status_message = 'Deploy your fleet! Click grid or press F for auto-placement. R to rotate.'

	// Auto-place enemy fleet
	g.p2_grid.auto_place_all()
}

pub fn (mut g BattleshipGame) start_battle() {
	// Check if all P1 ships are placed
	for s in g.p1_grid.ships {
		if !s.placed {
			g.status_message = 'Please place all 5 ships before starting battle!'
			return
		}
	}
	g.phase = .battle
	g.current_turn = 1
	g.status_message = 'Battle Stations! Click enemy radar grid to fire torpedoes.'
	g.sound_event = 'sonar'
}

pub fn (mut g BattleshipGame) fire_shot(target_grid_idx int, gx int, gy int) (bool, bool, string) {
	if gx < 0 || gx >= grid_size || gy < 0 || gy >= grid_size {
		return false, false, ''
	}

	mut target_grid := if target_grid_idx == 2 { &g.p2_grid } else { &g.p1_grid }
	cur_cell := target_grid.cells[gy][gx]

	if cur_cell == cell_miss || cur_cell == cell_hit || cur_cell == cell_sunk {
		return false, false, '' // Already fired here
	}

	if target_grid_idx == 2 {
		g.shots_fired_p1++
	}

	if cur_cell == cell_ship {
		// HIT!
		target_grid.cells[gy][gx] = cell_hit
		if target_grid_idx == 2 {
			g.shots_hit_p1++
		}

		// Find which ship was hit
		mut sunk_name := ''
		mut was_sunk := false
		for mut s in target_grid.ships {
			if s.is_sunk { continue }
			for i in 0 .. s.size {
				sx := if s.horizontal { s.x + i } else { s.x }
				sy := if s.horizontal { s.y } else { s.y + i }
				if sx == gx && sy == gy {
					s.hits++
					if s.hits >= s.size {
						s.is_sunk = true
						was_sunk = true
						sunk_name = s.name
						// Mark all cells of this ship as sunk
						for k in 0 .. s.size {
							kx := if s.horizontal { s.x + k } else { s.x }
							ky := if s.horizontal { s.y } else { s.y + k }
							target_grid.cells[ky][kx] = cell_sunk
						}
					}
					break
				}
			}
		}

		// Check game over
		mut all_sunk := true
		for s in target_grid.ships {
			if !s.is_sunk {
				all_sunk = false
				break
			}
		}

		if all_sunk {
			g.phase = .game_over
			g.winner = if target_grid_idx == 2 { 1 } else { 2 }
			winner_name := if g.winner == 1 { 'PLAYER 1' } else { if g.is_two_player { 'PLAYER 2' } else { 'ENEMY FLEET' } }
			g.status_message = '🏆 ${winner_name} HAS SUNK ALL ENEMY SHIPS!'
			g.sound_event = 'victory'
		}

		return true, was_sunk, sunk_name
	} else {
		// MISS!
		target_grid.cells[gy][gx] = cell_miss
		return false, false, ''
	}
}

pub fn (mut g BattleshipGame) execute_player_turn(gx int, gy int) {
	if g.phase != .battle || g.current_turn != 1 {
		return
	}

	if g.radar_active {
		// Execute 3x3 Radar scan
		g.radar_active = false
		g.radar_left_p1--
		g.radar_revealed.clear()
		g.radar_timer = 2.5
		g.sound_event = 'sonar'

		mut ships_found := 0
		for dy := -1; dy <= 1; dy++ {
			for dx := -1; dx <= 1; dx++ {
				rx := gx + dx
				ry := gy + dy
				if rx >= 0 && rx < grid_size && ry >= 0 && ry < grid_size {
					g.radar_revealed << [rx, ry]
					if g.p2_grid.cells[ry][rx] == cell_ship || g.p2_grid.cells[ry][rx] == cell_hit {
						ships_found++
					}
				}
			}
		}
		g.status_message = 'Radar Scan at ${coord_to_str(gx, gy)}: Detected ${ships_found} ship segment(s)!'
		return
	}

	is_hit, is_sunk, sunk_name := g.fire_shot(2, gx, gy)
	coord := coord_to_str(gx, gy)

	if g.phase == .game_over {
		return
	}

	if is_hit {
		if is_sunk {
			g.status_message = 'DIRECT HIT at ${coord}! You SUNK the enemy ${sunk_name}!'
			g.sound_event = 'sunk'
		} else {
			g.status_message = 'DIRECT HIT at ${coord}! Enemy vessel damaged!'
			g.sound_event = 'hit'
		}
	} else {
		g.status_message = 'TORPEDO MISSED at ${coord}. Ocean water splash.'
		g.sound_event = 'splash'
	}

	// Advance turn
	g.current_turn = 2
	g.ai_delay_timer = 0.8
}

pub fn (mut g BattleshipGame) update(dt f64) {
	if g.radar_timer > 0 {
		g.radar_timer -= dt
		if g.radar_timer <= 0 {
			g.radar_revealed.clear()
		}
	}

	if g.phase == .battle && g.current_turn == 2 && !g.is_two_player {
		g.ai_delay_timer -= dt
		if g.ai_delay_timer <= 0 {
			g.execute_ai_turn()
		}
	}
}

pub fn (mut g BattleshipGame) execute_ai_turn() {
	if g.phase != .battle || g.current_turn != 2 {
		return
	}

	mut gx := 0
	mut gy := 0
	mut found_target := false

	// Target mode: pop from target queue
	for g.ai_target_queue.len > 0 {
		target := g.ai_target_queue.pop()
		tx := target[0]
		ty := target[1]
		if tx >= 0 && tx < grid_size && ty >= 0 && ty < grid_size {
			c := g.p1_grid.cells[ty][tx]
			if c == cell_empty || c == cell_ship {
				gx = tx
				gy = ty
				found_target = true
				break
			}
		}
	}

	// Hunt mode: parity checkerboard scan
	if !found_target {
		mut available := [][]int{}
		for y in 0 .. grid_size {
			for x in 0 .. grid_size {
				if (x + y) % 2 == 0 {
					c := g.p1_grid.cells[y][x]
					if c == cell_empty || c == cell_ship {
						available << [x, y]
					}
				}
			}
		}
		if available.len == 0 {
			for y in 0 .. grid_size {
				for x in 0 .. grid_size {
					c := g.p1_grid.cells[y][x]
					if c == cell_empty || c == cell_ship {
						available << [x, y]
					}
				}
			}
		}
		if available.len > 0 {
			pick := available[rand.int_in_range(0, available.len) or { 0 }]
			gx = pick[0]
			gy = pick[1]
		}
	}

	is_hit, is_sunk, sunk_name := g.fire_shot(1, gx, gy)
	coord := coord_to_str(gx, gy)

	if is_hit {
		if is_sunk {
			g.status_message = 'Enemy fired at ${coord}: DIRECT HIT! Your ${sunk_name} was SUNK!'
			g.sound_event = 'sunk'
			g.ai_target_queue.clear() // Clear targets for this sunk ship
		} else {
			g.status_message = 'Enemy fired at ${coord}: DIRECT HIT on your vessel!'
			g.sound_event = 'hit'
			// Push 4 orthogonal neighbors to target queue
			g.ai_target_queue << [gx + 1, gy]
			g.ai_target_queue << [gx - 1, gy]
			g.ai_target_queue << [gx, gy + 1]
			g.ai_target_queue << [gx, gy - 1]
		}
	} else {
		g.status_message = 'Enemy fired at ${coord}: MISSED into open water.'
		g.sound_event = 'splash'
	}

	if g.phase != .game_over {
		g.current_turn = 1
	}
}

pub fn coord_to_str(gx int, gy int) string {
	col_letter := u8(`A` + gx).ascii_str()
	row_num := gy + 1
	return '${col_letter}${row_num}'
}
