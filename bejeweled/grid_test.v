module main

fn test_grid_initialization() {
	g := new_grid()
	// Should have no initial matches
	assert g.find_matches().len == 0
	// Should have at least one valid move
	assert g.has_valid_moves()
}

fn test_find_horizontal_match() {
	mut g := Grid{}
	for r in 0 .. grid_size {
		for c in 0 .. grid_size {
			g.cells[r][c] = Gem{kind: (r * 7 + c) % 5 + 1, special: .none, curr_x: f64(c), curr_y: f64(r)}
		}
	}
	// Create a 3-match horizontally at row 0, cols 0..2
	g.cells[0][0] = Gem{kind: 1, special: .none, curr_x: 0, curr_y: 0}
	g.cells[0][1] = Gem{kind: 1, special: .none, curr_x: 1, curr_y: 0}
	g.cells[0][2] = Gem{kind: 1, special: .none, curr_x: 2, curr_y: 0}
	g.cells[0][3] = Gem{kind: 2, special: .none, curr_x: 3, curr_y: 0}

	matches := g.find_matches()
	assert matches.len >= 1
	mut found_horiz := false
	for m in matches {
		if !m.is_vert && m.kind == 1 && m.points.len == 3 {
			found_horiz = true
		}
	}
	assert found_horiz
}

fn test_swap_and_adjacent() {
	assert is_adjacent(0, 0, 0, 1)
	assert is_adjacent(0, 0, 1, 0)
	assert !is_adjacent(0, 0, 1, 1)
	assert !is_adjacent(0, 0, 0, 2)

	mut g := Grid{}
	g.cells[0][0] = Gem{kind: 1}
	g.cells[0][1] = Gem{kind: 2}
	g.swap(0, 0, 0, 1)
	assert g.cells[0][0].kind == 2
	assert g.cells[0][1].kind == 1
}

fn test_hint_finding() {
	g := new_grid()
	p1, p2, ok := g.find_hint_move()
	assert ok
	assert is_adjacent(p1.r, p1.c, p2.r, p2.c)
}

fn test_special_gems_and_bgm_cycle() {
	mut sm := new_sound_manager()
	assert sm.bgm_type == .cosmic_trance
	sm.cycle_bgm()
	assert sm.bgm_type == .electro_rush
	sm.cycle_bgm()
	assert sm.bgm_type == .zen_ambient
	sm.cycle_bgm()
	assert sm.bgm_type == .off
	sm.cycle_bgm()
	assert sm.bgm_type == .cosmic_trance

	mut g := Grid{}
	g.cells[2][3] = Gem{kind: 1, special: .flame}
	g.cells[2][4] = Gem{kind: 2, special: .star}
	g.cells[2][5] = Gem{kind: 3, special: .hypercube}
	g.cells[2][6] = Gem{kind: 4, special: .supernova}
	assert g.cells[2][3].special == .flame
	assert g.cells[2][4].special == .star
	assert g.cells[2][5].special == .hypercube
	assert g.cells[2][6].special == .supernova
}
