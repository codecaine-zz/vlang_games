module main

import gg
import time

struct App {
mut:
	ctx        &gg.Context = unsafe { nil }
	renderer   Renderer
	game       GameEngine
	tex_mgr    MappyTextureManager
	sound_mgr  SoundManager
	key_left   bool
	key_right  bool
	key_action bool
	last_tick  i64
}

fn new_app() App {
	return App{
		game:      new_game_engine()
		sound_mgr: new_sound_manager()
		last_tick: time.ticks()
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

	app.game.update(dt, app.key_left, app.key_right, app.key_action, mut app.sound_mgr)
	app.key_action = false
	app.sound_mgr.update()

	draw_game(&app.renderer, &app.game, app.tex_mgr.sprite_texture)
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
				.escape { exit(0) }
				.left, .a { app.key_left = true }
				.right, .d { app.key_right = true }
				.space, .up, .w, .enter {
					app.key_action = true
					if app.game.state == .title || app.game.state == .game_over {
						app.game.start_game(1)
					}
				}
				.m { app.sound_mgr.toggle_music() }
				.r { app.game.start_game(1) }
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.left, .a { app.key_left = false }
				.right, .d { app.key_right = false }
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
		window_title: 'Mappy - Namco Arcade Police Mouse Classic'
		user_data:    &app
		init_fn:      on_init
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 0, g: 0, b: 0, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  800
		height: 600
	}
	ctx.run()
}
