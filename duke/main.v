module main

import gg
import time

const win_w = 960
const win_h = 600

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      DukeGame
	sound_mgr SoundManager
	sparks    []SparkParticle
	key_left  bool
	key_right bool
	key_up    bool
	key_down  bool
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_duke_game()
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

	update_sparks(mut app.sparks, dt)

	move_dir := if app.key_right && !app.key_left { 1 } else if app.key_left && !app.key_right { -1 } else { 0 }
	climb_dir := if app.key_up && !app.key_down { -1 } else if app.key_down && !app.key_up { 1 } else { 0 }
	crouch := app.key_down
	aim_up := app.key_up

	ev := app.game.update(f64(dt), move_dir, climb_dir, crouch, aim_up)
	if ev.picked_item {
		app.sound_mgr.play_pickup_sound()
	}
	if ev.unlocked_door {
		app.sound_mgr.play_keycard_sound()
	}
	app.sound_mgr.update()

	render_duke_game(&app.renderer, &app.game, win_w, win_h, app.sparks)
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
				.a, .left {
					app.key_left = true
				}
				.d, .right {
					app.key_right = true
				}
				.w, .up {
					app.key_up = true
				}
				.s, .down {
					app.key_down = true
				}
				.space {
					if app.game.state == .sector_debrief {
						app.game.load_sector(app.game.level_num + 1)
					} else if app.game.state == .game_won || app.game.state == .game_over {
						app.game.reset_game()
					} else {
						if app.game.player_jump() {
							app.sound_mgr.play_jump_sound()
						}
					}
				}
				.f, .j, .left_control {
					if app.game.player_shoot() {
						match app.game.player.weapon {
							.blaster { app.sound_mgr.play_laser_sound() }
							.dual_laser { app.sound_mgr.play_dual_laser_sound() }
							.flamethrower { app.sound_mgr.play_flame_sound() }
							.missile { app.sound_mgr.play_rocket_sound() }
						}
					}
				}
				.r {
					app.game.reset_game()
				}
				.m {
					app.sound_mgr.toggle_music()
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.a, .left {
					app.key_left = false
				}
				.d, .right {
					app.key_right = false
				}
				.w, .up {
					app.key_up = false
				}
				.s, .down {
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
		width:        win_w
		height:       win_h
		resizable:     true
		window_title: 'Duke - 90s Platformer Classic'
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
