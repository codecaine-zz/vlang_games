module main

import gg
import time

struct App {
mut:
	ctx         &gg.Context = unsafe { nil }
	renderer    Renderer
	game        CentipedeGame
	sound_mgr   SoundManager
	mouse_x     int
	mouse_y     int
	key_left    bool
	key_right   bool
	key_up      bool
	key_down    bool
	key_fire    bool
	btn_restart Button
	btn_sound   Button
	btn_pause   Button
	last_tick   i64
}

fn new_app() App {
	return App{
		game:      new_centipede_game()
		sound_mgr: new_sound_manager()
		btn_restart: Button{
			x:            50
			y:            640
			w:            170
			h:            34
			text:         'RESTART [R]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 60, b: 90}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 70, g: 90, b: 140}
		}
		btn_sound: Button{
			x:            580
			y:            640
			w:            170
			h:            34
			text:         'SOUND: ON [O]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 60, b: 90}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 70, g: 90, b: 140}
		}
		btn_pause: Button{
			x:            315
			y:            640
			w:            170
			h:            34
			text:         'PAUSE [P]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 60, b: 90}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 70, g: 90, b: 140}
		}
		last_tick: time.ticks()
	}
}

fn (mut app App) reset_game() {
	app.sound_mgr.clear_audio()
	app.game.reset()
}

fn on_init(data voidptr) {
	mut app := unsafe { &App(data) }
	app.game.init_textures(&app.renderer)
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f64(now - app.last_tick) / 1000.0
	app.last_tick = now
	clamped_dt := if raw_dt > 0.05 { 0.05 } else { raw_dt }

	// Handle continuous keyboard input
	mut dx := 0.0
	mut dy := 0.0
	if app.key_left { dx -= 1.0 }
	if app.key_right { dx += 1.0 }
	if app.key_up { dy -= 1.0 }
	if app.key_down { dy += 1.0 }

	if dx != 0.0 || dy != 0.0 {
		app.game.move_player(dx, dy, clamped_dt)
	}

	if app.key_fire {
		app.game.player_fire(&app.sound_mgr)
	}

	app.game.update(clamped_dt, &app.sound_mgr)
	app.sound_mgr.update()
	app.sound_mgr.update_bgm(!app.game.game_over && !app.game.paused)

	render_game(&app.renderer, &app.game, app.mouse_x, app.mouse_y, app.btn_restart, app.btn_sound, app.btn_pause)
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
				if app.btn_restart.contains(mx, my) {
					app.reset_game()
				} else if app.btn_sound.contains(mx, my) {
					enabled := app.sound_mgr.toggle_sound()
					app.btn_sound.text = if enabled { 'SOUND: ON [O]' } else { 'SOUND: OFF [O]' }
				} else if app.btn_pause.contains(mx, my) {
					app.game.paused = !app.game.paused
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
				.escape {
					exit(0)
				}
				.a, .left {
					app.key_left = true
				}
				.d, .right {
					app.key_right = true
				}
				.w, .up {
					app.key_up = true
				}
				.s, .down {
					app.key_down = true
				}
				.space, .j {
					app.key_fire = true
				}
				.r {
					app.reset_game()
				}
				.p {
					app.game.paused = !app.game.paused
				}
				.o {
					enabled := app.sound_mgr.toggle_sound()
					app.btn_sound.text = if enabled { 'SOUND: ON [O]' } else { 'SOUND: OFF [O]' }
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.m {
					app.sound_mgr.toggle_music()
				}
				.a, .left {
					app.key_left = false
				}
				.d, .right {
					app.key_right = false
				}
				.w, .up {
					app.key_up = false
				}
				.s, .down {
					app.key_down = false
				}
				.space, .j {
					app.key_fire = false
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
		height:       680
		resizable:     true
		window_title: 'Cyber Centipede Pro - Advanced Atari Centipede Classic'
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
		height: 680
	}
	ctx.run()
}
