module main

fn test_rodent_initialization() {
	mut g := new_rodent_game()
	assert g.level == 1
	assert g.lives == 3
	assert g.player_x == 10
	assert g.player_y == 10
	assert g.grid[0][0] == .wall
}

fn test_rodent_block_pushing() {
	mut g := new_rodent_game()
	g.grid[11][10] = .block
	g.grid[12][10] = .empty

	// Push block to the right
	assert g.move_player(1, 0)
	assert g.player_x == 11
	assert g.grid[11][10] == .empty
	assert g.grid[12][10] == .block
}

fn test_rodent_cat_trapping_and_cheese() {
	mut g := new_rodent_game()
	g.cats.clear()
	g.cats << Cat{
		x: 5
		y: 5
	}
	// Surround cat with blocks
	g.grid[5][4] = .block
	g.grid[5][6] = .block
	g.grid[4][5] = .block
	g.grid[6][5] = .block

	g.check_cat_traps()
	assert g.cats.len == 0
	assert g.grid[5][5] == .cheese
	assert g.score >= 1000
}
