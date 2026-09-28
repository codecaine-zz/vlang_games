module main

import math
import rand

pub const grid_cols = 64
pub const grid_rows = 40
pub const cell_size = 12
pub const arena_w = grid_cols * cell_size
pub const arena_h = grid_rows * cell_size

pub enum WallOrientation {
	horizontal
	vertical
}

pub struct Point {
pub mut:
	x f64
	y f64
}

pub struct Ball {
pub mut:
	x       f64
	y       f64
	vx      f64
	vy      f64
	radius  f64 = 6.0
	is_blue bool
	trail   []Point
}

pub struct ActiveWall {
pub mut:
	active   bool
	orient   WallOrientation
	start_gx int
	start_gy int
	// Current pixel extents
	pos_len  f64
	neg_len  f64
	pos_done bool
	neg_done bool
}

pub struct CaptureParticle {
pub mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	life  f64
	max_l f64
	col   Color
}

pub struct JezzGame {
pub mut:
	level        int = 1
	lives        int = 3
	score        int
	target_pct   f64 = 75.0
	cleared_pct  f64

	// Grid: 0=open, 1=perimeter border, 2=solid wall, 3=captured filled
	grid         [][]u8

	// Kinetic Balls
	balls        []Ball

	// Wall placement
	orient       WallOrientation = .horizontal
	wall         ActiveWall

	// Visual particles
	particles    []CaptureParticle

	// State
	is_won       bool
	is_game_over bool
	time_elapsed f64
	sound_event  string
	banner_text  string
	banner_timer f64
}

pub fn new_jezz_game() JezzGame {
	mut g := JezzGame{}
	g.init_level(1)
	return g
}

pub fn (mut g JezzGame) init_level(lvl int) {
	g.level = lvl
	g.cleared_pct = 0.0
	g.is_won = false
	g.is_game_over = false
	g.time_elapsed = 0.0
	g.wall.active = false
	g.particles.clear()
	g.sound_event = ''
	g.banner_text = 'LEVEL ${lvl} - TARGET: 75% CONTAINMENT'
	g.banner_timer = 2.5

	// Init grid
	g.grid = [][]u8{len: grid_rows, init: []u8{len: grid_cols, init: 0}}
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			if r == 0 || r == grid_rows - 1 || c == 0 || c == grid_cols - 1 {
				g.grid[r][c] = 1 // Perimeter
			} else {
				g.grid[r][c] = 0 // Open space
			}
		}
	}

	// Spawn Balls (Level 1 = 2 balls, Level 2 = 3 balls, etc.)
	ball_count := lvl + 1
	g.balls.clear()

	base_speed := 130.0 + f64(lvl) * 15.0

	for i in 0 .. ball_count {
		bx := 60.0 + rand.f64() * (f64(arena_w) - 120.0)
		by := 60.0 + rand.f64() * (f64(arena_h) - 120.0)
		angle := rand.f64() * 2.0 * math.pi
		vx := math.cos(angle) * base_speed
		vy := math.sin(angle) * base_speed

		g.balls << Ball{
			x: bx
			y: by
			vx: vx
			vy: vy
			is_blue: i % 2 == 0
		}
	}
}

pub fn (mut g JezzGame) toggle_orientation() {
	g.orient = match g.orient {
		.horizontal { WallOrientation.vertical }
		.vertical { WallOrientation.horizontal }
	}
}

pub fn (mut g JezzGame) start_wall(pixel_x int, pixel_y int) bool {
	if g.wall.active || g.is_won || g.is_game_over {
		return false
	}

	gx := pixel_x / cell_size
	gy := pixel_y / cell_size

	if gx <= 0 || gx >= grid_cols - 1 || gy <= 0 || gy >= grid_rows - 1 {
		return false
	}

	if g.grid[gy][gx] != 0 {
		return false
	}

	g.wall = ActiveWall{
		active: true
		orient: g.orient
		start_gx: gx
		start_gy: gy
		pos_len: 0.0
		neg_len: 0.0
		pos_done: false
		neg_done: false
	}

	g.sound_event = 'wall_build'
	return true
}

pub fn (mut g JezzGame) update(dt f64) {
	g.sound_event = ''
	g.time_elapsed += dt
	if g.banner_timer > 0.0 {
		g.banner_timer -= dt
	}

	// 1. Update Active Wall Expansion
	if g.wall.active {
		build_speed := 280.0 * dt

		// Positive direction
		if !g.wall.pos_done {
			g.wall.pos_len += build_speed
			cx, cy := g.get_wall_head_cell(true)
			if cx < 0 || cx >= grid_cols || cy < 0 || cy >= grid_rows || g.grid[cy][cx] != 0 {
				g.wall.pos_done = true
			}
		}

		// Negative direction
		if !g.wall.neg_done {
			g.wall.neg_len += build_speed
			cx, cy := g.get_wall_head_cell(false)
			if cx < 0 || cx >= grid_cols || cy < 0 || cy >= grid_rows || g.grid[cy][cx] != 0 {
				g.wall.neg_done = true
			}
		}

		// Check if wall completed on both sides!
		if g.wall.pos_done && g.wall.neg_done {
			g.commit_wall_and_capture()
		}
	}

	// 2. Update Balls & Collision
	for mut b in g.balls {
		// Update position
		b.x += b.vx * dt
		b.y += b.vy * dt

		// Trail
		b.trail << Point{
			x: b.x
			y: b.y
		}
		if b.trail.len > 8 {
			b.trail.delete(0)
		}

		// Bounce against solid grid cells
		g.bounce_ball_against_grid(mut b)

		// Check collision with expanding active wall
		if g.wall.active {
			if g.check_ball_wall_collision(b) {
				// Wall shattered!
				g.wall.active = false
				g.lives--
				g.sound_event = 'wall_shatter'
				g.banner_text = 'WALL SHATTERED! -1 LIFE'
				g.banner_timer = 2.0
				g.spawn_shatter_particles(b.x, b.y)

				if g.lives <= 0 {
					g.is_game_over = true
					g.sound_event = 'lose'
					g.banner_text = 'CONTAINMENT BREACH - GAME OVER!'
					g.banner_timer = 5.0
				}
				break
			}
		}
	}

	// 3. Update Particles
	g.update_particles(dt)
}

fn (g JezzGame) get_wall_head_cell(is_pos bool) (int, int) {
	if g.wall.orient == .horizontal {
		length := if is_pos { g.wall.pos_len } else { -g.wall.neg_len }
		head_px := f64(g.wall.start_gx * cell_size + cell_size / 2) + length
		return int(head_px / f64(cell_size)), g.wall.start_gy
	} else {
		length := if is_pos { g.wall.pos_len } else { -g.wall.neg_len }
		head_py := f64(g.wall.start_gy * cell_size + cell_size / 2) + length
		return g.wall.start_gx, int(head_py / f64(cell_size))
	}
}

fn (g JezzGame) check_ball_wall_collision(b Ball) bool {
	orig_x := f64(g.wall.start_gx * cell_size + cell_size / 2)
	orig_y := f64(g.wall.start_gy * cell_size + cell_size / 2)

	if g.wall.orient == .horizontal {
		min_x := orig_x - g.wall.neg_len
		max_x := orig_x + g.wall.pos_len

		if b.x >= min_x - b.radius && b.x <= max_x + b.radius {
			if math.abs(b.y - orig_y) <= b.radius + f64(cell_size) / 2.0 {
				return true
			}
		}
	} else {
		min_y := orig_y - g.wall.neg_len
		max_y := orig_y + g.wall.pos_len

		if b.y >= min_y - b.radius && b.y <= max_y + b.radius {
			if math.abs(b.x - orig_x) <= b.radius + f64(cell_size) / 2.0 {
				return true
			}
		}
	}
	return false
}

fn (mut g JezzGame) bounce_ball_against_grid(mut b Ball) {
	r := b.radius
	left_c := int((b.x - r) / f64(cell_size))
	right_c := int((b.x + r) / f64(cell_size))
	top_r := int((b.y - r) / f64(cell_size))
	bottom_r := int((b.y + r) / f64(cell_size))
	mid_c := int(b.x / f64(cell_size))
	mid_r := int(b.y / f64(cell_size))

	// Left wall bounce
	if left_c >= 0 && mid_r >= 0 && mid_r < grid_rows && g.grid[mid_r][left_c] != 0 {
		b.vx = math.abs(b.vx)
		b.x = f64(left_c + 1) * f64(cell_size) + r
		g.sound_event = 'bounce'
	}
	// Right wall bounce
	if right_c < grid_cols && mid_r >= 0 && mid_r < grid_rows && g.grid[mid_r][right_c] != 0 {
		b.vx = -math.abs(b.vx)
		b.x = f64(right_c) * f64(cell_size) - r
		g.sound_event = 'bounce'
	}
	// Top wall bounce
	if top_r >= 0 && mid_c >= 0 && mid_c < grid_cols && g.grid[top_r][mid_c] != 0 {
		b.vy = math.abs(b.vy)
		b.y = f64(top_r + 1) * f64(cell_size) + r
		g.sound_event = 'bounce'
	}
	// Bottom wall bounce
	if bottom_r < grid_rows && mid_c >= 0 && mid_c < grid_cols && g.grid[bottom_r][mid_c] != 0 {
		b.vy = -math.abs(b.vy)
		b.y = f64(bottom_r) * f64(cell_size) - r
		g.sound_event = 'bounce'
	}
}

fn (mut g JezzGame) commit_wall_and_capture() {
	orig_gx := g.wall.start_gx
	orig_gy := g.wall.start_gy

	// 1. Solidify Wall on Grid
	if g.wall.orient == .horizontal {
		min_c := int(math.max(0.0, (f64(orig_gx * cell_size) - g.wall.neg_len) / f64(cell_size)))
		max_c := int(math.min(f64(grid_cols - 1), (f64(orig_gx * cell_size) + g.wall.pos_len) / f64(cell_size)))
		for c in min_c .. max_c + 1 {
			if g.grid[orig_gy][c] == 0 {
				g.grid[orig_gy][c] = 2 // Solid wall
			}
		}
	} else {
		min_r := int(math.max(0.0, (f64(orig_gy * cell_size) - g.wall.neg_len) / f64(cell_size)))
		max_r := int(math.min(f64(grid_rows - 1), (f64(orig_gy * cell_size) + g.wall.pos_len) / f64(cell_size)))
		for r in min_r .. max_r + 1 {
			if g.grid[r][orig_gx] == 0 {
				g.grid[r][orig_gx] = 2 // Solid wall
			}
		}
	}

	g.wall.active = false
	g.sound_event = 'wall_lock'

	// 2. Connected Component Flood Fill from Ball Positions
	mut visited := [][]bool{len: grid_rows, init: []bool{len: grid_cols, init: false}}
	mut queue := []int{}

	// Seed BFS with ball locations
	for b in g.balls {
		bc := int(math.clamp(b.x / f64(cell_size), 0.0, f64(grid_cols - 1)))
		br := int(math.clamp(b.y / f64(cell_size), 0.0, f64(grid_rows - 1)))
		if g.grid[br][bc] == 0 && !visited[br][bc] {
			visited[br][bc] = true
			queue << br * grid_cols + bc
		}
	}

	// BFS expansion
	mut q_idx := 0
	for q_idx < queue.len {
		cur := queue[q_idx]
		q_idx++
		cr := cur / grid_cols
		cc := cur % grid_cols

		dr := [-1, 1, 0, 0]
		dc := [0, 0, -1, 1]

		for i in 0 .. 4 {
			nr := cr + dr[i]
			nc := cc + dc[i]
			if nr >= 0 && nr < grid_rows && nc >= 0 && nc < grid_cols {
				if g.grid[nr][nc] == 0 && !visited[nr][nc] {
					visited[nr][nc] = true
					queue << nr * grid_cols + nc
				}
			}
		}
	}

	// 3. Any open cell NOT visited by balls is isolated & captured!
	mut newly_captured := 0
	for r in 1 .. grid_rows - 1 {
		for c in 1 .. grid_cols - 1 {
			if g.grid[r][c] == 0 && !visited[r][c] {
				g.grid[r][c] = 3 // Captured!
				newly_captured++
				if rand.int_in_range(0, 10) or { 0 } == 0 {
					g.spawn_capture_particles(f64(c * cell_size + 6), f64(r * cell_size + 6))
				}
			}
		}
	}

	if newly_captured > 0 {
		g.sound_event = 'capture'
		g.score += newly_captured * 25
	}

	// 4. Calculate Percentage Cleared
	mut total_playable := 0
	mut total_cleared := 0
	for r in 1 .. grid_rows - 1 {
		for c in 1 .. grid_cols - 1 {
			total_playable++
			if g.grid[r][c] != 0 {
				total_cleared++
			}
		}
	}

	g.cleared_pct = (f64(total_cleared) / f64(total_playable)) * 100.0

	// 5. Check Win Condition
	if g.cleared_pct >= g.target_pct && !g.is_won {
		g.is_won = true
		g.sound_event = 'win'
		bonus := int((g.cleared_pct - g.target_pct) * 100.0) * 50 + g.lives * 1000
		g.score += bonus
		g.banner_text = 'CONTAINMENT SUCCESSFUL! LEVEL COMPLETE (+${bonus} PTS)'
		g.banner_timer = 4.0
	}
}

fn (mut g JezzGame) spawn_shatter_particles(x f64, y f64) {
	for _ in 0 .. 25 {
		g.particles << CaptureParticle{
			x: x
			y: y
			vx: (rand.f64() * 2.0 - 1.0) * 140.0
			vy: (rand.f64() * 2.0 - 1.0) * 140.0
			life: 0.0
			max_l: 0.4 + rand.f64() * 0.3
			col: Color{255, 60, 60, 255}
		}
	}
}

fn (mut g JezzGame) spawn_capture_particles(x f64, y f64) {
	g.particles << CaptureParticle{
		x: x
		y: y
		vx: (rand.f64() * 2.0 - 1.0) * 60.0
		vy: (rand.f64() * 2.0 - 1.0) * 60.0
		life: 0.0
		max_l: 0.5 + rand.f64() * 0.4
		col: Color{0, 220, 255, 255}
	}
}

fn (mut g JezzGame) update_particles(dt f64) {
	for i := g.particles.len - 1; i >= 0; i-- {
		mut p := g.particles[i]
		p.life += dt
		p.x += p.vx * dt
		p.y += p.vy * dt
		if p.life >= p.max_l {
			g.particles.delete(i)
		} else {
			g.particles[i] = p
		}
	}
}
