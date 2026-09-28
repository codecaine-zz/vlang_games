module main

fn test_cube_indexing() {
	assert get_cube_index(0, 0) == 0
	assert get_cube_index(1, 0) == 1
	assert get_cube_index(1, 1) == 2
	assert get_cube_index(6, 6) == 27
	assert get_cube_index(7, 0) == -1 // off pyramid
	assert get_cube_index(2, 3) == -1 // off pyramid
}

fn test_valid_hop_and_cube_flip() {
	mut g := new_qbert_game()
	assert g.player.r == 0
	assert g.player.c == 0
	assert g.cubes[0] == 1 // apex visited

	// Hop Down-Right to (1, 1)
	valid, disc := g.try_hop(.down_right)
	assert valid == true
	assert disc == false
	assert g.player.r == 1
	assert g.player.c == 1

	idx := get_cube_index(1, 1)
	assert g.cubes[idx] == 1
	assert g.score == 25
}

fn test_escape_disc() {
	mut g := new_qbert_game()
	// Place player adjacent to left escape disc at (2, 0)
	g.player.r = 2
	g.player.c = 0

	// Hop Up-Left into left disc at (2, -1)
	valid, disc := g.try_hop(.up_left)
	assert valid == true
	assert disc == true
	assert g.player.r == 0
	assert g.player.c == 0
	assert g.discs[0].active == false
}

fn test_pyramid_completion() {
	mut g := new_qbert_game()
	// Set all cubes to target except last one
	for i in 0 .. total_cubes - 1 {
		g.cubes[i] = 1
	}
	g.player.r = 5
	g.player.c = 5

	// Hop to last cube at (6, 6)
	g.try_hop(.down_right)
	assert g.state == .level_cleared
	assert g.score >= 1000
}

fn test_qbert_shake_trauma() {
	mut g := new_qbert_game()
	assert g.shake_trauma == 0.0
	// Jump off the pyramid (up-left from 0, 0 is off bounds)
	g.try_hop(.up_left)
	assert g.state == .cursing
	assert g.shake_trauma >= 0.50
	g.update(0.1)
	assert g.shake_trauma < 0.50
}
