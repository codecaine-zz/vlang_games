module main

fn test_jezzball_initialization() {
	mut g := new_jezz_game()
	assert g.level == 1
	assert g.lives == 3
	assert g.balls.len == 2
	assert g.grid.len == grid_rows
	assert g.grid[0].len == grid_cols
	// Perimeter should be 1
	assert g.grid[0][0] == 1
	assert g.grid[grid_rows - 1][grid_cols - 1] == 1
	// Interior should be 0
	assert g.grid[10][10] == 0
}

fn test_jezzball_wall_orientation_toggle() {
	mut g := new_jezz_game()
	assert g.orient == .horizontal
	g.toggle_orientation()
	assert g.orient == .vertical
	g.toggle_orientation()
	assert g.orient == .horizontal
}

fn test_jezzball_wall_start() {
	mut g := new_jezz_game()
	started := g.start_wall(arena_w / 2, arena_h / 2)
	assert started
	assert g.wall.active
	assert g.wall.start_gx == (arena_w / 2) / cell_size
	assert g.wall.start_gy == (arena_h / 2) / cell_size
}

fn test_jezzball_ball_physics() {
	mut g := new_jezz_game()
	b := g.balls[0]
	init_x := b.x
	init_y := b.y

	for _ in 0 .. 20 {
		g.update(0.016)
	}

	b_after := g.balls[0]
	assert b_after.x != init_x || b_after.y != init_y
}

fn test_jezzball_wall_completion_and_flood_fill() {
	mut g := new_jezz_game()
	// Place balls in the bottom half
	for mut b in g.balls {
		b.x = 200.0
		b.y = f64(arena_h - 80)
		b.vx = 0.0
		b.vy = 0.0
	}

	// Start a horizontal wall across the middle
	g.orient = .horizontal
	g.start_wall(arena_w / 2, arena_h / 2)

	// Step simulation until wall builds to both edges
	for _ in 0 .. 120 {
		g.update(0.02)
	}

	assert !g.wall.active
	// Cleared percentage should have increased significantly because top half has no balls!
	assert g.cleared_pct > 30.0
}
