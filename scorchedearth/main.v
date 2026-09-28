module main

import gg
import math
import time

const win_w = 920
const win_h = 640

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      ScorchedGame
	sound_mgr SoundManager
	key_left  bool
	key_right bool
	key_up    bool
	key_down  bool
	mouse_x   int
	mouse_y   int
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_scorched_game()
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

	if !app.game.in_shop && !app.game.is_game_over {
		if app.game.current_turn < app.game.tanks.len {
			mut cur_t := app.game.tanks[app.game.current_turn]
			if !cur_t.is_ai && !cur_t.is_dead && app.game.projectiles.len == 0 {
				if app.key_left {
					cur_t.angle = math.min(180.0, cur_t.angle + 35.0 * f64(dt))
				}
				if app.key_right {
					cur_t.angle = math.max(0.0, cur_t.angle - 35.0 * f64(dt))
				}
				if app.key_up {
					cur_t.power = math.min(1000.0, cur_t.power + 250.0 * f64(dt))
				}
				if app.key_down {
					cur_t.power = math.max(50.0, cur_t.power - 250.0 * f64(dt))
				}
				app.game.tanks[app.game.current_turn] = cur_t
			}
		}
	}

	app.game.update(f64(dt))
	app.sound_mgr.update()

	render_scorched_game(&app.renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y, app.sound_mgr.enabled)
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
				sound_x := win_w - 110
				if mx >= sound_x && mx <= sound_x + 95 && my >= 8 && my <= 32 {
					app.sound_mgr.toggle_sound()
				} else if app.game.in_shop {
					weps := [
						WeaponType.baby_nuke,
						WeaponType.mirv,
						WeaponType.mountain_mover,
						WeaponType.napalm,
						WeaponType.digger,
					]
					mut row_y := 160
					for w in weps {
						if mx >= 110 && mx <= win_w - 110 && my >= row_y && my <= row_y + 48 {
							app.game.buy_weapon(w)
							break
						}
						row_y += 58
					}
					if my >= win_h - 120 && my <= win_h - 70 && mx >= win_w / 2 - 200 && mx <= win_w / 2 + 200 {
						app.game.start_next_round()
					}
				} else if !app.game.is_game_over {
					if my >= win_h - 55 {
						if mx >= win_w - 220 {
							app.game.fire_shot()
						} else if mx >= 330 && mx <= win_w - 230 {
							app.game.cycle_weapon(true)
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
				.escape { exit(0) }
				.left, .a { app.key_left = true }
				.right, .d { app.key_right = true }
				.up, .w { app.key_up = true }
				.down, .s { app.key_down = true }
				.space, .enter {
					if app.game.in_shop {
						app.game.start_next_round()
					} else {
						app.game.fire_shot()
					}
				}
				.tab { app.game.cycle_weapon(true) }
				._1 {
					if app.game.in_shop { app.game.buy_weapon(.baby_nuke) }
					else { app.game.select_weapon(.standard) }
				}
				._2 {
					if app.game.in_shop { app.game.buy_weapon(.mirv) }
					else { app.game.select_weapon(.baby_nuke) }
				}
				._3 {
					if app.game.in_shop { app.game.buy_weapon(.mountain_mover) }
					else { app.game.select_weapon(.mirv) }
				}
				._4 {
					if app.game.in_shop { app.game.buy_weapon(.napalm) }
					else { app.game.select_weapon(.mountain_mover) }
				}
				._5 {
					if app.game.in_shop { app.game.buy_weapon(.digger) }
					else { app.game.select_weapon(.napalm) }
				}
				.m { app.sound_mgr.toggle_music() }
				.r { app.game.init_match() }
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.left, .a { app.key_left = false }
				.right, .d { app.key_right = false }
				.up, .w { app.key_up = false }
				.down, .s { app.key_down = false }
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
		window_title: 'Scorched Earth 1991 - The Mother of All Games'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 5, g: 10, b: 20, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
