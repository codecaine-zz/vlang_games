module main

import gg
import time

const win_w = 920
const win_h = 680

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      EtchGame
	sound_mgr SoundManager
	key_left  bool
	key_right bool
	key_up    bool
	key_down  bool
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_etch_game()
		sound_mgr: new_sound_manager()
		last_tick: time.ticks()
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	spd := 140.0 * dt
	mut kx := 0.0
	mut ky := 0.0
	if app.key_left { kx -= spd }
	if app.key_right { kx += spd }
	if app.key_up { ky -= spd }
	if app.key_down { ky += spd }
	if kx != 0.0 || ky != 0.0 {
		app.game.move_pen(kx, ky)
	}

	app.game.update(dt)
	app.sound_mgr.update()

	render_etch_game(&app.renderer, mut app.game, win_w, win_h, app.sound_mgr.sound_enabled)
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
				.escape {
					exit(0)
				}
				.f5 {
					app.game.save_state()
				}
				.f9 {
					app.game.load_state()
				}
				.left, .a {
					app.key_left = true
				}
				.right, .d {
					app.key_right = true
				}
				.up, .w {
					app.key_up = true
				}
				.down, .s {
					app.key_down = true
				}
				.c {
					app.game.reset_screen()
					app.sound_mgr.play_shake_whoosh()
				}
				.r {
					app.game.trigger_shake()
					app.sound_mgr.play_shake_whoosh()
				}
				.m {
					app.sound_mgr.toggle_music()
				}
				._1 {
					app.game.theme = .classic_silver
				}
				._2 {
					app.game.theme = .amber_phosphor
				}
				._3 {
					app.game.theme = .emerald_matrix
				}
				._4 {
					app.game.theme = .cyber_neon
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
				.up, .w {
					app.key_up = false
				}
				.down, .s {
					app.key_down = false
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
		width:        win_w
		height:       win_h
		resizable:     true
		window_title: 'Etch A Sketch - Classic Mechanical Drawing Toy'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 220, g: 30, b: 30, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
