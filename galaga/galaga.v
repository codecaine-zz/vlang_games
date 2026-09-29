module main

import math
import rand
import os



enum GameState {
	menu
	playing
	paused
	game_over
}

enum EnemyType {
	zako // Blue/yellow bee
	goei // Red/yellow moth
	boss // Green/purple commander (2 hits, can shoot tractor beam)
}

enum EnemyMode {
	formation
	swooping
	tractor_beam
	returning
}

struct Star {
mut:
	x          f32
	y          f32
	speed      f32
	brightness u8
	size       int
}

struct Bullet {
mut:
	x        f32
	y        f32
	vx       f32
	vy       f32
	is_enemy bool
	active   bool
}

struct Enemy {
mut:
	id            int
	enemy_type    EnemyType
	mode          EnemyMode
	x             f32
	y             f32
	home_x        f32
	home_y        f32
	vx            f32
	vy            f32
	swoop_time    f32
	swoop_pattern int
	swoop_speed   f32
	tractor_timer f32
	hp            int
	active        bool
	has_captured  bool
}

struct Particle {
mut:
	x        f32
	y        f32
	vx       f32
	vy       f32
	life     f32
	max_life f32
	color    Color
}

struct Player {
mut:
	x            f32
	y            f32
	width        f32
	height       f32
	speed        f32
	is_dual      bool
	dual_offset  f32
	lives        int
	is_captured  bool
	is_capturing bool
	invuln_timer f32
}

struct RescuableShip {
mut:
	x      f32
	y      f32
	vy     f32
	active bool
}

struct GalagaGame {
mut:
	state              GameState = .menu
	score              int
	high_score         int = 10000
	stage              int = 1
	player             Player
	enemies            []Enemy
	player_bullets     []Bullet
	enemy_bullets      []Bullet
	particles          []Particle
	stars              []Star
	rescuable_ships    []RescuableShip
	sound_mgr          SoundManager
	wave_timer         f32
	stage_intro_timer  f32
	stage_clear_timer  f32
	is_challenge_stage bool
	challenge_hits     int
	challenge_total    int
	tractor_active     bool
	tractor_enemy_id   int = -1
	tractor_beam_y     f32
	captured_ship_x    f32
	captured_ship_y    f32
	key_left           bool
	key_right          bool
	key_fire           bool
	fire_cooldown      f32
	shake_trauma       f32
	sprite_texture     &Texture = unsafe { nil }
	has_sprite_texture bool
}

pub fn (mut g GalagaGame) init_textures(renderer &Renderer) {
	paths := [
		'assets/sprites/galaga.png',
		'./assets/sprites/galaga.png',
		'../assets/sprites/galaga.png',
		'galaga/assets/sprites/galaga.png',
	]
	for p in paths {
		if os.exists(p) {
			g.sprite_texture = load_texture(renderer.ctx, p)
			if g.sprite_texture != unsafe { nil } && g.sprite_texture.valid {
				println('galaga Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

fn new_galaga_game() GalagaGame {
	mut g := GalagaGame{
		score:      0
		high_score: 10000
		stage:      1
		sound_mgr:  new_sound_manager()
	}
	g.init_stars()
	g.reset_game()
	return g
}

fn (mut g GalagaGame) init_stars() {
	g.stars.clear()
	for _ in 0 .. 75 {
		g.stars << Star{
			x:          f32(rand.intn(800) or { 400 })
			y:          f32(rand.intn(600) or { 300 })
			speed:      f32(rand.intn(4) or { 1 }) + 0.8
			size:       (rand.intn(2) or { 0 }) + 1
			brightness: u8(100 + (rand.intn(155) or { 100 }))
		}
	}
}

fn (mut g GalagaGame) reset_game() {
	g.score = 0
	g.stage = 1
	g.player = Player{
		x:            400.0
		y:            540.0
		width:        32.0
		height:       28.0
		speed:        420.0
		is_dual:      false
		dual_offset:  26.0
		lives:        3
		is_captured:  false
		is_capturing: false
		invuln_timer: 2.5
	}
	g.player_bullets.clear()
	g.enemy_bullets.clear()
	g.particles.clear()
	g.rescuable_ships.clear()
	g.captured_ship_x = 0
	g.captured_ship_y = 0
	g.spawn_wave()
	g.state = .playing
	g.stage_intro_timer = 2.0
	g.sound_mgr.play_stage_start_sound()
}

fn (mut g GalagaGame) spawn_wave() {
	g.enemies.clear()
	g.tractor_active = false
	g.tractor_enemy_id = -1
	g.wave_timer = 0.0
	g.stage_clear_timer = 0.0
	g.stage_intro_timer = 2.0
	g.is_challenge_stage = (g.stage % 4 == 3)
	g.challenge_hits = 0

	mut id_counter := 0

	// Boss row (4 commanders)
	for col in 0 .. 4 {
		g.enemies << Enemy{
			id:            id_counter
			enemy_type:    .boss
			mode:          .formation
			home_x:        280.0 + f32(col) * 80.0
			home_y:        100.0
			x:             280.0 + f32(col) * 80.0
			y:             -60.0 - f32(col) * 20.0
			swoop_speed:   220.0 + f32(g.stage) * 15.0
			swoop_pattern: col % 3
			hp:            2
			active:        true
		}
		id_counter++
	}

	// Goei row 1 (8 red moths)
	for col in 0 .. 8 {
		g.enemies << Enemy{
			id:            id_counter
			enemy_type:    .goei
			mode:          .formation
			home_x:        205.0 + f32(col) * 55.0
			home_y:        145.0
			x:             205.0 + f32(col) * 55.0
			y:             -100.0 - f32(col) * 15.0
			swoop_speed:   240.0 + f32(g.stage) * 18.0
			swoop_pattern: (col + 1) % 4
			hp:            1
			active:        true
		}
		id_counter++
	}

	// Zako row 1 & 2 (10 & 10 blue bees)
	for row in 0 .. 2 {
		for col in 0 .. 10 {
			g.enemies << Enemy{
				id:            id_counter
				enemy_type:    .zako
				mode:          .formation
				home_x:        175.0 + f32(col) * 50.0
				home_y:        185.0 + f32(row) * 35.0
				x:             175.0 + f32(col) * 50.0
				y:             -140.0 - f32(row) * 40.0 - f32(col) * 10.0
				swoop_speed:   260.0 + f32(g.stage) * 20.0
				swoop_pattern: (col + row * 2) % 4
				hp:            1
				active:        true
			}
			id_counter++
		}
	}

	g.challenge_total = g.enemies.len
	g.sound_mgr.play_stage_start_sound()
}

fn (mut g GalagaGame) update(dt f32) {
	if g.shake_trauma > 0.0 {
		g.shake_trauma = f32(math.max(0.0, g.shake_trauma - dt * 2.2))
	}

	warp_mult := if g.stage_intro_timer > 0 { f32(3.0) } else { f32(1.0) }
	g.update_stars(dt * warp_mult)

	if g.state != .playing {
		return
	}

	if g.stage_intro_timer > 0 {
		g.stage_intro_timer -= dt
	}

	// Stage clear timer check
	if g.stage_clear_timer > 0 {
		g.stage_clear_timer -= dt
		if g.stage_clear_timer <= 0 {
			g.stage++
			g.spawn_wave()
			return
		}
	}

	if g.fire_cooldown > 0 {
		g.fire_cooldown -= dt
	}

	if g.player.invuln_timer > 0 {
		g.player.invuln_timer -= dt
	}

	// Player Movement (Disabled if being captured)
	if !g.player.is_capturing {
		if g.key_left {
			g.player.x -= g.player.speed * dt
			min_x := if g.player.is_dual { f32(36.0) } else { f32(24.0) }
			if g.player.x < min_x {
				g.player.x = min_x
			}
		}
		if g.key_right {
			g.player.x += g.player.speed * dt
			max_x := if g.player.is_dual { f32(764.0) } else { f32(776.0) }
			if g.player.x > max_x {
				g.player.x = max_x
			}
		}

		// Player Shooting (Faster fire rate & speed)
		if g.key_fire && g.fire_cooldown <= 0 {
			g.fire_cooldown = 0.14
			bullet_speed := f32(-750.0)
			if g.player.is_dual {
				g.player_bullets << Bullet{
					x:        g.player.x - g.player.dual_offset / 2.0
					y:        g.player.y - 14.0
					vx:       0
					vy:       bullet_speed
					is_enemy: false
					active:   true
				}
				g.player_bullets << Bullet{
					x:        g.player.x + g.player.dual_offset / 2.0
					y:        g.player.y - 14.0
					vx:       0
					vy:       bullet_speed
					is_enemy: false
					active:   true
				}
			} else {
				g.player_bullets << Bullet{
					x:        g.player.x
					y:        g.player.y - 14.0
					vx:       0
					vy:       bullet_speed
					is_enemy: false
					active:   true
				}
			}
			g.sound_mgr.play_shoot_sound(g.player.is_dual)
		}
	}

	// Update Bullets
	for mut b in g.player_bullets {
		if !b.active {
			continue
		}
		b.y += b.vy * dt
		b.x += b.vx * dt
		if b.y < -20 {
			b.active = false
		}
	}

	for mut eb in g.enemy_bullets {
		if !eb.active {
			continue
		}
		eb.y += eb.vy * dt
		eb.x += eb.vx * dt
		if eb.y > 620 || eb.x < -20 || eb.x > 820 {
			eb.active = false
		}
	}

	// Update Rescuable Ships falling down
	for mut rs in g.rescuable_ships {
		if !rs.active {
			continue
		}
		rs.y += rs.vy * dt
		// Check capture by player
		if math.abs(g.player.x - rs.x) < 32.0 && math.abs(g.player.y - rs.y) < 24.0 {
			rs.active = false
			g.player.is_dual = true
			g.player.invuln_timer = 2.0
			g.add_score(1000)
			g.shake_trauma = f32(math.min(1.0, g.shake_trauma + 0.35))
			g.sound_mgr.play_rescue_fanfare()
		}
		if rs.y > 620 {
			rs.active = false
		}
	}

	// Update Enemies
	g.wave_timer += dt
	mut active_count := 0

	// Adaptive swoop probability based on remaining enemies & stage
	swoop_chance := math.max(60, 300 - g.stage * 20)

	for mut e in g.enemies {
		if !e.active {
			continue
		}
		active_count++

		match e.mode {
			.formation {
				dx := e.home_x - e.x
				dy := e.home_y - e.y
				dist := f32(math.sqrt(dx * dx + dy * dy))
				if dist > 6.0 {
					// Smooth entrance to home slot
					e.x += (dx / dist) * 260.0 * dt
					e.y += (dy / dist) * 260.0 * dt
				} else {
					// Authentic breathing grid oscillation
					sway := f32(math.sin(g.wave_timer * 2.2 + e.home_x * 0.02)) * 14.0
					bob := f32(math.cos(g.wave_timer * 1.8 + e.home_y * 0.03)) * 6.0
					e.x = e.home_x + sway
					e.y = e.home_y + bob
				}

				if rand.intn(swoop_chance) or { 0 } == 1 && g.wave_timer > 2.0 && g.stage_intro_timer <= 0 {
					e.mode = .swooping
					e.swoop_time = 0.0
					g.sound_mgr.play_enemy_dive()
				}
			}
			.swooping {
				e.swoop_time += dt
				base_dy := (e.swoop_speed + f32(g.stage) * 12.0) * dt
				e.y += base_dy

				// Diverse curve patterns
				match e.swoop_pattern {
					0 {
						e.x += f32(math.sin(e.swoop_time * 3.5)) * 180.0 * dt
					}
					1 {
						e.x += f32(math.cos(e.swoop_time * 4.2)) * 220.0 * dt
					}
					2 {
						e.x += f32(math.sin(e.swoop_time * 2.5)) * 140.0 * dt
					}
					else {
						// Aim toward player
						target_dx := if g.player.x > e.x { f32(100.0) } else { f32(-100.0) }
						e.x += target_dx * dt
					}
				}

				// Enemy shooting while diving
				fire_rate := math.max(40, 120 - g.stage * 8)
				if rand.intn(fire_rate) or { 0 } == 1 && e.y > 60 && e.y < 460 {
					eb_speed := 340.0 + f32(g.stage) * 18.0
					bullet_dx := (g.player.x - e.x) * 0.4
					g.enemy_bullets << Bullet{
						x:        e.x
						y:        e.y + 10.0
						vx:       bullet_dx
						vy:       eb_speed
						is_enemy: true
						active:   true
					}
					g.sound_mgr.play_enemy_bullet()
				}

				// Tractor beam trigger by Boss
				if e.enemy_type == .boss && !g.tractor_active && !g.player.is_dual && !g.player.is_capturing
					&& e.y > 180 && e.y < 280 && rand.intn(3) or { 0 } == 0 {
					e.mode = .tractor_beam
					e.tractor_timer = 3.5 // Beam stays active for at most 3.5 seconds
					g.tractor_active = true
					g.tractor_enemy_id = e.id
					g.sound_mgr.play_tractor_beam_sound()
				}

				// Screen loop around back to top
				if e.y > 640 {
					e.y = -40.0
					e.mode = .returning
				}
			}
			.tractor_beam {
				if g.tractor_enemy_id == e.id {
					e.tractor_timer -= dt
					g.tractor_beam_y = e.y + 20.0
					beam_width := f32(90.0)

					// Check if player is caught in the beam
					if !g.player.is_capturing && math.abs(g.player.x - e.x) < beam_width / 2.0 && g.player.y > g.tractor_beam_y {
						g.player.is_capturing = true
						g.sound_mgr.play_tractor_beam_sound()
					}

					// If capturing, pull player up along beam
					if g.player.is_capturing {
						g.player.y -= 140.0 * dt
						g.player.x += (e.x - g.player.x) * 6.0 * dt

						if g.player.y <= e.y + 35.0 {
							// Captured!
							g.player.is_captured = true
							g.player.is_capturing = false
							e.has_captured = true
							g.captured_ship_x = e.x
							g.captured_ship_y = e.y + 35.0
							g.tractor_active = false
							g.tractor_enemy_id = -1
							e.mode = .returning
							g.sound_mgr.play_player_captured()
							g.handle_player_death()
						}
					}

					// Timeout tractor beam if player escaped
					if e.tractor_timer <= 0 && !g.player.is_capturing {
						g.tractor_active = false
						g.tractor_enemy_id = -1
						e.mode = .swooping
					}
				}
			}
			.returning {
				// Fly smoothly to home
				dx := e.home_x - e.x
				dy := e.home_y - e.y
				dist := f32(math.sqrt(dx * dx + dy * dy))
				if dist > 8.0 {
					e.x += (dx / dist) * (260.0 + f32(g.stage) * 15.0) * dt
					e.y += (dy / dist) * (260.0 + f32(g.stage) * 15.0) * dt
				} else {
					e.mode = .formation
				}
				if e.has_captured {
					g.captured_ship_x = e.x
					g.captured_ship_y = e.y + 35.0
				}
			}
		}
	}

	// Wave Clear Condition -> Trigger Stage Clear Celebration & Advance
	if active_count == 0 && g.stage_clear_timer <= 0 {
		g.stage_clear_timer = 1.6
		mut clear_bonus := 1000 + g.stage * 200
		if g.is_challenge_stage && g.challenge_hits == g.challenge_total {
			clear_bonus += 10000
		}
		g.add_score(clear_bonus)
		g.sound_mgr.play_stage_clear_sound()
	}

	// Bullet - Enemy Collision Check
	for mut b in g.player_bullets {
		if !b.active {
			continue
		}
		for mut e in g.enemies {
			if !e.active {
				continue
			}
			dx := b.x - e.x
			dy := b.y - e.y
			if math.abs(dx) < 18.0 && math.abs(dy) < 18.0 {
				b.active = false
				e.hp--
				g.challenge_hits++
				if e.hp <= 0 {
					e.active = false
					points := match e.enemy_type {
						.zako { if e.mode == .formation { 50 } else { 100 } }
						.goei { if e.mode == .formation { 80 } else { 160 } }
						.boss { if e.mode == .formation { 150 } else { 400 } }
					}
					g.add_score(points)
					g.spawn_explosion(e.x, e.y, Color{
						r: 255
						g: 200
						b: 50
						a: 255
					})
					g.shake_trauma = f32(math.min(1.0, g.shake_trauma + match e.enemy_type {
						.boss { f32(0.30) }
						.goei { f32(0.18) }
						.zako { f32(0.12) }
					}))
					g.sound_mgr.play_kill_enemy(e.enemy_type, e.mode == .swooping)

					// If boss holding captured ship was destroyed:
					if e.has_captured {
						e.has_captured = false
						g.captured_ship_x = 0
						g.captured_ship_y = 0
						// Release rescuable ship
						g.rescuable_ships << RescuableShip{
							x:      e.x
							y:      e.y + 20.0
							vy:     120.0
							active: true
						}
					}
					// If tractor beam was active on this boss, disable it
					if g.tractor_enemy_id == e.id {
						g.tractor_active = false
						g.tractor_enemy_id = -1
						g.player.is_capturing = false
					}
				} else {
					g.shake_trauma = f32(math.min(1.0, g.shake_trauma + 0.15))
					g.sound_mgr.play_boss_hit()
				}
				break
			}
		}
	}

	// Enemy Bullet - Player Collision Check
	if g.player.invuln_timer <= 0 && !g.player.is_capturing {
		for mut eb in g.enemy_bullets {
			if !eb.active {
				continue
			}
			dx := eb.x - g.player.x
			dy := eb.y - g.player.y
			hit_dist := if g.player.is_dual { f32(26.0) } else { f32(16.0) }
			if math.abs(dx) < hit_dist && math.abs(dy) < 16.0 {
				eb.active = false
				g.handle_player_death()
				break
			}
		}

		// Enemy Ship - Player Ramming Check
		for mut e in g.enemies {
			if !e.active || e.mode == .formation {
				continue
			}
			dx := e.x - g.player.x
			dy := e.y - g.player.y
			hit_dist := if g.player.is_dual { f32(28.0) } else { f32(18.0) }
			if math.abs(dx) < hit_dist && math.abs(dy) < 18.0 {
				e.active = false
				g.spawn_explosion(e.x, e.y, Color{
					r: 255
					g: 100
					b: 50
					a: 255
				})
				g.handle_player_death()
				break
			}
		}
	}

	// Update Particles
	for mut p in g.particles {
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.life -= dt
	}
	g.particles = g.particles.filter(it.life > 0)
	g.player_bullets = g.player_bullets.filter(it.active)
	g.enemy_bullets = g.enemy_bullets.filter(it.active)
	g.rescuable_ships = g.rescuable_ships.filter(it.active)
}

fn (mut g GalagaGame) handle_player_death() {
	g.shake_trauma = f32(math.min(1.0, g.shake_trauma + 0.65))
	g.spawn_explosion(g.player.x, g.player.y, Color{
		r: 255
		g: 80
		b: 80
		a: 255
	})
	g.sound_mgr.play_player_death()

	if g.player.is_dual {
		g.player.is_dual = false
		g.player.invuln_timer = 2.5
	} else {
		g.player.lives--
		if g.player.lives <= 0 {
			g.state = .game_over
			g.sound_mgr.play_game_over_sound()
		} else {
			g.player.x = 400.0
			g.player.y = 540.0
			g.player.is_capturing = false
			g.player.invuln_timer = 3.0
		}
	}
}

fn (mut g GalagaGame) add_score(pts int) {
	g.score += pts
	if g.score > g.high_score {
		g.high_score = g.score
	}
}

fn (mut g GalagaGame) update_stars(dt f32) {
	for mut s in g.stars {
		s.y += s.speed * 60.0 * dt
		if s.y > 600 {
			s.y = 0
			s.x = f32(rand.intn(800) or { 400 })
		}
	}
}

fn (mut g GalagaGame) spawn_explosion(x f32, y f32, color Color) {
	for _ in 0 .. 22 {
		angle := f32(rand.intn(360) or { 0 }) * f32(math.pi) / 180.0
		speed := f32(rand.intn(180) or { 60 }) + 50.0
		g.particles << Particle{
			x:        x
			y:        y
			vx:       f32(math.cos(angle)) * speed
			vy:       f32(math.sin(angle)) * speed
			life:     0.35 + f32(rand.intn(25) or { 0 }) / 100.0
			max_life: 0.60
			color:    color
		}
	}
}
