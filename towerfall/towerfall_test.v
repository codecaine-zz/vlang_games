module main

fn test_screen_wrap() {
	mut game := new_towerfall_game()
	mut x := -10.0
	mut y := 200.0

	game.wrap_position(mut x, mut y)
	assert x == f64(arena_w - 4)

	x = f64(arena_w + 50)
	game.wrap_position(mut x, mut y)
	assert x == 4.0
}

fn test_archer_init() {
	mut game := new_towerfall_game()
	game.start_quest()

	assert game.players.len == 1
	assert game.players[0].arrows == 3
	assert game.players[0].lives == 3
}

fn test_save_serialization() {
	mut data := TowerFallSaveData{
		high_score: 15400
		max_quest_wave: 8
		unlocked_arenas: 3
		save_state_valid: true
		quest_wave: 5
		score: 8200
	}
	save_towerfall_data(&data)

	loaded := load_towerfall_save()
	assert loaded.high_score == 15400
	assert loaded.max_quest_wave == 8
	assert loaded.unlocked_arenas == 3
	assert loaded.save_state_valid == true
}
