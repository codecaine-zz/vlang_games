module main

import gg
import math
import time

const win_w = 900
const win_h = 720

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      SokobanGame
	sound_mgr SoundManager
	tex_mgr   SokobanTextureManager
	pulse     f64
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_sokoban_game()
		sound_mgr: new_sound_manager()
		last_tick: time.ticks()
	}
}

fn (mut app App) handle_move(dr int, dc int) {
	moved, pushed, hit_target := app.game.try_move(dr, dc)
	if moved {
		if pushed {
			app.sound_mgr.play_push_sound()
			if hit_target {
				app.sound_mgr.play_target_sound()
			}
		} else {
			app.sound_mgr.play_step_sound()
		}

		if app.game.level_cleared {
			app.sound_mgr.play_win_sound()
		}
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f64(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := math.min(raw_dt, 0.05)
	app.pulse += dt

	target_x := f64(app.game.player_c)
	target_y := f64(app.game.player_r)
	app.game.anim_px += (target_x - app.game.anim_px) * math.min(dt * 18.0, 1.0)
	app.game.anim_py += (target_y - app.game.anim_py) * math.min(dt * 18.0, 1.0)

	if app.game.toast_timer > 0 {
		app.game.toast_timer -= dt
	}

	app.sound_mgr.update_bgm(true)
	render_sokoban_game(&app.renderer, &app.game, win_w, win_h, app.pulse, app.tex_mgr.sprite_texture)
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
				.r {
					app.game.load_level(app.game.current_level)
				}
				.u, .z {
					app.game.undo()
				}
				.n {
					if app.game.current_level < sokoban_levels.len - 1 {
						app.game.load_level(app.game.current_level + 1)
						app.game.save_progress()
					}
				}
				.p {
					if app.game.current_level > 0 {
						app.game.load_level(app.game.current_level - 1)
						app.game.save_progress()
					}
				}
				.space {
					if app.game.level_cleared {
						if app.game.current_level < sokoban_levels.len - 1 {
							app.game.load_level(app.game.current_level + 1)
							app.game.save_progress()
						}
					}
				}
				.m {
					app.sound_mgr.toggle_music()
				}
				.up, .w {
					app.handle_move(-1, 0)
				}
				.down, .s {
					app.handle_move(1, 0)
				}
				.left, .a {
					app.handle_move(0, -1)
				}
				.right, .d {
					app.handle_move(0, 1)
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
		window_title:  'Sokoban Master - Warehouse Puzzle Strategy'
		user_data:     &app
		frame_fn:      on_frame
		event_fn:      on_event
		bg_color:      gg.Color{r: 20, g: 25, b: 35, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx: ctx
	}
	app.tex_mgr.init(&app.renderer)
	ctx.run()
}
