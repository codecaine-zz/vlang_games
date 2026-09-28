module main

fn test_blackjack_shoe_init() {
	mut g := new_blackjack_game()
	// 4 decks = 208 cards
	assert g.shoe.len == 208
}

fn test_hand_value_calculations() {
	// Hard 20
	cards1 := [Card{ rank: 10, suit: .spades }, Card{ rank: 13, suit: .hearts }]
	val1, soft1 := calculate_hand_value(cards1)
	assert val1 == 20
	assert soft1 == false

	// Soft 18 (Ace + 7)
	cards2 := [Card{ rank: 1, suit: .spades }, Card{ rank: 7, suit: .hearts }]
	val2, soft2 := calculate_hand_value(cards2)
	assert val2 == 18
	assert soft2 == true

	// Multi-Ace (Ace + Ace + 9 = 21)
	cards3 := [Card{ rank: 1, suit: .spades }, Card{ rank: 1, suit: .clubs }, Card{ rank: 9, suit: .hearts }]
	val3, soft3 := calculate_hand_value(cards3)
	assert val3 == 21
	assert soft3 == true
}

fn test_natural_blackjack() {
	// Ace + King
	bj_hand := [Card{ rank: 1, suit: .diamonds }, Card{ rank: 13, suit: .clubs }]
	assert is_natural_blackjack(bj_hand) == true

	// Non-BJ 21 (7 + 7 + 7)
	non_bj := [Card{ rank: 7, suit: .diamonds }, Card{ rank: 7, suit: .clubs }, Card{ rank: 7, suit: .hearts }]
	assert is_natural_blackjack(non_bj) == false
}
