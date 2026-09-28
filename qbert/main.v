module main

import gg
import time

const win_w = 840
const win_h = 680

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      QbertGame
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_qbert_game()
		sound_mgr: new_sound_manager()
		last_tick: time.ticks()
	}
}

fn (mut app App) do_hop(dir HopDir) {
	valid, on_disc := app.game.try_hop(dir)
	if valid {
		if on_disc {
			app.sound_mgr.play_disc_sound()
		} else if app.game.state == .cursing {
			app.sound_mgr.play_curse_sound()
		} else {
			app.sound_mgr.play_hop_sound()
		}

		if app.game.state == .level_cleared {
			app.sound_mgr.play_win_sound()
		}
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	ev := app.game.update(f64(dt))
	if ev.hit_enemy {
		app.sound_mgr.play_curse_sound()
	}
	if ev.cleared {
		app.sound_mgr.play_win_sound()
	}
	app.sound_mgr.update()

	render_qbert_game(&app.renderer, &app.game, win_w, win_h)
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
				.r { app.game.reset_game() }
				.s, .m { app.sound_mgr.toggle_music() }
				.space {
					if app.game.state == .level_cleared {
						app.game.round_num++
						app.game.reset_round()
					} else if app.game.state == .game_over {
						app.game.reset_game()
					}
				}
				.q, .w { app.do_hop(.up_left) }
				.e, .up { app.do_hop(.up_right) }
				.a, .left { app.do_hop(.down_left) }
				.d, .right, .down { app.do_hop(.down_right) }
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
		window_title: 'Q*bert 2.5D Isometric - Arcade Classic'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 0, g: 0, b: 0, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
