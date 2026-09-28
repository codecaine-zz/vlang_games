module main

fn test_gnujump_initialization() {
	game := new_gnujump_engine()
	assert game.score_p1 == 0
	assert game.high_score == 0
	assert game.mode == .menu
	assert game.platforms.len > 0
}

fn test_gnujump_start_game() {
	mut game := new_gnujump_engine()
	game.start_game()
	assert game.mode == .playing
	assert game.p1.is_alive == true
	assert game.score_p1 == 0
}

fn test_gnujump_jump_physics() {
	mut game := new_gnujump_engine()
	game.start_game()
	start_y := game.p1.y

	// Trigger jump
	game.update_step(false, false, true, false, false, false)
	assert game.p1.on_ground == false
	assert game.p1.vy < 0

	// Step forward into air
	game.update_step(false, false, false, false, false, false)
	assert game.p1.y < start_y
}

fn test_gnujump_wall_bounce() {
	mut game := new_gnujump_engine()
	game.start_game()

	// Drive P1 into left wall
	for _ in 0 .. 30 {
		game.update_step(true, false, false, false, false, false)
	}

	assert game.p1.x >= f64(wall_w)
}

fn test_gnujump_score_accumulation() {
	mut game := new_gnujump_engine()
	game.start_game()
	game.p1.cur_floor = 15
	game.update_step(false, false, false, false, false, false)
	assert game.score_p1 >= 150
}

fn test_gnujump_lives_and_death() {
	mut game := new_gnujump_engine()
	game.start_game()
	assert game.p1.lives == 3

	// Force P1 off bottom of screen
	game.p1.y = 900.0
	game.update_step(false, false, false, false, false, false)

	// Lives should decrement to 2 and respawn jumper
	assert game.p1.lives == 2
	assert game.p1.is_alive == true

	// Force death remaining lives
	game.p1.lives = 1
	game.p1.y = 900.0
	game.update_step(false, false, false, false, false, false)

	assert game.p1.lives == 0
	assert game.p1.is_alive == false
	assert game.mode == .game_over
}

fn test_gnujump_crumbly_fall_through() {
	mut game := new_gnujump_engine()
	game.start_game()
	game.platforms.clear()

	// Position P1 mid-tower away from ground
	game.p1.x = 200.0
	game.p1.y = 400.0

	// Add ONLY a crumbly platform right below P1
	game.platforms << Platform{
		x:     game.p1.x
		y:     game.p1.y + game.p1.h + 2.0
		w:     100.0
		floor: 99
		kind:  .crumbly
	}

	// Falling downward onto crumbly platform
	game.p1.on_ground = false
	game.p1.vy = 4.0
	game.update_step(false, false, false, false, false, false)

	// Jumper must NOT be stuck on ground and must be falling (on_ground = false, vy > 0)
	assert game.p1.on_ground == false
	assert game.p1.vy > 0
}
