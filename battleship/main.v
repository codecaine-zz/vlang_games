module main

import gg
import math
import time

const win_w = 940
const win_h = 660

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      BattleshipGame
	sound_mgr SoundManager
	tex_mgr   BattleshipTextureManager
	mouse_x   int
	mouse_y   int
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_battleship_game(false)
		sound_mgr: new_sound_manager()
		tex_mgr:   new_battleship_texture_manager()
		last_tick: time.ticks()
	}
}

fn on_init(data voidptr) {
	mut app := unsafe { &App(data) }
	app.tex_mgr.init(&app.renderer)
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	dt := math.min(f64(now - app.last_tick) / 1000.0, 0.05)
	app.last_tick = now

	app.game.update(dt)

	// Play sound events
	if app.game.sound_event != '' {
		ev := app.game.sound_event
		app.game.sound_event = ''
		match ev {
			'sonar' { app.sound_mgr.play_sonar() }
			'launch' { app.sound_mgr.play_launch() }
			'splash' { app.sound_mgr.play_splash() }
			'hit' { app.sound_mgr.play_hit() }
			'sunk' { app.sound_mgr.play_sunk() }
			'victory' { app.sound_mgr.play_victory() }
			'place' { app.sound_mgr.play_place() }
			'radar' { app.sound_mgr.play_radar() }
			else {}
		}
	}

	// Stream background soundtrack & active SFX channels
	app.sound_mgr.update()
	app.sound_mgr.update_bgm(true)

	render_battleship_game(&app.renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y, app.tex_mgr.sprite_texture)

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
			mx := int(e.mouse_x)
			my := int(e.mouse_y)

			if e.mouse_button == .right {
				// Toggle placement orientation
				if app.game.phase == .placement {
					app.game.place_horizontal = !app.game.place_horizontal
				}
			} else if e.mouse_button == .left {
				grid_pix := 32
				left_gx := 50
				left_gy := 120
				right_gx := 520
				right_gy := 120
				panel_y := win_h - 170

				if app.game.phase == .placement {
					// Check click on ship selection buttons
					for i in 0 .. app.game.p1_grid.ships.len {
						bx := 40 + i * 140
						by := panel_y + 52
						if mx >= bx && mx <= bx + 130 && my >= by && my <= by + 42 {
							app.game.selected_ship_idx = i
						}
					}

					// Check click on Auto-Place button
					if mx >= 760 && mx <= 890 && my >= panel_y + 14 && my <= panel_y + 50 {
						app.game.p1_grid.auto_place_all()
						app.sound_mgr.play_sonar()
					}

					// Check click on Start Battle button
					if mx >= 760 && mx <= 890 && my >= panel_y + 58 && my <= panel_y + 94 {
						app.game.start_battle()
					}

					// Check click on player placement grid
					if mx >= left_gx && mx < left_gx + grid_pix * 10 && my >= left_gy && my < left_gy + grid_pix * 10 {
						gx := (mx - left_gx) / grid_pix
						gy := (my - left_gy) / grid_pix
						if app.game.p1_grid.place_ship(app.game.selected_ship_idx, gx, gy, app.game.place_horizontal) {
							app.sound_mgr.play_sonar()
							// Select next unplaced ship
							for next_i, s in app.game.p1_grid.ships {
								if !s.placed {
									app.game.selected_ship_idx = next_i
									break
								}
							}
						}
					}
				} else if app.game.phase == .battle {
					// Check Radar Recon button click
					if mx >= 750 && mx <= 890 && my >= panel_y + 35 && my <= panel_y + 77 {
						if app.game.radar_left_p1 > 0 {
							app.game.radar_active = !app.game.radar_active
						}
					}

					// Check click on enemy radar grid
					if mx >= right_gx && mx < right_gx + grid_pix * 10 && my >= right_gy && my < right_gy + grid_pix * 10 {
						gx := (mx - right_gx) / grid_pix
						gy := (my - right_gy) / grid_pix
						app.game.execute_player_turn(gx, gy)
					}
				} else if app.game.phase == .game_over {
					app.game.reset()
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
				.r {
					if app.game.phase == .placement {
						app.game.place_horizontal = !app.game.place_horizontal
					} else if app.game.phase == .game_over {
						app.game.reset()
					}
				}
				.f {
					if app.game.phase == .placement {
						app.game.p1_grid.auto_place_all()
						app.sound_mgr.play_sonar()
					}
				}
				.space {
					if app.game.phase == .placement {
						app.game.start_battle()
					} else if app.game.phase == .game_over {
						app.game.reset()
					}
				}
				.v, .o {
					app.sound_mgr.toggle_sound()
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
		window_title: 'Battleship Pro - Tactical Naval Warfare & Radar Strategy'
		user_data:    &app
		init_fn:      on_init
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
