module main

fn test_new_game_engine() {
	ge := new_game_engine()
	assert ge.state == .title
	assert ge.mode == .mode_a_1p
	assert ge.high_score == 25000
	assert ge.world_w == 800.0
	assert ge.world_h == 600.0
}

fn test_flap_physics() {
	mut m := MotionState{
		x:           200
		y:           300
		vx:          0
		vy:          0
		is_grounded: true
	}
	apply_flap(mut m, 180.0)
	assert m.vy == -180.0
	assert m.is_grounded == false
}

fn test_wraparound_physics() {
	mut m := MotionState{
		x:           -25.0
		y:           300
		vx:          -50.0
		vy:          0
		is_grounded: false
	}
	update_motion(mut m, 0.016, 800.0)
	assert m.x > 700.0
}

fn test_stage_setup() {
	mut ge := new_game_engine()
	ge.start_game(.mode_a_1p)
	assert ge.state == .playing
	assert ge.players.len == 1
	assert ge.enemies.len > 0
	assert ge.platforms.len > 0
}

fn test_balloon_collisions() {
	mut ge := new_game_engine()
	sm := new_sound_manager()
	ge.start_game(.mode_a_1p)

	// Position player directly above enemy (p_feet <= e_head + 12)
	ge.players[0].motion.x = 200.0
	ge.players[0].motion.y = 90.0
	ge.players[0].motion.vy = 50.0

	ge.enemies[0].motion.x = 200.0
	ge.enemies[0].motion.y = 120.0
	ge.enemies[0].motion.vy = 0.0
	ge.enemies[0].balloons = 2
	ge.enemies[0].state = .flying

	ge.check_balloon_collisions(&sm)

	assert ge.enemies[0].balloons == 1
}

fn test_giant_fish_trigger() {
	mut ge := new_game_engine()
	sm := new_sound_manager()
	ge.start_game(.mode_a_1p)

	// Player hovers low over water
	ge.players[0].motion.x = 300.0
	ge.players[0].motion.y = 480.0
	ge.fish.cooldown = 3.5

	ge.update_giant_fish(0.016, &sm)

	assert ge.fish.active == true
	assert ge.fish.x == 300.0
}

fn test_ledge_fall_gravity() {
	platforms := [
		Platform{x: 100.0, y: 300.0, w: 100.0, h: 20.0},
	]
	// Standing on platform
	mut m := MotionState{
		x:           150.0
		y:           300.0 - 18.0 // Center of character (h=36)
		vx:          0
		vy:          0
		is_grounded: true
	}
	// Verify supported
	assert update_platforms_collision(mut m, 28.0, 36.0, platforms) == true
	assert m.is_grounded == true

	// Walk off the right edge (x past 200 + char_w/2)
	m.x = 220.0
	assert update_platforms_collision(mut m, 28.0, 36.0, platforms) == false
	assert m.is_grounded == false

	// Update motion - gravity MUST accelerate downward
	update_motion(mut m, 0.05, 800.0)
	assert m.vy > 0.0
	assert m.y > (300.0 - 18.0)
}

fn test_defeat_pumping_enemy_by_running_into_them() {
	mut ge := new_game_engine()
	sm := new_sound_manager()
	ge.start_game(.mode_a_1p)

	// Both player and enemy on same platform level
	ge.players[0].motion.x = 200.0
	ge.players[0].motion.y = 282.0
	ge.enemies[0].motion.x = 210.0
	ge.enemies[0].motion.y = 282.0
	ge.enemies[0].state = .pumping
	ge.enemies[0].active = true

	ge.check_balloon_collisions(&sm)

	assert ge.enemies[0].active == false
	assert ge.score > 0
}

fn test_player_zero_balloons_instant_death() {
	mut ge := new_game_engine()
	sm := new_sound_manager()
	ge.start_game(.mode_a_1p)

	initial_lives := ge.players[0].lives
	ge.players[0].balloons = 1
	ge.players[0].invincibility = 0
	ge.players[0].motion.x = 200.0
	ge.players[0].motion.y = 200.0

	// Position enemy directly above player to pop last balloon
	ge.enemies[0].motion.x = 200.0
	ge.enemies[0].motion.y = 180.0
	ge.enemies[0].state = .flying
	ge.enemies[0].active = true

	ge.check_balloon_collisions(&sm)

	// Player should immediately lose 1 life and respawn with 2 balloons
	assert ge.players[0].lives == initial_lives - 1
	assert ge.players[0].balloons == 2
	assert ge.players[0].state == .flying
}

fn test_wrap_dx_calculation() {
	world_w := 800.0
	// Normal close distance
	assert wrap_dx(100.0, 150.0, world_w) == 50.0
	assert wrap_dx(150.0, 100.0, world_w) == -50.0

	// Screen seam distance: entity at x=790 and entity at x=10
	// Direct distance: 10 - 790 = -780, wrapped should be +20!
	assert wrap_dx(790.0, 10.0, world_w) == 20.0
	// From x=10 to x=790: direct +780, wrapped should be -20!
	assert wrap_dx(10.0, 790.0, world_w) == -20.0
}

fn test_ai_altitude_contesting_and_climbing() {
	mut ge := new_game_engine()
	sm := new_sound_manager()
	ge.start_game(.mode_a_1p)

	// Set player at y=250.0
	ge.players[0].motion.x = 400.0
	ge.players[0].motion.y = 250.0
	ge.players[0].invincibility = 0.0

	// Position enemy below player at y=300.0, rank = red (wants desired_alt = 70.0 above player -> target y=180.0)
	ge.enemies[0].rank = .red
	ge.enemies[0].state = .flying
	ge.enemies[0].active = true
	ge.enemies[0].motion.x = 400.0
	ge.enemies[0].motion.y = 300.0
	ge.enemies[0].motion.vy = 0.0
	ge.enemies[0].flap_timer = 0.0

	// Update AI
	ge.update_single_enemy_ai(mut ge.enemies[0], 0.016, &sm)

	// Enemy should recognize height disadvantage, switch to .climb, and flap upward!
	assert ge.enemies[0].behavior == .climb
	assert ge.enemies[0].motion.vy < 0.0 // Upward flap impulse applied
}

fn test_ai_water_hazard_avoidance() {
	mut ge := new_game_engine()
	sm := new_sound_manager()
	ge.start_game(.mode_a_1p)

	// Enemy near water (y=440.0, water_level=540.0)
	ge.enemies[0].state = .flying
	ge.enemies[0].active = true
	ge.enemies[0].motion.x = 300.0
	ge.enemies[0].motion.y = 440.0
	ge.enemies[0].motion.vy = 20.0
	ge.enemies[0].flap_timer = 0.0

	ge.update_single_enemy_ai(mut ge.enemies[0], 0.016, &sm)

	// Enemy must enter panic_water and flap vigorously
	assert ge.enemies[0].behavior == .panic_water
	assert ge.enemies[0].motion.vy < 0.0
}

fn test_ai_parachuting_steers_to_platform() {
	mut ge := new_game_engine()
	sm := new_sound_manager()
	ge.start_game(.mode_a_1p)

	// Platform at x=100..260, y=450 (center 180.0)
	// Place parachuting enemy at x=220.0, y=380.0
	ge.enemies[0].state = .parachuting
	ge.enemies[0].active = true
	ge.enemies[0].motion.x = 220.0
	ge.enemies[0].motion.y = 380.0
	ge.enemies[0].motion.vx = 0.0

	ge.update_single_enemy_ai(mut ge.enemies[0], 0.05, &sm)

	// Enemy should identify platform at center 180.0 (to the left) and steer vx < 0
	assert ge.enemies[0].behavior == .seek_platform
	assert ge.enemies[0].motion.vx < 0.0
}

fn test_ai_emergency_scramble_takeoff_under_threat() {
	mut ge := new_game_engine()
	sm := new_sound_manager()
	ge.start_game(.mode_a_1p)

	// Enemy is pumping and already has 1 balloon inflated
	ge.enemies[0].state = .pumping
	ge.enemies[0].balloons = 1
	ge.enemies[0].active = true
	ge.enemies[0].motion.x = 200.0
	ge.enemies[0].motion.y = 282.0

	// Player is swooping in fast and close (distance < 90)
	ge.players[0].motion.x = 250.0
	ge.players[0].motion.y = 260.0
	ge.players[0].invincibility = 0.0

	ge.update_single_enemy_ai(mut ge.enemies[0], 0.016, &sm)

	// Enemy detects incoming stomper and scrambles into flight immediately!
	assert ge.enemies[0].state == .flying
	assert ge.enemies[0].motion.vy < 0.0
}

fn test_bonus_bubble_mechanics() {
	mut ge := new_game_engine()
	sm := new_sound_manager()
	ge.start_game(.mode_a_1p)

	initial_score := ge.score
	// Spawn a bonus bubble
	ge.spawn_bonus_bubble(200.0, 200.0)
	assert ge.bubbles.len == 1

	// Move player to touch bubble
	ge.players[0].motion.x = 200.0
	ge.players[0].motion.y = 200.0

	// Update FX
	ge.update_fx(0.016, &sm)

	// Bubble should be collected, score increased, particles & float text spawned
	assert ge.bubbles.len == 0
	assert ge.score > initial_score
	assert ge.particles.len > 0
	assert ge.float_texts.len > 0
}
