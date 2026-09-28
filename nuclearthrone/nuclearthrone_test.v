module main

fn test_new_nuclear_throne_game() {
	mut game := new_nuclear_throne_game()
	assert game.stage == 1
	assert game.substage == 1
	assert game.player.hp == 8
	assert game.player.max_hp == 8
	assert game.enemies.len > 0
}

fn test_player_shooting() {
	mut game := new_nuclear_throne_game()
	game.player.shoot_cooldown = 0
	game.player.ammo = 100
	initial_bullets := game.bullets.len

	game.fire_player_weapon()

	assert game.bullets.len > initial_bullets
	assert game.player.ammo == 99
}

fn test_level_up_and_mutation() {
	mut game := new_nuclear_throne_game()
	game.player.rads = 35
	game.level_up()

	assert game.mutation_screen
	assert game.available_mutations.len == 5

	game.select_mutation(1) // Rhino Skin (+2 Max HP)
	assert !game.mutation_screen
	assert game.player.max_hp == 10
}
