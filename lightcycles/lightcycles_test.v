module main

fn test_lightcycles_initialization() {
	mut g := new_lightcycles_game()
	assert g.p1_score == 0
	assert g.p2_score == 0
	assert g.p1.alive == true
	assert g.p2.alive == true
	assert g.p1.dir == .right
	assert g.p2.dir == .left
	assert g.state == .playing
	assert g.grid[g.p1.r][g.p1.c] == 1
	assert g.grid[g.p2.r][g.p2.c] == 2
}

fn test_direction_changes_and_reversal_prevention() {
	mut g := new_lightcycles_game()
	assert g.p1.dir == .right

	// Trying to reverse 180 degrees to .left directly should be rejected
	ok_rev := g.set_p1_dir(.left)
	assert ok_rev == false
	assert g.p1.dir == .right

	// 90 degree turn to .up should succeed
	ok_up := g.set_p1_dir(.up)
	assert ok_up == true
	assert g.p1.dir == .up
}

fn test_trail_collision_and_round_end() {
	mut g := new_lightcycles_game()
	// Place a trail right in front of P1
	target_c := g.p1.c + 1
	g.grid[g.p1.r][target_c] = 2

	// Step forward
	g.step_timer = g.step_interval
	ev := g.update(0.001)
	assert ev.crashed == true
	assert g.state == .round_over
	assert g.round_winner == 2
	assert g.p2_score == 1
}

fn test_ai_avoidance() {
	mut g := new_lightcycles_game()
	// Box in front of P2
	p2_r := g.p2.r
	p2_c := g.p2.c
	g.grid[p2_r][p2_c - 1] = 1 // Wall directly to left

	ai_dir := compute_ai_move(g.grid, p2_r, p2_c, .left, .master)
	// AI must pick either up or down, never left into the obstacle
	assert ai_dir == .up || ai_dir == .down
}
