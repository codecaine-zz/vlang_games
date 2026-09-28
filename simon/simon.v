module main

import rand

pub enum SimonMode {
	classic
	reverse
	speed
}

pub enum SimonState {
	attract
	playback
	player_turn
	round_success
	game_over
}

pub struct SimonGame {
pub mut:
	mode               SimonMode  = .classic
	state              SimonState = .attract
	sequence           []int
	player_step        int
	lit_pad            int = -1 // -1 = none, 0..3 = active lit pad
	playback_idx       int
	timer              f64
	step_duration      f64 = 0.45
	gap_duration       f64 = 0.15
	is_gap             bool
	score              int
	high_score_classic int
	high_score_reverse int
	high_score_speed   int
	last_mistake_pad   int = -1
	streak             int
	reaction_timer     f64
}

pub fn new_simon_game() SimonGame {
	mut g := SimonGame{}
	g.reset_game()
	return g
}

pub fn (mut g SimonGame) reset_game() {
	g.sequence.clear()
	g.player_step = 0
	g.lit_pad = -1
	g.playback_idx = 0
	g.timer = 0.0
	g.score = 0
	g.state = .attract
	g.last_mistake_pad = -1
	g.streak = 0
}

pub fn (mut g SimonGame) start_new_game() {
	g.sequence.clear()
	g.score = 0
	g.streak = 0
	g.last_mistake_pad = -1
	g.add_step()
	g.start_playback()
}

pub fn (mut g SimonGame) add_step() {
	next_pad := rand.intn(4) or { 0 }
	g.sequence << next_pad
}

pub fn (mut g SimonGame) start_playback() {
	g.state = .playback
	g.playback_idx = 0
	g.lit_pad = -1
	g.is_gap = true
	g.timer = 0.4 // Initial delay before playing

	// Calculate playback tempo based on mode & sequence length
	match g.mode {
		.classic {
			g.step_duration = 0.42
			g.gap_duration = 0.12
		}
		.reverse {
			g.step_duration = 0.45
			g.gap_duration = 0.14
		}
		.speed {
			speed_factor := 1.0 / (1.0 + f64(g.sequence.len) * 0.08)
			g.step_duration = 0.38 * speed_factor
			g.gap_duration = 0.10 * speed_factor
		}
	}
}

pub struct SimonEvents {
pub mut:
	pad_tone    int = -1
	pad_dur     f64 = 0.35
	error_buzz  bool
	round_clear bool
}

pub fn (mut g SimonGame) update(dt f64) SimonEvents {
	mut ev := SimonEvents{}

	match g.state {
		.attract {
			// Idle attract mode
		}
		.playback {
			g.timer -= dt
			if g.timer <= 0.0 {
				if g.is_gap {
					if g.playback_idx < g.sequence.len {
						// Light up current step
						g.lit_pad = g.sequence[g.playback_idx]
						g.is_gap = false
						g.timer = g.step_duration
						ev.pad_tone = g.lit_pad
						ev.pad_dur = g.step_duration
						g.playback_idx++
					} else {
						// Finished sequence playback -> hand over to player
						g.lit_pad = -1
						g.state = .player_turn
						g.player_step = 0
						g.reaction_timer = 0.0
					}
				} else {
					// Gap between tones
					g.lit_pad = -1
					g.is_gap = true
					g.timer = g.gap_duration
				}
			}
		}
		.player_turn {
			g.reaction_timer += dt
			if g.lit_pad >= 0 {
				g.timer -= dt
				if g.timer <= 0.0 {
					g.lit_pad = -1
				}
			}
		}
		.round_success {
			g.timer -= dt
			if g.timer <= 0.0 {
				g.add_step()
				g.start_playback()
			}
		}
		.game_over {
			// Awaiting restart
		}
	}

	return ev
}

pub fn (mut g SimonGame) handle_pad_press(pad_idx int) (bool, SimonEvents) {
	mut ev := SimonEvents{}
	if g.state != .player_turn {
		return false, ev
	}

	// Light up selected pad
	g.lit_pad = pad_idx
	g.timer = 0.28
	ev.pad_tone = pad_idx
	ev.pad_dur = 0.28

	// Expected pad based on mode
	expected_pad := if g.mode == .reverse {
		// In reverse mode, check backwards from end
		g.sequence[g.sequence.len - 1 - g.player_step]
	} else {
		g.sequence[g.player_step]
	}

	if pad_idx == expected_pad {
		g.player_step++
		if g.player_step >= g.sequence.len {
			// Successfully completed sequence!
			g.score = g.sequence.len
			g.streak++

			match g.mode {
				.classic {
					if g.score > g.high_score_classic { g.high_score_classic = g.score }
				}
				.reverse {
					if g.score > g.high_score_reverse { g.high_score_reverse = g.score }
				}
				.speed {
					if g.score > g.high_score_speed { g.high_score_speed = g.score }
				}
			}

			g.state = .round_success
			g.timer = 0.65
			ev.round_clear = true
		}
		return true, ev
	} else {
		// Mistake!
		g.state = .game_over
		g.last_mistake_pad = pad_idx
		ev.error_buzz = true
		return false, ev
	}
}

pub fn (mut g SimonGame) toggle_mode() {
	if g.state == .attract || g.state == .game_over {
		g.mode = match g.mode {
			.classic { .reverse }
			.reverse { .speed }
			.speed { .classic }
		}
	}
}
