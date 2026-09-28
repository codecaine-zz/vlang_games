module main

import gg
import math
import time

const win_w = 840
const win_h = 600

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      SkiGame
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_ski_game()
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
		match app.game.sound_event {
			'jump' { app.sound_mgr.play_jump() }
			'trick' { app.sound_mgr.play_trick_chime() }
			'crash' { app.sound_mgr.play_crash() }
			'gate' { app.sound_mgr.play_gate_bell() }
			'yeti_roar' { app.sound_mgr.play_yeti_roar() }
			'yeti_crunch' { app.sound_mgr.play_yeti_crunch() }
			else {}
		}
	}

	render_ski_game(&app.renderer, mut app.game, win_w, win_h)
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
				.left, .a {
					app.game.steer_left()
				}
				.right, .d {
					app.game.steer_right()
				}
				.down, .s {
					app.game.steer_down()
				}
				.up, .w {
					app.game.steer_up()
				}
				.space {
					if app.game.pose == .stopped {
						app.game.steer_down()
					} else if app.game.pose != .airborne && !app.game.is_trick_pose(app.game.pose) {
						app.game.pose = .airborne
						app.game.air_time = 0.0
						app.sound_mgr.play_jump()
					}
				}
				.m {
					app.game.mode = match app.game.mode {
						.free_ski { GameMode.slalom }
						.slalom { GameMode.tree_slalom }
						.tree_slalom { GameMode.yeti_survival }
						.yeti_survival { GameMode.free_ski }
					}
					app.game.reset_game()
				}
				.r {
					app.game.reset_game()
				}
				.o {
					app.sound_mgr.toggle_sound()
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
		window_title:  'SkiFree Extreme - Classic 1991 Shareware Winter Sports'
		user_data:     &app
		frame_fn:      on_frame
		event_fn:      on_event
		bg_color:      gg.Color{r: 245, g: 248, b: 252, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx: ctx
	}
	ctx.run()
}
