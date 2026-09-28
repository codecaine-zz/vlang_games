module main

import math

fn test_game_initialization() {
	mut g := new_game()
	assert g.lives == 3
	assert g.score == 0
	assert g.level == 1
	assert g.pacman.col == 13
	assert g.pacman.row == 18
	assert g.ghosts.len == 4
	assert g.dots_remaining > 0
}

fn test_maze_tile_collision() {
	mut g := new_game()
	// Boundary walls (0,0) is wall
	assert g.is_wall(0, 0) == true
	// Corridor tile (1,1) is dot / non-wall
	assert g.is_wall(1, 1) == false
	// Can move right from (1,1)
	assert g.can_move(1, 1, .right, false) == true
	// Cannot move left into outer wall from (1,1)
	assert g.can_move(1, 1, .left, false) == false
}

fn test_pacman_movement() {
	mut g := new_game()
	g.status = .playing

	// Move to open corridor tile (1,1)
	g.pacman.col = 1
	g.pacman.row = 1
	g.pacman.x = 1.0 * 24.0 + 12.0
	g.pacman.y = 1.0 * 24.0 + 12.0

	initial_x := g.pacman.x
	g.pacman.dir = .right
	g.pacman.next_dir = .right
	g.update_pacman(0.1)
	assert g.pacman.x > initial_x
}

fn test_dot_and_power_pellet_eating() {
	mut g := new_game()
	g.status = .playing

	// Place Pacman on dot tile (1,1)
	g.pacman.col = 1
	g.pacman.row = 1
	g.pacman.x = 1.0 * 24.0 + 12.0
	g.pacman.y = 1.0 * 24.0 + 12.0
	g.grid[1][1] = .dot

	initial_dots := g.dots_remaining
	initial_power_pellets := g.power_pellets_remaining
	initial_score := g.score

	ate_dot, ate_power := g.update_pacman(0.01)
	assert ate_dot == true
	assert ate_power == false
	assert g.score == initial_score + 10
	assert g.dots_remaining == initial_dots - 1
	assert g.power_pellets_remaining == initial_power_pellets
	assert g.grid[1][1] == .empty

	// Place Pacman on power pellet tile (1,1)
	g.grid[1][1] = .power_pellet
	_, ate_p2 := g.update_pacman(0.01)
	assert ate_p2 == true
	assert g.power_pellets_remaining == initial_power_pellets - 1
	assert g.dots_remaining == initial_dots - 1
	assert g.frightened_timer == 7.0
	assert g.ghosts[0].mode == .frightened
}

fn test_power_pellet_does_not_end_level_when_regular_dots_remain() {
	mut g := new_game()
	g.status = .playing
	g.dots_remaining = 1
	g.power_pellets_remaining = 1
	g.pacman.col = 1
	g.pacman.row = 1
	g.pacman.x = 1.0 * 24.0 + 12.0
	g.pacman.y = 1.0 * 24.0 + 12.0
	g.grid[1][1] = .power_pellet

	_, ate_power := g.update_pacman(0.01)
	assert ate_power == true
	assert g.status == .playing
	assert g.dots_remaining == 1
	assert g.power_pellets_remaining == 0
}

fn test_power_pellet_reverses_ghost_using_current_position() {
	mut g := new_game()
	g.status = .playing
	g.pacman.col = 2
	g.pacman.row = 1
	g.pacman.x = 2.0 * 24.0 + 12.0
	g.pacman.y = 1.0 * 24.0 + 12.0
	g.grid[2][1] = .power_pellet
	g.ghosts[0].dir = .right
	g.ghosts[0].col = 1
	g.ghosts[0].row = 1
	g.ghosts[0].x = 2.0 * 24.0 + 12.0
	g.ghosts[0].y = 1.0 * 24.0 + 12.0
	g.ghosts[0].mode = .scatter

	_, ate_power := g.update_pacman(0.01)
	assert ate_power == true
	assert g.ghosts[0].dir == .left
}

fn test_pacman_keeps_moving_after_power_pellet() {
	mut g := new_game()
	g.status = .playing
	g.pacman.col = 1
	g.pacman.row = 1
	g.pacman.x = 1.0 * 24.0 + 12.0
	g.pacman.y = 1.0 * 24.0 + 12.0
	g.pacman.dir = .right
	g.pacman.next_dir = .right
	g.grid[1][1] = .power_pellet

	initial_x := g.pacman.x
	_, _ := g.update_pacman(0.01)
	assert g.pacman.x > initial_x
}

fn test_ghost_targeting_ai() {
	mut g := new_game()
	g.status = .playing
	g.pacman.col = 10
	g.pacman.row = 15

	// Test Blinky Chase Target -> PacMan position
	g.ghosts[0].mode = .chase
	g.update_ghost_ai(0)
	assert g.ghosts[0].target_col == 10
	assert g.ghosts[0].target_row == 15

	// Test Pinky Chase Target -> 4 tiles ahead
	g.pacman.dir = .right
	g.ghosts[1].mode = .chase
	g.update_ghost_ai(1)
	assert g.ghosts[1].target_col == 14
	assert g.ghosts[1].target_row == 15
}

fn test_frightened_ghost_movement_does_not_freeze() {
	mut g := new_game()
	g.status = .playing
	g.ghosts[0].mode = .frightened

	initial_x := g.ghosts[0].x
	initial_y := g.ghosts[0].y

	// Run 30 simulation steps (approx 0.5 sec)
	for _ in 0 .. 30 {
		g.update_ghosts(0.016)
	}

	dist_moved := math.sqrt((g.ghosts[0].x - initial_x) * (g.ghosts[0].x - initial_x) +
		(g.ghosts[0].y - initial_y) * (g.ghosts[0].y - initial_y))
	assert dist_moved > 5.0
}

fn test_eating_frightened_ghost() {
	mut g := new_game()
	g.status = .playing

	// Place Pacman and ghost near each other
	g.pacman.x = 100.0
	g.pacman.y = 100.0
	g.ghosts[0].x = 102.0
	g.ghosts[0].y = 100.0
	g.ghosts[0].mode = .frightened

	initial_score := g.score
	ate_ghost, pac_died := g.update_ghosts(0.016)
	assert ate_ghost == true
	assert pac_died == false
	assert g.ghosts[0].mode == .eaten
	assert g.score == initial_score + 200
}

fn test_eaten_ghost_returns_home() {
	mut g := new_game()
	g.status = .playing

	// Set ghost mode to eaten at its spawn tile
	g.ghosts[0].mode = .eaten
	g.ghosts[0].x = f64(g.ghosts[0].spawn_col * 24 + 12)
	g.ghosts[0].y = f64(g.ghosts[0].spawn_row * 24 + 12)

	g.update_ghosts(0.016)
	assert g.ghosts[0].mode == .chase
}
