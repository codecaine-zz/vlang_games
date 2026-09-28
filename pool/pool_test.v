module main

fn test_pool_8ball_rack() {
	mut g := new_pool_game()
	g.rack_8ball()

	assert g.balls.len == 16
	assert g.balls[0].is_cue == true
	assert g.balls[0].id == 0

	// Check 8-ball exists in rack
	mut has_8 := false
	for b in g.balls {
		if b.id == 8 {
			has_8 = true
			assert b.is_eight == true
		}
	}
	assert has_8 == true
}

fn test_pool_9ball_rack() {
	mut g := new_pool_game()
	g.rack_9ball()

	assert g.balls.len == 10 // Cue ball + 9 balls
	assert g.balls[0].is_cue == true

	mut has_9 := false
	for b in g.balls {
		if b.id == 9 {
			has_9 = true
		}
	}
	assert has_9 == true
}

fn test_pool_pockets_initialization() {
	mut g := new_pool_game()
	assert g.pockets.len == 6
	for p in g.pockets {
		assert p.radius > 10.0
	}
}

fn test_8ball_cleared_group_check() {
	mut g := new_pool_game()
	g.rack_8ball()

	// Initially neither solids nor stripes are cleared
	assert g.are_all_group_balls_potted(.solids) == false
	assert g.are_all_group_balls_potted(.stripes) == false

	// Pot all solids
	for mut b in g.balls {
		if b.is_solid && !b.is_cue && !b.is_eight {
			b.potted = true
		}
	}
	assert g.are_all_group_balls_potted(.solids) == true
	assert g.are_all_group_balls_potted(.stripes) == false
}
