module main

fn test_pdp_init() {
	mut g := new_panel_game()
	assert g.state == .playing
	assert g.score == 0
	assert g.cur_c == 2
	assert g.cur_r == 6
	assert g.grid.len == pdp_rows
}

fn test_pdp_cursor_swap() {
	mut g := new_panel_game()
	g.grid[11][0] = 1
	g.grid[11][1] = 2
	g.cur_r = 11
	g.cur_c = 0

	ok := g.swap_panels()
	assert ok == true
	assert g.grid[11][0] == 2
	assert g.grid[11][1] == 1
}

fn test_pdp_horizontal_match() {
	mut g := new_panel_game()
	g.grid = [12][6]int{}
	// Place 3 Red Hearts (type 1)
	g.grid[11][0] = 1
	g.grid[11][1] = 1
	g.grid[11][2] = 1

	matched := g.check_matches()
	assert matched == true
	assert g.clearing_cells.len == 3
	assert g.stop_timer > 1.0
}

fn test_pdp_vertical_match() {
	mut g := new_panel_game()
	g.grid = [12][6]int{}
	// Place 3 Yellow Stars (type 2)
	g.grid[9][3] = 2
	g.grid[10][3] = 2
	g.grid[11][3] = 2

	matched := g.check_matches()
	assert matched == true
	assert g.clearing_cells.len == 3
}

fn test_pdp_gravity_cascade() {
	mut g := new_panel_game()
	g.grid = [12][6]int{}
	// Floating Cyan Diamond (type 3)
	g.grid[5][0] = 3

	moved := g.apply_gravity()
	assert moved == true
	assert g.grid[5][0] == 0
	assert g.grid[11][0] == 3
}
