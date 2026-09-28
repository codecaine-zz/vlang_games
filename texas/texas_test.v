module main

fn test_poker_hand_royal_flush() {
	cards := [
		Card{ rank: 14, suit: .spades }, // Ace
		Card{ rank: 13, suit: .spades }, // King
		Card{ rank: 12, suit: .spades }, // Queen
		Card{ rank: 11, suit: .spades }, // Jack
		Card{ rank: 10, suit: .spades }, // 10
		Card{ rank: 2, suit: .hearts },
		Card{ rank: 5, suit: .diamonds },
	]
	score := evaluate_7card_hand(cards)
	assert score.rank == .royal_flush
}

fn test_poker_hand_four_of_a_kind() {
	cards := [
		Card{ rank: 9, suit: .spades },
		Card{ rank: 9, suit: .hearts },
		Card{ rank: 9, suit: .diamonds },
		Card{ rank: 9, suit: .clubs },
		Card{ rank: 14, suit: .spades }, // Ace Kicker
		Card{ rank: 2, suit: .hearts },
		Card{ rank: 3, suit: .diamonds },
	]
	score := evaluate_7card_hand(cards)
	assert score.rank == .four_of_a_kind
	assert score.primary == 9
}

fn test_poker_hand_full_house() {
	cards := [
		Card{ rank: 10, suit: .spades },
		Card{ rank: 10, suit: .hearts },
		Card{ rank: 10, suit: .diamonds },
		Card{ rank: 4, suit: .clubs },
		Card{ rank: 4, suit: .spades },
		Card{ rank: 2, suit: .hearts },
		Card{ rank: 7, suit: .diamonds },
	]
	score := evaluate_7card_hand(cards)
	assert score.rank == .full_house
	assert score.primary == 10
	assert score.secondary == 4
}

fn test_poker_hand_straight() {
	cards := [
		Card{ rank: 9, suit: .spades },
		Card{ rank: 8, suit: .hearts },
		Card{ rank: 7, suit: .diamonds },
		Card{ rank: 6, suit: .clubs },
		Card{ rank: 5, suit: .spades },
		Card{ rank: 2, suit: .hearts },
		Card{ rank: 12, suit: .diamonds },
	]
	score := evaluate_7card_hand(cards)
	assert score.rank == .straight
	assert score.primary == 9
}

fn test_texas_blinds_and_deal() {
	g := new_texas_game()
	assert g.players.len == 4
	for p in g.players {
		assert p.hole_cards.len == 2
	}
	// Small blind ($10) + Big blind ($20) in pot
	assert g.pot == 30
}
