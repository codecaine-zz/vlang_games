module main

fn test_game_initialization() {
	mut game := new_mario_bros_game()
	assert game.state == .title
	assert game.platforms.len >= 5
	assert game.high_score >= 20000

	game.start_game(.single_player)
	assert game.state == .playing
	assert game.players.len == 1
	assert game.players[0].id == 1
	assert game.players[0].lives == 3
	assert game.pow_block.hits_left == 3
	assert game.pow_block.active == true
}

fn test_two_player_mode() {
	mut game := new_mario_bros_game()
	game.start_game(.two_players)
	assert game.state == .playing
	assert game.players.len == 2
	assert game.players[0].id == 1
	assert game.players[1].id == 2
	assert game.players[0].lives == 3
	assert game.players[1].lives == 3
}

fn test_platform_bump_and_shellcreeper_flip() {
	mut game := new_mario_bros_game()
	game.start_game(.single_player)
	game.enemies_left = 0
	game.enemies.clear()

	// Spawn a shellcreeper on Tier 2 platform (Y=290, top at 262)
	mut turtle := Enemy{
		id:          10
		enemy_type:  .shellcreeper
		state:       .walking
		x:           300.0
		y:           262.0
		vx:          100.0
		vy:          0.0
		is_grounded: true
		active:      true
	}
	game.enemies << turtle

	// Trigger a bump wave right underneath the turtle at (300, 290)
	game.trigger_bump_wave(300.0, 290.0)

	assert game.enemies[0].state == .stunned
	assert game.enemies[0].stun_timer > 5.0
	assert game.enemies[0].vy < 0.0 // Bounced upward
}

fn test_sidestepper_two_hits() {
	mut game := new_mario_bros_game()
	game.start_game(.single_player)
	game.enemies_left = 0
	game.enemies.clear()

	// Crab on platform
	mut crab := Enemy{
		id:          11
		enemy_type:  .sidestepper
		state:       .walking
		x:           300.0
		y:           262.0
		vx:          100.0
		vy:          0.0
		is_grounded: true
		active:      true
	}
	game.enemies << crab

	// 1st hit -> Enrages the crab (turns red / angry, doubles speed)
	game.trigger_bump_wave(300.0, 290.0)
	assert game.enemies[0].state == .angry
	assert game.enemies[0].angry_level == 1

	// 2nd hit while angry -> Flips crab onto its back!
	game.enemies[0].is_grounded = true
	game.enemies[0].y = 262.0
	game.trigger_bump_wave(300.0, 290.0)
	assert game.enemies[0].state == .stunned
	assert game.enemies[0].stun_timer > 4.0
}

fn test_pow_block_mechanics() {
	mut game := new_mario_bros_game()
	game.start_game(.single_player)
	game.enemies_left = 0
	game.enemies.clear()

	// Add 2 grounded enemies across the stage
	game.enemies << Enemy{
		id:          1
		enemy_type:  .shellcreeper
		state:       .walking
		x:           200.0
		y:           132.0
		is_grounded: true
		active:      true
	}
	game.enemies << Enemy{
		id:          2
		enemy_type:  .fighterfly
		state:       .walking
		x:           400.0
		y:           262.0
		is_grounded: true
		active:      true
	}

	assert game.pow_block.hits_left == 3
	game.hit_pow_block()

	assert game.pow_block.hits_left == 2
	assert game.screen_shake > 0.0
	assert game.enemies[0].state == .stunned
	assert game.enemies[1].state == .stunned

	// Exhaust POW block
	game.hit_pow_block()
	assert game.pow_block.hits_left == 1
	game.hit_pow_block()
	assert game.pow_block.hits_left == 0
	assert game.pow_block.active == false
}

fn test_enemy_kick_and_sliding_shell() {
	mut game := new_mario_bros_game()
	game.start_game(.single_player)
	game.enemies_left = 1
	game.enemies.clear()
	game.players[0].x = 300.0
	game.players[0].y = 504.0
	game.players[0].score = 0

	// Flipped turtle in front of Mario
	game.enemies << Enemy{
		id:          1
		enemy_type:  .shellcreeper
		state:       .stunned
		stun_timer:  6.0
		x:           310.0
		y:           504.0
		is_grounded: true
		active:      true
	}

	// Update game step to trigger kick
	game.update(0.016)

	// Kicking turtle should spawn a Sliding Shell bowling attack!
	assert game.sliding_shells.len == 1
	assert game.sliding_shells[0].vx > 0.0
	assert game.players[0].score == 800
	assert game.players[0].combo_count == 1
}

fn test_screen_wrap_around() {
	mut game := new_mario_bros_game()
	game.start_game(.single_player)
	game.enemies_left = 1
	// Add active enemy so game remains in playing state
	game.enemies << Enemy{
		id:     99
		active: true
	}

	// Move player past left screen edge
	game.players[0].x = -35.0
	game.players[0].vx = -100.0
	game.update(0.016)
	assert game.players[0].x >= 750.0

	// Move player past right screen edge
	game.players[0].x = 805.0
	game.players[0].vx = 100.0
	game.update(0.016)
	assert game.players[0].x <= 0.0
}

fn test_super_spring_jump() {
	mut game := new_mario_bros_game()
	game.start_game(.single_player)
	game.players[0].is_grounded = true
	game.p1_down = true

	// Charge for 0.4s
	game.update(0.4)
	assert game.players[0].is_charged == true

	// Release jump while charged
	game.p1_jump = true
	game.update(0.016)
	assert game.players[0].vy < -550.0 // Super Jump launch velocity!
	assert game.players[0].is_grounded == false
}

fn test_star_power_invincibility() {
	mut game := new_mario_bros_game()
	game.start_game(.single_player)
	game.players[0].x = 300.0
	game.players[0].y = 504.0
	game.players[0].star_timer = 8.0 // Star power active

	// Active upright walking crab
	game.enemies << Enemy{
		id:          1
		enemy_type:  .sidestepper
		state:       .walking
		x:           310.0
		y:           504.0
		is_grounded: true
		active:      true
	}

	game.update(0.016)
	// Player remains alive and enemy is defeated instantly on touch!
	assert game.players[0].is_dead == false
	assert game.enemies[0].state == .kicked
	assert game.players[0].score == 1000
}

fn test_fireball_throwing() {
	mut game := new_mario_bros_game()
	game.start_game(.single_player)
	game.players[0].has_fire = true
	game.p1_fire = true

	game.update(0.016)
	assert game.player_fireballs.len == 1
	assert game.player_fireballs[0].vx > 0.0
}

fn test_bonus_phase_coin_collection() {
	mut game := new_mario_bros_game()
	game.setup_phase(3)
	assert game.state == .bonus_phase
	assert game.coins.len == 10

	// Collect coin
	game.players << Player{
		id:    1
		x:     game.coins[0].x
		y:     game.coins[0].y
		lives: 3
	}
	initial_coins := game.coins.len
	game.update(0.016)
	assert game.players[0].score == 800
	assert game.coins.len == initial_coins - 1
}

fn test_sound_manager_toggle() {
	mut sm := new_sound_manager()
	initial := sm.sound_enabled
	toggled := sm.toggle_sound()
	assert toggled != initial
	assert sm.toggle_sound() == initial
}

fn test_enemy_bounce_off_upside_down() {
	mut game := new_mario_bros_game()
	game.start_game(.single_player)
	game.enemies_left = 1
	game.enemies.clear()

	// Enemy 1: Upside-down (stunned) at x=300
	game.enemies << Enemy{
		id:          1
		enemy_type:  .shellcreeper
		state:       .stunned
		stun_timer:  5.0
		x:           300.0
		y:           262.0
		vx:          0.0
		vy:          0.0
		is_grounded: true
		active:      true
	}

	// Enemy 2: Walking right toward Enemy 1 at x=280
	game.enemies << Enemy{
		id:           2
		enemy_type:   .shellcreeper
		state:        .walking
		x:            280.0
		y:            262.0
		vx:           100.0
		vy:           0.0
		facing_right: true
		is_grounded:  true
		active:       true
	}

	// Step game to trigger collision
	game.update(0.016)

	// Enemy 2 should have bounced off Enemy 1, now facing left with negative vx
	assert game.enemies[1].facing_right == false
	assert game.enemies[1].vx < 0.0
	assert game.enemies[1].x <= 300.0 - game.enemies[1].width
}

fn test_enemy_head_on_collision() {
	mut game := new_mario_bros_game()
	game.start_game(.single_player)
	game.enemies_left = 1
	game.enemies.clear()

	// Enemy 1: Walking right at x=280
	game.enemies << Enemy{
		id:           1
		enemy_type:   .shellcreeper
		state:        .walking
		x:            280.0
		y:            262.0
		vx:           100.0
		vy:           0.0
		facing_right: true
		is_grounded:  true
		active:       true
	}

	// Enemy 2: Walking left at x=295
	game.enemies << Enemy{
		id:           2
		enemy_type:   .fighterfly
		state:        .walking
		x:            295.0
		y:            262.0
		vx:           -100.0
		vy:           0.0
		facing_right: false
		is_grounded:  true
		active:       true
	}

	// Step game to trigger collision
	game.update(0.016)

	// Both should have reversed directions
	assert game.enemies[0].facing_right == false
	assert game.enemies[0].vx < 0.0
	assert game.enemies[1].facing_right == true
	assert game.enemies[1].vx > 0.0
}

fn test_enemy_running_momentum_bump() {
	mut game := new_mario_bros_game()
	game.start_game(.single_player)
	game.enemies_left = 1
	game.enemies.clear()

	// Enemy running right at x=300 with vx=120
	game.enemies << Enemy{
		id:           1
		enemy_type:   .shellcreeper
		state:        .walking
		x:            300.0
		y:            262.0
		vx:           120.0
		vy:           0.0
		facing_right: true
		is_grounded:  true
		active:       true
	}

	// Bump platform underneath running enemy
	game.hit_enemy_from_below(mut game.enemies[0])

	// Should flip to stunned, bound upward, and preserve forward momentum!
	assert game.enemies[0].state == .stunned
	assert game.enemies[0].vy < -200.0
	assert game.enemies[0].vx > 100.0
	assert game.enemies[0].is_grounded == false
}

fn test_active_enemy_hurts_player() {
	mut game := new_mario_bros_game()
	game.start_game(.single_player)
	game.players[0].invuln_timer = 0.0
	game.players[0].star_timer = 0.0
	game.players[0].x = 300.0
	game.players[0].y = 504.0
	game.players[0].lives = 3
	game.enemies.clear()

	// Spawn active walking enemy directly on player
	game.spawn_enemy()
	game.enemies[0].x = 300.0
	game.enemies[0].y = 504.0
	game.enemies[0].active = true

	// Step game to trigger collision
	game.update(0.016)

	// Player MUST take damage, lose a life, and enter dead state!
	assert game.players[0].is_dead == true
	assert game.players[0].lives == 2
	assert game.players[0].dead_timer > 0.0
}

fn test_hit_stunned_shellcreeper_flips_back_upright_and_dangerous() {
	mut game := new_mario_bros_game()
	game.start_game(.single_player)
	game.enemies_left = 1
	game.enemies.clear()

	// Spawn a stunned (turned over on back) turtle on platform
	game.enemies << Enemy{
		id:          1
		enemy_type:  .shellcreeper
		state:       .stunned
		stun_timer:  5.0
		x:           300.0
		y:           262.0
		vx:          0.0
		vy:          0.0
		facing_right: true
		is_grounded: true
		active:      true
	}

	// Bump platform right below the turned over turtle
	game.trigger_bump_wave(300.0, 290.0)

	// Shellcreeper should flip back upright, be walking, active and dangerous!
	assert game.enemies[0].state == .walking
	assert game.enemies[0].stun_timer == 0.0
	assert game.enemies[0].vy < 0.0 // Bounced upward
	assert game.enemies[0].vx > 0.0
	assert game.enemies[0].is_grounded == false

	// If player touches it now, it should hurt the player (dangerous), not be kicked!
	game.players[0].x = 300.0
	game.players[0].y = 262.0
	game.players[0].invuln_timer = 0.0
	game.players[0].star_timer = 0.0
	game.players[0].lives = 3
	game.enemies[0].y = 262.0

	game.update(0.016)
	assert game.players[0].is_dead == true
	assert game.players[0].lives == 2
}

fn test_hit_stunned_sidestepper_flips_back_upright_and_angry() {
	mut game := new_mario_bros_game()
	game.start_game(.single_player)
	game.enemies_left = 1
	game.enemies.clear()

	// Spawn a stunned crab on platform
	game.enemies << Enemy{
		id:          2
		enemy_type:  .sidestepper
		state:       .stunned
		stun_timer:  5.0
		x:           300.0
		y:           262.0
		vx:          0.0
		vy:          0.0
		facing_right: false
		is_grounded: true
		active:      true
	}

	// Hit crab from below
	game.hit_enemy_from_below(mut game.enemies[0])

	// Crab should flip back upright, become angry/dangerous, and face left with negative vx
	assert game.enemies[0].state == .angry
	assert game.enemies[0].angry_level == 1
	assert game.enemies[0].stun_timer == 0.0
	assert game.enemies[0].vy < 0.0
	assert game.enemies[0].vx < 0.0
}

fn test_pow_flips_stunned_enemy_back_upright() {
	mut game := new_mario_bros_game()
	game.start_game(.single_player)
	game.enemies_left = 1
	game.enemies.clear()

	// Flipped fighterfly on platform
	game.enemies << Enemy{
		id:          3
		enemy_type:  .fighterfly
		state:       .stunned
		stun_timer:  5.0
		x:           400.0
		y:           262.0
		is_grounded: true
		active:      true
	}

	game.hit_pow_block()

	// Fighterfly should flip back upright and walking
	assert game.enemies[0].state == .walking
	assert game.enemies[0].stun_timer == 0.0
	assert game.enemies[0].vy < 0.0
}

fn test_ambient_drips_and_splash_effects() {
	mut game := new_mario_bros_game()
	game.start_game(.single_player)
	game.water_drips.clear()
	game.particles.clear()

	// Spawn ambient drip
	game.spawn_ambient_drip()
	assert game.water_drips.len >= 1

	// Drip hitting target_y triggers splash particles
	drip := game.water_drips[0]
	target_y := drip.target_y
	game.water_drips[0].y = target_y - 2.0
	game.water_drips[0].vy = 200.0

	game.update(0.02)
	assert game.particles.len > 0
	// Splashed particles should have negative upward vy initial velocities
	assert game.particles[0].vy < 0.0
}


