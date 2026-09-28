module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      DrMarioGame
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_dr_mario_game()
		last_tick: time.ticks()
	}
}

fn on_init(data voidptr) {
	mut app := unsafe { &App(data) }
	app.game.init_textures(&app.renderer)
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.game.update(dt)
	app.game.sound_mgr.update()

	render_dr_mario_game(&app.renderer, mut app.game)
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
					app.game.sound_mgr.toggle_sfx()
				}
				.escape {
					if app.game.state == .title {
						exit(0)
					} else {
						app.game.reset_to_title()
					}
				}
				.a, .left {
					if app.game.state == .title {
						if app.game.level > 0 { app.game.level-- }
					} else {
						app.game.key_left = true
						app.game.move_horizontal(-1)
					}
				}
				.d, .right {
					if app.game.state == .title {
						if app.game.level < 20 { app.game.level++ }
					} else {
						app.game.key_right = true
						app.game.move_horizontal(1)
					}
				}
				.s, .down {
					app.game.key_down = true
				}
				.space, .enter {
					if app.game.state == .title {
						app.game.start_game(app.game.level, app.game.speed)
					} else if app.game.state == .stage_clear {
						app.game.next_level()
					} else if app.game.state == .game_over {
						app.game.reset_to_title()
					} else if app.game.state == .playing {
						app.game.hard_drop()
					}
				}
				.w, .up, .j, .z {
					if app.game.state == .title {
						app.game.start_game(app.game.level, app.game.speed)
					} else if app.game.state == .stage_clear {
						app.game.next_level()
					} else if app.game.state == .game_over {
						app.game.reset_to_title()
					} else {
						app.game.rotate_pill(true)
					}
				}
				.k, .x {
					app.game.rotate_pill(false)
				}
				.h, .left_shift, .right_shift {
					if app.game.state == .playing {
						app.game.hold_current_pill()
					}
				}
				._1 {
					app.game.speed = .low
				}
				._2 {
					app.game.speed = .med
				}
				._3 {
					app.game.speed = .hi
				}
				.p {
					if app.game.state in [.playing, .clearing_matches, .cascade_falling] {
						app.game.state = .paused
					} else if app.game.state == .paused {
						app.game.state = .playing
					}
				}
				.r {
					app.game.reset_to_title()
				}
				.m {
					app.game.sound_mgr.toggle_music()
				}
				.b, .t {
					app.game.sound_mgr.cycle_bgm()
				}
				.c {
					app.game.crt_filter = !app.game.crt_filter
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.n {
					app.game.sound_mgr.toggle_sfx()
				}
				.a, .left {
					app.game.key_left = false
				}
				.d, .right {
					app.game.key_right = false
				}
				.s, .down {
					app.game.key_down = false
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
		height:       600
		resizable:     true
		window_title: 'Dr. Codecaine (Virus Elimination Puzzle)'
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
