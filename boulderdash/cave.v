module main

import rand

const tile_empty = 0
const tile_dirt = 1
const tile_wall = 2       // Steel outer boundary
const tile_brick = 3      // Rounded brick wall
const tile_boulder = 4
const tile_diamond = 5
const tile_firefly = 6    // Explodes into empty space
const tile_butterfly = 7  // Explodes into diamonds
const tile_amoeba = 8
const tile_exit_closed = 9
const tile_exit_open = 10
const tile_player = 11

struct Point {
pub:
	r int
	c int
}

struct Cave {
pub mut:
	width             int
	height            int
	name              string
	grid              [][]int
	falling_grid      [][]bool
	player_pos        Point
	diamonds_needed   int
	diamonds_got      int
	time_limit        int
	time_left         f64
	score             int
	lives             int = 3
	game_over         bool
	level_completed   bool
	door_unlocked     bool
	player_dead       bool
	death_timer       f64
	physics_timer     f64
	enemy_timer       f64
	amoeba_timer      f64
	explosion_timer   f64
	explosions        []Point
	high_score        int
	max_cave_unlocked int
	current_cave_idx  int
	toast_msg         string
	toast_timer       f64
}

fn new_cave_from_layout(name string, layout []string, needed int, time_limit int) Cave {
	height := layout.len
	width := if height > 0 { layout[0].len } else { 0 }
	mut grid := [][]int{len: height}
	mut falling := [][]bool{len: height}
	mut player_p := Point{r: 1, c: 1}

	for r in 0 .. height {
		mut row := []int{len: width}
		mut f_row := []bool{len: width}
		for c in 0 .. width {
			ch := layout[r][c]
			t := match ch {
				`#` { tile_wall }
				`B` { tile_brick }
				`.` { tile_dirt }
				`O` { tile_boulder }
				`D` { tile_diamond }
				`F` { tile_firefly }
				`U` { tile_butterfly }
				`A` { tile_amoeba }
				`E` { tile_exit_closed }
				`P` {
					player_p = Point{r: r, c: c}
					tile_player
				}
				else { tile_empty }
			}
			row[c] = t
			f_row[c] = false
		}
		grid[r] = row
		falling[r] = f_row
	}

	return Cave{
		width:           width
		height:          height
		name:            name
		grid:            grid
		falling_grid:    falling
		player_pos:      player_p
		diamonds_needed: needed
		diamonds_got:    0
		time_limit:      time_limit
		time_left:       f64(time_limit)
		score:           0
		lives:           3
		game_over:       false
		level_completed: false
		door_unlocked:   false
		player_dead:     false
	}
}

fn (c &Cave) is_valid(r int, col int) bool {
	return r >= 0 && r < c.height && col >= 0 && col < c.width
}

fn (mut c Cave) trigger_explosion(center_r int, center_c int, into_diamonds bool) {
	for dr in -1 .. 2 {
		for dc in -1 .. 2 {
			nr := center_r + dr
			nc := center_c + dc
			if c.is_valid(nr, nc) && c.grid[nr][nc] != tile_wall {
				c.grid[nr][nc] = if into_diamonds { tile_diamond } else { tile_empty }
				c.falling_grid[nr][nc] = false
				c.explosions << Point{r: nr, c: nc}
			}
		}
	}
}

fn (mut c Cave) move_player(dr int, dc int, mut sm SoundManager) bool {
	if c.player_dead || c.level_completed || c.game_over {
		return false
	}

	target_r := c.player_pos.r + dr
	target_c := c.player_pos.c + dc
	if !c.is_valid(target_r, target_c) {
		return false
	}

	target_tile := c.grid[target_r][target_c]

	if target_tile == tile_empty {
		c.grid[c.player_pos.r][c.player_pos.c] = tile_empty
		c.player_pos = Point{r: target_r, c: target_c}
		c.grid[target_r][target_c] = tile_player
		return true
	} else if target_tile == tile_dirt {
		c.grid[c.player_pos.r][c.player_pos.c] = tile_empty
		c.player_pos = Point{r: target_r, c: target_c}
		c.grid[target_r][target_c] = tile_player
		sm.play_dig_sound()
		return true
	} else if target_tile == tile_diamond {
		c.grid[c.player_pos.r][c.player_pos.c] = tile_empty
		c.player_pos = Point{r: target_r, c: target_c}
		c.grid[target_r][target_c] = tile_player
		c.diamonds_got++
		c.score += 25
		sm.play_diamond_sound()

		if c.diamonds_got >= c.diamonds_needed && !c.door_unlocked {
			c.door_unlocked = true
			sm.play_door_open_sound()
			// Unlock exit door
			for r in 0 .. c.height {
				for col in 0 .. c.width {
					if c.grid[r][col] == tile_exit_closed {
						c.grid[r][col] = tile_exit_open
					}
				}
			}
		}
		return true
	} else if target_tile == tile_boulder && dr == 0 && dc != 0 {
		// Push boulder horizontally
		push_r := target_r
		push_c := target_c + dc
		if c.is_valid(push_r, push_c) && c.grid[push_r][push_c] == tile_empty {
			c.grid[push_r][push_c] = tile_boulder
			c.falling_grid[push_r][push_c] = false
			c.grid[target_r][target_c] = tile_player
			c.grid[c.player_pos.r][c.player_pos.c] = tile_empty
			c.player_pos = Point{r: target_r, c: target_c}
			sm.play_impact_sound()
			return true
		}
	} else if target_tile == tile_exit_open {
		c.grid[c.player_pos.r][c.player_pos.c] = tile_empty
		c.player_pos = Point{r: target_r, c: target_c}
		c.grid[target_r][target_c] = tile_player
		c.level_completed = true
		c.score += int(c.time_left) * 10
		sm.play_win_sound()
		return true
	}

	return false
}

fn (mut c Cave) update_physics(mut sm SoundManager) {
	// Scan from bottom to top so falling items don't double-step
	for r := c.height - 2; r >= 0; r-- {
		for col in 0 .. c.width {
			tile := c.grid[r][col]
			if tile != tile_boulder && tile != tile_diamond {
				continue
			}

			below := c.grid[r + 1][col]
			is_falling := c.falling_grid[r][col]

			// Case 1: Empty space directly below
			if below == tile_empty {
				c.grid[r][col] = tile_empty
				c.falling_grid[r][col] = false
				c.grid[r + 1][col] = tile
				c.falling_grid[r + 1][col] = true
				continue
			}

			// Case 2: Falling onto entity (Crush!)
			if is_falling {
				if below == tile_player {
					c.player_dead = true
					c.trigger_explosion(r + 1, col, false)
					sm.play_death_sound()
					continue
				} else if below == tile_firefly {
					c.trigger_explosion(r + 1, col, false)
					sm.play_explosion_sound()
					continue
				} else if below == tile_butterfly {
					c.trigger_explosion(r + 1, col, true)
					sm.play_explosion_sound()
					continue
				}
			}

			// Case 3: Rolling off rounded shoulders (boulder, diamond, brick)
			if below == tile_boulder || below == tile_diamond || below == tile_brick {
				// Check Roll Left
				if col > 0 && c.grid[r][col - 1] == tile_empty && c.grid[r + 1][col - 1] == tile_empty {
					c.grid[r][col] = tile_empty
					c.falling_grid[r][col] = false
					c.grid[r][col - 1] = tile
					c.falling_grid[r][col - 1] = true
					continue
				}
				// Check Roll Right
				if col < c.width - 1 && c.grid[r][col + 1] == tile_empty && c.grid[r + 1][col + 1] == tile_empty {
					c.grid[r][col] = tile_empty
					c.falling_grid[r][col] = false
					c.grid[r][col + 1] = tile
					c.falling_grid[r][col + 1] = true
					continue
				}
			}

			// Landed on flat surface
			if is_falling {
				c.falling_grid[r][col] = false
				sm.play_impact_sound()
			}
		}
	}
}

fn (mut c Cave) update_enemies(mut sm SoundManager) {
	for r in 0 .. c.height {
		for col in 0 .. c.width {
			tile := c.grid[r][col]
			if tile != tile_firefly && tile != tile_butterfly {
				continue
			}

			// Check if touching player
			for dr in -1 .. 2 {
				for dc in -1 .. 2 {
					if dr != 0 && dc != 0 { continue }
					nr := r + dr
					nc := col + dc
					if c.is_valid(nr, nc) && c.grid[nr][nc] == tile_player {
						c.player_dead = true
						c.trigger_explosion(nr, nc, false)
						sm.play_death_sound()
						return
					}
				}
			}

			// Random or perimeter wander
			dirs := [Point{r: -1, c: 0}, Point{r: 1, c: 0}, Point{r: 0, c: -1}, Point{r: 0, c: 1}]
			d := dirs[rand.int_in_range(0, dirs.len) or { 0 }]
			target_r := r + d.r
			target_c := col + d.c
			if c.is_valid(target_r, target_c) && c.grid[target_r][target_c] == tile_empty {
				c.grid[r][col] = tile_empty
				c.grid[target_r][target_c] = tile
			}
		}
	}
}

fn (mut c Cave) update(dt f64, mut sm SoundManager) {
	if c.level_completed || c.game_over {
		return
	}

	if c.player_dead {
		c.death_timer += dt
		if c.death_timer >= 2.0 {
			c.lives--
			if c.lives <= 0 {
				c.game_over = true
			} else {
				c.player_dead = false
				c.death_timer = 0.0
			}
		}
		return
	}

	// Time countdown
	c.time_left -= dt
	if c.time_left <= 0.0 {
		c.time_left = 0.0
		c.player_dead = true
		c.trigger_explosion(c.player_pos.r, c.player_pos.c, false)
		sm.play_death_sound()
	}

	// Physics timer (approx 6 ticks per sec for authentic retro feel)
	c.physics_timer += dt
	if c.physics_timer >= 0.14 {
		c.physics_timer = 0.0
		c.update_physics(mut sm)
	}

	// Enemy timer
	c.enemy_timer += dt
	if c.enemy_timer >= 0.25 {
		c.enemy_timer = 0.0
		c.update_enemies(mut sm)
	}
}

pub fn (mut c Cave) save_progress() {
	if c.score > c.high_score {
		c.high_score = c.score
	}
	mut saved := load_boulder_save()
	saved.high_score = c.high_score
	saved.max_cave_unlocked = c.max_cave_unlocked
	saved.current_cave = c.current_cave_idx
	save_boulder_data(&saved)
}

pub fn (mut c Cave) save_state() {
	if c.score > c.high_score {
		c.high_score = c.score
	}
	mut saved := load_boulder_save()
	saved.high_score = c.high_score
	saved.max_cave_unlocked = c.max_cave_unlocked
	saved.current_cave = c.current_cave_idx
	saved.save_state_valid = true
	saved.state_cave = c.current_cave_idx
	saved.state_score = c.score
	saved.state_lives = c.lives
	saved.state_diamonds_got = c.diamonds_got
	saved.state_time_left = c.time_left
	saved.state_player_r = c.player_pos.r
	saved.state_player_c = c.player_pos.c

	mut lines := []string{}
	for r in 0 .. c.height {
		mut row_str := ''
		for col in 0 .. c.width {
			t_code := c.grid[r][col]
			row_str += '${t_code:02d},'
		}
		lines << row_str
	}
	saved.state_grid_lines = lines
	save_boulder_data(&saved)

	c.toast_msg = 'STATE SAVED (F5)'
	c.toast_timer = 2.0
}

pub fn (mut c Cave) load_state() {
	saved := load_boulder_save()
	if !saved.save_state_valid || saved.state_grid_lines.len < c.height {
		c.toast_msg = 'NO SAVE STATE FOUND'
		c.toast_timer = 2.0
		return
	}
	c.current_cave_idx = saved.state_cave
	c.score = saved.state_score
	c.lives = saved.state_lives
	c.diamonds_got = saved.state_diamonds_got
	c.time_left = saved.state_time_left
	c.player_pos = Point{r: saved.state_player_r, c: saved.state_player_c}
	c.player_dead = false
	c.game_over = false

	for r in 0 .. c.height {
		if r < saved.state_grid_lines.len {
			line := saved.state_grid_lines[r]
			tokens := line.split(',')
			for col in 0 .. c.width {
				if col < tokens.len && tokens[col] != '' {
					c.grid[r][col] = tokens[col].int()
				}
			}
		}
	}

	c.toast_msg = 'STATE LOADED (F9)'
	c.toast_timer = 2.0
}
