module main

import math
import rand

pub const puyo_cols = 6
pub const puyo_rows = 12
pub const cell_sz = 40.0

pub enum PuyoGameState {
	falling
	settling
	popping
	game_over
}

pub struct PuyoPair {
pub mut:
	r1   f64 = 0.0 // Main Puyo row
	c1   int = 2   // Main Puyo col
	rot  int       // 0 = Sub above, 1 = right, 2 = below, 3 = left
	col1 int = 1   // Main color
	col2 int = 2   // Sub color
}

pub struct PuyoPopEvent {
pub mut:
	positions [][]int
	chain     int
	color     int
}

pub struct PuyoGame {
pub mut:
	grid        [][]int // 12 rows x 6 cols
	pair        PuyoPair
	next_pair   PuyoPair
	state       PuyoGameState = .falling
	score       int
	high_score  int           = 25000
	chain_count int
	fall_timer  f64
	fall_speed  f64 = 0.65 // seconds per row
	settle_timer f64
	last_pops   []PuyoPopEvent
}

pub fn new_puyo_game() PuyoGame {
	mut g := PuyoGame{}
	g.reset_game()
	return g
}

pub fn (mut g PuyoGame) reset_game() {
	g.grid = [][]int{len: puyo_rows, init: []int{len: puyo_cols, init: 0}}
	g.score = 0
	g.chain_count = 0
	g.fall_timer = 0.0
	g.state = .falling

	g.next_pair = PuyoPair{
		r1:   0.0
		c1:   2
		rot:  0
		col1: (rand.intn(4) or { 0 }) + 1
		col2: (rand.intn(4) or { 0 }) + 1
	}
	g.spawn_next_pair()
}

pub fn (mut g PuyoGame) spawn_next_pair() bool {
	g.pair = g.next_pair
	g.pair.r1 = 0.0
	g.pair.c1 = 2
	g.pair.rot = 0

	g.next_pair = PuyoPair{
		r1:   0.0
		c1:   2
		rot:  0
		col1: (rand.intn(4) or { 0 }) + 1
		col2: (rand.intn(4) or { 0 }) + 1
	}

	// Check if spawn column is blocked (Game Over)
	if g.grid[0][2] != 0 || g.grid[1][2] != 0 {
		g.state = .game_over
		if g.score > g.high_score {
			g.high_score = g.score
		}
		return false
	}
	g.state = .falling
	return true
}

pub fn (g &PuyoGame) get_sub_pos(r int, c int, rot int) (int, int) {
	match rot {
		0 { return r - 1, c }     // above
		1 { return r, c + 1 }     // right
		2 { return r + 1, c }     // below
		else { return r, c - 1 }  // left
	}
}

pub fn (g &PuyoGame) is_cell_empty(r int, c int) bool {
	if r < 0 {
		return c >= 0 && c < puyo_cols
	}
	if r >= puyo_rows || c < 0 || c >= puyo_cols {
		return false
	}
	return g.grid[r][c] == 0
}

pub fn (mut g PuyoGame) move_horiz(dc int) bool {
	if g.state != .falling {
		return false
	}
	r := int(g.pair.r1)
	c := g.pair.c1 + dc
	sub_r, sub_c := g.get_sub_pos(r, c, g.pair.rot)

	if g.is_cell_empty(r, c) && g.is_cell_empty(sub_r, sub_c) {
		g.pair.c1 = c
		return true
	}
	return false
}

pub fn (mut g PuyoGame) rotate(dir int) bool { // +1 = CW, -1 = CCW
	if g.state != .falling {
		return false
	}
	new_rot := (g.pair.rot + dir + 4) % 4
	r := int(g.pair.r1)
	c := g.pair.c1
	sub_r, sub_c := g.get_sub_pos(r, c, new_rot)

	if g.is_cell_empty(r, c) && g.is_cell_empty(sub_r, sub_c) {
		g.pair.rot = new_rot
		return true
	}

	// Wall kick left / right
	if sub_c < 0 && g.is_cell_empty(r, c + 1) {
		g.pair.c1 = c + 1
		g.pair.rot = new_rot
		return true
	} else if sub_c >= puyo_cols && g.is_cell_empty(r, c - 1) {
		g.pair.c1 = c - 1
		g.pair.rot = new_rot
		return true
	}

	return false
}

pub fn (mut g PuyoGame) drop_instant() {
	if g.state != .falling {
		return
	}
	for g.can_pair_fall() {
		g.pair.r1 += 1.0
	}
	g.lock_pair()
}

pub fn (g &PuyoGame) can_pair_fall() bool {
	r := int(g.pair.r1) + 1
	c := g.pair.c1
	sub_r, sub_c := g.get_sub_pos(r, c, g.pair.rot)

	return g.is_cell_empty(r, c) && g.is_cell_empty(sub_r, sub_c)
}

pub fn (mut g PuyoGame) lock_pair() {
	r1 := int(g.pair.r1)
	c1 := g.pair.c1
	r2, c2 := g.get_sub_pos(r1, c1, g.pair.rot)

	if r1 >= 0 && r1 < puyo_rows && c1 >= 0 && c1 < puyo_cols {
		g.grid[r1][c1] = g.pair.col1
	}
	if r2 >= 0 && r2 < puyo_rows && c2 >= 0 && c2 < puyo_cols {
		g.grid[r2][c2] = g.pair.col2
	}

	g.apply_gravity()
	g.chain_count = 0
	g.state = .settling
}

pub fn (mut g PuyoGame) apply_gravity() bool {
	mut moved := false
	for c in 0 .. puyo_cols {
		mut write_r := puyo_rows - 1
		for r := puyo_rows - 1; r >= 0; r-- {
			if g.grid[r][c] != 0 {
				if r != write_r {
					g.grid[write_r][c] = g.grid[r][c]
					g.grid[r][c] = 0
					moved = true
				}
				write_r--
			}
		}
	}
	return moved
}

pub fn (g &PuyoGame) find_connected_groups() [][][]int {
	mut groups := [][][]int{}
	mut visited := [][]bool{len: puyo_rows, init: []bool{len: puyo_cols, init: false}}

	for r in 0 .. puyo_rows {
		for c in 0 .. puyo_cols {
			col := g.grid[r][c]
			if col > 0 && !visited[r][c] {
				mut group := [][]int{}
				mut queue := [[r, c]]
				visited[r][c] = true

				for queue.len > 0 {
					pos := queue[0]
					queue.delete(0)
					gr := pos[0]
					gc := pos[1]
					group << [gr, gc]

					dirs := [[-1, 0], [1, 0], [0, -1], [0, 1]]
					for d in dirs {
						nr := gr + d[0]
						nc := gc + d[1]
						if nr >= 0 && nr < puyo_rows && nc >= 0 && nc < puyo_cols {
							if !visited[nr][nc] && g.grid[nr][nc] == col {
								visited[nr][nc] = true
								queue << [nr, nc]
							}
						}
					}
				}

				if group.len >= 4 {
					groups << group
				}
			}
		}
	}
	return groups
}

pub struct PuyoStepResult {
pub mut:
	popped       bool
	chain_level  int
	cleared_count int
}

pub fn (mut g PuyoGame) update(dt f64) PuyoStepResult {
	mut res := PuyoStepResult{}

	if g.state == .falling {
		g.fall_timer += dt
		if g.fall_timer >= g.fall_speed {
			g.fall_timer = 0.0
			if g.can_pair_fall() {
				g.pair.r1 += 1.0
			} else {
				g.lock_pair()
			}
		}
	} else if g.state == .settling {
		// Settle and check for matches
		groups := g.find_connected_groups()
		if groups.len > 0 {
			g.chain_count++
			res.popped = true
			res.chain_level = g.chain_count

			mut total_popped := 0
			for group in groups {
				col := g.grid[group[0][0]][group[0][1]]
				for pos in group {
					g.grid[pos[0]][pos[1]] = 0
					total_popped++
				}
				g.last_pops << PuyoPopEvent{
					positions: group.clone()
					chain:     g.chain_count
					color:     col
				}
			}
			res.cleared_count = total_popped

			// Classic Puyo Puyo Chain Multiplier Scoring: 10 * count * 2^(chain - 1)
			multiplier := int(math.pow(2.0, f64(g.chain_count - 1)))
			g.score += total_popped * 100 * multiplier
			if g.score > g.high_score {
				g.high_score = g.score
			}

			g.apply_gravity()
			g.state = .settling
		} else {
			// No more matches, spawn next piece
			g.spawn_next_pair()
		}
	}

	return res
}
