module main

enum CellState {
	empty
	filled
	crossed
}

struct Puzzle {
pub mut:
	name        string
	width       int
	height      int
	solution    [][]bool
	grid        [][]CellState
	row_clues   [][]int
	col_clues   [][]int
	row_solved  []bool
	col_solved  []bool
	completed   bool
	art_color   Color
	toast_msg   string
	toast_timer f64
}

fn compute_row_clues(solution [][]bool) [][]int {
	height := solution.len
	mut res := [][]int{len: height}
	for r in 0 .. height {
		mut clues := []int{}
		mut count := 0
		for c in 0 .. solution[r].len {
			if solution[r][c] {
				count++
			} else if count > 0 {
				clues << count
				count = 0
			}
		}
		if count > 0 {
			clues << count
		}
		if clues.len == 0 {
			clues << 0
		}
		res[r] = clues
	}
	return res
}

fn compute_col_clues(solution [][]bool) [][]int {
	if solution.len == 0 {
		return [][]int{}
	}
	height := solution.len
	width := solution[0].len
	mut res := [][]int{len: width}
	for c in 0 .. width {
		mut clues := []int{}
		mut count := 0
		for r in 0 .. height {
			if solution[r][c] {
				count++
			} else if count > 0 {
				clues << count
				count = 0
			}
		}
		if count > 0 {
			clues << count
		}
		if clues.len == 0 {
			clues << 0
		}
		res[c] = clues
	}
	return res
}

fn create_puzzle(name string, solution_pattern []string, art_color Color) Puzzle {
	height := solution_pattern.len
	width := if height > 0 { solution_pattern[0].len } else { 0 }
	mut sol := [][]bool{len: height}
	mut grid := [][]CellState{len: height}

	for r in 0 .. height {
		mut sol_row := []bool{len: width}
		mut grid_row := []CellState{len: width}
		for c in 0 .. width {
			ch := solution_pattern[r][c]
			sol_row[c] = (ch == `#` || ch == `O` || ch == `1` || ch == `X`)
			grid_row[c] = .empty
		}
		sol[r] = sol_row
		grid[r] = grid_row
	}

	row_clues := compute_row_clues(sol)
	col_clues := compute_col_clues(sol)

	return Puzzle{
		name:       name
		width:      width
		height:     height
		solution:   sol
		grid:       grid
		row_clues:  row_clues
		col_clues:  col_clues
		row_solved: []bool{len: height}
		col_solved: []bool{len: width}
		completed:  false
		art_color:  art_color
	}
}

fn (mut p Puzzle) reset() {
	for r in 0 .. p.height {
		p.row_solved[r] = false
		for c in 0 .. p.width {
			p.grid[r][c] = .empty
		}
	}
	for c in 0 .. p.width {
		p.col_solved[c] = false
	}
	p.completed = false
}

fn (p &Puzzle) is_row_correct(r int) bool {
	for c in 0 .. p.width {
		is_sol := p.solution[r][c]
		is_filled := p.grid[r][c] == .filled
		if is_sol != is_filled {
			return false
		}
	}
	return true
}

fn (p &Puzzle) is_col_correct(c int) bool {
	for r in 0 .. p.height {
		is_sol := p.solution[r][c]
		is_filled := p.grid[r][c] == .filled
		if is_sol != is_filled {
			return false
		}
	}
	return true
}

fn (mut p Puzzle) update_status() bool {
	mut all_correct := true
	for r in 0 .. p.height {
		p.row_solved[r] = p.is_row_correct(r)
		if !p.row_solved[r] {
			all_correct = false
		}
	}
	for c in 0 .. p.width {
		p.col_solved[c] = p.is_col_correct(c)
		if !p.col_solved[c] {
			all_correct = false
		}
	}
	p.completed = all_correct
	return all_correct
}

fn (mut p Puzzle) use_hint() (int, int, bool) {
	if p.completed {
		return -1, -1, false
	}
	// Look for unrevealed cell that should be filled or uncrossed cell that should be empty
	for r in 0 .. p.height {
		for c in 0 .. p.width {
			if p.solution[r][c] && p.grid[r][c] != .filled {
				p.grid[r][c] = .filled
				p.update_status()
				return r, c, true
			} else if !p.solution[r][c] && p.grid[r][c] != .crossed {
				p.grid[r][c] = .crossed
				p.update_status()
				return r, c, true
			}
		}
	}
	return -1, -1, false
}

pub fn (mut p Puzzle) save_progress(puzzle_idx int) {
	mut saved := load_picross_save()
	saved.puzzle_idx = puzzle_idx
	if p.completed {
		if puzzle_idx !in saved.solved_puzzles {
			saved.solved_puzzles << puzzle_idx
		}
	}
	save_picross_data(&saved)
}

pub fn (mut p Puzzle) save_state(puzzle_idx int) {
	p.save_progress(puzzle_idx)
	mut saved := load_picross_save()
	saved.save_state_valid = true
	saved.state_puzzle_idx = puzzle_idx

	mut lines := []string{}
	for r in 0 .. p.height {
		mut row_str := ''
		for c in 0 .. p.width {
			st := int(p.grid[r][c])
			row_str += '${st},'
		}
		lines << row_str
	}
	saved.grid_lines = lines
	save_picross_data(&saved)

	p.toast_msg = 'GAME SAVED (F5)'
	p.toast_timer = 2.0
}

pub fn (mut p Puzzle) load_state(puzzle_idx int) {
	saved := load_picross_save()
	if !saved.save_state_valid || saved.grid_lines.len < p.height {
		p.toast_msg = 'NO SAVE FOUND'
		p.toast_timer = 2.0
		return
	}
	for r in 0 .. p.height {
		if r < saved.grid_lines.len {
			line := saved.grid_lines[r]
			tokens := line.split(',')
			for c in 0 .. p.width {
				if c < tokens.len && tokens[c] != '' {
					p.grid[r][c] = unsafe { CellState(tokens[c].int()) }
				}
			}
		}
	}
	p.update_status()
	p.toast_msg = 'GAME LOADED (F9)'
	p.toast_timer = 2.0
}
