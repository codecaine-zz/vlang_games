module main

import rand

pub const pdp_cols = 6
pub const pdp_rows = 12
pub const max_panel_types = 5 // 1: Red Heart, 2: Yellow Star, 3: Cyan Diamond, 4: Green Triangle, 5: Purple Moon

pub enum GameState {
	playing
	game_over
}

pub struct PanelPos {
pub:
	r int
	c int
}

pub struct PanelGame {
pub mut:
	grid           [12][6]int // 0 is empty. Row 0 is top, Row 11 is bottom
	next_row       [6]int     // Preview row rising from bottom
	cur_r          int = 6    // Cursor row (0..11)
	cur_c          int = 2    // Cursor col (0..4) - spans cur_c and cur_c + 1
	rise_offset    f64        // 0.0 to 1.0 (portion of cell height pushed up)
	rise_speed     f64 = 0.08 // Cells per second
	stop_timer     f64        // Freeze time when matches occur
	state          GameState = .playing
	score          int
	high_score     int
	chain_count    int
	clearing_cells []PanelPos
	clear_timer    f64
	level          int = 1
	panels_cleared int
}

pub fn new_panel_game() PanelGame {
	mut g := PanelGame{}
	g.generate_next_row()
	// Fill bottom 5 rows with non-matching starting panels
	for r in 7 .. pdp_rows {
		for c in 0 .. pdp_cols {
			g.grid[r][c] = rand.int_in_range(1, max_panel_types + 1) or { 1 }
		}
	}
	// Eliminate any initial matches
	g.clean_initial_grid()
	return g
}

pub fn (mut g PanelGame) generate_next_row() {
	for c in 0 .. pdp_cols {
		mut col := rand.int_in_range(1, max_panel_types + 1) or { 1 }
		if c >= 2 && g.next_row[c - 1] == col && g.next_row[c - 2] == col {
			col = (col % max_panel_types) + 1
		}
		g.next_row[c] = col
	}
}

pub fn (mut g PanelGame) clean_initial_grid() {
	for r in 0 .. pdp_rows {
		for c in 0 .. pdp_cols {
			for (c >= 2 && g.grid[r][c] != 0 && g.grid[r][c] == g.grid[r][c - 1] && g.grid[r][c] == g.grid[r][c - 2]) ||
			    (r >= 2 && g.grid[r][c] != 0 && g.grid[r][c] == g.grid[r - 1][c] && g.grid[r][c] == g.grid[r - 2][c]) {
				g.grid[r][c] = (g.grid[r][c] % max_panel_types) + 1
			}
		}
	}
}

pub fn (mut g PanelGame) move_cursor(dr int, dc int) {
	new_r := g.cur_r + dr
	new_c := g.cur_c + dc
	if new_r >= 0 && new_r < pdp_rows {
		g.cur_r = new_r
	}
	if new_c >= 0 && new_c < pdp_cols - 1 {
		g.cur_c = new_c
	}
}

// Swap the two panels under the cursor
pub fn (mut g PanelGame) swap_panels() bool {
	if g.state != .playing {
		return false
	}
	r := g.cur_r
	c := g.cur_c

	tmp := g.grid[r][c]
	g.grid[r][c] = g.grid[r][c + 1]
	g.grid[r][c + 1] = tmp

	// Apply gravity immediately if air underneath
	g.apply_gravity()

	// Check if this swap triggered any matches
	g.check_matches()
	return true
}

// Push stack up by 1 row immediately (manual raise)
pub fn (mut g PanelGame) push_stack_up() bool {
	if g.state != .playing {
		return false
	}
	// Check if top row is occupied
	for c in 0 .. pdp_cols {
		if g.grid[0][c] != 0 {
			g.state = .game_over
			return false
		}
	}

	// Shift grid up
	for r in 0 .. pdp_rows - 1 {
		for c in 0 .. pdp_cols {
			g.grid[r][c] = g.grid[r + 1][c]
		}
	}

	// Bottom row becomes next_row
	for c in 0 .. pdp_cols {
		g.grid[pdp_rows - 1][c] = g.next_row[c]
	}

	// Generate new preview
	g.generate_next_row()
	g.rise_offset = 0.0

	// Move cursor up if it was at top
	if g.cur_r > 0 {
		g.cur_r--
	}

	g.score += 10
	g.apply_gravity()
	g.check_matches()
	return true
}

// Find horizontal & vertical 3+ matches
pub fn (mut g PanelGame) check_matches() bool {
	mut matched := [12][6]bool{}
	mut found := false

	// Horizontal check
	for r in 0 .. pdp_rows {
		for c in 0 .. pdp_cols - 2 {
			val := g.grid[r][c]
			if val != 0 && val == g.grid[r][c + 1] && val == g.grid[r][c + 2] {
				matched[r][c] = true
				matched[r][c + 1] = true
				matched[r][c + 2] = true
				found = true
				mut k := c + 3
				for k < pdp_cols && g.grid[r][k] == val {
					matched[r][k] = true
					k++
				}
			}
		}
	}

	// Vertical check
	for c in 0 .. pdp_cols {
		for r in 0 .. pdp_rows - 2 {
			val := g.grid[r][c]
			if val != 0 && val == g.grid[r + 1][c] && val == g.grid[r + 2][c] {
				matched[r][c] = true
				matched[r + 1][c] = true
				matched[r + 2][c] = true
				found = true
				mut k := r + 3
				for k < pdp_rows && g.grid[k][c] == val {
					matched[k][c] = true
					k++
				}
			}
		}
	}

	if found {
		mut pos_list := []PanelPos{}
		for r in 0 .. pdp_rows {
			for c in 0 .. pdp_cols {
				if matched[r][c] {
					pos_list << PanelPos{r: r, c: c}
				}
			}
		}
		g.clearing_cells = pos_list
		g.clear_timer = 0.35
		g.chain_count++

		// Grant freeze time / stop time
		g.stop_timer = 1.5 + f64(g.chain_count) * 0.8
		return true
	} else {
		g.chain_count = 0
		return false
	}
}

// Clear matched panels and drop upper panels
pub fn (mut g PanelGame) apply_clearing() {
	count := g.clearing_cells.len
	for p in g.clearing_cells {
		g.grid[p.r][p.c] = 0
	}
	g.clearing_cells.clear()

	points := count * 50 * g.chain_count * g.level
	g.score += points
	if g.score > g.high_score {
		g.high_score = g.score
	}
	g.panels_cleared += count
	g.level = 1 + (g.panels_cleared / 40)
	g.rise_speed = 0.08 + f64(g.level - 1) * 0.02

	// Gravity settle
	g.apply_gravity()

	// Check if drop triggered cascade chain
	g.check_matches()
}

pub fn (mut g PanelGame) apply_gravity() bool {
	mut moved := false
	for c in 0 .. pdp_cols {
		mut write_r := pdp_rows - 1
		for r := pdp_rows - 1; r >= 0; r-- {
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

pub fn (mut g PanelGame) update(dt f64) {
	if g.state != .playing {
		return
	}

	// Update Clear Timer
	if g.clearing_cells.len > 0 {
		g.clear_timer -= dt
		if g.clear_timer <= 0 {
			g.apply_clearing()
		}
		return
	}

	// Stop Timer (Freeze)
	if g.stop_timer > 0 {
		g.stop_timer -= dt
	} else {
		// Rise stack
		g.rise_offset += g.rise_speed * dt
		if g.rise_offset >= 1.0 {
			g.push_stack_up()
		}
	}
}
