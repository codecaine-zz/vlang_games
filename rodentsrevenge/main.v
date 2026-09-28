module main

import gg
import time

const win_w = 920
const win_h = 660

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      RodentGame
	sound_mgr SoundManager
	tex_mgr   TextureManager
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_rodent_game()
		sound_mgr: new_sound_manager()
		tex_mgr:   new_texture_manager()
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

	app.game.update(f64(dt))
	if app.game.sound_event != '' {
		match app.game.sound_event {
			'step' { app.sound_mgr.play_step() }
			'push' { app.sound_mgr.play_push() }
			'cheese' { app.sound_mgr.play_cheese_spawn() }
			'eat' { app.sound_mgr.play_eat() }
			'die' { app.sound_mgr.play_die() }
			'trap' { app.sound_mgr.play_trap() }
			'meow' { app.sound_mgr.play_meow() }
			'win' { app.sound_mgr.play_win() }
			else {}
		}
		app.game.sound_event = ''
	}
	app.sound_mgr.update()

	render_rodent_game(&app.renderer, mut app.game, win_w, win_h, app.sound_mgr.enabled, app.tex_mgr.sprite_texture)
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
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				sound_x := win_w - 135
				if mx >= sound_x && mx <= sound_x + 115 && my >= 10 && my <= 36 {
					app.sound_mgr.toggle_sound()
				}
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
				.escape { exit(0) }
				.left, .a { app.game.move_player(-1, 0) }
				.right, .d { app.game.move_player(1, 0) }
				.up, .w { app.game.move_player(0, -1) }
				.down, .s { app.game.move_player(0, 1) }
				.r { app.game.init_level(app.game.level) }
				.n { app.game.init_level(app.game.level + 1) }
				.m { app.sound_mgr.toggle_music() }
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
		window_title: "Rodent's Revenge Deluxe - Windows 1991 Classic Remaster"
		user_data:    &app
		init_fn:      on_init
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 10, g: 15, b: 25, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
