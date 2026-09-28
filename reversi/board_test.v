module main

fn test_board_initial_state() {
	b := new_board()
	assert b.black_count == 2
	assert b.white_count == 2
	assert b.current_player == piece_black
	assert !b.game_over

	// Center positions
	assert b.cells[3][3] == piece_white
	assert b.cells[3][4] == piece_black
	assert b.cells[4][3] == piece_black
	assert b.cells[4][4] == piece_white
}

fn test_valid_moves() {
	b := new_board()
	moves := b.get_valid_moves(piece_black)
	// Standard opening 4 valid moves for Black: (2,3), (3,2), (4,5), (5,4)
	assert moves.len == 4
	assert b.is_valid_move(2, 3, piece_black)
	assert b.is_valid_move(3, 2, piece_black)
	assert b.is_valid_move(4, 5, piece_black)
	assert b.is_valid_move(5, 4, piece_black)
	assert !b.is_valid_move(0, 0, piece_black)
}

fn test_make_move_and_flip() {
	mut b := new_board()
	flips, ok := b.make_move(2, 3)
	assert ok
	assert flips.len == 1
	assert flips[0].r == 3 && flips[0].c == 3

	// Now (2,3) is Black, and flipped (3,3) is now Black
	assert b.cells[2][3] == piece_black
	assert b.cells[3][3] == piece_black
	assert b.black_count == 4
	assert b.white_count == 1
	assert b.current_player == piece_white
}

fn test_undo() {
	mut b := new_board()
	b.make_move(2, 3)
	assert b.black_count == 4

	ok := b.undo()
	assert ok
	assert b.black_count == 2
	assert b.white_count == 2
	assert b.current_player == piece_black
}

fn test_ai_selection() {
	b := new_board()
	best := get_ai_best_move(&b, piece_black, .tactician)
	assert best.r >= 0 && best.c >= 0
	assert b.is_valid_move(best.r, best.c, piece_black)
}
