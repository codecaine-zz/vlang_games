module main

import gg
import time

const win_w = 720
const win_h = 600

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      PuyoGame
	sound_mgr SoundManager
	tex_mgr   PuyoTextureManager
	particles []PuyoParticle
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_puyo_game()
		sound_mgr: new_sound_manager()
		tex_mgr:   new_puyo_texture_manager()
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

	update_puyo_particles(mut app.particles, f64(dt))
	app.sound_mgr.update_bgm(app.game.state != .game_over)
	app.sound_mgr.update()

	res := app.game.update(f64(dt))
	if res.popped {
		app.sound_mgr.play_chain_pop_sound(res.chain_level)
	}

	render_puyo_game(&app.renderer, &app.game, win_w, win_h, app.particles, app.tex_mgr.sprite_texture)
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
				.r { app.game.reset_game() }
				.m { app.sound_mgr.toggle_music() }
				.left, .a {
					if app.game.move_horiz(-1) { app.sound_mgr.play_move_sound() }
				}
				.right, .d {
					if app.game.move_horiz(1) { app.sound_mgr.play_move_sound() }
				}
				.w, .up, .z {
					if app.game.rotate(1) { app.sound_mgr.play_rotate_sound() }
				}
				.x {
					if app.game.rotate(-1) { app.sound_mgr.play_rotate_sound() }
				}
				.s, .down { app.game.fall_speed = 0.08 }
				.space {
					if app.game.state == .game_over {
						app.game.reset_game()
					} else {
						app.game.drop_instant()
						app.sound_mgr.play_drop_sound()
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
				.s, .down { app.game.fall_speed = 0.65 }
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
		window_title: 'Puyo Puyo - Tsu Arcade Classic'
		user_data:    &app
		init_fn:      on_init
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 15, g: 15, b: 25, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
