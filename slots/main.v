module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      SlotsGame
	sound_mgr SoundManager
	tex_mgr   SlotsTextureManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_slots_game()
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
	app.sound_mgr.update_bgm(true)

	draw_slots_game(&app.renderer, &app.game, app.tex_mgr.sprite_texture)
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
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)

				if mx >= 690 && mx <= 770 && my >= 200 && my <= 400 {
					app.game.pull_lever(mut app.sound_mgr)
				} else if mx >= 550 && mx <= 660 && my >= 490 && my <= 520 {
					app.game.pull_lever(mut app.sound_mgr)
				} else if app.game.theme == .vegas_classic && my >= 170 && my <= 410 {
					rx := int(app.game.grid_x)
					rw := int(app.game.reel_w)
					for r := 0; r < 3; r++ {
						if mx >= rx + r * rw && mx < rx + (r + 1) * rw {
							app.game.toggle_hold(r)
						}
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
					if app.game.show_paytable {
						app.game.show_paytable = false
					} else {
						exit(0)
					}
				}
				.space, .enter {
					app.game.pull_lever(mut app.sound_mgr)
				}
				.tab, .p {
					app.game.show_paytable = !app.game.show_paytable
				}
				.t {
					new_th := if app.game.theme == .vegas_classic { SlotTheme.neon_cyber } else { SlotTheme.vegas_classic }
					app.game.init_theme(new_th)
				}
				.up, .w {
					app.game.adjust_bet(5)
				}
				.down, .s {
					app.game.adjust_bet(-5)
				}
				.right, .d {
					app.game.adjust_lines(1)
				}
				.left, .a {
					app.game.adjust_lines(-1)
				}
				.m {
					app.game.max_bet()
				}
				.c {
					app.game.add_credits(500)
					app.sound_mgr.play_coin_payout()
				}
				._1 {
					app.game.toggle_hold(0)
				}
				._2 {
					app.game.toggle_hold(1)
				}
				._3 {
					app.game.toggle_hold(2)
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
		window_title: 'Vegas Jackpot Slots - 777 & Neon Cyber'
		user_data: &app
		frame_fn: on_frame
		event_fn: on_event
		bg_color: gg.Color{15, 12, 28, 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{ctx: ctx}
	app.tex_mgr.init(&app.renderer)
	app.sound_mgr.init()
	ctx.run()
}
