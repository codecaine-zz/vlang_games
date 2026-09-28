module main

fn test_racer_initialization() {
	mut game := new_racer_game()
	assert game.player.speed == 0
	assert game.player.lap == 1
	assert game.ai_cars.len == 3
	assert game.checkpoints.len == 4
	assert game.waypoints.len > 0
}

fn test_racer_acceleration_and_steering() {
	mut game := new_racer_game()
	game.countdown = 0
	game.race_started = true

	initial_speed := game.player.speed
	initial_heading := game.player.heading

	// Accelerate & steer right
	game.update(0.016, true, false, false, true, false)
	assert game.player.speed > initial_speed
	assert game.player.heading > initial_heading
	assert game.sound_event_engine == true
}

fn test_racer_drift_mechanic() {
	mut game := new_racer_game()
	game.countdown = 0
	game.race_started = true
	game.player.speed = 200.0 // Moving fast enough to drift

	game.update(0.016, true, false, true, false, true) // Handbrake drift left
	assert game.player.is_drifting == true
	assert game.player.drift_factor > 0
	assert game.skid_marks.len > 0
	assert game.sound_event_skid == true
}

fn test_racer_surface_detection() {
	mut game := new_racer_game()
	game.countdown = 0
	game.race_started = true

	// Put player on turbo pad tile
	game.player.x = 14 * track_tile_size + 16
	game.player.y = 3 * track_tile_size + 16
	game.update(0.016, true, false, false, false, false)

	assert game.player.boost_timer > 0
	assert game.sound_event_boost == true
}

fn test_racer_checkpoint_and_lap_progression() {
	mut game := new_racer_game()
	game.countdown = 0
	game.race_started = true
	initial_lap := game.player.lap

	// Teleport player right inside checkpoint 1 gate (id: 1)
	cp1 := game.checkpoints[1]
	game.player.x = cp1.x + 10
	game.player.y = cp1.y + 10

	game.update(0.016, true, false, false, false, false)
	assert game.player.current_checkpoint == 1
	assert game.sound_event_gate == true
	assert game.player.lap == initial_lap
}

fn test_ai_lap_completion() {
	mut game := new_racer_game()
	game.countdown = 0
	game.race_started = true

	// Simulate 4500 steps (~72 seconds)
	for _ in 0 .. 4500 {
		game.update(0.016, false, false, false, false, false)
	}

	println('AI 0 lap: ${game.ai_cars[0].lap}, finished: ${game.ai_cars[0].finished}')
	println('AI 0 checkpoints_passed: ${game.ai_cars[0].checkpoints_passed}')
	assert game.ai_cars[0].lap > 3
	assert game.ai_cars[0].finished == true
}

fn test_player_lap_completion() {
	mut game := new_racer_game()
	game.countdown = 0
	game.race_started = true

	// Sequentially pass all 4 checkpoints for 3 laps
	for lap in 1 .. 4 {
		for cp_idx in 1 .. 5 {
			target_cp := cp_idx % 4
			cp := game.checkpoints[target_cp]
			game.player.x = cp.x + cp.w / 2.0
			game.player.y = cp.y + cp.h / 2.0
			game.update(0.016, false, false, false, false, false)
		}
		assert game.player.lap == lap + 1
	}

	assert game.player.finished == true
	assert game.race_finished == true
}

