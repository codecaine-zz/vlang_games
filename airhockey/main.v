module main

import gg
import math
import time

const win_w = 940
const win_h = 660

struct App {
mut:
	ctx          &gg.Context = unsafe { nil }
	renderer     Renderer
	game         AirHockeyGame
	sound_mgr    SoundManager
	tex_mgr      AirHockeyTextureManager
	p1_target_x  f64
	p1_target_y  f64
	p2_target_x  f64
	p2_target_y  f64
	p1_up        bool
	p1_down      bool
	p1_left      bool
	p1_right     bool
	p2_up        bool
	p2_down      bool
	p2_left      bool
	p2_right     bool
	use_mouse_p1 bool = true
	last_tick    i64
}

fn new_app() App {
	return App{
		game:      new_airhockey_game(false)
		sound_mgr: new_sound_manager()
		last_tick: time.ticks()
	}
}

fn on_init(data voidptr) {
	mut app := unsafe { &App(data) }
	app.tex_mgr.init(&app.renderer)
	app.p1_target_x = app.game.p1_mallet.x
	app.p1_target_y = app.game.p1_mallet.y
	app.p2_target_x = app.game.p2_mallet.x
	app.p2_target_y = app.game.p2_mallet.y
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	dt := math.min(f64(now - app.last_tick) / 1000.0, 0.05)
	app.last_tick = now

	// Process keyboard movement deltas
	kbd_speed := 600.0 * dt
	if !app.use_mouse_p1 {
		if app.p1_up { app.p1_target_y -= kbd_speed }
		if app.p1_down { app.p1_target_y += kbd_speed }
		if app.p1_left { app.p1_target_x -= kbd_speed }
		if app.p1_right { app.p1_target_x += kbd_speed }
	}

	if app.game.is_two_player {
		if app.p2_up { app.p2_target_y -= kbd_speed }
		if app.p2_down { app.p2_target_y += kbd_speed }
		if app.p2_left { app.p2_target_x -= kbd_speed }
		if app.p2_right { app.p2_target_x += kbd_speed }
	}

	app.game.update(dt, app.p1_target_x, app.p1_target_y, app.p2_target_x, app.p2_target_y)

	// Play sound events
	if app.game.sound_event != '' {
		ev := app.game.sound_event
		speed := app.game.sound_speed
		app.game.sound_event = ''
		match ev {
			'hit' { app.sound_mgr.play_mallet_hit(speed) }
			'rail' { app.sound_mgr.play_rail_bounce(speed) }
			'goal' { app.sound_mgr.play_goal_horn() }
			'victory' { app.sound_mgr.play_victory() }
			else {}
		}
	}

	app.sound_mgr.update()
	app.sound_mgr.update_bgm(app.game.state != .game_over)

	render_airhockey_game(&app.renderer, mut app.game, win_w, win_h, app.tex_mgr.sprite_texture)

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
			if app.use_mouse_p1 {
				app.p1_target_x = f64(e.mouse_x)
				app.p1_target_y = f64(e.mouse_y)
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
				.r, .space {
					if app.game.state == .game_over {
						app.game.reset_game()
					} else if e.key_code == .r {
						app.game.reset_game()
					}
				}
				.m {
					app.game.is_two_player = !app.game.is_two_player
					app.game.reset_game()
				}
				.tab {
					app.game.difficulty = match app.game.difficulty {
						.easy { AIDifficulty.medium }
						.medium { AIDifficulty.hard }
						.hard { AIDifficulty.easy }
					}
				}
				.v, .o {
					app.sound_mgr.toggle_sound()
				}
				.w {
					app.p1_up = true
					app.use_mouse_p1 = false
				}
				.s {
					app.p1_down = true
					app.use_mouse_p1 = false
				}
				.a {
					app.p1_left = true
					app.use_mouse_p1 = false
				}
				.d {
					app.p1_right = true
					app.use_mouse_p1 = false
				}
				.up, .i { app.p2_up = true }
				.down, .k { app.p2_down = true }
				.left, .j { app.p2_left = true }
				.right, .l { app.p2_right = true }
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.w { app.p1_up = false }
				.s { app.p1_down = false }
				.a { app.p1_left = false }
				.d { app.p1_right = false }
				.up, .i { app.p2_up = false }
				.down, .k { app.p2_down = false }
				.left, .j { app.p2_left = false }
				.right, .l { app.p2_right = false }
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
		window_title: 'Hyper Air Hockey - 2D Physics Arcade Table'
		user_data:    &app
		init_fn:      on_init
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
