module main

fn test_yahtzee_initialization() {
	mut g := new_yahtzee_game()
	assert g.round == 1
	assert g.rolls_left == 3
	assert g.dice.len == 5
	assert g.players.len == 1
	assert g.players[0].scores.len == 0
}

fn test_yahtzee_scoring_calculations() {
	mut g := new_yahtzee_game()
	g.dice[0].value = 1
	g.dice[1].value = 1
	g.dice[2].value = 3
	g.dice[3].value = 4
	g.dice[4].value = 5

	assert g.calculate_score(Category.ones) == 2
	assert g.calculate_score(Category.twos) == 0
	assert g.calculate_score(Category.threes) == 3
	assert g.calculate_score(Category.chance) == 14

	// Test Full House
	g.dice[0].value = 4
	g.dice[1].value = 4
	g.dice[2].value = 4
	g.dice[3].value = 6
	g.dice[4].value = 6
	assert g.calculate_score(Category.full_house) == 25
	assert g.calculate_score(Category.three_of_kind) == 24

	// Test Small Straight
	g.dice[0].value = 1
	g.dice[1].value = 2
	g.dice[2].value = 3
	g.dice[3].value = 4
	g.dice[4].value = 6
	assert g.calculate_score(Category.small_straight) == 30
	assert g.calculate_score(Category.large_straight) == 0

	// Test Large Straight
	g.dice[4].value = 5
	assert g.calculate_score(Category.large_straight) == 40

	// Test Yahtzee
	g.dice[0].value = 6
	g.dice[1].value = 6
	g.dice[2].value = 6
	g.dice[3].value = 6
	g.dice[4].value = 6
	assert g.calculate_score(Category.yahtzee) == 50
}

fn test_yahtzee_turn_progression_and_bonus() {
	mut g := new_yahtzee_game()
	g.roll_dice()
	// Let dice finish rolling
	g.update(0.5)
	assert g.rolls_left == 2

	// Choose Category
	assert g.choose_category(Category.chance)
	assert g.players[0].is_filled(Category.chance)
	assert g.rolls_left == 3
	assert g.round == 2

	// Test Upper Bonus: 3 of each upper section = 63 points -> +35 bonus
	g.players[0].scores[Category.ones.str()] = 3
	g.players[0].scores[Category.twos.str()] = 6
	g.players[0].scores[Category.threes.str()] = 9
	g.players[0].scores[Category.fours.str()] = 12
	g.players[0].scores[Category.fives.str()] = 15
	g.players[0].scores[Category.sixes.str()] = 18

	assert g.players[0].get_upper_subtotal() == 63
	assert g.players[0].get_upper_total() == 63 + 35
}

fn test_yahtzee_ai_mode() {
	mut g := new_yahtzee_game()
	g.mode = .vs_ai
	g.reset_game()
	assert g.players.len == 2
	assert !g.players[0].is_ai
	assert g.players[1].is_ai

	// Advance turn to AI
	g.roll_dice()
	g.update(0.5)
	assert g.choose_category(Category.ones)
	assert g.current_player == 1

	// Let AI play step
	g.update(0.8)
	assert g.is_rolling() || g.rolls_left < 3
}
