module main

fn test_war_deck_generation() {
	deck := generate_52_deck()
	assert deck.len == 52
}

fn test_war_deal_split() {
	g := new_war_game()
	assert g.player_draw_pile.len == 26
	assert g.ai_draw_pile.len == 26
	assert g.player_win_pile.len == 0
	assert g.ai_win_pile.len == 0
}

fn test_rank_comparison() {
	ace := Card{ rank: 14, suit: .spades }
	king := Card{ rank: 13, suit: .hearts }
	two := Card{ rank: 2, suit: .clubs }

	assert ace.rank > king.rank
	assert king.rank > two.rank
	assert ace.rank > two.rank
}

fn test_rank_formatting() {
	assert get_rank_str(14) == 'A'
	assert get_rank_str(13) == 'K'
	assert get_rank_str(12) == 'Q'
	assert get_rank_str(11) == 'J'
	assert get_rank_str(10) == '10'
	assert get_rank_str(7) == '7'
	assert get_rank_str(2) == '2'
}
