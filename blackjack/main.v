module main

import gg
import math
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      BlackjackGame
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_blackjack_game()
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
	dt := math.min(0.033, if raw_dt > 0.001 { raw_dt } else { 1.0 / 60.0 })

	app.game.update(dt, mut app.sound_mgr)
	app.sound_mgr.update()

	draw_blackjack_game(&app.renderer, &app.game)
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

				if app.game.state == .betting {
					// Click Chips
					if my >= 440 && my <= 480 {
						chips_x := 80
						for i := 0; i < 5; i++ {
							cx := chips_x + i * 48
							if mx >= cx - 20 && mx <= cx + 20 {
								amounts := [5, 25, 50, 100, 500]
								app.game.place_chip(amounts[i])
								app.sound_mgr.play_chip_clink()
								break
							}
						}
					}
					// Click Deal circle
					else if mx >= 360 && mx <= 440 && my >= 420 && my <= 500 {
						app.game.deal(mut app.sound_mgr)
					}
				} else if app.game.state == .round_over {
					app.game.state = .betting
					app.game.celebration = ''
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
				.space, .enter {
					if app.game.state == .betting {
						app.game.deal(mut app.sound_mgr)
					} else if app.game.state == .round_over {
						app.game.state = .betting
						app.game.celebration = ''
					}
				}
				.h {
					app.game.hit(mut app.sound_mgr)
				}
				.s {
					app.game.stand(mut app.sound_mgr)
				}
				.d {
					app.game.double_down(mut app.sound_mgr)
				}
				.p {
					app.game.split(mut app.sound_mgr)
				}
				.i {
					app.game.buy_insurance()
				}
				.c {
					app.game.clear_bet()
				}
				._1 {
					app.game.place_chip(5)
					app.sound_mgr.play_chip_clink()
				}
				._2 {
					app.game.place_chip(25)
					app.sound_mgr.play_chip_clink()
				}
				._3 {
					app.game.place_chip(50)
					app.sound_mgr.play_chip_clink()
				}
				._4 {
					app.game.place_chip(100)
					app.sound_mgr.play_chip_clink()
				}
				._5 {
					app.game.place_chip(500)
					app.sound_mgr.play_chip_clink()
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
		width:        800
		height:       600
		resizable:     true
		window_title: 'Blackjack 21 Pro - Vegas Casino Table'
		user_data:    &app
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
