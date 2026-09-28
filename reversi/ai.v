module main

import rand

enum Difficulty {
	novice
	tactician
	grandmaster
}

const position_weights = [
	[ 100, -20,  10,   5,   5,  10, -20,  100],
	[-20,  -40,  -5,  -5,  -5,  -5, -40,  -20],
	[  10,  -5,   3,   1,   1,   3,  -5,   10],
	[   5,  -5,   1,   1,   1,   1,  -5,    5],
	[   5,  -5,   1,   1,   1,   1,  -5,    5],
	[  10,  -5,   3,   1,   1,   3,  -5,   10],
	[-20,  -40,  -5,  -5,  -5,  -5, -40,  -20],
	[ 100, -20,  10,   5,   5,  10, -20,  100],
]

fn evaluate_board(b &Board, player int) int {
	opp := opponent_of(player)

	// 1. Positional Weights
	mut pos_score := 0
	for r in 0 .. board_size {
		for c in 0 .. board_size {
			if b.cells[r][c] == player {
				pos_score += position_weights[r][c]
			} else if b.cells[r][c] == opp {
				pos_score -= position_weights[r][c]
			}
		}
	}

	// 2. Mobility
	player_moves := b.get_valid_moves(player).len
	opp_moves := b.get_valid_moves(opp).len
	mobility_score := (player_moves - opp_moves) * 12

	// 3. Disc Count Parity
	mut player_discs := 0
	mut opp_discs := 0
	if player == piece_black {
		player_discs = b.black_count
		opp_discs = b.white_count
	} else {
		player_discs = b.white_count
		opp_discs = b.black_count
	}
	
	total_discs := player_discs + opp_discs
	disc_parity := if total_discs > 50 { (player_discs - opp_discs) * 15 } else { (player_discs - opp_discs) * 2 }

	return pos_score + mobility_score + disc_parity
}

fn minimax_alpha_beta(mut b Board, depth int, alpha_val int, beta_val int, maximizing bool, ai_player int) int {
	if depth == 0 || b.game_over {
		return evaluate_board(b, ai_player)
	}

	mut alpha := alpha_val
	mut beta := beta_val

	curr_player := if maximizing { ai_player } else { opponent_of(ai_player) }
	moves := b.get_valid_moves(curr_player)

	if moves.len == 0 {
		// Pass turn
		opp := opponent_of(curr_player)
		opp_moves := b.get_valid_moves(opp)
		if opp_moves.len == 0 {
			// Both pass = game over
			return evaluate_board(b, ai_player)
		}
		// Pass to opponent
		return minimax_alpha_beta(mut b, depth - 1, alpha, beta, !maximizing, ai_player)
	}

	if maximizing {
		mut max_eval := -1000000
		for pt in moves {
			mut clone := b
			clone.current_player = curr_player
			clone.make_move(pt.r, pt.c)
			eval := minimax_alpha_beta(mut clone, depth - 1, alpha, beta, false, ai_player)
			if eval > max_eval {
				max_eval = eval
			}
			if eval > alpha {
				alpha = eval
			}
			if beta <= alpha {
				break
			}
		}
		return max_eval
	} else {
		mut min_eval := 1000000
		for pt in moves {
			mut clone := b
			clone.current_player = curr_player
			clone.make_move(pt.r, pt.c)
			eval := minimax_alpha_beta(mut clone, depth - 1, alpha, beta, true, ai_player)
			if eval < min_eval {
				min_eval = eval
			}
			if eval < beta {
				beta = eval
			}
			if beta <= alpha {
				break
			}
		}
		return min_eval
	}
}

fn get_ai_best_move(b &Board, ai_player int, diff Difficulty) Point {
	valid_moves := b.get_valid_moves(ai_player)
	if valid_moves.len == 0 {
		return Point{r: -1, c: -1}
	}

	if diff == .novice {
		// 30% chance random move, otherwise 1-ply evaluation
		if rand.f64() < 0.3 {
			return valid_moves[rand.int_in_range(0, valid_moves.len) or { 0 }]
		}
	}

	mut max_depth := 1
	match diff {
		.novice { max_depth = 1 }
		.tactician { max_depth = 3 }
		.grandmaster {
			total_discs := b.black_count + b.white_count
			empty_cells := 64 - total_discs
			max_depth = if empty_cells <= 10 { 7 } else { 4 }
		}
	}

	mut best_move := valid_moves[0]
	mut best_val := -1000000

	for pt in valid_moves {
		mut clone := *b
		clone.current_player = ai_player
		clone.make_move(pt.r, pt.c)
		val := minimax_alpha_beta(mut clone, max_depth - 1, -1000000, 1000000, false, ai_player)
		if val > best_val {
			best_val = val
			best_move = pt
		}
	}

	return best_move
}
