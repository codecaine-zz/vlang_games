module main

import gg
import math
import time

struct App {
mut:
	ctx          &gg.Context = unsafe { nil }
	renderer     Renderer
	game         PoolGame
	sound_mgr    SoundManager
	tex_mgr      PoolTextureManager
	mouse_down   bool
	drag_start_x f64
	drag_start_y f64
	last_tick    i64
}

fn new_app() App {
	return App{
		game:      new_pool_game()
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
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.game.update(f64(dt), mut app.sound_mgr)
	app.sound_mgr.update()

	draw_pool_game(&app.renderer, &app.game, app.tex_mgr.sprite_texture)
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
			mx := f64(e.mouse_x)
			my := f64(e.mouse_y)
			if app.game.state == .aiming {
				app.game.aim_angle = math.atan2(my - app.game.balls[0].y, mx - app.game.balls[0].x)
			}
			if app.mouse_down && app.game.state == .power_pull {
				dy := my - app.drag_start_y
				app.game.cue_power = math.min(1.0, math.max(0.0, dy / 120.0))
			}
		}
		.mouse_down {
			if e.mouse_button == .left {
				mx := f64(e.mouse_x)
				my := f64(e.mouse_y)
				if app.game.state == .ball_in_hand {
					inner_min_x := app.game.table_x + app.game.cushion_thick + 12.0
					inner_max_x := app.game.table_x + app.game.table_w - app.game.cushion_thick - 12.0
					inner_min_y := app.game.table_y + app.game.cushion_thick + 12.0
					inner_max_y := app.game.table_y + app.game.table_h - app.game.cushion_thick - 12.0

					if mx >= inner_min_x && mx <= inner_max_x && my >= inner_min_y && my <= inner_max_y {
						app.game.balls[0].x = mx
						app.game.balls[0].y = my
						app.game.balls[0].potted = false
						app.game.state = .aiming
					}
				} else if app.game.state == .aiming {
					app.mouse_down = true
					app.drag_start_x = mx
					app.drag_start_y = my
					app.game.state = .power_pull
					app.game.cue_power = 0.1
				}
			}
		}
		.mouse_up {
			if e.mouse_button == .left && app.game.state == .power_pull {
				app.mouse_down = false
				if app.game.cue_power > 0.05 {
					app.game.strike_cue_ball(app.game.cue_power, mut app.sound_mgr)
				} else {
					app.game.state = .aiming
				}
				app.game.cue_power = 0.0
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
				.escape { exit(0) }
				.r {
					if app.game.typ == .nine_ball {
						app.game.rack_9ball()
					} else {
						app.game.rack_8ball()
					}
					app.game.state = .aiming
				}
				.m { app.sound_mgr.toggle_music() }
				._1 { app.game.set_mode(.eight_ball, false, false) }
				._2 { app.game.set_mode(.nine_ball, false, false) }
				._3 { app.game.set_mode(.practice, false, false) }
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
		window_title: 'Billiards Pro - 8-Ball & 9-Ball Pool'
		user_data:    &app
		init_fn:      on_init
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 10, g: 25, b: 15, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  800
		height: 600
	}
	ctx.run()
}
