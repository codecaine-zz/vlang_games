module main

fn test_asteroids_initialization() {
	game := new_asteroids_game()
	assert game.lives == 3
	assert game.score == 0
	assert game.game_over == false
	assert game.asteroids.len > 0
}

fn test_ship_movement_and_thrust() {
	mut game := new_asteroids_game()
	start_x := game.ship.x
	// Step with thrust input
	game.step(0.1, 0.0, true, false, false, false)
	assert game.ship.dx != 0.0 || game.ship.x != start_x
}

fn test_bullet_firing() {
	mut game := new_asteroids_game()
	initial_bullets := game.bullets.len
	game.step(0.1, 0.0, false, true, false, false)
	assert game.bullets.len > initial_bullets
}

fn test_hyperspace() {
	mut game := new_asteroids_game()
	old_x := game.ship.x
	old_y := game.ship.y
	game.trigger_hyperspace()
	assert game.ship.x != old_x || game.ship.y != old_y
	assert game.ship.invuln_timer > 0.0
}

fn test_shield_activation() {
	mut game := new_asteroids_game()
	assert game.ship.shield_active == false
	game.activate_shield()
	assert game.ship.shield_active == true
	assert game.ship.shield_hits == 3
}

fn test_powerup_application() {
	mut game := new_asteroids_game()
	game.apply_powerup(.spread_shot)
	assert game.ship.has_powerup == true
	assert game.ship.active_powerup == .spread_shot
	assert game.ship.powerup_timer == 10.0
}

fn test_asteroid_splitting() {
	mut game := new_asteroids_game()
	game.asteroids.clear()
	game.spawn_asteroid(400.0, 300.0, 0.0, 0.0, .large)
	game.bullets << Bullet{
		x:  400.0
		y:  300.0
		dx: 0.0
		dy: 0.0
	}
	game.step(0.01, 0.0, false, false, false, false)
	// Large asteroid should split into 2 medium asteroids
	assert game.asteroids.len == 2
	assert game.asteroids[0].size == .medium
	assert game.score == 20
}
