module main

fn test_game2048_initialization() {
	mut g := new_game_2048()
	assert g.grid.len == 4
	assert g.grid[0].len == 4
	assert g.score == 0
	assert g.state == .playing
	assert g.history.len == 0

	// Exactly 2 tiles should be non-zero
	mut count := 0
	for r in 0 .. 4 {
		for c in 0 .. 4 {
			if g.grid[r][c] > 0 {
				count++
			}
		}
	}
	assert count == 2
}

fn test_slide_and_merge_logic() {
	mut g := Game2048{
		grid: [][]int{len: 4, init: []int{len: 4, init: 0}}
	}
	// Row 0: [2, 2, 2, 2] -> slide left should result in [4, 4, 0, 0]
	g.grid[0] = [2, 2, 2, 2]
	// Row 1: [2, 0, 2, 4] -> slide left should result in [4, 4, 0, 0]
	g.grid[1] = [2, 0, 2, 4]

	moved, pts, max_m := g.slide(.left)
	assert moved == true
	assert g.grid[0][0] == 4
	assert g.grid[0][1] == 4
	assert g.grid[1][0] == 4
	assert g.grid[1][1] == 4
	assert max_m == 4
	assert pts == 12 // 4 + 4 + 4
}

fn test_undo_state_restoration() {
	mut g := Game2048{
		grid: [][]int{len: 4, init: []int{len: 4, init: 0}}
	}
	g.grid[0] = [2, 2, 0, 0]

	g.slide(.left)
	assert g.grid[0][0] == 4
	assert g.score == 4
	assert g.history.len == 1

	// Undo
	ok := g.undo()
	assert ok == true
	assert g.grid[0] == [2, 2, 0, 0]
	assert g.score == 0
}

fn test_can_move_detection() {
	mut g := Game2048{
		grid: [][]int{len: 4, init: []int{len: 4, init: 0}}
	}
	// Board completely full with alternating non-matching numbers:
	// 2 4 2 4
	// 4 2 4 2
	// 2 4 2 4
	// 4 2 4 2
	g.grid[0] = [2, 4, 2, 4]
	g.grid[1] = [4, 2, 4, 2]
	g.grid[2] = [2, 4, 2, 4]
	g.grid[3] = [4, 2, 4, 2]

	assert g.can_move() == false
}
