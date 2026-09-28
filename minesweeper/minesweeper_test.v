module main

fn test_minesweeper_initialization() {
	mut ms := new_minesweeper(.beginner)
	assert ms.cols == 9
	assert ms.rows == 9
	assert ms.total_mines == 10
	assert ms.state == .ready
	assert ms.face_state == .normal
	assert ms.first_click == true
	assert ms.get_remaining_mines() == 10

	ms.set_difficulty(.intermediate)
	assert ms.cols == 16
	assert ms.rows == 16
	assert ms.total_mines == 40
	assert ms.get_remaining_mines() == 40

	ms.set_difficulty(.expert)
	assert ms.cols == 30
	assert ms.rows == 16
	assert ms.total_mines == 99
	assert ms.get_remaining_mines() == 99
}

fn test_first_click_safety() {
	mut ms := new_minesweeper(.beginner)
	first_r := 4
	first_c := 4

	// First click on (4, 4) should never hit a mine
	hit_mine, opened := ms.reveal_cell(first_r, first_c)
	assert hit_mine == false
	assert opened >= 1
	assert ms.state == .playing
	assert ms.first_click == false
	assert ms.cells[first_r][first_c].is_mine == false
	assert ms.cells[first_r][first_c].state == .revealed

	// Verify exact number of mines on board
	mut mine_count := 0
	for r in 0 .. ms.rows {
		for c in 0 .. ms.cols {
			if ms.cells[r][c].is_mine {
				mine_count++
			}
		}
	}
	assert mine_count == 10
}

fn test_flag_toggling() {
	mut ms := new_minesweeper(.beginner)
	assert ms.get_remaining_mines() == 10

	// Toggle to flag
	st1 := ms.toggle_flag(0, 0)
	assert st1 == .flagged
	assert ms.flags_placed == 1
	assert ms.get_remaining_mines() == 9

	// Toggle to question
	st2 := ms.toggle_flag(0, 0)
	assert st2 == .question
	assert ms.flags_placed == 0
	assert ms.get_remaining_mines() == 10

	// Toggle to hidden
	st3 := ms.toggle_flag(0, 0)
	assert st3 == .hidden
	assert ms.flags_placed == 0
	assert ms.get_remaining_mines() == 10
}

fn test_deterministic_board_mechanics() {
	// Construct a known 3x3 board manually
	mut ms := Minesweeper{
		difficulty:  .custom
		cols:        3
		rows:        3
		total_mines: 1
		cells:       [][]Cell{len: 3, init: []Cell{len: 3, init: Cell{}}}
		state:       .playing
		first_click: false
	}
	// Mine at (0, 0)
	ms.cells[0][0].is_mine = true
	// Numbers around (0,0)
	ms.cells[0][1].neighbor_mines = 1
	ms.cells[1][0].neighbor_mines = 1
	ms.cells[1][1].neighbor_mines = 1

	// Reveal (2, 2) which has neighbor_mines = 0
	hit_mine, opened := ms.reveal_cell(2, 2)
	assert hit_mine == false
	// BFS should cascade to (2,2), (2,1), (1,2), (2,0), (0,2), (1,1), (0,1), (1,0) = 8 safe cells
	assert opened == 8
	assert ms.revealed_count == 8
	assert ms.state == .won
	assert ms.face_state == .cool
}

fn test_chording() {
	// Construct 3x3 board
	mut ms := Minesweeper{
		difficulty:  .custom
		cols:        3
		rows:        3
		total_mines: 1
		cells:       [][]Cell{len: 3, init: []Cell{len: 3, init: Cell{}}}
		state:       .playing
		first_click: false
	}
	ms.cells[0][0].is_mine = true
	ms.cells[0][1].neighbor_mines = 1
	ms.cells[0][1].state = .revealed
	ms.revealed_count = 1

	// Flag the mine at (0, 0)
	ms.cells[0][0].state = .flagged
	ms.flags_placed = 1

	// Chord on (0, 1)
	hit_mine, opened := ms.chord_cell(0, 1)
	assert hit_mine == false
	assert opened > 0
	// Non-flagged neighbors should now be revealed
	assert ms.cells[1][0].state == .revealed
	assert ms.cells[1][1].state == .revealed
	assert ms.cells[0][2].state == .revealed
}

fn test_mine_detonation_game_over() {
	mut ms := Minesweeper{
		difficulty:  .custom
		cols:        2
		rows:        2
		total_mines: 1
		cells:       [][]Cell{len: 2, init: []Cell{len: 2, init: Cell{}}}
		state:       .playing
		first_click: false
	}
	ms.cells[0][0].is_mine = true

	hit_mine, _ := ms.reveal_cell(0, 0)
	assert hit_mine == true
	assert ms.state == .lost
	assert ms.face_state == .dead
	assert ms.cells[0][0].exploded == true
}
