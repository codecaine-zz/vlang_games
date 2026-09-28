module main

fn test_battleship_grid_placement() {
	mut g := new_grid()
	assert g.ships.len == 5

	// Valid horizontal placement
	ok1 := g.place_ship(0, 0, 0, true)
	assert ok1
	assert g.cells[0][0] == cell_ship
	assert g.cells[0][4] == cell_ship

	// Overlapping placement should fail
	ok2 := g.place_ship(1, 2, 0, false)
	assert !ok2

	// Out of bounds placement should fail
	ok3 := g.place_ship(1, 8, 8, true)
	assert !ok3
}

fn test_battleship_auto_placement() {
	mut g := new_grid()
	g.auto_place_all()
	for s in g.ships {
		assert s.placed
	}

	mut total_ship_cells := 0
	for y in 0 .. grid_size {
		for x in 0 .. grid_size {
			if g.cells[y][x] == cell_ship {
				total_ship_cells++
			}
		}
	}
	// 5 + 4 + 3 + 3 + 2 = 17 cells
	assert total_ship_cells == 17
}

fn test_battleship_shooting_mechanics() {
	mut game := new_battleship_game(false)
	game.p1_grid.auto_place_all()
	game.p2_grid = new_grid()
	game.p2_grid.place_ship(4, 0, 0, true) // Destroyer: (0,0) and (1,0)
	game.start_battle()

	// Fire at (5,5) -> Miss
	hit1, sunk1, _ := game.fire_shot(2, 5, 5)
	assert !hit1
	assert !sunk1
	assert game.p2_grid.cells[5][5] == cell_miss

	// Fire at (0,0) -> Hit (not yet sunk)
	hit2, sunk2, _ := game.fire_shot(2, 0, 0)
	assert hit2
	assert !sunk2
	assert game.p2_grid.cells[0][0] == cell_hit

	// Fire at (1,0) -> Hit & Sunk Destroyer!
	hit3, sunk3, name3 := game.fire_shot(2, 1, 0)
	assert hit3
	assert sunk3
	assert name3 == 'Destroyer'
	assert game.p2_grid.cells[0][0] == cell_sunk
	assert game.p2_grid.cells[0][1] == cell_sunk
}
