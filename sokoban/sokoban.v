module main

pub enum Tile {
	empty
	floor
	wall
	target
	crate
	crate_on_target
	player
	player_on_target
}

pub struct MoveAction {
pub:
	from_r       int
	from_c       int
	to_r         int
	to_c         int
	pushed_crate bool
	crate_from_r int
	crate_from_c int
	crate_to_r   int
	crate_to_c   int
}

pub struct SokobanGame {
pub mut:
	current_level  int
	cols           int
	rows           int
	grid           [][]Tile
	player_r       int
	player_c       int
	player_dir     int
	anim_px        f64
	anim_py        f64
	steps          int
	pushes         int
	history        []MoveAction
	level_cleared  bool
	total_targets  int
	targets_filled int
	editor_mode    bool
	editor_brush       Tile = .wall
	max_level_unlocked int
	toast_msg          string
	toast_timer        f64
}

pub fn new_sokoban_game() SokobanGame {
	mut game := SokobanGame{}
	saved := load_sokoban_save()
	game.max_level_unlocked = saved.max_level_unlocked
	start_lvl := if saved.current_level >= 0 && saved.current_level < sokoban_levels.len { saved.current_level } else { 0 }
	game.load_level(start_lvl)
	return game
}

pub fn (mut g SokobanGame) load_level(lvl_idx int) {
	idx := if lvl_idx < 0 {
		0
	} else if lvl_idx >= sokoban_levels.len {
		sokoban_levels.len - 1
	} else {
		lvl_idx
	}
	g.current_level = idx
	g.load_from_lines(sokoban_levels[idx].map_data)
}

pub fn (mut g SokobanGame) load_from_lines(lines []string) {
	g.rows = lines.len
	mut max_w := 0
	for line in lines {
		if line.len > max_w {
			max_w = line.len
		}
	}
	g.cols = max_w

	g.grid = [][]Tile{len: g.rows, init: []Tile{len: g.cols, init: .empty}}
	g.total_targets = 0
	g.targets_filled = 0
	g.steps = 0
	g.pushes = 0
	g.history.clear()
	g.level_cleared = false

	for r in 0 .. g.rows {
		line := lines[r]
		for c in 0 .. line.len {
			ch := line[c]
			match ch {
				`#` {
					g.grid[r][c] = .wall
				}
				` ` {
					g.grid[r][c] = .floor
				}
				`.` {
					g.grid[r][c] = .target
					g.total_targets++
				}
				`$` {
					g.grid[r][c] = .crate
				}
				`*` {
					g.grid[r][c] = .crate_on_target
					g.total_targets++
					g.targets_filled++
				}
				`@` {
					g.grid[r][c] = .player
					g.player_r = r
					g.player_c = c
				}
				`+` {
					g.grid[r][c] = .player_on_target
					g.player_r = r
					g.player_c = c
					g.total_targets++
				}
				else {
					g.grid[r][c] = .empty
				}
			}
		}
	}

	g.anim_px = f64(g.player_c)
	g.anim_py = f64(g.player_r)
}

pub fn (g &SokobanGame) is_valid(r int, c int) bool {
	return r >= 0 && r < g.rows && c >= 0 && c < g.cols
}

pub fn (mut g SokobanGame) try_move(dr int, dc int) (bool, bool, bool) {
	if dr > 0 {
		g.player_dir = 0
	} else if dr < 0 {
		g.player_dir = 1
	} else if dc < 0 {
		g.player_dir = 2
	} else if dc > 0 {
		g.player_dir = 3
	}

	if g.level_cleared {
		return false, false, false
	}

	nr := g.player_r + dr
	nc := g.player_c + dc

	if !g.is_valid(nr, nc) {
		return false, false, false
	}

	dest := g.grid[nr][nc]
	if dest == .wall || dest == .empty {
		return false, false, false
	}

	mut pushed := false
	mut hit_target := false
	mut box_from_r := 0
	mut box_from_c := 0
	mut box_to_r := 0
	mut box_to_c := 0

	if dest == .crate || dest == .crate_on_target {
		// Attempt crate push
		nnr := nr + dr
		nnc := nc + dc
		if !g.is_valid(nnr, nnc) {
			return false, false, false
		}
		crate_dest := g.grid[nnr][nnc]
		if crate_dest == .wall || crate_dest == .empty || crate_dest == .crate || crate_dest == .crate_on_target {
			return false, false, false // Blocked crate
		}

		pushed = true
		box_from_r = nr
		box_from_c = nc
		box_to_r = nnr
		box_to_c = nnc

		// Move crate to new spot
		if crate_dest == .target {
			g.grid[nnr][nnc] = .crate_on_target
			hit_target = true
		} else {
			g.grid[nnr][nnc] = .crate
		}

		// Clear old crate spot
		if dest == .crate_on_target {
			g.grid[nr][nc] = .player_on_target
		} else {
			g.grid[nr][nc] = .player
		}
	} else if dest == .target {
		g.grid[nr][nc] = .player_on_target
	} else {
		g.grid[nr][nc] = .player
	}

	// Clear old player spot
	curr_tile := g.grid[g.player_r][g.player_c]
	if curr_tile == .player_on_target {
		g.grid[g.player_r][g.player_c] = .target
	} else {
		g.grid[g.player_r][g.player_c] = .floor
	}

	// Record history
	g.history << MoveAction{
		from_r:       g.player_r
		from_c:       g.player_c
		to_r:         nr
		to_c:         nc
		pushed_crate: pushed
		crate_from_r: box_from_r
		crate_from_c: box_from_c
		crate_to_r:   box_to_r
		crate_to_c:   box_to_c
	}

	g.player_r = nr
	g.player_c = nc
	g.steps++
	if pushed {
		g.pushes++
	}

	g.check_win()
	return true, pushed, hit_target
}

pub fn (mut g SokobanGame) undo() bool {
	if g.history.len == 0 {
		return false
	}
	last := g.history.pop()

	// Restore player
	curr_player_tile := g.grid[g.player_r][g.player_c]
	if curr_player_tile == .player_on_target {
		g.grid[g.player_r][g.player_c] = .target
	} else {
		g.grid[g.player_r][g.player_c] = .floor
	}

	g.player_r = last.from_r
	g.player_c = last.from_c
	from_tile := g.grid[last.from_r][last.from_c]
	if from_tile == .target {
		g.grid[last.from_r][last.from_c] = .player_on_target
	} else {
		g.grid[last.from_r][last.from_c] = .player
	}

	// Restore crate if pushed
	if last.pushed_crate {
		// Clear box to
		to_box_tile := g.grid[last.crate_to_r][last.crate_to_c]
		if to_box_tile == .crate_on_target {
			g.grid[last.crate_to_r][last.crate_to_c] = .target
		} else {
			g.grid[last.crate_to_r][last.crate_to_c] = .floor
		}

		// Restore box from
		from_box_tile := g.grid[last.crate_from_r][last.crate_from_c]
		if from_box_tile == .target || from_box_tile == .player_on_target {
			g.grid[last.crate_from_r][last.crate_from_c] = .crate_on_target
		} else {
			g.grid[last.crate_from_r][last.crate_from_c] = .crate
		}
		g.pushes--
	}

	g.steps--
	g.anim_px = f64(g.player_c)
	g.anim_py = f64(g.player_r)
	g.level_cleared = false
	g.check_win()
	return true
}

pub fn (mut g SokobanGame) check_win() bool {
	mut on_target := 0
	for r in 0 .. g.rows {
		for c in 0 .. g.cols {
			if g.grid[r][c] == .crate_on_target {
				on_target++
			}
		}
	}
	g.targets_filled = on_target
	if g.total_targets > 0 && on_target == g.total_targets {
		g.level_cleared = true
		if g.current_level >= g.max_level_unlocked {
			g.max_level_unlocked = g.current_level + 1
		}
		g.save_progress()
		return true
	}
	return false
}

pub fn (g &SokobanGame) calculate_stars() int {
	if g.current_level >= sokoban_levels.len {
		return 3
	}
	par := sokoban_levels[g.current_level].par_pushes
	if g.pushes <= par {
		return 3
	} else if g.pushes <= par * 3 / 2 {
		return 2
	} else {
		return 1
	}
}

pub fn (mut g SokobanGame) save_progress() {
	mut saved := load_sokoban_save()
	saved.max_level_unlocked = g.max_level_unlocked
	saved.current_level = g.current_level
	save_sokoban_data(&saved)
}

pub fn (mut g SokobanGame) save_state() {
	mut saved := load_sokoban_save()
	saved.max_level_unlocked = g.max_level_unlocked
	saved.current_level = g.current_level
	saved.save_state_valid = true
	saved.state_level = g.current_level
	saved.state_steps = g.steps
	saved.state_pushes = g.pushes
	saved.state_player_r = g.player_r
	saved.state_player_c = g.player_c
	
	mut lines := []string{}
	for r in 0 .. g.rows {
		mut row_str := ''
		for c in 0 .. g.cols {
			ch := match g.grid[r][c] {
				.wall { `#` }
				.floor { ` ` }
				.target { `.` }
				.crate { `$` }
				.crate_on_target { `*` }
				.player { `@` }
				.player_on_target { `+` }
				else { ` ` }
			}
			row_str += ch.str()
		}
		lines << row_str
	}
	saved.state_grid_lines = lines
	save_sokoban_data(&saved)

	g.toast_msg = 'STATE SAVED (F5)'
	g.toast_timer = 2.0
}

pub fn (mut g SokobanGame) load_state() {
	saved := load_sokoban_save()
	if !saved.save_state_valid || saved.state_grid_lines.len == 0 {
		g.toast_msg = 'NO SAVE STATE FOUND'
		g.toast_timer = 2.0
		return
	}
	g.current_level = saved.state_level
	g.steps = saved.state_steps
	g.pushes = saved.state_pushes
	g.player_r = saved.state_player_r
	g.player_c = saved.state_player_c
	g.load_from_lines(saved.state_grid_lines)
	g.steps = saved.state_steps
	g.pushes = saved.state_pushes

	g.toast_msg = 'STATE LOADED (F9)'
	g.toast_timer = 2.0
}

