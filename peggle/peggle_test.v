module main

fn test_peggle_initialization() {
	mut g := new_peggle_game()
	assert g.balls_left == 10
	assert g.pegs.len > 40
	assert g.orange_left > 0
	assert !g.is_fever
	assert !g.is_game_over
}

fn test_peggle_cannon_shooting_and_physics() {
	mut g := new_peggle_game()
	assert g.shoot_ball()
	assert g.balls_left == 9
	assert g.active_balls.len == 1
	assert g.active_balls[0].active

	// Advance physics
	g.update(0.1)
	assert g.active_balls[0].y > 45.0
}

fn test_peggle_extreme_fever() {
	mut g := new_peggle_game()
	g.orange_left = 1

	// Hit last orange peg
	g.pegs[0].ptype = .orange
	g.active_balls << Ball{
		x: g.pegs[0].x
		y: g.pegs[0].y - 12.0
		vx: 0
		vy: 150.0
		active: true
	}
	g.update(0.05)

	assert g.is_fever
	assert g.is_win
}
