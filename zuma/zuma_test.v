module main

fn test_zuma_init() {
	mut g := new_zuma_game()
	assert g.state == .playing
	assert g.score == 0
	assert g.track.len > 0
	assert g.total_track_len > 1000.0
	assert g.balls.len > 0
}

fn test_zuma_swap_ball() {
	mut g := new_zuma_game()
	c1 := g.current_ball
	c2 := g.next_ball

	g.swap_current_ball()
	assert g.current_ball == c2
	assert g.next_ball == c1
}

fn test_zuma_match_3() {
	mut g := new_zuma_game()
	g.balls.clear()

	// 3 Red balls (color 1)
	g.balls << Ball{color: 1, dist: 300.0}
	g.balls << Ball{color: 1, dist: 268.0}
	g.balls << Ball{color: 1, dist: 236.0}

	cleared := g.check_matches_at(1)
	assert cleared == 3
	assert g.balls.len == 0
	assert g.score >= 300
}

fn test_zuma_projectile_launch() {
	mut g := new_zuma_game()
	g.turret_angle = 0.0 // Point right
	ok := g.shoot_ball()
	assert ok == true
	assert g.projectile.active == true
	assert g.projectile.vx > 500.0
}
