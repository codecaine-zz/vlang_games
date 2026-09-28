module main

import gg
import math
import time

struct App {
mut:
	ctx         &gg.Context = unsafe { nil }
	renderer    Renderer
	game        NuclearThroneGame
	tex_mgr     NuclearThroneTextureManager
	sound_mgr   SoundManager
	btn_restart Button
	btn_sound   Button
	mouse_x     int
	mouse_y     int
	key_w       bool
	key_a       bool
	key_s       bool
	key_d       bool
	key_shoot   bool
	key_ability bool
	key_swap    bool
	last_tick   i64
}

fn new_app() App {
	return App{
		game:        new_nuclear_throne_game()
		tex_mgr:     new_nuclear_throne_texture_manager()
		sound_mgr:   new_sound_manager()
		btn_restart: Button{ x: 10, y: 550, w: 120, h: 40, text: 'RESET [R]' }
		btn_sound:   Button{ x: 140, y: 550, w: 130, h: 40, text: 'SOUND: ON [O]' }
		last_tick:   time.ticks()
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
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	mut move_x := 0.0
	mut move_y := 0.0
	if app.key_a { move_x -= 1.0 }
	if app.key_d { move_x += 1.0 }
	if app.key_w { move_y -= 1.0 }
	if app.key_s { move_y += 1.0 }

	if move_x != 0 && move_y != 0 {
		move_x *= 0.7071
		move_y *= 0.7071
	}

	player_screen_x := app.game.player.x - app.game.camera_x
	player_screen_y := app.game.player.y - app.game.camera_y
	aim_angle := math.atan2(f64(app.mouse_y) - player_screen_y, f64(app.mouse_x) - player_screen_x)

	app.game.update(dt, move_x, move_y, aim_angle, app.key_shoot, app.key_ability, app.key_swap)
	app.key_swap = false

	if app.game.last_sound_event != '' {
		app.sound_mgr.play_sound(app.game.last_sound_event)
		app.game.last_sound_event = ''
	}
	app.sound_mgr.update()

	render_nuclear_throne_game(&app.renderer, &app.game, app.tex_mgr.sprite_texture)
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
			if e.mouse_button == .left {
				if app.game.mutation_screen {
					if app.mouse_y >= 190 && app.mouse_y <= 440 {
						idx := (app.mouse_y - 190) / 55
						app.game.select_mutation(idx)
					}
				} else {
					app.key_shoot = true
				}
			} else if e.mouse_button == .right {
				app.key_ability = true
			}
		}
		.mouse_up {
			if e.mouse_button == .left { app.key_shoot = false }
			else if e.mouse_button == .right { app.key_ability = false }
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
				.escape { exit(0) }
				.w, .up { app.key_w = true }
				.a, .left { app.key_a = true }
				.s, .down { app.key_s = true }
				.d, .right { app.key_d = true }
				.e, .f, .q { app.key_swap = true }
				.space, .left_shift { app.key_ability = true }
				.r { app.game.start_new_game() }
				.o { app.sound_mgr.toggle_sound() }
				._1, ._2, ._3, ._4, ._5 {
					if app.game.mutation_screen {
						app.game.select_mutation(int(e.key_code) - int(gg.KeyCode._1))
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
				.w, .up { app.key_w = false }
				.a, .left { app.key_a = false }
				.s, .down { app.key_s = false }
				.d, .right { app.key_d = false }
				.space, .left_shift { app.key_ability = false }
				else {}
			}
		}
		else {}
	}
}

fn main() {
	mut app := new_app()
	mut ctx := gg.new_context(
		width:        800
		height:       600
		resizable:     true
		window_title: 'Nuclear Throne - Wasteland Twin-Stick Shooter'
		user_data:    &app
		init_fn:      on_init
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 20, g: 15, b: 12, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  800
		height: 600
	}
	ctx.run()
}
