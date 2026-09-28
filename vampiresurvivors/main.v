module main

import gg
import math
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      Game
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_game()
		last_tick: time.ticks()
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f64(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := math.min(raw_dt, 0.05)

	is_active := app.game.state == .playing || app.game.state == .level_up || app.game.state == .chest_opened
		|| app.game.state == .character_select || app.game.state == .power_up_shop
	app.game.sound_mgr.update_bgm(is_active)

	// Update Player velocities from directional flags
	if app.game.state == .playing && app.game.players.len > 0 {
		mut p1_vx := 0.0
		mut p1_vy := 0.0
		if app.game.p1_up {
			p1_vy -= 1.0
		}
		if app.game.p1_down {
			p1_vy += 1.0
		}
		if app.game.p1_left {
			p1_vx -= 1.0
		}
		if app.game.p1_right {
			p1_vx += 1.0
		}
		p1_vx, p1_vy = normalize(p1_vx, p1_vy)
		app.game.players[0].vx = p1_vx
		app.game.players[0].vy = p1_vy

		if app.game.is_coop && app.game.players.len > 1 {
			mut p2_vx := 0.0
			mut p2_vy := 0.0
			if app.game.p2_up {
				p2_vy -= 1.0
			}
			if app.game.p2_down {
				p2_vy += 1.0
			}
			if app.game.p2_left {
				p2_vx -= 1.0
			}
			if app.game.p2_right {
				p2_vx += 1.0
			}
			p2_vx, p2_vy = normalize(p2_vx, p2_vy)
			app.game.players[1].vx = p2_vx
			app.game.players[1].vy = p2_vy
		}
	}

	app.game.update(dt)
	app.game.render(&app.renderer)
	prod_fx_render(app.ctx)
	app.game.sound_mgr.update()
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
				.escape {
					if app.game.state == .playing {
						app.game.state = .paused
					} else if app.game.state == .paused {
						app.game.state = .playing
					} else if app.game.state == .power_up_shop {
						app.game.state = .character_select
					} else {
						exit(0)
					}
				}
				.p {
					if app.game.state == .playing {
						app.game.state = .paused
					} else if app.game.state == .paused {
						app.game.state = .playing
					}
				}
				.h, .f {
					app.game.cycle_speed()
				}
				.tab {
					app.game.show_radar = !app.game.show_radar
				}
				.t, .b {
					app.game.sound_mgr.cycle_bgm()
				}
				.m {
					if app.game.state == .character_select {
						app.game.cycle_stage()
					} else {
						app.game.sound_mgr.toggle_music()
					}
				}
				.n, .o {
					app.game.sound_mgr.toggle_sfx()
				}
				.f5 {
					save_data_to_file(&app.game.save_data)
				}
				.f9 {
					app.game.save_data = load_save_data()
				}
				.f11, .grave_accent {
					gg.toggle_fullscreen()
				}
				.f10 {
					prod_fx_cycle_mode()
				}
				else {
					if app.game.state == .character_select {
						match e.key_code {
							._1 { app.game.start_game(.antonio, .imelda, app.game.is_coop) }
							._2 { app.game.start_game(.imelda, .antonio, app.game.is_coop) }
							._3 { app.game.start_game(.pasqualina, .gennaro, app.game.is_coop) }
							._4 { app.game.start_game(.gennaro, .pasqualina, app.game.is_coop) }
							._5 { app.game.start_game(.mortaccio, .eleanor, app.game.is_coop) }
							._6 { app.game.start_game(.eleanor, .mortaccio, app.game.is_coop) }
							.c { app.game.is_coop = !app.game.is_coop }
							.d, .k { app.game.cycle_difficulty() }
							.u { app.game.state = .power_up_shop }
							else {}
						}
					} else if app.game.state == .power_up_shop {
						match e.key_code {
							._1 { app.game.buy_powerup('might') }
							._2 { app.game.buy_powerup('health') }
							._3 { app.game.buy_powerup('speed') }
							._4 { app.game.buy_powerup('greed') }
							._5 { app.game.buy_powerup('growth') }
							._6 { app.game.buy_powerup('rerolls') }
							._7 { app.game.buy_powerup('banish') }
							.u { app.game.state = .character_select }
							else {}
						}
					} else if app.game.state == .level_up {
						match e.key_code {
							._1 { app.game.select_upgrade(0) }
							._2 { app.game.select_upgrade(1) }
							._3 { app.game.select_upgrade(2) }
							.r { app.game.reroll_upgrades(0) }
							.s { app.game.skip_upgrade(0) }
							.b { app.game.banish_upgrade(0, app.game.selected_card) }
							.up, .w {
								if app.game.upgrade_cards.len > 0 {
									app.game.selected_card = (app.game.selected_card - 1 + app.game.upgrade_cards.len) % app.game.upgrade_cards.len
								}
							}
							.down {
								if app.game.upgrade_cards.len > 0 {
									app.game.selected_card = (app.game.selected_card + 1) % app.game.upgrade_cards.len
								}
							}
							.space, .enter {
								app.game.select_upgrade(app.game.selected_card)
							}
							else {}
						}
					} else if app.game.state == .chest_opened {
						if e.key_code == .space || e.key_code == .enter {
							app.game.state = .playing
						}
					} else if app.game.state == .game_over || app.game.state == .victory {
						if e.key_code == .r || e.key_code == .enter {
							app.game.state = .character_select
						}
					} else if app.game.state == .playing {
						match e.key_code {
							.left_shift, .right_shift { app.game.perform_dash(0) }
							.space { app.game.activate_ultimate(0) }
							else {}
						}
					}

					// Movement keys
					match e.key_code {
						.w { app.game.p1_up = true }
						.s { app.game.p1_down = true }
						.a { app.game.p1_left = true }
						.d { app.game.p1_right = true }
						.up {
							if app.game.is_coop {
								app.game.p2_up = true
							} else {
								app.game.p1_up = true
							}
						}
						.down {
							if app.game.is_coop {
								app.game.p2_down = true
							} else {
								app.game.p1_down = true
							}
						}
						.left {
							if app.game.is_coop {
								app.game.p2_left = true
							} else {
								app.game.p1_left = true
							}
						}
						.right {
							if app.game.is_coop {
								app.game.p2_right = true
							} else {
								app.game.p1_right = true
							}
						}
						else {}
					}
				}
			}
		}
		.key_up {
			match e.key_code {
				.w { app.game.p1_up = false }
				.s { app.game.p1_down = false }
				.a { app.game.p1_left = false }
				.d { app.game.p1_right = false }
				.up {
					if app.game.is_coop {
						app.game.p2_up = false
					} else {
						app.game.p1_up = false
					}
				}
				.down {
					if app.game.is_coop {
						app.game.p2_down = false
					} else {
						app.game.p1_down = false
					}
				}
				.left {
					if app.game.is_coop {
						app.game.p2_left = false
					} else {
						app.game.p1_left = false
					}
				}
				.right {
					if app.game.is_coop {
						app.game.p2_right = false
					} else {
						app.game.p1_right = false
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
		width:         win_width
		height:        win_height
		resizable:     true
		window_title:  'Vampire Survivors Arcade'
		user_data:     &app
		frame_fn:      on_frame
		event_fn:      on_event
		bg_color:      gg.Color{r: 10, g: 8, b: 12, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx: ctx
	}
	app.game.init_textures(&app.renderer)
	ctx.run()
}
