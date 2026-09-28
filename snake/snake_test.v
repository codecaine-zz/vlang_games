module main

fn test_snake_movement() {
	mut game := new_snake_game()
	start_len := game.body.len
	start_head := game.body[0]

	game.step()
	assert game.body.len == start_len
	assert game.body[0].x == start_head.x + 1
	assert game.body[0].y == start_head.y
}

fn test_snake_wall_collision() {
	mut game := new_snake_game()
	// Drive head to left wall
	game.set_direction(.left)
	for _ in 0 .. 15 {
		game.step()
	}
	assert game.game_over == true
}

fn test_snake_food_growth() {
	mut game := new_snake_game()
	start_len := game.body.len

	// Place food right in front of snake
	head := game.body[0]
	game.food = Point{
		x: head.x + 1
		y: head.y
	}
	game.has_gold = false

	ate_reg, _ := game.step()
	assert ate_reg == true
	assert game.body.len == start_len + 1
	assert game.score == 10
}
