module main

fn test_frogger_initialization() {
	mut g := new_frogger_game()
	assert g.lives == 3
	assert g.docks.len == 5
	assert g.frog_row == 12
	assert g.objects.len > 0
}

fn test_frogger_hop() {
	mut g := new_frogger_game()
	initial_row := g.frog_row
	g.hop(0, -1)
	assert g.frog_row == initial_row - 1
}

fn test_frogger_docking() {
	mut g := new_frogger_game()
	g.frog_row = 0
	g.frog_x = 80.0 // Aligns with first dock
	g.update(0.01)
	assert g.docks[0].filled
	assert g.score >= 500
}

fn test_frogger_reset() {
	mut g := new_frogger_game()
	g.hop(0, -1)
	g.reset_game()
	assert g.frog_row == 12
	assert g.score == 0
	assert g.lives == 3
}
