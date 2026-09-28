module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      TowerDefenseGame
	tex_mgr   TowerDefenseTextureManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_towerdefense_game()
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

	if app.game.toast_timer > 0 {
		app.game.toast_timer -= dt
	}
	app.game.update(dt)
	app.game.sound_mgr.update_bgm(app.game.state == .playing)

	render_towerdefense_game(&app.renderer, mut app.game, app.tex_mgr.sprite_texture)
	app.game.sound_mgr.update()
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
			if app.game.state == .menu || app.game.state == .game_over || app.game.state == .victory {
				app.game.reset_game()
			} else {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				gx := (mx - offset_x) / tile_size
				gy := (my - offset_y) / tile_size

				if gx >= 0 && gx < grid_cols && gy >= 0 && gy < grid_rows {
					app.game.selected_gx = gx
					app.game.selected_gy = gy
					app.game.place_turret(gx, gy, app.game.selected_type)
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
					app.game.sound_mgr.toggle_sfx()
				}
				.escape {
					exit(0)
				}
				._1, .kp_1, .l {
					app.game.selected_type = .laser
				}
				._2, .kp_2, .c {
					app.game.selected_type = .cannon
				}
				._3, .kp_3, .f {
					app.game.selected_type = .frost
				}
				.left, .a {
					if app.game.selected_gx > 0 { app.game.selected_gx-- }
				}
				.right, .d {
					if app.game.selected_gx < grid_cols - 1 { app.game.selected_gx++ }
				}
				.up, .w {
					if app.game.selected_gy > 0 { app.game.selected_gy-- }
				}
				.down, .s {
					if app.game.selected_gy < grid_rows - 1 { app.game.selected_gy++ }
				}
				.space, .enter, .kp_enter, .b {
					if app.game.state == .menu || app.game.state == .game_over || app.game.state == .victory {
						app.game.reset_game()
					} else if app.game.state == .playing {
						app.game.place_turret(app.game.selected_gx, app.game.selected_gy, app.game.selected_type)
					}
				}
				.u {
					app.game.upgrade_turret(app.game.selected_gx, app.game.selected_gy)
				}
				.x, .delete, .backspace {
					app.game.sell_turret(app.game.selected_gx, app.game.selected_gy)
				}
				.p {
					if app.game.state == .playing {
						app.game.state = .paused
					} else if app.game.state == .paused {
						app.game.state = .playing
					}
				}
				.r {
					app.game.reset_game()
				}
				.m {
					app.game.sound_mgr.toggle_music()
				}
				.f5 {
					app.game.save_state()
				}
				.f9 {
					app.game.load_state()
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
		width:         800
		height:        600
		resizable:     true
		window_title:  'Cyber Defense Tower Defense'
		user_data:     &app
		frame_fn:      on_frame
		event_fn:      on_event
		bg_color:      gg.Color{r: 15, g: 20, b: 30, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx: ctx
	}
	app.tex_mgr.init(&app.renderer)
	ctx.run()
}
