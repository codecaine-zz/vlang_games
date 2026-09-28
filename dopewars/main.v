module main

import gg
import time

const win_w = 920
const win_h = 640

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      DopeWarsGame
	sound_mgr SoundManager
	mouse_x   int
	mouse_y   int
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_dopewars_game()
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

	render_dopewars_game(&app.renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y, app.sound_mgr.sound_enabled)
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
				// Sound toggle badge
				sound_x := win_w - 140
				if mx >= sound_x && mx <= sound_x + 120 && my >= 10 && my <= 36 {
					app.sound_mgr.toggle_sound()
					return
				}

				match app.game.ui_state {
					.market {
						table_x := 30
						table_y := 65
						for i in 0 .. drug_catalogue.len {
							row_y := table_y + 44 + i * 42
							if my >= row_y - 4 && my <= row_y + 32 && mx >= table_x && mx <= table_x + 540 {
								app.game.selected_drug = i
								if mx >= table_x + 430 && mx <= table_x + 475 {
									app.game.buy_drug(i, 100)
								} else if mx >= table_x + 480 && mx <= table_x + 525 {
									app.game.sell_drug(i, 100)
								}
								break
							}
						}

						ledger_x := 590
						nav_y := 65 + 330
						if mx >= ledger_x + 20 && mx <= ledger_x + 280 {
							if my >= nav_y && my <= nav_y + 38 {
								app.game.ui_state = .subway
							} else if my >= nav_y + 50 && my <= nav_y + 88 {
								app.game.ui_state = .bank
							} else if my >= nav_y + 100 && my <= nav_y + 138 {
								app.game.ui_state = .loan_shark
							}
						}
					}
					.subway {
						locs := [
							Borough.manhattan,
							Borough.bronx,
							Borough.brooklyn,
							Borough.queens,
							Borough.staten_island,
							Borough.coney_island,
						]
						mut by := 190
						for l in locs {
							if mx >= win_w / 2 - 160 && mx <= win_w / 2 + 160 && my >= by && my <= by + 36 {
								app.game.travel_to(l)
								break
							}
							by += 48
						}
						if my >= win_h - 135 && my <= win_h - 100 {
							app.game.ui_state = .market
						}
					}
					.bank {
						if my >= 220 && my <= 250 {
							app.game.deposit_bank(app.game.cash)
						} else if my >= 260 && my <= 290 {
							app.game.withdraw_bank(app.game.bank)
						} else if my >= 315 && my <= 350 {
							app.game.ui_state = .market
						}
					}
					.loan_shark {
						if my >= 220 && my <= 255 {
							app.game.pay_debt(app.game.cash)
						} else if my >= 285 && my <= 325 {
							app.game.ui_state = .market
						}
					}
					.police_encounter {
						if my >= 255 && my <= 290 {
							app.game.handle_police_action('run')
						} else if my >= 295 && my <= 330 {
							app.game.handle_police_action('bribe')
						}
					}
					.game_over_screen {
						if my >= 400 && my <= 450 {
							app.game.init_game()
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
				.escape {
					if app.game.ui_state != .market && app.game.ui_state != .police_encounter {
						app.game.ui_state = .market
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
				.up {
					if app.game.ui_state == .market {
						app.game.selected_drug = (app.game.selected_drug + drug_catalogue.len - 1) % drug_catalogue.len
					}
				}
				.down {
					if app.game.ui_state == .market {
						app.game.selected_drug = (app.game.selected_drug + 1) % drug_catalogue.len
					}
				}
				.b {
					if app.game.ui_state == .market {
						app.game.buy_drug(app.game.selected_drug, 100)
					} else if app.game.ui_state == .police_encounter {
						app.game.handle_police_action('bribe')
					}
				}
				.s {
					if app.game.ui_state == .market {
						app.game.sell_drug(app.game.selected_drug, 100)
					}
				}
				.t {
					if app.game.ui_state == .market {
						app.game.ui_state = .subway
					}
				}
				.k {
					if app.game.ui_state == .market {
						app.game.ui_state = .bank
					}
				}
				.l {
					if app.game.ui_state == .market {
						app.game.ui_state = .loan_shark
					}
				}
				.d {
					if app.game.ui_state == .bank {
						app.game.deposit_bank(app.game.cash)
					}
				}
				.w {
					if app.game.ui_state == .bank {
						app.game.withdraw_bank(app.game.bank)
					}
				}
				.p {
					if app.game.ui_state == .loan_shark {
						app.game.pay_debt(app.game.cash)
					}
				}
				.r {
					if app.game.ui_state == .police_encounter {
						app.game.handle_police_action('run')
					} else if app.game.ui_state == .game_over_screen {
						app.game.init_game()
					}
				}
				.enter, .space {
					if app.game.ui_state == .market {
						app.game.buy_drug(app.game.selected_drug, 100)
					} else if app.game.ui_state == .game_over_screen {
						app.game.init_game()
					}
				}
				.m {
					app.sound_mgr.toggle_music()
				}
				._1 {
					if app.game.ui_state == .subway { app.game.travel_to(.manhattan) }
					else if app.game.ui_state == .market { app.game.selected_drug = 0 }
				}
				._2 {
					if app.game.ui_state == .subway { app.game.travel_to(.bronx) }
					else if app.game.ui_state == .market { app.game.selected_drug = 1 }
				}
				._3 {
					if app.game.ui_state == .subway { app.game.travel_to(.brooklyn) }
					else if app.game.ui_state == .market { app.game.selected_drug = 2 }
				}
				._4 {
					if app.game.ui_state == .subway { app.game.travel_to(.queens) }
					else if app.game.ui_state == .market { app.game.selected_drug = 3 }
				}
				._5 {
					if app.game.ui_state == .subway { app.game.travel_to(.staten_island) }
					else if app.game.ui_state == .market { app.game.selected_drug = 4 }
				}
				._6 {
					if app.game.ui_state == .subway { app.game.travel_to(.coney_island) }
					else if app.game.ui_state == .market { app.game.selected_drug = 5 }
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
		window_title: 'Dope Wars - 1984 Financial Strategy Game'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 10, g: 15, b: 24, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
