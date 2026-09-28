module main

fn test_breakout_initialization() {
	game := new_breakout_game()
	assert game.lives == 3
	assert game.score == 0
	assert game.level == 1
	assert game.game_over == false
	assert game.bricks.len > 0
	assert game.balls.len == 1
	assert game.balls[0].attached == true
}

fn test_level_loading() {
	mut game := new_breakout_game()
	game.load_level(2)
	assert game.level == 1 // game.level state stays, load_level loads brick map
	assert game.bricks.len > 0
}

fn test_ball_launch() {
	mut game := new_breakout_game()
	assert game.balls[0].attached == true
	game.launch_balls()
	assert game.balls[0].attached == false
	assert game.balls[0].dx != 0.0
	assert game.balls[0].dy < 0.0
}

fn test_brick_damage() {
	mut game := new_breakout_game()
	initial_bricks := game.bricks.len
	assert initial_bricks > 0
	game.damage_brick(0, 1)
	assert game.score > 0 || game.bricks[0].hp < game.bricks[0].max_hp
}

fn test_powerup_application() {
	mut game := new_breakout_game()
	game.apply_powerup(.multiball)
	assert game.balls.len == 3

	game.apply_powerup(.expand_paddle)
	assert game.paddle.w > game.paddle.base_w
	assert game.paddle.expand_timer == 12.0

	game.apply_powerup(.laser_paddle)
	assert game.paddle.has_lasers == true

	game.apply_powerup(.bottom_shield)
	assert game.bottom_shield_active == true
}

fn test_laser_firing() {
	mut game := new_breakout_game()
	game.apply_powerup(.laser_paddle)
	assert game.lasers.len == 0
	game.fire_lasers()
	assert game.lasers.len == 2
}
