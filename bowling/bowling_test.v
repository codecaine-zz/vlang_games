module main

fn test_pin_rack_initialization() {
	pins := init_pins()
	assert pins.len == 10
	assert pins[0].id == 1
	assert pins[9].id == 10
	for p in pins {
		assert p.standing == true
	}
}

fn test_bowling_strike_scoring() {
	mut g := new_bowling_game()
	mut p := &g.players[0]

	// Frame 1: Strike
	p.frames[0].roll1 = 10
	p.frames[0].is_strike = true

	// Frame 2: 7 and 2
	p.frames[1].roll1 = 7
	p.frames[1].roll2 = 2

	g.calculate_cumulative_scores()

	// Frame 1 score should be 10 + 7 + 2 = 19
	assert p.frames[0].cumulative == 19
	// Frame 2 cumulative should be 19 + 9 = 28
	assert p.frames[1].cumulative == 28
	assert p.total_score == 28
}

fn test_bowling_spare_scoring() {
	mut g := new_bowling_game()
	mut p := &g.players[0]

	// Frame 1: Spare (6 + 4)
	p.frames[0].roll1 = 6
	p.frames[0].roll2 = 4
	p.frames[0].is_spare = true

	// Frame 2: 5 and 3
	p.frames[1].roll1 = 5
	p.frames[1].roll2 = 3

	g.calculate_cumulative_scores()

	// Frame 1 score should be 10 + 5 = 15
	assert p.frames[0].cumulative == 15
	// Frame 2 cumulative should be 15 + 8 = 23
	assert p.frames[1].cumulative == 23
	assert p.total_score == 23
}

fn test_bowling_perfect_game_300() {
	mut g := new_bowling_game()
	mut p := &g.players[0]

	// 12 consecutive strikes
	for i in 0 .. 9 {
		p.frames[i].roll1 = 10
		p.frames[i].is_strike = true
	}
	// 10th frame: 3 strikes
	p.frames[9].roll1 = 10
	p.frames[9].roll2 = 10
	p.frames[9].roll3 = 10

	g.calculate_cumulative_scores()

	assert p.frames[0].cumulative == 30
	assert p.frames[1].cumulative == 60
	assert p.frames[8].cumulative == 270
	assert p.frames[9].cumulative == 300
	assert p.total_score == 300
}
