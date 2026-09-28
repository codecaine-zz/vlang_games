module main

import gg
import math
import time

const win_w = 940
const win_h = 660

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      TriviaGame
	sound_mgr SoundManager
	mouse_x   int
	mouse_y   int
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_trivia_game(false)
		sound_mgr: new_sound_manager()
		last_tick: time.ticks()
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f64(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := math.min(raw_dt, 0.05)

	app.game.update(dt)

	if app.game.sound_event != '' {
		ev := app.game.sound_event
		app.game.sound_event = ''
		match ev {
			'lock' { app.sound_mgr.play_buzzer_lock() }
			'correct' { app.sound_mgr.play_correct() }
			'wrong' { app.sound_mgr.play_wrong() }
			'victory' { app.sound_mgr.play_victory() }
			else {}
		}
	}

	render_trivia_game(&app.renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y)
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
		.mouse_move {
			app.mouse_x = int(e.mouse_x)
			app.mouse_y = int(e.mouse_y)
		}
		.mouse_down {
			app.mouse_x = int(e.mouse_x)
			app.mouse_y = int(e.mouse_y)

			if app.game.state == .title || app.game.state == .game_over {
				app.game.start_game()
			} else if app.game.state == .question {
				btn_w := (win_w - 72) / 2
				btn_h := 85
				for i in 0 .. 4 {
					gx := i % 2
					gy := i / 2
					bx := 24 + gx * (btn_w + 24)
					by := 280 + gy * (btn_h + 20)
					if app.mouse_x >= bx && app.mouse_x <= bx + btn_w && app.mouse_y >= by && app.mouse_y <= by + btn_h {
						app.game.submit_answer_p1(i)
					}
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
				.space {
					if app.game.state == .title || app.game.state == .game_over {
						app.game.start_game()
					} else if app.game.state == .answer_reveal {
						app.game.advance_to_next()
					}
				}
				.t {
					app.game.start_game()
				}
				.m {
					app.game.is_two_player = !app.game.is_two_player
					app.game.start_game()
				}
				.s {
					app.sound_mgr.toggle_sound()
				}
				._1, .a { app.game.submit_answer_p1(0) }
				._2, .b { app.game.submit_answer_p1(1) }
				._3, .c { app.game.submit_answer_p1(2) }
				._4, .d { app.game.submit_answer_p1(3) }
				.u { app.game.submit_answer_p2(0) }
				.i { app.game.submit_answer_p2(1) }
				.o { app.game.submit_answer_p2(2) }
				.p { app.game.submit_answer_p2(3) }
				else {}
			}
		}
		else {}
	}
}

fn main() {
	mut app := new_app()
	mut ctx := gg.new_context(
		width:         win_w
		height:        win_h
		resizable:     true
		window_title:  'Party Trivia Show - TV Quiz Arena & Buzzers'
		user_data:     &app
		frame_fn:      on_frame
		event_fn:      on_event
		bg_color:      gg.Color{r: 10, g: 15, b: 30, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx: ctx
	}
	ctx.run()
}
