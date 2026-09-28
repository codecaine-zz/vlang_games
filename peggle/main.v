module main

import gg
import math
import time

const win_w = 920
const win_h = 640

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      PeggleGame
	sound_mgr SoundManager
	key_left  bool
	key_right bool
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_peggle_game()
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

	if app.key_left {
		app.game.cannon_angle = math.max(0.2, app.game.cannon_angle - 1.5 * f64(dt))
	}
	if app.key_right {
		app.game.cannon_angle = math.min(math.pi - 0.2, app.game.cannon_angle + 1.5 * f64(dt))
	}

	app.game.update(f64(dt))
	app.sound_mgr.update()

	render_peggle_game(&app.renderer, mut app.game, win_w, win_h, app.sound_mgr.enabled, unsafe { nil })
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
			mx := int(e.mouse_x)
			my := int(e.mouse_y)
			if my > 45 {
				cx := f64(win_w) / 2.0
				cy := 45.0
				app.game.cannon_angle = math.atan2(f64(my) - cy, f64(mx) - cx)
				app.game.cannon_angle = math.clamp(app.game.cannon_angle, 0.2, math.pi - 0.2)
			}
		}
		.mouse_down {
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				sound_x := win_w - 140
				if mx >= sound_x && mx <= sound_x + 120 && my >= 8 && my <= 32 {
					app.sound_mgr.toggle_sound()
				} else {
					app.game.shoot_ball()
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
				.escape { exit(0) }
				.left, .a { app.key_left = true }
				.right, .d { app.key_right = true }
				.space { app.game.shoot_ball() }
				.r { app.game.init_level() }
				.m, .o { app.sound_mgr.toggle_sound() }
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.left, .a { app.key_left = false }
				.right, .d { app.key_right = false }
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
		window_title: 'Peggle Arcade - Extreme Fever Odyssey'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 10, g: 15, b: 30, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
