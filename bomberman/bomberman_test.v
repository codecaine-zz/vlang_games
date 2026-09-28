module main

fn test_bomberman_initialization() {
	mut g := new_bomberman_game()
	assert g.players.len == 2
	assert g.grid.len == grid_rows
	assert g.grid[0].len == grid_cols
	assert g.grid[0][0] == .hard_wall
	assert g.grid[1][1] == .empty
}

fn test_bomberman_drop_bomb() {
	mut g := new_bomberman_game()
	g.drop_bomb(0)
	assert g.bombs.len == 1
	assert g.bombs[0].owner_id == 1
}

fn test_bomberman_detonation() {
	mut g := new_bomberman_game()
	g.drop_bomb(0)
	g.update(2.25)
	assert g.flames.len > 0
}

fn test_bomberman_reset() {
	mut g := new_bomberman_game()
	g.drop_bomb(0)
	g.reset_game()
	assert g.bombs.len == 0
	assert g.flames.len == 0
	assert g.players[0].active
}

fn test_player_grid_fit_and_movement() {
	mut g := new_bomberman_game()
	// Player centered in tile 1,1
	p_x := f32(grid_offset_x + 1 * tile_size + 20)
	p_y := f32(grid_offset_y + 1 * tile_size + 20)
	assert g.can_move_to(p_x, p_y)
	// Try moving into hard wall (tile 0,0) -> should be blocked
	wall_x := f32(grid_offset_x + 10)
	wall_y := f32(grid_offset_y + 10)
	assert !g.can_move_to(wall_x, wall_y)
}

fn test_bomb_blocking() {
	mut g := new_bomberman_game()
	// Player 1 drops bomb at (1,1)
	g.drop_bomb(0)
	assert g.bombs.len == 1
	// Player is inside (1,1), so can_move_to_with_bomb from (1,1) is true
	p1_x := g.players[0].x
	p1_y := g.players[0].y
	assert g.can_move_to_with_bomb(p1_x, p1_y, p1_x, p1_y)
	// From tile (1,2), moving back into bomb at (1,1) should be blocked
	p_adj_x := f32(grid_offset_x + 1 * tile_size + 20)
	p_adj_y := f32(grid_offset_y + 2 * tile_size + 20)
	assert !g.can_move_to_with_bomb(p1_x, p1_y, p_adj_x, p_adj_y)
}

fn test_wall_destruction() {
	mut g := new_bomberman_game()
	// Force a soft block at tile (1,2)
	g.grid[2][1] = .soft_block
	g.drop_bomb(0) // bomb at (1,1)
	g.update(2.25) // detonate bomb
	assert g.grid[2][1] == .empty
}

fn test_key_bomb_dropping() {
	mut g := new_bomberman_game()
	assert g.players[0].bomb_count == 0
	g.key_p1_bomb = true
	g.update(0.016)
	assert g.players[0].bomb_count == 1
	p1_bombs := g.bombs.filter(it.owner_id == 1)
	assert p1_bombs.len == 1
}

fn test_grid_step_movement() {
	mut g := new_bomberman_game()
	g.grid[1][2] = .empty
	assert g.players[0].target_gx == 1
	assert g.players[0].target_gy == 1

	g.key_p1_right = true
	g.update(0.016)
	assert g.players[0].target_gx == 2
	assert g.players[0].is_moving == true

	// Release key so player stops at target tile
	g.key_p1_right = false
	g.update(0.3)
	assert g.players[0].is_moving == false
	expected_x := f32(grid_offset_x + 2 * tile_size + 20)
	assert g.players[0].x == expected_x
}

fn test_ai_danger_detection_and_flee() {
	mut g := new_bomberman_game()
	// Clear area around AI
	ai_gx := g.players[1].target_gx
	ai_gy := g.players[1].target_gy

	// Check initially not in danger
	assert !g.is_tile_in_danger(ai_gx, ai_gy)

	// Place bomb in AI's path
	g.bombs << Bomb{
		grid_x: ai_gx
		grid_y: ai_gy
		owner_id: 2
		fuse_timer: 2.0
		radius: 2
		active: true
	}

	// Now AI's tile is in danger!
	assert g.is_tile_in_danger(ai_gx, ai_gy)

	// In danger, AI should select a safe neighbor tile to escape
	g.update_ai_player(1, 0.016)
	assert g.players[1].is_moving == true
	assert g.players[1].target_gx != ai_gx || g.players[1].target_gy != ai_gy
}
