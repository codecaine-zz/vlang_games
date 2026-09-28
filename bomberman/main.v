module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      BombermanGame
	tex_mgr   BombermanTextureManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_bomberman_game()
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
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.game.update(dt)
	app.game.sound_mgr.update()

	render_bomberman_game(&app.renderer, mut app.game, app.tex_mgr.sprite_texture)
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
				.a {
					app.game.key_p1_left = true
				}
				.d {
					app.game.key_p1_right = true
				}
				.w {
					app.game.key_p1_up = true
				}
				.s {
					app.game.key_p1_down = true
				}
				.space {
					if app.game.state == .menu || app.game.state == .game_over || app.game.state == .victory {
						app.game.reset_game()
					} else {
						app.game.key_p1_bomb = true
					}
				}
				.left {
					app.game.key_p2_left = true
				}
				.right {
					app.game.key_p2_right = true
				}
				.up {
					app.game.key_p2_up = true
				}
				.down {
					app.game.key_p2_down = true
				}
				.enter {
					app.game.key_p2_bomb = true
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
				.a {
					app.game.key_p1_left = false
				}
				.d {
					app.game.key_p1_right = false
				}
				.w {
					app.game.key_p1_up = false
				}
				.s {
					app.game.key_p1_down = false
				}
				.left {
					app.game.key_p2_left = false
				}
				.right {
					app.game.key_p2_right = false
				}
				.up {
					app.game.key_p2_up = false
				}
				.down {
					app.game.key_p2_down = false
				}
				.space {
					app.game.key_p1_bomb = false
				}
				.enter {
					app.game.key_p2_bomb = false
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
		window_title: 'Cyber Bomberman Tactical Maze'
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
