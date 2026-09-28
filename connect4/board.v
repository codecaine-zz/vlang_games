module main

const board_cols = 7
const board_rows = 6

struct Pos {
	row int
	col int
}

enum GameState {
	in_progress
	won_p1
	won_p2
	draw
}

enum GameMode {
	pvp
	pve
}

enum Difficulty {
	easy
	medium
	hard
}

struct Board {
mut:
	grid         [6][7]int
	current_turn int       = 1 // 1 for Red, 2 for Yellow
	state        GameState = .in_progress
	winning_line []Pos
	history      []Pos
}

fn new_board() Board {
	return Board{
		grid:         [6][7]int{}
		current_turn: 1
		state:        .in_progress
		winning_line: []Pos{}
		history:      []Pos{}
	}
}

fn (b &Board) get_lowest_empty_row(col int) int {
	if col < 0 || col >= board_cols {
		return -1
	}
	for r := board_rows - 1; r >= 0; r-- {
		if b.grid[r][col] == 0 {
			return r
		}
	}
	return -1
}

fn (b &Board) is_valid_col(col int) bool {
	if col < 0 || col >= board_cols {
		return false
	}
	return b.grid[0][col] == 0
}

fn (mut b Board) drop_piece(col int) bool {
	if b.state != .in_progress {
		return false
	}
	r := b.get_lowest_empty_row(col)
	if r == -1 {
		return false
	}
	b.grid[r][col] = b.current_turn
	b.history << Pos{
		row: r
		col: col
	}

	win, line := b.check_win_for_player(r, col, b.current_turn)
	if win {
		b.state = if b.current_turn == 1 { GameState.won_p1 } else { GameState.won_p2 }
		b.winning_line = line
	} else if b.is_full() {
		b.state = .draw
	} else {
		b.current_turn = if b.current_turn == 1 { 2 } else { 1 }
	}
	return true
}

fn (mut b Board) undo_move() bool {
	if b.history.len == 0 {
		return false
	}
	last_pos := b.history.pop()
	b.grid[last_pos.row][last_pos.col] = 0
	b.state = .in_progress
	b.winning_line = []Pos{}
	b.current_turn = if b.current_turn == 1 { 2 } else { 1 }
	return true
}

fn (b &Board) is_full() bool {
	for c in 0 .. board_cols {
		if b.grid[0][c] == 0 {
			return false
		}
	}
	return true
}

fn (b &Board) check_win_for_player(r int, c int, p int) (bool, []Pos) {
	// Check horizontal
	mut count := 0
	mut line := []Pos{}
	for col in 0 .. board_cols {
		if b.grid[r][col] == p {
			count++
			line << Pos{
				row: r
				col: col
			}
			if count >= 4 {
				return true, line[line.len - 4..line.len]
			}
		} else {
			count = 0
			line.clear()
		}
	}

	// Check vertical
	count = 0
	line.clear()
	for row in 0 .. board_rows {
		if b.grid[row][c] == p {
			count++
			line << Pos{
				row: row
				col: c
			}
			if count >= 4 {
				return true, line[line.len - 4..line.len]
			}
		} else {
			count = 0
			line.clear()
		}
	}

	// Check positive slope diagonal (bottom-left to top-right)
	for dr := -3; dr <= 3; dr++ {
		nr := r + dr
		nc := c + dr
		if nr >= 0 && nr < board_rows && nc >= 0 && nc < board_cols {
			// Find start of diagonal
		}
	}

	// More robust diagonal search:
	// Diagonal 1: top-left to bottom-right (r-k, c-k)
	count = 0
	line.clear()
	for k := -3; k <= 3; k++ {
		row := r + k
		col := c + k
		if row >= 0 && row < board_rows && col >= 0 && col < board_cols {
			if b.grid[row][col] == p {
				count++
				line << Pos{
					row: row
					col: col
				}
				if count >= 4 {
					return true, line[line.len - 4..line.len]
				}
			} else {
				count = 0
				line.clear()
			}
		}
	}

	// Diagonal 2: bottom-left to top-right (r-k, c+k)
	count = 0
	line.clear()
	for k := -3; k <= 3; k++ {
		row := r - k
		col := c + k
		if row >= 0 && row < board_rows && col >= 0 && col < board_cols {
			if b.grid[row][col] == p {
				count++
				line << Pos{
					row: row
					col: col
				}
				if count >= 4 {
					return true, line[line.len - 4..line.len]
				}
			} else {
				count = 0
				line.clear()
			}
		}
	}

	return false, []Pos{}
}
