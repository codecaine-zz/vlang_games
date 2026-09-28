module main

import gg
import math
import rand
import time

struct App {
mut:
	ctx         &gg.Context = unsafe { nil }
	renderer    Renderer
	game        AsteroidsGame
	sound_mgr   SoundManager
	tex_mgr     AsteroidsTextureManager
	particles   []Particle
	mouse_x     int
	mouse_y     int
	key_left    bool
	key_right   bool
	key_up      bool
	key_fire    bool
	key_hyper   bool
	key_shield  bool
	paused      bool
	btn_restart Button
	btn_hyper   Button
	btn_shield  Button
	btn_sound   Button
	last_tick   i64
}

fn new_app() App {
	mut app := App{
		game:        new_asteroids_game()
		sound_mgr:   new_sound_manager()
		btn_restart: Button{
			x:            50
			y:            540
			w:            150
			h:            40
			text:         'RESTART [R]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 60, b: 90}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 70, g: 90, b: 140}
		}
		btn_hyper:   Button{
			x:            220
			y:            540
			w:            170
			h:            40
			text:         'HYPERSPACE [H]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 60, b: 90}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 70, g: 90, b: 140}
		}
		btn_shield:  Button{
			x:            410
			y:            540
			w:            150
			h:            40
			text:         'SHIELD [S]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 60, b: 90}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 70, g: 90, b: 140}
		}
		btn_sound:   Button{
			x:            580
			y:            540
			w:            170
			h:            40
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
		speed := 30.0 + rand.f64() * 120.0
		life := 0.2 + rand.f64() * 0.4
		app.particles << Particle{
			x:        x
			y:        y
			dx:       math.cos(angle) * speed
			dy:       math.sin(angle) * speed
			life:     life
			max_life: life
			color:    color
		}
	}
}

fn (mut app App) reset_game() {
	app.sound_mgr.clear_audio()
	app.game.reset()
	app.game.last_sound_event = ''
}

fn (mut app App) update(dt f64) {
	if app.paused {
		return
	}

	mut rot_input := 0.0
	if app.key_left {
		rot_input -= 1.0
	}
	if app.key_right {
		rot_input += 1.0
	}

	app.game.step(dt, rot_input, app.key_up, app.key_fire, app.key_hyper, app.key_shield)

	// Consume one-shot triggers
	app.key_hyper = false
	app.key_shield = false

	// Particle thruster trail
	if app.game.ship.thrusting && !app.game.game_over {
		tx := app.game.ship.x - math.cos(app.game.ship.angle) * 14.0
		ty := app.game.ship.y - math.sin(app.game.ship.angle) * 14.0
		app.spawn_particles(tx, ty, 2, Color{r: 255, g: 150, b: 0})
	}

	// Process Sound Triggers & Sound FX Particles
	if app.game.last_sound_event != '' {
		event := app.game.last_sound_event
		app.game.last_sound_event = ''
		match event {
			'laser' {
				app.sound_mgr.play_laser_sound()
			}
			'plasma' {
				app.sound_mgr.play_plasma_sound()
			}
			'explosion' {
				app.sound_mgr.play_explosion_sound(app.game.last_sound_param)
			}
			'powerup' {
				app.sound_mgr.play_powerup_sound()
				app.spawn_particles(app.game.ship.x, app.game.ship.y, 25, Color{
					r: 255
					g: 255
					b: 0
				})
			}
			'emp' {
				app.sound_mgr.play_emp_sound()
				app.spawn_particles(world_w / 2, world_h / 2, 60, Color{
					r: 200
					g: 100
					b: 255
				})
			}
			'warp' {
				app.sound_mgr.play_warp_sound()
				app.spawn_particles(app.game.ship.x, app.game.ship.y, 30, Color{
					r: 0
					g: 255
					b: 255
				})
			}
			'shield' {
				app.sound_mgr.play_shield_sound()
			}
			else {}
		}
	}

	// Update Particle physics
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

fn on_init(data voidptr) {
	mut app := unsafe { &App(data) }
	app.tex_mgr.init(&app.renderer)
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	dt := f64(now - app.last_tick) / 1000.0
	app.last_tick = now

	app.update(math.min(dt, 0.05))
	app.sound_mgr.update()
	app.sound_mgr.update_bgm(!app.paused && !app.game.game_over)

	render_asteroids_game(&app.renderer, &app.game, app.particles, app.tex_mgr.sprite_texture)

	// Render UI buttons
	app.btn_restart.render(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_hyper.render(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_shield.render(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_sound.render(&app.renderer, app.mouse_x, app.mouse_y)

	if app.paused {
		draw_text_centered(&app.renderer, world_w / 2, 280, 'PAUSED', 4, Color{
			r: 255
			g: 255
			b: 0
		})
	}

	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	if app.renderer.scale > 0.001 {
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
				if app.btn_restart.contains(mx, my) {
					app.reset_game()
				} else if app.btn_hyper.contains(mx, my) {
					app.key_hyper = true
				} else if app.btn_shield.contains(mx, my) {
					app.key_shield = true
				} else if app.btn_sound.contains(mx, my) {
					muted := !app.sound_mgr.toggle_sound()
					app.btn_sound.text = if muted { 'SOUND: OFF [O]' } else { 'SOUND: ON [O]' }
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
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.m {
					app.sound_mgr.toggle_music()
				}
				.left, .a { app.key_left = true }
				.right, .d { app.key_right = true }
				.up, .w { app.key_up = true }
				.space, .j { app.key_fire = true }
				.h, .k { app.key_hyper = true }
				.s, .down { app.key_shield = true }
				.r { app.reset_game() }
				.p { app.paused = !app.paused }
				.o {
					muted := !app.sound_mgr.toggle_sound()
					app.btn_sound.text = if muted { 'SOUND: OFF [O]' } else { 'SOUND: ON [O]' }
				}
				.f5 {
					save_data_to_file(&SaveData{
						high_score:       app.game.score
						save_state_valid: true
						score:            app.game.score
					})
				}
				.f9 {
					saved := load_save_data()
					if saved.save_state_valid {
						app.game.score = saved.score
					}
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.m {
					app.sound_mgr.toggle_music()
				}
				.left, .a { app.key_left = false }
				.right, .d { app.key_right = false }
				.up, .w { app.key_up = false }
				.space, .j { app.key_fire = false }
				else {}
			}
		}
		else {}
	}
}

fn main() {
	mut app := new_app()
	mut ctx := gg.new_context(
		width:         world_w
		height:        world_h
		resizable:     true
		window_title:  'Asteroids Pro: Top-Down Space Shooter'
		user_data:     &app
		init_fn:       on_init
		frame_fn:      on_frame
		event_fn:      on_event
		bg_color:      gg.Color{r: 0, g: 0, b: 0, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  world_w
		height: world_h
	}
	ctx.run()
}
