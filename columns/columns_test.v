module main

fn test_columns_init() {
	mut g := new_columns_game()
	assert g.state == .falling
	assert g.score == 0
	assert g.level == 1
	assert g.active_col.gems.len == 3
}

fn test_columns_cycle() {
	mut g := new_columns_game()
	g.active_col.gems[0] = 1
	g.active_col.gems[1] = 2
	g.active_col.gems[2] = 3

	g.cycle_gems()
	assert g.active_col.gems[0] == 3
	assert g.active_col.gems[1] == 1
	assert g.active_col.gems[2] == 2

	g.cycle_gems()
	assert g.active_col.gems[0] == 2
	assert g.active_col.gems[1] == 3
	assert g.active_col.gems[2] == 1
}

fn test_columns_horizontal_match() {
	mut g := new_columns_game()
	// Place horizontal match of 3 Rubies (gem type 1) at bottom row
	g.grid[12][0] = 1
	g.grid[12][1] = 1
	g.grid[12][2] = 1

	matched := g.check_matches()
	assert matched == true
	assert g.clearing_pos.len == 3
	assert g.state == .clearing
}

fn test_columns_vertical_match() {
	mut g := new_columns_game()
	// Place vertical match of 3 Emeralds (gem type 2) at column 3
	g.grid[10][3] = 2
	g.grid[11][3] = 2
	g.grid[12][3] = 2

	matched := g.check_matches()
	assert matched == true
	assert g.clearing_pos.len == 3
}

fn test_columns_diagonal_match() {
	mut g := new_columns_game()
	// Diagonal down-right match of 3 Sapphires (gem type 3)
	g.grid[10][0] = 3
	g.grid[11][1] = 3
	g.grid[12][2] = 3

	matched := g.check_matches()
	assert matched == true
	assert g.clearing_pos.len == 3
}

fn test_columns_gravity_cascade() {
	mut g := new_columns_game()
	// Place floating gem at row 5, col 0
	g.grid[5][0] = 4
	moved := g.apply_gravity()
	assert moved == true
	assert g.grid[5][0] == 0
	assert g.grid[12][0] == 4
}
