module main

import gg
import time

const win_width = 800
const win_height = 576

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      TowerFallGame
	tex_mgr   TextureManager
	key_left  bool
	key_right bool
	key_up    bool
	key_down  bool
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_towerfall_game()
		last_tick: time.ticks()
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f64(now - app.last_tick) / 1000.0
	app.last_tick = now
	capped_dt := if raw_dt > 0.05 { 0.05 } else { raw_dt }

	// Continuous movement for P1
	if app.game.mode != .menu && app.game.players.len > 0 {
		mut p := unsafe { &app.game.players[0] }
		if !p.is_dashing {
			if app.key_left {
				p.vx = -220.0
				p.facing = -1
			} else if app.key_right {
				p.vx = 220.0
				p.facing = 1
			}

			mut ax := f64(p.facing)
			mut ay := 0.0
			if app.key_up { ay = -1.0 }
			if app.key_down { ay = 1.0 }
			if app.key_left || app.key_right { ax = if app.key_left { -1.0 } else { 1.0 } }
			p.aim_x = ax
			p.aim_y = ay
		}
	}

	app.game.update(capped_dt)
	app.game.sound_mgr.update_bgm(app.game.mode != .menu)
	app.game.sound_mgr.update()
	render_towerfall_game(&app.renderer, mut app.game, app.tex_mgr.sprite_texture)
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
					app.game.sound_mgr.toggle_sfx()
				}
				.m {
					app.game.sound_mgr.toggle_music()
				}
				.escape {
					if app.game.mode != .menu {
						app.game.mode = .menu
					} else {
						exit(0)
					}
				}
				.f5 {
					app.game.save_state()
				}
				.f9 {
					app.game.load_state()
				}
				else {
					if app.game.mode == .menu {
						match e.key_code {
							.up, .w {
								app.game.menu_selected = (app.game.menu_selected + 1) % 2
							}
							.down, .s {
								app.game.menu_selected = (app.game.menu_selected + 1) % 2
							}
							._1 {
								app.game.start_quest()
							}
							._2 {
								app.game.start_versus()
							}
							.space, .enter, .j {
								if app.game.menu_selected == 0 {
									app.game.start_quest()
								} else {
									app.game.start_versus()
								}
							}
							else {}
						}
					} else {
						match e.key_code {
							.a, .left { app.key_left = true }
							.d, .right { app.key_right = true }
							.w, .up { app.key_up = true }
							.s, .down { app.key_down = true }
							.space, .k {
								if app.game.players.len > 0 {
									mut p := unsafe { &app.game.players[0] }
									if p.is_grounded {
										p.vy = -480.0
										app.game.sound_mgr.play_clip('jump')
									} else if p.is_wall_slide {
										p.vy = -440.0
										p.vx = f64(-p.wall_dir) * 320.0
										app.game.sound_mgr.play_clip('jump')
									}
								}
							}
							.j, .l, .enter {
								if app.game.players.len > 0 {
									mut p := unsafe { &app.game.players[0] }
									app.game.shoot_arrow(mut p)
								}
							}
							.left_shift, .right_shift, .i {
								if app.game.players.len > 0 {
									mut p := unsafe { &app.game.players[0] }
									mut dx := 0.0
									mut dy := 0.0
									if app.key_left { dx = -1.0 }
									if app.key_right { dx = 1.0 }
									if app.key_up { dy = -1.0 }
									if app.key_down { dy = 1.0 }
									if dx == 0.0 && dy == 0.0 { dx = f64(p.facing) }
									app.game.dodge_dash(mut p, dx, dy)
								}
							}
							else {}
						}
					}
				}
			}
		}
		.key_up {
			match e.key_code {
				.a, .left { app.key_left = false }
				.d, .right { app.key_right = false }
				.w, .up { app.key_up = false }
				.s, .down { app.key_down = false }
				else {}
			}
		}
		else {}
	}
}

fn main() {
	mut app := new_app()
	mut ctx := gg.new_context(
		width:         win_width
		height:        win_height
		resizable:     true
		window_title:  'TowerFall Ascension - V & GG'
		user_data:     &app
		frame_fn:      on_frame
		event_fn:      on_event
		bg_color:      gg.Color{r: 20, g: 15, b: 30, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx: ctx
	}
	app.tex_mgr.init(&app.renderer)
	ctx.run()
}
