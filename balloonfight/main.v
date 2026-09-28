module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      GameEngine
	sound_mgr SoundManager
	p1_left   bool
	p1_right  bool
	p1_flap   bool
	p2_left   bool
	p2_right  bool
	p2_flap   bool
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_game_engine()
		sound_mgr: new_sound_manager()
		last_tick: time.ticks()
	}
}

fn on_init(data voidptr) {
	mut app := unsafe { &App(data) }
	app.game.init_textures(&app.renderer)
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	target_dt := 1.0 / 60.0

	// Update game logic
	app.game.update(target_dt, app.p1_left, app.p1_right,
		app.p1_flap, app.p2_left, app.p2_right, app.p2_flap,
		&app.sound_mgr)
	app.sound_mgr.update()
	app.sound_mgr.update_bgm(app.game.state != .game_over)

	// Render frame
	draw_game(&app.renderer, &app.game)
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
			ws := app.ctx.window_size()
			if prod_fx_handle_mouse(int(e.mouse_x), int(e.mouse_y), ws.width, ws.height) {
				return
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
				.left, .a {
					app.p1_left = true
				}
				.right, .d {
					app.p1_right = true
				}
				.up, .w, .space {
					app.p1_flap = true
					if app.game.state == .phase_clear {
						app.game.state = .playing
						app.game.setup_stage()
					} else if app.game.state == .title {
						app.game.start_game(.mode_a_1p)
					} else if app.game.state == .game_over {
						app.game.start_game(.mode_a_1p)
					}
				}
				.j {
					app.p2_left = true
				}
				.l {
					app.p2_right = true
				}
				.i, .o {
					app.p2_flap = true
				}
				._1 {
					app.game.start_game(.mode_a_1p)
				}
				._2 {
					app.game.start_game(.mode_b_2p)
				}
				._3 {
					app.game.start_game(.balloon_trip)
				}
				.p {
					if app.game.state == .playing {
						app.game.state = .paused
					} else if app.game.state == .paused {
						app.game.state = .playing
					}
				}
				.r {
					app.game.start_game(app.game.mode)
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
				.left, .a {
					app.p1_left = false
				}
				.right, .d {
					app.p1_right = false
				}
				.up, .w, .space {
					app.p1_flap = false
				}
				.j {
					app.p2_left = false
				}
				.l {
					app.p2_right = false
				}
				.i, .o {
					app.p2_flap = false
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
		window_title: 'NES Balloon Fight - 1984 Arcade Recreation'
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
