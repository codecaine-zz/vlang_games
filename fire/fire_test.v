module main

fn test_fire_initialization() {
	mut game := new_fire_game()
	assert game.state == .title
	assert game.high_score == 0

	game.start_game(.game_a)
	assert game.state == .playing
	assert game.score == 0
	assert game.misses == 0
	assert game.trampoline_pos == 1
}

fn test_fire_trampoline_movement() {
	mut game := new_fire_game()
	game.start_game(.game_a)

	game.move_left()
	assert game.trampoline_pos == 0
	game.move_left() // Clamp at 0
	assert game.trampoline_pos == 0

	game.move_right()
	assert game.trampoline_pos == 1
	game.move_right()
	assert game.trampoline_pos == 2
	game.move_right() // Clamp at 2
	assert game.trampoline_pos == 2
}

fn test_fire_bounce_and_score() {
	mut game := new_fire_game()
	mut sm := new_sound_manager()
	sm.enabled = false
	game.start_game(.game_a)

	// Inject a jumper at step 2 (about to hit Pos 0)
	game.jumpers << Jumper{
		step: 2
		active: true
		crashed: false
	}
	game.trampoline_pos = 0 // Paramedics ready at Left

	// Advance clock
	game.tick_timer = game.tick_interval
	game.update(0.01, mut sm)

	assert game.score >= 1
	assert game.misses == 0
}
