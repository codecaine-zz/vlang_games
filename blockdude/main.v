module main

import gg
import math
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      BlockDudeGame
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_blockdude_game()
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

	if app.game.toast_timer > 0 {
		app.game.toast_timer -= dt
	}

	draw_blockdude_game(&app.renderer, &app.game)
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
				.escape {
					exit(0)
				}
				.f5 {
					app.game.save_state()
				}
				.f9 {
					app.game.load_state()
				}
				.m {
					app.sound_mgr.toggle_music()
				}
				.u {
					if app.game.undo() {
						app.sound_mgr.play_step()
					}
				}
				.r {
					app.game.restart_level()
					app.sound_mgr.play_restart()
				}
				.n {
					app.game.next_level()
					app.sound_mgr.play_step()
				}
				.p {
					app.game.prev_level()
					app.sound_mgr.play_step()
				}
				.left, .a {
					prev_y := app.game.player_y
					if app.game.move_dir(.left) {
						if app.game.player_y < prev_y {
							app.sound_mgr.play_climb()
						} else {
							app.sound_mgr.play_step()
						}
						if app.game.state == .level_complete || app.game.state == .game_won {
							app.sound_mgr.play_win()
						}
					}
				}
				.right, .d {
					prev_y := app.game.player_y
					if app.game.move_dir(.right) {
						if app.game.player_y < prev_y {
							app.sound_mgr.play_climb()
						} else {
							app.sound_mgr.play_step()
						}
						if app.game.state == .level_complete || app.game.state == .game_won {
							app.sound_mgr.play_win()
						}
					}
				}
				.space, .up, .w, .down, .s {
					if app.game.state == .level_complete {
						app.game.next_level()
						app.sound_mgr.play_step()
					} else if app.game.state == .game_won {
						app.game.load_level(0)
						app.sound_mgr.play_restart()
					} else {
						was_carrying := app.game.carrying_block
						if app.game.pickup_or_drop() {
							if was_carrying {
								app.sound_mgr.play_drop()
							} else {
								app.sound_mgr.play_pickup()
							}
						}
					}
				}
				.enter {
					if app.game.state == .level_complete {
						app.game.next_level()
						app.sound_mgr.play_step()
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
		width:        800
		height:       600
		resizable:     true
		window_title: 'TI-83 Block Dude - Retro Puzzle Platformer'
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
