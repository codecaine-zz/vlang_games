module main

import rand

const column_order = [3, 2, 4, 1, 5, 0, 6]

fn get_best_move(board Board, diff Difficulty) int {
	mut valid_cols := []int{}
	for c in 0 .. board_cols {
		if board.is_valid_col(c) {
			valid_cols << c
		}
	}
	if valid_cols.len == 0 {
		return 0
	}

	// 1. Immediate Win Check & Immediate Block Check (All Difficulties)
	for col in valid_cols {
		mut temp_board := board
		temp_board.drop_piece(col)
		if temp_board.state == .won_p2 {
			return col // Take immediate win!
		}
	}

	for col in valid_cols {
		mut temp_board := board
		temp_board.current_turn = 1 // Opponent
		temp_board.drop_piece(col)
		if temp_board.state == .won_p1 {
			return col // Block immediate opponent win!
		}
	}

	if diff == .easy {
		return valid_cols[rand.intn(valid_cols.len) or { 0 }]
	}

	depth := if diff == .medium { 3 } else { 5 }

	mut best_score := -1000000000
	mut best_col := valid_cols[0]

	for col in column_order {
		if !board.is_valid_col(col) {
			continue
		}
		mut temp_board := board
		temp_board.drop_piece(col)

		score := minimax(mut temp_board, depth - 1, -1000000000, 1000000000, false)
		if score > best_score {
			best_score = score
			best_col = col
		}
	}

	return best_col
}

fn minimax(mut board Board, depth int, alpha_val int, beta_val int, is_maximizing bool) int {
	mut alpha := alpha_val
	mut beta := beta_val

	if board.state == .won_p2 {
		return 1000000 + depth
	}
	if board.state == .won_p1 {
		return -1000000 - depth
	}
	if board.state == .draw || depth == 0 {
		return evaluate_board(board)
	}

	if is_maximizing {
		mut value := -1000000000
		for col in column_order {
			if !board.is_valid_col(col) {
				continue
			}
			mut next_board := board
			next_board.drop_piece(col)

			score := minimax(mut next_board, depth - 1, alpha, beta, false)
			if score > value {
				value = score
			}
			if value > alpha {
				alpha = value
			}
			if alpha >= beta {
				break
			}
		}
		return value
	} else {
		mut value := 1000000000
		for col in column_order {
			if !board.is_valid_col(col) {
				continue
			}
			mut next_board := board
			next_board.drop_piece(col)

			score := minimax(mut next_board, depth - 1, alpha, beta, true)
			if score < value {
				value = score
			}
			if value < beta {
				beta = value
			}
			if alpha >= beta {
				break
			}
		}
		return value
	}
}

fn evaluate_board(board &Board) int {
	mut score := 0

	// Score center column preference
	mut center_count := 0
	for r in 0 .. board_rows {
		if board.grid[r][3] == 2 {
			center_count++
		}
	}
	score += center_count * 6

	// Evaluate horizontal windows
	for r in 0 .. board_rows {
		for c in 0 .. board_cols - 3 {
			w := [board.grid[r][c], board.grid[r][c + 1], board.grid[r][c + 2], board.grid[r][c + 3]]
			score += evaluate_window(w)
		}
	}

	// Evaluate vertical windows
	for c in 0 .. board_cols {
		for r in 0 .. board_rows - 3 {
			w := [board.grid[r][c], board.grid[r + 1][c], board.grid[r + 2][c], board.grid[r + 3][c]]
			score += evaluate_window(w)
		}
	}

	// Evaluate positive slope diagonals
	for r in 0 .. board_rows - 3 {
		for c in 0 .. board_cols - 3 {
			w := [board.grid[r][c], board.grid[r + 1][c + 1], board.grid[r + 2][c + 2], board.grid[
				r + 3][c + 3]]
			score += evaluate_window(w)
		}
	}

	// Evaluate negative slope diagonals
	for r in 3 .. board_rows {
		for c in 0 .. board_cols - 3 {
			w := [board.grid[r][c], board.grid[r - 1][c + 1], board.grid[r - 2][c + 2], board.grid[r - 3][
				c + 3]]
			score += evaluate_window(w)
		}
	}

	return score
}

fn evaluate_window(window []int) int {
	mut p2_count := 0
	mut p1_count := 0
	mut empty_count := 0

	for val in window {
		if val == 2 {
			p2_count++
		} else if val == 1 {
			p1_count++
		} else {
			empty_count++
		}
	}

	if p2_count == 4 {
		return 10000
	} else if p2_count == 3 && empty_count == 1 {
		return 100
	} else if p2_count == 2 && empty_count == 2 {
		return 10
	}

	if p1_count == 3 && empty_count == 1 {
		return -80
	}

	return 0
}
