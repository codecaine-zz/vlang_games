module main

import math
import rand

pub enum DartsGameType {
	x501
	x301
	cricket
	around_clock
}

pub enum ThrowPhase {
	aiming
	power_meter
	flying
	scored
	bust
	leg_won
}

pub struct DartHit {
pub mut:
	x         f64 // Board coordinate X (-board_radius to +board_radius)
	y         f64 // Board coordinate Y
	base_num  int // 1..20, or 25 for bullseye, 0 for miss
	multiplier int // 1: Single, 2: Double, 3: Triple
	score     int // base_num * multiplier
	is_bull   bool
	is_double_bull bool
	turn_idx  int // 0, 1, 2
}

pub struct DartsPlayer {
pub mut:
	name          string
	is_ai         bool
	score_left    int = 501
	start_score   int = 501
	legs_won      int
	darts_thrown  int
	current_turn  []DartHit
	turn_start_score int = 501
	// Cricket stats
	cricket_hits  map[int]int // 15..20, 25 -> hit count
	cricket_score int
	// Around the Clock
	atc_target    int = 1 // 1..20, 25
}

// 20-Segment Order clockwise from Top
pub const dart_segments = [
	20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5
]

// Dartboard Radii (in mm ratio or pixels)
pub const r_double_bull = 12.0 // 50 pts
pub const r_outer_bull  = 30.0 // 25 pts
pub const r_triple_in   = 95.0
pub const r_triple_out  = 112.0
pub const r_double_in   = 160.0
pub const r_double_out  = 180.0
pub const r_board_outer = 220.0

pub struct DartsGame {
pub mut:
	typ           DartsGameType = .x501
	phase         ThrowPhase    = .aiming
	players       []DartsPlayer
	current_p_idx int
	board_center_x f64 = 265.0
	board_center_y f64 = 300.0
	aim_x         f64 = 265.0
	aim_y         f64 = 195.0
	wobble_x      f64
	wobble_y      f64
	wobble_t      f64
	power         f64 = 0.5
	power_dir     f64 = 1.0
	state_timer   f64
	celebration   string
	celeb_timer   f64
	ai_diff       int = 1 // 0: Casual, 1: League Player, 2: World Champion
	checkout_hint string
}

pub fn new_darts_game() DartsGame {
	mut game := DartsGame{
		typ: .x501
		phase: .aiming
		players: [
			DartsPlayer{ name: 'Player 1', is_ai: false, score_left: 501, turn_start_score: 501 }
		]
		current_p_idx: 0
		board_center_x: 265.0
		board_center_y: 300.0
		aim_x: 265.0
		aim_y: 195.0 // Aim near Triple 20 (300 - 105)
	}
	game.update_checkout_hint()
	return game
}

pub fn (mut g DartsGame) set_game_type(typ DartsGameType, is_2p bool, is_ai bool) {
	g.typ = typ
	g.players.clear()
	start_score := match typ {
		.x501 { 501 }
		.x301 { 301 }
		else { 0 }
	}

	g.players << DartsPlayer{
		name: 'Player 1'
		is_ai: false
		score_left: start_score
		start_score: start_score
		turn_start_score: start_score
		atc_target: 1
	}

	if is_ai {
		g.players << DartsPlayer{
			name: 'CPU Phil'
			is_ai: true
			score_left: start_score
			start_score: start_score
			turn_start_score: start_score
			atc_target: 1
		}
	} else if is_2p {
		g.players << DartsPlayer{
			name: 'Player 2'
			is_ai: false
			score_left: start_score
			start_score: start_score
			turn_start_score: start_score
			atc_target: 1
		}
	}

	g.current_p_idx = 0
	g.phase = .aiming
	g.celebration = ''
	g.update_checkout_hint()
}

// Convert (x, y) relative to board center into DartHit sector
pub fn calculate_dart_hit(rel_x f64, rel_y f64) DartHit {
	dist := math.sqrt(rel_x * rel_x + rel_y * rel_y)

	// Off the board miss
	if dist > r_double_out {
		return DartHit{ x: rel_x, y: rel_y, base_num: 0, multiplier: 0, score: 0 }
	}

	// Double Bullseye (50)
	if dist <= r_double_bull {
		return DartHit{ x: rel_x, y: rel_y, base_num: 25, multiplier: 2, score: 50, is_bull: true, is_double_bull: true }
	}

	// Single Outer Bullseye (25)
	if dist <= r_outer_bull {
		return DartHit{ x: rel_x, y: rel_y, base_num: 25, multiplier: 1, score: 25, is_bull: true, is_double_bull: false }
	}

	// Calculate angle in degrees (0 is Top 20)
	// Math.atan2 gives 0 along +X (Right, 6). We want 0 at -Y (Top, 20).
	mut angle := math.atan2(rel_y, rel_x) + math.pi / 2.0
	if angle < 0.0 {
		angle += 2.0 * math.pi
	}

	// 20 segments, each 18 degrees (pi / 10 radians)
	// Top segment is centered at 0, so offset by 9 degrees (pi / 20)
	mut seg_angle := angle + (math.pi / 20.0)
	if seg_angle >= 2.0 * math.pi {
		seg_angle -= 2.0 * math.pi
	}

	seg_idx := int(seg_angle / (math.pi / 10.0)) % 20
	base_num := dart_segments[seg_idx]

	// Determine multiplier based on radius
	if dist >= r_double_in && dist <= r_double_out {
		return DartHit{ x: rel_x, y: rel_y, base_num: base_num, multiplier: 2, score: base_num * 2 }
	} else if dist >= r_triple_in && dist <= r_triple_out {
		return DartHit{ x: rel_x, y: rel_y, base_num: base_num, multiplier: 3, score: base_num * 3 }
	} else {
		return DartHit{ x: rel_x, y: rel_y, base_num: base_num, multiplier: 1, score: base_num }
	}
}

pub fn (mut g DartsGame) throw_dart(mut sound_mgr SoundManager) {
	// Calculate scatter based on power release accuracy & AI difficulty
	power_offset := (g.power - 0.5) * 28.0
	scatter_radius := if g.players[g.current_p_idx].is_ai {
		match g.ai_diff {
			0 { 24.0 } // Casual
			1 { 12.0 } // League
			else { 5.0 } // World champ
		}
	} else {
		math.abs(g.power - 0.5) * 45.0 + 4.0
	}

	final_x := (g.aim_x + g.wobble_x - g.board_center_x) + (rand.f64() * scatter_radius * 2.0 - scatter_radius)
	final_y := (g.aim_y + g.wobble_y - g.board_center_y) + power_offset + (rand.f64() * scatter_radius * 2.0 - scatter_radius)

	hit := calculate_dart_hit(final_x, final_y)

	mut p := &g.players[g.current_p_idx]
	p.current_turn << hit
	p.darts_thrown++

	// Audio & score processing
	if hit.is_double_bull || hit.is_bull {
		sound_mgr.play_bullseye()
	} else if hit.multiplier >= 2 {
		sound_mgr.play_multiplier(hit.multiplier)
	} else {
		sound_mgr.play_thud()
	}

	match g.typ {
		.x501, .x301 {
			g.process_x01_hit(hit, mut sound_mgr)
		}
		.cricket {
			g.process_cricket_hit(hit, mut sound_mgr)
		}
		.around_clock {
			g.process_atc_hit(hit, mut sound_mgr)
		}
	}

	g.update_checkout_hint()
}

fn (mut g DartsGame) process_x01_hit(hit DartHit, mut sound_mgr SoundManager) {
	mut p := &g.players[g.current_p_idx]
	new_score := p.score_left - hit.score

	if new_score == 0 && (hit.multiplier == 2 || hit.is_double_bull) {
		// Double Out Victory!
		p.score_left = 0
		p.legs_won++
		g.celebration = 'LEG WON! CHECKOUT!'
		sound_mgr.play_180_fanfare()
		g.phase = .leg_won
		g.state_timer = 0.0
	} else if new_score <= 1 {
		// BUST! (Score went below 0 or left at 1, which cannot double-out)
		p.score_left = p.turn_start_score
		g.celebration = 'BUST!'
		sound_mgr.play_bust()
		g.phase = .bust
		g.state_timer = 0.0
	} else {
		// Valid throw
		p.score_left = new_score
		g.phase = .scored
		g.state_timer = 0.0

		// Check for 180 (three T20s in one turn)
		if p.current_turn.len == 3 {
			turn_sum := p.current_turn[0].score + p.current_turn[1].score + p.current_turn[2].score
			if turn_sum == 180 {
				g.celebration = 'ONE HUNDRED AND EIGHTY!!'
				sound_mgr.play_180_fanfare()
			}
		}
	}
}

fn (mut g DartsGame) process_cricket_hit(hit DartHit, mut sound_mgr SoundManager) {
	mut p := &g.players[g.current_p_idx]
	num := hit.base_num

	if (num >= 15 && num <= 20) || num == 25 {
		cur_hits := p.cricket_hits[num]
		added_hits := hit.multiplier
		new_hits := cur_hits + added_hits
		p.cricket_hits[num] = math.min(3, new_hits)

		// If player already has 3 hits, any surplus scores points IF opponent hasn't closed it
		if cur_hits >= 3 {
			p.cricket_score += num * added_hits
			sound_mgr.play_multiplier(added_hits)
		} else if new_hits > 3 {
			surplus := new_hits - 3
			p.cricket_score += num * surplus
			sound_mgr.play_multiplier(surplus)
		}
	}
	g.phase = .scored
	g.state_timer = 0.0
}

fn (mut g DartsGame) process_atc_hit(hit DartHit, mut sound_mgr SoundManager) {
	mut p := &g.players[g.current_p_idx]
	if hit.base_num == p.atc_target {
		if p.atc_target == 20 {
			p.atc_target = 25 // Final Bullseye
			sound_mgr.play_multiplier(2)
		} else if p.atc_target == 25 {
			// Won Around the Clock!
			g.celebration = 'VICTORY! ROUND CLEARED!'
			sound_mgr.play_180_fanfare()
			g.phase = .leg_won
			g.state_timer = 0.0
			return
		} else {
			p.atc_target++
			sound_mgr.play_multiplier(1)
		}
	}
	g.phase = .scored
	g.state_timer = 0.0
}

pub fn (mut g DartsGame) update(dt f64, mut sound_mgr SoundManager) {
	// Update wobble breathing physics
	g.wobble_t += dt * 3.5
	wobble_amp := if g.players[g.current_p_idx].is_ai { 2.0 } else { 8.0 }
	g.wobble_x = math.sin(g.wobble_t) * wobble_amp + math.cos(g.wobble_t * 1.7) * 4.0
	g.wobble_y = math.cos(g.wobble_t * 1.3) * wobble_amp + math.sin(g.wobble_t * 2.1) * 4.0

	// Celebration timer
	if g.celeb_timer > 0.0 {
		g.celeb_timer -= dt
		if g.celeb_timer <= 0.0 {
			g.celebration = ''
		}
	}

	match g.phase {
		.aiming {
			if g.players[g.current_p_idx].is_ai {
				g.update_ai_aim(dt, mut sound_mgr)
			}
		}
		.power_meter {
			if !g.players[g.current_p_idx].is_ai {
				g.power += g.power_dir * 2.2 * dt
				if g.power > 1.0 {
					g.power = 1.0
					g.power_dir = -1.0
				} else if g.power < 0.0 {
					g.power = 0.0
					g.power_dir = 1.0
				}
			} else {
				g.power = 0.5 + (rand.f64() * 0.08 - 0.04)
				g.throw_dart(mut sound_mgr)
			}
		}
		.scored, .bust {
			g.state_timer += dt
			if g.state_timer > 1.2 {
				g.advance_throw()
			}
		}
		.leg_won {
			g.state_timer += dt
			if g.state_timer > 2.5 {
				g.reset_leg()
			}
		}
		else {}
	}
}

fn (mut g DartsGame) advance_throw() {
	mut p := &g.players[g.current_p_idx]

	if g.phase == .bust || p.current_turn.len >= 3 {
		// End of 3-dart turn
		p.current_turn.clear()
		p.turn_start_score = p.score_left

		if g.players.len > 1 {
			g.current_p_idx = (g.current_p_idx + 1) % g.players.len
		}
	}

	g.phase = .aiming
	g.update_checkout_hint()
}

fn (mut g DartsGame) reset_leg() {
	start_score := match g.typ {
		.x501 { 501 }
		.x301 { 301 }
		else { 0 }
	}
	for mut p in g.players {
		p.score_left = start_score
		p.turn_start_score = start_score
		p.current_turn.clear()
		p.atc_target = 1
	}
	g.phase = .aiming
	g.celebration = ''
	g.update_checkout_hint()
}

pub fn (mut g DartsGame) update_checkout_hint() {
	p := g.players[g.current_p_idx]
	rem := p.score_left

	g.checkout_hint = match rem {
		170 { 'T20 -> T20 -> BULL' }
		167 { 'T20 -> T19 -> BULL' }
		164 { 'T20 -> T18 -> BULL' }
		161 { 'T20 -> T17 -> BULL' }
		160 { 'T20 -> T20 -> D20' }
		140 { 'T20 -> T20 -> D10' }
		121 { 'T20 -> T15 -> D8' }
		100 { 'T20 -> D20' }
		80  { 'T20 -> D10' }
		60  { 'S20 -> D20' }
		50  { 'BULLSEYE' }
		40  { 'DOUBLE 20' }
		32  { 'DOUBLE 16' }
		24  { 'DOUBLE 12' }
		16  { 'DOUBLE 8' }
		8   { 'DOUBLE 4' }
		4   { 'DOUBLE 2' }
		2   { 'DOUBLE 1' }
		else {
			if rem <= 40 && rem % 2 == 0 {
				'DOUBLE ${rem / 2}'
			} else {
				''
			}
		}
	}
}

// AI Aiming
fn (mut g DartsGame) update_ai_aim(dt f64, mut _ SoundManager) {
	p := g.players[g.current_p_idx]

	// Determine ideal target coordinate
	mut target_x := g.board_center_x
	mut target_y := g.board_center_y - 105.0 // Triple 20 by default

	if g.typ == .x501 || g.typ == .x301 {
		if p.score_left <= 40 && p.score_left % 2 == 0 {
			// Aim for specific double
			d_num := p.score_left / 2
			target_x, target_y = g.get_board_coord(d_num, 2)
		} else if p.score_left == 50 {
			target_x = g.board_center_x
			target_y = g.board_center_y
		}
	}

	dx := target_x - g.aim_x
	dy := target_y - g.aim_y
	dist := math.sqrt(dx * dx + dy * dy)

	if dist > 3.0 {
		g.aim_x += (dx / dist) * 160.0 * dt
		g.aim_y += (dy / dist) * 160.0 * dt
	} else {
		g.phase = .power_meter
	}
}

pub fn (g &DartsGame) get_board_coord(num int, ring int) (f64, f64) {
	for idx, s in dart_segments {
		if s == num {
			angle := (f64(idx) * math.pi / 10.0) - math.pi / 2.0
			r := match ring {
				2 { (r_double_in + r_double_out) * 0.5 }
				3 { (r_triple_in + r_triple_out) * 0.5 }
				else { (r_outer_bull + r_triple_in) * 0.5 }
			}
			return g.board_center_x + math.cos(angle) * r, g.board_center_y + math.sin(angle) * r
		}
	}
	return g.board_center_x, g.board_center_y
}
