module main

fn test_ragdoll_initialization() {
	mut game := new_ragdoll_game()
	assert game.ragdolls.len > 0
	r := game.ragdolls[0]
	assert r.points.len == 11
	assert r.constraints.len > 8
	assert game.obstacles.len > 0
}

fn test_verlet_physics_step() {
	mut game := new_ragdoll_game()
	initial_y := game.ragdolls[0].points[0].y
	game.update(0.016, 400, 300, false, false)
	new_y := game.ragdolls[0].points[0].y
	assert new_y > initial_y
}

fn test_distance_constraint_solver() {
	mut game := new_ragdoll_game()
	r := game.ragdolls[0]
	c := r.constraints[0]
	p1 := r.points[c.p1_idx]
	p2 := r.points[c.p2_idx]
	dx := p1.x - p2.x
	dy := p1.y - p2.y
	dist := (dx * dx + dy * dy)
	assert dist > 0
}

fn test_arena_switching() {
	mut game := new_ragdoll_game()
	assert game.active_arena == .funhouse

	game.load_arena(.staircase)
	assert game.active_arena == .staircase
	assert game.ragdolls.len == 2

	game.load_arena(.zero_g)
	assert game.active_arena == .zero_g
	assert game.gravity == 120.0
}

fn test_prop_spawning() {
	mut game := new_ragdoll_game()
	initial_props := game.props.len
	game.spawn_prop_at(200.0, 200.0, 'barrel')
	assert game.props.len == initial_props + 1
	assert game.props[game.props.len - 1].prop_type == 'barrel'
}

fn test_shockwave_blast() {
	mut game := new_ragdoll_game()
	p_initial_x := game.ragdolls[0].points[0].x
	game.trigger_shockwave(p_initial_x - 50.0, game.ragdolls[0].points[0].y, 150.0, 1000.0)
	game.update(0.016, 400, 300, false, false)
	p_new_x := game.ragdolls[0].points[0].x
	assert p_new_x > p_initial_x
}
