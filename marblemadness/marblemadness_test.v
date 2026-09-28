module main

fn test_isometric_projection() {
	sx, sy := world_to_screen(0, 0, 0, 100, 100)
	assert sx == 100.0
	assert sy == 100.0

	// Move along x
	sx1, sy1 := world_to_screen(1.0, 0, 0, 100, 100)
	assert sx1 > sx
	assert sy1 > sy

	// Elevation shifts y upwards
	sx_z, sy_z := world_to_screen(0, 0, 2.0, 100, 100)
	assert sx_z == sx
	assert sy_z < sy
}

fn test_level_loading() {
	for lvl in 1 .. 7 {
		ld := get_level_by_number(lvl)
		assert ld.def.level_num == lvl
		assert ld.tiles.len > 0
		assert ld.tiles[0].len > 0
		assert ld.def.start_time > 0
	}
}

fn test_game_state_transition() {
	mut game := new_marble_game()
	assert game.state == .title

	game.start_game(1)
	assert game.current_level == 1
	assert game.player.pos.z > 0
	assert game.player.speed_mph >= 0.0
}

fn test_surface_info_query() {
	ld := get_level_by_number(1)
	valid, h, dz_dx, dz_dy, t_type := get_surface_info(ld.tiles, 2.5, 2.5, 0.0)
	assert valid
	assert h == 6.0
	assert dz_dx == 0.0
	assert dz_dy == 0.0
	assert t_type == .flat
}
