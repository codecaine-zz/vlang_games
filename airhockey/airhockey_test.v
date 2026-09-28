module main

fn test_airhockey_init() {
	mut g := new_airhockey_game(false)
	assert g.score_p1 == 0
	assert g.score_p2 == 0
	assert g.max_score == 7
	assert g.puck.radius == 16.0
	assert g.p1_mallet.radius == 28.0
}

fn test_airhockey_physics_step() {
	mut g := new_airhockey_game(false)
	g.puck.x = 200.0
	g.puck.y = 200.0
	g.puck.vx = 100.0
	g.puck.vy = 50.0

	g.update(0.016, 200.0, 200.0, 700.0, 200.0)

	// Puck should have moved according to velocity
	assert g.puck.x > 200.0
	assert g.puck.y > 200.0
}

fn test_airhockey_scoring() {
	mut g := new_airhockey_game(false)
	// Place puck directly crossing right goal line within goal mouth
	cy := g.table_y + g.table_h / 2.0
	g.puck.x = g.table_x + g.table_w + 5.0
	g.puck.y = cy
	g.puck.vx = 200.0

	g.update(0.016, 100.0, cy, 700.0, cy)

	assert g.score_p1 == 1
	assert g.state == .goal_celebration
}
