module main

fn test_shinobi_initialization() {
	mut g := new_shinobi_game()
	assert g.lives == 3
	assert g.platforms.len == 3
	assert g.player_x == 150.0
	assert g.is_grounded
}

fn test_shinobi_double_jump() {
	mut g := new_shinobi_game()
	g.jump()
	assert !g.is_grounded
	assert g.player_vy < 0.0

	// Second jump in air
	g.jump()
	assert !g.double_jump_ready
}

fn test_shinobi_shuriken_throw() {
	mut g := new_shinobi_game()
	g.throw_shuriken()
	assert g.shurikens.len == 1
	g.update(0.1)
	assert g.shurikens[0].x > 166.0
}

fn test_shinobi_reset() {
	mut g := new_shinobi_game()
	g.jump()
	g.reset_game()
	assert g.lives == 3
	assert g.player_x == 150.0
	assert g.is_grounded
}
