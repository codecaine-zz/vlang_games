module main

import rand

pub enum GameMode {
	game_a
	game_b
}

pub enum GameState {
	title
	playing
	game_over
}

pub struct Jumper {
pub mut:
	step            int  // 0 to 13 (LCD trajectory node)
	active          bool
	crashed         bool
	hesitation      int  // Ticks to pause at window ledge before leaping
	fall_rate       int = 1 // Ticks per step advance (usually 1, or 2 for high altitude float)
	tick_count      int
}

pub struct FireGame {
pub mut:
	trampoline_pos   int = 1 // 0: Left, 1: Middle, 2: Right
	jumpers          []Jumper
	score            int
	high_score       int
	misses           int
	state            GameState = .title
	mode             GameMode  = .game_a
	tick_timer       f64
	tick_interval    f64 = 0.32
	spawn_timer      int
	last_event       string
	cleared_at_200   bool
	cleared_at_500   bool
}

pub fn new_fire_game() FireGame {
	return FireGame{
		state: .title
		high_score: 0
	}
}

pub fn (mut g FireGame) start_game(mode GameMode) {
	g.mode = mode
	g.score = 0
	g.misses = 0
	g.trampoline_pos = 1
	g.jumpers.clear()
	g.state = .playing
	g.tick_timer = 0.0
	g.tick_interval = if mode == .game_a { 0.30 } else { 0.22 }
	g.spawn_timer = 1
	g.last_event = 'START'
	g.cleared_at_200 = false
	g.cleared_at_500 = false
}

pub fn (mut g FireGame) move_left() {
	if g.trampoline_pos > 0 {
		g.trampoline_pos--
	}
}

pub fn (mut g FireGame) move_right() {
	if g.trampoline_pos < 2 {
		g.trampoline_pos++
	}
}

pub fn (mut g FireGame) set_pos(pos int) {
	if pos >= 0 && pos <= 2 {
		g.trampoline_pos = pos
	}
}

pub fn (mut g FireGame) update(dt f64, mut sm SoundManager) {
	if g.state != .playing {
		return
	}

	g.tick_timer += dt
	if g.tick_timer < g.tick_interval {
		return
	}
	g.tick_timer = 0.0

	// Dynamic speed scaling curve
	base_interval := if g.mode == .game_a { 0.30 } else { 0.22 }
	// Speed scales up smoothly with score and mode
	speedup := f64(g.score) * 0.0018
	min_interval := if g.mode == .game_a { 0.12 } else { 0.09 }
	g.tick_interval = if base_interval - speedup > min_interval { base_interval - speedup } else { min_interval }

	// Milestone Bonus: Clear misses at 200 and 500 points!
	if g.score >= 200 && !g.cleared_at_200 {
		g.cleared_at_200 = true
		if g.misses > 0 {
			g.misses = 0
			sm.play_score()
		}
	}
	if g.score >= 500 && !g.cleared_at_500 {
		g.cleared_at_500 = true
		if g.misses > 0 {
			g.misses = 0
			sm.play_score()
		}
	}

	// Spawn Director: Creates varied, dynamic, unpredictable jump patterns
	g.spawn_timer--
	if g.spawn_timer <= 0 {
		active_count := g.jumpers.filter(it.active && !it.crashed).len
		max_active := if g.mode == .game_a {
			if g.score < 20 { 2 } else if g.score < 60 { 3 } else { 4 }
		} else {
			if g.score < 15 { 3 } else if g.score < 50 { 4 } else { 5 }
		}

		if active_count < max_active {
			// Random hesitation (0..2 beats) on window ledge to break monotonous lockstep
			hesitation := rand.int_in_range(0, 3) or { 0 }
			start_step := if (rand.int_in_range(0, 4) or { 0 }) == 0 && g.score > 25 { 1 } else { 0 }

			g.jumpers << Jumper{
				step: start_step
				active: true
				crashed: false
				hesitation: hesitation
				fall_rate: 1
				tick_count: 0
			}
			sm.play_tick()
		}

		// Asymmetric, dynamic spawn delays
		spawn_min := if g.mode == .game_a { 3 } else { 2 }
		spawn_max := if g.mode == .game_a { 6 } else { 5 }
		spawn_delay := rand.int_in_range(spawn_min, spawn_max + 1) or { 4 }
		g.spawn_timer = spawn_delay
	}

	// Advance jumpers with individual cadence
	mut i := 0
	for i < g.jumpers.len {
		if !g.jumpers[i].active {
			g.jumpers.delete(i)
			continue
		}

		if g.jumpers[i].crashed {
			g.jumpers[i].active = false
			i++
			continue
		}

		// Handle hesitation on window ledge before falling
		if g.jumpers[i].step == 0 && g.jumpers[i].hesitation > 0 {
			g.jumpers[i].hesitation--
			i++
			continue
		}

		g.jumpers[i].step++
		cur_step := g.jumpers[i].step

		// Bounce checks at 3 trampoline stations:
		// Step 3 -> Station 0 (Left Paramedic position)
		if cur_step == 3 {
			if g.trampoline_pos == 0 {
				sm.play_bounce()
				g.score++
			} else {
				g.jumpers[i].crashed = true
				g.misses++
				sm.play_miss()
			}
		} else if cur_step == 7 {
			// Step 7 -> Station 1 (Middle Paramedic position)
			if g.trampoline_pos == 1 {
				sm.play_bounce()
				g.score++
			} else {
				g.jumpers[i].crashed = true
				g.misses++
				sm.play_miss()
			}
		} else if cur_step == 11 {
			// Step 11 -> Station 2 (Right Paramedic position)
			if g.trampoline_pos == 2 {
				sm.play_bounce()
				g.score++
			} else {
				g.jumpers[i].crashed = true
				g.misses++
				sm.play_miss()
			}
		} else if cur_step >= 13 {
			// Safely into the ambulance!
			g.score += 2
			g.jumpers[i].active = false
			sm.play_score()
		} else {
			sm.play_tick()
		}

		if g.score > g.high_score {
			g.high_score = g.score
		}

		if g.misses >= 3 {
			g.state = .game_over
			sm.play_game_over()
			break
		}

		i++
	}
}
