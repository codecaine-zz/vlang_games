module main

fn test_galaga_initialization() {
	mut g := new_galaga_game()
	assert g.score == 0
	assert g.player.lives == 3
	assert g.enemies.len > 0
	assert g.player.x == 400.0
}

fn test_galaga_player_movement() {
	mut g := new_galaga_game()
	g.key_left = true
	g.update(0.1)
	assert g.player.x < 400.0

	g.key_left = false
	g.key_right = true
	g.update(0.2)
	assert g.player.x > 360.0
}

fn test_galaga_shooting() {
	mut g := new_galaga_game()
	g.key_fire = true
	g.fire_cooldown = 0.0
	g.update(0.02)
	assert g.player_bullets.len > 0
}

fn test_galaga_scoring() {
	mut g := new_galaga_game()
	initial_score := g.score
	g.add_score(400)
	assert g.score == initial_score + 400
	assert g.high_score >= g.score
}

fn test_galaga_reset() {
	mut g := new_galaga_game()
	g.score = 1500
	g.reset_game()
	assert g.score == 0
	assert g.player.lives == 3
	assert g.stage == 1
}
