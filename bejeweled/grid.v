module main

import rand

const grid_size = 8
const num_gem_types = 7

pub enum SpecialType {
	none
	flame
	star
	hypercube
	supernova
	time_bonus
	butterfly
	gold_relic
}

struct Point {
pub:
	r int
	c int
}

struct Gem {
pub mut:
	kind    int         // 1..7 (0 = empty)
	special SpecialType = .none
	curr_x  f64
	curr_y  f64
	animating bool
}

struct MatchGroup {
pub mut:
	points   []Point
	kind     int
	is_vert  bool
}

struct Grid {
pub mut:
	cells [8][8]Gem
}

fn new_grid() Grid {
	mut g := Grid{}
	g.init_board()
	return g
}

fn (mut g Grid) init_board() {
	for {
		for r in 0 .. grid_size {
			for c in 0 .. grid_size {
				// Pick random gem that doesn't cause immediate 3-in-a-row
				mut valid_kinds := []int{}
				for k in 1 .. num_gem_types + 1 {
					// Check left 2
					if c >= 2 && g.cells[r][c - 1].kind == k && g.cells[r][c - 2].kind == k {
						continue
					}
					// Check top 2
					if r >= 2 && g.cells[r - 1][c].kind == k && g.cells[r - 2][c].kind == k {
						continue
					}
					valid_kinds << k
				}
				k := valid_kinds[rand.int_in_range(0, valid_kinds.len) or { 0 }]
				g.cells[r][c] = Gem{
					kind:      k
					special:   .none
					curr_x:    f64(c)
					curr_y:    f64(r)
					animating: false
				}
			}
		}

		if g.has_valid_moves() {
			break
		}
	}
}

fn (g &Grid) find_matches() []MatchGroup {
	mut groups := []MatchGroup{}

	// Horizontal matches
	for r in 0 .. grid_size {
		mut match_len := 1
		for c in 0 .. grid_size {
			curr_k := g.cells[r][c].kind
			if c < grid_size - 1 && curr_k > 0 && curr_k == g.cells[r][c + 1].kind {
				match_len++
			} else {
				if match_len >= 3 && curr_k > 0 {
					mut pts := []Point{}
					for i := 0; i < match_len; i++ {
						pts << Point{r: r, c: c - i}
					}
					groups << MatchGroup{
						points:  pts
						kind:    curr_k
						is_vert: false
					}
				}
				match_len = 1
			}
		}
	}

	// Vertical matches
	for c in 0 .. grid_size {
		mut match_len := 1
		for r in 0 .. grid_size {
			curr_k := g.cells[r][c].kind
			if r < grid_size - 1 && curr_k > 0 && curr_k == g.cells[r + 1][c].kind {
				match_len++
			} else {
				if match_len >= 3 && curr_k > 0 {
					mut pts := []Point{}
					for i := 0; i < match_len; i++ {
						pts << Point{r: r - i, c: c}
					}
					groups << MatchGroup{
						points:  pts
						kind:    curr_k
						is_vert: true
					}
				}
				match_len = 1
			}
		}
	}

	return groups
}

fn (mut g Grid) swap(r1 int, c1 int, r2 int, c2 int) {
	temp := g.cells[r1][c1]
	g.cells[r1][c1] = g.cells[r2][c2]
	g.cells[r2][c2] = temp
}

fn is_adjacent(r1 int, c1 int, r2 int, c2 int) bool {
	dr := if r1 > r2 { r1 - r2 } else { r2 - r1 }
	dc := if c1 > c2 { c1 - c2 } else { c2 - c1 }
	return (dr == 1 && dc == 0) || (dr == 0 && dc == 1)
}

fn (g &Grid) test_swap_gives_match(r1 int, c1 int, r2 int, c2 int) bool {
	if g.cells[r1][c1].special == .hypercube || g.cells[r2][c2].special == .hypercube {
		return true
	}
	mut clone := *g
	clone.swap(r1, c1, r2, c2)
	return clone.find_matches().len > 0
}

fn (g &Grid) has_valid_moves() bool {
	for r in 0 .. grid_size {
		for c in 0 .. grid_size {
			if c < grid_size - 1 && g.test_swap_gives_match(r, c, r, c + 1) {
				return true
			}
			if r < grid_size - 1 && g.test_swap_gives_match(r, c, r + 1, c) {
				return true
			}
		}
	}
	return false
}

fn (g &Grid) find_hint_move() (Point, Point, bool) {
	for r in 0 .. grid_size {
		for c in 0 .. grid_size {
			if c < grid_size - 1 && g.test_swap_gives_match(r, c, r, c + 1) {
				return Point{r: r, c: c}, Point{r: r, c: c + 1}, true
			}
			if r < grid_size - 1 && g.test_swap_gives_match(r, c, r + 1, c) {
				return Point{r: r, c: c}, Point{r: r + 1, c: c}, true
			}
		}
	}
	return Point{r: -1, c: -1}, Point{r: -1, c: -1}, false
}

fn (mut g Grid) apply_gravity_and_refill() bool {
	mut changed := false

	for c in 0 .. grid_size {
		// Shift down
		mut write_r := grid_size - 1
		for r := grid_size - 1; r >= 0; r-- {
			if g.cells[r][c].kind != 0 {
				if write_r != r {
					g.cells[write_r][c] = g.cells[r][c]
					g.cells[r][c] = Gem{kind: 0, special: .none, curr_x: f64(c), curr_y: f64(r), animating: false}
					changed = true
				}
				write_r--
			}
		}

		// Refill top empty cells
		for r := write_r; r >= 0; r-- {
			k := rand.int_in_range(1, num_gem_types + 1) or { 1 }
			g.cells[r][c] = Gem{
				kind:      k
				special:   .none
				curr_x:    f64(c)
				curr_y:    f64(r - write_r - 1) // start above board for falling animation
				animating: true
			}
			changed = true
		}
	}

	return changed
}

fn (mut g Grid) reshuffle() {
	for {
		// Collect all existing gems
		mut gems := []Gem{}
		for r in 0 .. grid_size {
			for c in 0 .. grid_size {
				if g.cells[r][c].kind > 0 {
					gems << g.cells[r][c]
				}
			}
		}

		// Shuffle
		for i in 0 .. gems.len {
			j := rand.int_in_range(0, gems.len) or { 0 }
			tmp := gems[i]
			gems[i] = gems[j]
			gems[j] = tmp
		}

		// Put back
		mut idx := 0
		for r in 0 .. grid_size {
			for c in 0 .. grid_size {
				if idx < gems.len {
					g.cells[r][c] = gems[idx]
					g.cells[r][c].curr_x = f64(c)
					g.cells[r][c].curr_y = f64(r)
					idx++
				}
			}
		}

		// Check if valid without initial matches
		if g.find_matches().len == 0 && g.has_valid_moves() {
			break
		}
	}
}
