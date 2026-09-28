module main

import gg
import time

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      MarioBrosGame
	tex_mgr   MarioBrosTextureManager
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_mario_bros_game()
		sound_mgr: new_sound_manager()
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
	app.sound_mgr.update()

	render_mario_bros_game(&app.renderer, mut app.game, app.tex_mgr.sprite_texture)
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
				.a, .left { app.game.p1_left = true }
				.d, .right { app.game.p1_right = true }
				.s, .down { app.game.p1_down = true }
				.f, .x { app.game.p1_fire = true }
				.w, .space {
					if app.game.state == .title {
						app.game.start_game(app.game.mode)
					} else if app.game.state == .phase_clear {
						app.game.next_phase()
					} else if app.game.state == .game_over {
						app.game.reset_to_title()
					} else {
						app.game.p1_jump = true
					}
				}
				.m { app.sound_mgr.toggle_music() }
				.r { app.game.reset_to_title() }
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.a, .left { app.game.p1_left = false }
				.d, .right { app.game.p1_right = false }
				.s, .down { app.game.p1_down = false }
				.f, .x { app.game.p1_fire = false }
				.w, .space { app.game.p1_jump = false }
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
		window_title: 'Codecaine Bros. (Arcade Sewer Platformer)'
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
