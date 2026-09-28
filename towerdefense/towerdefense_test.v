module main

fn test_towerdefense_initialization() {
	mut g := new_towerdefense_game()
	assert g.gold == 350
	assert g.lives == 10
	assert g.waypoints.len == 7
}

fn test_towerdefense_place_turret() {
	mut g := new_towerdefense_game()
	initial_gold := g.gold
	g.place_turret(2, 2, .laser) // Path is at (2,2) -> invalid
	assert g.turrets.len == 0

	g.place_turret(1, 1, .laser) // Valid grass tile
	assert g.turrets.len == 1
	assert g.gold == initial_gold - 100
}

fn test_towerdefense_creep_spawning() {
	mut g := new_towerdefense_game()
	g.update(1.2)
	assert g.creeps.len > 0
}

fn test_towerdefense_reset() {
	mut g := new_towerdefense_game()
	g.place_turret(1, 1, .laser)
	g.reset_game()
	assert g.gold == 350
	assert g.lives == 10
	assert g.turrets.len == 0
}

fn test_towerdefense_upgrade_and_sell() {
	mut g := new_towerdefense_game()
	g.place_turret(1, 1, .laser) // Costs 100 gold, leaves 250
	assert g.turrets.len == 1
	assert g.gold == 250

	// Upgrade: costs (100 * 1) / 2 = 50 gold, leaves 200
	g.upgrade_turret(1, 1)
	assert g.turrets[0].level == 2
	assert g.gold == 200

	// Sell: total value = 100 + 50 = 150. Refund 70% = 105. Gold becomes 200 + 105 = 305
	g.sell_turret(1, 1)
	assert g.turrets.len == 0
	assert g.gold == 305
}
