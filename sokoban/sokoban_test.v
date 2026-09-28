module main

fn test_sokoban_level_loading() {
	mut g := new_sokoban_game()
	assert g.current_level == 0
	assert g.rows == 7
	assert g.total_targets == 2
	assert g.targets_filled == 0
	assert g.level_cleared == false
	assert g.steps == 0
	assert g.pushes == 0
}

fn test_player_wall_collision() {
	// Create simple 5x5 test arena:
	// #####
	// # @ #
	// #   #
	// #####
	lines := [
		'#####',
		'# @ #',
		'#   #',
		'#####',
	]
	mut g := SokobanGame{}
	g.load_from_lines(lines)
	assert g.player_r == 1
	assert g.player_c == 2

	// Try move up into wall (#) -> should fail
	moved_up, _, _ := g.try_move(-1, 0)
	assert moved_up == false
	assert g.player_r == 1
	assert g.player_c == 2
	assert g.steps == 0

	// Move down into empty floor -> should succeed
	moved_down, _, _ := g.try_move(1, 0)
	assert moved_down == true
	assert g.player_r == 2
	assert g.player_c == 2
	assert g.steps == 1
}

fn test_crate_pushing_and_undo() {
	// Simple test map:
	// ######
	// #@ $ #
	// ######
	lines := [
		'######',
		'#@ $ #',
		'######',
	]
	mut g := SokobanGame{}
	g.load_from_lines(lines)
	assert g.player_r == 1
	assert g.player_c == 1

	// Move right: steps to (1,2)
	m1, _, _ := g.try_move(0, 1)
	assert m1 == true
	assert g.player_c == 2

	// Push crate at (1,3) to (1,4)
	m2, pushed, _ := g.try_move(0, 1)
	assert m2 == true
	assert pushed == true
	assert g.player_c == 3
	assert g.grid[1][4] == .crate
	assert g.pushes == 1

	// Try push crate at (1,4) into wall at (1,5) -> blocked!
	m3, _, _ := g.try_move(0, 1)
	assert m3 == false
	assert g.player_c == 3
	assert g.grid[1][4] == .crate

	// Undo the push move
	u1 := g.undo()
	assert u1 == true
	assert g.player_c == 2
	assert g.grid[1][3] == .crate
	assert g.grid[1][4] == .floor
	assert g.pushes == 0
	assert g.steps == 1
}

fn test_sokoban_win_condition() {
	// 1 crate and 1 target in line
	// #####
	// #@$.#
	// #####
	lines := [
		'#####',
		'#@$.#',
		'#####',
	]
	mut g := SokobanGame{}
	g.load_from_lines(lines)
	assert g.total_targets == 1
	assert g.targets_filled == 0
	assert g.level_cleared == false

	// Push crate onto target
	moved, pushed, hit_target := g.try_move(0, 1)
	assert moved == true
	assert pushed == true
	assert hit_target == true
	assert g.grid[1][3] == .crate_on_target
	assert g.targets_filled == 1
	assert g.level_cleared == true
}
