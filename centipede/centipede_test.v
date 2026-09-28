module main

fn test_centipede_initialization() {
	game := new_centipede_game()
	assert game.lives == 3
	assert game.score == 0
	assert game.game_over == false
	assert game.wave == 1
	assert game.chains.len > 0
	assert game.chains[0].segments.len > 0
}

fn test_player_movement() {
	mut game := new_centipede_game()
	start_x := game.player.x
	start_y := game.player.y

	// Move right and up
	game.move_player(1.0, -1.0, 0.1)
	assert game.player.x > start_x
	assert game.player.y < start_y

	// Attempt moving beyond top boundary of player zone
	game.move_player(0.0, -10.0, 1.0)
	min_y := playfield_offset_y + (24.0 * tile_size) + game.player.radius
	assert game.player.y >= min_y
}

fn test_laser_firing() {
	mut game := new_centipede_game()
	sound_mgr := new_sound_manager()
	assert game.lasers.len == 0

	game.player_fire(&sound_mgr)
	assert game.lasers.len == 1

	// Activate triple shot
	game.timer_triple_shot = 5.0
	game.player.fire_cooldown = 0.0
	game.player_fire(&sound_mgr)
	assert game.lasers.len == 4
}

fn test_mushroom_hit_and_destruction() {
	mut game := new_centipede_game()
	sound_mgr := new_sound_manager()

	// Place mushroom at (5, 5)
	game.grid[5][5] = Mushroom{exists: true, hp: 2}
	mx := playfield_offset_x + 5.0 * tile_size + 10.0
	my := playfield_offset_y + 5.0 * tile_size + 10.0

	// Spawn laser on top of mushroom
	game.lasers << Laser{x: mx, y: my, dx: 0.0, dy: -100.0}
	game.check_collisions(&sound_mgr)

	assert game.grid[5][5].hp == 1
	assert game.grid[5][5].exists == true

	// Hit again
	game.lasers << Laser{x: mx, y: my, dx: 0.0, dy: -100.0}
	game.check_collisions(&sound_mgr)

	assert game.grid[5][5].exists == false
	assert game.score > 0
}

fn test_centipede_splitting() {
	mut game := new_centipede_game()
	sound_mgr := new_sound_manager()

	game.chains.clear()
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			game.grid[r][c].exists = false
		}
	}
	mut segments := []CentipedeSegment{}
	for i in 0 .. 5 {
		segments << CentipedeSegment{
			col: 10 + i
			row: 10
			sub_x: 0.5
			sub_y: 0.5
			is_head: (i == 0)
			hp: 1
		}
	}
	game.chains << CentipedeChain{segments: segments}
	assert game.chains.len == 1
	assert game.chains[0].segments.len == 5

	// Shoot the middle segment (index 2, col 12)
	seg2_x := playfield_offset_x + (12.0 + 0.5) * tile_size
	seg2_y := playfield_offset_y + (10.0 + 0.5) * tile_size

	game.lasers << Laser{x: seg2_x, y: seg2_y, dx: 0.0, dy: -100.0}
	game.check_collisions(&sound_mgr)

	// Original centipede split into two chains
	assert game.chains.len == 2
	assert game.chains[0].segments.len == 2
	assert game.chains[1].segments.len == 2
	assert game.chains[1].segments[0].is_head == true

	// Mushroom created at (10, 12)
	assert game.grid[10][12].exists == true
}

fn test_powerup_application() {
	mut game := new_centipede_game()
	sound_mgr := new_sound_manager()

	game.apply_powerup(.rapid_fire, &sound_mgr)
	assert game.timer_rapid_fire == 6.0

	game.apply_powerup(.shield, &sound_mgr)
	assert game.timer_shield == 6.0
}

fn test_emp_nuke() {
	mut game := new_centipede_game()

	game.spiders << Spider{x: 200.0, y: 550.0, active: true}
	game.scorpions << Scorpion{row: 5, x: 200.0, active: true}
	game.grid[4][4] = Mushroom{exists: true, is_poison: true}

	game.trigger_emp_nuke()

	assert game.spiders.len == 0
	assert game.scorpions.len == 0
	assert game.grid[4][4].is_poison == false
}
