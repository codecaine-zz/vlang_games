module main

fn test_blockdude_initialization() {
	mut game := new_blockdude_game()
	assert game.current_level == 0
	assert game.width == 20
	assert game.height == 11
	assert game.state == .playing
	assert game.player_x > 0
	assert game.player_y > 0
	assert !game.carrying_block
}

fn test_blockdude_movement_and_turn() {
	mut game := new_blockdude_game()
	start_x := game.player_x

	// Initial facing is right. Facing left turns player first.
	game.move_dir(.left)
	assert game.facing == .left
	assert game.moves_count == 1

	// Moving left takes a step if empty
	game.move_dir(.left)
	assert game.player_x <= start_x
}

fn test_blockdude_undo() {
	mut game := new_blockdude_game()
	game.move_dir(.right)
	assert game.moves_count > 0
	assert game.history.len > 0

	undone := game.undo()
	assert undone
}

fn test_blockdude_levels() {
	mut game := new_blockdude_game()
	game.next_level()
	assert game.current_level == 1
	game.prev_level()
	assert game.current_level == 0
}
