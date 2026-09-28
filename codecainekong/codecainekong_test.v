module main

fn test_donkeykong_initialization() {
	mut g := new_donkeykong_game()
	assert g.lives == 3
	assert g.girders.len == 6
	assert g.ladders.len == 5
	assert g.player_x == 100.0
}

fn test_donkeykong_movement() {
	mut g := new_donkeykong_game()
	g.key_right = true
	g.update(0.1)
	assert g.player_x > 100.0
}

fn test_donkeykong_jump() {
	mut g := new_donkeykong_game()
	start_y := g.player_y
	g.key_jump = true
	g.update(0.02)
	g.key_jump = false
	assert !g.is_grounded
	
	// Simulate full jump peak without taking a ladder
	for _ in 0 .. 50 {
		g.update(0.02)
	}
	// Verify jump height peak is modest (~32px max) and lands back on Tier 1 ground (around start_y)
	assert g.player_y >= start_y - 40.0
	assert g.is_grounded
}

fn test_donkeykong_enemies_and_hammers() {
	mut g := new_donkeykong_game()
	assert g.hammers.len == 2
	
	// Pickup hammer
	g.player_x = g.hammers[0].x
	g.player_y = g.hammers[0].y
	g.update(0.01)
	assert g.hammer_timer > 0

	// Fireball & Barrel interaction
	g.fireballs << Fireball{
		x: g.player_x
		y: g.player_y
		active: true
	}
	g.update(0.01)
	assert g.fireballs.len == 0 || !g.fireballs[0].active
	assert g.score >= 500
}

fn test_donkeykong_barrel_falling() {
	mut g := new_donkeykong_game()
	// Clear automatically spawned barrels for isolated test
	g.barrels.clear()
	g.barrels << Barrel{
		x: 160.0
		y: 126.0
		vx: 140.0
		vy: 0.0
		active: true
	}
	initial_y := g.barrels[0].y

	// Simulate barrel movement over 3 seconds (rolls right off Tier 5 edge and drops to Tier 4)
	for _ in 0 .. 150 {
		g.update(0.02)
	}

	assert g.barrels.len > 0
	// Verify barrel dropped down vertically to a lower girder tier (y > initial_y)
	assert g.barrels[0].y > initial_y + 50.0
}

fn test_donkeykong_barrel_full_descent() {
	mut g := new_donkeykong_game()
	g.barrels.clear()
	g.barrels << Barrel{
		x: 160.0
		y: 126.0
		vx: 140.0
		vy: 0.0
		b_type: .blue
		active: true
	}

	// Simulate barrel movement over 15 seconds
	for _ in 0 .. 750 {
		g.update(0.02)
	}

	// Verify barrel completed full descent and spawned a fireball at the Oil Drum
	assert g.fireballs.len > 0
}

fn test_donkeykong_barrel_ladder_climb() {
	mut g := new_donkeykong_game()
	g.barrels.clear()
	// Place a barrel right over Ladder 3 (x=660, top_y=222, bot_y=338)
	g.barrels << Barrel{
		x: 660.0
		y: 208.0
		vx: 0.0
		vy: 160.0
		is_climbing: true
		active: true
	}

	// Update over 1 second
	for _ in 0 .. 50 {
		g.update(0.02)
	}

	// Verify barrel climbed down to near bot_y (338.0) and stepped off
	assert g.barrels[0].y > 300.0
}

fn test_donkeykong_reset() {
	mut g := new_donkeykong_game()
	g.key_right = true
	g.update(0.1)
	g.reset_game()
	assert g.player_x == 100.0
	assert g.lives == 3
	assert g.score == 0
}


