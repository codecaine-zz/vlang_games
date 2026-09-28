module main

fn test_digdug_initialization() {
	mut g := new_digdug_game()
	assert g.lives == 3
	assert g.grid.len == grid_rows
	assert g.boulders.len == 3
	assert g.enemies.len == 3
}

fn test_digdug_movement_and_digging() {
	mut g := new_digdug_game()
	start_gx := g.player_gx
	g.move_player(1, 0)
	assert g.player_gx == start_gx + 1
	assert g.grid[g.player_gy][g.player_gx].is_dug
}

fn test_digdug_pump_inflation() {
	mut g := new_digdug_game()
	g.pump_action()
	// Enemies start away, hose fires
	assert g.pump.active
}

fn test_digdug_reset() {
	mut g := new_digdug_game()
	g.move_player(1, 0)
	g.reset_game()
	assert g.lives == 3
	assert g.score == 0
}
