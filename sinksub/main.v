module main

import math
import rand
import gg
import time

struct App {
mut:
	ctx           &gg.Context = unsafe { nil }
	renderer      Renderer
	last_tick     i64
	game            GameEngine
	sound_mgr       SoundManager
	particles       []Particle
	shockwaves      []ShockwaveRing
	float_texts     []FloatText
	camera_shake    f64
	red_flash_timer f64
	mouse_x         int
	mouse_y         int
	key_left        bool
	key_right       bool
	btn_start       Button
	btn_easy        Button
	btn_norm        Button
	btn_hard        Button
	btn_next_sec    Button
	btn_buy_eng     Button
	btn_buy_load    Button
	btn_buy_hull    Button
	btn_buy_blast   Button
	btn_restart     Button
	btn_sound       Button
}

fn new_app() App {
	mut app := App{
		game:          new_game_engine()
		sound_mgr:     new_sound_manager()
		btn_start:     Button{
			x:            350
			y:            480
			w:            300
			h:            52
			text:         'ENGAGE SEA PATROL'
			bg_color:     Color{
				r: 6
				g: 182
				b: 212
			}
			hover_color:  Color{
				r: 34
				g: 211
				b: 238
			}
			text_color:   Color{
				r: 15
				g: 23
				b: 42
			}
			border_color: Color{
				r: 250
				g: 204
				b: 21
			}
		}
		btn_easy:      Button{
			x:            320
			y:            400
			w:            110
			h:            40
			text:         'EASY'
			bg_color:     Color{
				r: 30
				g: 41
				b: 59
			}
			hover_color:  Color{
				r: 51
				g: 65
				b: 85
			}
			text_color:   Color{
				r: 255
				g: 255
				b: 255
			}
			border_color: Color{
				r: 71
				g: 85
				b: 105
			}
		}
		btn_norm:      Button{
			x:            445
			y:            400
			w:            110
			h:            40
			text:         'NORMAL'
			bg_color:     Color{
				r: 6
				g: 182
				b: 212
			}
			hover_color:  Color{
				r: 34
				g: 211
				b: 238
			}
			text_color:   Color{
				r: 15
				g: 23
				b: 42
			}
			border_color: Color{
				r: 250
				g: 204
				b: 21
			}
		}
		btn_hard:      Button{
			x:            570
			y:            400
			w:            110
			h:            40
			text:         'HARD'
			bg_color:     Color{
				r: 30
				g: 41
				b: 59
			}
			hover_color:  Color{
				r: 51
				g: 65
				b: 85
			}
			text_color:   Color{
				r: 255
				g: 255
				b: 255
			}
			border_color: Color{
				r: 71
				g: 85
				b: 105
			}
		}
		btn_next_sec:  Button{
			x:            320
			y:            520
			w:            360
			h:            48
			text:         'NEXT SECTOR DEPART ➡️'
			bg_color:     Color{
				r: 16
				g: 185
				b: 129
			}
			hover_color:  Color{
				r: 52
				g: 211
				b: 153
			}
			text_color:   Color{
				r: 15
				g: 23
				b: 42
			}
			border_color: Color{
				r: 250
				g: 204
				b: 21
			}
		}
		btn_buy_eng:   Button{
			x:            620
			y:            280
			w:            90
			h:            36
			text:         '$200'
			bg_color:     Color{
				r: 30
				g: 41
				b: 59
			}
			hover_color:  Color{
				r: 51
				g: 65
				b: 85
			}
			text_color:   Color{
				r: 250
				g: 204
				b: 21
			}
			border_color: Color{
				r: 71
				g: 85
				b: 105
			}
		}
		btn_buy_load:  Button{
			x:            620
			y:            335
			w:            90
			h:            36
			text:         '$250'
			bg_color:     Color{
				r: 30
				g: 41
				b: 59
			}
			hover_color:  Color{
				r: 51
				g: 65
				b: 85
			}
			text_color:   Color{
				r: 250
				g: 204
				b: 21
			}
			border_color: Color{
				r: 71
				g: 85
				b: 105
			}
		}
		btn_buy_hull:  Button{
			x:            620
			y:            390
			w:            90
			h:            36
			text:         '$300'
			bg_color:     Color{
				r: 30
				g: 41
				b: 59
			}
			hover_color:  Color{
				r: 51
				g: 65
				b: 85
			}
			text_color:   Color{
				r: 250
				g: 204
				b: 21
			}
			border_color: Color{
				r: 71
				g: 85
				b: 105
			}
		}
		btn_buy_blast: Button{
			x:            620
			y:            445
			w:            90
			h:            36
			text:         '$200'
			bg_color:     Color{
				r: 30
				g: 41
				b: 59
			}
			hover_color:  Color{
				r: 51
				g: 65
				b: 85
			}
			text_color:   Color{
				r: 250
				g: 204
				b: 21
			}
			border_color: Color{
				r: 71
				g: 85
				b: 105
			}
		}
		btn_restart:   Button{
			x:            375
			y:            440
			w:            250
			h:            48
			text:         'RESTART OPERATION'
			bg_color:     Color{
				r: 239
				g: 68
				b: 68
			}
			hover_color:  Color{
				r: 248
				g: 113
				b: 113
			}
			text_color:   Color{
				r: 255
				g: 255
				b: 255
			}
			border_color: Color{
				r: 250
				g: 204
				b: 21
			}
		}
		btn_sound:     Button{
			x:            840
			y:            12
			w:            140
			h:            28
			text:         'SOUND: ON [O]'
			bg_color:     Color{
				r: 15
				g: 23
				b: 42
			}
			hover_color:  Color{
				r: 30
				g: 41
				b: 59
			}
			text_color:   Color{
				r: 80
				g: 240
				b: 140
			}
			border_color: Color{
				r: 71
				g: 85
				b: 105
			}
		}
	}
	return app
}



fn (mut app App) spawn_sub_explosion(cx f64, cy f64, sub_kind SubType, points int) {
	// 1. Concentric Shockwave Water Rings
	is_big := sub_kind == .boss || sub_kind == .heavy
	max_radius := if is_big { 100.0 } else { 65.0 }
	app.shockwaves << ShockwaveRing{
		x:        cx
		y:        cy
		r:        4.0
		max_r:    max_radius
		life:     0.0
		max_life: 0.45
		col:      Color{100, 240, 255, 220}
	}
	app.shockwaves << ShockwaveRing{
		x:        cx
		y:        cy
		r:        2.0
		max_r:    max_radius * 0.65
		life:     0.0
		max_life: 0.35
		col:      Color{255, 200, 60, 240}
	}

	// 2. Metallic Shrapnel & Hull Debris
	shrapnel_count := if is_big { 28 } else { 16 }
	shrapnel_colors := [
		Color{148, 163, 184, 255}, // slate metal
		Color{71, 85, 105, 255},   // dark steel
		Color{245, 158, 11, 255},  // copper/brass
		Color{30, 41, 59, 255},    // charred hull
	]
	for _ in 0 .. shrapnel_count {
		angle := rand.f64() * 6.28
		speed := 2.5 + rand.f64() * 6.5
		col := shrapnel_colors[rand.intn(shrapnel_colors.len) or { 0 }]
		app.particles << Particle{
			x:           cx
			y:           cy
			vx:          math.cos(angle) * speed
			vy:          math.sin(angle) * speed
			life:        1.0
			max_life:    1.0
			color:       col
			size:        f64(3 + rand.intn(6) or { 3 })
			is_shrapnel: true
			rot:         rand.f64() * 6.28
			vrot:        (rand.f64() - 0.5) * 14.0
		}
	}

	// 3. Underwater Fireball & Dense Smoke
	fire_count := if is_big { 35 } else { 20 }
	for _ in 0 .. fire_count {
		angle := rand.f64() * 6.28
		speed := 1.0 + rand.f64() * 4.0
		is_f := rand.f64() > 0.35
		col := if is_f { Color{255, 120 + u8(rand.intn(80) or { 0 }), 30, 240} } else { Color{40, 50, 65, 200} }
		app.particles << Particle{
			x:        cx
			y:        cy
			vx:       math.cos(angle) * speed
			vy:       math.sin(angle) * speed
			life:     0.85
			max_life: 0.85
			color:    col
			size:     f64(4 + rand.intn(5) or { 4 })
			is_fire:  is_f
			is_smoke: !is_f
		}
	}

	// 4. Erupting Air Bubble Column
	bubble_count := if is_big { 45 } else { 25 }
	for _ in 0 .. bubble_count {
		app.particles << Particle{
			x:         cx + (rand.f64() - 0.5) * 24.0
			y:         cy + (rand.f64() - 0.5) * 14.0
			vx:        (rand.f64() - 0.5) * 2.2
			vy:        -1.5 - rand.f64() * 3.5
			life:      1.2
			max_life:  1.2
			color:     Color{210, 245, 255, 200}
			size:      f64(2 + rand.intn(4) or { 2 })
			is_bubble: true
		}
	}

	// 5. Floating Score Text
	txt := if sub_kind == .boss { '★ BOSS SUNK! +${points} ★' } else { '+${points} PTS' }
	app.float_texts << FloatText{
		x:     cx
		y:     cy - 18.0
		text:  txt
		life:  0.0
		color: Color{250, 204, 21, 255}
	}

	app.camera_shake = math.max(app.camera_shake, if is_big { 9.0 } else { 5.0 })
}

fn (mut app App) spawn_boat_hit_fx(cx f64, cy f64) {
	// 1. Violent Screen Trauma & Flash
	app.camera_shake = 18.0
	app.red_flash_timer = 0.45

	// 2. High-Velocity Geyser Water Spout Plume
	for _ in 0 .. 50 {
		app.particles << Particle{
			x:         cx + (rand.f64() - 0.5) * 36.0
			y:         cy
			vx:        (rand.f64() - 0.5) * 6.5
			vy:        -6.0 - rand.f64() * 8.5
			life:      1.1
			max_life:  1.1
			color:     Color{210, 245, 255, 240}
			size:      f64(2 + rand.intn(3) or { 2 })
			is_splash: true
		}
	}

	// 3. Fiery Hull Sparks & Splinters
	for _ in 0 .. 35 {
		angle := rand.f64() * 6.28
		speed := 2.5 + rand.f64() * 7.0
		is_f := rand.f64() > 0.4
		app.particles << Particle{
			x:           cx
			y:           cy - 8.0
			vx:          math.cos(angle) * speed
			vy:          math.sin(angle) * speed
			life:        0.9
			max_life:    0.9
			color:       if is_f { Color{255, 80, 20, 255} } else { Color{250, 204, 21, 255} }
			size:        f64(3 + rand.intn(4) or { 3 })
			is_fire:     is_f
			is_shrapnel: !is_f
			rot:         rand.f64() * 6.28
			vrot:        (rand.f64() - 0.5) * 16.0
		}
	}

	// 4. Surface Shockwaves
	app.shockwaves << ShockwaveRing{
		x:        cx
		y:        cy
		r:        6.0
		max_r:    90.0
		life:     0.0
		max_life: 0.5
		col:      Color{255, 80, 50, 240}
	}
	app.shockwaves << ShockwaveRing{
		x:        cx
		y:        cy
		r:        3.0
		max_r:    120.0
		life:     0.0
		max_life: 0.6
		col:      Color{255, 220, 100, 200}
	}

	// 5. Floating Alert
	app.float_texts << FloatText{
		x:     cx
		y:     cy - 35.0
		text:  'CRITICAL HULL HIT! -1 LIFE'
		life:  0.0
		color: Color{255, 60, 60, 255}
	}
}

fn (mut app App) spawn_charge_burst(cx f64, cy f64) {
	app.shockwaves << ShockwaveRing{
		x:        cx
		y:        cy
		r:        3.0
		max_r:    45.0
		life:     0.0
		max_life: 0.35
		col:      Color{250, 204, 21, 200}
	}
	for _ in 0 .. 15 {
		angle := rand.f64() * 6.28
		speed := 1.5 + rand.f64() * 3.5
		app.particles << Particle{
			x:        cx
			y:        cy
			vx:       math.cos(angle) * speed
			vy:       math.sin(angle) * speed
			life:     0.6
			max_life: 0.6
			color:    Color{255, 160, 40, 230}
			size:     3.0
			is_fire:  true
		}
	}
}

fn (mut app App) update_particles() {
	dt := 0.016

	// 1. Update Particles
	for i := app.particles.len - 1; i >= 0; i-- {
		mut p := app.particles[i]
		p.x += p.vx
		p.y += p.vy
		p.life -= dt / p.max_life

		if p.is_shrapnel {
			p.rot += p.vrot * dt
			p.vx *= 0.97
			p.vy = math.min(3.0, p.vy + 0.08)
		} else if p.is_bubble {
			p.vy -= 0.07 // Buoyancy!
			p.vx += math.sin(p.life * 12.0) * 0.06
			if p.y <= f64(water_level_y) {
				p.life = 0.0 // Pop at surface!
			}
		} else if p.is_splash {
			p.vy += 0.24 // Gravity!
			if p.y >= f64(water_level_y + 10) && p.vy > 0 {
				p.life = 0.0
			}
		} else if p.is_fire || p.is_smoke {
			p.size += 0.08
			p.vy -= 0.03
			p.vx *= 0.96
		}

		if p.life <= 0 {
			app.particles.delete(i)
		} else {
			app.particles[i] = p
		}
	}

	// 2. Update Shockwaves
	for i := app.shockwaves.len - 1; i >= 0; i-- {
		mut sw := app.shockwaves[i]
		sw.life += dt
		sw.r = sw.max_r * (sw.life / sw.max_life)
		if sw.life >= sw.max_life {
			app.shockwaves.delete(i)
		} else {
			app.shockwaves[i] = sw
		}
	}

	// 3. Update Float Texts
	for i := app.float_texts.len - 1; i >= 0; i-- {
		mut ft := app.float_texts[i]
		ft.y -= 0.9
		ft.life += dt
		if ft.life >= 1.4 {
			app.float_texts.delete(i)
		} else {
			app.float_texts[i] = ft
		}
	}

	// 4. Camera Shake & Red Flash Decay
	if app.camera_shake > 0.05 {
		app.camera_shake *= 0.88
	} else {
		app.camera_shake = 0.0
	}

	if app.red_flash_timer > 0.0 {
		app.red_flash_timer -= dt
	}
}

fn (mut app App) handle_mouse_click(x int, y int) {
	if app.btn_sound.is_hovered(x, y) {
		is_on := app.sound_mgr.toggle_sound()
		app.btn_sound.text = if is_on { 'SOUND: ON [O]' } else { 'SOUND: OFF [O]' }
		app.btn_sound.text_color = if is_on {
			Color{
				r: 80
				g: 240
				b: 140
			}
		} else {
			Color{
				r: 240
				g: 90
				b: 90
			}
		}
		return
	}

	if app.game.mode == .menu {
		if app.btn_easy.is_hovered(x, y) {
			app.game.difficulty = 'easy'
			app.btn_easy.bg_color = Color{
				r: 6
				g: 182
				b: 212
			}
			app.btn_norm.bg_color = Color{
				r: 30
				g: 41
				b: 59
			}
			app.btn_hard.bg_color = Color{
				r: 30
				g: 41
				b: 59
			}
		} else if app.btn_norm.is_hovered(x, y) {
			app.game.difficulty = 'normal'
			app.btn_easy.bg_color = Color{
				r: 30
				g: 41
				b: 59
			}
			app.btn_norm.bg_color = Color{
				r: 6
				g: 182
				b: 212
			}
			app.btn_hard.bg_color = Color{
				r: 30
				g: 41
				b: 59
			}
		} else if app.btn_hard.is_hovered(x, y) {
			app.game.difficulty = 'hard'
			app.btn_easy.bg_color = Color{
				r: 30
				g: 41
				b: 59
			}
			app.btn_norm.bg_color = Color{
				r: 30
				g: 41
				b: 59
			}
			app.btn_hard.bg_color = Color{
				r: 6
				g: 182
				b: 212
			}
		} else if app.btn_start.is_hovered(x, y) {
			app.game.start_new_game()
		}
	} else if app.game.mode == .shop {
		if app.btn_buy_eng.is_hovered(x, y) {
			if app.game.buy_upgrade('engine') {
				app.sound_mgr.play_powerup()
			}
		} else if app.btn_buy_load.is_hovered(x, y) {
			if app.game.buy_upgrade('loader') {
				app.sound_mgr.play_powerup()
			}
		} else if app.btn_buy_hull.is_hovered(x, y) {
			if app.game.buy_upgrade('hull') {
				app.sound_mgr.play_powerup()
			}
		} else if app.btn_buy_blast.is_hovered(x, y) {
			if app.game.buy_upgrade('blast') {
				app.sound_mgr.play_powerup()
			}
		} else if app.btn_next_sec.is_hovered(x, y) {
			app.game.start_sector(app.game.sector + 1)
			app.game.mode = .playing
		}
	} else if app.game.mode == .game_over {
		if app.btn_restart.is_hovered(x, y) {
			app.game.mode = .menu
		}
	}
}

fn (mut app App) render() {
	ticks := u32(time.ticks())

	// Apply Dynamic Screen Shake Offset
	if app.camera_shake > 0.0 {
		shake_x := int((rand.f64() * 2.0 - 1.0) * app.camera_shake)
		shake_y := int((rand.f64() * 2.0 - 1.0) * app.camera_shake)
		vp := Rect{x: shake_x, y: shake_y, w: ocean_width, h: ocean_height}
		render_set_viewport(&app.renderer, &vp)
	} else {
		full_vp := Rect{x: 0, y: 0, w: ocean_width, h: ocean_height}
		render_set_viewport(&app.renderer, &full_vp)
	}

	render_ocean_background(&app.renderer, ticks)

	// In-game World
	if app.game.mode == .playing || app.game.mode == .shop {
		// Player Boat
		render_ship(&app.renderer, app.game.ship, app.game.perks.shield > 0, ticks, app.game.sprite_texture)

		// Submarines
		for sub in app.game.subs {
			render_submarine(&app.renderer, sub, ticks, app.game.sprite_texture)
		}

		// Depth Charges
		for dc in app.game.charges {
			render_depth_charge(&app.renderer, dc, ticks, app.game.sprite_texture)
		}

		// Homing Torpedoes
		for torp in app.game.torpedoes {
			render_torpedo(&app.renderer, torp, ticks, app.game.sprite_texture)
		}

		// Spiked Naval Floatmines
		for mine in app.game.mines {
			render_mine(&app.renderer, mine, ticks, app.game.sprite_texture)
		}

		// Supply Crates
		for cr in app.game.crates {
			render_supply_crate(&app.renderer, cr, ticks, app.game.sprite_texture)
		}

		// Controls overlay hint at bottom
		draw_text_centered(&app.renderer, ocean_width / 2, ocean_height - 30, 'CONTROLS: ARROWS = MOVE | Z/J = STERN CHARGE | X/K = BOW ROCKET | SPACE = NUKE | F11: Fullscreen',
			1, Color{ r: 148, g: 163, b: 184 })
	}

	// Shockwave Rings & Particles
	render_shockwaves(&app.renderer, app.shockwaves)
	render_particles(&app.renderer, app.particles)
	render_float_texts(&app.renderer, app.float_texts)

	// Red Damage Flash Vignette
	render_damage_vignette(&app.renderer, app.red_flash_timer, ocean_width, ocean_height)

	// Overlay Modals
	if app.game.mode == .menu {
		draw_glass_card(&app.renderer, 250, 160, 500, 420, Color{ r: 6, g: 182, b: 212 })
		draw_text_centered(&app.renderer, ocean_width / 2, 190, 'SINKSUB PRO', 3, Color{
			r: 34
			g: 211
			b: 238
		})
		draw_text_centered(&app.renderer, ocean_width / 2, 230, 'TACTICAL OVERDRIVE', 2,
			Color{ r: 250, g: 204, b: 21 })

		draw_text_centered(&app.renderer, ocean_width / 2, 290, 'HIGH RECORD: ${app.game.high_score}',
			2, Color{ r: 148, g: 163, b: 184 })
		draw_text_centered(&app.renderer, ocean_width / 2, 350, 'SELECT DIFFICULTY:', 2,
			Color{ r: 255, g: 255, b: 255 })

		app.btn_easy.render(&app.renderer, app.mouse_x, app.mouse_y)
		app.btn_norm.render(&app.renderer, app.mouse_x, app.mouse_y)
		app.btn_hard.render(&app.renderer, app.mouse_x, app.mouse_y)
		app.btn_start.render(&app.renderer, app.mouse_x, app.mouse_y)
	} else if app.game.mode == .shop {
		draw_glass_card(&app.renderer, 250, 140, 500, 460, Color{ r: 16, g: 185, b: 129 })
		draw_text_centered(&app.renderer, ocean_width / 2, 165, 'SECTOR SECURED!', 3, Color{
			r: 52
			g: 211
			b: 153
		})
		draw_text_centered(&app.renderer, ocean_width / 2, 210, 'UPGRADE SHOP TERMINAL',
			2, Color{ r: 250, g: 204, b: 21 })
		draw_text_centered(&app.renderer, ocean_width / 2, 240, 'BUDGET: $${app.game.credits}',
			2, Color{ r: 255, g: 255, b: 255 })

		draw_text(&app.renderer, 280, 290, 'ENGINE HYDRO-THRUST (Lvl ${app.game.upgrades.engine})',
			1, Color{ r: 255, g: 255, b: 255 })
		app.btn_buy_eng.render(&app.renderer, app.mouse_x, app.mouse_y)

		draw_text(&app.renderer, 280, 345, 'RAPID AUTOLOADER (Lvl ${app.game.upgrades.loader})',
			1, Color{ r: 255, g: 255, b: 255 })
		app.btn_buy_load.render(&app.renderer, app.mouse_x, app.mouse_y)

		draw_text(&app.renderer, 280, 400, 'ARCLITE PLATED ARMOR (${app.game.upgrades.hull} Slots)',
			1, Color{ r: 255, g: 255, b: 255 })
		app.btn_buy_hull.render(&app.renderer, app.mouse_x, app.mouse_y)

		draw_text(&app.renderer, 280, 455, 'HIGH-YIELD EXPLOSIVES (Lvl ${app.game.upgrades.blast})',
			1, Color{ r: 255, g: 255, b: 255 })
		app.btn_buy_blast.render(&app.renderer, app.mouse_x, app.mouse_y)

		app.btn_next_sec.render(&app.renderer, app.mouse_x, app.mouse_y)
	} else if app.game.mode == .game_over {
		draw_glass_card(&app.renderer, 250, 160, 500, 380, Color{ r: 239, g: 68, b: 68 })
		draw_text_centered(&app.renderer, ocean_width / 2, 195, 'VESSEL SUNK', 3, Color{
			r: 248
			g: 113
			b: 113
		})
		draw_text_centered(&app.renderer, ocean_width / 2, 245, 'MISSION FAILED IN SECTOR ${app.game.sector}',
			2, Color{ r: 250, g: 204, b: 21 })
		draw_text_centered(&app.renderer, ocean_width / 2, 305, 'FINAL SCORE: ${app.game.score}',
			2, Color{ r: 255, g: 255, b: 255 })
		draw_text_centered(&app.renderer, ocean_width / 2, 345, 'HONORARY RANK: ${app.game.current_rank.title}',
			2, Color{ r: 148, g: 163, b: 184 })

		app.btn_restart.render(&app.renderer, app.mouse_x, app.mouse_y)
	}

	// Always-visible HUD in play
	if app.game.mode == .playing || app.game.mode == .shop {
		// Top glass status bar
		draw_glass_card(&app.renderer, 20, 12, ocean_width - 40, 44, Color{ r: 6, g: 182, b: 212 })

		// Rank & Title
		draw_text(&app.renderer, 40, 24, 'RANK: ${app.game.current_rank.title}', 2, Color{
			r: 250
			g: 204
			b: 21
		})

		// Score & Targets
		draw_text(&app.renderer, 300, 24, 'SCORE: ${app.game.score}', 2, Color{
			r: 255
			g: 255
			b: 255
		})
		draw_text(&app.renderer, 470, 24, 'SECTOR ${app.game.sector}: ${app.game.target_killed}/${app.game.req_to_clear}',
			2, Color{ r: 34, g: 211, b: 238 })

		// Lives Indicators
		draw_text(&app.renderer, 670, 24, 'HULL:', 2, Color{ r: 239, g: 68, b: 68 })
		for i in 0 .. app.game.lives {
			draw_text(&app.renderer, 740 + i * 22, 24, '⚓', 2, Color{ r: 239, g: 68, b: 68 })
		}

		// Active Perks badges
		if app.game.perks.shield > 0 {
			draw_text(&app.renderer, 840, 24, '⚡SHIELD', 1, Color{ r: 34, g: 211, b: 238 })
		}
		if app.game.perks.nuke > 0 {
			draw_text(&app.renderer, 910, 24, '☢x${app.game.perks.nuke}', 1, Color{
				r: 250
				g: 204
				b: 21
			})
		}
	}

	app.btn_sound.render(&app.renderer, app.mouse_x, app.mouse_y)

	
	
}


fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	app.last_tick = time.ticks()


	_, exploded, powerup := app.game.update_step(app.key_left, app.key_right)

	if app.game.last_events.subs_destroyed.len > 0 {
		for destroyed in app.game.last_events.subs_destroyed {
			app.spawn_sub_explosion(destroyed.x + destroyed.w / 2.0, destroyed.y + destroyed.h / 2.0, destroyed.kind, destroyed.points)
		}
		app.sound_mgr.play_explosion(true)
	} else if app.game.last_events.charge_hit {
		app.spawn_charge_burst(app.game.last_events.charge_hit_x, app.game.last_events.charge_hit_y)
		app.sound_mgr.play_explosion(false)
	} else if exploded {
		app.sound_mgr.play_explosion(true)
	}

	if app.game.last_events.boat_hit {
		app.spawn_boat_hit_fx(app.game.last_events.boat_hit_x, app.game.last_events.boat_hit_y)
	}

	if powerup || app.game.last_events.powerup_got {
		app.sound_mgr.play_powerup()
	}

	app.sound_mgr.update_bgm(app.game.mode == .playing || app.game.mode == .shop)
	app.sound_mgr.update()
	app.update_particles()

	app.render()
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	if e.typ in [.mouse_move, .mouse_down, .mouse_up, .mouse_scroll] && app.renderer.scale > 0.001 {
		mut me := unsafe { &gg.Event(e) }
		me.mouse_x = (e.mouse_x - app.renderer.offset_x) / app.renderer.scale
		me.mouse_y = (e.mouse_y - app.renderer.offset_y) / app.renderer.scale
	}
	match e.typ {
		.mouse_move {
			app.mouse_x = int(e.mouse_x)
			app.mouse_y = int(e.mouse_y)
		}
		.mouse_down {
			mx := int(e.mouse_x)
			my := int(e.mouse_y)
			app.handle_mouse_click(mx, my)
		}
		.key_down {
			match e.key_code {
				.f11, .grave_accent {
					gg.toggle_fullscreen()
				}
				.f10 {
					prod_fx_cycle_mode()
				}
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.escape {
					exit(0)
				}
				.left, .a {
					app.key_left = true
				}
				.right, .d {
					app.key_right = true
				}
				.z, .j {
					if app.game.drop_stern_charge(u32(time.ticks())) {
						app.sound_mgr.play_launch()
					}
				}
				.x, .k {
					if app.game.throw_bow_charge(u32(time.ticks())) {
						app.sound_mgr.play_launch()
					}
				}
				.space {
					if app.game.trigger_nuke() {
						app.sound_mgr.play_nuke()
						app.spawn_sub_explosion(ocean_width / 2.0, ocean_height / 2.0, .boss, 1000)
					}
				}
				.o, .m {
					is_on := app.sound_mgr.toggle_sound()
					app.btn_sound.text = if is_on { 'SOUND: ON [O]' } else { 'SOUND: OFF [O]' }
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.left, .a {
					app.key_left = false
				}
				.right, .d {
					app.key_right = false
				}
				else {}
			}
		}
		else {}
	}
}

fn main() {
	mut app := new_app()
	mut ctx := gg.new_context(
		width: ocean_width
		height: ocean_height
		resizable:     true
		window_title: 'SinkSub Pro // Tactical Naval Patrol'
		user_data: &app
		frame_fn: on_frame
		event_fn: on_event
		bg_color: gg.Color{10, 15, 25, 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{ctx: ctx}
	app.game.init_textures(&app.renderer)
	ctx.run()
}
