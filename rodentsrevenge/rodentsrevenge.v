module main

import math
import rand

pub enum TileType {
	empty
	wall
	block
	cheese
	mousetrap
}

pub struct Cat {
pub mut:
	x           int
	y           int
	is_sleeping bool
	is_trapped  bool
	move_timer  f64
}

pub const grid_w = 20
pub const grid_h = 20

pub struct RodentGame {
pub mut:
	grid         [][]TileType
	level        int = 1
	score        int
	lives        int = 3
	cats         []Cat

	player_x     int
	player_y     int
	facing_dx    int
	facing_dy    int = -1

	is_game_over bool
	is_win       bool
	time_left    f64
	step_timer   f64

	sound_event  string
	banner_text  string
	banner_timer f64
}

pub fn new_rodent_game() RodentGame {
	mut g := RodentGame{
		grid: [][]TileType{len: grid_w, init: []TileType{len: grid_h, init: TileType.empty}}
	}
	g.init_level(1)
	return g
}

pub fn (mut g RodentGame) init_level(lvl int) {
	g.level = lvl
	g.time_left = 120.0
	g.is_game_over = false
	g.is_win = false

	// Clear Grid & Build Walls
	for x in 0 .. grid_w {
		for y in 0 .. grid_h {
			if x == 0 || x == grid_w - 1 || y == 0 || y == grid_h - 1 {
				g.grid[x][y] = .wall
			} else {
				g.grid[x][y] = .empty
			}
		}
	}

	// Scatter pushable blocks
	block_count := 80 + lvl * 10
	for _ in 0 .. block_count {
		bx := 1 + rand.int_in_range(0, grid_w - 2) or { 1 }
		by := 1 + rand.int_in_range(0, grid_h - 2) or { 1 }
		if !(bx >= 8 && bx <= 11 && by >= 8 && by <= 11) {
			g.grid[bx][by] = .block
		}
	}

	// Add occasional mousetraps in higher levels
	if lvl >= 2 {
		for _ in 0 .. lvl * 2 {
			tx := 2 + rand.int_in_range(0, grid_w - 4) or { 2 }
			ty := 2 + rand.int_in_range(0, grid_h - 4) or { 2 }
			if g.grid[tx][ty] == .empty {
				g.grid[tx][ty] = .mousetrap
			}
		}
	}

	// Place Player in center
	g.player_x = 10
	g.player_y = 10
	g.grid[10][10] = .empty

	// Spawn Cats
	g.cats.clear()
	cat_count := 2 + lvl * 2
	for _ in 0 .. cat_count {
		cx := 1 + rand.int_in_range(0, grid_w - 2) or { 1 }
		cy := 1 + rand.int_in_range(0, grid_h - 2) or { 1 }
		if g.grid[cx][cy] == .empty && (math.abs(cx - 10) > 3 || math.abs(cy - 10) > 3) {
			g.cats << Cat{
				x: cx
				y: cy
				is_sleeping: false
				is_trapped: false
				move_timer: 0.0
			}
		}
	}

	g.banner_text = 'LEVEL ${g.level}: TRAP ALL CATS!'
	g.banner_timer = 2.5
}

pub fn (mut g RodentGame) move_player(dx int, dy int) bool {
	if g.is_game_over || g.is_win {
		return false
	}
	g.facing_dx = dx
	g.facing_dy = dy

	tx := g.player_x + dx
	ty := g.player_y + dy

	if tx < 0 || tx >= grid_w || ty < 0 || ty >= grid_h {
		return false
	}

	target := g.grid[tx][ty]

	// Check if walking into a cat
	for c in g.cats {
		if c.x == tx && c.y == ty {
			g.kill_mouse()
			return false
		}
	}

	match target {
		.wall {
			return false
		}
		.mousetrap {
			g.kill_mouse()
			return false
		}
		.cheese {
			g.grid[tx][ty] = .empty
			g.score += 500
			g.sound_event = 'eat'
			g.player_x = tx
			g.player_y = ty
			g.check_level_clear()
			return true
		}
		.empty {
			g.player_x = tx
			g.player_y = ty
			g.sound_event = 'step'
			return true
		}
		.block {
			// Try pushing line of blocks
			mut far_x := tx
			mut far_y := ty
			for {
				far_x += dx
				far_y += dy
				if far_x < 0 || far_x >= grid_w || far_y < 0 || far_y >= grid_h {
					return false
				}
				if g.grid[far_x][far_y] == .wall || g.grid[far_x][far_y] == .mousetrap {
					return false
				}
				// Cannot push into a cat
				for c in g.cats {
					if c.x == far_x && c.y == far_y {
						return false
					}
				}
				if g.grid[far_x][far_y] == .empty {
					// Empty space found: shift all blocks forward!
					mut sx := far_x
					mut sy := far_y
					for sx != tx || sy != ty {
						prev_x := sx - dx
						prev_y := sy - dy
						g.grid[sx][sy] = g.grid[prev_x][prev_y]
						sx = prev_x
						sy = prev_y
					}
					g.grid[tx][ty] = .empty
					g.sound_event = 'push'
					g.player_x = tx
					g.player_y = ty

					// Check if any cats are now trapped!
					g.check_cat_traps()
					return true
				}
			}
		}
	}
	return false
}

pub fn (mut g RodentGame) kill_mouse() {
	g.lives--
	g.sound_event = 'die'
	if g.lives <= 0 {
		g.is_game_over = true
		g.banner_text = 'GAME OVER! CAUGHT BY CATS'
		g.banner_timer = 4.0
	} else {
		g.player_x = 10
		g.player_y = 10
		g.banner_text = 'OOPS! LIVES LEFT: ${g.lives}'
		g.banner_timer = 2.0
	}
}

pub fn (mut g RodentGame) check_cat_traps() {
	for i := g.cats.len - 1; i >= 0; i-- {
		c := g.cats[i]
		if g.is_cat_trapped(c.x, c.y) {
			// Convert Cat to Giant Cheese!
			g.grid[c.x][c.y] = .cheese
			g.cats.delete(i)
			g.score += 1000
			g.sound_event = 'cheese'
			g.banner_text = 'CAT TRAPPED -> CHEESE!'
			g.banner_timer = 1.8
		}
	}
	g.check_level_clear()
}

fn (g RodentGame) is_cat_trapped(cx int, cy int) bool {
	// Check North, South, East, West
	dirs := [[0, -1], [0, 1], [-1, 0], [1, 0]]
	for d in dirs {
		nx := cx + d[0]
		ny := cy + d[1]
		if nx < 0 || nx >= grid_w || ny < 0 || ny >= grid_h {
			continue
		}
		tile := g.grid[nx][ny]
		if tile == .empty {
			return false
		}
	}
	return true
}

pub fn (mut g RodentGame) check_level_clear() {
	if g.cats.len == 0 {
		// All cats turned to cheese
		g.is_win = true
		g.score += int(g.time_left) * 20
		g.banner_text = 'LEVEL ${g.level} COMPLETE! +${int(g.time_left) * 20} TIME BONUS'
		g.banner_timer = 3.5
	}
}

pub fn (mut g RodentGame) update(dt f64) {
	if g.banner_timer > 0.0 {
		g.banner_timer -= dt
	}
	if g.is_game_over || g.is_win {
		return
	}

	g.time_left -= dt
	if g.time_left <= 0.0 {
		g.kill_mouse()
	}

	// Move Cats
	g.step_timer += dt
	if g.step_timer >= 0.65 {
		g.step_timer = 0.0
		g.move_cats()
	}
}

fn (mut g RodentGame) move_cats() {
	for mut c in g.cats {
		dx := g.player_x - c.x
		dy := g.player_y - c.y

		mut step_x := 0
		mut step_y := 0

		if math.abs(dx) > math.abs(dy) {
			step_x = if dx > 0 { 1 } else { -1 }
		} else {
			step_y = if dy > 0 { 1 } else { -1 }
		}

		nx := c.x + step_x
		ny := c.y + step_y

		// Check if cat can step into cell
		if nx >= 0 && nx < grid_w && ny >= 0 && ny < grid_h && g.grid[nx][ny] == .empty {
			c.x = nx
			c.y = ny
		}

		// Check if cat caught mouse
		if c.x == g.player_x && c.y == g.player_y {
			g.kill_mouse()
			return
		}
	}
}
