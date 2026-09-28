module main

import gg
import time

struct App {
mut:
	ctx        &gg.Context = unsafe { nil }
	renderer   Renderer
	game       GameEngine
	sound_mgr  SoundManager
	tex_mgr    SidescrollerTextureManager
	key_left   bool
	key_right  bool
	key_up     bool
	key_down   bool
	key_jump   bool
	key_fire   bool
	key_dash   bool
	last_tick  i64
}

fn new_app() App {
	return App{
		game:      new_game_engine()
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

	app.game.update(f64(dt), app.key_left, app.key_right, app.key_up, app.key_down, app.key_jump, app.key_fire, app.key_dash, &app.sound_mgr)
	app.sound_mgr.update_bgm(app.game.state == .playing)

	draw_game(&app.renderer, &app.game, app.tex_mgr.sprite_texture)
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
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.escape {
					exit(0)
				}
				.left, .a { app.key_left = true }
				.right, .d { app.key_right = true }
				.up, .w {
					app.key_up = true
					app.key_jump = true
				}
				.down, .s { app.key_down = true }
				.space {
					app.key_jump = true
					if app.game.state == .title || app.game.state == .game_over || app.game.state == .victory {
						app.game.start_game()
					} else if app.game.state == .stage_clear {
						app.game.state = .playing
					}
				}
				.j, .z { app.key_fire = true }
				.k, .left_shift, .right_shift { app.key_dash = true }
				.b { app.game.trigger_emp_bomb(&app.sound_mgr) }
				.q { app.game.switch_weapon(false) }
				.e { app.game.switch_weapon(true) }
				._1 { app.game.set_weapon_by_idx(0) }
				._2 { app.game.set_weapon_by_idx(1) }
				._3 { app.game.set_weapon_by_idx(2) }
				._4 { app.game.set_weapon_by_idx(3) }
				._5 { app.game.set_weapon_by_idx(4) }
				._6 { app.game.set_weapon_by_idx(5) }
				._7 { app.game.set_weapon_by_idx(6) }
				._8 { app.game.set_weapon_by_idx(7) }
				.p {
					if app.game.state == .playing {
						app.game.state = .paused
					} else if app.game.state == .paused {
						app.game.state = .playing
					}
				}
				.m { app.sound_mgr.toggle_music() }
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
				.up, .w {
					app.key_up = false
					app.key_jump = false
				}
				.down, .s { app.key_down = false }
				.space { app.key_jump = false }
				.j, .z { app.key_fire = false }
				.k, .left_shift, .right_shift { app.key_dash = false }
				else {}
			}
		}
		else {}
	}
}

fn main() {
	mut app := new_app()
	mut ctx := gg.new_context(
		width: 960
		height: 540
		resizable:     true
		window_title: 'Cyberpunk Vanguard - Advanced 2D Side-Scroller'
		user_data: &app
		frame_fn: on_frame
		event_fn: on_event
		bg_color: gg.Color{10, 12, 20, 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{ctx: ctx}
	app.tex_mgr.init(&app.renderer)
	ctx.run()
}
