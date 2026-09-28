module main

fn test_liarsdice_bid_validation() {
	prev := Bid{ qty: 3, face: 4 }

	// Same quantity, lower face -> invalid
	b1 := Bid{ qty: 3, face: 3 }
	assert !b1.is_valid_higher(prev, 20)

	// Same quantity, higher face -> valid
	b2 := Bid{ qty: 3, face: 5 }
	assert b2.is_valid_higher(prev, 20)

	// Higher quantity, any face -> valid
	b3 := Bid{ qty: 4, face: 2 }
	assert b3.is_valid_higher(prev, 20)

	// Switch to 1s (Pacos): needs ceil(3/2) = 2 ones
	b4 := Bid{ qty: 2, face: 1 }
	assert b4.is_valid_higher(prev, 20)

	// Only 1 one -> invalid
	b5 := Bid{ qty: 1, face: 1 }
	assert !b5.is_valid_higher(prev, 20)

	// Switch from 1s (2 ones) to normal face: needs 2*2 + 1 = 5 dice
	prev_ones := Bid{ qty: 2, face: 1 }
	b6 := Bid{ qty: 5, face: 6 }
	assert b6.is_valid_higher(prev_ones, 20)

	b7 := Bid{ qty: 4, face: 6 }
	assert !b7.is_valid_higher(prev_ones, 20)
}

fn test_liarsdice_game_flow() {
	mut g := new_liarsdice_game(false)
	assert g.players.len == 4
	assert g.total_active_dice() == 20

	// Custom dice injection for deterministic testing
	g.players[0].dice = [2, 3, 4, 5, 6]
	g.players[1].dice = [1, 2, 3, 4, 5]
	g.players[2].dice = [1, 1, 3, 5, 6]
	g.players[3].dice = [2, 4, 4, 6, 6]

	// Count matching 4s (with 1s being wild)
	// P0 has 1 four, P1 has 1 four + 1 one = 2, P2 has 2 ones = 2, P3 has 2 fours = 2 -> total 7
	count_fours := g.count_matching_dice(4)
	assert count_fours == 7

	// Count matching 1s (1s are NOT wild for themselves)
	// P1 has 1, P2 has 2 -> total 3
	count_ones := g.count_matching_dice(1)
	assert count_ones == 3

	// Test bidding
	g.phase = .bidding
	g.current_player = 0
	ok := g.make_bid(0, 4, 4)
	assert ok
	assert g.last_bid.qty == 4
	assert g.last_bid.face == 4
	assert g.last_bidder == 0
}
