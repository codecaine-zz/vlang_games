module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      TexasGame
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_texas_game()
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

	draw_texas_game(&app.renderer, &app.game)
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
				.escape {
					exit(0)
				}
				.m {
					app.sound_mgr.toggle_music()
				}
				.space, .enter {
					if app.game.stage == .round_over {
						app.game.start_new_hand()
					} else if app.game.current_turn_idx == 0 && !app.game.players[0].is_folded && !app.game.players[0].is_all_in {
						app.game.player_action_check_call(0, mut app.sound_mgr)
					}
				}
				.c {
					if app.game.current_turn_idx == 0 && !app.game.players[0].is_folded && !app.game.players[0].is_all_in {
						app.game.player_action_check_call(0, mut app.sound_mgr)
					}
				}
				.f {
					if app.game.current_turn_idx == 0 && !app.game.players[0].is_folded && !app.game.players[0].is_all_in {
						app.game.player_action_fold(0, mut app.sound_mgr)
					}
				}
				.r {
					if app.game.current_turn_idx == 0 && !app.game.players[0].is_folded && !app.game.players[0].is_all_in {
						app.game.player_action_raise(0, app.game.raise_amount, mut app.sound_mgr)
					}
				}
				.a {
					if app.game.current_turn_idx == 0 && !app.game.players[0].is_folded && !app.game.players[0].is_all_in {
						all_in_amt := app.game.players[0].chips + app.game.players[0].current_bet
						app.game.player_action_raise(0, all_in_amt, mut app.sound_mgr)
					}
				}
				.up, .w {
					if app.game.current_turn_idx == 0 && !app.game.players[0].is_folded && !app.game.players[0].is_all_in {
						app.game.raise_amount += 20
					}
				}
				.down, .s {
					if app.game.current_turn_idx == 0 && !app.game.players[0].is_folded && !app.game.players[0].is_all_in {
						if app.game.raise_amount > 20 {
							app.game.raise_amount -= 20
						}
					}
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
		window_title: 'Texas Hold\'em - 16-Bit Cyber Poker'
		user_data: &app
		frame_fn: on_frame
		event_fn: on_event
		bg_color: gg.Color{10, 25, 18, 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{ctx: ctx}
	ctx.run()
}
