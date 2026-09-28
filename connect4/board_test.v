module main

fn test_board_win_vertical() {
	mut b := new_board()

	b.drop_piece(0) // Red (1)
	b.drop_piece(1) // Yellow (2)
	b.drop_piece(0) // Red (1)
	b.drop_piece(1) // Yellow (2)
	b.drop_piece(0) // Red (1)
	b.drop_piece(1) // Yellow (2)
	b.drop_piece(0) // Red (1) -> Win!

	assert b.state == .won_p1
}

fn test_board_win_horizontal() {
	mut b := new_board()

	b.drop_piece(0) // P1
	b.drop_piece(0) // P2
	b.drop_piece(1) // P1
	b.drop_piece(1) // P2
	b.drop_piece(2) // P1
	b.drop_piece(2) // P2
	b.drop_piece(3) // P1 -> Win!

	assert b.state == .won_p1
}

fn test_ai_defense_block() {
	mut b := new_board()
	b.drop_piece(3) // Red (1)
	b.drop_piece(0) // Yellow (2)
	b.drop_piece(3) // Red (1)
	b.drop_piece(1) // Yellow (2)
	b.drop_piece(3) // Red (1) - 3 in a row vertically!

	ai_move := get_best_move(b, .hard)
	assert ai_move == 3 // AI MUST block col 3
}

fn test_board_undo() {
	mut b := new_board()
	b.drop_piece(2)
	assert b.history.len == 1
	b.undo_move()
	assert b.history.len == 0
	assert b.state == .in_progress
}
