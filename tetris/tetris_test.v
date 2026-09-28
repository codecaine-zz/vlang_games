module main

fn test_tetris_initialization() {
	game := new_tetris_game()
	assert game.score == 0
	assert game.lines == 0
	assert game.level == 1
	assert game.game_over == false
}

fn test_tetris_piece_move() {
	mut game := new_tetris_game()
	start_x := game.curr_piece.x
	moved := game.move_right()
	assert moved == true
	assert game.curr_piece.x == start_x + 1
}

fn test_tetris_hard_drop() {
	mut game := new_tetris_game()
	drop_dist := game.hard_drop()
	assert drop_dist > 0
}

fn test_tetris_line_clearing() {
	mut game := new_tetris_game()
	// Fill bottom row except last cell
	for col in 0 .. grid_cols - 1 {
		game.grid[grid_rows - 1][col] = 1
	}
	game.grid[grid_rows - 1][grid_cols - 1] = 1 // Full row!
	cleared := game.clear_lines()
	assert cleared == 1
	assert game.score == 100
}
