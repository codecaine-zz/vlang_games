module main

fn test_micromayhem_init() {
	mut g := new_micromayhem_game()
	assert g.lives == 5
	assert g.score == 0
	assert g.streak == 0
	assert g.phase == .title
}

fn test_micromayhem_bomb_defusal() {
	mut g := new_micromayhem_game()
	g.start_game()
	g.current_micro = .defuse_bomb
	g.bomb_target_wire = 1 // Green
	g.phase = .playing

	// Cut correct wire (2 = Green)
	g.handle_key_action(2)
	assert g.is_success
	assert g.score > 0
	assert g.streak == 1
}

fn test_micromayhem_gem_catching() {
	mut g := new_micromayhem_game()
	g.start_game()
	g.current_micro = .catch_gem
	g.gem_x = 400.0
	g.gem_y = 470.0
	g.phase = .playing

	// Position basket under gem (x = 400)
	g.update(0.016, 400.0)
	assert g.gem_caught
	assert g.is_success
}

fn test_micromayhem_laser_dodge() {
	mut g := new_micromayhem_game()
	g.start_game()
	g.current_micro = .dodge_laser
	g.player_lane = 1
	g.laser_danger_lane = 1
	g.phase = .playing

	// Dodge to left lane
	g.handle_key_action(-1)
	assert g.player_lane == 0

	g.finish_microgame()
	assert g.is_success
}
