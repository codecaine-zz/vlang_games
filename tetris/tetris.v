module main

import rand

const grid_cols = 10
const grid_rows = 20

// Tetromino types: 0=Empty, 1=I, 2=J, 3=L, 4=O, 5=S, 6=T, 7=Z
const piece_shapes = [
	// Empty
	[[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]],
	// 1: I
	[[0, 0, 0, 0], [1, 1, 1, 1], [0, 0, 0, 0], [0, 0, 0, 0]],
	// 2: J
	[[2, 0, 0], [2, 2, 2], [0, 0, 0]],
	// 3: L
	[[0, 0, 3], [3, 3, 3], [0, 0, 0]],
	// 4: O
	[[4, 4], [4, 4]],
	// 5: S
	[[0, 5, 5], [5, 5, 0], [0, 0, 0]],
	// 6: T
	[[0, 6, 0], [6, 6, 6], [0, 0, 0]],
	// 7: Z
	[[7, 7, 0], [0, 7, 7], [0, 0, 0]],
]

struct Piece {
pub mut:
	kind   int
	matrix [][]int
	x      int
	y      int
}

fn new_piece(k int) Piece {
	shape := piece_shapes[k]
	size := shape.len
	mut m := [][]int{len: size, init: []int{len: size}}
	for r in 0 .. size {
		for c in 0 .. size {
			m[r][c] = shape[r][c]
		}
	}
	start_x := (grid_cols - size) / 2
	return Piece{
		kind:   k
		matrix: m
		x:      start_x
		y:      0
	}
}

fn rotate_matrix_cw(m [][]int) [][]int {
	n := m.len
	mut res := [][]int{len: n, init: []int{len: n}}
	for r in 0 .. n {
		for c in 0 .. n {
			res[c][n - 1 - r] = m[r][c]
		}
	}
	return res
}

struct TetrisGame {
pub mut:
	grid       [20][10]int
	curr_piece Piece
	next_piece Piece
	hold_piece Piece
	can_hold   bool = true
	has_hold   bool
	score      int
	lines      int
	level      int = 1
	game_over  bool
	is_paused    bool
	last_cleared int
	high_score   int
	toast_msg    string
	toast_timer  f64
}

fn new_tetris_game() TetrisGame {
	p1_kind := rand.intn(7) or { 0 } + 1
	p2_kind := rand.intn(7) or { 0 } + 1
	saved := load_tetris_save()
	mut game := TetrisGame{
		grid:       [20][10]int{}
		curr_piece: new_piece(p1_kind)
		next_piece: new_piece(p2_kind)
		hold_piece: Piece{}
		score:      0
		lines:      0
		level:      1
		game_over:  false
		is_paused:  false
		high_score: saved.high_score
	}
	return game
}

fn (g &TetrisGame) check_collision(p Piece, ox int, oy int) bool {
	size := p.matrix.len
	for r in 0 .. size {
		for c in 0 .. size {
			if p.matrix[r][c] != 0 {
				nx := p.x + c + ox
				ny := p.y + r + oy
				if nx < 0 || nx >= grid_cols || ny >= grid_rows {
					return true
				}
				if ny >= 0 && g.grid[ny][nx] != 0 {
					return true
				}
			}
		}
	}
	return false
}

fn (mut g TetrisGame) move_left() bool {
	if g.game_over || g.is_paused {
		return false
	}
	if !g.check_collision(g.curr_piece, -1, 0) {
		g.curr_piece.x--
		return true
	}
	return false
}

fn (mut g TetrisGame) move_right() bool {
	if g.game_over || g.is_paused {
		return false
	}
	if !g.check_collision(g.curr_piece, 1, 0) {
		g.curr_piece.x++
		return true
	}
	return false
}

fn (mut g TetrisGame) rotate() bool {
	if g.game_over || g.is_paused {
		return false
	}
	mut rot := g.curr_piece
	rot.matrix = rotate_matrix_cw(rot.matrix)

	// Basic wall kicks
	offsets := [0, 1, -1, 2, -2]
	for ox in offsets {
		if !g.check_collision(rot, ox, 0) {
			rot.x += ox
			g.curr_piece = rot
			return true
		}
	}
	return false
}

fn (g &TetrisGame) get_ghost_y() int {
	mut ghost_y := g.curr_piece.y
	for !g.check_collision(g.curr_piece, 0, ghost_y - g.curr_piece.y + 1) {
		ghost_y++
	}
	return ghost_y
}

fn (mut g TetrisGame) hard_drop() int {
	if g.game_over || g.is_paused {
		return 0
	}
	ghost_y := g.get_ghost_y()
	drop_dist := ghost_y - g.curr_piece.y
	g.curr_piece.y = ghost_y
	g.lock_piece()
	return drop_dist
}

fn (mut g TetrisGame) hold() bool {
	if g.game_over || g.is_paused || !g.can_hold {
		return false
	}
	g.can_hold = false
	if !g.has_hold {
		g.hold_piece = new_piece(g.curr_piece.kind)
		g.curr_piece = g.next_piece
		g.next_piece = new_piece(rand.intn(7) or { 0 } + 1)
		g.has_hold = true
	} else {
		temp := g.curr_piece.kind
		g.curr_piece = new_piece(g.hold_piece.kind)
		g.hold_piece = new_piece(temp)
	}
	return true
}

fn (mut g TetrisGame) lock_piece() int { // returns lines cleared
	size := g.curr_piece.matrix.len
	for r in 0 .. size {
		for c in 0 .. size {
			if g.curr_piece.matrix[r][c] != 0 {
				gx := g.curr_piece.x + c
				gy := g.curr_piece.y + r
				if gy >= 0 && gy < grid_rows && gx >= 0 && gx < grid_cols {
					g.grid[gy][gx] = g.curr_piece.kind
				}
			}
		}
	}

	cleared := g.clear_lines()
	g.last_cleared = cleared

	// Spawn next piece
	g.curr_piece = g.next_piece
	g.next_piece = new_piece(rand.intn(7) or { 0 } + 1)
	g.can_hold = true

	// Check Game Over
	if g.check_collision(g.curr_piece, 0, 0) {
		g.game_over = true
	}

	return cleared
}

fn (mut g TetrisGame) clear_lines() int {
	mut cleared := 0
	for r := grid_rows - 1; r >= 0; r-- {
		mut full := true
		for c in 0 .. grid_cols {
			if g.grid[r][c] == 0 {
				full = false
				break
			}
		}
		if full {
			cleared++
			// Shift rows down
			for row := r; row > 0; row-- {
				for col in 0 .. grid_cols {
					g.grid[row][col] = g.grid[row - 1][col]
				}
			}
			for col in 0 .. grid_cols {
				g.grid[0][col] = 0
			}
			r++ // Check same row index again after shift
		}
	}

	if cleared > 0 {
		g.lines += cleared
		g.level = 1 + (g.lines / 10)
		points := match cleared {
			1 { 100 * g.level }
			2 { 300 * g.level }
			3 { 500 * g.level }
			4 { 800 * g.level }
			else { 1000 * g.level }
		}
		g.score += points
	}

	return cleared
}

fn (mut g TetrisGame) step_down() bool { // returns true if piece locked
	if g.game_over || g.is_paused {
		return false
	}
	if !g.check_collision(g.curr_piece, 0, 1) {
		g.curr_piece.y++
		return false
	} else {
		g.lock_piece()
		return true
	}
}

fn (mut g TetrisGame) reset() {
	g.grid = [20][10]int{}
	p1_kind := rand.intn(7) or { 0 } + 1
	p2_kind := rand.intn(7) or { 0 } + 1
	g.curr_piece = new_piece(p1_kind)
	g.next_piece = new_piece(p2_kind)
	g.hold_piece = Piece{}
	g.can_hold = true
	g.has_hold = false
	g.score = 0
	g.lines = 0
	g.level = 1
	g.game_over = false
	g.is_paused = false
}

pub fn (mut g TetrisGame) save_progress() {
	if g.score > g.high_score {
		g.high_score = g.score
	}
	mut saved := load_tetris_save()
	saved.high_score = g.high_score
	saved.score = g.score
	saved.lines = g.lines
	saved.level = g.level
	saved.save_state_valid = true

	mut lines := []string{}
	for r in 0 .. 20 {
		mut row_str := ''
		for c in 0 .. 10 {
			row_str += '${g.grid[r][c]},'
		}
		lines << row_str
	}
	saved.grid_lines = lines
	save_tetris_data(&saved)
}

pub fn (mut g TetrisGame) save_state() {
	g.save_progress()
	g.toast_msg = 'GAME SAVED (F5)'
	g.toast_timer = 2.0
}

pub fn (mut g TetrisGame) load_state() {
	saved := load_tetris_save()
	if !saved.save_state_valid || saved.grid_lines.len < 20 {
		g.toast_msg = 'NO SAVE FOUND'
		g.toast_timer = 2.0
		return
	}
	if saved.high_score > 0 { g.high_score = saved.high_score }
	g.score = saved.score
	g.lines = saved.lines
	g.level = saved.level

	for r in 0 .. 20 {
		line := saved.grid_lines[r]
		tokens := line.split(',')
		for c in 0 .. 10 {
			if c < tokens.len && tokens[c] != '' {
				g.grid[r][c] = tokens[c].int()
			}
		}
	}
	g.game_over = false
	g.toast_msg = 'GAME LOADED (F9)'
	g.toast_timer = 2.0
}
