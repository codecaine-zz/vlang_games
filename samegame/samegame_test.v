module main

fn test_samegame_init() {
	mut g := new_same_game(.puzzle)
	assert g.state == .playing
	assert g.score == 0
	assert g.grid.len == sg_rows
	assert g.grid[0].len == sg_cols
}

fn test_samegame_cluster_find_and_shatter() {
	mut g := new_same_game(.puzzle)
	g.grid = [14][12]int{}

	// Place 3 Ruby gems (type 1) in L shape
	g.grid[13][0] = 1
	g.grid[13][1] = 1
	g.grid[12][0] = 1

	cluster := g.find_cluster(13, 0)
	assert cluster.len == 3

	cleared := g.click_cell(13, 0)
	assert cleared == 3
	assert g.grid[13][0] == 0
	assert g.grid[13][1] == 0
	assert g.grid[12][0] == 0
	assert g.score > 0
}

fn test_samegame_gravity_and_column_shift() {
	mut g := new_same_game(.puzzle)
	g.grid = [14][12]int{}

	// Place floating gem in col 1, col 0 is empty
	g.grid[10][1] = 2

	g.apply_gravity()
	// Should drop to bottom row and shift from col 1 to col 0!
	assert g.grid[13][0] == 2
	assert g.grid[10][1] == 0
}

fn test_samegame_perfect_clear_bonus() {
	mut g := new_same_game(.puzzle)
	g.grid = [14][12]int{}

	// 2 adjacent Topaz gems (type 4)
	g.grid[13][0] = 4
	g.grid[13][1] = 4

	cleared := g.click_cell(13, 0)
	assert cleared == 2
	assert g.state == .cleared_all
	assert g.score >= 20000
}
