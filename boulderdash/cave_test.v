module main

fn test_cave_loading_and_player() {
	caves := get_cave_levels()
	assert caves.len == 5

	c1 := caves[0]
	assert c1.width == 20
	assert c1.height == 15
	assert c1.diamonds_needed == 8
	assert c1.diamonds_got == 0
	assert c1.player_pos.r == 1 && c1.player_pos.c == 1
}

fn test_dig_dirt_and_diamond() {
	mut c := new_cave_from_layout(
		'Test Cave',
		[
			'#####',
			'#P.D#',
			'#####',
		],
		1,
		60
	)
	mut sm := new_sound_manager()

	// Move right into dirt
	ok1 := c.move_player(0, 1, mut sm)
	assert ok1
	assert c.player_pos.r == 1 && c.player_pos.c == 2
	assert c.grid[1][1] == tile_empty
	assert c.grid[1][2] == tile_player

	// Move right into diamond
	ok2 := c.move_player(0, 1, mut sm)
	assert ok2
	assert c.diamonds_got == 1
	assert c.door_unlocked
}

fn test_boulder_gravity_and_rolling() {
	mut c := new_cave_from_layout(
		'Physics Cave',
		[
			'#####',
			'#O  #',
			'#   #',
			'#####',
		],
		0,
		60
	)
	mut sm := new_sound_manager()

	assert c.grid[1][1] == tile_boulder
	c.update_physics(mut sm)
	// Boulder should fall into row 2
	assert c.grid[1][1] == tile_empty
	assert c.grid[2][1] == tile_boulder
}
