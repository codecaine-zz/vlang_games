module main

import gg
import time

const win_w = 940
const win_h = 660

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      LiarsDiceGame
	sound_mgr SoundManager
	mouse_x   int
	mouse_y   int
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_liarsdice_game(false)
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

	app.game.update(dt)
	app.sound_mgr.update()

	render_liarsdice_game(&app.renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y)
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
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				panel_y := win_h - 85

				if app.game.phase == .round_over {
					app.game.start_new_round()
					app.sound_mgr.play_cup_shake()
				} else if app.game.phase == .game_over {
					app.game.reset()
					app.sound_mgr.play_cup_shake()
				} else if app.game.phase == .bidding && !app.game.players[app.game.current_player].is_ai {
					if mx >= 80 && mx <= 110 && my >= panel_y + 10 && my <= panel_y + 42 {
						if app.game.selected_qty > 1 {
							app.game.selected_qty--
							app.sound_mgr.play_bid()
						}
					}
					if mx >= 160 && mx <= 190 && my >= panel_y + 10 && my <= panel_y + 42 {
						if app.game.selected_qty < app.game.total_active_dice() {
							app.game.selected_qty++
							app.sound_mgr.play_bid()
						}
					}
					for f := 1; f <= 6; f++ {
						fx := 260 + (f - 1) * 44
						if mx >= fx - 2 && mx <= fx + 34 && my >= panel_y + 8 && my <= panel_y + 44 {
							app.game.selected_face = f
							app.sound_mgr.play_bid()
						}
					}
					if mx >= 540 && mx <= 640 && my >= panel_y + 10 && my <= panel_y + 44 {
						if app.game.make_bid(app.game.current_player, app.game.selected_qty, app.game.selected_face) {
							app.sound_mgr.play_bid()
						}
					}
					if mx >= 655 && mx <= 765 && my >= panel_y + 10 && my <= panel_y + 44 {
						if app.game.call_liar(app.game.current_player) {
							app.sound_mgr.play_challenge()
						}
					}
					if mx >= 780 && mx <= 890 && my >= panel_y + 10 && my <= panel_y + 44 {
						if app.game.call_spot_on(app.game.current_player) {
							app.sound_mgr.play_spot_on()
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
				.escape { exit(0) }
				.r {
					app.game.reset()
					app.sound_mgr.play_cup_shake()
				}
				.m {
					app.game.is_two_player = !app.game.is_two_player
					app.game.reset()
					app.sound_mgr.play_cup_shake()
				}
				.s { app.sound_mgr.toggle_sound() }
				.space {
					if app.game.phase == .round_over {
						app.game.start_new_round()
						app.sound_mgr.play_cup_shake()
					} else if app.game.phase == .game_over {
						app.game.reset()
						app.sound_mgr.play_cup_shake()
					} else if app.game.phase == .bidding && !app.game.players[app.game.current_player].is_ai {
						if app.game.make_bid(app.game.current_player, app.game.selected_qty, app.game.selected_face) {
							app.sound_mgr.play_bid()
						}
					}
				}
				.l {
					if app.game.phase == .bidding && !app.game.players[app.game.current_player].is_ai {
						if app.game.call_liar(app.game.current_player) {
							app.sound_mgr.play_challenge()
						}
					}
				}
				.c {
					if app.game.phase == .bidding && !app.game.players[app.game.current_player].is_ai {
						if app.game.call_spot_on(app.game.current_player) {
							app.sound_mgr.play_spot_on()
						}
					}
				}
				.up {
					if app.game.selected_qty < app.game.total_active_dice() {
						app.game.selected_qty++
						app.sound_mgr.play_bid()
					}
				}
				.down {
					if app.game.selected_qty > 1 {
						app.game.selected_qty--
						app.sound_mgr.play_bid()
					}
				}
				.right {
					if app.game.selected_face < 6 {
						app.game.selected_face++
						app.sound_mgr.play_bid()
					}
				}
				.left {
					if app.game.selected_face > 1 {
						app.game.selected_face--
						app.sound_mgr.play_bid()
					}
				}
				._1 { app.game.selected_face = 1; app.sound_mgr.play_bid() }
				._2 { app.game.selected_face = 2; app.sound_mgr.play_bid() }
				._3 { app.game.selected_face = 3; app.sound_mgr.play_bid() }
				._4 { app.game.selected_face = 4; app.sound_mgr.play_bid() }
				._5 { app.game.selected_face = 5; app.sound_mgr.play_bid() }
				._6 { app.game.selected_face = 6; app.sound_mgr.play_bid() }
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
		window_title: "Liar's Dice (Perudo / Dudo) - Bluffing Dice Game"
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 20, g: 25, b: 35, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
