module main

import gg
import time

const win_w = 600
const win_h = 700

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      Game2048
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_game_2048()
		sound_mgr: new_sound_manager()
		last_tick: time.ticks()
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	app.last_tick = time.ticks()


	app.sound_mgr.update()

	render_game_2048(&app.renderer, &app.game, win_w, win_h, []MergeParticle{})
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn (mut app App) handle_slide(dir Direction) {
	moved, pts, _ := app.game.slide(dir)
	if moved {
		if pts > 0 {
			app.sound_mgr.play_merge_sound(pts)
		} else {
			app.sound_mgr.play_slide_sound()
		}
	}
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
				.f5 {
					app.game.save_state()
				}
				.f9 {
					app.game.load_state()
				}
				.r {
					app.game.reset()
				}
				.u {
					app.game.undo()
				}
				.s, .m {
					app.sound_mgr.toggle_music()
				}
				.left, .a {
					app.handle_slide(.left)
				}
				.right, .d {
					app.handle_slide(.right)
				}
				.up, .w {
					app.handle_slide(.up)
				}
				.down {
					app.handle_slide(.down)
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
		window_title: '2048 - Classic Sliding Tile Puzzle'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 250, g: 248, b: 239, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
