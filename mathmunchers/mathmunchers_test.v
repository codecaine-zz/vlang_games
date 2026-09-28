module main

fn test_is_prime() {
	assert !is_prime(0)
	assert !is_prime(1)
	assert is_prime(2)
	assert is_prime(3)
	assert !is_prime(4)
	assert is_prime(5)
	assert !is_prime(9)
	assert is_prime(13)
	assert is_prime(17)
}

fn test_evaluate_rule() {
	mult_rule := RuleInfo{
		rule_type:   .multiples
		param:       5
		title:       'MULTIPLES OF 5'
		description: ''
	}
	assert evaluate_rule(5, '5', mult_rule)
	assert evaluate_rule(15, '15', mult_rule)
	assert evaluate_rule(25, '25', mult_rule)
	assert !evaluate_rule(12, '12', mult_rule)
	assert !evaluate_rule(7, '7', mult_rule)

	fact_rule := RuleInfo{
		rule_type:   .factors
		param:       12
		title:       'FACTORS OF 12'
		description: ''
	}
	assert evaluate_rule(4, '4', fact_rule)
	assert !evaluate_rule(5, '5', fact_rule)

	prime_rule := RuleInfo{
		rule_type:   .primes
		param:       0
		title:       'PRIMES'
		description: ''
	}
	assert evaluate_rule(7, '7', prime_rule)
	assert !evaluate_rule(8, '8', prime_rule)

	gt_rule := RuleInfo{
		rule_type:   .greater_than
		param:       20
		title:       'GREATER THAN 20'
		description: ''
	}
	assert evaluate_rule(25, '25', gt_rule)
	assert !evaluate_rule(15, '15', gt_rule)
}

fn test_multiples_of_5_level_clear() {
	mut game := new_mathmunchers_game()
	mut sm := SoundManager{}
	game.state = .playing
	game.level = 1
	game.current_rule = RuleInfo{
		rule_type:   .multiples
		param:       5
		title:       'MULTIPLES OF 5'
		description: ''
	}

	// Set up grid with exactly 2 multiples of 5, and rest distractors
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			game.grid[r][c] = Cell{
				value:     12
				expr:      '12'
				is_target: false
				eaten:     false
			}
		}
	}
	game.grid[0][0] = Cell{
		value:     15
		expr:      '15'
		is_target: true
		eaten:     false
	}
	game.grid[0][1] = Cell{
		value:     25
		expr:      '25'
		is_target: true
		eaten:     false
	}

	assert game.count_remaining_targets() == 2

	// Munch first target
	game.player.grid_x = 0
	game.player.grid_y = 0
	game.munch_cell(mut sm)
	assert game.count_remaining_targets() == 1
	assert game.level == 1

	// Munch second (last) target -> Level should advance to level 2!
	game.player.grid_x = 1
	game.player.grid_y = 0
	game.munch_cell(mut sm)
	assert game.level == 2
}

fn test_game_initialization() {
	mut game := new_mathmunchers_game()
	game.set_difficulty(.medium)
	game.start_new_game()
	assert game.player.lives == 3
	assert game.grid.len == grid_rows
	assert game.grid[0].len == grid_cols
	assert game.count_remaining_targets() > 0
}

fn test_extra_life_award() {
	mut game := new_mathmunchers_game()
	mut sm := SoundManager{}
	initial_lives := game.player.lives
	game.add_score(10000, mut sm)
	assert game.player.lives == initial_lives + 1
}

fn test_troggle_warning_queue() {
	mut game := new_mathmunchers_game()
	game.queue_troggle_warning()
	assert game.troggle_warnings.len == 1
}

fn test_difficulty_selection() {
	mut game := new_mathmunchers_game()
	game.set_difficulty(.easy)
	game.start_new_game()
	assert game.player.lives == 4

	game.set_difficulty(.hard)
	game.start_new_game()
	assert game.player.lives == 2
}

fn test_save_data_serialization() {
	data := SaveData{
		high_score:       9950
		save_state_valid: true
		level:            4
		score:            3200
		lives:            2
		sound_enabled:    true
	}
	save_data_to_file(&data)
	loaded := load_save_data()
	assert loaded.high_score == 9950
	assert loaded.level == 4
	assert loaded.score == 3200
}
