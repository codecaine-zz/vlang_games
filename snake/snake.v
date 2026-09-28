module main

import rand

const grid_cols = 24
const grid_rows = 18

enum Direction {
	up
	down
	left
	right
}

struct Point {
pub mut:
	x int
	y int
}

struct SnakeGame {
pub mut:
	body       []Point
	dir        Direction = .right
	next_dir   Direction = .right
	food       Point
	gold_food  Point
	has_gold   bool
	score      int
	high_score int
	game_over  bool
	is_paused  bool
}

fn new_snake_game() SnakeGame {
	mut game := SnakeGame{
		body:       [Point{
			x: 10
			y: 9
		}, Point{
			x: 9
			y: 9
		}, Point{
			x: 8
			y: 9
		}]
		dir:        .right
		next_dir:   .right
		score:      0
		high_score: 0
		game_over:  false
		is_paused:  false
	}
	game.spawn_food()
	return game
}

fn (mut g SnakeGame) spawn_food() {
	for {
		fx := rand.intn(grid_cols) or { 5 }
		fy := rand.intn(grid_rows) or { 5 }

		mut is_occupied := false
		for p in g.body {
			if p.x == fx && p.y == fy {
				is_occupied = true
				break
			}
		}
		if !is_occupied {
			g.food = Point{
				x: fx
				y: fy
			}
			break
		}
	}

	// 20% chance to spawn a golden apple
	if rand.intn(10) or { 0 } < 2 {
		for {
			gx := rand.intn(grid_cols) or { 8 }
			gy := rand.intn(grid_rows) or { 8 }
			if gx != g.food.x || gy != g.food.y {
				g.gold_food = Point{
					x: gx
					y: gy
				}
				g.has_gold = true
				break
			}
		}
	} else {
		g.has_gold = false
	}
}

fn (mut g SnakeGame) set_direction(new_d Direction) {
	if g.game_over || g.is_paused {
		return
	}
	if (g.dir == .up && new_d == .down) || (g.dir == .down && new_d == .up) {
		return
	}
	if (g.dir == .left && new_d == .right) || (g.dir == .right && new_d == .left) {
		return
	}
	g.next_dir = new_d
}

fn (mut g SnakeGame) step() (bool, bool) { // returns (ate_regular_food, ate_gold_food)
	if g.game_over || g.is_paused {
		return false, false
	}

	g.dir = g.next_dir
	head := g.body[0]

	mut new_head := Point{
		x: head.x
		y: head.y
	}
	match g.dir {
		.up { new_head.y-- }
		.down { new_head.y++ }
		.left { new_head.x-- }
		.right { new_head.x++ }
	}

	// Wall Collision check
	if new_head.x < 0 || new_head.x >= grid_cols || new_head.y < 0 || new_head.y >= grid_rows {
		g.game_over = true
		return false, false
	}

	// Self Collision check
	for p in g.body {
		if p.x == new_head.x && p.y == new_head.y {
			g.game_over = true
			return false, false
		}
	}

	// Insert new head
	g.body.insert(0, new_head)

	mut ate_reg := false
	mut ate_gold := false

	// Check Regular Food Collision
	if new_head.x == g.food.x && new_head.y == g.food.y {
		g.score += 10
		if g.score > g.high_score {
			g.high_score = g.score
		}
		g.spawn_food()
		ate_reg = true
	} else if g.has_gold && new_head.x == g.gold_food.x && new_head.y == g.gold_food.y {
		g.score += 50
		if g.score > g.high_score {
			g.high_score = g.score
		}
		g.has_gold = false
		ate_gold = true
	} else {
		// Pop tail if no food eaten
		g.body.pop()
	}

	return ate_reg, ate_gold
}

fn (mut g SnakeGame) reset() {
	g.body = [Point{
		x: 10
		y: 9
	}, Point{
		x: 9
		y: 9
	}, Point{
		x: 8
		y: 9
	}]
	g.dir = .right
	g.next_dir = .right
	g.score = 0
	g.game_over = false
	g.is_paused = false
	g.spawn_food()
}
