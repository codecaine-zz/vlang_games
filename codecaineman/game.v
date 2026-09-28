module main

import math
import rand

const map_cols = 28
const map_rows = 25

enum TileType {
	empty
	wall
	dot
	power_pellet
	door
	fruit
}

enum Direction {
	none
	up
	down
	left
	right
}

enum GhostName {
	blinky
	pinky
	inky
	clyde
}

enum GhostMode {
	chase
	scatter
	frightened
	eaten
}

enum GameStatus {
	ready
	playing
	dying
	level_clear
	game_over
	paused
}

struct PacMan {
pub mut:
	col           int
	row           int
	x             f64
	y             f64
	dir           Direction
	next_dir      Direction
	speed         f64
	mouth_angle   f64
	mouth_opening bool
}

struct Ghost {
pub mut:
	name       GhostName
	mode       GhostMode
	col        int
	row        int
	x          f64
	y          f64
	dir        Direction
	target_col int
	target_row int
	home_col   int
	home_row   int
	spawn_col  int
	spawn_row  int
	speed      f64
	last_c     int = -1
	last_r     int = -1
}

struct Particle {
pub mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	color Color
	life  f64
}

struct FloatingText {
pub mut:
	x     f64
	y     f64
	text  string
	color Color
	life  f64
}

struct Game {
pub mut:
	grid                    [28][25]TileType
	pacman                  PacMan
	ghosts                  []Ghost
	particles               []Particle
	popups                  []FloatingText
	status                  GameStatus = .ready
	score                   int
	high_score              int
	lives                   int = 3
	level                   int = 1
	dots_remaining          int
	power_pellets_remaining int
	frightened_timer        f64
	ghost_eaten_cnt         int
	scatter_timer           f64
	global_timer            f64
	ready_timer             f64 = 2.0
	dying_timer             f64
	fruit_active            bool
	fruit_timer             f64
	fruit_col               int = 13
	fruit_row               int = 18
	fruit_val               int = 100
	last_ate_fruit          bool
	is_pacman_moving        bool
	shake_trauma            f64
}

// Authentic 28x25 Pac-Man Arcade Maze Layout String Array
const default_maze = [
	'1111111111111111111111111111',
	'1322221122221111222211222231',
	'1211121121121111211211211121',
	'1211121121121111211211211121',
	'1222222222222222222222222221',
	'1211121121111111111211211121',
	'1211121121111111111211211121',
	'1222221122221111222211222221',
	'1111121111101111011111211111',
	'0000121100000000000011210000',
	'1111121101114411110011211111',
	'0000020001000000010000200000',
	'1111121101111111110011211111',
	'0000121100000000000011210000',
	'1111121101111111110011211111',
	'1222222222221111222222222221',
	'1211121111121111211111211121',
	'1211121111121111211111211121',
	'1322222222220000222222222231',
	'1112121121111111111211212111',
	'1222221122221111222211222221',
	'1211111111121111211111111121',
	'1211111111121111211111111121',
	'1222222222222222222222222221',
	'1111111111111111111111111111',
]

fn dir_to_offset(dir Direction) (int, int) {
	return match dir {
		.up { 0, -1 }
		.down { 0, 1 }
		.left { -1, 0 }
		.right { 1, 0 }
		else { 0, 0 }
	}
}

fn opposite_dir(dir Direction) Direction {
	return match dir {
		.up { Direction.down }
		.down { Direction.up }
		.left { Direction.right }
		.right { Direction.left }
		else { Direction.none }
	}
}

fn new_game() Game {
	mut g := Game{
		status:     .ready
		lives:      3
		score:      0
		high_score: 0
		level:      1
	}
	g.init_level()
	return g
}

fn (mut g Game) init_level() {
	g.particles.clear()
	g.popups.clear()
	g.frightened_timer = 0
	g.ghost_eaten_cnt = 0
	g.scatter_timer = 0
	g.global_timer = 0
	g.ready_timer = 2.0
	g.dying_timer = 0
	g.fruit_active = false
	g.shake_trauma = 0.0
	g.status = .ready

	// Load 28x25 default maze
	g.dots_remaining = 0
	g.power_pellets_remaining = 0
	for r in 0 .. map_rows {
		line := if r < default_maze.len { default_maze[r] } else { default_maze[0] }
		for c in 0 .. map_cols {
			ch := if c < line.len { line[c] } else { `0` }
			tile := match ch {
				`1` { TileType.wall }
				`2` { TileType.dot }
				`3` { TileType.power_pellet }
				`4` { TileType.door }
				else { TileType.empty }
			}
			g.grid[c][r] = tile
			if tile == .dot {
				g.dots_remaining++
			} else if tile == .power_pellet {
				g.power_pellets_remaining++
			}
		}
	}

	// Init Pac-Man at starting open tile (13, 18)
	g.pacman = PacMan{
		col:           13
		row:           18
		x:             13.0 * 24.0 + 12.0
		y:             18.0 * 24.0 + 12.0
		dir:           .left
		next_dir:      .left
		speed:         110.0
		mouth_angle:   0.25
		mouth_opening: true
	}

	// Init 4 Ghosts
	g.ghosts = [
		Ghost{
			name:       .blinky
			mode:       .scatter
			col:        13
			row:        9
			x:          13.0 * 24.0 + 12.0
			y:          9.0 * 24.0 + 12.0
			dir:        .left
			target_col: 25
			target_row: 0
			home_col:   25
			home_row:   0
			spawn_col:  13
			spawn_row:  9
			speed:      100.0
			last_c:     -1
			last_r:     -1
		},
		Ghost{
			name:       .pinky
			mode:       .scatter
			col:        13
			row:        11
			x:          13.0 * 24.0 + 12.0
			y:          11.0 * 24.0 + 12.0
			dir:        .up
			target_col: 2
			target_row: 0
			home_col:   2
			home_row:   0
			spawn_col:  13
			spawn_row:  11
			speed:      95.0
			last_c:     -1
			last_r:     -1
		},
		Ghost{
			name:       .inky
			mode:       .scatter
			col:        11
			row:        11
			x:          11.0 * 24.0 + 12.0
			y:          11.0 * 24.0 + 12.0
			dir:        .up
			target_col: 27
			target_row: 24
			home_col:   27
			home_row:   24
			spawn_col:  11
			spawn_row:  11
			speed:      90.0
			last_c:     -1
			last_r:     -1
		},
		Ghost{
			name:       .clyde
			mode:       .scatter
			col:        15
			row:        11
			x:          15.0 * 24.0 + 12.0
			y:          11.0 * 24.0 + 12.0
			dir:        .up
			target_col: 0
			target_row: 24
			home_col:   0
			home_row:   24
			spawn_col:  15
			spawn_row:  11
			speed:      85.0
			last_c:     -1
			last_r:     -1
		},
	]
}

fn (mut g Game) is_wall(c int, r int) bool {
	if c < 0 || c >= map_cols || r < 0 || r >= map_rows {
		if (r == 9 || r == 13) && (c < 0 || c >= map_cols) {
			return false
		}
		return true
	}
	return g.grid[c][r] == .wall
}

fn (mut g Game) can_move(c int, r int, dir Direction, is_ghost bool) bool {
	dc, dr := dir_to_offset(dir)
	nc := c + dc
	nr := r + dr

	if (nr == 9 || nr == 13) && (nc < 0 || nc >= map_cols) {
		return true
	}

	if nc < 0 || nc >= map_cols || nr < 0 || nr >= map_rows {
		return false
	}

	tile := g.grid[nc][nr]
	if tile == .wall {
		return false
	}
	if tile == .door {
		if !is_ghost {
			return false
		}
		is_inside_house := r >= 10 && r <= 12 && c >= 10 && c <= 17
		if !is_inside_house && dir == .down {
			return false
		}
	}
	return true
}

fn (mut g Game) update_pacman(dt f64) (bool, bool) {
	mut ate_dot := false
	mut ate_power := false
	mut ate_fruit := false
	mut is_moving := false

	mut c := int(g.pacman.x / 24.0)
	mut r := int(g.pacman.y / 24.0)
	if c < 0 {
		c = 0
	} else if c >= map_cols {
		c = map_cols - 1
	}
	if r < 0 {
		r = 0
	} else if r >= map_rows {
		r = map_rows - 1
	}
	g.pacman.col = c
	g.pacman.row = r

	cx := f64(g.pacman.col * 24 + 12)
	cy := f64(g.pacman.row * 24 + 12)

	dist_to_center := math.sqrt((g.pacman.x - cx) * (g.pacman.x - cx) +
		(g.pacman.y - cy) * (g.pacman.y - cy))

	if dist_to_center < 5.0 && g.pacman.next_dir != g.pacman.dir {
		if g.can_move(g.pacman.col, g.pacman.row, g.pacman.next_dir, false) {
			if g.pacman.next_dir == .up || g.pacman.next_dir == .down {
				g.pacman.x = cx
			}
			if g.pacman.next_dir == .left || g.pacman.next_dir == .right {
				g.pacman.y = cy
			}
			g.pacman.dir = g.pacman.next_dir
		}
	}

	dc2, dr2 := dir_to_offset(g.pacman.dir)
	next_c := g.pacman.col + dc2
	next_r := g.pacman.row + dr2
	is_tunnel_wrap := (g.pacman.row == 9 || g.pacman.row == 13)
		&& (next_c < 0 || next_c >= map_cols)
	mut blocked := false
	if is_tunnel_wrap {
		blocked = false
	} else if next_c < 0 || next_c >= map_cols || next_r < 0 || next_r >= map_rows {
		blocked = true
	} else if g.grid[next_c][next_r] == .wall || g.grid[next_c][next_r] == .door {
		mut x_blocked := false
		if dc2 > 0 && g.pacman.x >= cx {
			x_blocked = true
		} else if dc2 < 0 && g.pacman.x <= cx {
			x_blocked = true
		}
		mut y_blocked := false
		if dr2 > 0 && g.pacman.y >= cy {
			y_blocked = true
		} else if dr2 < 0 && g.pacman.y <= cy {
			y_blocked = true
		}
		if x_blocked || y_blocked {
			blocked = true
		}
	}

	if !blocked {
		is_moving = true
		dc, dr := dir_to_offset(g.pacman.dir)
		g.pacman.x += f64(dc) * g.pacman.speed * dt
		g.pacman.y += f64(dr) * g.pacman.speed * dt

		if g.pacman.row == 9 || g.pacman.row == 13 {
			if g.pacman.x < 0 {
				g.pacman.x = f64(map_cols * 24 - 12)
			} else if g.pacman.x >= f64(map_cols * 24) {
				g.pacman.x = 12.0
			}
		}

		if g.pacman.mouth_opening {
			g.pacman.mouth_angle += 5.5 * dt
			if g.pacman.mouth_angle >= 0.85 {
				g.pacman.mouth_angle = 0.85
				g.pacman.mouth_opening = false
			}
		} else {
			g.pacman.mouth_angle -= 5.5 * dt
			if g.pacman.mouth_angle <= 0.05 {
				g.pacman.mouth_angle = 0.05
				g.pacman.mouth_opening = true
			}
		}
	} else {
		if dc2 != 0 {
			g.pacman.x = cx
		} else if dr2 != 0 {
			g.pacman.y = cy
		}
	}

	mut cur_c := int(g.pacman.x / 24.0)
	mut cur_r := int(g.pacman.y / 24.0)
	if cur_c < 0 {
		cur_c = 0
	} else if cur_c >= map_cols {
		cur_c = map_cols - 1
	}
	if cur_r < 0 {
		cur_r = 0
	} else if cur_r >= map_rows {
		cur_r = map_rows - 1
	}
	g.pacman.col = cur_c
	g.pacman.row = cur_r

	tile := g.grid[cur_c][cur_r]
	if tile == .dot {
		g.grid[cur_c][cur_r] = .empty
		g.dots_remaining--
		g.score += 10
		ate_dot = true

		if g.score > g.high_score {
			g.high_score = g.score
		}

		if g.dots_remaining == 120 && !g.fruit_active {
			g.fruit_active = true
			g.fruit_timer = 9.0
		}
	} else if tile == .power_pellet {
		g.grid[cur_c][cur_r] = .empty
		g.power_pellets_remaining--
		g.score += 50
		ate_power = true
		g.frightened_timer = 7.0
		g.ghost_eaten_cnt = 0

		for i in 0 .. g.ghosts.len {
			if g.ghosts[i].mode != .eaten {
				g.ghosts[i].mode = .frightened
				g.ghosts[i].last_c = -1
				g.ghosts[i].last_r = -1
				gc := int(g.ghosts[i].x / 24.0)
				gr := int(g.ghosts[i].y / 24.0)
				g.ghosts[i].col = gc
				g.ghosts[i].row = gr
				opp := opposite_dir(g.ghosts[i].dir)
				if g.can_move(gc, gr, opp, true) {
					g.ghosts[i].dir = opp
				}
			}
		}

		if g.score > g.high_score {
			g.high_score = g.score
		}
	}

	if g.fruit_active && cur_c == g.fruit_col && cur_r == g.fruit_row {
		g.fruit_active = false
		g.score += g.fruit_val
		ate_fruit = true
		g.popups << FloatingText{
			x:     f64(g.fruit_col * 24 + 12)
			y:     f64(g.fruit_row * 24 + 12)
			text:  '+${g.fruit_val}'
			color: Color{
				r: 255
				g: 100
				b: 200
			}
			life:  1.2
		}
	}

	if g.dots_remaining <= 0 && g.power_pellets_remaining <= 0 {
		g.status = .level_clear
	}

	g.last_ate_fruit = ate_fruit
	g.is_pacman_moving = is_moving
	return ate_dot, ate_power
}

fn (mut g Game) update_ghost_ai(idx int) {
	mut ghost := &g.ghosts[idx]

	match ghost.mode {
		.scatter {
			ghost.target_col = ghost.home_col
			ghost.target_row = ghost.home_row
		}
		.frightened {
			ghost.target_col = rand.intn(map_cols) or { 0 }
			ghost.target_row = rand.intn(map_rows) or { 0 }
		}
		.eaten {
			ghost.target_col = ghost.spawn_col
			ghost.target_row = ghost.spawn_row
		}
		.chase {
			match ghost.name {
				.blinky {
					ghost.target_col = g.pacman.col
					ghost.target_row = g.pacman.row
				}
				.pinky {
					dc, dr := dir_to_offset(g.pacman.dir)
					ghost.target_col = g.pacman.col + dc * 4
					ghost.target_row = g.pacman.row + dr * 4
				}
				.inky {
					dc, dr := dir_to_offset(g.pacman.dir)
					p2_c := g.pacman.col + dc * 2
					p2_r := g.pacman.row + dr * 2
					b_c := g.ghosts[0].col
					b_r := g.ghosts[0].row
					ghost.target_col = p2_c + (p2_c - b_c)
					ghost.target_row = p2_r + (p2_r - b_r)
				}
				.clyde {
					dist_sq := (ghost.col - g.pacman.col) * (ghost.col - g.pacman.col) +
						(ghost.row - g.pacman.row) * (ghost.row - g.pacman.row)
					if dist_sq > 64 {
						ghost.target_col = g.pacman.col
						ghost.target_row = g.pacman.row
					} else {
						ghost.target_col = ghost.home_col
						ghost.target_row = ghost.home_row
					}
				}
			}
		}
	}
}

fn (mut g Game) update_ghosts(dt f64) (bool, bool) {
	mut ate_ghost := false
	mut pacman_died := false

	for i in 0 .. g.ghosts.len {
		g.update_ghost_ai(i)
		mut ghost := &g.ghosts[i]

		ghost.col = int(ghost.x / 24.0)
		ghost.row = int(ghost.y / 24.0)
		cur_c := ghost.col
		cur_r := ghost.row
		cx := f64(cur_c * 24 + 12)
		cy := f64(cur_r * 24 + 12)

		dist_center := math.sqrt((ghost.x - cx) * (ghost.x - cx) + (ghost.y - cy) * (ghost.y - cy))

		// Evaluate direction change if current direction is blocked OR (near cell center AND new tile)
		is_new_tile := cur_c != ghost.last_c || cur_r != ghost.last_r
		if !g.can_move(cur_c, cur_r, ghost.dir, true) || (dist_center < 5.0 && is_new_tile) {
			ghost.last_c = cur_c
			ghost.last_r = cur_r
			dirs := [Direction.up, Direction.left, Direction.down, Direction.right]
			opp := opposite_dir(ghost.dir)

			mut valid_dirs := []Direction{}
			for d in dirs {
				if d != opp && g.can_move(cur_c, cur_r, d, true) {
					valid_dirs << d
				}
			}

			if valid_dirs.len == 0 {
				for d in dirs {
					if g.can_move(cur_c, cur_r, d, true) {
						valid_dirs << d
					}
				}
			}

			if valid_dirs.len > 0 {
				if ghost.mode == .frightened {
					ghost.dir = valid_dirs[rand.intn(valid_dirs.len) or { 0 }]
				} else {
					mut best_d := valid_dirs[0]
					mut min_d := 999999.0
					for d in valid_dirs {
						dc, dr := dir_to_offset(d)
						nc := cur_c + dc
						nr := cur_r + dr
						dist := f64((nc - ghost.target_col) * (nc - ghost.target_col) +
							(nr - ghost.target_row) * (nr - ghost.target_row))
						if dist < min_d {
							min_d = dist
							best_d = d
						}
					}
					ghost.dir = best_d
				}

				if ghost.dir == .up || ghost.dir == .down {
					ghost.x = cx
				}
				if ghost.dir == .left || ghost.dir == .right {
					ghost.y = cy
				}
			}
		}

		cur_speed := match ghost.mode {
			.frightened { ghost.speed * 0.55 }
			.eaten { ghost.speed * 1.8 }
			else { ghost.speed }
		}

		if g.can_move(cur_c, cur_r, ghost.dir, true) {
			dc, dr := dir_to_offset(ghost.dir)
			ghost.x += f64(dc) * cur_speed * dt
			ghost.y += f64(dr) * cur_speed * dt

			if cur_r == 9 || cur_r == 13 {
				if ghost.x < 0 {
					ghost.x = f64(map_cols * 24 - 12)
				} else if ghost.x >= f64(map_cols * 24) {
					ghost.x = 12.0
				}
			}
		} else {
			ghost.x = cx
			ghost.y = cy
		}

		ghost.col = int(ghost.x / 24.0)
		ghost.row = int(ghost.y / 24.0)

		if ghost.mode == .eaten && ghost.col == ghost.spawn_col && ghost.row == ghost.spawn_row {
			ghost.mode = .chase
		}

		dist_to_pac := (ghost.x - g.pacman.x) * (ghost.x - g.pacman.x) +
			(ghost.y - g.pacman.y) * (ghost.y - g.pacman.y)
		if dist_to_pac < 256.0 {
			if ghost.mode == .frightened {
				ghost.mode = .eaten
				g.ghost_eaten_cnt++
				pts := match g.ghost_eaten_cnt {
					1 { 200 }
					2 { 400 }
					3 { 800 }
					else { 1600 }
				}
				g.score += pts
				ate_ghost = true
				g.popups << FloatingText{
					x:     ghost.x
					y:     ghost.y
					text:  '+${pts}'
					color: Color{
						r: 50
						g: 220
						b: 255
					}
					life:  1.0
				}
			} else if ghost.mode != .eaten {
				pacman_died = true
			}
		}
	}

	return ate_ghost, pacman_died
}

pub struct PacmanEvents {
pub mut:
	ate_dot   bool
	ate_power bool
	ate_fruit bool
	ate_ghost bool
	pac_died  bool
	level_win bool
	is_moving bool
}

pub fn (mut g Game) update(dt f64) PacmanEvents {
	mut ev := PacmanEvents{}

	g.global_timer += dt

	for i := g.popups.len - 1; i >= 0; i-- {
		g.popups[i].life -= dt
		g.popups[i].y -= 25.0 * dt
		if g.popups[i].life <= 0 {
			g.popups.delete(i)
		}
	}

	for i := g.particles.len - 1; i >= 0; i-- {
		g.particles[i].life -= dt
		g.particles[i].x += g.particles[i].vx * dt
		g.particles[i].y += g.particles[i].vy * dt
		if g.particles[i].life <= 0 {
			g.particles.delete(i)
		}
	}

	if g.fruit_active {
		g.fruit_timer -= dt
		if g.fruit_timer <= 0 {
			g.fruit_active = false
		}
	}

	if g.shake_trauma > 0.0 {
		g.shake_trauma = math.max(0.0, g.shake_trauma - dt * 2.2)
	}

	match g.status {
		.ready {
			g.ready_timer -= dt
			if g.ready_timer <= 0 {
				g.status = .playing
			}
		}
		.playing {
			if g.frightened_timer > 0 {
				g.frightened_timer -= dt
				if g.frightened_timer <= 0 {
					g.frightened_timer = 0
					for i in 0 .. g.ghosts.len {
						if g.ghosts[i].mode == .frightened {
							g.ghosts[i].mode = .chase
							g.ghosts[i].last_c = -1
							g.ghosts[i].last_r = -1
						}
					}
				}
			} else {
				g.scatter_timer += dt
				if g.scatter_timer >= 27.0 {
					g.scatter_timer = 0
				}
				new_mode := if g.scatter_timer < 7.0 { GhostMode.scatter } else { GhostMode.chase }
				for i in 0 .. g.ghosts.len {
					if g.ghosts[i].mode != .eaten && g.ghosts[i].mode != .frightened {
						g.ghosts[i].mode = new_mode
					}
				}
			}

			ev.ate_dot, ev.ate_power = g.update_pacman(dt)
			ev.ate_fruit = g.last_ate_fruit
			ev.is_moving = g.is_pacman_moving
			ev.ate_ghost, ev.pac_died = g.update_ghosts(dt)

			if ev.ate_power {
				g.shake_trauma = math.min(1.0, g.shake_trauma + 0.18)
			}
			if ev.ate_fruit {
				g.shake_trauma = math.min(1.0, g.shake_trauma + 0.15)
			}
			if ev.ate_ghost {
				g.shake_trauma = math.min(1.0, g.shake_trauma + 0.28)
			}

			if ev.pac_died {
				g.lives--
				g.shake_trauma = math.min(1.0, g.shake_trauma + 0.55)
				g.status = .dying
				g.dying_timer = 1.5
			}
		}
		.dying {
			g.dying_timer -= dt
			if g.dying_timer <= 0 {
				if g.lives <= 0 {
					g.status = .game_over
				} else {
					g.init_level()
				}
			}
		}
		.level_clear {
			ev.level_win = true
			g.ready_timer -= dt
			if g.ready_timer <= 0 {
				g.level++
				g.init_level()
			}
		}
		else {}
	}

	return ev
}
