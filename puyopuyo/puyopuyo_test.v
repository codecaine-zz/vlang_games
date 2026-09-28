module main

fn test_puyo_initialization() {
	mut g := new_puyo_game()
	assert g.state == .falling
	assert g.score == 0
	assert g.grid.len == puyo_rows
	assert g.grid[0].len == puyo_cols
	assert g.pair.c1 == 2
}

fn test_puyo_rotation_and_wall_kick() {
	mut g := new_puyo_game()
	assert g.pair.rot == 0

	// Rotate clockwise to sub right (rot = 1)
	ok1 := g.rotate(1)
	assert ok1 == true
	assert g.pair.rot == 1

	// Move against right wall (col 5)
	g.pair.c1 = puyo_cols - 1
	// Rotating to sub right should kick left to col 4
	ok_kick := g.rotate(1)
	assert ok_kick == true
}

fn test_gravity_settle() {
	mut g := new_puyo_game()
	// Place a floating Puyo at row 2, col 3 with empty rows below
	g.grid[2][3] = 1

	moved := g.apply_gravity()
	assert moved == true
	assert g.grid[2][3] == 0
	assert g.grid[puyo_rows - 1][3] == 1
}

fn test_match_4_pop_and_cascade() {
	mut g := new_puyo_game()
	// Create a 2x2 square of 4 Red Puyos at bottom left
	g.grid[puyo_rows - 1][0] = 1
	g.grid[puyo_rows - 1][1] = 1
	g.grid[puyo_rows - 2][0] = 1
	g.grid[puyo_rows - 2][1] = 1

	groups := g.find_connected_groups()
	assert groups.len == 1
	assert groups[0].len == 4

	// Update in settling state to trigger pop and score
	g.state = .settling
	res := g.update(0.1)
	assert res.popped == true
	assert res.cleared_count == 4
	assert g.score >= 400
}
