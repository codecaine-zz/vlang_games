module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      WarGame
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_war_game()
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

	app.game.update(f64(dt), mut app.sound_mgr)

	draw_war_game(&app.renderer, &app.game)
	app.sound_mgr.update()
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
		.mouse_down {
			if e.mouse_button == .left {
				if app.game.phase == .ready || app.game.phase == .comparing {
					app.game.step_battle(mut app.sound_mgr)
				} else if app.game.phase == .game_over {
					app.game.start_new_match()
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
				.escape {
					exit(0)
				}
				.space, .enter {
					if app.game.phase == .ready || app.game.phase == .comparing {
						app.game.step_battle(mut app.sound_mgr)
					} else if app.game.phase == .game_over {
						app.game.start_new_match()
					}
				}
				.a {
					app.game.auto_play = !app.game.auto_play
				}
				.r {
					app.game.start_new_match()
				}
				.m {
					app.sound_mgr.toggle_music()
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
		width: 800
		height: 600
		resizable:     true
		window_title: 'War - The 52-Card Battle Strategy'
		user_data: &app
		frame_fn: on_frame
		event_fn: on_event
		bg_color: gg.Color{16, 20, 32, 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{ctx: ctx}
	ctx.run()
}
