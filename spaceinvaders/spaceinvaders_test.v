module main

fn test_game_initialization() {
	mut g := new_space_invaders_game()
	assert g.aliens.len == 5
	assert g.aliens[0].len == 11
	assert g.aliens_alive == 55
	assert g.lives == 3
	assert g.score == 0
	assert g.wave == 1
	assert g.state == .playing
	assert g.shields.len == 4
	assert g.march_dir == 1

	// Check alien row types
	assert g.aliens[0][0].kind == .squid
	assert g.aliens[1][0].kind == .crab
	assert g.aliens[2][0].kind == .crab
	assert g.aliens[3][0].kind == .octopus
	assert g.aliens[4][0].kind == .octopus
}

fn test_player_firing_rule() {
	mut g := new_space_invaders_game()
	assert g.bullets.len == 0

	// First shot succeeds
	ok1 := g.fire_player_bullet()
	assert ok1 == true
	assert g.bullets.len == 1
	assert g.bullets[0].is_player == true
	assert g.bullets[0].alive == true

	// Simultaneous second shot is rejected (classic 1-shot limit)
	ok2 := g.fire_player_bullet()
	assert ok2 == false
	assert g.bullets.len == 1
}

fn test_alien_collision_and_scoring() {
	mut g := new_space_invaders_game()
	// Target the squid at (0, 0)
	target_x := g.aliens[0][0].x + 10.0
	target_y := g.aliens[0][0].y + 10.0

	g.bullets << Bullet{
		x:         target_x
		y:         target_y
		dy:        -500.0
		is_player: true
		alive:     true
	}

	ev := g.update(0.01, false, false)
	assert ev.alien_exploded == true
	assert g.aliens[0][0].alive == false
	assert g.aliens_alive == 54
	assert g.score == 30 // Squid worth 30 points
	assert g.bullets.len == 0 // Bullet destroyed
}

fn test_shield_erosion() {
	mut shield := new_bunker_shield(100.0, 500.0)
	assert shield.grid[3][3] == true

	mut g := new_space_invaders_game()
	g.shields = [shield]

	// Bullet hitting shield at block (3, 3)
	hit_x := 100.0 + 3.0 * f64(bunker_block_sz) + 2.0
	hit_y := 500.0 + 3.0 * f64(bunker_block_sz) + 2.0

	g.bullets << Bullet{
		x:         hit_x
		y:         hit_y
		dy:        200.0
		is_player: false
		alive:     true
	}

	g.update(0.01, false, false)
	assert g.shields[0].grid[3][3] == false
	assert g.bullets.len == 0
}

fn test_wave_clear() {
	mut g := new_space_invaders_game()
	// Kill 54 aliens
	for r in 0 .. 5 {
		for c in 0 .. 11 {
			if r == 0 && c == 0 {
				continue
			}
			g.aliens[r][c].alive = false
		}
	}
	g.aliens_alive = 1

	// Shoot the last remaining alien
	g.bullets << Bullet{
		x:         g.aliens[0][0].x + 10.0
		y:         g.aliens[0][0].y + 10.0
		dy:        -500.0
		is_player: true
		alive:     true
	}

	g.update(0.01, false, false)
	assert g.aliens_alive == 0
	assert g.state == .wave_clear
}
