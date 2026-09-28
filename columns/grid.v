module main

import rand

pub const col_cols = 6
pub const col_rows = 13
pub const max_gem_types = 6
pub const magic_gem_type = 7

pub enum GameState {
	falling
	clearing
	settling
	game_over
}

pub struct FallingColumn {
pub mut:
	c     int      // Column index (0..col_cols-1)
	y     f64      // Floating row position of top gem
	gems  [3]int   // Top, Middle, Bottom gem IDs (1..max_gem_types or magic_gem_type)
}

pub struct MatchPos {
pub:
	r int
	c int
}

pub struct ColumnsGame {
pub mut:
	grid         [13][6]int // Row 0 is top, Row 12 is bottom
	state        GameState = .falling
	active_col   FallingColumn
	next_gems    [3]int
	score        int
	high_score   int
	level        int = 1
	jewels_cleared int
	combo_count  int
	fall_speed   f64 = 1.8 // rows per second
	clearing_pos []MatchPos
	clear_timer  f64
}

pub fn new_columns_game() ColumnsGame {
	mut g := ColumnsGame{}
	g.next_gems = [
		rand.int_in_range(1, max_gem_types + 1) or { 1 },
		rand.int_in_range(1, max_gem_types + 1) or { 2 },
		rand.int_in_range(1, max_gem_types + 1) or { 3 },
	]!
	g.spawn_column()
	return g
}

pub fn (mut g ColumnsGame) spawn_column() bool {
	// 5% chance of spawning Magic Gem column when score >= 1000
	mut gems := g.next_gems
	if g.score >= 1000 && rand.int_in_range(0, 20) or { 0 } == 0 {
		gems = [magic_gem_type, magic_gem_type, magic_gem_type]!
	}

	// Prepare next preview
	g.next_gems = [
		rand.int_in_range(1, max_gem_types + 1) or { 1 },
		rand.int_in_range(1, max_gem_types + 1) or { 2 },
		rand.int_in_range(1, max_gem_types + 1) or { 3 },
	]!

	spawn_c := col_cols / 2 - 1
	// If spawn location is already blocked, game over
	if g.grid[0][spawn_c] != 0 || g.grid[1][spawn_c] != 0 || g.grid[2][spawn_c] != 0 {
		g.state = .game_over
		return false
	}

	g.active_col = FallingColumn{
		c:    spawn_c
		y:    -2.0
		gems: gems
	}
	g.state = .falling
	g.combo_count = 0
	return true
}

// Cycle gems in falling column (top becomes middle, middle becomes bottom, bottom becomes top)
pub fn (mut g ColumnsGame) cycle_gems() {
	if g.state != .falling {
		return
	}
	t := g.active_col.gems[0]
	m := g.active_col.gems[1]
	b := g.active_col.gems[2]
	g.active_col.gems[0] = b
	g.active_col.gems[1] = t
	g.active_col.gems[2] = m
}

// Move column left or right
pub fn (mut g ColumnsGame) move_column(dir int) bool {
	if g.state != .falling {
		return false
	}
	target_c := g.active_col.c + dir
	if target_c < 0 || target_c >= col_cols {
		return false
	}

	// Check collision with existing gems at current depth
	bottom_row := int(g.active_col.y) + 2
	for r in int(g.active_col.y) .. bottom_row + 1 {
		if r >= 0 && r < col_rows {
			if g.grid[r][target_c] != 0 {
				return false
			}
		}
	}
	g.active_col.c = target_c
	return true
}

// Find max landing row for current column
pub fn (g ColumnsGame) get_landing_row(c int) int {
	for r in 0 .. col_rows {
		if g.grid[r][c] != 0 {
			return r - 1
		}
	}
	return col_rows - 1
}

// Lock active column into grid
pub fn (mut g ColumnsGame) lock_column() {
	bottom_r := g.get_landing_row(g.active_col.c)
	if bottom_r < 2 {
		// Stack overflow -> game over
		g.state = .game_over
		return
	}

	c := g.active_col.c
	is_magic := g.active_col.gems[0] == magic_gem_type

	if is_magic {
		// Check what color gem was landed on
		mut target_gem_type := 0
		if bottom_r + 1 < col_rows {
			target_gem_type = g.grid[bottom_r + 1][c]
		}
		if target_gem_type == 0 {
			// Random color clear
			target_gem_type = rand.int_in_range(1, max_gem_types + 1) or { 1 }
		}

		mut matches := []MatchPos{}
		for r in 0 .. col_rows {
			for col in 0 .. col_cols {
				if g.grid[r][col] == target_gem_type {
					matches << MatchPos{r: r, c: col}
				}
			}
		}
		g.clearing_pos = matches
		g.state = .clearing
		g.clear_timer = 0.4
		return
	}

	g.grid[bottom_r - 2][c] = g.active_col.gems[0]
	g.grid[bottom_r - 1][c] = g.active_col.gems[1]
	g.grid[bottom_r][c] = g.active_col.gems[2]

	g.check_matches()
}

// Find all matches of 3 or more horizontally, vertically, diagonally
pub fn (mut g ColumnsGame) check_matches() bool {
	mut matched := [13][6]bool{}
	mut found := false

	// Horizontal check (3+)
	for r in 0 .. col_rows {
		for c in 0 .. col_cols - 2 {
			val := g.grid[r][c]
			if val != 0 && val == g.grid[r][c + 1] && val == g.grid[r][c + 2] {
				matched[r][c] = true
				matched[r][c + 1] = true
				matched[r][c + 2] = true
				found = true
				// Check 4, 5, 6
				mut k := c + 3
				for k < col_cols && g.grid[r][k] == val {
					matched[r][k] = true
					k++
				}
			}
		}
	}

	// Vertical check (3+)
	for c in 0 .. col_cols {
		for r in 0 .. col_rows - 2 {
			val := g.grid[r][c]
			if val != 0 && val == g.grid[r + 1][c] && val == g.grid[r + 2][c] {
				matched[r][c] = true
				matched[r + 1][c] = true
				matched[r + 2][c] = true
				found = true
				mut k := r + 3
				for k < col_rows && g.grid[k][c] == val {
					matched[k][c] = true
					k++
				}
			}
		}
	}

	// Diagonal down-right check (3+)
	for r in 0 .. col_rows - 2 {
		for c in 0 .. col_cols - 2 {
			val := g.grid[r][c]
			if val != 0 && val == g.grid[r + 1][c + 1] && val == g.grid[r + 2][c + 2] {
				matched[r][c] = true
				matched[r + 1][c + 1] = true
				matched[r + 2][c + 2] = true
				found = true
				mut kr := r + 3
				mut kc := c + 3
				for kr < col_rows && kc < col_cols && g.grid[kr][kc] == val {
					matched[kr][kc] = true
					kr++
					kc++
				}
			}
		}
	}

	// Diagonal down-left check (3+)
	for r in 0 .. col_rows - 2 {
		for c in 2 .. col_cols {
			val := g.grid[r][c]
			if val != 0 && val == g.grid[r + 1][c - 1] && val == g.grid[r + 2][c - 2] {
				matched[r][c] = true
				matched[r + 1][c - 1] = true
				matched[r + 2][c - 2] = true
				found = true
				mut kr := r + 3
				mut kc := c - 3
				for kr < col_rows && kc >= 0 && g.grid[kr][kc] == val {
					matched[kr][kc] = true
					kr++
					kc--
				}
			}
		}
	}

	if found {
		mut pos_list := []MatchPos{}
		for r in 0 .. col_rows {
			for c in 0 .. col_cols {
				if matched[r][c] {
					pos_list << MatchPos{r: r, c: c}
				}
			}
		}
		g.clearing_pos = pos_list
		g.state = .clearing
		g.clear_timer = 0.35
		g.combo_count++
		return true
	} else {
		g.combo_count = 0
		g.spawn_column()
		return false
	}
}

// Clear matched gems and trigger score
pub fn (mut g ColumnsGame) apply_clearing() {
	count := g.clearing_pos.len
	for pos in g.clearing_pos {
		g.grid[pos.r][pos.c] = 0
	}
	g.clearing_pos.clear()

	// Score formula: (count * 50) * combo_multiplier * level
	points := count * 50 * g.combo_count * g.level
	g.score += points
	if g.score > g.high_score {
		g.high_score = g.score
	}
	g.jewels_cleared += count

	// Level progression every 30 jewels
	g.level = 1 + (g.jewels_cleared / 30)
	g.fall_speed = 1.8 + f64(g.level - 1) * 0.45

	g.state = .settling
}

// Apply gravity pull to floating gems in each column
pub fn (mut g ColumnsGame) apply_gravity() bool {
	mut moved := false
	for c in 0 .. col_cols {
		mut write_r := col_rows - 1
		for r := col_rows - 1; r >= 0; r-- {
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

pub fn (mut g ColumnsGame) update(dt f64) {
	match g.state {
		.falling {
			landing_r := g.get_landing_row(g.active_col.c)
			g.active_col.y += g.fall_speed * dt
			if int(g.active_col.y) + 2 >= landing_r {
				g.lock_column()
			}
		}
		.clearing {
			g.clear_timer -= dt
			if g.clear_timer <= 0 {
				g.apply_clearing()
			}
		}
		.settling {
			g.apply_gravity()
			g.check_matches()
		}
		.game_over {}
	}
}

pub fn (mut g ColumnsGame) hard_drop() {
	if g.state != .falling {
		return
	}
	landing_r := g.get_landing_row(g.active_col.c)
	g.active_col.y = f64(landing_r - 2)
	g.lock_column()
}
