module main

import math
import rand

pub const grid_rows = 13
pub const grid_cols = 8
pub const bubble_radius = 18.0
pub const bubble_diameter = 36.0
pub const row_height = 31.1769145362 // bubble_diameter * sin(60 deg)

pub enum GameState {
	ready
	aiming
	shooting
	dropping
	won
	game_over
}

pub struct FallingBubble {
pub mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	color int
}

pub struct Projectile {
pub mut:
	x      f64
	y      f64
	vx     f64
	vy     f64
	color  int
	active bool
}

pub struct BubbleShooterGame {
pub mut:
	grid           [][]int // 0 = empty, 1..6 = colors
	state          GameState = .aiming
	score          int
	high_score     int       = 10000
	shots_fired    int
	missed_shots   int
	miss_limit     int       = 5
	aim_angle      f64       = math.pi / 2.0 // straight up
	current_color  int       = 1
	next_color     int       = 2
	projectile     Projectile
	falling        []FallingBubble
	arena_x        f64       = 200.0
	arena_y        f64       = 60.0
	arena_w        f64       = 288.0 // 8 * 36
	arena_h        f64       = 500.0
	danger_y       f64       = 480.0
	shake_trauma   f64
}

pub fn new_bubbleshooter_game() BubbleShooterGame {
	mut g := BubbleShooterGame{}
	g.reset_game()
	return g
}

pub fn (mut g BubbleShooterGame) reset_game() {
	g.grid = [][]int{len: grid_rows, init: []int{len: grid_cols, init: 0}}
	g.state = .aiming
	g.score = 0
	g.shots_fired = 0
	g.missed_shots = 0
	g.shake_trauma = 0.0
	g.aim_angle = math.pi / 2.0
	g.falling.clear()
	g.projectile.active = false

	// Populate top 5 rows with random colors
	for r in 0 .. 5 {
		max_c := if r % 2 == 0 { grid_cols } else { grid_cols - 1 }
		for c in 0 .. max_c {
			g.grid[r][c] = (rand.intn(5) or { 0 }) + 1
		}
	}

	g.current_color = g.get_random_active_color()
	g.next_color = g.get_random_active_color()
}

pub fn (g &BubbleShooterGame) get_random_active_color() int {
	mut colors := []int{}
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			col := g.grid[r][c]
			if col > 0 && !colors.contains(col) {
				colors << col
			}
		}
	}
	if colors.len == 0 {
		return (rand.intn(5) or { 0 }) + 1
	}
	return colors[rand.intn(colors.len) or { 0 }]
}

pub fn (g &BubbleShooterGame) get_bubble_pos(r int, c int) (f64, f64) {
	is_odd := (r % 2) != 0
	offset_x := if is_odd { bubble_radius } else { 0.0 }
	bx := g.arena_x + offset_x + f64(c) * bubble_diameter + bubble_radius
	by := g.arena_y + f64(r) * row_height + bubble_radius
	return bx, by
}

pub fn (mut g BubbleShooterGame) shoot() bool {
	if g.state != .aiming || g.projectile.active {
		return false
	}
	speed := 750.0
	launcher_x := g.arena_x + g.arena_w / 2.0
	launcher_y := g.arena_y + g.arena_h - 30.0

	g.projectile = Projectile{
		x:      launcher_x
		y:      launcher_y
		vx:     math.cos(g.aim_angle) * speed
		vy:     -math.sin(g.aim_angle) * speed
		color:  g.current_color
		active: true
	}
	g.state = .shooting
	g.shots_fired++
	return true
}

pub struct UpdateEvents {
pub mut:
	shot_fired   bool
	bounced      bool
	popped_count int
	dropped_count int
	won          bool
	game_over    bool
}

pub fn (mut g BubbleShooterGame) update(dt f64) UpdateEvents {
	mut ev := UpdateEvents{}

	if g.shake_trauma > 0.0 {
		g.shake_trauma = math.max(0.0, g.shake_trauma - dt * 2.2)
	}

	// Update falling bubbles
	if g.falling.len > 0 {
		for mut fb in g.falling {
			fb.x += fb.vx * dt
			fb.y += fb.vy * dt
			fb.vy += 800.0 * dt // gravity
		}
		// Filter out bubbles that left bottom of screen
		mut remaining := []FallingBubble{}
		for fb in g.falling {
			if fb.y < g.arena_y + g.arena_h + 100.0 {
				remaining << fb
			}
		}
		g.falling = remaining.clone()
	}

	if g.state != .shooting || !g.projectile.active {
		return ev
	}

	g.projectile.x += g.projectile.vx * dt
	g.projectile.y += g.projectile.vy * dt

	// Bounce off left / right walls
	if g.projectile.x - bubble_radius <= g.arena_x {
		g.projectile.x = g.arena_x + bubble_radius
		g.projectile.vx = -g.projectile.vx
		ev.bounced = true
	} else if g.projectile.x + bubble_radius >= g.arena_x + g.arena_w {
		g.projectile.x = g.arena_x + g.arena_w - bubble_radius
		g.projectile.vx = -g.projectile.vx
		ev.bounced = true
	}

	// Collision with top ceiling or existing bubbles
	mut collided := false
	if g.projectile.y - bubble_radius <= g.arena_y {
		collided = true
	} else {
		// Check distance to all existing bubbles
		for r in 0 .. grid_rows {
			max_c := if r % 2 == 0 { grid_cols } else { grid_cols - 1 }
			for c in 0 .. max_c {
				if g.grid[r][c] > 0 {
					bx, by := g.get_bubble_pos(r, c)
					dist_sq := (g.projectile.x - bx) * (g.projectile.x - bx) + (g.projectile.y - by) * (g.projectile.y - by)
					if dist_sq <= (bubble_diameter * 0.92) * (bubble_diameter * 0.92) {
						collided = true
						break
					}
				}
			}
			if collided {
				break
			}
		}
	}

	if collided {
		g.projectile.active = false
		target_r, target_c := g.find_closest_empty_slot(g.projectile.x, g.projectile.y)
		if target_r >= 0 && target_r < grid_rows && target_c >= 0 && target_c < grid_cols {
			g.grid[target_r][target_c] = g.projectile.color

			// Check match-3 cluster
			cluster := g.find_color_cluster(target_r, target_c, g.projectile.color)
			if cluster.len >= 3 {
				// Pop cluster
				for pos in cluster {
					g.grid[pos[0]][pos[1]] = 0
				}
				g.score += cluster.len * 100
				g.shake_trauma = math.min(1.0, g.shake_trauma + 0.15 + f64(cluster.len) * 0.03)
				ev.popped_count = cluster.len

				// Check floating detached bubbles
				floating := g.find_floating_bubbles()
				if floating.len > 0 {
					for pos in floating {
						col := g.grid[pos[0]][pos[1]]
						g.grid[pos[0]][pos[1]] = 0
						bx, by := g.get_bubble_pos(pos[0], pos[1])
						g.falling << FallingBubble{
							x:     bx
							y:     by
							vx:    f64(rand.intn(120) or { 60 }) - 60.0
							vy:    -50.0 - f64(rand.intn(80) or { 40 })
							color: col
						}
					}
					g.score += floating.len * 250
					g.shake_trauma = math.min(1.0, g.shake_trauma + 0.25 + f64(floating.len) * 0.04)
					ev.dropped_count = floating.len
				}
			} else {
				g.missed_shots++
				if g.missed_shots >= g.miss_limit {
					g.missed_shots = 0
					g.shift_ceiling_down()
				}
			}

			// Check Win condition (board empty)
			mut remaining_count := 0
			for r in 0 .. grid_rows {
				for c in 0 .. grid_cols {
					if g.grid[r][c] > 0 {
						remaining_count++
					}
				}
			}

			if remaining_count == 0 {
				g.state = .won
				ev.won = true
				g.score += 5000
				g.shake_trauma = math.min(1.0, g.shake_trauma + 0.45)
				if g.score > g.high_score {
					g.high_score = g.score
				}
				return ev
			}

			// Check Game Over condition (any bubble past danger line)
			for r in 0 .. grid_rows {
				max_c := if r % 2 == 0 { grid_cols } else { grid_cols - 1 }
				for c in 0 .. max_c {
					if g.grid[r][c] > 0 {
						_, by := g.get_bubble_pos(r, c)
						if by + bubble_radius >= g.danger_y {
							g.state = .game_over
							ev.game_over = true
							g.shake_trauma = math.min(1.0, g.shake_trauma + 0.50)
							if g.score > g.high_score {
								g.high_score = g.score
							}
							return ev
						}
					}
				}
			}

			// Prepare next shot
			g.current_color = g.next_color
			g.next_color = g.get_random_active_color()
			g.state = .aiming
		} else {
			// Fallback: game over if no slot
			g.state = .game_over
			ev.game_over = true
		}
	}

	return ev
}

pub fn (g &BubbleShooterGame) find_closest_empty_slot(px f64, py f64) (int, int) {
	mut best_r := -1
	mut best_c := -1
	mut min_dist_sq := 1e9

	for r in 0 .. grid_rows {
		max_c := if r % 2 == 0 { grid_cols } else { grid_cols - 1 }
		for c in 0 .. max_c {
			if g.grid[r][c] == 0 {
				bx, by := g.get_bubble_pos(r, c)
				dist_sq := (px - bx) * (px - bx) + (py - by) * (py - by)
				if dist_sq < min_dist_sq {
					min_dist_sq = dist_sq
					best_r = r
					best_c = c
				}
			}
		}
	}
	return best_r, best_c
}

pub fn (g &BubbleShooterGame) get_neighbors(r int, c int) [][]int {
	mut neighbors := [][]int{}
	is_odd := (r % 2) != 0

	// Hexagonal offsets
	offsets := if is_odd {
		[[-1, 0], [-1, 1], [0, -1], [0, 1], [1, 0], [1, 1]]
	} else {
		[[-1, -1], [-1, 0], [0, -1], [0, 1], [1, -1], [1, 0]]
	}

	for off in offsets {
		nr := r + off[0]
		nc := c + off[1]
		if nr >= 0 && nr < grid_rows {
			max_c := if nr % 2 == 0 { grid_cols } else { grid_cols - 1 }
			if nc >= 0 && nc < max_c {
				neighbors << [nr, nc]
			}
		}
	}
	return neighbors
}

pub fn (g &BubbleShooterGame) find_color_cluster(start_r int, start_c int, color int) [][]int {
	mut cluster := [][]int{}
	mut visited := [][]bool{len: grid_rows, init: []bool{len: grid_cols, init: false}}
	mut queue := [[start_r, start_c]]
	visited[start_r][start_c] = true

	for queue.len > 0 {
		pos := queue[0]
		queue.delete(0)
		r := pos[0]
		c := pos[1]
		cluster << [r, c]

		for n in g.get_neighbors(r, c) {
			nr := n[0]
			nc := n[1]
			if !visited[nr][nc] && g.grid[nr][nc] == color {
				visited[nr][nc] = true
				queue << [nr, nc]
			}
		}
	}
	return cluster
}

pub fn (g &BubbleShooterGame) find_floating_bubbles() [][]int {
	mut connected := [][]bool{len: grid_rows, init: []bool{len: grid_cols, init: false}}
	mut queue := [][]int{}

	// Root from top row (r = 0)
	for c in 0 .. grid_cols {
		if g.grid[0][c] > 0 {
			connected[0][c] = true
			queue << [0, c]
		}
	}

	for queue.len > 0 {
		pos := queue[0]
		queue.delete(0)
		r := pos[0]
		c := pos[1]

		for n in g.get_neighbors(r, c) {
			nr := n[0]
			nc := n[1]
			if !connected[nr][nc] && g.grid[nr][nc] > 0 {
				connected[nr][nc] = true
				queue << [nr, nc]
			}
		}
	}

	mut floating := [][]int{}
	for r in 0 .. grid_rows {
		max_c := if r % 2 == 0 { grid_cols } else { grid_cols - 1 }
		for c in 0 .. max_c {
			if g.grid[r][c] > 0 && !connected[r][c] {
				floating << [r, c]
			}
		}
	}
	return floating
}

pub fn (mut g BubbleShooterGame) shift_ceiling_down() {
	g.shake_trauma = math.min(1.0, g.shake_trauma + 0.30)
	// Shift all rows down by 1
	for r := grid_rows - 1; r > 0; r-- {
		g.grid[r] = g.grid[r - 1].clone()
	}
	// Spawn new top row
	g.grid[0] = []int{len: grid_cols, init: 0}
	for c in 0 .. grid_cols {
		g.grid[0][c] = (rand.intn(5) or { 0 }) + 1
	}
}
