module main

import gg
import time

const win_w = 880
const win_h = 600

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      ChimpGame
	sound_mgr SoundManager
	mouse_x   int
	mouse_y   int
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_chimp_game()
		sound_mgr: new_sound_manager()
		last_tick: time.ticks()
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	hover_gx, hover_gy := get_chimp_grid_coords_at(app.mouse_x, app.mouse_y, win_w, win_h)

	app.sound_mgr.update()

	render_chimp_test(&app.renderer, &app.game, win_w, win_h, hover_gx, hover_gy)
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
				hover_gx, hover_gy := get_chimp_grid_coords_at(app.mouse_x, app.mouse_y, win_w, win_h)
				if app.game.state == .level_failed || app.game.state == .benchmark_over {
					app.game.handle_cell_click(0, 0)
				} else if hover_gx >= 0 && hover_gy >= 0 {
					_, ev := app.game.handle_cell_click(hover_gx, hover_gy)
					if ev.tile_clicked > 0 {
						app.sound_mgr.play_tile_chime(ev.tile_clicked)
					}
					if ev.strike_taken {
						app.sound_mgr.play_strike_buzzer()
					}
					if ev.level_cleared {
						app.sound_mgr.play_level_clear()
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
				.escape {
					exit(0)
				}
				.r {
					app.game.reset_game()
				}
				.s {
					app.sound_mgr.toggle_sound()
				}
				.space {
					if app.game.state == .level_failed || app.game.state == .benchmark_over {
						app.game.handle_cell_click(0, 0)
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
		window_title: 'Chimp Test Pro - Spatial Working Memory Benchmark'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 0, g: 0, b: 0, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
