module main

import math
import os
import rand



pub enum GridMode {
	grid_4x4
	grid_6x4
	grid_6x6
}

pub enum CardIcon {
	gem
	crown
	star
	key
	potion
	fire
	lightning
	heart
	crescent
	atom
	rocket
	shield
	diamond
	coin
	music
	clover
	bell
	skull
}

pub struct Card {
pub mut:
	id            int
	icon          CardIcon
	is_face_up    bool
	is_matched    bool
	flip_progress f64 // 0.0 = face down, 1.0 = face up
	flip_target   f64
	shake_timer   f64
}

pub enum MemoryState {
	playing
	mismatch_delay
	game_won
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

pub struct MemoryGame {
pub mut:
	grid_mode      GridMode = .grid_4x4
	state          MemoryState = .playing
	cols           int = 4
	rows           int = 4
	cards          []Card
	first_card_idx int = -1
	second_card_idx int = -1
	turns          int
	matches        int
	total_pairs    int = 8
	combo          int
	max_combo      int
	timer          f64
	mismatch_timer f64
	stars          int = 3
	best_turns_4x4 int
	best_turns_6x4 int
	best_turns_6x6 int
	best_time_4x4  f64
	best_time_6x4  f64
	best_time_6x6  f64

	// VFX State
	particles       []Particle
	floating_texts  []FloatingText
	shockwaves      []Shockwave
	shake_intensity f64
	shake_timer     f64
	anim_timer      f64
	pulse_time      f64
	sprite_texture  &Texture = unsafe { nil }
}

pub fn (mut g MemoryGame) init_textures(renderer &Renderer) {
	paths := [
		'assets/sprites/memorymatch.png',
		'./assets/sprites/memorymatch.png',
		'../assets/sprites/memorymatch.png',
		'memorymatch/assets/sprites/memorymatch.png',
	]
	for p in paths {
		if os.exists(p) {
			g.sprite_texture = load_texture(renderer.ctx, p)
			if g.sprite_texture != unsafe { nil } && g.sprite_texture.valid {
				println('memorymatch Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

pub fn new_memory_game() MemoryGame {
	mut g := MemoryGame{}
	g.reset_game()
	return g
}

pub fn (mut g MemoryGame) reset_game() {
	match g.grid_mode {
		.grid_4x4 {
			g.cols = 4
			g.rows = 4
			g.total_pairs = 8
		}
		.grid_6x4 {
			g.cols = 6
			g.rows = 4
			g.total_pairs = 12
		}
		.grid_6x6 {
			g.cols = 6
			g.rows = 6
			g.total_pairs = 18
		}
	}

	g.cards.clear()
	g.first_card_idx = -1
	g.second_card_idx = -1
	g.turns = 0
	g.matches = 0
	g.combo = 0
	g.max_combo = 0
	g.timer = 0.0
	g.mismatch_timer = 0.0
	g.state = .playing
	g.stars = 3

	// Create pairs of icons
	all_icons := [
		CardIcon.gem, .crown, .star, .key, .potion, .fire,
		.lightning, .heart, .crescent, .atom, .rocket, .shield,
		.diamond, .coin, .music, .clover, .bell, .skull,
	]

	mut pair_icons := []CardIcon{cap: g.total_pairs * 2}
	for i in 0 .. g.total_pairs {
		icon := all_icons[i % all_icons.len]
		pair_icons << icon
		pair_icons << icon
	}

	// Fisher-Yates Shuffle
	for i := pair_icons.len - 1; i > 0; i-- {
		j := rand.intn(i + 1) or { 0 }
		temp := pair_icons[i]
		pair_icons[i] = pair_icons[j]
		pair_icons[j] = temp
	}

	for id, icon in pair_icons {
		g.cards << Card{
			id:            id
			icon:          icon
			is_face_up:    false
			is_matched:    false
			flip_progress: 0.0
			flip_target:   0.0
		}
	}
}

pub struct MemoryEvents {
pub mut:
	card_flipped   bool
	cards_matched  bool
	cards_mismatch bool
	game_won       bool
	combo_level    int
}

pub fn (mut g MemoryGame) trigger_shake(intensity f64, duration f64) {
	g.shake_intensity = intensity
	g.shake_timer = duration
}

pub fn (mut g MemoryGame) spawn_sparks(x f64, y f64, count int, col Color) {
	for _ in 0 .. count {
		angle := rand.f64() * math.pi * 2.0
		speed := 40.0 + rand.f64() * 180.0
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
			gravity:    100.0
		}
	}
}

pub fn (mut g MemoryGame) spawn_confetti(x f64, y f64, count int) {
	cols := [
		Color{ r: 255, g: 215, b: 0 },
		Color{ r: 80, g: 200, b: 255 },
		Color{ r: 255, g: 80, b: 120 },
		Color{ r: 90, g: 255, b: 140 },
		Color{ r: 255, g: 255, b: 255 },
	]
	for _ in 0 .. count {
		angle := rand.f64() * math.pi * 2.0
		speed := 70.0 + rand.f64() * 250.0
		col_idx := rand.int_in_range(0, cols.len) or { 0 }
		g.particles << Particle{
			x:          x + (rand.f64() - 0.5) * 50.0
			y:          y + (rand.f64() - 0.5) * 50.0
			vx:         math.cos(angle) * speed
			vy:         math.sin(angle) * speed - 120.0
			color:      cols[col_idx]
			size:       4.0 + rand.f64() * 4.0
			life:       0.0
			max_life:   1.4 + rand.f64() * 0.9
			shape_type: 2
			rot:        rand.f64() * 6.28
			vrot:       (rand.f64() - 0.5) * 8.0
			gravity:    100.0
		}
	}
}

pub fn (mut g MemoryGame) spawn_shockwave(cx f64, cy f64, col Color) {
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

pub fn (mut g MemoryGame) spawn_floating_text(x f64, y f64, text string, col Color, scale int) {
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

pub fn (mut g MemoryGame) update(dt f64) MemoryEvents {
	mut ev := MemoryEvents{}

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

	if g.state == .playing || g.state == .mismatch_delay {
		g.timer += dt
	}

	// Update 3D card flipping animations
	for mut card in g.cards {
		if card.flip_progress < card.flip_target {
			card.flip_progress = math.min(card.flip_progress + dt * 6.0, card.flip_target)
		} else if card.flip_progress > card.flip_target {
			card.flip_progress = math.max(card.flip_progress - dt * 6.0, card.flip_target)
		}

		if card.shake_timer > 0.0 {
			card.shake_timer -= dt
		}
	}

	if g.state == .mismatch_delay {
		g.mismatch_timer -= dt
		if g.mismatch_timer <= 0.0 {
			// Flip mismatched cards back down
			if g.first_card_idx >= 0 && g.first_card_idx < g.cards.len {
				g.cards[g.first_card_idx].is_face_up = false
				g.cards[g.first_card_idx].flip_target = 0.0
			}
			if g.second_card_idx >= 0 && g.second_card_idx < g.cards.len {
				g.cards[g.second_card_idx].is_face_up = false
				g.cards[g.second_card_idx].flip_target = 0.0
			}
			g.first_card_idx = -1
			g.second_card_idx = -1
			g.state = .playing
		}
	}

	return ev
}

pub fn (mut g MemoryGame) flip_card(idx int) (bool, MemoryEvents) {
	mut ev := MemoryEvents{}
	if g.state != .playing || idx < 0 || idx >= g.cards.len {
		return false, ev
	}

	if g.cards[idx].is_face_up || g.cards[idx].is_matched {
		return false, ev
	}

	// Flip chosen card face up
	g.cards[idx].is_face_up = true
	g.cards[idx].flip_target = 1.0
	ev.card_flipped = true

	if g.first_card_idx == -1 {
		// First card in turn
		g.first_card_idx = idx
	} else if g.second_card_idx == -1 {
		// Second card in turn
		g.second_card_idx = idx
		g.turns++

		c1 := g.cards[g.first_card_idx]
		c2 := g.cards[g.second_card_idx]

		if c1.icon == c2.icon {
			// Matched!
			g.cards[g.first_card_idx].is_matched = true
			g.cards[g.second_card_idx].is_matched = true
			g.matches++
			g.combo++
			if g.combo > g.max_combo { g.max_combo = g.combo }

			ev.cards_matched = true
			ev.combo_level = g.combo

			g.spawn_sparks(400, 320, 25, Color{ r: 100, g: 255, b: 180 })
			g.spawn_shockwave(400, 320, Color{ r: 80, g: 220, b: 255 })
			if g.combo > 1 {
				g.spawn_floating_text(400, 260, '★ ${g.combo}X COMBO! MATCH! ★', Color{ r: 255, g: 215, b: 0 }, 1)
			} else {
				g.spawn_floating_text(400, 260, '★ PAIR MATCHED! ★', Color{ r: 100, g: 255, b: 150 }, 1)
			}

			g.first_card_idx = -1
			g.second_card_idx = -1

			if g.matches >= g.total_pairs {
				// All pairs matched -> Victory!
				g.state = .game_won
				ev.game_won = true
				g.calculate_stars()
				g.spawn_confetti(400, 300, 60)
				g.spawn_shockwave(400, 300, Color{ r: 255, g: 215, b: 0 })
				g.trigger_shake(6.0, 0.45)

				match g.grid_mode {
					.grid_4x4 {
						if g.best_turns_4x4 == 0 || g.turns < g.best_turns_4x4 { g.best_turns_4x4 = g.turns }
						if g.best_time_4x4 == 0.0 || g.timer < g.best_time_4x4 { g.best_time_4x4 = g.timer }
					}
					.grid_6x4 {
						if g.best_turns_6x4 == 0 || g.turns < g.best_turns_6x4 { g.best_turns_6x4 = g.turns }
						if g.best_time_6x4 == 0.0 || g.timer < g.best_time_6x4 { g.best_time_6x4 = g.timer }
					}
					.grid_6x6 {
						if g.best_turns_6x6 == 0 || g.turns < g.best_turns_6x6 { g.best_turns_6x6 = g.turns }
						if g.best_time_6x6 == 0.0 || g.timer < g.best_time_6x6 { g.best_time_6x6 = g.timer }
					}
				}
			}
		} else {
			// Mismatch!
			g.combo = 0
			g.state = .mismatch_delay
			g.mismatch_timer = 0.75
			g.cards[g.first_card_idx].shake_timer = 0.35
			g.cards[g.second_card_idx].shake_timer = 0.35
			ev.cards_mismatch = true
		}
	}
	return true, ev
}

pub fn (mut g MemoryGame) calculate_stars() {
	par_turns := g.total_pairs + int(f64(g.total_pairs) * 0.4)
	if g.turns <= par_turns {
		g.stars = 3
	} else if g.turns <= par_turns + 6 {
		g.stars = 2
	} else {
		g.stars = 1
	}
}

pub fn (mut g MemoryGame) toggle_grid_mode() {
	g.grid_mode = match g.grid_mode {
		.grid_4x4 { .grid_6x4 }
		.grid_6x4 { .grid_6x6 }
		.grid_6x6 { .grid_4x4 }
	}
	g.reset_game()
}
