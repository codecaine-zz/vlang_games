module main

import gg
import time

const win_w = 840
const win_h = 480

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      WorldRunnerGame
	sound_mgr SoundManager
	tex_mgr   WorldRunnerTextureManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_worldrunner_game()
		sound_mgr: new_sound_manager()
		tex_mgr:   WorldRunnerTextureManager{}
		last_tick: time.ticks()
	}
}

fn (mut app App) handle_sound_events() {
	if app.game.sound_laser {
		app.sound_mgr.play_laser()
		app.game.sound_laser = false
	}
	if app.game.sound_jump {
		app.sound_mgr.play_jump()
		app.game.sound_jump = false
	}
	if app.game.sound_boost {
		app.sound_mgr.play_boost()
		app.game.sound_boost = false
	}
	if app.game.sound_explosion {
		app.sound_mgr.play_explosion()
		app.game.sound_explosion = false
	}
	if app.game.sound_powerup {
		app.sound_mgr.play_powerup()
		app.game.sound_powerup = false
	}
	if app.game.sound_dragon {
		app.sound_mgr.play_dragon_roar()
		app.game.sound_dragon = false
	}
	if app.game.sound_victory {
		app.sound_mgr.play_victory()
		app.game.sound_victory = false
	}
	if app.game.sound_crash {
		app.sound_mgr.play_crash()
		app.game.sound_crash = false
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	clamped_dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.game.update(clamped_dt)
	app.handle_sound_events()
	app.sound_mgr.update_bgm(app.game.state == .playing)

	render_game(&app.renderer, &app.game, win_w, win_h, app.tex_mgr.sprite_texture)
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
		.mouse_down {
			if app.game.state == .title {
				app.game.start_game(1)
			} else if app.game.state == .playing {
				app.game.input_fire = true
			} else if app.game.state == .game_over || app.game.state == .victory {
				app.game.init_title()
			}
		}
		.mouse_up {
			app.game.input_fire = false
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
					if app.game.state == .title {
						exit(0)
					} else {
						app.game.init_title()
					}
				}
				.space, .enter {
					match app.game.state {
						.title {
							app.game.start_game(1)
						}
						.world_intro {
							app.game.state = .playing
						}
						.game_over, .victory {
							app.game.init_title()
						}
						.playing {
							app.game.input_jump = true
						}
						else {}
					}
				}
				.left, .a {
					app.game.input_left = true
				}
				.right, .d {
					app.game.input_right = true
				}
				.up, .w, .left_shift, .right_shift {
					app.game.input_boost = true
				}
				.down, .s {
					app.game.input_down = true
				}
				.j, .z {
					app.game.input_fire = true
				}
				.k, .x {
					app.game.input_jump = true
				}
				.p {
					if app.game.state == .playing {
						app.game.state = .paused
					} else if app.game.state == .paused {
						app.game.state = .playing
					}
				}
				.r {
					app.game.start_game(app.game.current_world)
				}
				.m {
					app.sound_mgr.toggle_music()
				}
				._1 {
					app.game.start_game(1)
				}
				._2 {
					app.game.start_game(2)
				}
				._3 {
					app.game.start_game(3)
				}
				._4 {
					app.game.start_game(4)
				}
				._5 {
					app.game.start_game(5)
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
					app.game.input_left = false
				}
				.right, .d {
					app.game.input_right = false
				}
				.up, .w, .left_shift, .right_shift {
					app.game.input_boost = false
				}
				.down, .s {
					app.game.input_down = false
				}
				.j, .z {
					app.game.input_fire = false
				}
				.k, .x, .space {
					app.game.input_jump = false
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
		width:         win_w
		height:        win_h
		resizable:     true
		window_title:  '3D WorldRunner - Cosmic Harrier 3D'
		user_data:     &app
		frame_fn:      on_frame
		event_fn:      on_event
		bg_color:      gg.Color{r: 0, g: 0, b: 0, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx: ctx
	}
	app.tex_mgr.init(&app.renderer)
	ctx.run()
}
