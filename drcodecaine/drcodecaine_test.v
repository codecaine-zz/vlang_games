module main

fn test_game_init_and_reset() {
	mut game := new_dr_mario_game()
	assert game.state == .title
	assert game.viruses_left == 0

	game.start_game(0, .med)
	assert game.state == .playing
	assert game.viruses_left == 4 // (0 + 1) * 4 = 4 viruses
	assert game.has_active_pill == true
}

fn test_higher_level_viruses() {
	mut game := new_dr_mario_game()
	game.start_game(5, .hi)
	assert game.viruses_left == 24 // (5 + 1) * 4 = 24 viruses
	assert game.speed == .hi
}

fn test_match_four_horizontal() {
	mut game := new_dr_mario_game()
	game.start_game(0, .low)
	game.clear_grid()

	// 4 red cells in a horizontal row
	game.grid[15][0] = Cell{ cell_type: .pill_single, color: .red }
	game.grid[15][1] = Cell{ cell_type: .pill_single, color: .red }
	game.grid[15][2] = Cell{ cell_type: .pill_single, color: .red }
	game.grid[15][3] = Cell{ cell_type: .virus, color: .red }
	game.viruses_left = 1
	game.red_viruses = 1

	matched := game.check_and_clear_matches()
	assert matched == true
	assert game.grid[15][0].cell_type == .empty
	assert game.grid[15][1].cell_type == .empty
	assert game.grid[15][2].cell_type == .empty
	assert game.grid[15][3].cell_type == .empty
	assert game.viruses_left == 0
}

fn test_match_four_vertical() {
	mut game := new_dr_mario_game()
	game.start_game(0, .low)
	game.clear_grid()

	// 4 blue cells in a vertical column
	game.grid[12][2] = Cell{ cell_type: .pill_single, color: .blue }
	game.grid[13][2] = Cell{ cell_type: .pill_single, color: .blue }
	game.grid[14][2] = Cell{ cell_type: .pill_single, color: .blue }
	game.grid[15][2] = Cell{ cell_type: .virus, color: .blue }
	game.viruses_left = 1
	game.blue_viruses = 1

	matched := game.check_and_clear_matches()
	assert matched == true
	assert game.grid[12][2].cell_type == .empty
	assert game.grid[13][2].cell_type == .empty
	assert game.grid[14][2].cell_type == .empty
	assert game.grid[15][2].cell_type == .empty
	assert game.viruses_left == 0
}

fn test_gravity_cascade() {
	mut game := new_dr_mario_game()
	game.start_game(0, .low)
	game.clear_grid()

	// Floating single pill segment at row 10
	game.grid[10][3] = Cell{ cell_type: .pill_single, color: .yellow }

	moved := game.apply_gravity_step()
	assert moved == true
	assert game.grid[10][3].cell_type == .empty
	assert game.grid[11][3].cell_type == .pill_single
}

fn test_stage_clear_and_next_level() {
	mut game := new_dr_mario_game()
	game.start_game(0, .low)
	assert game.level == 0
	assert game.viruses_left == 4

	// Clear grid and place exactly 1 virus to test eradication
	game.clear_grid()
	game.grid[15][0] = Cell{ cell_type: .pill_single, color: .red }
	game.grid[15][1] = Cell{ cell_type: .pill_single, color: .red }
	game.grid[15][2] = Cell{ cell_type: .pill_single, color: .red }
	game.grid[15][3] = Cell{ cell_type: .virus, color: .red }
	assert game.count_viruses() == 1

	matched := game.check_and_clear_matches()
	assert matched == true
	assert game.viruses_left == 0
	assert game.state == .stage_clear
	assert game.stage_clear_timer > 0.0

	// Advance to next level
	game.next_level()
	assert game.level == 1
	assert game.state == .playing
	assert game.viruses_left == 8 // (1 + 1) * 4 = 8 viruses
}

fn test_sound_toggle_and_bgm_cycle() {
	mut sm := new_sound_manager()
	initial := sm.sound_enabled
	toggled := sm.toggle_sound()
	assert toggled != initial

	assert sm.bgm_type == .fever
	sm.cycle_bgm()
	assert sm.bgm_type == .chill
	sm.cycle_bgm()
	assert sm.bgm_type == .off
	sm.cycle_bgm()
	assert sm.bgm_type == .fever
}

fn test_ghost_projection_and_hard_drop() {
	mut game := new_dr_mario_game()
	game.start_game(0, .low)
	game.clear_grid()

	// Spawn pill at top
	game.active_pill = ActivePill{
		x: 3
		y: 0
		c1: .red
		c2: .yellow
		orientation: .horizontal
	}
	game.has_active_pill = true

	// Ghost Y should be bottom row 15
	ghost_y := game.get_ghost_y()
	assert ghost_y == 15

	// Hard drop should slam pill to row 15 and lock it
	game.hard_drop()
	assert game.grid[15][3].cell_type == .pill_left
	assert game.grid[15][4].cell_type == .pill_right
	assert game.grid[15][3].color == .red
	assert game.grid[15][4].color == .yellow
}

fn test_hold_capsule_queue() {
	mut game := new_dr_mario_game()
	game.start_game(0, .low)
	game.clear_grid()

	game.active_pill = ActivePill{
		x: 3
		y: 0
		c1: .blue
		c2: .blue
		orientation: .horizontal
	}
	game.has_active_pill = true
	assert game.has_hold_pill == false

	// Hold active blue-blue pill
	game.hold_current_pill()
	assert game.has_hold_pill == true
	assert game.hold_c1 == .blue
	assert game.hold_c2 == .blue
	assert game.can_hold == false
}
