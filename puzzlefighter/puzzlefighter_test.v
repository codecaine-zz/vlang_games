module main

fn test_pf_init() {
	mut pb := new_player_board(false)
	assert pb.state == .falling
	assert pb.score == 0
	assert pb.grid.len == pf_rows
	assert pb.grid[0].len == pf_cols
}

fn test_pf_rotation_and_wall_kick() {
	mut pb := new_player_board(false)
	assert pb.pair.rot == 0

	// Move against right wall (col 5)
	pb.pair.c1 = pf_cols - 1
	// Rotate clockwise to rot 1 (sub right) -> should kick left so c1 becomes col 4
	pb.rotate(1)
	assert pb.pair.rot == 1
	assert pb.pair.c1 == pf_cols - 2
	assert pb.pair.c2 == pf_cols - 1
}

fn test_pf_power_fusion() {
	mut pb := new_player_board(false)
	// Place a 2x2 square of Red gems (color 1)
	pb.grid[10][0] = GemCell{color: 1, nature: .normal}
	pb.grid[10][1] = GemCell{color: 1, nature: .normal}
	pb.grid[11][0] = GemCell{color: 1, nature: .normal}
	pb.grid[11][1] = GemCell{color: 1, nature: .normal}

	pb.detect_power_fusions()
	assert pb.grid[10][0].power_id > 0
	assert pb.grid[10][1].power_id == pb.grid[10][0].power_id
	assert pb.grid[11][0].power_id == pb.grid[10][0].power_id
	assert pb.grid[11][1].power_id == pb.grid[10][0].power_id
}

fn test_pf_crash_orb_detonation() {
	mut pb := new_player_board(false)
	// Place 3 Blue normal gems + 1 Blue Crash Orb
	pb.grid[11][0] = GemCell{color: 2, nature: .normal}
	pb.grid[11][1] = GemCell{color: 2, nature: .normal}
	pb.grid[10][0] = GemCell{color: 2, nature: .normal}
	pb.grid[10][1] = GemCell{color: 2, nature: .crash_orb}

	count := pb.check_crash_detonations()
	assert count == 4
	assert pb.state == .clearing
	assert pb.clearing_cells.len == 4
}

fn test_pf_counter_gem_countdown() {
	mut pb := new_player_board(false)
	pb.grid[11][0] = GemCell{color: 3, nature: .counter, timer: 1}
	pb.pair.c1 = 4
	pb.pair.c2 = 4
	pb.lock_pair()

	// Timer was 1, so after lock it should become 0 and convert to normal
	assert pb.grid[11][0].nature == .normal
}
