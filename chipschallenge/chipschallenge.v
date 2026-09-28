module main

pub enum Tile {
	floor
	wall
	chip
	chip_socket
	exit_portal
	hint_tile
	red_key
	blue_key
	yellow_key
	green_key
	red_door
	blue_door
	yellow_door
	green_door
	water
	fire
	ice
	dirt_block
	dirt_floor
	flippers
	fire_boots
	ice_skates
	suction_boots
}

pub struct Monster {
pub mut:
	x  int
	y  int
	dx int
	dy int
}

pub struct LevelData {
pub mut:
	name       string
	time_limit int
	hint_text  string
	start_x    int
	start_y    int
	grid       [][]Tile
	monsters   []Monster
}

pub const grid_size = 16

pub struct ChipsGame {
pub mut:
	level_idx       int
	levels          []LevelData
	grid            [][]Tile
	monsters        []Monster

	player_x        int
	player_y        int
	facing_dx       int
	facing_dy       int = 1
	walk_step       int

	chips_left      int
	red_keys        int
	blue_keys       int
	yellow_keys     int
	green_keys      int // Green keys are reusable!

	has_flippers    bool
	has_fire_boots  bool
	has_ice_skates  bool
	has_suction     bool

	time_left       f64
	is_dead         bool
	is_win          bool
	monster_timer   f64
	anim_timer      f64
	anim_frame      int

	sound_event     string
	banner_text     string
	banner_timer    f64
	showing_hint        bool
	max_level_unlocked  int
}

pub fn new_chips_game() ChipsGame {
	mut g := ChipsGame{
		grid: [][]Tile{len: grid_size, init: []Tile{len: grid_size, init: Tile.floor}}
	}
	g.init_levels()
	saved := load_chips_save()
	g.max_level_unlocked = saved.max_level_unlocked
	start_lvl := if saved.current_level >= 0 && saved.current_level < g.levels.len { saved.current_level } else { 0 }
	g.load_level(start_lvl)
	return g
}

pub fn (mut g ChipsGame) init_levels() {
	g.levels.clear()

	// Level 1: Lesson 1: Key to Success
	mut l1 := LevelData{
		name: '1. Key to Success'
		time_limit: 150
		hint_text: 'Collect chips to open the socket! Keys open matching doors.'
		start_x: 2
		start_y: 2
		grid: [][]Tile{len: grid_size, init: []Tile{len: grid_size, init: Tile.floor}}
	}
	// Walls border
	for x in 0 .. grid_size {
		for y in 0 .. grid_size {
			if x == 0 || x == grid_size - 1 || y == 0 || y == grid_size - 1 {
				l1.grid[x][y] = .wall
			}
		}
	}
	// Internal walls & puzzles
	l1.grid[4][2] = .red_key
	l1.grid[6][2] = .red_door
	l1.grid[7][2] = .chip
	l1.grid[4][4] = .blue_key
	l1.grid[6][4] = .blue_door
	l1.grid[7][4] = .chip
	l1.grid[4][6] = .yellow_key
	l1.grid[6][6] = .yellow_door
	l1.grid[7][6] = .chip
	l1.grid[4][8] = .green_key
	l1.grid[6][8] = .green_door
	l1.grid[7][8] = .chip

	l1.grid[10][5] = .chip_socket
	l1.grid[12][5] = .exit_portal
	l1.grid[2][4] = .hint_tile
	g.levels << l1

	// Level 2: Lesson 2: Elemental Hazards
	mut l2 := LevelData{
		name: '2. Elemental Hazards'
		time_limit: 180
		hint_text: 'Boots protect you from Water, Fire, and Ice!'
		start_x: 2
		start_y: 2
		grid: [][]Tile{len: grid_size, init: []Tile{len: grid_size, init: Tile.floor}}
	}
	for x in 0 .. grid_size {
		for y in 0 .. grid_size {
			if x == 0 || x == grid_size - 1 || y == 0 || y == grid_size - 1 {
				l2.grid[x][y] = .wall
			}
		}
	}
	// Water hazard corridor
	for y in 1 .. 6 { l2.grid[5][y] = .water }
	l2.grid[2][4] = .flippers
	l2.grid[7][3] = .chip

	// Fire hazard corridor
	for y in 7 .. 12 { l2.grid[5][y] = .fire }
	l2.grid[2][8] = .fire_boots
	l2.grid[7][9] = .chip

	// Dirt blocks
	l2.grid[9][6] = .dirt_block
	l2.grid[10][6] = .water
	l2.grid[11][6] = .chip

	l2.grid[13][8] = .chip_socket
	l2.grid[14][8] = .exit_portal
	g.levels << l2
}

pub fn (mut g ChipsGame) load_level(idx int) {
	g.level_idx = idx % g.levels.len
	lvl := g.levels[g.level_idx]

	for x in 0 .. grid_size {
		for y in 0 .. grid_size {
			g.grid[x][y] = lvl.grid[x][y]
		}
	}

	g.monsters.clear()
	for m in lvl.monsters {
		g.monsters << m
	}

	g.player_x = lvl.start_x
	g.player_y = lvl.start_y
	g.facing_dx = 0
	g.facing_dy = 1
	g.walk_step = 0

	g.red_keys = 0
	g.blue_keys = 0
	g.yellow_keys = 0
	g.green_keys = 0

	g.has_flippers = false
	g.has_fire_boots = false
	g.has_ice_skates = false
	g.has_suction = false

	g.time_left = f64(lvl.time_limit)
	g.is_dead = false
	g.is_win = false
	g.showing_hint = false

	// Count remaining chips
	mut count := 0
	for x in 0 .. grid_size {
		for y in 0 .. grid_size {
			if g.grid[x][y] == .chip {
				count++
			}
		}
	}
	g.chips_left = count

	g.sound_event = 'key'
	g.banner_text = 'LEVEL ${g.level_idx + 1}: ${lvl.name.to_upper()}'
	g.banner_timer = 2.5
}

pub fn (mut g ChipsGame) move_player(dx int, dy int) bool {
	if g.is_dead || g.is_win {
		return false
	}
	g.facing_dx = dx
	g.facing_dy = dy
	g.walk_step = (g.walk_step + 1) % 2

	tx := g.player_x + dx
	ty := g.player_y + dy

	if tx < 0 || tx >= grid_size || ty < 0 || ty >= grid_size {
		return false
	}

	target_tile := g.grid[tx][ty]

	match target_tile {
		.wall {
			return false
		}
		.chip_socket {
			if g.chips_left == 0 {
				g.grid[tx][ty] = .floor
				g.sound_event = 'socket'
				g.banner_text = 'SOCKET OPENED!'
				g.banner_timer = 2.0
				g.player_x = tx
				g.player_y = ty
				return true
			}
			return false
		}
		.exit_portal {
			g.player_x = tx
			g.player_y = ty
			g.is_win = true
			g.sound_event = 'win'
			g.banner_text = 'LEVEL COMPLETE!'
			g.banner_timer = 4.0
			return true
		}
		.chip {
			g.grid[tx][ty] = .floor
			g.chips_left--
			g.sound_event = 'chip'
			g.player_x = tx
			g.player_y = ty
			return true
		}
		.red_key {
			g.red_keys++
			g.grid[tx][ty] = .floor
			g.sound_event = 'key'
		}
		.blue_key {
			g.blue_keys++
			g.grid[tx][ty] = .floor
			g.sound_event = 'key'
		}
		.yellow_key {
			g.yellow_keys++
			g.grid[tx][ty] = .floor
			g.sound_event = 'key'
		}
		.green_key {
			g.green_keys++
			g.grid[tx][ty] = .floor
			g.sound_event = 'key'
		}
		.red_door {
			if g.red_keys > 0 {
				g.red_keys--
				g.grid[tx][ty] = .floor
				g.sound_event = 'door'
			} else {
				return false
			}
		}
		.blue_door {
			if g.blue_keys > 0 {
				g.blue_keys--
				g.grid[tx][ty] = .floor
				g.sound_event = 'door'
			} else {
				return false
			}
		}
		.yellow_door {
			if g.yellow_keys > 0 {
				g.yellow_keys--
				g.grid[tx][ty] = .floor
				g.sound_event = 'door'
			} else {
				return false
			}
		}
		.green_door {
			if g.green_keys > 0 {
				// Green key is reusable!
				g.grid[tx][ty] = .floor
				g.sound_event = 'door'
			} else {
				return false
			}
		}
		.flippers {
			g.has_flippers = true
			g.grid[tx][ty] = .floor
			g.sound_event = 'boot'
		}
		.fire_boots {
			g.has_fire_boots = true
			g.grid[tx][ty] = .floor
			g.sound_event = 'boot'
		}
		.ice_skates {
			g.has_ice_skates = true
			g.grid[tx][ty] = .floor
			g.sound_event = 'boot'
		}
		.suction_boots {
			g.has_suction = true
			g.grid[tx][ty] = .floor
			g.sound_event = 'boot'
		}
		.dirt_block {
			// Push dirt block
			bx := tx + dx
			by := ty + dy
			if bx >= 0 && bx < grid_size && by >= 0 && by < grid_size {
				b_tile := g.grid[bx][by]
				if b_tile == .floor {
					g.grid[bx][by] = .dirt_block
					g.grid[tx][ty] = .floor
					g.sound_event = 'push'
				} else if b_tile == .water {
					// Bridges water into dirt floor!
					g.grid[bx][by] = .dirt_floor
					g.grid[tx][ty] = .floor
					g.sound_event = 'door'
				} else {
					return false
				}
			} else {
				return false
			}
		}
		.water {
			if !g.has_flippers {
				g.is_dead = true
				g.sound_event = 'splash'
				g.banner_text = 'OOPS! CHIP CANNOT SWIM WITHOUT FLIPPERS'
				g.banner_timer = 3.0
			}
		}
		.fire {
			if !g.has_fire_boots {
				g.is_dead = true
				g.sound_event = 'burn'
				g.banner_text = 'OUCH! CHIP STEPPED ON FIRE WITHOUT FIRE BOOTS'
				g.banner_timer = 3.0
			}
		}
		.hint_tile {
			g.showing_hint = true
		}
		.floor {
			g.sound_event = 'step'
		}
		else {
			g.sound_event = 'step'
		}
	}

	g.player_x = tx
	g.player_y = ty
	return true
}

pub fn (mut g ChipsGame) update(dt f64) {
	g.anim_timer += dt
	if g.anim_timer >= 0.20 {
		g.anim_timer = 0.0
		g.anim_frame = (g.anim_frame + 1) % 4
	}

	if g.banner_timer > 0.0 {
		g.banner_timer -= dt
	}
	if !g.is_dead && !g.is_win {
		g.time_left -= dt
		if g.time_left <= 0.0 {
			g.time_left = 0.0
			g.is_dead = true
			g.sound_event = 'death'
			g.banner_text = 'TIME EXPIRED!'
			g.banner_timer = 3.0
		}
	}
}

pub fn (mut g ChipsGame) save_progress() {
	mut saved := load_chips_save()
	saved.max_level_unlocked = g.max_level_unlocked
	saved.current_level = g.level_idx
	save_chips_data(&saved)
}

pub fn (mut g ChipsGame) save_state() {
	mut saved := load_chips_save()
	saved.max_level_unlocked = g.max_level_unlocked
	saved.current_level = g.level_idx
	saved.save_state_valid = true
	saved.state_level = g.level_idx
	saved.state_player_x = g.player_x
	saved.state_player_y = g.player_y
	saved.state_chips_left = g.chips_left
	saved.state_time_left = g.time_left
	saved.state_keys = [g.red_keys, g.blue_keys, g.yellow_keys, g.green_keys]
	saved.state_boots = [g.has_flippers, g.has_fire_boots, g.has_ice_skates, g.has_suction]

	mut lines := []string{}
	for x in 0 .. grid_size {
		mut row_str := ''
		for y in 0 .. grid_size {
			t_code := int(g.grid[x][y])
			row_str += '${t_code:02d},'
		}
		lines << row_str
	}
	saved.state_grid_lines = lines
	save_chips_data(&saved)

	g.banner_text = 'STATE SAVED (F5)'
	g.banner_timer = 2.0
}

pub fn (mut g ChipsGame) load_state() {
	saved := load_chips_save()
	if !saved.save_state_valid || saved.state_grid_lines.len < grid_size {
		g.banner_text = 'NO SAVE STATE FOUND'
		g.banner_timer = 2.0
		return
	}
	g.level_idx = saved.state_level
	g.player_x = saved.state_player_x
	g.player_y = saved.state_player_y
	g.chips_left = saved.state_chips_left
	g.time_left = saved.state_time_left
	if saved.state_keys.len == 4 {
		g.red_keys = saved.state_keys[0]
		g.blue_keys = saved.state_keys[1]
		g.yellow_keys = saved.state_keys[2]
		g.green_keys = saved.state_keys[3]
	}
	if saved.state_boots.len == 4 {
		g.has_flippers = saved.state_boots[0]
		g.has_fire_boots = saved.state_boots[1]
		g.has_ice_skates = saved.state_boots[2]
		g.has_suction = saved.state_boots[3]
	}
	g.is_dead = false
	g.is_win = false

	for x in 0 .. grid_size {
		line := saved.state_grid_lines[x]
		tokens := line.split(',')
		for y in 0 .. grid_size {
			if y < tokens.len && tokens[y] != '' {
				code := tokens[y].int()
				g.grid[x][y] = unsafe { Tile(code) }
			}
		}
	}

	g.banner_text = 'STATE LOADED (F9)'
	g.banner_timer = 2.0
}

