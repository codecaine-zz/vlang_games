module main

import gg
import math
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      BowlingGame
	sound_mgr SoundManager
	tex_mgr   BowlingTextureManager
	key_left  bool
	key_right bool
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_bowling_game()
		sound_mgr: new_sound_manager()
		last_tick: time.ticks()
	}
}

fn on_init(data voidptr) {
	mut app := unsafe { &App(data) }
	app.tex_mgr.init(&app.renderer)
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f64(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := math.min(0.033, if raw_dt > 0.001 { raw_dt } else { 1.0 / 60.0 })

	// Handle continuous position shifting
	if app.game.phase == .position && !app.game.players[app.game.current_player].is_ai {
		if app.key_left {
			app.game.aim_x = math.max(app.game.lane_left + 25.0, app.game.aim_x - 180.0 * dt)
		}
		if app.key_right {
			app.game.aim_x = math.min(app.game.lane_right - 25.0, app.game.aim_x + 180.0 * dt)
		}
	}

	app.game.update(dt, mut app.sound_mgr)
	app.sound_mgr.update()
	app.sound_mgr.update_bgm(app.game.phase != .game_over)

	draw_bowling_game(&app.renderer, &app.game, app.tex_mgr.sprite_texture)
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
				.r {
					app.game.reset_game()
				}
				.m {
					app.sound_mgr.toggle_music()
				}
				._1 {
					app.game.set_mode(.solo)
				}
				._2 {
					app.game.set_mode(.vs_2p)
				}
				._3 {
					app.game.set_mode(.vs_ai)
				}
				.tab {
					app.game.ai_diff = (app.game.ai_diff + 1) % 3
				}
				.left, .a {
					app.key_left = true
				}
				.right, .d {
					app.key_right = true
				}
				.z {
					app.game.hook = math.max(-1.0, app.game.hook - 0.2)
				}
				.x {
					app.game.hook = math.min(1.0, app.game.hook + 0.2)
				}
				.space {
					if app.game.phase == .game_over {
						app.game.reset_game()
					} else if app.game.phase == .position {
						app.game.phase = .angle
					} else if app.game.phase == .angle {
						app.game.phase = .power
					} else if app.game.phase == .power {
						app.game.launch_ball(mut app.sound_mgr)
					}
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
		height:       680
		resizable:     true
		window_title: 'Bowling Pro - 10-Pin Arcade Bowling'
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
		height: 680
	}
	ctx.run()
}
