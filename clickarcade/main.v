module main

import gg
import math
import time

const win_w = 880
const win_h = 600

struct App {
pub mut:
	ctx           &gg.Context = unsafe { nil }
	renderer      Renderer
	arcade        ArcadeManager
	sound_mgr     SoundManager
	is_mouse_down bool
	mouse_x       int
	mouse_y       int
	last_tick     i64
}

fn new_app() App {
	return App{
		arcade:    new_arcade_manager()
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
	dt := math.min(raw_dt, 0.05)

	// Update hover state in menu
	if app.arcade.screen == .menu {
		app.arcade.hovered_btn = -1
		for i, btn in app.arcade.buttons {
			if app.mouse_x >= btn.x && app.mouse_x <= btn.x + btn.w && app.mouse_y >= btn.y && app.mouse_y <= btn.y + btn.h {
				app.arcade.hovered_btn = i
				break
			}
		}
	}

	app.arcade.update(dt, mut app.sound_mgr)
	app.sound_mgr.update()

	match app.arcade.screen {
		.menu {
			render_arcade_menu(&app.renderer, &app.arcade, win_w, win_h)
		}
		.gem_rush {
			render_gem_rush(&app.renderer, &app.arcade.gem_game, win_w, win_h)
		}
		.chain_reaction {
			render_chain_reaction(&app.renderer, &app.arcade.chain_game, win_w, win_h, app.mouse_x, app.mouse_y)
		}
		.whack_monster {
			render_whack_monster(&app.renderer, &app.arcade.whack_game, win_w, win_h, app.mouse_x, app.mouse_y)
		}
		.blade_slicer {
			render_blade_slicer(&app.renderer, &app.arcade.blade_game, win_w, win_h)
		}
	}

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
			if app.arcade.screen == .blade_slicer {
				app.arcade.blade_game.process_mouse_move(f64(e.mouse_x), f64(e.mouse_y), app.is_mouse_down, mut app.sound_mgr)
			}
		}
		.mouse_up {
			if e.mouse_button == .left {
				app.is_mouse_down = false
				if app.arcade.screen == .blade_slicer {
					app.arcade.blade_game.process_mouse_move(f64(e.mouse_x), f64(e.mouse_y), false, mut app.sound_mgr)
				}
			}
		}
		.mouse_down {
			if e.mouse_button == .left {
				app.is_mouse_down = true
				app.arcade.total_clicks++
				mx := f64(e.mouse_x)
				my := f64(e.mouse_y)

				match app.arcade.screen {
					.menu {
						if app.arcade.hovered_btn >= 0 {
							app.sound_mgr.play_upgrade_bought()
							match app.arcade.hovered_btn {
								0 { app.arcade.screen = .gem_rush }
								1 {
									app.arcade.chain_game.start_level(1)
									app.arcade.screen = .chain_reaction
								}
								2 {
									app.arcade.whack_game.reset()
									app.arcade.screen = .whack_monster
								}
								3 {
									app.arcade.blade_game.reset()
									app.arcade.screen = .blade_slicer
								}
								else {}
							}
						}
					}
					.gem_rush {
						// Check back button
						if mx >= 20.0 && mx <= 120.0 && my >= 10.0 && my <= 40.0 {
							app.arcade.screen = .menu
							app.sound_mgr.play_click_pop()
							return
						}

						// Check Golden Gem
						if app.arcade.gem_game.golden_gem.active {
							dx := mx - app.arcade.gem_game.golden_gem.x
							dy := my - app.arcade.gem_game.golden_gem.y
							if dx * dx + dy * dy <= 30.0 * 30.0 {
								app.arcade.gem_game.click_golden_gem(mut app.sound_mgr)
								return
							}
						}

						// Check Shop Buildings
						shop_x := 490.0
						shop_w := 365.0
						mut cur_y := 115.0
						mut clicked_shop := false

						for i in 0 .. app.arcade.gem_game.buildings.len {
							if mx >= shop_x && mx <= shop_x + shop_w && my >= cur_y && my <= cur_y + 56.0 {
								app.arcade.gem_game.buy_building(i, mut app.sound_mgr)
								clicked_shop = true
								break
							}
							cur_y += 62.0
						}

						// Check Ascension button
						if !clicked_shop && app.arcade.gem_game.can_ascend() {
							if mx >= shop_x && mx <= shop_x + shop_w && my >= cur_y + 10.0 && my <= cur_y + 52.0 {
								app.arcade.gem_game.ascend(mut app.sound_mgr)
								clicked_shop = true
							}
						}

						// Check Big Gem click
						if !clicked_shop {
							gem_cx := 240.0
							gem_cy := 290.0
							dx := mx - gem_cx
							dy := my - gem_cy
							rad := 110.0
							if dx * dx + dy * dy <= rad * rad {
								app.arcade.gem_game.click_gem(mx, my, mut app.sound_mgr)
							} else {
								if mx < 470.0 && my > 70.0 {
									app.arcade.gem_game.click_gem(gem_cx, gem_cy, mut app.sound_mgr)
								}
							}
						}
					}
					.chain_reaction {
						if mx >= 20.0 && mx <= 120.0 && my >= 10.0 && my <= 40.0 {
							app.arcade.screen = .menu
							app.sound_mgr.play_click_pop()
							return
						}

						if app.arcade.chain_game.state == 'cleared' {
							app.arcade.chain_game.start_level(app.arcade.chain_game.level + 1)
							app.sound_mgr.play_click_pop()
						} else if app.arcade.chain_game.state == 'failed' {
							app.arcade.chain_game.start_level(app.arcade.chain_game.level)
							app.sound_mgr.play_click_pop()
						} else if app.arcade.chain_game.state == 'ready' {
							app.arcade.chain_game.click_trigger(mx, my, mut app.sound_mgr)
						}
					}
					.whack_monster {
						if mx >= 20.0 && mx <= 120.0 && my >= 10.0 && my <= 40.0 {
							app.arcade.screen = .menu
							app.sound_mgr.play_click_pop()
							return
						}

						if app.arcade.whack_game.game_over {
							app.arcade.whack_game.reset()
							app.sound_mgr.play_click_pop()
						} else {
							app.arcade.whack_game.click_at(mx, my, mut app.sound_mgr)
						}
					}
					.blade_slicer {
						if mx >= 20.0 && mx <= 120.0 && my >= 10.0 && my <= 40.0 {
							app.arcade.screen = .menu
							app.sound_mgr.play_click_pop()
							return
						}

						if app.arcade.blade_game.game_over {
							app.arcade.blade_game.reset()
							app.sound_mgr.play_click_pop()
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
					if app.arcade.screen == .menu {
						exit(0)
					} else {
						app.arcade.screen = .menu
						app.sound_mgr.play_click_pop()
					}
				}
				.m {
					app.sound_mgr.toggle_music()
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
		window_title: 'Click Arcade - Addictive Mouse Mini Games'
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
