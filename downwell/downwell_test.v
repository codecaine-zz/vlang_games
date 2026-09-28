module main

fn test_new_downwell_game() {
	mut game := new_downwell_game()
	assert game.stage == 1
	assert game.player.hp == 4
	assert game.player.max_hp == 4
	assert game.player.ammo == 8
	assert game.grid.len > 0
}

fn test_gunboots_shooting() {
	mut game := new_downwell_game()
	game.player.is_grounded = false
	game.player.can_shoot = true
	game.player.shoot_cooldown = 0

	initial_ammo := game.player.ammo
	game.fire_gunboots()

	assert game.player.ammo == initial_ammo - 1
	assert game.bullets.len > 0
	assert game.screen_shake > 0
}

fn test_shop_purchases() {
	mut game := new_downwell_game()
	game.player.gems = 100
	game.open_shop()
	assert game.shop_active
	assert game.shop_items.len >= 4

	game.buy_shop_item(0) // Health refill / +1 HP
	assert game.shop_items[0].bought
	assert game.player.gems == 85
}
