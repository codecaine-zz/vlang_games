module main

import math
import rand

pub const grid_cols = 8
pub const grid_rows = 5
pub const total_cells = grid_cols * grid_rows

pub struct ChimpCell {
pub mut:
	grid_x     int
	grid_y     int
	number     int  // 1..N (0 if empty)
	is_clicked bool
	is_error   bool
}

pub enum ChimpState {
	ready
	active_hidden
	level_failed
	benchmark_over
}

pub struct ChimpGame {
pub mut:
	state          ChimpState = .ready
	level          int        = 4 // Number of active tiles (starts at 4)
	max_level      int        = 4
	strikes        int
	max_strikes    int = 3
	next_expected  int = 1
	cells          []ChimpCell
	high_score     int = 4
	percentile     f64
	reaction_timer f64
}

pub fn new_chimp_game() ChimpGame {
	mut g := ChimpGame{}
	g.reset_game()
	return g
}

pub fn (mut g ChimpGame) reset_game() {
	g.level = 4
	g.strikes = 0
	g.next_expected = 1
	g.start_level()
}

pub fn (mut g ChimpGame) start_level() {
	g.state = .ready
	g.next_expected = 1
	g.cells.clear()

	// Pick `g.level` unique random cell positions out of total_cells
	mut positions := []int{cap: total_cells}
	for i in 0 .. total_cells {
		positions << i
	}

	// Shuffle
	for i := positions.len - 1; i > 0; i-- {
		j := rand.intn(i + 1) or { 0 }
		temp := positions[i]
		positions[i] = positions[j]
		positions[j] = temp
	}

	// Initialize empty cells
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			g.cells << ChimpCell{
				grid_x:     c
				grid_y:     r
				number:     0
				is_clicked: false
				is_error:   false
			}
		}
	}

	// Assign numbers 1..g.level to selected positions
	for num in 1 .. g.level + 1 {
		cell_pos := positions[num - 1]
		g.cells[cell_pos].number = num
	}
}

pub struct ChimpEvents {
pub mut:
	tile_clicked  int = -1
	strike_taken  bool
	level_cleared bool
	game_over     bool
}

pub fn (mut g ChimpGame) handle_cell_click(gx int, gy int) (bool, ChimpEvents) {
	mut ev := ChimpEvents{}

	if g.state == .level_failed {
		// Advance after reviewing failure
		if g.strikes >= g.max_strikes {
			g.state = .benchmark_over
			g.calculate_percentile()
			ev.game_over = true
		} else {
			g.start_level()
		}
		return true, ev
	} else if g.state == .benchmark_over {
		g.reset_game()
		return true, ev
	}

	if gx < 0 || gx >= grid_cols || gy < 0 || gy >= grid_rows {
		return false, ev
	}

	cell_idx := gy * grid_cols + gx
	if cell_idx >= g.cells.len {
		return false, ev
	}

	mut cell := &g.cells[cell_idx]
	if cell.number == 0 || cell.is_clicked {
		return false, ev
	}

	// First click transitions from visible state to hidden mask state
	if g.state == .ready {
		g.state = .active_hidden
	}

	if cell.number == g.next_expected {
		// Correct tile!
		cell.is_clicked = true
		ev.tile_clicked = g.next_expected
		g.next_expected++

		if g.next_expected > g.level {
			// Level cleared!
			if g.level > g.high_score {
				g.high_score = g.level
			}
			g.level++
			if g.level > g.max_level {
				g.max_level = g.level
			}
			ev.level_cleared = true
			g.start_level()
		}
		return true, ev
	} else {
		// Mistake!
		cell.is_error = true
		g.strikes++
		ev.strike_taken = true
		g.state = .level_failed

		if g.strikes >= g.max_strikes {
			g.calculate_percentile()
		}
		return false, ev
	}
}

pub fn (mut g ChimpGame) calculate_percentile() {
	score := math.max(g.max_level - 1, 4)
	g.percentile = match score {
		4 { 15.0 }
		5 { 30.0 }
		6 { 45.0 }
		7 { 60.0 }
		8 { 72.0 }
		9 { 82.0 }
		10 { 90.0 }
		11 { 94.0 }
		12 { 97.0 }
		13 { 98.5 }
		14 { 99.4 }
		15 { 99.8 }
		else { 99.9 }
	}
}
