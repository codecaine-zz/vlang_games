module main

import math
import rand

pub enum CardSuit {
	hearts
	diamonds
	clubs
	spades
}

pub struct Card {
pub mut:
	rank int // 1=Ace, 2..10, 11=J, 12=Q, 13=K
	suit CardSuit
}

pub struct Hand {
pub mut:
	cards      []Card
	bet        int
	is_doubled bool
	is_stand   bool
	is_busted  bool
	is_bj      bool
	is_surrender bool
}

pub enum BJState {
	betting
	player_turn
	dealer_turn
	round_over
}

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

pub struct BlackjackGame {
pub mut:
	shoe            []Card
	player_hands    []Hand
	active_hand_idx int
	dealer_hand     []Card
	dealer_hidden   bool = true
	chips           int = 1000
	current_bet     int = 25
	last_payout     int
	state           BJState = .betting
	insurance_bet   int
	insurance_avail bool
	dealer_bj       bool
	celebration     string
	celeb_timer     f64
	state_timer     f64
	// Stats
	hands_played    int
	hands_won       int
	hands_lost      int
	hands_pushed    int
	blackjacks_hit  int

	// VFX State
	particles       []Particle
	floating_texts  []FloatingText
	shockwaves      []Shockwave
	flying_cards    []FlyingCard
	shake_intensity f64
	shake_timer     f64
	anim_timer      f64
	pulse_time      f64
	win_streak      int
}

pub fn new_blackjack_game() BlackjackGame {
	mut game := BlackjackGame{
		chips: 1000
		current_bet: 25
		state: .betting
	}
	game.init_shoe(4) // 4-deck shoe
	return game
}

pub fn (mut g BlackjackGame) init_shoe(num_decks int) {
	g.shoe.clear()
	suits := [CardSuit.hearts, CardSuit.diamonds, CardSuit.clubs, CardSuit.spades]
	for _ in 0 .. num_decks {
		for s in suits {
			for r := 1; r <= 13; r++ {
				g.shoe << Card{ rank: r, suit: s }
			}
		}
	}
	shuffle_shoe(mut g.shoe)
}

pub fn shuffle_shoe(mut shoe []Card) {
	for i := shoe.len - 1; i > 0; i-- {
		j := rand.int_in_range(0, i + 1) or { 0 }
		temp := shoe[i]
		shoe[i] = shoe[j]
		shoe[j] = temp
	}
}

pub fn (mut g BlackjackGame) draw_card() Card {
	if g.shoe.len < 20 {
		g.init_shoe(4)
	}
	return g.shoe.pop()
}

pub fn calculate_hand_value(cards []Card) (int, bool) {
	mut total := 0
	mut aces := 0

	for c in cards {
		if c.rank == 1 {
			aces++
			total += 11
		} else if c.rank >= 10 {
			total += 10
		} else {
			total += c.rank
		}
	}

	mut is_soft := false
	for total > 21 && aces > 0 {
		total -= 10
		aces--
	}

	if aces > 0 {
		is_soft = true
	}

	return total, is_soft
}

pub fn is_natural_blackjack(cards []Card) bool {
	if cards.len != 2 {
		return false
	}
	c1 := cards[0]
	c2 := cards[1]
	has_ace := c1.rank == 1 || c2.rank == 1
	has_ten := (c1.rank >= 10 && c1.rank <= 13) || (c2.rank >= 10 && c2.rank <= 13)
	return has_ace && has_ten
}

pub fn (mut g BlackjackGame) place_chip(amount int) {
	if g.state == .betting {
		if g.chips >= amount {
			g.current_bet += amount
		}
	}
}

pub fn (mut g BlackjackGame) clear_bet() {
	if g.state == .betting {
		g.current_bet = 0
	}
}

pub fn (mut g BlackjackGame) deal(mut sound_mgr SoundManager) {
	if g.state != .betting || g.current_bet <= 0 || g.chips < g.current_bet {
		return
	}

	g.chips -= g.current_bet
	g.player_hands.clear()
	g.dealer_hand.clear()
	g.insurance_bet = 0
	g.insurance_avail = false
	g.last_payout = 0
	g.celebration = ''
	g.hands_played++

	mut initial_hand := Hand{
		cards: []Card{cap: 10}
		bet: g.current_bet
	}

	// Deal 2 cards to player, 2 to dealer
	initial_hand.cards << g.draw_card()
	g.dealer_hand << g.draw_card()
	initial_hand.cards << g.draw_card()
	g.dealer_hand << g.draw_card()
	g.dealer_hidden = true

	g.player_hands << initial_hand
	g.active_hand_idx = 0

	sound_mgr.play_card_deal()

	// Check natural blackjack
	if is_natural_blackjack(g.player_hands[0].cards) {
		g.player_hands[0].is_bj = true
		g.player_hands[0].is_stand = true
		g.blackjacks_hit++
		// Reveal dealer and finish
		g.state = .dealer_turn
		g.state_timer = 0.0
		return
	}

	// Offer Insurance if dealer's upcard is Ace
	if g.dealer_hand[0].rank == 1 {
		g.insurance_avail = true
	}

	g.state = .player_turn
}

pub fn (mut g BlackjackGame) hit(mut sound_mgr SoundManager) {
	if g.state != .player_turn {
		return
	}

	mut hand := &g.player_hands[g.active_hand_idx]
	if hand.is_stand || hand.is_busted {
		return
	}

	hand.cards << g.draw_card()
	sound_mgr.play_card_deal()

	val, _ := calculate_hand_value(hand.cards)
	if val > 21 {
		hand.is_busted = true
		hand.is_stand = true
		sound_mgr.play_bust()
		g.advance_hand_or_dealer()
	} else if val == 21 {
		hand.is_stand = true
		g.advance_hand_or_dealer()
	}
}

pub fn (mut g BlackjackGame) stand(mut sound_mgr SoundManager) {
	if g.state != .player_turn {
		return
	}

	mut hand := &g.player_hands[g.active_hand_idx]
	hand.is_stand = true
	sound_mgr.play_stand_knock()
	g.advance_hand_or_dealer()
}

pub fn (mut g BlackjackGame) double_down(mut sound_mgr SoundManager) {
	if g.state != .player_turn {
		return
	}

	mut hand := &g.player_hands[g.active_hand_idx]
	if hand.cards.len != 2 || g.chips < hand.bet {
		return
	}

	g.chips -= hand.bet
	hand.bet *= 2
	hand.is_doubled = true

	// Receive exactly 1 card then stand
	hand.cards << g.draw_card()
	sound_mgr.play_card_deal()

	val, _ := calculate_hand_value(hand.cards)
	if val > 21 {
		hand.is_busted = true
		sound_mgr.play_bust()
	}
	hand.is_stand = true
	g.advance_hand_or_dealer()
}

pub fn (mut g BlackjackGame) split(mut sound_mgr SoundManager) {
	if g.state != .player_turn || g.player_hands.len >= 2 {
		return
	}

	mut hand := &g.player_hands[0]
	if hand.cards.len != 2 || g.chips < hand.bet {
		return
	}

	r1 := if hand.cards[0].rank >= 10 { 10 } else { hand.cards[0].rank }
	r2 := if hand.cards[1].rank >= 10 { 10 } else { hand.cards[1].rank }
	if r1 != r2 {
		return
	}

	g.chips -= hand.bet
	c2 := hand.cards.pop()

	mut hand2 := Hand{
		cards: [c2, g.draw_card()]
		bet: hand.bet
	}
	hand.cards << g.draw_card()

	g.player_hands << hand2
	sound_mgr.play_card_deal()
}

pub fn (mut g BlackjackGame) buy_insurance() {
	if g.state == .player_turn && g.insurance_avail && g.insurance_bet == 0 {
		ins_cost := g.current_bet / 2
		if g.chips >= ins_cost {
			g.chips -= ins_cost
			g.insurance_bet = ins_cost
			g.insurance_avail = false
		}
	}
}

fn (mut g BlackjackGame) advance_hand_or_dealer() {
	if g.active_hand_idx < g.player_hands.len - 1 {
		g.active_hand_idx++
	} else {
		g.state = .dealer_turn
		g.state_timer = 0.0
		g.dealer_hidden = false
	}
}

pub fn (mut g BlackjackGame) trigger_shake(intensity f64, duration f64) {
	g.shake_intensity = intensity
	g.shake_timer = duration
}

pub fn (mut g BlackjackGame) spawn_sparks(x f64, y f64, count int, col Color) {
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

pub fn (mut g BlackjackGame) spawn_confetti(x f64, y f64, count int) {
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

pub fn (mut g BlackjackGame) spawn_shockwave(cx f64, cy f64, col Color) {
	g.shockwaves << Shockwave{
		cx:         cx
		cy:         cy
		radius:     10.0
		max_radius: 110.0
		color:      col
		life:       0.0
		max_life:   0.45
		thickness:  3.0
	}
}

pub fn (mut g BlackjackGame) spawn_floating_text(x f64, y f64, text string, col Color, scale int) {
	g.floating_texts << FloatingText{
		x:        x
		y:        y
		text:     text
		color:    col
		scale:    scale
		life:     0.0
		max_life: 1.5
		vy:       -28.0
	}
}

pub fn (mut g BlackjackGame) spawn_flying_card(c Card, sx f64, sy f64, tx f64, ty f64, face_up bool) {
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
		speed:         3.8
		flip_progress: 0.0
	}
}

pub fn (mut g BlackjackGame) update(dt f64, mut sound_mgr SoundManager) {
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

	if g.state == .dealer_turn {
		g.state_timer += dt
		if g.state_timer >= 0.7 {
			g.state_timer = 0.0
			g.process_dealer_step(mut sound_mgr)
		}
	}
}

fn (mut g BlackjackGame) process_dealer_step(mut sound_mgr SoundManager) {
	g.dealer_hidden = false

	// Check if all player hands busted
	mut all_busted := true
	for h in g.player_hands {
		if !h.is_busted {
			all_busted = false
			break
		}
	}

	if all_busted {
		g.evaluate_round_payouts(mut sound_mgr)
		return
	}

	dealer_val, _ := calculate_hand_value(g.dealer_hand)

	// Dealer hits on 16 or less, stands on 17+
	if dealer_val < 17 {
		c := g.draw_card()
		g.dealer_hand << c
		g.spawn_flying_card(c, 700, 80, 400 + g.dealer_hand.len * 38, 60, true)
		sound_mgr.play_card_deal()
	} else {
		g.evaluate_round_payouts(mut sound_mgr)
	}
}

fn (mut g BlackjackGame) evaluate_round_payouts(mut sound_mgr SoundManager) {
	g.state = .round_over
	dealer_val, _ := calculate_hand_value(g.dealer_hand)
	dealer_bj := is_natural_blackjack(g.dealer_hand)
	mut total_won := 0
	mut win_count := 0
	mut loss_count := 0

	// Resolve Insurance
	if g.insurance_bet > 0 {
		if dealer_bj {
			ins_pay := g.insurance_bet * 3
			g.chips += ins_pay
			total_won += ins_pay
			g.spawn_floating_text(400, 240, 'INSURANCE PAYS +$$${ins_pay}!', Color{ r: 255, g: 215, b: 0 }, 1)
		}
	}

	for h_idx, h in g.player_hands {
		p_val, _ := calculate_hand_value(h.cards)
		hx := if g.player_hands.len == 1 { 400.0 } else { 280.0 + f64(h_idx) * 240.0 }

		if h.is_busted {
			loss_count++
			g.hands_lost++
			g.spawn_floating_text(hx, 320, 'BUST!', Color{ r: 255, g: 80, b: 80 }, 1)
		} else if h.is_bj {
			if dealer_bj {
				g.chips += h.bet
				total_won += h.bet
				g.hands_pushed++
				g.spawn_floating_text(hx, 320, 'PUSH (BOTH 21)', Color{ r: 200, g: 220, b: 255 }, 1)
			} else {
				payout := h.bet + int(f64(h.bet) * 1.5)
				g.chips += payout
				total_won += payout
				win_count++
				g.hands_won++
				g.trigger_shake(8.0, 0.45)
				g.spawn_confetti(hx, 320, 50)
				g.spawn_shockwave(hx, 320, Color{ r: 255, g: 215, b: 0 })
				g.spawn_floating_text(hx, 310, '★ BLACKJACK 21! +$$${payout} ★', Color{ r: 255, g: 230, b: 50 }, 1)
			}
		} else if dealer_val > 21 {
			payout := h.bet * 2
			g.chips += payout
			total_won += payout
			win_count++
			g.hands_won++
			g.spawn_sparks(hx, 320, 20, Color{ r: 100, g: 255, b: 150 })
			g.spawn_floating_text(hx, 320, 'DEALER BUSTS! +$$${payout}', Color{ r: 80, g: 255, b: 120 }, 1)
		} else if p_val > dealer_val {
			payout := h.bet * 2
			g.chips += payout
			total_won += payout
			win_count++
			g.hands_won++
			g.spawn_sparks(hx, 320, 20, Color{ r: 255, g: 215, b: 50 })
			g.spawn_floating_text(hx, 320, 'WIN! +$$${payout}', Color{ r: 255, g: 230, b: 70 }, 1)
		} else if p_val == dealer_val {
			g.chips += h.bet
			total_won += h.bet
			g.hands_pushed++
			g.spawn_floating_text(hx, 320, 'PUSH (TIE)', Color{ r: 200, g: 220, b: 255 }, 1)
		} else {
			loss_count++
			g.hands_lost++
			g.spawn_floating_text(hx, 320, 'DEALER TAKES HAND', Color{ r: 255, g: 120, b: 120 }, 1)
		}
	}

	g.last_payout = total_won

	if win_count > 0 {
		g.win_streak++
		if g.player_hands[0].is_bj && !dealer_bj {
			g.celebration = 'BLACKJACK 21!! PAYS 3:2 ($${total_won})'
			sound_mgr.play_blackjack_fanfare()
		} else {
			g.celebration = 'YOU WIN!! +$${total_won}'
			sound_mgr.play_win_payout()
		}
	} else {
		g.win_streak = 0
		if loss_count > 0 && win_count == 0 && total_won == 0 {
			g.celebration = 'DEALER WINS'
			sound_mgr.play_bust()
		} else {
			g.celebration = 'PUSH (TIE)'
		}
	}
	g.celeb_timer = 3.5
}
