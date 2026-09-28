module main

import math
import rand

const grid_cols = 16
const grid_rows = 12
const tile_size = 40
const offset_x = 80
const offset_y = 80

enum GameState {
	menu
	playing
	paused
	game_over
	stage_clear
}

enum EnemyType {
	pooka
	fygar
}

enum Direction {
	left
	right
	up
	down
}

struct DirtTile {
mut:
	is_dug bool
	layer  int // 0..3 dirt color layer
}

struct Boulder {
mut:
	grid_x     int
	grid_y     int
	y          f32
	is_falling bool
	fall_speed f32
	active     bool
}

struct Enemy {
mut:
	id          int
	enemy_type  EnemyType
	grid_x      int
	grid_y      int
	x           f32
	y           f32
	dir         Direction
	inflate_stage int // 0..4 (4 = pop!)
	is_ghost    bool
	active      bool = true
	fire_timer  f32
	is_breathing_fire bool
}

struct PumpHose {
mut:
	active   bool
	dir      Direction
	length   f32
	target_id int = -1
}

struct DigDugGame {
mut:
	state       GameState = .menu
	score       int
	high_score  int = 5000
	stage       int = 1
	lives       int = 3
	player_gx   int = 8
	player_gy   int = 6
	player_x    f32 = 400.0
	player_y    f32 = 320.0
	player_dir  Direction = .right
	grid        [][]DirtTile
	boulders    []Boulder
	enemies      []Enemy
	pump         PumpHose
	sound_mgr    SoundManager
	shake_trauma f32
}

fn new_digdug_game() DigDugGame {
	mut g := DigDugGame{
		grid: [][]DirtTile{len: grid_rows, init: []DirtTile{len: grid_cols, init: DirtTile{ is_dug: false, layer: 0 }}}
		sound_mgr: new_sound_manager()
	}
	g.reset_game()
	return g
}

fn (mut g DigDugGame) reset_game() {
	g.score = 0
	g.stage = 1
	g.lives = 3
	g.init_stage()
	g.state = .playing
}

fn (mut g DigDugGame) init_stage() {
	// Initialize 16x12 Dirt Grid with 4 color layers
	g.grid = [][]DirtTile{len: grid_rows, init: []DirtTile{len: grid_cols, init: DirtTile{ is_dug: false, layer: 0 }}}

	for r in 0 .. grid_rows {
		layer_idx := r / 3
		for c in 0 .. grid_cols {
			// Top row 0 is sky (open)
			is_open := r == 0
			g.grid[r][c] = DirtTile{ is_dug: is_open, layer: layer_idx }
		}
	}

	// Dig out starting center tunnel for player
	g.player_gx = 8
	g.player_gy = 6
	g.player_x = f32(offset_x + 8 * tile_size + 20)
	g.player_y = f32(offset_y + 6 * tile_size + 20)
	g.grid[6][8].is_dug = true
	g.grid[6][7].is_dug = true
	g.grid[6][9].is_dug = true

	// Boulders
	g.boulders = [
		Boulder{ grid_x: 3, grid_y: 2, y: f32(offset_y + 2 * tile_size), active: true },
		Boulder{ grid_x: 12, grid_y: 3, y: f32(offset_y + 3 * tile_size), active: true },
		Boulder{ grid_x: 6, grid_y: 8, y: f32(offset_y + 8 * tile_size), active: true },
	]

	// Enemies
	g.enemies = [
		Enemy{ id: 1, enemy_type: .pooka, grid_x: 3, grid_y: 4, x: f32(offset_x + 3 * tile_size + 20), y: f32(offset_y + 4 * tile_size + 20), dir: .right },
		Enemy{ id: 2, enemy_type: .pooka, grid_x: 12, grid_y: 7, x: f32(offset_x + 12 * tile_size + 20), y: f32(offset_y + 7 * tile_size + 20), dir: .left },
		Enemy{ id: 3, enemy_type: .fygar, grid_x: 4, grid_y: 9, x: f32(offset_x + 4 * tile_size + 20), y: f32(offset_y + 9 * tile_size + 20), dir: .right },
	]

	// Clear tunnel spots for enemies
	g.grid[4][3].is_dug = true
	g.grid[7][12].is_dug = true
	g.grid[9][4].is_dug = true

	g.pump = PumpHose{ active: false }
}

fn (mut g DigDugGame) move_player(dx int, dy int) {
	if g.state != .playing { return }

	if dx < 0 { g.player_dir = .left }
	else if dx > 0 { g.player_dir = .right }
	else if dy < 0 { g.player_dir = .up }
	else if dy > 0 { g.player_dir = .down }

	new_gx := g.player_gx + dx
	new_gy := g.player_gy + dy

	if new_gx >= 0 && new_gx < grid_cols && new_gy >= 1 && new_gy < grid_rows {
		// Check boulder collision
		for b in g.boulders {
			if b.active && b.grid_x == new_gx && b.grid_y == new_gy {
				return
			}
		}

		g.player_gx = new_gx
		g.player_gy = new_gy
		g.player_x = f32(offset_x + new_gx * tile_size + 20)
		g.player_y = f32(offset_y + new_gy * tile_size + 20)

		// Dig out tile!
		if !g.grid[new_gy][new_gx].is_dug {
			g.grid[new_gy][new_gx].is_dug = true
			g.score += 10
			g.sound_mgr.play_dig_sound()
		}
	}
}

fn (mut g DigDugGame) pump_action() {
	if g.state != .playing { return }

	// If pump already connected to enemy -> inflate!
	if g.pump.active && g.pump.target_id > 0 {
		for mut e in g.enemies {
			if e.id == g.pump.target_id && e.active {
				e.inflate_stage++
				g.sound_mgr.play_pump_sound()
				if e.inflate_stage >= 4 {
					// Pop!
					e.active = false
					g.pump.active = false
					g.score += if e.enemy_type == .pooka { 400 } else { 800 }
					if g.score > g.high_score { g.high_score = g.score }
					g.sound_mgr.play_pop_sound()
					g.shake_trauma = f32(math.min(1.0, f64(g.shake_trauma + 0.35)))
				}
				return
			}
		}
	}

	// Shoot new hose line in facing direction
	g.pump.active = true
	g.pump.dir = g.player_dir
	g.pump.length = 60.0
	g.pump.target_id = -1

	// Check if hose touches any enemy
	for mut e in g.enemies {
		if !e.active { continue }
		dist := f32(math.abs(g.player_x - e.x) + math.abs(g.player_y - e.y))
		if dist < 65.0 {
			g.pump.target_id = e.id
			e.inflate_stage = 1
			g.sound_mgr.play_pump_sound()
			break
		}
	}
}

fn (mut g DigDugGame) update(dt f32) {
	if g.state != .playing { return }

	if g.shake_trauma > 0 {
		g.shake_trauma = f32(math.max(0.0, f64(g.shake_trauma - dt * 2.5)))
	}

	// 1. Deflate pumped enemies gradually if player stops pumping
	for mut e in g.enemies {
		if !e.active { continue }
		if e.inflate_stage > 0 && (!g.pump.active || g.pump.target_id != e.id) {
			e.inflate_stage = 0
		}
	}

	// 2. Update Boulders (Falling physics)
	for mut b in g.boulders {
		if !b.active { continue }

		if !b.is_falling {
			// Check if dirt underneath is dug out
			if b.grid_y + 1 < grid_rows && g.grid[b.grid_y + 1][b.grid_x].is_dug {
				b.is_falling = true
				b.fall_speed = 220.0
				g.sound_mgr.play_rock_drop_sound()
			}
		} else {
			b.y += b.fall_speed * dt
			b.grid_y = int((b.y - f32(offset_y)) / f32(tile_size))

			// Check boulder collision with player
			if b.grid_x == g.player_gx && b.grid_y == g.player_gy {
				g.handle_player_death()
				return
			}

			// Check boulder collision with enemies
			for mut e in g.enemies {
				if e.active && e.grid_x == b.grid_x && e.grid_y == b.grid_y {
					e.active = false
					g.score += 1000
				}
			}

			// Stop when hitting solid ground or screen bottom
			if b.grid_y + 1 >= grid_rows || !g.grid[b.grid_y + 1][b.grid_x].is_dug {
				b.active = false
			}
		}
	}

	// 3. Update Enemies
	mut active_enemies := 0
	for mut e in g.enemies {
		if !e.active { continue }
		active_enemies++

		if e.inflate_stage > 0 { continue } // Stunned while inflating

		// Move enemy in tunnels or ghost through dirt
		if (rand.intn(200) or { 0 }) == 1 {
			e.is_ghost = !e.is_ghost
		}

		speed := if e.is_ghost { f32(40.0) } else { f32(75.0) }

		if e.is_ghost {
			// Move straight towards player position
			dx := g.player_x - e.x
			dy := g.player_y - e.y
			dist := f32(math.sqrt(dx * dx + dy * dy))
			if dist > 5.0 {
				e.x += (dx / dist) * speed * dt
				e.y += (dy / dist) * speed * dt
			}
			e.grid_x = int((e.x - f32(offset_x)) / f32(tile_size))
			e.grid_y = int((e.y - f32(offset_y)) / f32(tile_size))

			if g.grid[e.grid_y][e.grid_x].is_dug {
				e.is_ghost = false
			}
		} else {
			// Fygar fire breath logic
			if e.enemy_type == .fygar {
				if e.is_breathing_fire {
					e.fire_timer -= dt
					// Check flame collision with player
					flame_min_x := if e.dir == .right { e.x } else { e.x - 70.0 }
					flame_max_x := if e.dir == .right { e.x + 70.0 } else { e.x }
					if g.player_x >= flame_min_x && g.player_x <= flame_max_x && math.abs(g.player_y - e.y) < 16.0 {
						g.handle_player_death()
						return
					}
					if e.fire_timer <= 0 {
						e.is_breathing_fire = false
						e.fire_timer = 3.0 + f32(rand.intn(200) or { 100 }) / 100.0
					}
				} else {
					e.fire_timer -= dt
					if e.fire_timer <= 0 && e.grid_y == g.player_gy {
						dist_gx := g.player_gx - e.grid_x
						if (dist_gx > 0 && dist_gx <= 3 && e.dir == .right) || (dist_gx < 0 && dist_gx >= -3 && e.dir == .left) {
							e.is_breathing_fire = true
							e.fire_timer = 1.0
						}
					}
				}
			}

			if !e.is_breathing_fire {
				// 4-Way tunnel navigation
				dx, dy := match e.dir {
					.left { -1.0, 0.0 }
					.right { 1.0, 0.0 }
					.up { 0.0, -1.0 }
					.down { 0.0, 1.0 }
				}
				e.x += f32(dx) * speed * dt
				e.y += f32(dy) * speed * dt
				e.grid_x = int((e.x - f32(offset_x)) / f32(tile_size))
				e.grid_y = int((e.y - f32(offset_y)) / f32(tile_size))

				// Check if enemy hit a wall or boundary
				if e.grid_x <= 0 || e.grid_x >= grid_cols - 1 || e.grid_y <= 0 || e.grid_y >= grid_rows - 1 || !g.grid[e.grid_y][e.grid_x].is_dug {
					e.x -= f32(dx) * speed * dt
					e.y -= f32(dy) * speed * dt
					e.grid_x = int((e.x - f32(offset_x)) / f32(tile_size))
					e.grid_y = int((e.y - f32(offset_y)) / f32(tile_size))

					mut valid_dirs := []Direction{}
					for test_dir in [Direction.left, .right, .up, .down] {
						tdx, tdy := match test_dir {
							.left { -1, 0 }
							.right { 1, 0 }
							.up { 0, -1 }
							.down { 0, 1 }
						}
						nx := e.grid_x + tdx
						ny := e.grid_y + tdy
						if nx >= 0 && nx < grid_cols && ny >= 0 && ny < grid_rows {
							if g.grid[ny][nx].is_dug {
								valid_dirs << test_dir
							}
						}
					}

					if valid_dirs.len > 0 {
						e.dir = valid_dirs[rand.intn(valid_dirs.len) or { 0 }]
					} else {
						e.is_ghost = true
					}
				}
			}
		}

		// Touch player check
		if math.abs(e.x - g.player_x) < 18.0 && math.abs(e.y - g.player_y) < 18.0 {
			g.handle_player_death()
			return
		}
	}

	if active_enemies == 0 {
		g.stage++
		g.init_stage()
	}
}

fn (mut g DigDugGame) handle_player_death() {
	g.lives--
	g.pump.active = false
	g.shake_trauma = 0.55
	if g.lives <= 0 {
		g.state = .game_over
	} else {
		g.player_gx = 8
		g.player_gy = 6
		g.player_x = f32(offset_x + 8 * tile_size + 20)
		g.player_y = f32(offset_y + 6 * tile_size + 20)
	}
}
