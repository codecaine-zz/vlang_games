module main

fn test_arcade_init() {
	arcade := new_arcade_manager()
	assert arcade.screen == .menu
	assert arcade.buttons.len == 4
}

fn test_gem_rush_init() {
	game := new_gem_rush_game()
	assert game.gems == 0.0
	assert game.buildings.len > 0
}

fn test_chain_reaction_init() {
	game := new_chain_reaction_game()
	assert game.level == 1
}

fn test_whack_monster_init() {
	game := new_whack_monster_game()
	assert game.holes.len == 9
}

fn test_blade_slicer_init() {
	game := new_blade_slicer_game()
	assert game.lives == 3
}
