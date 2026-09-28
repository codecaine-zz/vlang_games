module main

fn test_simon_game_initialization() {
	mut g := new_simon_game()
	assert g.state == .attract
	assert g.mode == .classic
	assert g.score == 0
	assert g.sequence.len == 0

	g.start_new_game()
	assert g.sequence.len == 1
	assert g.state == .playback
}

fn test_simon_modes_toggle() {
	mut g := new_simon_game()
	assert g.mode == .classic
	g.toggle_mode()
	assert g.mode == .reverse
	g.toggle_mode()
	assert g.mode == .speed
	g.toggle_mode()
	assert g.mode == .classic
}

fn test_simon_classic_and_reverse_input() {
	// 1. Test Classic Mode Input
	mut g := new_simon_game()
	g.mode = .classic
	g.sequence = [0, 1, 2]
	g.state = .player_turn
	g.player_step = 0

	// Step 1: Green (0)
	ok1, _ := g.handle_pad_press(0)
	assert ok1 == true
	assert g.player_step == 1
	assert g.state == .player_turn

	// Step 2: Red (1)
	ok2, _ := g.handle_pad_press(1)
	assert ok2 == true
	assert g.player_step == 2

	// Step 3: Yellow (2) - Completes round!
	ok3, ev3 := g.handle_pad_press(2)
	assert ok3 == true
	assert g.state == .round_success
	assert ev3.round_clear == true
	assert g.score == 3

	// 2. Test Reverse Mode Input
	mut gr := new_simon_game()
	gr.mode = .reverse
	gr.sequence = [0, 1, 3] // Reverse is 3 -> 1 -> 0
	gr.state = .player_turn
	gr.player_step = 0

	// Must press 3 first
	ok_rev1, _ := gr.handle_pad_press(3)
	assert ok_rev1 == true

	// Then 1
	ok_rev2, _ := gr.handle_pad_press(1)
	assert ok_rev2 == true

	// Then 0
	ok_rev3, ev_rev3 := gr.handle_pad_press(0)
	assert ok_rev3 == true
	assert gr.state == .round_success
	assert ev_rev3.round_clear == true
}

fn test_simon_mistake_game_over() {
	mut g := new_simon_game()
	g.sequence = [0, 1, 2]
	g.state = .player_turn
	g.player_step = 0

	// Wrong pad press (pressed 3 instead of 0)
	ok, ev := g.handle_pad_press(3)
	assert ok == false
	assert g.state == .game_over
	assert ev.error_buzz == true
}
