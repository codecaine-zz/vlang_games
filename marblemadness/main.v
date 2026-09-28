module main

import gg
import time

const win_w = 840
const win_h = 640

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      MarbleGame
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_marble_game()
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

	app.game.update(dt)
	app.sound_mgr.update()

	render_game(&app.renderer, &app.game, win_w, win_h)
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
				.space, .enter {
					match app.game.state {
						.title { app.game.start_game(1) }
						.level_intro { app.game.state = .playing }
						.game_over, .victory { app.game.init_title() }
						.playing {
							app.game.input_turbo = true
							app.game.input_jump = true
						}
						else {}
					}
				}
				.up, .w { app.game.input_up = true }
				.down, .s { app.game.input_down = true }
				.left, .a { app.game.input_left = true }
				.right, .d { app.game.input_right = true }
				.p {
					if app.game.state == .playing { app.game.state = .paused }
					else if app.game.state == .paused { app.game.state = .playing }
				}
				.r { app.game.start_game(app.game.current_level) }
				.m { app.sound_mgr.toggle_music() }
				.t { app.game.control_diagonal = !app.game.control_diagonal }
				._1 { app.game.start_game(1) }
				._2 { app.game.start_game(2) }
				._3 { app.game.start_game(3) }
				._4 { app.game.start_game(4) }
				._5 { app.game.start_game(5) }
				._6 { app.game.start_game(6) }
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.up, .w { app.game.input_up = false }
				.down, .s { app.game.input_down = false }
				.left, .a { app.game.input_left = false }
				.right, .d { app.game.input_right = false }
				.space, .enter {
					app.game.input_turbo = false
					app.game.input_jump = false
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
		window_title: 'Marble Madness (Atari 1984 Isometric Arcade)'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 12, g: 15, b: 24, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:       ctx
		width:     win_w
		height:    win_h
		logical_w: win_w
		logical_h: win_h
	}
	ctx.run()
}
