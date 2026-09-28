module main

fn test_pong_initialization() {
	game := new_pong_game()
	assert game.score_p1 == 0
	assert game.score_p2 == 0
	assert game.game_over == false
}

fn test_pong_ball_movement() {
	mut game := new_pong_game()
	start_x := game.ball.x
	game.step()
	assert game.ball.x != start_x
}

fn test_pong_paddle_movement() {
	mut game := new_pong_game()
	start_y := game.p1.y
	game.update_p1(true, false) // Move UP
	assert game.p1.y < start_y
}

fn test_pong_winning_condition() {
	mut game := new_pong_game()
	game.score_p1 = winning_score - 1
	game.ball.x = f64(court_w + 10) // Ball past right edge
	game.step()
	assert game.score_p1 == winning_score
	assert game.game_over == true
	assert game.winner_p1 == true
}

fn test_pong_ai_prediction_and_recenter() {
	mut game := new_pong_game()
	game.mode = .pve

	// When ball is moving towards P1 (vx < 0), predict_ball_y should return court center
	game.ball.vx = -6.0
	assert game.predict_ball_y() == f64(court_h / 2)

	// When ball is moving towards P2 (vx > 0), AI should track predicted arrival
	game.ball.x = 200.0
	game.ball.y = 200.0
	game.ball.vx = 8.0
	game.ball.vy = 4.0
	predicted := game.predict_ball_y()
	assert predicted > 100.0 && predicted < f64(court_h - 90)

	// Update AI and ensure p2 moves towards predicted position
	initial_p2_y := game.p2.y
	game.update_p2(false, false)
	// Since ball travels downwards, p2 should adjust its position
	assert game.p2.y != initial_p2_y || game.p2.y + paddle_h / 2.0 == predicted
}
