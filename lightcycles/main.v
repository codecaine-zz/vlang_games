module main

import gg
import time

const win_w = 920
const win_h = 700

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      LightCyclesGame
	sound_mgr SoundManager
	particles []CrashParticle
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_lightcycles_game()
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

	update_crash_particles(mut app.particles, dt)

	ev := app.game.update(dt)
	if ev.crashed {
		app.sound_mgr.play_crash_sound()
		col := if app.game.round_winner == 1 { Color{r: 255, g: 110, b: 30, a: 255} } else { Color{r: 30, g: 220, b: 255, a: 255} }
		app.particles << create_crash_particles(f64(win_w / 2), f64(win_h / 2), col)
	}
	if ev.round_ended && app.game.state == .match_over {
		app.sound_mgr.play_win_sound()
	}

	app.sound_mgr.update()

	render_lightcycles_arena(&app.renderer, &app.game, win_w, win_h, app.particles)
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
				.escape { exit(0) }
				.r { app.game.reset_match() }
				.m {
					app.game.mode = if app.game.mode == .pve { GameMode.pvp } else { GameMode.pve }
					app.game.reset_match()
				}
				.d {
					app.game.diff = match app.game.diff {
						.easy { Difficulty.normal }
						.normal { Difficulty.master }
						.master { Difficulty.easy }
					}
				}
				.s { app.sound_mgr.toggle_sound() }
				.space {
					if app.game.state == .round_over {
						app.game.reset_round()
					} else if app.game.state == .match_over {
						app.game.reset_match()
					} else {
						app.game.p1.is_boosting = true
						app.sound_mgr.play_boost_sound()
					}
				}
				.w, .up {
					if app.game.set_p1_dir(.up) { app.sound_mgr.play_turn_sound() }
				}
				.down {
					if app.game.set_p1_dir(.down) { app.sound_mgr.play_turn_sound() }
				}
				.a, .left {
					if app.game.set_p1_dir(.left) { app.sound_mgr.play_turn_sound() }
				}
				.right {
					if app.game.set_p1_dir(.right) { app.sound_mgr.play_turn_sound() }
				}
				.i {
					if app.game.mode == .pvp {
						if app.game.set_p2_dir(.up) { app.sound_mgr.play_turn_sound() }
					}
				}
				.k {
					if app.game.mode == .pvp {
						if app.game.set_p2_dir(.down) { app.sound_mgr.play_turn_sound() }
					}
				}
				.j {
					if app.game.mode == .pvp {
						if app.game.set_p2_dir(.left) { app.sound_mgr.play_turn_sound() }
					}
				}
				.l {
					if app.game.mode == .pvp {
						if app.game.set_p2_dir(.right) { app.sound_mgr.play_turn_sound() }
					}
				}
				.right_shift {
					if app.game.mode == .pvp {
						app.game.p2.is_boosting = true
						app.sound_mgr.play_boost_sound()
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
				.space { app.game.p1.is_boosting = false }
				.right_shift { app.game.p2.is_boosting = false }
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
		window_title: 'Light Cycles - Retro Cyber Arena'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 5, g: 8, b: 15, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
