module main

fn test_chimp_game_initialization() {
	mut g := new_chimp_game()
	assert g.state == .ready
	assert g.level == 4
	assert g.strikes == 0
	assert g.cells.len == total_cells
	assert g.next_expected == 1

	// Count number of active cells
	mut active_cells := 0
	for cell in g.cells {
		if cell.number > 0 {
			active_cells++
		}
	}
	assert active_cells == 4
}

fn test_chimp_click_progression_and_hidden_state() {
	mut g := new_chimp_game()
	g.level = 4
	g.start_level()

	// Find cell with number 1
	mut c1_x := -1
	mut c1_y := -1
	for cell in g.cells {
		if cell.number == 1 {
			c1_x = cell.grid_x
			c1_y = cell.grid_y
			break
		}
	}
	assert c1_x != -1

	// Click cell 1
	ok1, ev1 := g.handle_cell_click(c1_x, c1_y)
	assert ok1 == true
	assert ev1.tile_clicked == 1
	assert g.state == .active_hidden // Hidden mask active!
	assert g.next_expected == 2
}

fn test_chimp_strike_and_game_over() {
	mut g := new_chimp_game()
	g.level = 4
	g.start_level()

	// Find cell with number 2
	mut c2_x := -1
	mut c2_y := -1
	for cell in g.cells {
		if cell.number == 2 {
			c2_x = cell.grid_x
			c2_y = cell.grid_y
			break
		}
	}

	// Click cell 2 when 1 was expected -> Strike!
	ok, ev := g.handle_cell_click(c2_x, c2_y)
	assert ok == false
	assert ev.strike_taken == true
	assert g.strikes == 1
	assert g.state == .level_failed
}
