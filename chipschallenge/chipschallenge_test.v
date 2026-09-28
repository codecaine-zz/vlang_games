module main

fn test_chips_initialization() {
	mut g := new_chips_game()
	assert g.levels.len >= 2
	assert g.level_idx == 0
	assert g.chips_left == 4
	assert !g.is_dead
	assert !g.is_win
}

fn test_chips_key_and_door_mechanic() {
	mut g := new_chips_game()
	assert g.red_keys == 0
	// Move right to red key at (4,2)
	g.move_player(1, 0)
	g.move_player(1, 0)
	assert g.red_keys == 1

	// Move right to red door at (6,2)
	g.move_player(1, 0)
	g.move_player(1, 0)
	assert g.red_keys == 0
	assert g.grid[6][2] == .floor

	// Move right to chip at (7,2)
	g.move_player(1, 0)
	assert g.chips_left == 3
}

fn test_chips_socket_and_win() {
	mut g := new_chips_game()
	g.chips_left = 0
	// Socket at (10,5) should open
	g.player_x = 9
	g.player_y = 5
	assert g.move_player(1, 0)
	assert g.grid[10][5] == .floor

	// Exit portal at (12,5)
	g.move_player(1, 0)
	g.move_player(1, 0)
	assert g.is_win
}
