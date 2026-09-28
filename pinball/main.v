module main

import gg
import time

struct App {
mut:
	ctx         &gg.Context = unsafe { nil }
	renderer    Renderer
	game        GameEngine
	sound_mgr   SoundManager
	tex_mgr     PinballTextureManager
	p1_left     bool
	p1_right    bool
	mario_left  bool
	mario_right bool
	plunge_hold bool
	last_tick   i64
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

	app.game.update(f64(dt), app.p1_left, app.p1_right, app.mario_left, app.mario_right, app.plunge_hold)

	for sound_name in app.game.sound_queue {
		match sound_name {
			'flick' { app.sound_mgr.play_flick() }
			'bumper' { app.sound_mgr.play_bumper() }
			'slingshot' { app.sound_mgr.play_slingshot() }
			'target' { app.sound_mgr.play_target() }
			'spinner' { app.sound_mgr.play_spinner() }
			'mario_bounce' { app.sound_mgr.play_mario_bounce() }
			'damsel_rescue' { app.sound_mgr.play_damsel_rescue() }
			'drain' { app.sound_mgr.play_drain() }
			'plunger_release' { app.sound_mgr.play_plunger_release() }
			'tilt' { app.sound_mgr.play_tilt() }
			else {}
		}
	}
	app.game.sound_queue.clear()
	app.sound_mgr.update()

	render_game(&app.renderer, &app.game, app.tex_mgr.sprite_texture)
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
				.z, .left, .a {
					app.p1_left = true
					app.mario_left = true
				}
				.slash, .right, .d {
					app.p1_right = true
					app.mario_right = true
				}
				.space, .down, .s {
					app.plunge_hold = true
				}
				.r { app.game.start_game(app.game.mode) }
				.m { app.sound_mgr.toggle_music() }
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.z, .left, .a {
					app.p1_left = false
					app.mario_left = false
				}
				.slash, .right, .d {
					app.p1_right = false
					app.mario_right = false
				}
				.space, .down, .s {
					app.plunge_hold = false
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
		width:        800
		height:       900
		resizable:     true
		window_title: 'NES Pinball - 1984 Nintendo Arcade Recreation'
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
		height: 900
	}
	ctx.run()
}
