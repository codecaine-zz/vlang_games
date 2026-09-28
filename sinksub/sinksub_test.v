module main

fn test_sinksub_initialization() {
	game := new_game_engine()
	assert game.score == 0
	assert game.credits == 0
	assert game.lives == 3
	assert game.current_rank.title == 'SAILOR BOY'
}

fn test_sinksub_start_game() {
	mut game := new_game_engine()
	game.start_new_game()
	assert game.mode == .playing
	assert game.subs.len > 0
	assert game.sector == 1
}

fn test_sinksub_depth_charge() {
	mut game := new_game_engine()
	game.start_new_game()
	start_charges := game.charges.len
	game.drop_stern_charge(1000)
	assert game.charges.len == start_charges + 1
}

fn test_sinksub_upgrade_purchase() {
	mut game := new_game_engine()
	game.credits = 500
	bought := game.buy_upgrade('engine')
	assert bought == true
	assert game.upgrades.engine == 2
	assert game.credits == 300
}

fn test_sinksub_rank_up() {
	mut game := new_game_engine()
	game.score = 750
	promoted := game.update_rank()
	assert promoted == true
	assert game.current_rank.title == 'PETTY OFFICER'
}
