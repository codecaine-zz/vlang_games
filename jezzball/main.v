module main

import gg
import time

const win_w = 880
const win_h = 600

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      JezzGame
	sound_mgr SoundManager
	mouse_x   int
	mouse_y   int
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_jezz_game()
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

	app.game.update(dt)
	app.sound_mgr.update()

	render_jezz_game(&app.renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y)
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
			app.mouse_x = int(e.mouse_x)
			app.mouse_y = int(e.mouse_y)
		}
		.mouse_down {
			if e.mouse_button == .left {
				if app.game.is_won {
					app.game.init_level(app.game.level + 1)
				} else if app.game.is_game_over {
					app.game.init_level(1)
					app.game.lives = 3
					app.game.score = 0
				} else {
					app.game.start_wall(app.mouse_x, app.mouse_y)
				}
			} else if e.mouse_button == .right {
				app.game.toggle_orientation()
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
				.escape {
					exit(0)
				}
				.space {
					if app.game.is_won {
						app.game.init_level(app.game.level + 1)
					} else if app.game.is_game_over {
						app.game.init_level(1)
						app.game.lives = 3
						app.game.score = 0
					} else {
						app.game.toggle_orientation()
					}
				}
				.n {
					if app.game.is_won {
						app.game.init_level(app.game.level + 1)
					}
				}
				.r {
					app.game.init_level(1)
					app.game.lives = 3
					app.game.score = 0
				}
				.m {
					app.sound_mgr.toggle_music()
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
		window_title: 'JezzBall (Windows Entertainment Pack Classic)'
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
