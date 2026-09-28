module main

fn test_memory_grid_initialization() {
	mut g := new_memory_game()
	assert g.grid_mode == .grid_4x4
	assert g.cols == 4
	assert g.rows == 4
	assert g.cards.len == 16
	assert g.total_pairs == 8
	assert g.matches == 0
	assert g.turns == 0

	// Toggle to 6x4
	g.toggle_grid_mode()
	assert g.grid_mode == .grid_6x4
	assert g.cards.len == 24
	assert g.total_pairs == 12

	// Toggle to 6x6
	g.toggle_grid_mode()
	assert g.grid_mode == .grid_6x6
	assert g.cards.len == 36
	assert g.total_pairs == 18
}

fn test_card_flip_and_matching() {
	mut g := new_memory_game()
	g.grid_mode = .grid_4x4
	g.reset_game()

	// Find two matching cards
	c1_idx := 0
	target_icon := g.cards[c1_idx].icon
	mut c2_idx := -1
	for i in 1 .. g.cards.len {
		if g.cards[i].icon == target_icon {
			c2_idx = i
			break
		}
	}
	assert c2_idx != -1

	// Flip first card
	ok1, ev1 := g.flip_card(c1_idx)
	assert ok1 == true
	assert ev1.card_flipped == true
	assert g.cards[c1_idx].is_face_up == true
	assert g.first_card_idx == c1_idx

	// Flip second matching card
	ok2, ev2 := g.flip_card(c2_idx)
	assert ok2 == true
	assert ev2.cards_matched == true
	assert g.cards[c1_idx].is_matched == true
	assert g.cards[c2_idx].is_matched == true
	assert g.matches == 1
	assert g.turns == 1
	assert g.combo == 1
}

fn test_mismatch_and_recovery() {
	mut g := new_memory_game()
	g.grid_mode = .grid_4x4
	g.reset_game()

	c1_idx := 0
	target_icon := g.cards[c1_idx].icon
	mut mismatch_idx := -1
	for i in 1 .. g.cards.len {
		if g.cards[i].icon != target_icon {
			mismatch_idx = i
			break
		}
	}
	assert mismatch_idx != -1

	// Flip first card
	g.flip_card(c1_idx)

	// Flip mismatching card
	_, ev := g.flip_card(mismatch_idx)
	assert ev.cards_mismatch == true
	assert g.state == .mismatch_delay
	assert g.combo == 0

	// Update game past mismatch timer
	g.update(1.0)
	assert g.state == .playing
	assert g.cards[c1_idx].is_face_up == false
	assert g.cards[mismatch_idx].is_face_up == false
}
