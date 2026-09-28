module main

import math
import rand

pub struct Particle {
pub mut:
	x          f64
	y          f64
	vx         f64
	vy         f64
	color      Color
	size       f64
	life       f64
	max_life   f64
	shape_type int // 0: spark, 1: circle/star, 2: confetti
	rot        f64
	vrot       f64
	gravity    f64
}

pub struct FloatingText {
pub mut:
	x        f64
	y        f64
	text     string
	color    Color
	scale    int
	life     f64
	max_life f64
	vy       f64
}

pub struct Shockwave {
pub mut:
	cx         f64
	cy         f64
	radius     f64
	max_radius f64
	color      Color
	life       f64
	max_life   f64
	thickness  f64
}

pub struct FlyingCard {
pub mut:
	card          Card
	is_face_up    bool
	start_x       f64
	start_y       f64
	target_x      f64
	target_y      f64
	x             f64
	y             f64
	progress      f64
	speed         f64
	flip_progress f64
}

pub struct PokerPlayer {
pub mut:
	name         string
	is_ai        bool
	chips        int = 1000
	current_bet  int
	hole_cards   []Card
	is_folded    bool
	is_all_in    bool
	avatar_col   Color
	last_action  string
	hand_score   HandScore
}

pub enum PokerStage {
	preflop
	flop
	turn
	river
	showdown
	round_over
}

pub struct TexasGame {
pub mut:
	players           []PokerPlayer
	community_cards   []Card
	deck              []Card
	pot               int
	current_bet       int // Current highest bet on the table this round
	min_raise         int = 20
	dealer_idx        int
	current_turn_idx  int = 1
	last_raiser_idx   int = -1
	stage             PokerStage = .preflop
	small_blind       int = 10
	big_blind         int = 20
	raise_amount      int = 40
	celebration       string
	celeb_timer       f64
	stage_timer       f64
	hand_count        int
	winner_indices    []int

	// VFX State
	particles       []Particle
	floating_texts  []FloatingText
	shockwaves      []Shockwave
	flying_cards    []FlyingCard
	shake_intensity f64
	shake_timer     f64
	anim_timer      f64
	pulse_time      f64
}

pub fn new_texas_game() TexasGame {
	mut game := TexasGame{
		players: [
			PokerPlayer{ name: 'You (P1)', is_ai: false, chips: 1000, avatar_col: Color{ r: 40, g: 140, b: 240 } },
			PokerPlayer{ name: 'Shark Sam', is_ai: true, chips: 1000, avatar_col: Color{ r: 240, g: 60, b: 70 } },
			PokerPlayer{ name: 'Rock Rachel', is_ai: true, chips: 1000, avatar_col: Color{ r: 70, g: 190, b: 90 } },
			PokerPlayer{ name: 'Pro Pete', is_ai: true, chips: 1000, avatar_col: Color{ r: 240, g: 180, b: 40 } },
		]
	}
	game.start_new_hand()
	return game
}

pub fn (mut g TexasGame) start_new_hand() {
	g.deck = generate_52_deck()
	shuffle_52_deck(mut g.deck)
	g.community_cards.clear()
	g.pot = 0
	g.current_bet = 0
	g.winner_indices.clear()
	g.celebration = ''
	g.hand_count++

	// Reset players
	for mut p in g.players {
		p.hole_cards.clear()
		p.current_bet = 0
		p.is_folded = p.chips <= 0
		p.is_all_in = false
		p.last_action = if p.chips <= 0 { 'OUT' } else { '' }
	}

	// Advance Dealer Button
	g.dealer_idx = (g.dealer_idx + 1) % g.players.len
	for g.players[g.dealer_idx].chips <= 0 {
		g.dealer_idx = (g.dealer_idx + 1) % g.players.len
	}

	// Deal 2 hole cards to each active player
	for mut p in g.players {
		if p.chips > 0 {
			p.hole_cards << g.deck.pop()
			p.hole_cards << g.deck.pop()
		}
	}

	// Post Small Blind
	sb_idx := g.get_next_active_player(g.dealer_idx)
	g.post_bet(sb_idx, g.small_blind)
	g.players[sb_idx].last_action = 'SB (\$${g.small_blind})'

	// Post Big Blind
	bb_idx := g.get_next_active_player(sb_idx)
	g.post_bet(bb_idx, g.big_blind)
	g.players[bb_idx].last_action = 'BB (\$${g.big_blind})'

	g.current_bet = g.big_blind
	g.min_raise = g.big_blind * 2
	g.raise_amount = g.current_bet + g.big_blind
	g.last_raiser_idx = bb_idx

	// Action starts on player after Big Blind
	g.current_turn_idx = g.get_next_active_player(bb_idx)
	g.stage = .preflop
	g.stage_timer = 0.0
}

fn (mut g TexasGame) post_bet(p_idx int, amount int) int {
	mut p := &g.players[p_idx]
	actual := if p.chips < amount { p.chips } else { amount }
	p.chips -= actual
	p.current_bet += actual
	g.pot += actual
	if p.chips == 0 {
		p.is_all_in = true
	}
	return actual
}

pub fn (g &TexasGame) get_next_active_player(from_idx int) int {
	mut idx := (from_idx + 1) % g.players.len
	for i := 0; i < g.players.len; i++ {
		if !g.players[idx].is_folded && g.players[idx].chips > 0 {
			return idx
		}
		idx = (idx + 1) % g.players.len
	}
	return from_idx
}

pub fn (g &TexasGame) count_active_unfolded() int {
	mut c := 0
	for p in g.players {
		if !p.is_folded {
			c++
		}
	}
	return c
}

pub fn (mut g TexasGame) player_action_fold(p_idx int, mut sound_mgr SoundManager) {
	mut p := &g.players[p_idx]
	p.is_folded = true
	p.last_action = 'FOLD'
	sound_mgr.play_fold()

	if g.count_active_unfolded() <= 1 {
		g.award_pot_to_last_standing(mut sound_mgr)
		return
	}
	g.advance_betting_turn(mut sound_mgr)
}

pub fn (mut g TexasGame) player_action_check_call(p_idx int, mut sound_mgr SoundManager) {
	mut p := &g.players[p_idx]
	to_call := g.current_bet - p.current_bet

	if to_call == 0 {
		p.last_action = 'CHECK'
		sound_mgr.play_check_tap()
	} else {
		g.post_bet(p_idx, to_call)
		p.last_action = 'CALL ($$${to_call})'
		sound_mgr.play_chip_bet()
	}

	g.advance_betting_turn(mut sound_mgr)
}

pub fn (mut g TexasGame) player_action_raise(p_idx int, total_bet int, mut sound_mgr SoundManager) {
	mut p := &g.players[p_idx]
	delta := total_bet - p.current_bet
	if delta <= 0 {
		return
	}

	g.post_bet(p_idx, delta)
	g.current_bet = p.current_bet
	g.min_raise = g.current_bet + g.big_blind
	g.last_raiser_idx = p_idx
	p.last_action = 'RAISE TO $$${g.current_bet}'

	if p.is_all_in {
		p.last_action = 'ALL-IN ($$${p.current_bet})'
		sound_mgr.play_all_in()
	} else {
		sound_mgr.play_chip_bet()
	}

	g.advance_betting_turn(mut sound_mgr)
}

pub fn (mut g TexasGame) advance_betting_turn(mut sound_mgr SoundManager) {
	// Find next eligible player who needs to act
	next_idx := g.get_next_active_player(g.current_turn_idx)

	// Check if betting round is complete (all non-folded players matched current_bet or all-in)
	mut round_complete := true
	for p in g.players {
		if !p.is_folded && !p.is_all_in {
			if p.current_bet != g.current_bet || p.last_action == '' {
				round_complete = false
				break
			}
		}
	}

	if round_complete || next_idx == g.last_raiser_idx {
		g.advance_street_stage(mut sound_mgr)
	} else {
		g.current_turn_idx = next_idx
		g.stage_timer = 0.0
	}
}

fn (mut g TexasGame) advance_street_stage(mut sound_mgr SoundManager) {
	// Reset current bets for the next street
	for mut p in g.players {
		p.current_bet = 0
		if !p.is_folded && !p.is_all_in {
			p.last_action = ''
		}
	}
	g.current_bet = 0
	g.min_raise = g.big_blind
	g.raise_amount = g.big_blind

	match g.stage {
		.preflop {
			// Deal Flop (3 cards)
			g.community_cards << g.deck.pop()
			g.community_cards << g.deck.pop()
			g.community_cards << g.deck.pop()
			g.stage = .flop
			sound_mgr.play_card_deal()
		}
		.flop {
			// Deal Turn (1 card)
			g.community_cards << g.deck.pop()
			g.stage = .turn
			sound_mgr.play_card_deal()
		}
		.turn {
			// Deal River (1 card)
			g.community_cards << g.deck.pop()
			g.stage = .river
			sound_mgr.play_card_deal()
		}
		.river {
			// Showdown!
			g.resolve_showdown(mut sound_mgr)
			return
		}
		else {}
	}

	g.current_turn_idx = g.get_next_active_player(g.dealer_idx)
	g.last_raiser_idx = g.current_turn_idx
	g.stage_timer = 0.0
}

fn (mut g TexasGame) award_pot_to_last_standing(mut sound_mgr SoundManager) {
	for i, p in g.players {
		if !p.is_folded {
			g.players[i].chips += g.pot
			g.celebration = '${p.name.to_upper()} WINS $$${g.pot} (ALL FOLDED)'
			g.winner_indices = [i]
			break
		}
	}
	g.pot = 0
	g.stage = .round_over
	g.stage_timer = 0.0
	sound_mgr.play_pot_win()
}

fn (mut g TexasGame) resolve_showdown(mut sound_mgr SoundManager) {
	g.stage = .showdown
	g.winner_indices.clear()

	// Evaluate all active players' hands
	mut best_score := i64(0)
	for i in 0 .. g.players.len {
		if !g.players[i].is_folded {
			mut all_cards := g.players[i].hole_cards.clone()
			for c in g.community_cards {
				all_cards << c
			}
			score := evaluate_7card_hand(all_cards)
			g.players[i].hand_score = score
			if score.score_val > best_score {
				best_score = score.score_val
			}
		}
	}

	// Identify winners
	for i in 0 .. g.players.len {
		if !g.players[i].is_folded && g.players[i].hand_score.score_val == best_score {
			g.winner_indices << i
		}
	}

	// Split pot among winners
	if g.winner_indices.len > 0 {
		split_amount := g.pot / g.winner_indices.len
		for w_idx in g.winner_indices {
			g.players[w_idx].chips += split_amount
		}

		w_name := g.players[g.winner_indices[0]].name
		h_name := g.players[g.winner_indices[0]].hand_score.name
		g.celebration = '${w_name.to_upper()} WINS $$${g.pot} WITH ${h_name.to_upper()}!'
		g.pot = 0
		sound_mgr.play_pot_win()
	}

	g.stage = .round_over
	g.stage_timer = 0.0
}

pub fn (mut g TexasGame) trigger_shake(intensity f64, duration f64) {
	g.shake_intensity = intensity
	g.shake_timer = duration
}

pub fn (mut g TexasGame) spawn_sparks(x f64, y f64, count int, col Color) {
	for _ in 0 .. count {
		angle := rand.f64() * math.pi * 2.0
		speed := 40.0 + rand.f64() * 160.0
		g.particles << Particle{
			x:          x
			y:          y
			vx:         math.cos(angle) * speed
			vy:         math.sin(angle) * speed
			color:      col
			size:       2.0 + rand.f64() * 3.0
			life:       0.0
			max_life:   0.35 + rand.f64() * 0.35
			shape_type: 0
			rot:        rand.f64() * 6.28
			vrot:       (rand.f64() - 0.5) * 10.0
			gravity:    120.0
		}
	}
}

pub fn (mut g TexasGame) spawn_confetti(x f64, y f64, count int) {
	cols := [
		Color{ r: 255, g: 215, b: 0 },
		Color{ r: 255, g: 60, b: 60 },
		Color{ r: 50, g: 150, b: 255 },
		Color{ r: 60, g: 255, b: 120 },
		Color{ r: 255, g: 120, b: 240 },
		Color{ r: 255, g: 255, b: 255 },
	]
	for _ in 0 .. count {
		angle := rand.f64() * math.pi * 2.0
		speed := 60.0 + rand.f64() * 240.0
		col_idx := rand.int_in_range(0, cols.len) or { 0 }
		g.particles << Particle{
			x:          x + (rand.f64() - 0.5) * 40.0
			y:          y + (rand.f64() - 0.5) * 40.0
			vx:         math.cos(angle) * speed
			vy:         math.sin(angle) * speed - 100.0
			color:      cols[col_idx]
			size:       4.0 + rand.f64() * 4.0
			life:       0.0
			max_life:   1.3 + rand.f64() * 1.0
			shape_type: 2
			rot:        rand.f64() * 6.28
			vrot:       (rand.f64() - 0.5) * 8.0
			gravity:    100.0
		}
	}
}

pub fn (mut g TexasGame) spawn_shockwave(cx f64, cy f64, col Color) {
	g.shockwaves << Shockwave{
		cx:         cx
		cy:         cy
		radius:     10.0
		max_radius: 120.0
		color:      col
		life:       0.0
		max_life:   0.45
		thickness:  3.0
	}
}

pub fn (mut g TexasGame) spawn_floating_text(x f64, y f64, text string, col Color, scale int) {
	g.floating_texts << FloatingText{
		x:        x
		y:        y
		text:     text
		color:    col
		scale:    scale
		life:     0.0
		max_life: 1.6
		vy:       -26.0
	}
}

pub fn (mut g TexasGame) spawn_flying_card(c Card, sx f64, sy f64, tx f64, ty f64, face_up bool) {
	g.flying_cards << FlyingCard{
		card:          c
		is_face_up:    face_up
		start_x:       sx
		start_y:       sy
		target_x:      tx
		target_y:      ty
		x:             sx
		y:             sy
		progress:      0.0
		speed:         4.0
		flip_progress: 0.0
	}
}

pub fn (mut g TexasGame) update(dt f64, mut sound_mgr SoundManager) {
	g.anim_timer += dt
	g.pulse_time += dt

	if g.shake_timer > 0.0 {
		g.shake_timer -= dt
		if g.shake_timer <= 0.0 {
			g.shake_intensity = 0.0
		}
	}

	for mut p in g.particles {
		p.life += dt
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.vy += p.gravity * dt
		p.rot += p.vrot * dt
		p.vx *= (1.0 - 0.5 * dt)
	}
	g.particles = g.particles.filter(it.life < it.max_life)

	for mut sw in g.shockwaves {
		sw.life += dt
		prog := sw.life / sw.max_life
		sw.radius = 10.0 + (sw.max_radius - 10.0) * math.sin(prog * math.pi * 0.5)
	}
	g.shockwaves = g.shockwaves.filter(it.life < it.max_life)

	for mut ft in g.floating_texts {
		ft.life += dt
		ft.y += ft.vy * dt
		ft.vy *= (1.0 - 0.8 * dt)
	}
	g.floating_texts = g.floating_texts.filter(it.life < it.max_life)

	for mut fc in g.flying_cards {
		fc.progress += fc.speed * dt
		if fc.progress > 1.0 {
			fc.progress = 1.0
		}
		t := fc.progress
		ease := 1.0 - math.pow(1.0 - t, 3.0)
		fc.x = fc.start_x + (fc.target_x - fc.start_x) * ease
		fc.y = fc.start_y + (fc.target_y - fc.start_y) * ease
		fc.flip_progress = t
	}
	g.flying_cards = g.flying_cards.filter(it.progress < 1.0)

	if g.celeb_timer > 0.0 {
		g.celeb_timer -= dt
		if g.celeb_timer <= 0.0 {
			g.celebration = ''
		}
	}

	match g.stage {
		.round_over {
			g.stage_timer += dt
			if g.stage_timer >= 4.0 {
				g.start_new_hand()
			}
		}
		.preflop, .flop, .turn, .river {
			cur_p := &g.players[g.current_turn_idx]
			if cur_p.is_ai && !cur_p.is_folded && !cur_p.is_all_in {
				g.stage_timer += dt
				if g.stage_timer >= 0.8 {
					g.process_ai_decision(g.current_turn_idx, mut sound_mgr)
				}
			}
		}
		else {}
	}
}

fn (mut g TexasGame) process_ai_decision(p_idx int, mut sound_mgr SoundManager) {
	p := &g.players[p_idx]
	to_call := g.current_bet - p.current_bet

	// Simple heuristic AI
	r := rand.int_in_range(0, 100) or { 50 }

	if to_call == 0 {
		// Can check for free, 25% chance of bet
		if r < 25 && p.chips > g.big_blind * 2 {
			g.player_action_raise(p_idx, g.current_bet + g.big_blind, mut sound_mgr)
		} else {
			g.player_action_check_call(p_idx, mut sound_mgr)
		}
	} else {
		// To call > 0
		if to_call > p.chips / 2 && r < 40 {
			// Fold big bets if low confidence
			g.player_action_fold(p_idx, mut sound_mgr)
		} else if r < 75 || to_call <= g.big_blind {
			g.player_action_check_call(p_idx, mut sound_mgr)
		} else if r >= 75 && p.chips >= g.current_bet + g.big_blind * 2 {
			g.player_action_raise(p_idx, g.current_bet + g.big_blind * 2, mut sound_mgr)
		} else {
			g.player_action_fold(p_idx, mut sound_mgr)
		}
	}
}
