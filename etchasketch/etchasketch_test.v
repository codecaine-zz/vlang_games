module main

fn test_etch_initial_state() {
	mut g := new_etch_game()
	assert g.pen_x > 0
	assert g.pen_y > 0
	assert g.points.len >= 1
	assert g.stencils.len >= 5
}

fn test_etch_movement() {
	mut g := new_etch_game()
	init_x := g.pen_x
	init_y := g.pen_y
	moved := g.move_pen(10.0, 5.0)
	assert moved
	assert g.pen_x == init_x + 10.0
	assert g.pen_y == init_y + 5.0
	assert g.points.len >= 2
	assert g.total_distance >= 10.0
}

fn test_etch_bounds_clamping() {
	mut g := new_etch_game()
	g.move_pen(1000.0, 1000.0)
	assert g.pen_x <= f64(g.screen_w)
	assert g.pen_y <= f64(g.screen_h)

	g.move_pen(-2000.0, -2000.0)
	assert g.pen_x >= 4.0
	assert g.pen_y >= 4.0
}

fn test_etch_shake_erase() {
	mut g := new_etch_game()
	g.move_pen(20.0, 30.0)
	g.move_pen(15.0, -10.0)
	assert g.points.len > 2

	g.trigger_shake()
	assert g.is_shaking
	assert g.particles.len > 100

	// Advance shake until complete
	for _ in 0 .. 60 {
		g.update(0.02)
	}

	assert !g.is_shaking
	assert g.points.len == 1
}

fn test_etch_spirograph() {
	mut g := new_etch_game()
	g.tool_mode = .spirograph
	g.spiro.running = true
	init_points := g.points.len

	for _ in 0 .. 10 {
		g.update(0.016)
	}

	assert g.points.len > init_points
	assert g.spiro.theta > 0
}

fn test_etch_stencils() {
	mut g := new_etch_game()
	g.tool_mode = .stencil
	g.current_stencil = 0
	st := g.stencils[0]
	assert st.points.len > 0

	// Draw along stencil points
	for p in st.points {
		target_x := p.x * f64(g.screen_w)
		target_y := p.y * f64(g.screen_h)
		dx := target_x - g.pen_x
		dy := target_y - g.pen_y
		g.move_pen(dx, dy)
	}

	assert g.stencil_score > 50.0
	assert g.stencil_stars >= 1
}
