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
	rank int // 2 .. 14 (11=J, 12=Q, 13=K, 14=A)
	suit CardSuit
}

pub enum WarPhase {
	ready
	flipping
	comparing
	war_declared
	war_flipping
	game_over
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
	shape_type int // 0: spark, 1: circle/star, 2: confetti rect
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
	flip_progress f64 // 0.0 -> 1.0 (0.5 is edge-on)
	purpose       int // 0: deal to duel, 1: war face-down, 2: win collect
	is_player     bool
}

pub struct WarGame {
pub mut:
	player_draw_pile []Card
	player_win_pile  []Card
	ai_draw_pile     []Card
	ai_win_pile      []Card
	battle_player    Card
	battle_ai        Card
	has_battle_card  bool
	war_pot          []Card
	phase            WarPhase = .ready
	round_winner     int      // 1: Player, 2: AI, 3: War tie
	phase_timer      f64
	round_count      int
	wars_fought      int
	auto_play        bool
	auto_speed       f64 = 0.6
	celebration      string
	celeb_timer      f64
	match_winner     int // 1: Player, 2: AI

	// Visual Effects & Animation State
	particles       []Particle
	floating_texts  []FloatingText
	shockwaves      []Shockwave
	flying_cards    []FlyingCard
	shake_intensity f64
	shake_timer     f64
	anim_timer      f64
	pulse_time      f64
	bob_mood        int // 0: neutral, 1: confident/happy, 2: worried/shocked, 3: raging war
	player_streak   int
	ai_streak       int
	highest_pot     int
	last_player_win bool
}

pub fn new_war_game() WarGame {
	mut game := WarGame{
		phase: .ready
	}
	game.start_new_match()
	return game
}

pub fn (mut g WarGame) start_new_match() {
	mut deck := generate_52_deck()
	shuffle_52_deck(mut deck)

	g.player_draw_pile.clear()
	g.player_win_pile.clear()
	g.ai_draw_pile.clear()
	g.ai_win_pile.clear()
	g.war_pot.clear()
	g.has_battle_card = false
	g.particles.clear()
	g.floating_texts.clear()
	g.shockwaves.clear()
	g.flying_cards.clear()

	// Deal 26 cards to each player
	for i := 0; i < 26; i++ {
		g.player_draw_pile << deck[i]
		g.ai_draw_pile << deck[i + 26]
	}

	g.phase = .ready
	g.round_count = 0
	g.wars_fought = 0
	g.match_winner = 0
	g.celebration = ''
	g.bob_mood = 0
	g.player_streak = 0
	g.ai_streak = 0
	g.highest_pot = 0
	g.shake_intensity = 0.0
	g.shake_timer = 0.0

	g.spawn_floating_text(400, 240, 'BATTLE COMMENCES! 52 CARDS DEALT', Color{ r: 255, g: 215, b: 0 }, 1)
}

pub fn generate_52_deck() []Card {
	mut deck := []Card{cap: 52}
	suits := [CardSuit.hearts, CardSuit.diamonds, CardSuit.clubs, CardSuit.spades]
	for s in suits {
		for r := 2; r <= 14; r++ {
			deck << Card{ rank: r, suit: s }
		}
	}
	return deck
}

pub fn shuffle_52_deck(mut deck []Card) {
	for i := deck.len - 1; i > 0; i-- {
		j := rand.int_in_range(0, i + 1) or { 0 }
		temp := deck[i]
		deck[i] = deck[j]
		deck[j] = temp
	}
}

pub fn (g &WarGame) get_player_total_cards() int {
	return g.player_draw_pile.len + g.player_win_pile.len
}

pub fn (g &WarGame) get_ai_total_cards() int {
	return g.ai_draw_pile.len + g.ai_win_pile.len
}

// Recycle win pile into draw pile if draw pile is depleted
fn (mut g WarGame) recycle_player_deck() {
	if g.player_draw_pile.len == 0 && g.player_win_pile.len > 0 {
		g.player_draw_pile = g.player_win_pile.clone()
		g.player_win_pile.clear()
		shuffle_52_deck(mut g.player_draw_pile)
		g.spawn_floating_text(135, 430, 'DECK RECYCLED & SHUFFLED!', Color{ r: 100, g: 200, b: 255 }, 1)
	}
}

fn (mut g WarGame) recycle_ai_deck() {
	if g.ai_draw_pile.len == 0 && g.ai_win_pile.len > 0 {
		g.ai_draw_pile = g.ai_win_pile.clone()
		g.ai_win_pile.clear()
		shuffle_52_deck(mut g.ai_draw_pile)
		g.spawn_floating_text(135, 120, 'BOB RECYCLES FORCES!', Color{ r: 255, g: 150, b: 150 }, 1)
	}
}

pub fn (mut g WarGame) step_battle(mut sound_mgr SoundManager) {
	if g.phase != .ready && g.phase != .comparing {
		return
	}

	g.recycle_player_deck()
	g.recycle_ai_deck()

	// Check victory
	if g.player_draw_pile.len == 0 {
		g.match_winner = 2
		g.phase = .game_over
		g.celebration = 'GENERAL BOB WINS THE WAR!!'
		g.bob_mood = 1
		g.trigger_shake(8.0, 0.6)
		g.spawn_sparks(400, 300, 60, Color{ r: 255, g: 50, b: 50 })
		return
	}
	if g.ai_draw_pile.len == 0 {
		g.match_winner = 1
		g.phase = .game_over
		g.celebration = 'VICTORY! YOU CONQUERED ALL 52 CARDS!!'
		g.bob_mood = 2
		g.trigger_shake(12.0, 1.0)
		g.spawn_confetti(400, 250, 120)
		g.spawn_shockwave(400, 300, Color{ r: 255, g: 215, b: 0 })
		sound_mgr.play_victory()
		return
	}

	g.round_count++
	p_card := g.player_draw_pile.pop()
	ai_card := g.ai_draw_pile.pop()

	g.battle_player = p_card
	g.battle_ai = ai_card
	g.has_battle_card = true
	sound_mgr.play_card_flip()

	// Add animated flying card from draw piles to battle positions
	g.spawn_flying_card(p_card, 100, 390, 410, 315, true, 0, true)
	g.spawn_flying_card(ai_card, 100, 80, 410, 155, true, 0, false)

	g.war_pot << p_card
	g.war_pot << ai_card
	if g.war_pot.len > g.highest_pot {
		g.highest_pot = g.war_pot.len
	}

	cx := 450.0
	cy := 290.0

	if p_card.rank > ai_card.rank {
		// Player Wins Round
		g.round_winner = 1
		g.phase = .comparing
		g.phase_timer = 0.0
		g.player_streak++
		g.ai_streak = 0
		g.bob_mood = if p_card.rank - ai_card.rank >= 6 { 2 } else { 0 }
		sound_mgr.play_round_win()

		// Visual Effects
		g.spawn_sparks(cx, cy, 25, Color{ r: 70, g: 180, b: 255 })
		if p_card.rank == 14 {
			g.trigger_shake(5.0, 0.25)
			g.spawn_floating_text(cx, cy - 10, '★ CRITICAL ACE SLAM! ★', Color{ r: 255, g: 230, b: 60 }, 1)
			g.spawn_shockwave(cx, cy, Color{ r: 100, g: 200, b: 255 })
		} else if g.player_streak >= 3 {
			g.spawn_floating_text(cx, cy - 10, 'STREAK x${g.player_streak}! +2 CARDS', Color{ r: 100, g: 255, b: 150 }, 1)
		} else {
			g.spawn_floating_text(cx, cy - 10, '+2 CARDS WON!', Color{ r: 150, g: 220, b: 255 }, 1)
		}
	} else if ai_card.rank > p_card.rank {
		// AI Wins Round
		g.round_winner = 2
		g.phase = .comparing
		g.phase_timer = 0.0
		g.ai_streak++
		g.player_streak = 0
		g.bob_mood = 1
		sound_mgr.play_round_win()

		g.spawn_sparks(cx, cy, 25, Color{ r: 255, g: 90, b: 90 })
		if ai_card.rank == 14 {
			g.trigger_shake(5.0, 0.25)
			g.spawn_floating_text(cx, cy - 10, 'BOB DROPS THE ACE!', Color{ r: 255, g: 100, b: 100 }, 1)
			g.spawn_shockwave(cx, cy, Color{ r: 255, g: 80, b: 80 })
		} else {
			g.spawn_floating_text(cx, cy - 10, 'BOB TAKES ROUND (-2)', Color{ r: 255, g: 150, b: 150 }, 1)
		}
	} else {
		// Tie -> "I DECLARE WAR!"
		g.round_winner = 3
		g.wars_fought++
		g.phase = .war_declared
		g.phase_timer = 0.0
		g.celebration = '⚔️ I DECLARE WAR!! ⚔️'
		g.celeb_timer = 2.5
		g.bob_mood = 3
		g.trigger_shake(10.0, 0.5)
		g.spawn_sparks(cx, cy, 50, Color{ r: 255, g: 215, b: 0 })
		g.spawn_shockwave(cx, cy, Color{ r: 255, g: 220, b: 50 })
		g.spawn_floating_text(cx, cy - 25, '⚔️ RANKS TIED (${get_rank_str(p_card.rank)})! WAR! ⚔️', Color{ r: 255, g: 235, b: 50 }, 1)
		sound_mgr.play_war_clash()
	}
}

pub fn (mut g WarGame) trigger_shake(intensity f64, duration f64) {
	g.shake_intensity = intensity
	g.shake_timer = duration
}

pub fn (mut g WarGame) spawn_sparks(x f64, y f64, count int, col Color) {
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
			max_life:   0.3 + rand.f64() * 0.4
			shape_type: 0
			rot:        rand.f64() * 6.28
			vrot:       (rand.f64() - 0.5) * 10.0
			gravity:    120.0
		}
	}
}

pub fn (mut g WarGame) spawn_confetti(x f64, y f64, count int) {
	cols := [
		Color{ r: 255, g: 50, b: 50 },
		Color{ r: 50, g: 150, b: 255 },
		Color{ r: 255, g: 215, b: 0 },
		Color{ r: 50, g: 255, b: 100 },
		Color{ r: 255, g: 100, b: 255 },
		Color{ r: 255, g: 255, b: 255 },
	]
	for _ in 0 .. count {
		angle := rand.f64() * math.pi * 2.0
		speed := 60.0 + rand.f64() * 220.0
		col_idx := rand.int_in_range(0, cols.len) or { 0 }
		g.particles << Particle{
			x:          x + (rand.f64() - 0.5) * 40.0
			y:          y + (rand.f64() - 0.5) * 40.0
			vx:         math.cos(angle) * speed
			vy:         math.sin(angle) * speed - 80.0
			color:      cols[col_idx]
			size:       4.0 + rand.f64() * 4.0
			life:       0.0
			max_life:   1.2 + rand.f64() * 1.0
			shape_type: 2
			rot:        rand.f64() * 6.28
			vrot:       (rand.f64() - 0.5) * 8.0
			gravity:    90.0
		}
	}
}

pub fn (mut g WarGame) spawn_shockwave(cx f64, cy f64, col Color) {
	g.shockwaves << Shockwave{
		cx:         cx
		cy:         cy
		radius:     10.0
		max_radius: 90.0
		color:      col
		life:       0.0
		max_life:   0.45
		thickness:  3.0
	}
}

pub fn (mut g WarGame) spawn_floating_text(x f64, y f64, text string, col Color, scale int) {
	g.floating_texts << FloatingText{
		x:        x
		y:        y
		text:     text
		color:    col
		scale:    scale
		life:     0.0
		max_life: 1.4
		vy:       -28.0
	}
}

pub fn (mut g WarGame) spawn_flying_card(c Card, sx f64, sy f64, tx f64, ty f64, face_up bool, purpose int, is_p bool) {
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
		speed:         if g.auto_play { 4.5 } else { 3.2 }
		flip_progress: 0.0
		purpose:       purpose
		is_player:     is_p
	}
}

pub fn (mut g WarGame) update(dt f64, mut sound_mgr SoundManager) {
	g.anim_timer += dt
	g.pulse_time += dt

	// Update screen shake
	if g.shake_timer > 0.0 {
		g.shake_timer -= dt
		if g.shake_timer <= 0.0 {
			g.shake_intensity = 0.0
		}
	}

	// Update particles
	for mut p in g.particles {
		p.life += dt
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.vy += p.gravity * dt
		p.rot += p.vrot * dt
		p.vx *= (1.0 - 0.5 * dt)
	}
	g.particles = g.particles.filter(it.life < it.max_life)

	// Update shockwaves
	for mut sw in g.shockwaves {
		sw.life += dt
		prog := sw.life / sw.max_life
		sw.radius = 10.0 + (sw.max_radius - 10.0) * math.sin(prog * math.pi * 0.5)
	}
	g.shockwaves = g.shockwaves.filter(it.life < it.max_life)

	// Update floating texts
	for mut ft in g.floating_texts {
		ft.life += dt
		ft.y += ft.vy * dt
		ft.vy *= (1.0 - 0.8 * dt)
	}
	g.floating_texts = g.floating_texts.filter(it.life < it.max_life)

	// Update flying cards
	for mut fc in g.flying_cards {
		fc.progress += fc.speed * dt
		if fc.progress > 1.0 {
			fc.progress = 1.0
		}
		// Smooth ease-out curve
		t := fc.progress
		ease := 1.0 - math.pow(1.0 - t, 3.0)
		fc.x = fc.start_x + (fc.target_x - fc.start_x) * ease
		fc.y = fc.start_y + (fc.target_y - fc.start_y) * ease

		// Arc height for win collection
		if fc.purpose == 2 {
			arc := math.sin(t * math.pi) * -40.0
			fc.y += arc
		}
		fc.flip_progress = t
	}
	g.flying_cards = g.flying_cards.filter(it.progress < 1.0)

	if g.celeb_timer > 0.0 {
		g.celeb_timer -= dt
		if g.celeb_timer <= 0.0 {
			g.celebration = ''
		}
	}

	match g.phase {
		.comparing {
			g.phase_timer += dt
			threshold := if g.auto_play { g.auto_speed } else { 1.2 }
			if g.phase_timer >= threshold {
				// Fly pot cards to winner capture pile
				win_x := if g.round_winner == 1 { 200.0 } else { 200.0 }
				win_y := if g.round_winner == 1 { 390.0 } else { 80.0 }

				for c in g.war_pot {
					g.spawn_flying_card(c, 450, 280, win_x, win_y, false, 2, g.round_winner == 1)
				}

				// Award war pot to winner
				if g.round_winner == 1 {
					for c in g.war_pot {
						g.player_win_pile << c
					}
				} else if g.round_winner == 2 {
					for c in g.war_pot {
						g.ai_win_pile << c
					}
				}
				g.war_pot.clear()
				g.has_battle_card = false
				g.phase = .ready

				if g.auto_play {
					g.step_battle(mut sound_mgr)
				}
			}
		}
		.war_declared {
			g.phase_timer += dt
			threshold := if g.auto_play { 0.8 } else { 1.2 }
			if g.phase_timer >= threshold {
				g.execute_war_flip(mut sound_mgr)
			}
		}
		.ready {
			if g.auto_play {
				g.phase_timer += dt
				if g.phase_timer >= g.auto_speed {
					g.step_battle(mut sound_mgr)
				}
			}
		}
		else {}
	}
}

fn (mut g WarGame) execute_war_flip(mut sound_mgr SoundManager) {
	// Put up to 3 cards face down each, then 1 face-up
	for idx in 0 .. 3 {
		g.recycle_player_deck()
		if g.player_draw_pile.len > 1 {
			p_down := g.player_draw_pile.pop()
			g.war_pot << p_down
			g.spawn_flying_card(p_down, 100, 390, 370 + idx * 25, 290, false, 1, true)
		}
		g.recycle_ai_deck()
		if g.ai_draw_pile.len > 1 {
			ai_down := g.ai_draw_pile.pop()
			g.war_pot << ai_down
			g.spawn_flying_card(ai_down, 100, 80, 370 + idx * 25, 240, false, 1, false)
		}
	}

	g.recycle_player_deck()
	g.recycle_ai_deck()

	if g.player_draw_pile.len == 0 || g.ai_draw_pile.len == 0 {
		g.step_battle(mut sound_mgr)
		return
	}

	p_war_card := g.player_draw_pile.pop()
	ai_war_card := g.ai_draw_pile.pop()

	g.battle_player = p_war_card
	g.battle_ai = ai_war_card
	g.has_battle_card = true
	g.war_pot << p_war_card
	g.war_pot << ai_war_card
	if g.war_pot.len > g.highest_pot {
		g.highest_pot = g.war_pot.len
	}

	g.spawn_flying_card(p_war_card, 100, 390, 410, 315, true, 0, true)
	g.spawn_flying_card(ai_war_card, 100, 80, 410, 155, true, 0, false)

	sound_mgr.play_card_flip()

	cx := 450.0
	cy := 290.0

	if p_war_card.rank > ai_war_card.rank {
		g.round_winner = 1
		g.phase = .comparing
		g.phase_timer = 0.0
		g.celebration = 'YOU CONQUERED THE WAR! +${g.war_pot.len} CARDS!'
		g.celeb_timer = 2.5
		g.bob_mood = 2
		g.player_streak += 2
		g.trigger_shake(8.0, 0.4)
		g.spawn_confetti(cx, cy, 60)
		g.spawn_shockwave(cx, cy, Color{ r: 255, g: 215, b: 0 })
		g.spawn_floating_text(cx, cy - 20, '★ WAR SPOILS WON! +${g.war_pot.len} ★', Color{ r: 255, g: 220, b: 50 }, 1)
		sound_mgr.play_round_win()
	} else if ai_war_card.rank > p_war_card.rank {
		g.round_winner = 2
		g.phase = .comparing
		g.phase_timer = 0.0
		g.celebration = 'GENERAL BOB CONQUERED THE WAR! +${g.war_pot.len} CARDS'
		g.celeb_timer = 2.5
		g.bob_mood = 1
		g.ai_streak += 2
		g.trigger_shake(8.0, 0.4)
		g.spawn_sparks(cx, cy, 45, Color{ r: 255, g: 80, b: 80 })
		g.spawn_shockwave(cx, cy, Color{ r: 255, g: 60, b: 60 })
		g.spawn_floating_text(cx, cy - 20, 'BOB TAKES WAR POT (-${g.war_pot.len})', Color{ r: 255, g: 120, b: 120 }, 1)
		sound_mgr.play_round_win()
	} else {
		// Double War!
		g.round_winner = 3
		g.wars_fought++
		g.phase = .war_declared
		g.phase_timer = 0.0
		g.celebration = '⚔️ DOUBLE WAR!! ⚔️'
		g.celeb_timer = 2.5
		g.bob_mood = 3
		g.trigger_shake(14.0, 0.6)
		g.spawn_sparks(cx, cy, 70, Color{ r: 255, g: 200, b: 0 })
		g.spawn_shockwave(cx, cy, Color{ r: 255, g: 255, b: 100 })
		g.spawn_floating_text(cx, cy - 25, '🔥 DOUBLE WAR CLASH!! 🔥', Color{ r: 255, g: 215, b: 0 }, 1)
		sound_mgr.play_war_clash()
	}
}

pub fn get_rank_str(r int) string {
	return match r {
		14 { 'A' }
		13 { 'K' }
		12 { 'Q' }
		11 { 'J' }
		10 { '10' }
		else { '${r}' }
	}
}
