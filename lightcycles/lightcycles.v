module main

import math

pub enum Direction {
	up
	right
	down
	left
}

pub enum Difficulty {
	easy
	normal
	master
}

pub enum GameMode {
	pve
	pvp
}

pub enum RoundState {
	ready
	playing
	round_over
	match_over
}

pub fn is_opposite_dir(d1 Direction, d2 Direction) bool {
	return (d1 == .up && d2 == .down) || (d1 == .down && d2 == .up) || (d1 == .left && d2 == .right)
		|| (d1 == .right && d2 == .left)
}

pub fn dir_offsets(d Direction) (int, int) {
	match d {
		.up { return -1, 0 }
		.down { return 1, 0 }
		.left { return 0, -1 }
		.right { return 0, 1 }
	}
}

pub struct LightCycle {
pub mut:
	r            int
	c            int
	dir          Direction
	alive        bool = true
	boost_energy f64  = 100.0
	is_boosting  bool
	player_id    int = 1
}

pub struct LightCyclesGame {
pub mut:
	cols          int = 110
	rows          int = 75
	grid          [][]int // 0 = empty, 1 = p1 trail, 2 = p2 trail, 3 = border
	p1            LightCycle
	p2            LightCycle
	p1_score      int
	p2_score      int
	target_score  int = 5
	mode          GameMode   = .pve
	diff          Difficulty = .normal
	state         RoundState = .ready
	round_winner  int        // 0 = draw, 1 = p1, 2 = p2
	step_timer    f64
	step_interval f64 = 0.05
}

pub fn new_lightcycles_game() LightCyclesGame {
	mut g := LightCyclesGame{}
	g.reset_match()
	return g
}

pub fn (mut g LightCyclesGame) reset_match() {
	g.p1_score = 0
	g.p2_score = 0
	g.reset_round()
}

pub fn (mut g LightCyclesGame) reset_round() {
	g.grid = [][]int{len: g.rows, init: []int{len: g.cols, init: 0}}
	g.state = .playing
	g.round_winner = 0
	g.step_timer = 0.0

	// Set border walls
	for r in 0 .. g.rows {
		g.grid[r][0] = 3
		g.grid[r][g.cols - 1] = 3
	}
	for c in 0 .. g.cols {
		g.grid[0][c] = 3
		g.grid[g.rows - 1][c] = 3
	}

	// P1 start on left facing right
	p1_r := g.rows / 2
	p1_c := 15
	g.p1 = LightCycle{
		r:            p1_r
		c:            p1_c
		dir:          .right
		alive:        true
		boost_energy: 100.0
		is_boosting:  false
		player_id:    1
	}
	g.grid[p1_r][p1_c] = 1

	// P2 start on right facing left
	p2_r := g.rows / 2
	p2_c := g.cols - 16
	g.p2 = LightCycle{
		r:            p2_r
		c:            p2_c
		dir:          .left
		alive:        true
		boost_energy: 100.0
		is_boosting:  false
		player_id:    2
	}
	g.grid[p2_r][p2_c] = 2
}

pub fn (mut g LightCyclesGame) set_p1_dir(dir Direction) bool {
	if !is_opposite_dir(g.p1.dir, dir) && g.p1.alive && g.state == .playing {
		if g.p1.dir != dir {
			g.p1.dir = dir
			return true
		}
	}
	return false
}

pub fn (mut g LightCyclesGame) set_p2_dir(dir Direction) bool {
	if !is_opposite_dir(g.p2.dir, dir) && g.p2.alive && g.state == .playing {
		if g.p2.dir != dir {
			g.p2.dir = dir
			return true
		}
	}
	return false
}

pub struct StepEvents {
pub mut:
	p1_turned   bool
	p2_turned   bool
	crashed     bool
	round_ended bool
}

pub fn (mut g LightCyclesGame) update(dt f64) StepEvents {
	mut ev := StepEvents{}
	if g.state != .playing {
		return ev
	}

	// Recharge boost energy over time
	if !g.p1.is_boosting && g.p1.boost_energy < 100.0 {
		g.p1.boost_energy = math.min(100.0, g.p1.boost_energy + 15.0 * dt)
	}
	if !g.p2.is_boosting && g.p2.boost_energy < 100.0 {
		g.p2.boost_energy = math.min(100.0, g.p2.boost_energy + 15.0 * dt)
	}

	// Consume boost
	if g.p1.is_boosting {
		g.p1.boost_energy = math.max(0.0, g.p1.boost_energy - 60.0 * dt)
		if g.p1.boost_energy <= 0.0 {
			g.p1.is_boosting = false
		}
	}
	if g.p2.is_boosting {
		g.p2.boost_energy = math.max(0.0, g.p2.boost_energy - 60.0 * dt)
		if g.p2.boost_energy <= 0.0 {
			g.p2.is_boosting = false
		}
	}

	// Step interval calculation
	cur_interval := if g.p1.is_boosting || g.p2.is_boosting { g.step_interval * 0.55 } else { g.step_interval }
	g.step_timer += dt

	if g.step_timer >= cur_interval {
		g.step_timer = 0.0

		// If PvE, compute AI move for P2
		if g.mode == .pve && g.p2.alive {
			ai_dir := compute_ai_move(g.grid, g.p2.r, g.p2.c, g.p2.dir, g.diff)
			if ai_dir != g.p2.dir {
				g.p2.dir = ai_dir
				ev.p2_turned = true
			}
		}

		// Calculate next positions
		p1_dr, p1_dc := dir_offsets(g.p1.dir)
		p1_nr := g.p1.r + p1_dr
		p1_nc := g.p1.c + p1_dc

		p2_dr, p2_dc := dir_offsets(g.p2.dir)
		p2_nr := g.p2.r + p2_dr
		p2_nc := g.p2.c + p2_dc

		mut p1_dead := false
		mut p2_dead := false

		// Head on head collision
		if p1_nr == p2_nr && p1_nc == p2_nc {
			p1_dead = true
			p2_dead = true
		} else {
			// Check P1 collision
			if p1_nr < 0 || p1_nr >= g.rows || p1_nc < 0 || p1_nc >= g.cols || g.grid[p1_nr][p1_nc] != 0 {
				p1_dead = true
			}
			// Check P2 collision
			if p2_nr < 0 || p2_nr >= g.rows || p2_nc < 0 || p2_nc >= g.cols || g.grid[p2_nr][p2_nc] != 0 {
				p2_dead = true
			}
		}

		if p1_dead || p2_dead {
			ev.crashed = true
			ev.round_ended = true
			g.state = .round_over

			if p1_dead && p2_dead {
				g.round_winner = 0 // Draw
			} else if p1_dead {
				g.p2_score++
				g.round_winner = 2
			} else {
				g.p1_score++
				g.round_winner = 1
			}

			if g.p1_score >= g.target_score || g.p2_score >= g.target_score {
				g.state = .match_over
			}
			return ev
		}

		// Advance P1
		g.p1.r = p1_nr
		g.p1.c = p1_nc
		g.grid[p1_nr][p1_nc] = 1

		// Advance P2
		g.p2.r = p2_nr
		g.p2.c = p2_nc
		g.grid[p2_nr][p2_nc] = 2
	}

	return ev
}
