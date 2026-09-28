module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      GameEngine
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_game_engine()
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

	draw_game(&app.renderer, &app.game)
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
		.char {
			if e.char_code >= 32 && e.char_code <= 126 {
				app.game.handle_character_input(rune(e.char_code), mut app.sound_mgr)
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
				.f1 {
					if app.game.state == .playing {
						app.game.state = .paused
					} else if app.game.state == .paused {
						app.game.state = .playing
					}
				}
				.f9 {
					app.sound_mgr.toggle_sound()
				}
				.f5 {
					app.game.start_game(app.game.mode)
				}
				.escape {
					if app.game.state == .playing {
						if app.game.locked_enemy_id != -1 {
							app.game.cancel_lock()
						} else {
							app.game.state = .paused
						}
					} else if app.game.state == .paused {
						app.game.state = .playing
					} else {
						exit(0)
					}
				}
				.backspace {
					if app.game.state == .playing {
						app.game.cancel_lock()
					}
				}
				.space, .enter {
					if app.game.state == .paused {
						app.game.state = .playing
					} else if app.game.state == .title || app.game.state == .game_over || app.game.state == .victory {
						app.game.start_game(app.game.mode)
					}
				}
				.p {
					if app.game.state == .paused {
						app.game.state = .playing
					}
				}
				.r {
					if app.game.state == .paused || app.game.state == .game_over || app.game.state == .victory {
						app.game.start_game(app.game.mode)
					}
				}
				.m, .s {
					if app.game.state != .playing {
						app.sound_mgr.toggle_sound()
					}
				}
				.tab {
					if app.game.state == .title {
						app.game.cycle_mode()
					}
				}
				._1 {
					if app.game.state == .title {
						app.game.set_mode(.arcade)
					}
				}
				._2 {
					if app.game.state == .title {
						app.game.set_mode(.speed_blitz)
					}
				}
				._3 {
					if app.game.state == .title {
						app.game.set_mode(.code_words)
					}
				}
				._4 {
					if app.game.state == .title {
						app.game.set_mode(.endless)
					}
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
		window_title: 'CyberType - Neon Arcade Space Typist'
		user_data: &app
		frame_fn: on_frame
		event_fn: on_event
		bg_color: gg.Color{10, 15, 30, 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{ctx: ctx}
	ctx.run()
}
