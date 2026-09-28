module main

import gg
import math
import rand
import time

struct App {
mut:
	ctx		&gg.Context = unsafe { nil }
	renderer	Renderer
	game        PongGame
	sound_mgr   SoundManager
	tex_mgr     PongTextureManager
	particles   []Particle
	mouse_x     int
	mouse_y     int
	key_w       bool
	key_s       bool
	key_up      bool
	key_down    bool
	btn_restart Button
	btn_mode    Button
	btn_sound   Button
	toast_text   string
	toast_timer  f64
	shake_trauma f64
	last_tick    i64
}

fn new_app() App {
	mut app := App{
		game:        new_pong_game()
		sound_mgr:   new_sound_manager()
		btn_restart: Button{
			x:            70
			y:            620
			w:            220
			h:            44
			text:         'RESTART [R]'
			bg_color:     gg.Color{r: 35, g: 45, b: 70, a: 255}
			hover_color:  gg.Color{r: 55, g: 70, b: 105, a: 255}
			text_color:   gg.Color{r: 255, g: 255, b: 255, a: 255}
			border_color: gg.Color{r: 70, g: 130, b: 230, a: 255}
		}
		btn_mode:    Button{
			x:            310
			y:            620
			w:            220
			h:            44
			text:         'MODE: VS CPU [M]'
			bg_color:     gg.Color{r: 35, g: 45, b: 70, a: 255}
			hover_color:  gg.Color{r: 55, g: 70, b: 105, a: 255}
			text_color:   gg.Color{r: 255, g: 255, b: 255, a: 255}
			border_color: gg.Color{r: 70, g: 130, b: 230, a: 255}
		}
		btn_sound:   Button{
			x:            550
			y:            620
			w:            220
			h:            44
			text:         'SOUND: ON [S]'
			bg_color:     gg.Color{r: 35, g: 45, b: 70, a: 255}
			hover_color:  gg.Color{r: 55, g: 70, b: 105, a: 255}
			text_color:   gg.Color{r: 255, g: 255, b: 255, a: 255}
			border_color: gg.Color{r: 70, g: 130, b: 230, a: 255}
		}
		last_tick:   time.ticks()
	}
	return app
}

fn (mut app App) show_toast(msg string) {
	app.toast_text = msg
	app.toast_timer = 2.0
}

fn (mut app App) spawn_hit_particles(cx f64, cy f64, color gg.Color) {
	for _ in 0 .. 12 {
		angle := rand.f64() * math.pi * 2.0
		speed := 1.5 + rand.f64() * 5.0
		app.particles << Particle{
			x:     cx
			y:     cy
			vx:    math.cos(angle) * speed
			vy:    math.sin(angle) * speed
			life:  1.0
			color: color
			size:  3 + rand.intn(3) or { 3 }
		}
	}
}

fn (mut app App) update_particles() {
	for i := app.particles.len - 1; i >= 0; i-- {
		app.particles[i].x += app.particles[i].vx
		app.particles[i].y += app.particles[i].vy
		app.particles[i].life -= 0.035
		if app.particles[i].life <= 0 {
			app.particles.delete(i)
		}
	}
}

fn (mut app App) update_game() {
	now := time.ticks()
	dt := f64(now - app.last_tick) / 1000.0
	app.last_tick = now

	if app.toast_timer > 0 {
		app.toast_timer -= dt
		if app.toast_timer < 0 {
			app.toast_timer = 0
		}
	}

	if app.game.mode == .pve {
		p1_up := app.key_w || app.key_up
		p1_down := app.key_s || app.key_down
		app.game.update_p1(p1_up, p1_down)
		app.game.update_p2(false, false)
	} else {
		app.game.update_p1(app.key_w, app.key_s)
		app.game.update_p2(app.key_up, app.key_down)
	}

	hit_paddle, hit_wall, scored_goal := app.game.step()
	if hit_paddle {
		ball_speed := math.sqrt(app.game.ball.vx * app.game.ball.vx + app.game.ball.vy * app.game.ball.vy)
		app.sound_mgr.play_hit_sound(ball_speed)
		color := if app.game.ball.vx > 0 { gg.Color{r: 255, g: 70, b: 90, a: 255} } else { gg.Color{r: 50, g: 230, b: 255, a: 255} }
		app.spawn_hit_particles(app.game.ball.x, app.game.ball.y, color)
		trauma := 0.20 + (ball_speed / 13.0) * 0.25
		app.shake_trauma = math.min(1.0, app.shake_trauma + trauma)
		prod_fx_trigger_shake(f32(trauma * 0.4))
		spark_r := if app.game.ball.vx > 0 { u8(255) } else { u8(60) }
		spark_g := if app.game.ball.vx > 0 { u8(90) } else { u8(230) }
		spark_b := if app.game.ball.vx > 0 { u8(120) } else { u8(255) }
		prod_fx_trigger_sparks(f32(app.game.ball.x), f32(app.game.ball.y), f32(app.game.ball.vx * 6), f32(app.game.ball.vy * 6), 8, spark_r, spark_g, spark_b)
	} else if hit_wall {
		app.sound_mgr.play_wall_sound()
		app.shake_trauma = math.min(1.0, app.shake_trauma + 0.12)
		prod_fx_trigger_shake(0.08)
	} else if scored_goal {
		app.sound_mgr.play_score_sound()
		app.shake_trauma = 0.55
		prod_fx_trigger_shake(0.55)
		prod_fx_trigger_shockwave(f32(app.game.ball.x), f32(app.game.ball.y), 160.0, 255, 230, 80)
		prod_fx_trigger_sparks(f32(app.game.ball.x), f32(app.game.ball.y), 0, 0, 24, 255, 220, 60)
		prod_fx_trigger_floating_score(f32(app.game.ball.x), f32(app.game.ball.y), 1, 255, 240, 100)
		for _ in 0 .. 3 {
			app.spawn_hit_particles(app.game.ball.x, app.game.ball.y, gg.Color{r: 255, g: 220, b: 40, a: 255})
			app.spawn_hit_particles(app.game.ball.x, app.game.ball.y, gg.Color{r: 255, g: 80, b: 220, a: 255})
		}
		if app.game.game_over {
			app.sound_mgr.play_win_sound()
			prod_fx_trigger_shake(0.8)
		}
	}

	// Spawn sparkling plasma embers drifting from the ball
	if !app.game.game_over && !app.game.is_paused {
		speed := math.sqrt(app.game.ball.vx * app.game.ball.vx + app.game.ball.vy * app.game.ball.vy)
		particle_col := if speed >= 11.0 {
			gg.Color{r: 255, g: 230, b: 120, a: 255}
		} else if speed >= 8.5 {
			gg.Color{r: 255, g: 100, b: 240, a: 255}
		} else {
			gg.Color{r: 70, g: 210, b: 255, a: 255}
		}
		app.particles << Particle{
			x:     app.game.ball.x + f64(ball_size) / 2.0 + (rand.f64() * 4.0 - 2.0)
			y:     app.game.ball.y + f64(ball_size) / 2.0 + (rand.f64() * 4.0 - 2.0)
			vx:    -app.game.ball.vx * 0.12 + (rand.f64() * 1.5 - 0.75)
			vy:    -app.game.ball.vy * 0.12 + (rand.f64() * 1.5 - 0.75)
			life:  0.4
			color: particle_col
			size:  if speed > 9.0 { 3 } else { 2 }
		}
	}
}

fn (mut app App) render() {
	ctx := app.ctx

	// Apply camera trauma shake
	mut sx := f32(0.0)
	mut sy := f32(0.0)
	if app.shake_trauma > 0 {
		app.shake_trauma = math.max(0.0, app.shake_trauma - 0.04)
		mag := f32(app.shake_trauma * app.shake_trauma * 16.0)
		sx = (rand.f32() * 2.0 - 1.0) * mag
		sy = (rand.f32() * 2.0 - 1.0) * mag
	}
	app.renderer.offset_x += sx
	app.renderer.offset_y += sy
	defer {
		app.renderer.offset_x -= sx
		app.renderer.offset_y -= sy
	}

	// Court Background - fills entire widescreen monitor
	min_x, min_y, max_x, max_y := app.renderer.visible_bounds()
	app.renderer.draw_rect_filled(min_x, min_y, max_x - min_x, max_y - min_y, gg.Color{r: 15, g: 18, b: 30, a: 255})

	// Court Boundary & Center Net
	app.renderer.draw_rounded_rect_empty(20, 20, court_w - 40, court_h - 110, 8, gg.Color{r: 45, g: 55, b: 85, a: 160})

	dash_h := 12
	gap := 8
	for y := 24; y < court_h - 100; y += dash_h + gap {
		app.renderer.draw_rect_filled(court_w / 2 - 2, f32(y), 4, f32(dash_h), gg.Color{r: 60, g: 75, b: 110, a: 120})
	}
	app.renderer.draw_circle_empty(court_w / 2, (court_h - 90) / 2, 70, gg.Color{r: 60, g: 75, b: 110, a: 90})

	// Header: Title & Scores
	app.renderer.draw_text(court_w / 2, 38, 'HYPER PONG',
		size:          28
		color:         gg.white
		align:         .center
		vertical_align: .middle
	)

	draw_glass_card(&app.renderer, 40, 48, 220, 44, gg.Color{r: 235, g: 45, b: 60, a: 255})
	app.renderer.draw_text(150, 70, 'P1: ${app.game.score_p1}',
		size:          22
		color:         gg.Color{r: 255, g: 120, b: 135, a: 255}
		align:         .center
		vertical_align: .middle
	)

	draw_glass_card(&app.renderer, court_w - 260, 48, 220, 44, gg.Color{r: 40, g: 220, b: 240, a: 255})
	p2_label := if app.game.mode == .pve {
		'AI: ${app.game.score_p2}'
	} else {
		'P2: ${app.game.score_p2}'
	}
	app.renderer.draw_text(court_w - 150, 70, p2_label,
		size:          22
		color:         gg.Color{r: 120, g: 240, b: 255, a: 255}
		align:         .center
		vertical_align: .middle
	)

	// Ball Trail
	draw_ball_trail(&app.renderer, app.game.ball.trail, app.game.ball.x, app.game.ball.y, math.sqrt(app.game.ball.vx * app.game.ball.vx + app.game.ball.vy * app.game.ball.vy))

	// Paddles & Ball
	draw_paddle_sprite(&app.renderer, int(app.game.p1.x), int(app.game.p1.y), paddle_w, paddle_h, true, &app.tex_mgr)
	draw_paddle_sprite(&app.renderer, int(app.game.p2.x), int(app.game.p2.y), paddle_w, paddle_h, false, &app.tex_mgr)
	draw_ball_sprite(&app.renderer, int(app.game.ball.x), int(app.game.ball.y), ball_size, &app.tex_mgr)

	// Particles
	for p in app.particles {
		app.renderer.draw_rect_filled(f32(p.x), f32(p.y), f32(p.size), f32(p.size), p.color)
	}

	// Status Overlay if paused or game over
	if app.game.game_over {
		winner_str := if app.game.winner_p1 { 'PLAYER 1 WINS!' } else { 'PLAYER 2 WINS!' }
		app.renderer.draw_text(court_w / 2, court_h / 2 - 20, winner_str,
			size:          36
			color:         gg.Color{r: 255, g: 220, b: 50, a: 255}
			align:         .center
			vertical_align: .middle
		)
		app.renderer.draw_text(court_w / 2, court_h / 2 + 30, 'Press R or Click Restart',
			size:          20
			color:         gg.white
			align:         .center
			vertical_align: .middle
		)
	} else if app.game.is_paused {
		app.renderer.draw_text(court_w / 2, court_h / 2, 'PAUSED [SPACE]',
			size:          34
			color:         gg.Color{r: 255, g: 200, b: 80, a: 255}
			align:         .center
			vertical_align: .middle
		)
	}

	// Toast Notification
	if app.toast_timer > 0 {
		draw_glass_card(&app.renderer, court_w / 2 - 120, court_h - 150, 240, 36, gg.Color{r: 100, g: 220, b: 120, a: 255})
		app.renderer.draw_text(court_w / 2, court_h - 132, app.toast_text,
			size:          18
			color:         gg.Color{r: 120, g: 255, b: 150, a: 255}
			align:         .center
			vertical_align: .middle
		)
	}

	// Bottom UI Buttons
	app.btn_restart.draw(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_mode.draw(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_sound.draw(&app.renderer, app.mouse_x, app.mouse_y)

	// Polish FX: Vignette & Sparkles
	prod_fx_render(ctx)
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	app.update_game()
	app.update_particles()
	app.sound_mgr.update()
	app.sound_mgr.update_bgm(!app.game.game_over)
	app.render()

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
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				ws := app.ctx.window_size()
				if prod_fx_handle_mouse(mx, my, ws.width, ws.height) {
					return
				}
				if app.btn_restart.is_hovered(mx, my) {
					app.sound_mgr.play_click_sound()
					app.game.reset()
					app.show_toast('Game Restarted')
				} else if app.btn_mode.is_hovered(mx, my) {
					app.sound_mgr.play_click_sound()
					app.game.mode = if app.game.mode == .pve { GameMode.pvp } else { GameMode.pve }
					app.btn_mode.text = if app.game.mode == .pve { 'MODE: VS CPU [M]' } else { 'MODE: 2 PLAYERS [M]' }
					app.show_toast('Mode Changed')
				} else if app.btn_sound.is_hovered(mx, my) {
					enabled := app.sound_mgr.toggle_sound()
					app.btn_sound.text = if enabled { 'SOUND: ON [S]' } else { 'SOUND: OFF [S]' }
					app.show_toast(if enabled { 'Sound Enabled' } else { 'Sound Muted' })
				}
			}
		}
		.key_down {
			match e.key_code {
				.f11, .grave_accent {
					gg.toggle_fullscreen()
				}
				.f10, .o {
					prod_fx_cycle_mode()
				}
				.w { app.key_w = true }
				.s { app.key_s = true }
				.up { app.key_up = true }
				.down { app.key_down = true }
				.r {
					app.sound_mgr.play_click_sound()
					app.game.reset()
					app.show_toast('Game Restarted')
				}
				.m {
					app.sound_mgr.play_click_sound()
					app.game.mode = if app.game.mode == .pve { GameMode.pvp } else { GameMode.pve }
					app.btn_mode.text = if app.game.mode == .pve { 'MODE: VS CPU [M]' } else { 'MODE: 2 PLAYERS [M]' }
					app.show_toast('Mode Changed')
				}
				.b {
					music_on := app.sound_mgr.toggle_music()
					app.show_toast(if music_on { 'Music: ON' } else { 'Music: OFF' })
				}
				.n {
					sfx_on := app.sound_mgr.toggle_sfx()
					app.btn_sound.text = if sfx_on { 'SOUND: ON [S]' } else { 'SOUND: OFF [S]' }
					app.show_toast(if sfx_on { 'Sound FX: ON' } else { 'Sound FX: OFF' })
				}
				.space {
					app.game.is_paused = !app.game.is_paused
					prod_fx_set_paused(app.game.is_paused)
				}
				.f5 {
					data_save := SaveData{
						high_score:       math.max(app.game.score_p1, app.game.score_p2)
						save_state_valid: true
						score:            app.game.score_p1
					}
					save_data_to_file(&data_save)
					app.show_toast('Game Saved (F5)')
				}
				.f9 {
					saved := load_save_data()
					if saved.save_state_valid {
						app.game.score_p1 = saved.score
						app.show_toast('Game Loaded (F9)')
					}
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.w { app.key_w = false }
				.s { app.key_s = false }
				.up { app.key_up = false }
				.down { app.key_down = false }
				else {}
			}
		}
		else {}
	}
}

fn on_init(data voidptr) {
	mut app := unsafe { &App(data) }
	app.tex_mgr.init(app.ctx)
}

fn main() {
	mut app := new_app()

	app.ctx = gg.new_context(
		width:         court_w
		height:        court_h
		window_title:  'Hyper Pong [GG + Sokol]'
		user_data:     &app
		init_fn:       on_init
		frame_fn:      on_frame
		event_fn:      on_event
		bg_color:      gg.Color{r: 15, g: 18, b: 30, a: 255}
		resizable:     true
		create_window: true
	)

	app.renderer = Renderer{
		ctx: app.ctx
		width: court_w
		height: court_h
	}
	app.ctx.run()
	app.sound_mgr.cleanup()
}
