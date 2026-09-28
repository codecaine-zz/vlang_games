module main

fn test_skifree_initialization() {
	mut g := new_ski_game()
	assert g.pose == .stopped
	assert g.obstacles.len > 0
	assert g.distance_m == 0
}

fn test_skifree_steering() {
	mut g := new_ski_game()
	g.steer_down()
	assert g.pose == .ski_straight

	g.steer_left()
	assert g.pose == .turn_diag_left

	g.steer_left()
	assert g.pose == .turn_left

	g.steer_right()
	assert g.pose == .turn_diag_left
}

fn test_skifree_downhill_movement() {
	mut g := new_ski_game()
	g.steer_down()
	init_y := g.y

	for _ in 0 .. 30 {
		g.update(0.016)
	}

	assert g.y > init_y
	assert g.vy > 0
	assert g.distance_m >= 1
}

fn test_skifree_airborne_tricks() {
	mut g := new_ski_game()
	g.steer_down()
	g.pose = .airborne
	g.air_time = 0.1

	// Perform daffy trick in air
	g.steer_left()
	assert g.pose == .trick_daffy
	assert g.trick_points > 0

	// Complete airborne duration
	for _ in 0 .. 60 {
		g.update(0.02)
	}

	assert g.altitude == 0.0
	assert g.score > 0
}

fn test_skifree_crash_and_recovery() {
	mut g := new_ski_game()
	g.trigger_crash()
	assert g.pose == .crashed
	assert g.crash_timer > 0

	for _ in 0 .. 100 {
		g.update(0.02)
	}

	assert g.pose == .stopped
}

fn test_skifree_yeti_spawn() {
	mut g := new_ski_game()
	g.mode = .yeti_survival
	g.reset_game()
	assert g.yeti.active

	// Advance Yeti chase
	init_yeti_y := g.yeti.y
	for _ in 0 .. 30 {
		g.update(0.016)
	}
	assert g.yeti.y > init_yeti_y
}
