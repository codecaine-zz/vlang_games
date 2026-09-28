module main

import math

fn test_player_initialization() {
	player := Player{
		x: 0.0
		y: 0.0
		z: 0.0
		target_x: 0.0
		shields: 3
		score: 0
		multiplier: 1
	}
	assert player.x == 0.0
	assert player.shields == 3
	assert player.multiplier == 1
}

fn test_aabb_3d_collision() {
	p_min_x := -0.8
	p_max_x := 0.8
	p_min_y := 0.0
	p_max_y := 0.6
	p_min_z := 9.0
	p_max_z := 11.0

	// Obstacle directly in path
	o1_min_x := -0.5
	o1_max_x := 0.5
	o1_min_y := 0.0
	o1_max_y := 1.0
	o1_min_z := 9.5
	o1_max_z := 10.5

	collide1 := (p_min_x <= o1_max_x && p_max_x >= o1_min_x) &&
	            (p_min_y <= o1_max_y && p_max_y >= o1_min_y) &&
	            (p_min_z <= o1_max_z && p_max_z >= o1_min_z)

	assert collide1 == true

	// Obstacle to the far side
	o2_min_x := 3.0
	o2_max_x := 4.0
	o2_min_y := 0.0
	o2_max_y := 1.0
	o2_min_z := 9.5
	o2_max_z := 10.5

	collide2 := (p_min_x <= o2_max_x && p_max_x >= o2_min_x) &&
	            (p_min_y <= o2_max_y && p_max_y >= o2_min_y) &&
	            (p_min_z <= o2_max_z && p_max_z >= o2_min_z)

	assert collide2 == false
}

fn test_speed_calculation() {
	base_speed := 30.0
	boost_active := true
	speed := if boost_active { base_speed * 1.8 } else { base_speed }
	assert math.abs(speed - 54.0) < 0.001
}
