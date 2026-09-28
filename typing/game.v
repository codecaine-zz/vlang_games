module main

import math
import rand

enum GameState {
	title
	playing
	wave_clear
	game_over
	victory
	paused
}

enum GameMode {
	arcade
	speed_blitz
	code_words
	endless
}

fn (m GameMode) name() string {
	return match m {
		.arcade { 'ARCADE CAMPAIGN' }
		.speed_blitz { '60s SPEED BLITZ' }
		.code_words { 'CODE SYNTAX' }
		.endless { 'ENDLESS SURVIVAL' }
	}
}

enum EnemyType {
	scout
	cruiser
	dreadnought
	emp_nuke
	time_freeze
	shield_repair
}

struct Star {
pub mut:
	x     f64
	y     f64
	speed f64
	size  int
	color Color
}

struct EnemyShip {
pub mut:
	id          int
	word        string
	typed_count int
	enemy_type  EnemyType
	x           f64
	y           f64
	vx          f64
	vy          f64
	width       f64
	height      f64
	alive       bool
	anim_timer  f64
	color       Color
}

struct LaserBeam {
pub mut:
	x1    f64
	y1    f64
	x2    f64
	y2    f64
	timer f64
	color Color
}

struct Particle {
pub mut:
	x        f64
	y        f64
	vx       f64
	vy       f64
	life     f64
	max_life f64
	size     f64
	color    Color
}

struct FloatingText {
pub mut:
	x     f64
	y     f64
	text  string
	timer f64
	color Color
}

struct GameEngine {
pub mut:
	state             GameState
	mode              GameMode = .arcade
	score             int
	high_score        int = 15000
	wave              int = 1
	shields           int = 4
	max_shields       int = 4
	combo_streak      int
	max_combo         int
	words_typed       int
	total_keystrokes  int
	correct_keystrokes int
	game_timer        f64
	blitz_timer       f64 = 60.0
	freeze_timer      f64
	spawn_timer       f64
	spawn_interval    f64 = 2.2
	wave_enemies_left int = 12
	locked_enemy_id   int = -1
	screen_shake      f64
	transition_timer  f64
	enemies           []EnemyShip
	lasers            []LaserBeam
	particles         []Particle
	floating_texts    []FloatingText
	stars             []Star
	ship_x            f64 = 400.0
	ship_y            f64 = 540.0
	emp_flash_timer   f64
	emp_shock_radius  f64
}

fn new_game_engine() GameEngine {
	mut g := GameEngine{
		state: .title
	}
	g.init_starfield()
	return g
}

fn (mut g GameEngine) init_starfield() {
	g.stars.clear()
	for _ in 0 .. 90 {
		speed := 20.0 + rand.f64() * 80.0
		size := if speed > 60.0 { 2 } else { 1 }
		brightness := u8(100 + rand.intn(155) or { 100 })
		g.stars << Star{
			x: rand.f64() * 800.0
			y: rand.f64() * 600.0
			speed: speed
			size: size
			color: Color{ r: brightness, g: brightness, b: u8(math.min(255, int(brightness) + 30)) }
		}
	}
}

fn (mut g GameEngine) set_mode(m GameMode) {
	g.mode = m
}

fn (mut g GameEngine) cycle_mode() {
	g.mode = match g.mode {
		.arcade { .speed_blitz }
		.speed_blitz { .code_words }
		.code_words { .endless }
		.endless { .arcade }
	}
}

fn (mut g GameEngine) start_game(m GameMode) {
	g.mode = m
	g.score = 0
	g.wave = 1
	g.shields = 4
	g.max_shields = 4
	g.combo_streak = 0
	g.max_combo = 0
	g.words_typed = 0
	g.total_keystrokes = 0
	g.correct_keystrokes = 0
	g.game_timer = 0.0
	g.blitz_timer = 60.0
	g.freeze_timer = 0.0
	g.locked_enemy_id = -1
	g.enemies.clear()
	g.lasers.clear()
	g.particles.clear()
	g.floating_texts.clear()
	g.load_wave(1)
	g.state = .playing
}

fn (mut g GameEngine) load_wave(w int) {
	g.wave = w
	g.enemies.clear()
	g.locked_enemy_id = -1
	g.spawn_timer = 0.5
	g.transition_timer = 0.0

	// Wave progression parameters
	match g.mode {
		.arcade {
			g.wave_enemies_left = 8 + w * 4
			g.spawn_interval = math.max(0.85, 2.2 - f64(w) * 0.12)
		}
		.speed_blitz {
			g.wave_enemies_left = 9999
			g.spawn_interval = 1.0
		}
		.code_words {
			g.wave_enemies_left = 10 + w * 5
			g.spawn_interval = math.max(0.95, 2.4 - f64(w) * 0.10)
		}
		.endless {
			g.wave_enemies_left = 9999
			g.spawn_interval = math.max(0.65, 2.0 - f64(w) * 0.15)
		}
	}
}

fn (mut g GameEngine) update(dt f64, mut sm SoundManager) {
	// Update Starfield Background
	for mut s in g.stars {
		s.y += s.speed * dt
		if s.y > 600.0 {
			s.y = 0.0
			s.x = rand.f64() * 800.0
		}
	}

	match g.state {
		.title {
			return
		}
		.paused {
			return
		}
		.playing {
			g.update_playing(dt, mut sm)
		}
		.wave_clear {
			g.transition_timer += dt
			if g.transition_timer >= 1.6 {
				g.transition_timer = 0.0
				if g.mode == .arcade && g.wave >= 10 {
					g.state = .victory
					sm.play_wave_clear()
				} else {
					g.load_wave(g.wave + 1)
					g.state = .playing
				}
			}
		}
		.game_over, .victory {
			g.transition_timer += dt
		}
	}
}

fn (mut g GameEngine) update_playing(dt f64, mut sm SoundManager) {
	g.game_timer += dt

	if g.mode == .speed_blitz {
		g.blitz_timer -= dt
		if g.blitz_timer <= 0 {
			g.blitz_timer = 0
			g.state = .game_over
			sm.play_wave_clear()
			return
		}
	}

	if g.freeze_timer > 0 {
		g.freeze_timer = math.max(0.0, g.freeze_timer - dt)
	}

	if g.screen_shake > 0 {
		g.screen_shake = math.max(0.0, g.screen_shake - dt * 15.0)
	}

	if g.emp_flash_timer > 0 {
		g.emp_flash_timer = math.max(0.0, g.emp_flash_timer - dt * 2.5)
		g.emp_shock_radius += dt * 900.0
	}

	// Spawn Enemies
	g.spawn_timer += dt
	if g.spawn_timer >= g.spawn_interval && g.wave_enemies_left > 0 {
		g.spawn_timer = 0.0
		g.spawn_enemy()
		if g.mode != .speed_blitz && g.mode != .endless {
			g.wave_enemies_left--
		}
	}

	// Update Enemies
	enemy_speed_mult := if g.freeze_timer > 0 { 0.15 } else { 1.0 }
	for mut en in g.enemies {
		if !en.alive {
			continue
		}
		en.anim_timer += dt * 4.0
		en.y += en.vy * enemy_speed_mult * dt
		en.x += math.sin(en.anim_timer) * en.vx * dt

		// Keep within horizontal bounds
		en.x = math.max(40.0, math.min(760.0 - en.width, en.x))

		// Check Hull Impact (Enemy reached bottom of screen)
		if en.y >= 510.0 {
			en.alive = false
			g.shields--
			g.combo_streak = 0
			g.screen_shake = 10.0
			sm.play_damage()
			g.spawn_explosion(en.x + en.width / 2.0, en.y, 25, Color{ r: 255, g: 80, b: 60 })

			if g.locked_enemy_id == en.id {
				g.locked_enemy_id = -1
			}

			if g.shields <= 0 {
				g.shields = 0
				g.state = .game_over
				return
			}
		}
	}

	// Update Lasers
	for mut l in g.lasers {
		l.timer -= dt * 6.0
	}
	g.lasers = g.lasers.filter(it.timer > 0)

	// Update Particles
	for mut p in g.particles {
		p.life -= dt
		p.x += p.vx * dt
		p.y += p.vy * dt
	}
	g.particles = g.particles.filter(it.life > 0)

	// Update Floating Texts
	for mut ft in g.floating_texts {
		ft.timer -= dt
		ft.y -= dt * 30.0
	}
	g.floating_texts = g.floating_texts.filter(it.timer > 0)

	// Check Wave Clear
	if g.mode != .speed_blitz && g.mode != .endless {
		alive_count := g.enemies.filter(it.alive).len
		if g.wave_enemies_left <= 0 && alive_count == 0 {
			g.state = .wave_clear
			g.transition_timer = 0.0
			sm.play_wave_clear()
			g.floating_texts << FloatingText{
				x: 400.0
				y: 250.0
				text: 'SECTOR ${g.wave} CLEARED!'
				timer: 2.0
				color: Color{ r: 80, g: 255, b: 180 }
			}
		}
	}
}

fn (mut g GameEngine) spawn_enemy() {
	mut etype := EnemyType.scout
	roll := rand.f64()

	// Special word probabilities
	if roll < 0.07 {
		etype = .emp_nuke
	} else if roll < 0.13 {
		etype = .time_freeze
	} else if roll < 0.18 && g.shields < g.max_shields {
		etype = .shield_repair
	} else if roll < 0.45 {
		etype = .cruiser
	} else if roll < 0.58 && g.wave >= 3 {
		etype = .dreadnought
	} else {
		etype = .scout
	}

	mut word := ''
	is_code := (g.mode == .code_words)

	match etype {
		.emp_nuke {
			word = get_random_emp_word()
		}
		.time_freeze {
			word = get_random_freeze_word()
		}
		.shield_repair {
			word = get_random_heal_word()
		}
		.scout {
			word = get_random_word(0, is_code)
		}
		.cruiser {
			word = get_random_word(1, is_code)
		}
		.dreadnought {
			word = get_random_word(2, is_code)
		}
	}

	// Speed calculation based on wave & type
	base_fall_speed := match etype {
		.scout { 38.0 + f64(g.wave) * 4.0 }
		.cruiser { 28.0 + f64(g.wave) * 3.0 }
		.dreadnought { 18.0 + f64(g.wave) * 2.0 }
		else { 32.0 + f64(g.wave) * 3.0 }
	}

	color := match etype {
		.scout { Color{ r: 255, g: 120, b: 120 } }
		.cruiser { Color{ r: 255, g: 215, b: 0 } }
		.dreadnought { Color{ r: 255, g: 60, b: 180 } }
		.emp_nuke { Color{ r: 0, g: 240, b: 255 } }
		.time_freeze { Color{ r: 180, g: 120, b: 255 } }
		.shield_repair { Color{ r: 80, g: 255, b: 120 } }
	}

	width := f64(word.len * 14 + 20)
	spawn_x := 50.0 + rand.f64() * (700.0 - width)

	g.enemies << EnemyShip{
		id: g.enemies.len + 1
		word: word
		typed_count: 0
		enemy_type: etype
		x: spawn_x
		y: 40.0
		vx: (rand.f64() * 2.0 - 1.0) * 15.0
		vy: base_fall_speed
		width: width
		height: 32.0
		alive: true
		anim_timer: rand.f64() * 10.0
		color: color
	}
}

// Process typed character
fn (mut g GameEngine) handle_character_input(ch rune, mut sm SoundManager) {
	if g.state != .playing {
		return
	}

	ch_lower := if ch >= `A` && ch <= `Z` { ch + 32 } else { ch }
	if ch_lower < `a` || ch_lower > `z` {
		return
	}

	g.total_keystrokes++

	// 1. If currently locked onto an enemy, check if input matches next letter
	if g.locked_enemy_id != -1 {
		mut found := false
		for mut en in g.enemies {
			if en.id == g.locked_enemy_id && en.alive {
				found = true
				if en.typed_count < en.word.len && rune(en.word[en.typed_count]) == ch_lower {
					// Correct keypress on locked target!
					en.typed_count++
					g.correct_keystrokes++
					g.combo_streak++
					if g.combo_streak > g.max_combo {
						g.max_combo = g.combo_streak
					}

					// Laser bolt fired at target
					target_x := en.x + f64(en.typed_count * 14)
					target_y := en.y + 16.0
					g.lasers << LaserBeam{
						x1: g.ship_x
						y1: g.ship_y
						x2: target_x
						y2: target_y
						timer: 1.0
						color: en.color
					}
					g.spawn_explosion(target_x, target_y, 4, en.color)
					sm.play_laser_zap(en.typed_count)

					// Check word completed
					if en.typed_count >= en.word.len {
						g.handle_enemy_destroyed(mut en, mut sm)
					}
					return
				} else {
					// Misfire / incorrect character!
					g.combo_streak = 0
					sm.play_misfire()
					return
				}
			}
		}
		if !found {
			g.locked_enemy_id = -1
		}
	}

	// 2. Not locked onto an enemy: search active enemies starting with this letter
	mut best_enemy_idx := -1
	mut lowest_y := -100.0

	for i, en in g.enemies {
		if en.alive && en.typed_count == 0 && en.word.len > 0 {
			if rune(en.word[0]) == ch_lower {
				if en.y > lowest_y {
					lowest_y = en.y
					best_enemy_idx = i
				}
			}
		}
	}

	if best_enemy_idx != -1 {
		// Acquire Lock & Fire first laser!
		mut en := &g.enemies[best_enemy_idx]
		g.locked_enemy_id = en.id
		en.typed_count = 1
		g.correct_keystrokes++
		g.combo_streak++
		if g.combo_streak > g.max_combo {
			g.max_combo = g.combo_streak
		}

		target_x := en.x + 14.0
		target_y := en.y + 16.0
		g.lasers << LaserBeam{
			x1: g.ship_x
			y1: g.ship_y
			x2: target_x
			y2: target_y
			timer: 1.0
			color: en.color
		}
		g.spawn_explosion(target_x, target_y, 4, en.color)
		sm.play_laser_zap(1)

		if en.typed_count >= en.word.len {
			g.handle_enemy_destroyed(mut en, mut sm)
		}
	} else {
		// No enemy starts with this letter: misfire!
		g.combo_streak = 0
		sm.play_misfire()
	}
}

fn (mut g GameEngine) cancel_lock() {
	if g.locked_enemy_id != -1 {
		for mut en in g.enemies {
			if en.id == g.locked_enemy_id {
				en.typed_count = 0
			}
		}
		g.locked_enemy_id = -1
	}
}

fn (mut g GameEngine) handle_enemy_destroyed(mut en EnemyShip, mut sm SoundManager) {
	en.alive = false
	g.words_typed++
	g.locked_enemy_id = -1

	// Combo multiplier: 1x, 2x (10+), 3x (25+), 4x (50+), 5x (100+)
	combo_mult := match true {
		g.combo_streak >= 100 { 5 }
		g.combo_streak >= 50 { 4 }
		g.combo_streak >= 25 { 3 }
		g.combo_streak >= 10 { 2 }
		else { 1 }
	}

	base_pts := en.word.len * 50
	pts := base_pts * combo_mult
	g.score += pts
	if g.score > g.high_score {
		g.high_score = g.score
	}

	sm.play_word_complete(combo_mult)
	g.spawn_explosion(en.x + en.width / 2.0, en.y + 16.0, 20, en.color)

	// Floating score indicator
	mut txt := '+${pts}'
	if combo_mult > 1 {
		txt = '${combo_mult}x +${pts}!'
	}
	g.floating_texts << FloatingText{
		x: en.x + en.width / 2.0
		y: en.y - 10.0
		text: txt
		timer: 1.2
		color: en.color
	}

	// Handle Special Word Abilities
	match en.enemy_type {
		.emp_nuke {
			// Wipe all other active enemies on screen!
			g.emp_flash_timer = 1.0
			g.emp_shock_radius = 10.0
			sm.play_emp_blast()

			for mut other in g.enemies {
				if other.alive {
					other.alive = false
					g.words_typed++
					g.score += other.word.len * 30
					g.spawn_explosion(other.x + other.width / 2.0, other.y + 16.0, 16, other.color)
				}
			}
			g.floating_texts << FloatingText{
				x: 400.0
				y: 300.0
				text: 'EMP DETONATION! SCREEN CLEARED!'
				timer: 2.0
				color: Color{ r: 0, g: 240, b: 255 }
			}
		}
		.time_freeze {
			g.freeze_timer = 4.0
			sm.play_powerup()
			g.floating_texts << FloatingText{
				x: en.x + en.width / 2.0
				y: en.y - 25.0
				text: 'TIME WARP FREEZE (4s)!'
				timer: 1.8
				color: Color{ r: 180, g: 120, b: 255 }
			}
		}
		.shield_repair {
			if g.shields < g.max_shields {
				g.shields++
			}
			sm.play_powerup()
			g.floating_texts << FloatingText{
				x: en.x + en.width / 2.0
				y: en.y - 25.0
				text: 'HULL SHIELD REPAIRED (+1)!'
				timer: 1.8
				color: Color{ r: 80, g: 255, b: 120 }
			}
		}
		else {}
	}
}

fn (mut g GameEngine) spawn_explosion(cx f64, cy f64, count int, col Color) {
	for _ in 0 .. count {
		angle := rand.f64() * 2.0 * math.pi
		spd := 40.0 + rand.f64() * 180.0
		life := 0.25 + rand.f64() * 0.45
		g.particles << Particle{
			x: cx
			y: cy
			vx: math.cos(angle) * spd
			vy: math.sin(angle) * spd
			life: life
			max_life: life
			size: 2.0 + rand.f64() * 3.0
			color: col
		}
	}
}

// Calculate real-time Words Per Minute (WPM)
fn (g GameEngine) calculate_wpm() int {
	if g.game_timer < 1.0 || g.correct_keystrokes == 0 {
		return 0
	}
	minutes := g.game_timer / 60.0
	words := f64(g.correct_keystrokes) / 5.0
	return int(words / minutes)
}

// Calculate typing accuracy percentage
fn (g GameEngine) calculate_accuracy() int {
	if g.total_keystrokes == 0 {
		return 100
	}
	return int((f64(g.correct_keystrokes) / f64(g.total_keystrokes)) * 100.0)
}
