module main

import gg
import math
import time

struct App {
mut:
	ctx       &gg.Context         = unsafe { nil }
	renderer  Renderer
	game      DartsGame
	sound_mgr SoundManager
	tex_mgr   DartsTextureManager
	key_left  bool
	key_right bool
	key_up    bool
	key_down  bool
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_darts_game()
		sound_mgr: new_sound_manager()
		tex_mgr:   new_darts_texture_manager()
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
	raw_dt := f64(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := math.min(0.033, if raw_dt > 0.001 { raw_dt } else { 1.0 / 60.0 })

	if app.game.phase == .aiming && !app.game.players[app.game.current_p_idx].is_ai {
		speed := 180.0 * dt
		if app.key_left { app.game.aim_x -= speed }
		if app.key_right { app.game.aim_x += speed }
		if app.key_up { app.game.aim_y -= speed }
		if app.key_down { app.game.aim_y += speed }
		app.game.aim_x = math.max(45.0, math.min(485.0, app.game.aim_x))
		app.game.aim_y = math.max(80.0, math.min(520.0, app.game.aim_y))
	}

	app.game.update(dt, mut app.sound_mgr)
	app.sound_mgr.update()
	app.sound_mgr.update_bgm(true)

	draw_darts_game(&app.renderer, &app.game, app.tex_mgr.sprite_texture)
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
			if app.game.phase == .aiming && !app.game.players[app.game.current_p_idx].is_ai {
				app.game.aim_x = math.max(45.0, math.min(485.0, f64(e.mouse_x)))
				app.game.aim_y = math.max(80.0, math.min(520.0, f64(e.mouse_y)))
			}
		}
		.mouse_down {
			if e.mouse_button == .left {
				if app.game.phase == .aiming {
					app.game.phase = .power_meter
					app.game.power = 0.5
				} else if app.game.phase == .power_meter {
					app.game.throw_dart(mut app.sound_mgr)
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
					exit(0)
				}
				.r {
					app.game.reset_leg()
				}
				.m {
					app.sound_mgr.toggle_music()
				}
				._1 {
					app.game.set_game_type(.x501, false, false)
				}
				._2 {
					app.game.set_game_type(.x301, false, false)
				}
				._3 {
					app.game.set_game_type(.cricket, false, false)
				}
				._4 {
					app.game.set_game_type(.around_clock, false, false)
				}
				.p {
					app.game.set_game_type(app.game.typ, true, false)
				}
				.c {
					app.game.set_game_type(app.game.typ, false, true)
				}
				.tab {
					app.game.ai_diff = (app.game.ai_diff + 1) % 3
				}
				.left, .a {
					app.key_left = true
				}
				.right, .d {
					app.key_right = true
				}
				.up, .w {
					app.key_up = true
				}
				.down, .s {
					app.key_down = true
				}
				.space {
					if app.game.phase == .aiming {
						app.game.phase = .power_meter
						app.game.power = 0.5
					} else if app.game.phase == .power_meter {
						app.game.throw_dart(mut app.sound_mgr)
					}
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.left, .a {
					app.key_left = false
				}
				.right, .d {
					app.key_right = false
				}
				.up, .w {
					app.key_up = false
				}
				.down, .s {
					app.key_down = false
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
		width:        800
		height:       600
		resizable:     true
		window_title: 'Darts Masters - 501 / 301 / Cricket Championship'
		user_data:    &app
		init_fn:      on_init
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 0, g: 0, b: 0, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  800
		height: 600
	}
	ctx.run()
}
