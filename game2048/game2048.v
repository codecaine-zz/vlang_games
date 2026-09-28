module main

import rand

pub enum Direction {
	up
	down
	left
	right
}

pub enum GameState {
	playing
	won
	game_over
}

pub struct MoveHistory {
pub:
	grid  [][]int
	score int
}

pub struct Game2048 {
pub mut:
	grid         [][]int
	score        int
	best_score   int = 12480
	state        GameState = .playing
	won_flag     bool
	keep_playing bool
	history      []MoveHistory
	max_tile     int
	toast_msg    string
	toast_timer  f64
}

pub fn new_game_2048() Game2048 {
	mut g := Game2048{
		grid: [][]int{len: 4, init: []int{len: 4, init: 0}}
	}
	saved := load_2048_save()
	if saved.best_score > 0 {
		g.best_score = saved.best_score
	}
	if saved.save_state_valid && saved.grid_lines.len == 4 {
		g.load_state()
	} else {
		g.reset()
	}
	return g
}

pub fn (mut g Game2048) reset() {
	g.grid = [][]int{len: 4, init: []int{len: 4, init: 0}}
	g.score = 0
	g.state = .playing
	g.won_flag = false
	g.keep_playing = false
	g.history.clear()
	g.max_tile = 2

	g.spawn_tile()
	g.spawn_tile()
}

pub fn (mut g Game2048) spawn_tile() bool {
	mut empty_cells := [][]int{}
	for r in 0 .. 4 {
		for c in 0 .. 4 {
			if g.grid[r][c] == 0 {
				empty_cells << [r, c]
			}
		}
	}
	if empty_cells.len == 0 {
		return false
	}

	idx := rand.intn(empty_cells.len) or { 0 }
	pos := empty_cells[idx]
	r := pos[0]
	c := pos[1]
	// 90% chance of 2, 10% chance of 4
	val := if (rand.intn(10) or { 0 }) == 0 { 4 } else { 2 }
	g.grid[r][c] = val

	if val > g.max_tile {
		g.max_tile = val
	}
	return true
}

pub fn (mut g Game2048) slide(dir Direction) (bool, int, int) {
	if g.state == .game_over {
		return false, 0, 0
	}

	// Save history clone before moving
	mut snap := [][]int{len: 4, init: []int{len: 4, init: 0}}
	for r in 0 .. 4 {
		for c in 0 .. 4 {
			snap[r][c] = g.grid[r][c]
		}
	}

	mut moved := false
	mut score_gained := 0
	mut max_merged := 0

	match dir {
		.left {
			for r in 0 .. 4 {
				mut row := g.grid[r].clone()
				m, pts, mx := slide_and_merge_line(mut row)
				if m {
					moved = true
					score_gained += pts
					if mx > max_merged { max_merged = mx }
					g.grid[r] = row.clone()
				}
			}
		}
		.right {
			for r in 0 .. 4 {
				mut row := g.grid[r].clone()
				row.reverse_in_place()
				m, pts, mx := slide_and_merge_line(mut row)
				if m {
					moved = true
					score_gained += pts
					if mx > max_merged { max_merged = mx }
					row.reverse_in_place()
					g.grid[r] = row.clone()
				}
			}
		}
		.up {
			for c in 0 .. 4 {
				mut col := []int{len: 4}
				for r in 0 .. 4 { col[r] = g.grid[r][c] }
				m, pts, mx := slide_and_merge_line(mut col)
				if m {
					moved = true
					score_gained += pts
					if mx > max_merged { max_merged = mx }
					for r in 0 .. 4 { g.grid[r][c] = col[r] }
				}
			}
		}
		.down {
			for c in 0 .. 4 {
				mut col := []int{len: 4}
				for r in 0 .. 4 { col[r] = g.grid[r][c] }
				col.reverse_in_place()
				m, pts, mx := slide_and_merge_line(mut col)
				if m {
					moved = true
					score_gained += pts
					if mx > max_merged { max_merged = mx }
					col.reverse_in_place()
					for r in 0 .. 4 { g.grid[r][c] = col[r] }
				}
			}
		}
	}

	if moved {
		g.history << MoveHistory{
			grid:  snap.clone()
			score: g.score
		}
		g.score += score_gained
		if g.score > g.best_score {
			g.best_score = g.score
		}

		g.spawn_tile()

		// Update max tile
		for r in 0 .. 4 {
			for c in 0 .. 4 {
				if g.grid[r][c] > g.max_tile {
					g.max_tile = g.grid[r][c]
				}
			}
		}

		// Check 2048 victory
		if !g.won_flag && g.max_tile >= 2048 {
			g.won_flag = true
			if !g.keep_playing {
				g.state = .won
			}
		}

		// Check game over
		if !g.can_move() {
			g.state = .game_over
		}
	}

	return moved, score_gained, max_merged
}

fn slide_and_merge_line(mut line []int) (bool, int, int) {
	orig := line.clone()
	mut non_zeros := []int{}
	for v in line {
		if v != 0 {
			non_zeros << v
		}
	}

	mut merged := []int{}
	mut score := 0
	mut max_m := 0
	mut skip := false

	for i in 0 .. non_zeros.len {
		if skip {
			skip = false
			continue
		}
		if i + 1 < non_zeros.len && non_zeros[i] == non_zeros[i + 1] {
			comb := non_zeros[i] * 2
			merged << comb
			score += comb
			if comb > max_m {
				max_m = comb
			}
			skip = true
		} else {
			merged << non_zeros[i]
		}
	}

	for merged.len < 4 {
		merged << 0
	}

	line = merged.clone()

	mut changed := false
	for i in 0 .. 4 {
		if orig[i] != line[i] {
			changed = true
			break
		}
	}
	return changed, score, max_m
}

pub fn (mut g Game2048) undo() bool {
	if g.history.len == 0 {
		return false
	}
	last := g.history.pop()
	g.grid = last.grid.clone()
	g.score = last.score
	g.state = .playing

	// Recompute max tile
	mut mx := 2
	for r in 0 .. 4 {
		for c in 0 .. 4 {
			if g.grid[r][c] > mx {
				mx = g.grid[r][c]
			}
		}
	}
	g.max_tile = mx
	return true
}

pub fn (g &Game2048) can_move() bool {
	// Check for any empty tile
	for r in 0 .. 4 {
		for c in 0 .. 4 {
			if g.grid[r][c] == 0 {
				return true
			}
		}
	}
	// Check for horizontal adjacent matches
	for r in 0 .. 4 {
		for c in 0 .. 3 {
			if g.grid[r][c] == g.grid[r][c + 1] {
				return true
			}
		}
	}
	// Check for vertical adjacent matches
	for r in 0 .. 3 {
		for c in 0 .. 4 {
			if g.grid[r][c] == g.grid[r + 1][c] {
				return true
			}
		}
	}
	return false
}

pub fn (mut g Game2048) save_progress() {
	if g.score > g.best_score {
		g.best_score = g.score
	}
	mut saved := load_2048_save()
	saved.best_score = g.best_score
	saved.score = g.score
	saved.max_tile = g.max_tile
	saved.save_state_valid = true
	
	mut lines := []string{}
	for r in 0 .. 4 {
		mut row_str := ''
		for c in 0 .. 4 {
			row_str += '${g.grid[r][c]},'
		}
		lines << row_str
	}
	saved.grid_lines = lines
	save_2048_data(&saved)
}

pub fn (mut g Game2048) save_state() {
	g.save_progress()
	g.toast_msg = 'GAME SAVED (F5)'
	g.toast_timer = 2.0
}

pub fn (mut g Game2048) load_state() {
	saved := load_2048_save()
	if !saved.save_state_valid || saved.grid_lines.len < 4 {
		g.toast_msg = 'NO SAVE STATE FOUND'
		g.toast_timer = 2.0
		return
	}
	if saved.best_score > 0 {
		g.best_score = saved.best_score
	}
	g.score = saved.score
	g.max_tile = saved.max_tile
	for r in 0 .. 4 {
		line := saved.grid_lines[r]
		tokens := line.split(',')
		for c in 0 .. 4 {
			if c < tokens.len && tokens[c] != '' {
				g.grid[r][c] = tokens[c].int()
			}
		}
	}
	g.state = .playing
	g.toast_msg = 'GAME LOADED (F9)'
	g.toast_timer = 2.0
}

