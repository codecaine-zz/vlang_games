module main

import gg
import math
import time

const win_w = 800
const win_h = 600

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      SimonGame
	sound_mgr SoundManager
	tex_mgr   SimonTextureManager
	mouse_x   int
	mouse_y   int
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_simon_game()
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

	ev := app.game.update(dt)
	if ev.pad_tone >= 0 {
		app.sound_mgr.play_pad_tone(ev.pad_tone, ev.pad_dur)
	}
	if ev.error_buzz {
		app.sound_mgr.play_error_buzzer()
	}
	if ev.round_clear {
		app.sound_mgr.play_victory_jingle()
	}

	render_simon_console(&app.renderer, &app.game, win_w, win_h, app.mouse_x, app.mouse_y, app.tex_mgr.sprite_texture)
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
	cx := win_w / 2
	cy := win_h / 2 + 10
	outer_rad := 200
	inner_rad := 85

	match e.typ {
		.mouse_move {
			app.mouse_x = int(e.mouse_x)
			app.mouse_y = int(e.mouse_y)
		}
		.mouse_down {
			app.mouse_x = int(e.mouse_x)
			app.mouse_y = int(e.mouse_y)
			if app.game.state == .attract || app.game.state == .game_over {
				app.game.start_new_game()
			} else if app.game.state == .player_turn {
				pad := get_pad_under_mouse(cx, cy, inner_rad, outer_rad, app.mouse_x, app.mouse_y)
				if pad >= 0 {
					_, ev := app.game.handle_pad_press(pad)
					if ev.pad_tone >= 0 { app.sound_mgr.play_pad_tone(ev.pad_tone, ev.pad_dur) }
					if ev.error_buzz { app.sound_mgr.play_error_buzzer() }
					if ev.round_clear { app.sound_mgr.play_victory_jingle() }
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
				.space {
					if app.game.state == .attract || app.game.state == .game_over {
						app.game.start_new_game()
					}
				}
				.r {
					app.game.reset_game()
				}
				.m {
					app.game.toggle_mode()
				}
				.s {
					app.sound_mgr.toggle_sound()
				}
				._1, .q {
					_, ev := app.game.handle_pad_press(0)
					if ev.pad_tone >= 0 { app.sound_mgr.play_pad_tone(ev.pad_tone, ev.pad_dur) }
					if ev.error_buzz { app.sound_mgr.play_error_buzzer() }
					if ev.round_clear { app.sound_mgr.play_victory_jingle() }
				}
				._2, .w {
					_, ev := app.game.handle_pad_press(1)
					if ev.pad_tone >= 0 { app.sound_mgr.play_pad_tone(ev.pad_tone, ev.pad_dur) }
					if ev.error_buzz { app.sound_mgr.play_error_buzzer() }
					if ev.round_clear { app.sound_mgr.play_victory_jingle() }
				}
				._3, .a {
					_, ev := app.game.handle_pad_press(2)
					if ev.pad_tone >= 0 { app.sound_mgr.play_pad_tone(ev.pad_tone, ev.pad_dur) }
					if ev.error_buzz { app.sound_mgr.play_error_buzzer() }
					if ev.round_clear { app.sound_mgr.play_victory_jingle() }
				}
				._4, .d {
					_, ev := app.game.handle_pad_press(3)
					if ev.pad_tone >= 0 { app.sound_mgr.play_pad_tone(ev.pad_tone, ev.pad_dur) }
					if ev.error_buzz { app.sound_mgr.play_error_buzzer() }
					if ev.round_clear { app.sound_mgr.play_victory_jingle() }
				}
				.escape {
					exit(0)
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
		width:         win_w
		height:        win_h
		resizable:     true
		window_title:  'Cyber Simon - Electronic Light & Sound Memory Game'
		user_data:     &app
		frame_fn:      on_frame
		event_fn:      on_event
		bg_color:      gg.Color{r: 10, g: 15, b: 25, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx: ctx
		width: win_w
		height: win_h
		logical_w: win_w
		logical_h: win_h
	}
	app.tex_mgr.init(&app.renderer)
	ctx.run()
}
