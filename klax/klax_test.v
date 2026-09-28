module main

fn test_klax_init() {
	mut g := new_klax_game()
	assert g.state == .playing
	assert g.paddle_lane == 2
	assert g.drops_left == 3
	assert g.wave == 1
	assert g.goal_type == .klaxes
}

fn test_klax_horizontal_match() {
	mut g := new_klax_game()
	// Place 3 Red tiles (type 1) at bottom row
	g.bin[4][0] = 1
	g.bin[4][1] = 1
	g.bin[4][2] = 1

	matched := g.check_bin_matches()
	assert matched == true
	assert g.clearing_pos.len == 3
	assert g.state == .clearing
}

fn test_klax_vertical_match() {
	mut g := new_klax_game()
	// Place 3 Blue tiles (type 2) in column 2
	g.bin[2][2] = 2
	g.bin[3][2] = 2
	g.bin[4][2] = 2

	matched := g.check_bin_matches()
	assert matched == true
	assert g.clearing_pos.len == 3
}

fn test_klax_diagonal_match() {
	mut g := new_klax_game()
	// Place 3 Green tiles (type 3) in diagonal
	g.bin[2][0] = 3
	g.bin[3][1] = 3
	g.bin[4][2] = 3

	matched := g.check_bin_matches()
	assert matched == true
	assert g.clearing_pos.len == 3
}

fn test_klax_wild_tile_match() {
	mut g := new_klax_game()
	// Place 2 Yellow tiles (type 4) and 1 Wild tile (type 6)
	g.bin[4][0] = 4
	g.bin[4][1] = wild_tile_type
	g.bin[4][2] = 4

	matched := g.check_bin_matches()
	assert matched == true
	assert g.clearing_pos.len == 3
}

fn test_klax_flip_into_bin() {
	mut g := new_klax_game()
	g.paddle_tiles << 1
	g.paddle_lane = 0
	ok := g.flip_tile()
	assert ok == true
	assert g.bin[4][0] == 1
	assert g.paddle_tiles.len == 0
}
