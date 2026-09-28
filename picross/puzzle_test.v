module main

fn test_compute_clues() {
	sol := [
		[true, true, false, true, true],
		[false, false, false, false, false],
		[true, true, true, true, true],
		[true, false, true, false, true],
		[false, true, true, true, false],
	]

	row_clues := compute_row_clues(sol)
	assert row_clues[0] == [2, 2]
	assert row_clues[1] == [0]
	assert row_clues[2] == [5]
	assert row_clues[3] == [1, 1, 1]
	assert row_clues[4] == [3]

	col_clues := compute_col_clues(sol)
	assert col_clues[0] == [1, 2]
	assert col_clues[1] == [1, 1, 1]
	assert col_clues[2] == [3]
	assert col_clues[3] == [1, 1, 1]
	assert col_clues[4] == [1, 2]
}

fn test_puzzle_creation_and_solve() {
	mut p := create_puzzle(
		'Test 3x3',
		[
			'#.#',
			'###',
			'.#.',
		],
		Color{r: 255, g: 0, b: 0}
	)

	assert p.width == 3
	assert p.height == 3
	assert !p.completed

	// Fill cells
	p.grid[0][0] = .filled
	p.grid[0][2] = .filled
	p.grid[1][0] = .filled
	p.grid[1][1] = .filled
	p.grid[1][2] = .filled
	p.grid[2][1] = .filled

	assert p.update_status()
	assert p.completed
}

fn test_puzzle_hints() {
	mut p := create_puzzle(
		'Hint Test',
		[
			'#.',
			'.#',
		],
		Color{r: 255, g: 255, b: 255}
	)

	r1, c1, ok1 := p.use_hint()
	assert ok1
	assert r1 == 0 && c1 == 0
	assert p.grid[0][0] == .filled
}
