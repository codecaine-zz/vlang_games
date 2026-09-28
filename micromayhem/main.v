module main

import gg
import time

const win_w = 940
const win_h = 660

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      MicroMayhemGame
	sound_mgr SoundManager
	mouse_x   int
	mouse_y   int
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_micromayhem_game()
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

	app.game.update(dt, f64(app.mouse_x))

	if app.game.sound_event != '' {
		ev := app.game.sound_event
		app.game.sound_event = ''
		match ev {
			'tick' { app.sound_mgr.play_tick(600.0) }
			'win' { app.sound_mgr.play_win() }
			'fail' { app.sound_mgr.play_fail() }
			'speedup' { app.sound_mgr.play_speedup() }
			else {}
		}
	}
	app.sound_mgr.update()

	render_micromayhem_game(&app.renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y)
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
				if app.game.phase == .title || app.game.phase == .game_over {
					app.game.start_game()
					app.sound_mgr.play_speedup()
				} else if app.game.phase == .playing {
					app.game.handle_click(f64(e.mouse_x), f64(e.mouse_y))
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
				.escape { exit(0) }
				.space {
					if app.game.phase == .title || app.game.phase == .game_over {
						app.game.start_game()
						app.sound_mgr.play_speedup()
					} else if app.game.phase == .playing {
						app.game.handle_key_action(0)
					}
				}
				.r { app.game.start_game() }
				.v, .o { app.sound_mgr.toggle_sound() }
				._1 { app.game.handle_key_action(1) }
				._2 { app.game.handle_key_action(2) }
				._3 { app.game.handle_key_action(3) }
				.a, .left { app.game.handle_key_action(-1) }
				.d, .right { app.game.handle_key_action(1) }
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
		window_title: 'Micro Mayhem - Rapid Microgames Challenge'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 20, g: 15, b: 30, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
