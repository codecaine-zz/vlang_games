module main

fn test_slots_initialization() {
	mut g := new_slots_game()
	assert g.num_reels == 3
	assert g.reels.len == 3
	assert g.balance == 1000
	assert g.active_lines == 5
}

fn test_3reel_777_payout() {
	// 3x Lucky 7 = 200x bet
	bet := 10
	payout, sym := evaluate_3reel_line(.seven, .seven, .seven, bet)
	assert sym == .seven
	assert payout == 2000
}

fn test_3reel_diamond_jackpot() {
	// 3x Diamond = 500x bet
	bet := 25
	payout, sym := evaluate_3reel_line(.diamond, .diamond, .diamond, bet)
	assert sym == .diamond
	assert payout == 12500
}

fn test_3reel_wild_substitution() {
	// Wild substitutes for seven
	bet := 5
	payout, sym := evaluate_3reel_line(.seven, .wild, .seven, bet)
	assert sym == .seven
	assert payout == 1000
}

fn test_5reel_diamond_5x() {
	// 5x Diamond = 1000x bet
	bet := 5
	symbols := [SymbolType.diamond, SymbolType.diamond, SymbolType.diamond, SymbolType.diamond, SymbolType.diamond]
	payout, sym, count := evaluate_5reel_line(symbols, bet)
	assert sym == .diamond
	assert count == 5
	assert payout == 5000
}

fn test_theme_switch_and_hold() {
	mut g := new_slots_game()
	assert g.theme == .vegas_classic

	// Hold reel 0
	g.toggle_hold(0)
	assert g.reels[0].hold == true

	// Switch to 5-reel
	g.init_theme(.neon_cyber)
	assert g.num_reels == 5
	assert g.reels.len == 5
	assert g.active_lines == 20
}
