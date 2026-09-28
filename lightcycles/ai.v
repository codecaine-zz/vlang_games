module main

import math

pub fn compute_ai_move(grid [][]int, head_r int, head_c int, curr_dir Direction, diff Difficulty) Direction {
	rows := grid.len
	cols := grid[0].len

	// Candidate moves (no 180-degree instant reversal)
	mut valid_dirs := []Direction{}
	all_dirs := [Direction.up, Direction.right, Direction.down, Direction.left]

	for d in all_dirs {
		if is_opposite_dir(curr_dir, d) {
			continue
		}
		dr, dc := dir_offsets(d)
		nr := head_r + dr
		nc := head_c + dc
		if nr >= 0 && nr < rows && nc >= 0 && nc < cols {
			if grid[nr][nc] == 0 {
				valid_dirs << d
			}
		}
	}

	if valid_dirs.len == 0 {
		return curr_dir // Trapped
	}
	if valid_dirs.len == 1 {
		return valid_dirs[0]
	}

	// For Easy mode: keep going or pick random safe direction
	if diff == .easy {
		for d in valid_dirs {
			if d == curr_dir {
				return d
			}
		}
		return valid_dirs[0]
	}

	// For Normal: Flood Fill lookahead (60 cells)
	// For Master: Deeper Flood Fill lookahead (160 cells) + Dead-end lookahead + Cutting tactics
	max_depth := match diff {
		.normal { 60 }
		.master { 160 }
		else { 60 }
	}

	mut best_dir := valid_dirs[0]
	mut max_score := -999999

	// Locate opponent's head if possible (value 1 in grid)
	mut opp_r := -1
	mut opp_c := -1
	if diff == .master {
		for r in 0 .. rows {
			for c in 0 .. cols {
				if grid[r][c] == 1 {
					// Check if this might be the head (has adjacent empty cell)
					opp_r = r
					opp_c = c
				}
			}
		}
	}

	for d in valid_dirs {
		dr, dc := dir_offsets(d)
		nr := head_r + dr
		nc := head_c + dc

		// Check 2-step exit count: does (nr, nc) have available exits?
		mut immediate_exits := 0
		for exit_d in all_dirs {
			edr, edc := dir_offsets(exit_d)
			enr := nr + edr
			enc := nc + edc
			if enr >= 0 && enr < rows && enc >= 0 && enc < cols {
				if grid[enr][enc] == 0 && (enr != head_r || enc != head_c) {
					immediate_exits++
				}
			}
		}

		// Heavy penalty for heading into a 0-exit dead end
		if immediate_exits == 0 {
			continue
		}

		open_area := flood_fill_count(grid, nr, nc, max_depth)
		mut score := open_area * 10

		// Bonus for more immediate exits (avoids narrowing corridors)
		score += immediate_exits * 5

		// Bias to continue straight to prevent unnecessary swerving
		if d == curr_dir {
			score += 3
		}

		// Master: Strategic cutoff heuristic
		if diff == .master && opp_r >= 0 {
			// Encourage positioning that corners the opponent without suffocating self
			dist_to_opp := math.abs(nr - opp_r) + math.abs(nc - opp_c)
			if open_area >= max_depth / 2 {
				// We have plenty of room; apply pressure
				score -= dist_to_opp
			}
		}

		if score > max_score {
			max_score = score
			best_dir = d
		}
	}

	return best_dir
}

fn flood_fill_count(grid [][]int, start_r int, start_c int, max_depth int) int {
	rows := grid.len
	cols := grid[0].len
	mut visited := [][]bool{len: rows, init: []bool{len: cols, init: false}}
	mut queue := [ [start_r, start_c] ]
	visited[start_r][start_c] = true
	mut q_head := 0
	mut count := 0

	for q_head < queue.len && count < max_depth {
		pos := queue[q_head]
		q_head++
		count++

		r := pos[0]
		c := pos[1]
		dirs := [[-1, 0], [1, 0], [0, -1], [0, 1]]
		for d in dirs {
			nr := r + d[0]
			nc := c + d[1]
			if nr >= 0 && nr < rows && nc >= 0 && nc < cols {
				if grid[nr][nc] == 0 && !visited[nr][nc] {
					visited[nr][nc] = true
					queue << [nr, nc]
				}
			}
		}
	}
	return count
}
