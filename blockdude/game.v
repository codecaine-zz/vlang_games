module main

pub enum TileType {
	empty
	wall
	block
	door
}

pub enum Direction {
	left
	right
}

pub enum GameState {
	playing
	level_complete
	game_won
}

pub struct HistorySnapshot {
pub:
	grid           [][]TileType
	player_x       int
	player_y       int
	facing         Direction
	carrying_block bool
}

pub struct BlockDudeGame {
pub mut:
	grid               [][]TileType
	width              int
	height             int
	player_x           int
	player_y           int
	facing             Direction
	carrying_block     bool
	current_level      int
	moves_count        int
	state              GameState
	history            []HistorySnapshot
	max_level_unlocked int
	toast_msg          string
	toast_timer        f64
}

const levels_raw = [
	// Level 1: "First Steps" (Tutorial - 1 Block, 2-high wall)
	[
		'####################',
		'#                  #',
		'#                  #',
		'#                  #',
		'#                  #',
		'#                  #',
		'#                  #',
		'#       B          #',
		'# P    ##         D#',
		'###   ###        ###',
		'####################',
	],
	// Level 2: "Bridging the Gap" (2 Blocks)
	[
		'####################',
		'#                  #',
		'#                  #',
		'#                  #',
		'#                  #',
		'#                  #',
		'#                  #',
		'# P   B   B       D#',
		'###  ##  ##      ###',
		'###  ##  ##      ###',
		'####################',
	],
	// Level 3: "The Trench" (3 Blocks, high exit on left)
	[
		'####################',
		'#                  #',
		'#                  #',
		'#                  #',
		'#                  #',
		'#                  #',
		'# D                #',
		'###   B   B   B    #',
		'### P #   #   #    #',
		'####################',
	],
	// Level 4: "Block Quarry" (3 Blocks)
	[
		'####################',
		'#                  #',
		'#                  #',
		'#                  #',
		'#                  #',
		'#       B          #',
		'#     B # B       D#',
		'# P   # # #      ###',
		'###   # # #      ###',
		'####################',
	],
	// Level 5: "The Terraces" (3 Blocks)
	[
		'####################',
		'#                  #',
		'#                  #',
		'#                  #',
		'#                  #',
		'#     B            #',
		'#    ##   B        #',
		'#   ###  ##   B   D#',
		'# P ###  ##  ##  ###',
		'####################',
	],
	// Level 6: "The Tower of Steps" (3 Blocks)
	[
		'####################',
		'#                  #',
		'#                  #',
		'#                  #',
		'#                 D#',
		'#  B B B         ###',
		'#  # # #        ####',
		'#P # # #       #####',
		'####################',
	],
	// Level 7: "The Vault" (4 Blocks)
	[
		'####################',
		'#                  #',
		'#                  #',
		'# D                #',
		'###                #',
		'# #   B  B  B  B   #',
		'# #   #  #  #  #   #',
		'# #P  #  #  #  #   #',
		'####################',
	],
	// Level 8: "The Master Challenge" (4 Blocks)
	[
		'####################',
		'#                  #',
		'#                  #',
		'#                  #',
		'#    B             #',
		'#    #    B       D#',
		'#    #    #   B  ###',
		'# P  # B  #   #  ###',
		'##   # #  #   #  ###',
		'####################',
	],
]

pub fn new_blockdude_game() BlockDudeGame {
	mut g := BlockDudeGame{
		current_level: 0
		state: .playing
	}
	g.load_level(0)
	return g
}

pub fn (mut g BlockDudeGame) load_level(level_idx int) {
	if level_idx < 0 || level_idx >= levels_raw.len {
		return
	}
	g.current_level = level_idx
	g.moves_count = 0
	g.carrying_block = false
	g.facing = .right
	g.state = .playing
	g.history.clear()

	lines := levels_raw[level_idx]
	g.height = lines.len
	g.width = lines[0].len
	g.grid = [][]TileType{len: g.height, init: []TileType{len: g.width, init: .empty}}

	for y in 0 .. g.height {
		line := lines[y]
		for x in 0 .. g.width {
			ch := line[x]
			match ch {
				`#` { g.grid[y][x] = .wall }
				`B` { g.grid[y][x] = .block }
				`D` { g.grid[y][x] = .door }
				`P` {
					g.player_x = x
					g.player_y = y
					g.grid[y][x] = .empty
				}
				else { g.grid[y][x] = .empty }
			}
		}
	}
	g.apply_gravity()
}

pub fn (mut g BlockDudeGame) save_history() {
	mut copy_grid := [][]TileType{len: g.height, init: []TileType{len: g.width, init: .empty}}
	for y in 0 .. g.height {
		for x in 0 .. g.width {
			copy_grid[y][x] = g.grid[y][x]
		}
	}
	g.history << HistorySnapshot{
		grid: copy_grid
		player_x: g.player_x
		player_y: g.player_y
		facing: g.facing
		carrying_block: g.carrying_block
	}
	if g.history.len > 200 {
		g.history.delete(0)
	}
}

pub fn (mut g BlockDudeGame) undo() bool {
	if g.history.len == 0 || g.state == .game_won {
		return false
	}
	snap := g.history.pop()
	g.grid = snap.grid
	g.player_x = snap.player_x
	g.player_y = snap.player_y
	g.facing = snap.facing
	g.carrying_block = snap.carrying_block
	if g.moves_count > 0 {
		g.moves_count--
	}
	return true
}

pub fn (g BlockDudeGame) is_solid(x int, y int) bool {
	if x < 0 || x >= g.width || y < 0 || y >= g.height {
		return true
	}
	return g.grid[y][x] == .wall || g.grid[y][x] == .block
}

pub fn (g BlockDudeGame) is_empty(x int, y int) bool {
	if x < 0 || x >= g.width || y < 0 || y >= g.height {
		return false
	}
	return g.grid[y][x] == .empty || g.grid[y][x] == .door
}

pub fn (mut g BlockDudeGame) apply_gravity() {
	// 1. Drop movable blocks
	for _ in 0 .. g.height {
		mut changed := false
		for y := g.height - 2; y >= 0; y-- {
			for x in 0 .. g.width {
				if g.grid[y][x] == .block {
					if y + 1 < g.height && g.grid[y + 1][x] == .empty && !(x == g.player_x && y + 1 == g.player_y) && !(g.carrying_block && x == g.player_x && y + 1 == g.player_y - 1) {
						g.grid[y][x] = .empty
						g.grid[y + 1][x] = .block
						changed = true
					}
				}
			}
		}
		if !changed {
			break
		}
	}

	// 2. Drop player
	for _ in 0 .. g.height {
		if g.player_y + 1 < g.height && !g.is_solid(g.player_x, g.player_y + 1) {
			g.player_y++
		} else {
			break
		}
	}
}

pub fn (mut g BlockDudeGame) move_dir(dir Direction) bool {
	if g.state != .playing {
		return false
	}
	g.save_history()

	dx := if dir == .left { -1 } else { 1 }

	// If player is changing direction, turn first
	if g.facing != dir {
		g.facing = dir
		g.moves_count++
		return true
	}

	target_x := g.player_x + dx
	target_y := g.player_y

	// Case 1: Walk horizontally into empty space
	if !g.is_solid(target_x, target_y) {
		// If carrying block, ensure headroom at destination
		if g.carrying_block && g.is_solid(target_x, target_y - 1) {
			return false
		}
		g.player_x = target_x
		g.moves_count++
		g.apply_gravity()
		g.check_door()
		return true
	}

	// Case 2: Climb 1 block step (target is solid, cell above target is clear, cell above player is clear)
	climb_y := target_y - 1
	if climb_y >= 0 && !g.is_solid(target_x, climb_y) && !g.is_solid(g.player_x, g.player_y - 1) {
		// If carrying block, need 2 blocks of clearance above destination and current pos
		if g.carrying_block {
			if g.is_solid(g.player_x, g.player_y - 2) || g.is_solid(target_x, climb_y - 1) {
				return false
			}
		}
		g.player_x = target_x
		g.player_y = climb_y
		g.moves_count++
		g.apply_gravity()
		g.check_door()
		return true
	}

	return false
}

pub fn (mut g BlockDudeGame) pickup_or_drop() bool {
	if g.state != .playing {
		return false
	}
	g.save_history()

	dx := if g.facing == .left { -1 } else { 1 }
	target_x := g.player_x + dx
	target_y := g.player_y

	if !g.carrying_block {
		// 1. Pick up block at feet level (player_y)
		if target_x >= 0 && target_x < g.width && target_y >= 0 && target_y < g.height {
			if g.grid[target_y][target_x] == .block {
				// Overhead space above block AND above player must be clear
				if !g.is_solid(g.player_x, g.player_y - 1) && (target_y - 1 < 0 || !g.is_solid(target_x, target_y - 1)) {
					g.grid[target_y][target_x] = .empty
					g.carrying_block = true
					g.moves_count++
					return true
				}
			}
		}
		// 2. Pick up block on 1-step ledge in front (player_y - 1)
		ledge_y := target_y - 1
		if ledge_y >= 0 && target_x >= 0 && target_x < g.width {
			if g.grid[ledge_y][target_x] == .block {
				if !g.is_solid(g.player_x, g.player_y - 1) && (ledge_y - 1 < 0 || !g.is_solid(target_x, ledge_y - 1)) {
					g.grid[ledge_y][target_x] = .empty
					g.carrying_block = true
					g.moves_count++
					return true
				}
			}
		}
	} else {
		// Drop block: place in front of player
		mut drop_x := target_x
		mut drop_y := target_y

		// If feet-level target is solid, place on top of it
		if g.is_solid(target_x, target_y) {
			drop_y = target_y - 1
		}

		if drop_x >= 0 && drop_x < g.width && drop_y >= 0 && drop_y < g.height {
			if !g.is_solid(drop_x, drop_y) {
				g.grid[drop_y][drop_x] = .block
				g.carrying_block = false
				g.moves_count++
				g.apply_gravity()
				return true
			}
		}
	}
	return false
}

pub fn (mut g BlockDudeGame) check_door() {
	if g.grid[g.player_y][g.player_x] == .door {
		if g.current_level + 1 < levels_raw.len {
			g.state = .level_complete
			if g.current_level >= g.max_level_unlocked {
				g.max_level_unlocked = g.current_level + 1
			}
			g.save_progress()
		} else {
			g.state = .game_won
		}
	}
}

pub fn (mut g BlockDudeGame) next_level() {
	if g.current_level + 1 < levels_raw.len {
		g.load_level(g.current_level + 1)
		g.save_progress()
	}
}

pub fn (mut g BlockDudeGame) prev_level() {
	if g.current_level > 0 {
		g.load_level(g.current_level - 1)
		g.save_progress()
	}
}

pub fn (mut g BlockDudeGame) restart_level() {
	g.load_level(g.current_level)
}

pub fn (mut g BlockDudeGame) save_progress() {
	mut saved := load_blockdude_save()
	saved.max_level_unlocked = g.max_level_unlocked
	saved.current_level = g.current_level
	save_blockdude_data(&saved)
}

pub fn (mut g BlockDudeGame) save_state() {
	mut saved := load_blockdude_save()
	saved.max_level_unlocked = g.max_level_unlocked
	saved.current_level = g.current_level
	saved.save_state_valid = true
	saved.state_level = g.current_level
	saved.state_player_x = g.player_x
	saved.state_player_y = g.player_y
	saved.state_facing_right = (g.facing == .right)
	saved.state_carrying = g.carrying_block
	saved.state_moves = g.moves_count
	
	mut lines := []string{}
	for y in 0 .. g.height {
		mut row_str := ''
		for x in 0 .. g.width {
			ch := match g.grid[y][x] {
				.wall { `#` }
				.block { `B` }
				.door { `D` }
				else { ` ` }
			}
			row_str += ch.str()
		}
		lines << row_str
	}
	saved.state_grid_lines = lines
	save_blockdude_data(&saved)

	g.toast_msg = 'STATE SAVED (F5)'
	g.toast_timer = 2.0
}

pub fn (mut g BlockDudeGame) load_state() {
	saved := load_blockdude_save()
	if !saved.save_state_valid || saved.state_grid_lines.len == 0 {
		g.toast_msg = 'NO SAVE STATE FOUND'
		g.toast_timer = 2.0
		return
	}
	g.current_level = saved.state_level
	g.height = saved.state_grid_lines.len
	g.width = if g.height > 0 { saved.state_grid_lines[0].len } else { 0 }
	g.grid = [][]TileType{len: g.height, init: []TileType{len: g.width, init: .empty}}
	for y in 0 .. g.height {
		line := saved.state_grid_lines[y]
		for x in 0 .. line.len {
			match line[x] {
				`#` { g.grid[y][x] = .wall }
				`B` { g.grid[y][x] = .block }
				`D` { g.grid[y][x] = .door }
				else { g.grid[y][x] = .empty }
			}
		}
	}
	g.player_x = saved.state_player_x
	g.player_y = saved.state_player_y
	g.facing = if saved.state_facing_right { Direction.right } else { Direction.left }
	g.carrying_block = saved.state_carrying
	g.moves_count = saved.state_moves
	g.state = .playing

	g.toast_msg = 'STATE LOADED (F9)'
	g.toast_timer = 2.0
}

