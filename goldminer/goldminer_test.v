module main

fn test_goldminer_initialization() {
	mut g := new_gold_miner_game()
	assert g.state == .mining
	assert g.money == 0
	assert g.target_money == 600
	assert g.items.len > 0
	assert g.claw.state == .swinging
	assert g.dynamite_count == 1
}

fn test_claw_launch_and_extend() {
	mut g := new_gold_miner_game()
	assert g.claw.state == .swinging
	launched := g.launch_claw()
	assert launched == true
	assert g.claw.state == .extending

	// Second launch attempt while extending should fail
	assert g.launch_claw() == false
}

fn test_dynamite_destruction() {
	mut g := new_gold_miner_game()
	// Hook an item
	g.claw.state = .retracting
	g.claw.hooked_item = 0
	assert g.dynamite_count == 1

	used := g.use_dynamite()
	assert used == true
	assert g.dynamite_count == 0
	assert g.claw.hooked_item == -1
	assert g.items[0].active == false
}

fn test_level_win_and_money_quota() {
	mut g := new_gold_miner_game()
	g.target_money = 500
	g.money = 650
	g.time_left = 0.001

	ev := g.update(0.01)
	assert ev.won_level == true
	assert g.state == .won_level
}
