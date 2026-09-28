module main

import time

import rand


pub enum Difficulty {
	beginner
	intermediate
	expert
	custom
}

pub enum GameState {
	ready
	playing
	won
	lost
}

pub enum FaceState {
	normal
	shock
	cool
	dead
}

pub enum CellState {
	hidden
	revealed
	flagged
	question
}

pub struct Cell {
pub mut:
	is_mine        bool
	neighbor_mines int
	state          CellState = .hidden
	exploded       bool
	wrong_flag     bool
}

pub struct Minesweeper {
pub mut:
	difficulty     Difficulty = .beginner
	cols           int        = 9
	rows           int        = 9
	total_mines    int        = 10
	cells          [][]Cell
	state          GameState = .ready
	face_state     FaceState = .normal
	first_click    bool      = true
	timer_ticks    int
	start_tick     u32
	flags_placed   int
	revealed_count int
	best_beg       int = 999
	best_int       int = 999
	best_exp       int = 999
	theme_neon     bool
	toast_msg      string
	toast_timer    f64
}

pub fn new_minesweeper(diff Difficulty) Minesweeper {
	mut ms := Minesweeper{}
	saved := load_mine_save()
	if saved.best_beg > 0 { ms.best_beg = saved.best_beg }
	if saved.best_int > 0 { ms.best_int = saved.best_int }
	if saved.best_exp > 0 { ms.best_exp = saved.best_exp }
	ms.set_difficulty(diff)
	return ms
}

pub fn (mut ms Minesweeper) set_difficulty(diff Difficulty) {
	ms.difficulty = diff
	match diff {
		.beginner {
			ms.cols = 9
			ms.rows = 9
			ms.total_mines = 10
		}
		.intermediate {
			ms.cols = 16
			ms.rows = 16
			ms.total_mines = 40
		}
		.expert {
			ms.cols = 30
			ms.rows = 16
			ms.total_mines = 99
		}
		.custom {
			// Keeps current cols/rows/mines
		}
	}
	ms.reset()
}

pub fn (mut ms Minesweeper) reset() {
	ms.state = .ready
	ms.face_state = .normal
	ms.first_click = true
	ms.timer_ticks = 0
	ms.start_tick = 0
	ms.flags_placed = 0
	ms.revealed_count = 0

	ms.cells = [][]Cell{len: ms.rows, init: []Cell{len: ms.cols, init: Cell{}}}
}

pub fn (ms &Minesweeper) is_valid(r int, c int) bool {
	return r >= 0 && r < ms.rows && c >= 0 && c < ms.cols
}

pub fn (mut ms Minesweeper) place_mines_safe(first_r int, first_c int) {
	// Clear any existing mines
	for r in 0 .. ms.rows {
		for c in 0 .. ms.cols {
			ms.cells[r][c].is_mine = false
			ms.cells[r][c].neighbor_mines = 0
		}
	}

	// Place mines safely avoiding first_r, first_c (and adjacent if possible)
	mut placed := 0
	max_attempts := 5000
	mut attempts := 0

	for placed < ms.total_mines && attempts < max_attempts {
		attempts++
		r := rand.intn(ms.rows) or { 0 }
		c := rand.intn(ms.cols) or { 0 }

		// Avoid first cell and its immediate 8 neighbors for opening cascade
		dr := if r >= first_r { r - first_r } else { first_r - r }
		dc := if c >= first_c { c - first_c } else { first_c - c }
		if dr <= 1 && dc <= 1 {
			// If small board and too many mines, only avoid the first clicked cell
			if ms.total_mines > (ms.rows * ms.cols - 9) {
				if r == first_r && c == first_c {
					continue
				}
			} else {
				continue
			}
		}

		if !ms.cells[r][c].is_mine {
			ms.cells[r][c].is_mine = true
			placed++
		}
	}

	// Fallback if not all mines placed due to strict safe zone
	if placed < ms.total_mines {
		for r in 0 .. ms.rows {
			for c in 0 .. ms.cols {
				if placed >= ms.total_mines {
					break
				}
				if r == first_r && c == first_c {
					continue
				}
				if !ms.cells[r][c].is_mine {
					ms.cells[r][c].is_mine = true
					placed++
				}
			}
		}
	}

	// Compute neighbor numbers
	for r in 0 .. ms.rows {
		for c in 0 .. ms.cols {
			if ms.cells[r][c].is_mine {
				continue
			}
			mut count := 0
			for dr in -1 .. 2 {
				for dc in -1 .. 2 {
					nr := r + dr
					nc := c + dc
					if ms.is_valid(nr, nc) && ms.cells[nr][nc].is_mine {
						count++
					}
				}
			}
			ms.cells[r][c].neighbor_mines = count
		}
	}
}

pub fn (mut ms Minesweeper) update_timer(current_tick u32) {
	if ms.state == .playing {
		if ms.start_tick == 0 {
			ms.start_tick = current_tick
		}
		elapsed_secs := int((current_tick - ms.start_tick) / 1000)
		ms.timer_ticks = if elapsed_secs > 999 { 999 } else { elapsed_secs }
	}
}

pub fn (mut ms Minesweeper) reveal_cell(r int, c int) (bool, int) {
	if !ms.is_valid(r, c) || ms.state == .won || ms.state == .lost {
		return false, 0
	}

	mut cell := &ms.cells[r][c]
	if cell.state != .hidden && cell.state != .question {
		return false, 0
	}

	if ms.first_click {
		ms.place_mines_safe(r, c)
		ms.first_click = false
		ms.state = .playing
		ms.start_tick = u32(time.ticks())
	}

	if cell.is_mine {
		// Game Over!
		cell.state = .revealed
		cell.exploded = true
		ms.state = .lost
		ms.face_state = .dead

		// Reveal all mines and mark wrong flags
		for row in 0 .. ms.rows {
			for col in 0 .. ms.cols {
				mut curr := &ms.cells[row][col]
				if curr.is_mine && curr.state != .flagged {
					curr.state = .revealed
				} else if !curr.is_mine && curr.state == .flagged {
					curr.wrong_flag = true
				}
			}
		}
		return true, 1 // Hit mine
	}

	// BFS Flood Fill for 0s and open cells
	mut queue := [ [r, c] ]
	cell.state = .revealed
	ms.revealed_count++
	mut total_revealed := 1

	for queue.len > 0 {
		pos := queue[0]
		queue.delete(0)
		cr := pos[0]
		cc := pos[1]

		if ms.cells[cr][cc].neighbor_mines == 0 {
			for dr in -1 .. 2 {
				for dc in -1 .. 2 {
					nr := cr + dr
					nc := cc + dc
					if ms.is_valid(nr, nc) {
						mut neighbor := &ms.cells[nr][nc]
						if neighbor.state == .hidden || neighbor.state == .question {
							if !neighbor.is_mine {
								neighbor.state = .revealed
								ms.revealed_count++
								total_revealed++
								if neighbor.neighbor_mines == 0 {
									queue << [nr, nc]
								}
							}
						}
					}
				}
			}
		}
	}

	// Check victory condition
	ms.check_win()
	return false, total_revealed
}

pub fn (mut ms Minesweeper) toggle_flag(r int, c int) CellState {
	if !ms.is_valid(r, c) || ms.state == .won || ms.state == .lost {
		return .hidden
	}

	mut cell := &ms.cells[r][c]
	if cell.state == .hidden {
		cell.state = .flagged
		ms.flags_placed++
		if ms.state == .ready {
			ms.state = .playing
			ms.start_tick = u32(time.ticks())
		}
		ms.check_win()
		return .flagged
	} else if cell.state == .flagged {
		cell.state = .question
		ms.flags_placed--
		return .question
	} else if cell.state == .question {
		cell.state = .hidden
		return .hidden
	}
	return cell.state
}

pub fn (mut ms Minesweeper) chord_cell(r int, c int) (bool, int) {
	if !ms.is_valid(r, c) || ms.state != .playing {
		return false, 0
	}

	cell := ms.cells[r][c]
	if cell.state != .revealed || cell.neighbor_mines == 0 {
		return false, 0
	}

	// Count neighboring flags
	mut flag_count := 0
	for dr in -1 .. 2 {
		for dc in -1 .. 2 {
			nr := r + dr
			nc := c + dc
			if ms.is_valid(nr, nc) && ms.cells[nr][nc].state == .flagged {
				flag_count++
			}
		}
	}

	if flag_count != cell.neighbor_mines {
		return false, 0
	}

	// Reveal non-flagged neighbors
	mut hit_mine := false
	mut total_opened := 0

	for dr in -1 .. 2 {
		for dc in -1 .. 2 {
			nr := r + dr
			nc := c + dc
			if ms.is_valid(nr, nc) {
				neighbor := ms.cells[nr][nc]
				if neighbor.state == .hidden || neighbor.state == .question {
					mined, opened := ms.reveal_cell(nr, nc)
					if mined {
						hit_mine = true
					}
					total_opened += opened
				}
			}
		}
	}

	return hit_mine, total_opened
}

pub fn (mut ms Minesweeper) check_win() bool {
	safe_cells := (ms.rows * ms.cols) - ms.total_mines
	if ms.revealed_count == safe_cells && ms.state != .lost {
		ms.state = .won
		ms.face_state = .cool

		// Automatically flag all remaining mines
		for r in 0 .. ms.rows {
			for c in 0 .. ms.cols {
				if ms.cells[r][c].is_mine {
					ms.cells[r][c].state = .flagged
				}
			}
		}
		ms.flags_placed = ms.total_mines

		// Update best times
		match ms.difficulty {
			.beginner {
				if ms.timer_ticks < ms.best_beg {
					ms.best_beg = ms.timer_ticks
				}
			}
			.intermediate {
				if ms.timer_ticks < ms.best_int {
					ms.best_int = ms.timer_ticks
				}
			}
			.expert {
				if ms.timer_ticks < ms.best_exp {
					ms.best_exp = ms.timer_ticks
				}
			}
			else {}
		}
		ms.save_progress()
		return true
	}
	return false
}

pub fn (ms &Minesweeper) get_remaining_mines() int {
	rem := ms.total_mines - ms.flags_placed
	return if rem < -99 { -99 } else if rem > 999 { 999 } else { rem }
}

pub fn (mut ms Minesweeper) save_progress() {
	mut saved := load_mine_save()
	saved.best_beg = ms.best_beg
	saved.best_int = ms.best_int
	saved.best_exp = ms.best_exp
	saved.diff_idx = int(ms.difficulty)
	saved.cols = ms.cols
	saved.rows = ms.rows
	saved.total_mines = ms.total_mines
	saved.timer_ticks = ms.timer_ticks
	save_mine_data(&saved)
}

pub fn (mut ms Minesweeper) save_state() {
	ms.save_progress()
	mut saved := load_mine_save()
	saved.save_state_valid = true
	
	mut lines := []string{}
	for r in 0 .. ms.rows {
		mut row_str := ''
		for c in 0 .. ms.cols {
			cell := ms.cells[r][c]
			mine := if cell.is_mine { 1 } else { 0 }
			st := int(cell.state)
			row_str += '${mine}:${cell.neighbor_mines}:${st},'
		}
		lines << row_str
	}
	saved.grid_lines = lines
	save_mine_data(&saved)

	ms.toast_msg = 'GAME SAVED (F5)'
	ms.toast_timer = 2.0
}

pub fn (mut ms Minesweeper) load_state() {
	saved := load_mine_save()
	if !saved.save_state_valid || saved.grid_lines.len < ms.rows {
		ms.toast_msg = 'NO SAVE FOUND'
		ms.toast_timer = 2.0
		return
	}
	if saved.best_beg > 0 { ms.best_beg = saved.best_beg }
	if saved.best_int > 0 { ms.best_int = saved.best_int }
	if saved.best_exp > 0 { ms.best_exp = saved.best_exp }
	ms.timer_ticks = saved.timer_ticks

	for r in 0 .. ms.rows {
		if r < saved.grid_lines.len {
			line := saved.grid_lines[r]
			tokens := line.split(',')
			for c in 0 .. ms.cols {
				if c < tokens.len && tokens[c] != '' {
					parts := tokens[c].split(':')
					if parts.len == 3 {
						ms.cells[r][c].is_mine = parts[0] == '1'
						ms.cells[r][c].neighbor_mines = parts[1].int()
						ms.cells[r][c].state = unsafe { CellState(parts[2].int()) }
					}
				}
			}
		}
	}
	ms.toast_msg = 'GAME LOADED (F9)'
	ms.toast_timer = 2.0
}
