module main

import rand

pub const sg_cols = 12
pub const sg_rows = 14
pub const max_gem_colors = 5 // 1: Ruby, 2: Sapphire, 3: Emerald, 4: Topaz, 5: Amethyst

pub enum GameMode {
	puzzle
	arcade_collapse
}

pub enum GameState {
	playing
	cleared_all
	no_moves_left
	game_over
}

pub struct CellPos {
pub:
	r int
	c int
}

pub struct SameGame {
pub mut:
	grid           [14][12]int // 0 is empty. Row 0 is top, Row 13 is bottom
	mode           GameMode  = .puzzle
	state          GameState = .playing
	score          int
	high_score     int
	hover_cluster  []CellPos
	hover_r        int = -1
	hover_c        int = -1
	rise_timer     f64
	rise_interval  f64 = 6.0
	gems_cleared   int
}

pub fn new_same_game(mode GameMode) SameGame {
	mut g := SameGame{
		mode: mode
	}
	g.init_grid()
	return g
}

pub fn (mut g SameGame) init_grid() {
	g.state = .playing
	g.gems_cleared = 0
	g.hover_cluster.clear()
	g.hover_r = -1
	g.hover_c = -1
	g.rise_timer = 0

	match g.mode {
		.puzzle {
			// Fill entire board with random colors
			for r in 0 .. sg_rows {
				for c in 0 .. sg_cols {
					g.grid[r][c] = rand.int_in_range(1, max_gem_colors + 1) or { 1 }
				}
			}
		}
		.arcade_collapse {
			// Fill bottom 7 rows
			g.grid = [14][12]int{}
			for r in 7 .. sg_rows {
				for c in 0 .. sg_cols {
					g.grid[r][c] = rand.int_in_range(1, max_gem_colors + 1) or { 1 }
				}
			}
		}
	}
}

// Find all connected cells of same color starting at (start_r, start_c)
pub fn (g SameGame) find_cluster(start_r int, start_c int) []CellPos {
	if start_r < 0 || start_r >= sg_rows || start_c < 0 || start_c >= sg_cols {
		return []CellPos{}
	}
	target_color := g.grid[start_r][start_c]
	if target_color == 0 {
		return []CellPos{}
	}

	mut visited := [14][12]bool{}
	mut cluster := []CellPos{}
	mut queue := [CellPos{r: start_r, c: start_c}]
	visited[start_r][start_c] = true

	for queue.len > 0 {
		p := queue.pop()
		cluster << p

		neighbors := [
			CellPos{r: p.r - 1, c: p.c},
			CellPos{r: p.r + 1, c: p.c},
			CellPos{r: p.r, c: p.c - 1},
			CellPos{r: p.r, c: p.c + 1},
		]
		for nb in neighbors {
			if nb.r >= 0 && nb.r < sg_rows && nb.c >= 0 && nb.c < sg_cols {
				if !visited[nb.r][nb.c] && g.grid[nb.r][nb.c] == target_color {
					visited[nb.r][nb.c] = true
					queue << nb
				}
			}
		}
	}

	if cluster.len >= 2 {
		return cluster
	}
	return []CellPos{}
}

// Update hovered cell and cache active cluster
pub fn (mut g SameGame) update_hover(r int, c int) {
	if r == g.hover_r && c == g.hover_c {
		return
	}
	g.hover_r = r
	g.hover_c = c
	if r >= 0 && c >= 0 {
		g.hover_cluster = g.find_cluster(r, c)
	} else {
		g.hover_cluster.clear()
	}
}

// Shatter the active cluster at (r, c)
pub fn (mut g SameGame) click_cell(r int, c int) int {
	if g.state != .playing {
		return 0
	}
	cluster := g.find_cluster(r, c)
	if cluster.len < 2 {
		return 0
	}

	// Clear cells
	for p in cluster {
		g.grid[p.r][p.c] = 0
	}

	// Score formula: (count - 2)^2 * 100
	count := cluster.len
	pts := (count - 2) * (count - 2) * 100 + count * 50
	g.score += pts
	if g.score > g.high_score {
		g.high_score = g.score
	}
	g.gems_cleared += count

	// Apply Gravity
	g.apply_gravity()

	// Clear hover cache
	g.hover_cluster.clear()

	// Check Game Over / Victory
	g.check_game_state()
	return count
}

// Apply vertical gravity drops and horizontal column shifts
pub fn (mut g SameGame) apply_gravity() {
	// Vertical Drop
	for c in 0 .. sg_cols {
		mut write_r := sg_rows - 1
		for r := sg_rows - 1; r >= 0; r-- {
			if g.grid[r][c] != 0 {
				if r != write_r {
					g.grid[write_r][c] = g.grid[r][c]
					g.grid[r][c] = 0
				}
				write_r--
			}
		}
	}

	// Horizontal Column Shift (shift nonempty columns left)
	mut write_c := 0
	for c in 0 .. sg_cols {
		// Check if column c has any gems
		mut has_gems := false
		for r in 0 .. sg_rows {
			if g.grid[r][c] != 0 {
				has_gems = true
				break
			}
		}
		if has_gems {
			if c != write_c {
				// Copy column c to write_c
				for r in 0 .. sg_rows {
					g.grid[r][write_c] = g.grid[r][c]
					g.grid[r][c] = 0
				}
			}
			write_c++
		}
	}
}

// Push new row from bottom in Arcade mode
pub fn (mut g SameGame) push_new_row() bool {
	// Check if top row is occupied -> ceiling breach!
	for c in 0 .. sg_cols {
		if g.grid[0][c] != 0 {
			g.state = .game_over
			return false
		}
	}

	// Shift grid up
	for r in 0 .. sg_rows - 1 {
		for c in 0 .. sg_cols {
			g.grid[r][c] = g.grid[r + 1][c]
		}
	}

	// Fill bottom row
	for c in 0 .. sg_cols {
		g.grid[sg_rows - 1][c] = rand.int_in_range(1, max_gem_colors + 1) or { 1 }
	}
	return true
}

// Check remaining moves or full board clear
pub fn (mut g SameGame) check_game_state() {
	mut remaining_count := 0
	mut has_valid_cluster := false

	for r in 0 .. sg_rows {
		for c in 0 .. sg_cols {
			if g.grid[r][c] != 0 {
				remaining_count++
				if !has_valid_cluster {
					// Check adjacent right or down
					if c + 1 < sg_cols && g.grid[r][c + 1] == g.grid[r][c] {
						has_valid_cluster = true
					}
					if r + 1 < sg_rows && g.grid[r + 1][c] == g.grid[r][c] {
						has_valid_cluster = true
					}
				}
			}
		}
	}

	if remaining_count == 0 {
		g.state = .cleared_all
		g.score += 20000 // Perfect clear bonus!
		if g.score > g.high_score {
			g.high_score = g.score
		}
	} else if !has_valid_cluster {
		if g.mode == .puzzle {
			g.state = .no_moves_left
		}
	}
}

pub fn (mut g SameGame) update(dt f64) {
	if g.state != .playing {
		return
	}

	if g.mode == .arcade_collapse {
		g.rise_timer += dt
		if g.rise_timer >= g.rise_interval {
			g.rise_timer = 0
			g.push_new_row()
		}
	}
}
