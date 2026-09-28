module main

fn test_perspective_projection() {
	cam := Camera{
		x: 0
		y: 110.0
		z: 0
		focal_len: 440.0
		horizon_y: 240.0
	}

	// Directly forward
	proj := project_3d(vec3(0, 0, 440.0), cam, 0.0, 0.0, 840, 480)
	assert proj.visible
	assert proj.sx == 420.0
	assert proj.scale > 0.9 && proj.scale < 1.1

	// Far point
	proj_far := project_3d(vec3(0, 0, 2200.0), cam, 0.0, 0.0, 840, 480)
	assert proj_far.visible
	assert proj_far.scale < proj.scale
}

fn test_world_loading_and_obstacles() {
	for w := 1; w <= 5; w++ {
		theme := get_world_theme(w)
		assert theme.world_num == w
		assert theme.track_length >= 10000.0

		obs := generate_world_obstacles(w)
		assert obs.len > 10
	}
}

fn test_game_and_dragon_boss() {
	mut game := new_worldrunner_game()
	game.start_game(1)
	game.state = .playing
	assert game.player.speed_kmh >= 180.0
	assert game.has_boss
	assert game.boss.segments.len == 14
	assert game.boss.segments[0].is_head

	// Test Laser Creation
	game.input_fire = true
	game.update(0.016)
	assert game.lasers.len >= 2
}

fn test_collision_detection() {
	p1 := vec3(0, 0, 100)
	sz1 := vec3(50, 50, 50)
	p2 := vec3(20, 10, 110)
	sz2 := vec3(40, 40, 40)
	assert check_box_collision_3d(p1, sz1, p2, sz2)

	p_far := vec3(200, 200, 500)
	assert !check_box_collision_3d(p1, sz1, p_far, sz2)
}

fn test_sound_and_bgm() {
	mut sm := new_sound_manager()
	assert sm.sound_enabled
	for w := 1; w <= 5; w++ {
		sm.set_world(w)
		assert sm.cur_world == w
	}
	sm.toggle_sound()
	assert !sm.sound_enabled
}
