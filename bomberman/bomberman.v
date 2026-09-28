module main

import math
import rand

const grid_cols = 15
const grid_rows = 13
const tile_size = 40
const grid_offset_x = 100
const grid_offset_y = 40

enum GameState {
	menu
	playing
	paused
	game_over
	victory
}

enum TileType {
	empty
	hard_wall
	soft_block
}

enum PowerUpType {
	none
	flame
	bomb_cap
	speed
	kick
}

struct PowerUp {
mut:
	grid_x      int
	grid_y      int
	power_type  PowerUpType
	active      bool
}

struct Bomb {
mut:
	grid_x     int
	grid_y     int
	owner_id   int
	fuse_timer f32
	radius     int
	active     bool
}

struct FlameRay {
mut:
	grid_x int
	grid_y int
	timer  f32
}

struct BomberPlayer {
mut:
	id              int
	x               f32
	y               f32
	speed           f32 = 140.0
	bomb_count      int
	max_bombs       int = 1
	flame_radius    int = 2
	has_kick        bool
	lives           int = 3
	score           int
	is_ai           bool
	active          bool = true
	dir_x           f32
	dir_y           f32
	ai_change_timer f32
	target_gx       int = 1
	target_gy       int = 1
	is_moving       bool
}


struct BombermanGame {
mut:
	state          GameState = .menu
	grid           [][]TileType
	powerups       []PowerUp
	bombs          []Bomb
	flames         []FlameRay
	players        []BomberPlayer
	sound_mgr      SoundManager
	game_time      f32
	key_p1_up      bool
	key_p1_down    bool
	key_p1_left    bool
	key_p1_right   bool
	key_p1_bomb    bool
	key_p2_up      bool
	key_p2_down    bool
	key_p2_left    bool
	key_p2_right   bool
	key_p2_bomb    bool
	shake_trauma   f32
}

fn new_bomberman_game() BombermanGame {
	mut g := BombermanGame{
		grid: [][]TileType{len: grid_rows, init: []TileType{len: grid_cols, init: .empty}}
		sound_mgr: new_sound_manager()
	}
	g.reset_game()
	return g
}

fn (mut g BombermanGame) reset_game() {
	// Initialize Grid
	g.grid = [][]TileType{len: grid_rows, init: []TileType{len: grid_cols, init: .empty}}

	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			if r == 0 || r == grid_rows - 1 || c == 0 || c == grid_cols - 1 {
				g.grid[r][c] = .hard_wall
			} else if r % 2 == 0 && c % 2 == 0 {
				g.grid[r][c] = .hard_wall
			} else {
				// Don't place soft blocks near spawn corners (1,1), (1,2), (2,1) and (13,11)
				is_spawn := (r <= 2 && c <= 2) || (r >= grid_rows - 3 && c >= grid_cols - 3)
				if !is_spawn && (rand.intn(100) or { 0 }) < 65 {
					g.grid[r][c] = .soft_block
				}
			}
		}
	}

	g.bombs.clear()
	g.flames.clear()
	g.powerups.clear()

	// Players
	g.players = [
		BomberPlayer{
			id: 1
			x: f32(grid_offset_x + 1 * tile_size + 20)
			y: f32(grid_offset_y + 1 * tile_size + 20)
			target_gx: 1
			target_gy: 1
			is_ai: false
			lives: 3
			bomb_count: 0
			max_bombs: 1
		},
		BomberPlayer{
			id: 2
			x: f32(grid_offset_x + (grid_cols - 2) * tile_size + 20)
			y: f32(grid_offset_y + (grid_rows - 2) * tile_size + 20)
			target_gx: grid_cols - 2
			target_gy: grid_rows - 2
			is_ai: true
			lives: 3
			bomb_count: 0
			max_bombs: 1
		}
	]

	g.state = .playing
}

fn (mut g BombermanGame) update(dt f32) {
	if g.state != .playing { return }

	g.game_time += dt

	if g.shake_trauma > 0 {
		g.shake_trauma = f32(math.max(0.0, f64(g.shake_trauma - dt * 2.5)))
	}

	// Update Player 1
	g.update_player(0, dt)

	// Update Player 2 (or AI)
	if g.players[1].is_ai {
		g.update_ai_player(1, dt)
	} else {
		g.update_player(1, dt)
	}

	// Update Flames
	for mut f in g.flames {
		f.timer -= dt
	}
	g.flames = g.flames.filter(it.timer > 0)

	// Update Bombs
	for mut b in g.bombs {
		if !b.active { continue }
		b.fuse_timer -= dt
		if b.fuse_timer <= 0 {
			b.active = false
			g.detonate_bomb(b)
		}
	}
	g.bombs = g.bombs.filter(it.active)

	// Check Power-Up Pickups
	for mut p in g.powerups {
		if !p.active { continue }
		for mut pl in g.players {
			if !pl.active { continue }
			p_gx := int((pl.x - f32(grid_offset_x)) / f32(tile_size))
			p_gy := int((pl.y - f32(grid_offset_y)) / f32(tile_size))

			if p_gx == p.grid_x && p_gy == p.grid_y {
				p.active = false
				match p.power_type {
					.flame { pl.flame_radius++ }
					.bomb_cap { pl.max_bombs++ }
					.speed { pl.speed += 30.0 }
					.kick { pl.has_kick = true }
					else {}
				}
				pl.score += 200
				g.sound_mgr.play_powerup_sound()
			}
		}
	}
	g.powerups = g.powerups.filter(it.active)

	// Check Win/Loss conditions
	if !g.players[0].active {
		g.state = .game_over
	} else if !g.players[1].active {
		g.state = .victory
	}
}

fn (g &BombermanGame) is_tile_passable(gx int, gy int, cur_gx int, cur_gy int) bool {
	if gx < 0 || gx >= grid_cols || gy < 0 || gy >= grid_rows {
		return false
	}
	if g.grid[gy][gx] != .empty {
		return false
	}
	for b in g.bombs {
		if b.active && b.grid_x == gx && b.grid_y == gy {
			if cur_gx != gx || cur_gy != gy {
				return false
			}
		}
	}
	return true
}

fn (mut g BombermanGame) update_player(idx int, dt f32) {
	mut pl := &g.players[idx]
	if !pl.active { return }

	if idx == 0 {
		if g.key_p1_bomb {
			if pl.bomb_count < pl.max_bombs {
				g.drop_bomb(idx)
			}
			g.key_p1_bomb = false
		}
	} else {
		if g.key_p2_bomb {
			if pl.bomb_count < pl.max_bombs {
				g.drop_bomb(idx)
			}
			g.key_p2_bomb = false
		}
	}

	cur_gx := int((pl.x - f32(grid_offset_x)) / f32(tile_size))
	cur_gy := int((pl.y - f32(grid_offset_y)) / f32(tile_size))

	target_center_x := f32(grid_offset_x + pl.target_gx * tile_size + tile_size / 2)
	target_center_y := f32(grid_offset_y + pl.target_gy * tile_size + tile_size / 2)

	if pl.is_moving {
		step := pl.speed * dt
		if pl.x < target_center_x {
			pl.x = math.min(target_center_x, pl.x + step)
		} else if pl.x > target_center_x {
			pl.x = math.max(target_center_x, pl.x - step)
		}

		if pl.y < target_center_y {
			pl.y = math.min(target_center_y, pl.y + step)
		} else if pl.y > target_center_y {
			pl.y = math.max(target_center_y, pl.y - step)
		}

		if pl.x == target_center_x && pl.y == target_center_y {
			pl.is_moving = false
		}
	}

	if !pl.is_moving {
		mut directions := [][]int{}
		if idx == 0 {
			if g.key_p1_left { directions << [-1, 0] }
			if g.key_p1_right { directions << [1, 0] }
			if g.key_p1_up { directions << [0, -1] }
			if g.key_p1_down { directions << [0, 1] }
		} else {
			if g.key_p2_left { directions << [-1, 0] }
			if g.key_p2_right { directions << [1, 0] }
			if g.key_p2_up { directions << [0, -1] }
			if g.key_p2_down { directions << [0, 1] }
		}

		for dir in directions {
			next_gx := cur_gx + dir[0]
			next_gy := cur_gy + dir[1]
			if g.is_tile_passable(next_gx, next_gy, cur_gx, cur_gy) {
				pl.target_gx = next_gx
				pl.target_gy = next_gy
				pl.is_moving = true
				break
			}
		}
	}
}

fn (g &BombermanGame) would_bomb_hit_tile(bx int, by int, radius int, tx int, ty int) bool {
	if bx == tx && by == ty {
		return true
	}
	if bx == tx {
		min_y := if by < ty { by } else { ty }
		max_y := if by > ty { by } else { ty }
		if max_y - min_y <= radius {
			mut blocked := false
			for check_y in min_y + 1 .. max_y {
				if g.grid[check_y][bx] != .empty {
					blocked = true
					break
				}
			}
			if !blocked {
				return true
			}
		}
	} else if by == ty {
		min_x := if bx < tx { bx } else { tx }
		max_x := if bx > tx { bx } else { tx }
		if max_x - min_x <= radius {
			mut blocked := false
			for check_x in min_x + 1 .. max_x {
				if g.grid[by][check_x] != .empty {
					blocked = true
					break
				}
			}
			if !blocked {
				return true
			}
		}
	}
	return false
}

fn (g &BombermanGame) is_tile_in_danger(gx int, gy int) bool {
	if gx < 0 || gx >= grid_cols || gy < 0 || gy >= grid_rows {
		return true
	}
	for f in g.flames {
		if f.grid_x == gx && f.grid_y == gy {
			return true
		}
	}
	for b in g.bombs {
		if !b.active {
			continue
		}
		if g.would_bomb_hit_tile(b.grid_x, b.grid_y, b.radius, gx, gy) {
			return true
		}
	}
	return false
}

fn (g &BombermanGame) can_escape_bomb_at(bx int, by int, radius int) bool {
	dirs := [[1, 0], [-1, 0], [0, 1], [0, -1]]
	for d1 in dirs {
		n1x := bx + d1[0]
		n1y := by + d1[1]
		if !g.is_tile_passable(n1x, n1y, bx, by) {
			continue
		}
		// Check if step 1 is safe
		if !g.would_bomb_hit_tile(bx, by, radius, n1x, n1y) && !g.is_tile_in_danger(n1x, n1y) {
			return true
		}
		// Check step 2 around corners
		for d2 in dirs {
			n2x := n1x + d2[0]
			n2y := n1y + d2[1]
			if n2x == bx && n2y == by {
				continue
			}
			if g.is_tile_passable(n2x, n2y, n1x, n1y) {
				if !g.would_bomb_hit_tile(bx, by, radius, n2x, n2y) && !g.is_tile_in_danger(n2x, n2y) {
					return true
				}
			}
		}
	}
	return false
}

fn (mut g BombermanGame) update_ai_player(idx int, dt f32) {
	mut pl := &g.players[idx]
	if !pl.active { return }

	if pl.ai_change_timer > 0 {
		pl.ai_change_timer -= dt
	}

	cur_gx := int((pl.x - f32(grid_offset_x)) / f32(tile_size))
	cur_gy := int((pl.y - f32(grid_offset_y)) / f32(tile_size))

	target_center_x := f32(grid_offset_x + pl.target_gx * tile_size + tile_size / 2)
	target_center_y := f32(grid_offset_y + pl.target_gy * tile_size + tile_size / 2)

	if pl.is_moving {
		step := pl.speed * dt
		if pl.x < target_center_x {
			pl.x = math.min(target_center_x, pl.x + step)
		} else if pl.x > target_center_x {
			pl.x = math.max(target_center_x, pl.x - step)
		}

		if pl.y < target_center_y {
			pl.y = math.min(target_center_y, pl.y + step)
		} else if pl.y > target_center_y {
			pl.y = math.max(target_center_y, pl.y - step)
		}

		if pl.x == target_center_x && pl.y == target_center_y {
			pl.is_moving = false
		}
	}

	if !pl.is_moving {
		dirs := [[1, 0], [-1, 0], [0, 1], [0, -1]]
		cur_danger := g.is_tile_in_danger(cur_gx, cur_gy)

		if cur_danger {
			// PRIORITY 1: Flee from danger! Find an immediate safe passable tile
			mut safe_dirs := [][]int{}
			mut passable_dirs := [][]int{}
			for d in dirs {
				nx := cur_gx + d[0]
				ny := cur_gy + d[1]
				if g.is_tile_passable(nx, ny, cur_gx, cur_gy) {
					passable_dirs << d
					if !g.is_tile_in_danger(nx, ny) {
						safe_dirs << d
					}
				}
			}

			if safe_dirs.len > 0 {
				chosen := safe_dirs[rand.intn(safe_dirs.len) or { 0 }]
				pl.target_gx = cur_gx + chosen[0]
				pl.target_gy = cur_gy + chosen[1]
				pl.is_moving = true
				return
			} else if passable_dirs.len > 0 {
				// Step away even if still risky to keep running towards safety
				chosen := passable_dirs[rand.intn(passable_dirs.len) or { 0 }]
				pl.target_gx = cur_gx + chosen[0]
				pl.target_gy = cur_gy + chosen[1]
				pl.is_moving = true
				return
			}
		} else {
			// Not in danger: Consider tactical bomb drop or advancing
			mut should_drop_bomb := false
			p1_gx := int((g.players[0].x - f32(grid_offset_x)) / f32(tile_size))
			p1_gy := int((g.players[0].y - f32(grid_offset_y)) / f32(tile_size))

			if pl.bomb_count < pl.max_bombs && pl.ai_change_timer <= 0 {
				// Condition A: Soft block adjacent
				mut has_adjacent_soft_block := false
				for d in dirs {
					adj_x := cur_gx + d[0]
					adj_y := cur_gy + d[1]
					if adj_x >= 0 && adj_x < grid_cols && adj_y >= 0 && adj_y < grid_rows {
						if g.grid[adj_y][adj_x] == .soft_block {
							has_adjacent_soft_block = true
							break
						}
					}
				}

				// Condition B: Player 1 in line of fire
				p1_in_range := g.would_bomb_hit_tile(cur_gx, cur_gy, pl.flame_radius, p1_gx, p1_gy)

				if (has_adjacent_soft_block || p1_in_range) && g.can_escape_bomb_at(cur_gx, cur_gy, pl.flame_radius) {
					should_drop_bomb = true
				}
			}

			if should_drop_bomb {
				g.drop_bomb(idx)
				pl.ai_change_timer = 2.0
				// Immediately move to an available escape tile
				for d in dirs {
					nx := cur_gx + d[0]
					ny := cur_gy + d[1]
					if g.is_tile_passable(nx, ny, cur_gx, cur_gy) {
						pl.target_gx = nx
						pl.target_gy = ny
						pl.is_moving = true
						return
					}
				}
				return
			}

			// Navigation: Seek powerups or close in on Player 1
			mut target_x := p1_gx
			mut target_y := p1_gy

			// If a powerup is on the board, target the nearest one
			mut min_dist := 9999
			for pu in g.powerups {
				if pu.active {
					dist := math.abs(pu.grid_x - cur_gx) + math.abs(pu.grid_y - cur_gy)
					if dist < min_dist {
						min_dist = dist
						target_x = pu.grid_x
						target_y = pu.grid_y
					}
				}
			}

			mut best_dir := []int{}
			mut best_dist := 99999
			mut safe_moves := [][]int{}

			for d in dirs {
				nx := cur_gx + d[0]
				ny := cur_gy + d[1]
				if g.is_tile_passable(nx, ny, cur_gx, cur_gy) && !g.is_tile_in_danger(nx, ny) {
					safe_moves << d
					dist := math.abs(target_x - nx) + math.abs(target_y - ny)
					if dist < best_dist {
						best_dist = dist
						best_dir = d.clone()
					}
				}
			}

			if best_dir.len > 0 {
				pl.target_gx = cur_gx + best_dir[0]
				pl.target_gy = cur_gy + best_dir[1]
				pl.is_moving = true
			} else if safe_moves.len > 0 {
				chosen := safe_moves[rand.intn(safe_moves.len) or { 0 }]
				pl.target_gx = cur_gx + chosen[0]
				pl.target_gy = cur_gy + chosen[1]
				pl.is_moving = true
			}
		}
	}
}

fn (g &BombermanGame) can_move_to(x f32, y f32) bool {
	return g.can_move_to_with_bomb(x, y, x, y)
}

fn (g &BombermanGame) can_move_to_with_bomb(x f32, y f32, cur_x f32, cur_y f32) bool {
	radius := f32(13.0)
	corners_x := [x - radius, x + radius]
	corners_y := [y - radius, y + radius]

	for cx in corners_x {
		for cy in corners_y {
			gx := int((cx - f32(grid_offset_x)) / f32(tile_size))
			gy := int((cy - f32(grid_offset_y)) / f32(tile_size))

			if gx < 0 || gx >= grid_cols || gy < 0 || gy >= grid_rows {
				return false
			}
			if g.grid[gy][gx] != .empty {
				return false
			}
			for b in g.bombs {
				if b.active && b.grid_x == gx && b.grid_y == gy {
					cur_gx := int((cur_x - f32(grid_offset_x)) / f32(tile_size))
					cur_gy := int((cur_y - f32(grid_offset_y)) / f32(tile_size))
					if cur_gx != gx || cur_gy != gy {
						return false
					}
				}
			}
		}
	}
	return true
}

fn (mut g BombermanGame) drop_bomb(player_idx int) {
	mut pl := &g.players[player_idx]
	gx := int((pl.x - f32(grid_offset_x)) / f32(tile_size))
	gy := int((pl.y - f32(grid_offset_y)) / f32(tile_size))

	// Ensure no duplicate bomb at exact tile
	for b in g.bombs {
		if b.grid_x == gx && b.grid_y == gy && b.active {
			return
		}
	}

	g.bombs << Bomb{
		grid_x: gx
		grid_y: gy
		owner_id: pl.id
		fuse_timer: 2.2
		radius: pl.flame_radius
		active: true
	}
	pl.bomb_count++
	g.sound_mgr.play_bomb_drop_sound()
}

fn (mut g BombermanGame) detonate_bomb(b Bomb) {
	g.sound_mgr.play_explosion_sound()
	g.shake_trauma = f32(math.min(1.0, f64(g.shake_trauma + 0.45)))

	// Replenish player bomb capacity
	for mut pl in g.players {
		if pl.id == b.owner_id && pl.bomb_count > 0 {
			pl.bomb_count--
		}
	}

	// Center explosion flame
	g.add_flame(b.grid_x, b.grid_y)

	// Raycast 4 directions (Up, Down, Left, Right)
	dirs_x := [0, 0, -1, 1]
	dirs_y := [-1, 1, 0, 0]

	for d in 0 .. 4 {
		dx := dirs_x[d]
		dy := dirs_y[d]

		for step in 1 .. b.radius + 1 {
			gx := b.grid_x + dx * step
			gy := b.grid_y + dy * step

			if gx < 0 || gx >= grid_cols || gy < 0 || gy >= grid_rows {
				break
			}

			tile := g.grid[gy][gx]
			if tile == .hard_wall {
				break
			}

			g.add_flame(gx, gy)

			if tile == .soft_block {
				g.grid[gy][gx] = .empty
				// Spawn powerup chance
				if (rand.intn(100) or { 0 }) < 50 {
					p_type := match rand.intn(3) or { 0 } {
						0 { PowerUpType.flame }
						1 { PowerUpType.bomb_cap }
						else { PowerUpType.speed }
					}
					g.powerups << PowerUp{ grid_x: gx, grid_y: gy, power_type: p_type, active: true }
				}
				break
			}
		}
	}
}

fn (mut g BombermanGame) add_flame(gx int, gy int) {
	g.flames << FlameRay{ grid_x: gx, grid_y: gy, timer: 0.5 }

	flame_min_x := f32(grid_offset_x + gx * tile_size)
	flame_max_x := f32(grid_offset_x + (gx + 1) * tile_size)
	flame_min_y := f32(grid_offset_y + gy * tile_size)
	flame_max_y := f32(grid_offset_y + (gy + 1) * tile_size)

	radius := f32(13.0)

	// Check if flame hits any player
	for mut pl in g.players {
		if !pl.active { continue }
		p_min_x := pl.x - radius
		p_max_x := pl.x + radius
		p_min_y := pl.y - radius
		p_max_y := pl.y + radius

		if p_max_x > flame_min_x && p_min_x < flame_max_x && p_max_y > flame_min_y && p_min_y < flame_max_y {
			pl.lives--
			g.sound_mgr.play_hurt_sound()
			if pl.lives <= 0 {
				pl.active = false
			}
		}
	}
}
