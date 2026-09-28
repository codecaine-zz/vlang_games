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
	game      TamagotchiGame
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_tamagotchi_game()
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

	if app.game.toast_timer > 0 {
		app.game.toast_timer -= dt
	}

	app.game.update(dt)
	render_tamagotchi(&app.renderer, &app.game, win_w, win_h)
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
		.mouse_down {
			mx := int(e.mouse_x)
			my := int(e.mouse_y)
			cx := win_w / 2
			btn_y := win_h / 2 + 110

			if my >= btn_y - 25 && my <= btn_y + 25 {
				if mx >= cx - 85 && mx <= cx - 45 {
					app.game.button_a()
					app.sound_mgr.play_btn_click()
				} else if mx >= cx - 20 && mx <= cx + 20 {
					app.game.button_b()
					app.sound_mgr.play_btn_click()
				} else if mx >= cx + 45 && mx <= cx + 85 {
					app.game.button_c()
					app.sound_mgr.play_btn_click()
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
				.f5 {
					app.game.save_state()
				}
				.f9 {
					app.game.load_state()
				}
				.a, .left {
					app.game.button_a()
					app.sound_mgr.play_btn_click()
				}
				.b, .space, .enter {
					app.game.button_b()
					app.sound_mgr.play_btn_click()
				}
				.c, .backspace {
					app.game.button_c()
					app.sound_mgr.play_btn_click()
				}
				.m {
					app.sound_mgr.toggle_music()
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
		window_title:  'Tamagotchi 1996 - Virtual Pet Keychain Simulator'
		user_data:     &app
		frame_fn:      on_frame
		event_fn:      on_event
		bg_color:      gg.Color{r: 30, g: 30, b: 40, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:       ctx
		width:     win_w
		height:    win_h
		logical_w: win_w
		logical_h: win_h
	}
	app.sound_mgr.init()
	ctx.run()
}
