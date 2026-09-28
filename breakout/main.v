module main

import gg
import math
import rand
import time

struct App {
mut:
	ctx             &gg.Context = unsafe { nil }
	renderer        Renderer
	game            BreakoutGame
	sound_mgr       SoundManager
	tex_mgr         BreakoutTextureManager
	particles       []Particle
	paddle_target_x f64 = world_w / 2.0
	mouse_x         int = int(world_w / 2.0)
	mouse_y         int
	key_left        bool
	key_right       bool
	key_launch      bool
	key_fire        bool
	paused          bool
	btn_restart     Button
	btn_level       Button
	btn_sound       Button
	last_tick       i64
	high_score      int
}

fn new_app() App {
	saved := load_save_data()
	mut app := App{
		game:        new_breakout_game()
		sound_mgr:   new_sound_manager()
		high_score:  saved.high_score
		btn_restart: Button{
			x:            100
			y:            565
			w:            170
			h:            30
			text:         'RESTART [R]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 60, b: 90}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 70, g: 90, b: 140}
		}
		btn_level:   Button{
			x:            310
			y:            565
			w:            180
			h:            30
			text:         'NEXT LEVEL [L]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 60, b: 90}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 70, g: 90, b: 140}
		}
		btn_sound:   Button{
			x:            520
			y:            565
			w:            170
			h:            30
			text:         'SOUND: ON [O]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 60, b: 90}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 70, g: 90, b: 140}
		}
		last_tick:   time.ticks()
	}
	return app
}

fn (mut app App) spawn_particles(x f64, y f64, count int, color Color) {
	for _ in 0 .. count {
		angle := rand.f64() * 2.0 * math.pi
		speed := 40.0 + rand.f64() * 140.0
		life := 0.2 + rand.f64() * 0.4
		app.particles << Particle{
			x:        x
			y:        y
			dx:       math.cos(angle) * speed
			dy:       math.sin(angle) * speed
			life:     life
			max_life: life
			color:    color
			size:     2.0 + rand.f64() * 3.0
		}
	}
}

fn (mut app App) reset_game() {
	app.game.reset()
	app.particles.clear()
	app.paddle_target_x = world_w / 2.0
	app.key_launch = false
	app.key_fire = false
}

fn (mut app App) update(dt f64) {
	if app.paused {
		return
	}

	// Move paddle with smooth acceleration
	if app.key_left {
		app.paddle_target_x -= 550.0 * dt
	} else if app.key_right {
		app.paddle_target_x += 550.0 * dt
	}
	if app.paddle_target_x < 10.0 {
		app.paddle_target_x = 10.0
	} else if app.paddle_target_x > f64(world_w - 10) {
		app.paddle_target_x = f64(world_w - 10)
	}

	app.game.step(dt, app.paddle_target_x, app.key_launch, app.key_fire)

	if app.key_launch || app.key_fire {
		app.key_launch = false
		app.key_fire = false
	}
	if app.game.score > app.high_score {
		app.high_score = app.game.score
	}

	// Fireball particle trail
	if app.game.paddle.fireball_timer > 0.0 {
		for ball in app.game.balls {
			if !ball.attached {
				app.spawn_particles(ball.x, ball.y, 2, Color{r: 255, g: 120, b: 0})
			}
		}
	}

	// Sound Events & Particle Triggering
	if app.game.last_sound_event != '' {
		event := app.game.last_sound_event
		app.game.last_sound_event = ''
		match event {
			'paddle' {
				app.sound_mgr.play_paddle_hit()
			}
			'brick' {
				app.sound_mgr.play_brick_hit(rand.f64())
				app.spawn_particles(f64(app.mouse_x), 150.0, 8, Color{r: 255, g: 255, b: 200})
			}
			'metal' {
				app.sound_mgr.play_metal_hit()
			}
			'explosion' {
				app.sound_mgr.play_explosion_sound()
				app.spawn_particles(f64(app.mouse_x), 150.0, 25, Color{r: 255, g: 80, b: 40})
			}
			'laser' {
				app.sound_mgr.play_laser_sound()
			}
			'powerup' {
				app.sound_mgr.play_powerup_sound()
				app.spawn_particles(app.game.paddle.x + app.game.paddle.w / 2, app.game.paddle.y,
					20, Color{r: 0, g: 255, b: 200})
			}
			'lose' {
				app.sound_mgr.play_lose_ball_sound()
			}
			'win' {
				app.sound_mgr.play_win_fanfare()
				app.spawn_particles(world_w / 2, 200, 50, Color{r: 0, g: 255, b: 150})
			}
			else {}
		}
	}

	// Update Particles
	for i := app.particles.len - 1; i >= 0; i-- {
		mut p := app.particles[i]
		p.x += p.dx * dt
		p.y += p.dy * dt
		p.life -= dt

		if p.life <= 0.0 {
			app.particles.delete(i)
		} else {
			app.particles[i] = p
		}
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.renderer.ctx = app.ctx
	app.renderer.width = world_w
	app.renderer.height = world_h
	app.ctx.begin()

	now := time.ticks()
	dt := f64(now - app.last_tick) / 1000.0
	app.last_tick = now

	app.update(math.min(dt, 0.05))
	app.sound_mgr.update()
	app.sound_mgr.update_bgm(!app.paused && !app.game.game_over)

	render_breakout_game(&app.renderer, &app.game, app.particles, app.tex_mgr.sprite_texture)

	app.btn_restart.render(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_level.render(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_sound.render(&app.renderer, app.mouse_x, app.mouse_y)

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
			app.paddle_target_x = f64(e.mouse_x)
		}
		.mouse_down {
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				if app.btn_restart.contains(mx, my) {
					app.reset_game()
				} else if app.btn_level.contains(mx, my) {
					app.game.level++
					if app.game.level > max_level {
						app.game.level = 1
					}
					app.game.load_level(app.game.level)
				} else if app.btn_sound.contains(mx, my) {
					muted := !app.sound_mgr.toggle_sound()
					app.btn_sound.text = if muted { 'SOUND: OFF [O]' } else { 'SOUND: ON [O]' }
				} else {
					app.key_launch = true
					app.key_fire = true
				}
			}
		}
		.key_down {
			match e.key_code {
				.f11, .grave_accent {
					gg.toggle_fullscreen()
				}
				.f10 {
					prod_fx_cycle_mode()
				}
				.m {
					app.sound_mgr.toggle_music()
				}
				.left, .a, .h { app.key_left = true }
				.right, .d, .l { app.key_right = true }
				.space, .up, .w, .enter {
					app.key_launch = true
					app.key_fire = true
				}
				.r { app.reset_game() }
				.n {
					app.game.level++
					if app.game.level > max_level {
						app.game.level = 1
					}
					app.game.load_level(app.game.level)
				}
				.p { app.paused = !app.paused }
				.o {
					muted := !app.sound_mgr.toggle_sound()
					app.btn_sound.text = if muted { 'SOUND: OFF [O]' } else { 'SOUND: ON [O]' }
				}
				.f5 {
					data_save := SaveData{
						high_score:       app.high_score
						save_state_valid: true
						level:            app.game.level
						score:            app.game.score
					}
					save_data_to_file(&data_save)
				}
				.f9 {
					saved := load_save_data()
					if saved.save_state_valid {
						app.game.score = saved.score
						app.game.level = saved.level
						app.game.load_level(saved.level)
					}
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.m {
					app.sound_mgr.toggle_music()
				}
				.left, .a, .h { app.key_left = false }
				.right, .d, .l { app.key_right = false }
				else {}
			}
		}
		else {}
	}
}

fn on_init(data voidptr) {
	mut app := unsafe { &App(data) }
	app.renderer.ctx = app.ctx
	app.tex_mgr.init(&app.renderer)
}

fn main() {
	mut app := new_app()

	app.ctx = gg.new_context(
		width:         world_w
		height:        world_h
		window_title:  'Breakout Pro: Brick Breaker Overdrive [GG + Sokol]'
		user_data:     &app
		init_fn:       on_init
		frame_fn:      on_frame
		event_fn:      on_event
		bg_color:      gg.Color{r: 14, g: 16, b: 28, a: 255}
		resizable:     true
		create_window: true
	)

	app.ctx.run()
	app.sound_mgr.cleanup()
}
