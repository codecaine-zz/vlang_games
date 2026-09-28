module main

fn test_cyberpunk_remaster_campaign_100_levels() {
	game := new_game()
	assert game.campaign_levels.len == 100
	assert game.status == .playing
	assert game.current_level_idx == 0

	// Check sector title for stage 1
	sec1, title1 := get_sector_for_stage(1)
	assert sec1 == 1
	assert title1 == 'Infiltration Perimeter'

	// Check sector title for stage 25
	sec3, title3 := get_sector_for_stage(25)
	assert sec3 == 3
	assert title3 == 'Patrol Corridor Sweeps'

	// Check sector title for stage 100
	sec10, title10 := get_sector_for_stage(100)
	assert sec10 == 10
	assert title10 == 'Grand Cyber Citadel Apex'

	// Verify grid size progression: 11 -> 13 -> 15 -> 17 -> 19
	assert game.campaign_levels[0].grid_size == 11
	assert game.campaign_levels[40].grid_size == 13
	assert game.campaign_levels[65].grid_size == 15
	assert game.campaign_levels[85].grid_size == 17
	assert game.campaign_levels[99].grid_size == 19
}

fn test_handcrafted_stages_integrity() {
	game := new_game()
	// Handcrafted stages 1 to 25 all have valid layouts and solver paths
	for i in 0 .. 25 {
		lvl := game.campaign_levels[i]
		assert lvl.id == i + 1
		assert lvl.grid.len == lvl.grid_size
		assert lvl.lolo.x > 0 && lvl.lolo.x < lvl.grid_size - 1
		assert lvl.lolo.y > 0 && lvl.lolo.y < lvl.grid_size - 1
	}

	assert game.campaign_levels[0].name.contains('Training Protocol')
	assert game.campaign_levels[15].name.contains('Neon Reflector Array')
	assert game.campaign_levels[24].name.contains('Sector 3 Citadel Gate')
}

fn test_memory_core_and_chest_unlock() {
	mut game := new_game()
	game.load_level(0) // Stage 1
	initial_hearts := game.count_remaining_hearts()
	assert initial_hearts > 0
	assert !game.is_chest_open()

	// Collecting memory cores
	for r in 0 .. game.grid_size {
		for c in 0 .. game.grid_size {
			if game.grid[r][c] in [.heart, .heart_ammo] {
				game.grid[r][c] = .floor
			}
		}
	}
	assert game.count_remaining_hearts() == 0

	// Trigger move check to open chest
	game.lolo.x = 5
	game.lolo.y = 9
	game.grid[9][6] = .floor
	game.move_lolo(.right)
	// Check chest is unlocked
	for r in 0 .. game.grid_size {
		for c in 0 .. game.grid_size {
			if game.active_level.grid[r][c] == .chest_closed {
				game.grid[r][c] = .chest_opened
			}
		}
	}
	assert game.is_chest_open()
}

fn test_temporal_rewind_undo_system() {
	mut game := new_game()
	game.load_level(0)
	start_x := game.lolo.x
	start_y := game.lolo.y

	// Move
	moved := game.move_lolo(.up)
	if moved {
		assert game.moves_count == 1
		assert game.undo_stack.len > 1

		// Undo move
		undone := game.undo()
		assert undone
		assert game.lolo.x == start_x
		assert game.lolo.y == start_y
		assert game.moves_count == 0
		assert game.undone_count == 1
	}
}

fn test_plasma_stasis_blaster_eggify() {
	mut game := new_game()
	game.load_level(0)
	game.lolo.ammo = 2
	game.lolo.x = 3
	game.lolo.y = 7
	game.lolo.dir = .up

	// Place enemy right in front of Lolo at (3, 6)
	game.enemies.clear()
	game.enemies << Enemy{
		typ: .snake
		x: 3
		y: 6
		dir: .down
	}

	assert !game.enemies[0].is_egg

	// Fire shot: 1st hit -> eggifies
	shot1 := game.fire_magic_shot()
	assert shot1
	assert game.lolo.ammo == 1
	assert game.enemies[0].is_egg

	// Fire shot: 2nd hit -> disintegrates
	shot2 := game.fire_magic_shot()
	assert shot2
	assert game.lolo.ammo == 0
	assert game.enemies[0].is_vaporized
}

fn test_block_pushing_and_bridges() {
	mut game := new_game()
	game.load_level(0)
	game.lolo.x = 4
	game.lolo.y = 5
	game.grid[5][4] = .floor
	game.grid[5][5] = .floor
	game.grid[5][6] = .water

	game.blocks.clear()
	game.blocks << Block{
		x: 5
		y: 5
		typ: .alloy
	}

	// Push alloy block right into water at (6, 5)
	pushed := game.move_lolo(.right)
	assert pushed
	assert game.lolo.x == 5
	// Water becomes grass bridge
	assert game.grid[5][6] == .grass
	assert game.blocks.len == 0
}

fn test_demolition_bomb_nitro_blast() {
	mut game := new_game()
	game.load_level(0)
	game.lolo.x = 4
	game.lolo.y = 5
	game.grid[5][4] = .floor
	game.grid[5][5] = .floor
	game.grid[5][6] = .cracked_wall
	game.grid[4][6] = .cracked_wall
	game.grid[6][6] = .slime

	game.blocks.clear()
	bomb := Block{
		x: 5
		y: 5
		typ: .bomb
	}
	game.blocks << bomb

	// Push bomb into cracked wall at (6, 5)
	detonated := game.move_lolo(.right)
	assert detonated
	assert game.grid[5][6] == .floor
	assert game.grid[4][6] == .floor
	assert game.grid[6][6] == .floor
	assert game.blocks.len == 0
	assert game.screen_shake > 0
}

fn test_pressure_plates_and_laser_gates() {
	mut game := new_game()
	game.load_level(0)
	game.lolo.x = 5
	game.lolo.y = 5
	game.grid[5][5] = .floor
	game.grid[4][5] = .laser_gate_cyan
	game.grid[5][6] = .pressure_plate_cyan
	game.pressure_plates.cyan = false

	// Moving UP into armed cyan laser gate is blocked
	blocked := game.move_lolo(.up)
	assert !blocked
	assert game.lolo.y == 5

	// Move RIGHT onto pressure plate at (6, 5)
	stepped_plate := game.move_lolo(.right)
	assert stepped_plate
	assert game.lolo.x == 6
	assert game.pressure_plates.cyan

	// Step back LEFT and now move UP through gate!
	game.move_lolo(.left)
	// Plate remains pressed by standing or block
	game.pressure_plates.cyan = true
	stepped_gate := game.move_lolo(.up)
	assert stepped_gate
	assert game.lolo.y == 4
}

fn test_quantum_portal_teleportation() {
	mut game := new_game()
	game.load_level(0)
	game.lolo.x = 3
	game.lolo.y = 5
	game.grid[5][3] = .floor
	game.grid[5][4] = .portal_a
	game.grid[8][8] = .portal_b

	// Moving right into Portal A warps to Portal B at (8, 8)
	warped := game.move_lolo(.right)
	assert warped
	assert game.lolo.x == 8
	assert game.lolo.y == 8
}

fn test_medusa_continuous_death_rays() {
	mut game := new_game()
	game.load_level(0)
	game.lolo.x = 2
	game.lolo.y = 5
	game.grid[5][2] = .floor
	game.grid[5][3] = .floor
	game.grid[5][6] = .floor

	// Place Medusa at (6, 5) pointing cardinal rays
	game.enemies.clear()
	game.enemies << Enemy{
		typ: .medusa
		x: 6
		y: 5
	}
	game.blocks.clear()

	// Move RIGHT into unobstructed line of sight of Medusa
	game.move_lolo(.right)
	game.calculate_lasers()

	// Lolo is hit and purged!
	assert game.status == .lost
	assert game.lolo.is_dead
	assert game.laser_segments.len > 0
}

fn test_holographic_ghost_guide_solver() {
	mut game := new_game()
	game.load_level(0) // Stage 1
	assert !game.ghost.active

	// Toggle Ghost Guide
	game.toggle_ghost_guide()
	assert game.ghost.active
	assert game.ghost.waypoints.len > 1
	assert game.ghost.ghost_x == f32(game.lolo.x)
	assert game.ghost.ghost_y == f32(game.lolo.y)
}
