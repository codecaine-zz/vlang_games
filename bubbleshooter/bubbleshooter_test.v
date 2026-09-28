module main

fn test_bubbleshooter_initialization() {
	mut g := new_bubbleshooter_game()
	assert g.state == .aiming
	assert g.score == 0
	assert g.projectile.active == false
	assert g.grid.len == grid_rows
	assert g.grid[0].len == grid_cols

	// Top rows should have bubbles
	mut top_count := 0
	for c in 0 .. grid_cols {
		if g.grid[0][c] > 0 {
			top_count++
		}
	}
	assert top_count > 0
}

fn test_hexagonal_neighbors() {
	g := new_bubbleshooter_game()
	// Row 0, col 2 (even row)
	n_even := g.get_neighbors(0, 2)
	assert n_even.len > 0

	// Row 1, col 2 (odd row)
	n_odd := g.get_neighbors(1, 2)
	assert n_odd.len > 0
}

fn test_color_cluster_match() {
	mut g := new_bubbleshooter_game()
	// Clear grid
	g.grid = [][]int{len: grid_rows, init: []int{len: grid_cols, init: 0}}

	// Place 3 connected red bubbles (color = 1)
	g.grid[0][0] = 1
	g.grid[0][1] = 1
	g.grid[1][0] = 1

	cluster := g.find_color_cluster(0, 0, 1)
	assert cluster.len == 3
}

fn test_floating_bubble_detachment() {
	mut g := new_bubbleshooter_game()
	// Clear grid
	g.grid = [][]int{len: grid_rows, init: []int{len: grid_cols, init: 0}}

	// Place a bubble at row 0 (attached to ceiling)
	g.grid[0][3] = 2

	// Place a detached bubble at row 5 (not connected to row 0)
	g.grid[5][3] = 2

	floating := g.find_floating_bubbles()
	assert floating.len == 1
	assert floating[0][0] == 5
	assert floating[0][1] == 3
}

fn test_projectile_shooting() {
	mut g := new_bubbleshooter_game()
	assert g.projectile.active == false
	shot := g.shoot()
	assert shot == true
	assert g.projectile.active == true
	assert g.state == .shooting
	assert g.shots_fired == 1
}
