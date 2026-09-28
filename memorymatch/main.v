module main

import gg
import time

const win_w = 900
const win_h = 650

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      MemoryGame
	sound_mgr SoundManager
	hover_idx int = -1
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_memory_game()
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

	render_memory_match(&app.renderer, &app.game, win_w, win_h, app.hover_idx)
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
			app.hover_idx = get_card_index_at(mx, my, &app.game, win_w, win_h)
		}
		.mouse_down {
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				if app.game.state == .game_won {
					app.game.reset_game()
				} else {
					if my < 54 {
						if mx >= 220 && mx <= 360 {
							app.game.toggle_grid_mode()
							app.sound_mgr.play_click_sound()
						} else if mx >= 380 && mx <= 490 {
							app.sound_mgr.toggle_sound()
						} else if mx >= win_w - 140 && mx <= win_w - 20 {
							app.game.reset_game()
							app.sound_mgr.play_click_sound()
						}
					} else {
						clicked_idx := get_card_index_at(mx, my, &app.game, win_w, win_h)
						if clicked_idx >= 0 {
							_, ev := app.game.flip_card(clicked_idx)
							if ev.card_flipped {
								app.sound_mgr.play_flip_sound()
							}
							if ev.cards_matched {
								app.sound_mgr.play_match_sound(ev.combo_level)
							}
							if ev.cards_mismatch {
								app.sound_mgr.play_mismatch_sound()
							}
							if ev.game_won {
								app.sound_mgr.play_win_fanfare()
							}
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
				.m {
					app.sound_mgr.toggle_music()
				}
				.escape { exit(0) }
				.r { app.game.reset_game() }
				.g { app.game.toggle_grid_mode() }
				.s { app.sound_mgr.toggle_sound() }
				.space {
					if app.game.state == .game_won {
						app.game.reset_game()
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
		width:        win_w
		height:       win_h
		resizable:     true
		window_title: 'Memory Match Pro - 3D Card Flip Pair Memory Training'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 15, g: 20, b: 35, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
