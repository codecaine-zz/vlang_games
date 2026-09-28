module main

import gg
import time

struct App {
mut:
	ctx        &gg.Context = unsafe { nil }
	renderer   Renderer
	game       GalagaGame
	last_tick  i64
}

fn new_app() App {
	return App{
		game:      new_galaga_game()
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

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.game.update(dt)
	app.game.sound_mgr.update()

	render_galaga_game(&app.renderer, mut app.game)
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
					app.game.sound_mgr.toggle_sfx()
				}
				.escape {
					exit(0)
				}
				.left, .a {
					app.game.key_left = true
				}
				.right, .d {
					app.game.key_right = true
				}
				.space {
					if app.game.state == .menu || app.game.state == .game_over {
						app.game.reset_game()
					} else {
						app.game.key_fire = true
					}
				}
				.p {
					if app.game.state == .playing {
						app.game.state = .paused
					} else if app.game.state == .paused {
						app.game.state = .playing
					}
				}
				.r {
					app.game.reset_game()
				}
				.m {
					app.game.sound_mgr.toggle_music()
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.n {
					app.game.sound_mgr.toggle_sfx()
				}
				.left, .a {
					app.game.key_left = false
				}
				.right, .d {
					app.game.key_right = false
				}
				.space {
					app.game.key_fire = false
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
		window_title: 'Galaga Space Shooter Arcade'
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
