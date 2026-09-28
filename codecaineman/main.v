module main

import gg
import math
import time

struct App {
mut:
	ctx         &gg.Context = unsafe { nil }
	renderer    Renderer
	game        Game
	sound_mgr   SoundManager
	tex_mgr     PacmanTextureManager
	btn_reset   Button
	btn_sound   Button
	btn_pause   Button
	mouse_x     int
	mouse_y     int
	last_tick   i64
}

fn new_app() App {
	return App{
		game:      new_game()
		sound_mgr: new_sound_manager()
		tex_mgr:   new_pacman_texture_manager()
		btn_reset: Button{
			x:            735
			y:            160
			w:            200
			h:            44
			text:         'RESET [R]'
			bg_color:     Color{ r: 35, g: 45, b: 70, a: 255 }
			hover_color:  Color{ r: 55, g: 70, b: 105, a: 255 }
			text_color:   Color{ r: 255, g: 255, b: 255, a: 255 }
			border_color: Color{ r: 90, g: 120, b: 180, a: 255 }
		}
		btn_sound: Button{
			x:            735
			y:            220
			w:            200
			h:            44
			text:         'SOUND: ON [S]'
			bg_color:     Color{ r: 35, g: 45, b: 70, a: 255 }
			hover_color:  Color{ r: 55, g: 70, b: 105, a: 255 }
			text_color:   Color{ r: 255, g: 255, b: 255, a: 255 }
			border_color: Color{ r: 90, g: 120, b: 180, a: 255 }
		}
		btn_pause: Button{
			x:            735
			y:            280
			w:            200
			h:            44
			text:         'PAUSE [P]'
			bg_color:     Color{ r: 35, g: 45, b: 70, a: 255 }
			hover_color:  Color{ r: 55, g: 70, b: 105, a: 255 }
			text_color:   Color{ r: 255, g: 255, b: 255, a: 255 }
			border_color: Color{ r: 90, g: 120, b: 180, a: 255 }
		}
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

	game_ev := app.game.update(dt)
	if game_ev.ate_dot || (game_ev.is_moving && math.fmod(app.game.global_timer, 0.2) < dt) {
		app.sound_mgr.play_waka_sound()
	}
	if game_ev.ate_power { app.sound_mgr.play_power_pellet_sound() }
	if game_ev.ate_fruit { app.sound_mgr.play_eat_fruit_sound() }
	if game_ev.ate_ghost { app.sound_mgr.play_eat_ghost_sound() }
	if game_ev.pac_died { app.sound_mgr.play_death_sound() }
	if game_ev.level_win { app.sound_mgr.play_extra_life_sound() }

	app.sound_mgr.update()

	draw_game(&app.renderer, &app.game, app.mouse_x, app.mouse_y, &app.btn_reset, &app.btn_sound, &app.btn_pause, app.tex_mgr.sprite_texture)
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
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				if app.btn_reset.contains(mx, my) {
					app.game.init_level()
					app.game.score = 0
					app.game.lives = 3
					app.sound_mgr.play_intro_sound()
				} else if app.btn_sound.contains(mx, my) {
					is_on := app.sound_mgr.toggle_sound()
					app.btn_sound.text = if is_on { 'SOUND: ON [S]' } else { 'SOUND: OFF [S]' }
				} else if app.btn_pause.contains(mx, my) {
					if app.game.status == .playing { app.game.status = .paused }
					else if app.game.status == .paused { app.game.status = .playing }
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
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.m {
					app.sound_mgr.toggle_music()
				}
				.escape { exit(0) }
				.up, .w { app.game.pacman.next_dir = .up }
				.down, .s { app.game.pacman.next_dir = .down }
				.left, .a { app.game.pacman.next_dir = .left }
				.right, .d { app.game.pacman.next_dir = .right }
				.r {
					app.game.init_level()
					app.game.score = 0
					app.game.lives = 3
				}
				.p {
					if app.game.status == .playing { app.game.status = .paused }
					else if app.game.status == .paused { app.game.status = .playing }
				}
				.o {
					is_on := app.sound_mgr.toggle_sound()
					app.btn_sound.text = if is_on { 'SOUND: ON [S]' } else { 'SOUND: OFF [S]' }
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
		window_title: 'Codecaine Man (Arcade Maze Chomp)'
		user_data:    &app
		init_fn:      on_init
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 5, g: 5, b: 15, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
