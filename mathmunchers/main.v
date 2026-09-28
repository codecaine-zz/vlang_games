module main

import gg
import time

struct App {
mut:
	ctx         &gg.Context = unsafe { nil }
	renderer    Renderer
	game        MathMunchersGame
	sound_mgr   SoundManager
	btn_restart Button
	btn_sound   Button
	btn_pause   Button
	btn_menu    Button
	mouse_x     int
	mouse_y     int
	last_tick   i64
}

fn new_app() App {
	return App{
		game:        new_mathmunchers_game()
		sound_mgr:   new_sound_manager()
		btn_restart: Button{ x: 10, y: 550, w: 110, h: 40, text: 'RESET [R]' }
		btn_sound:   Button{ x: 130, y: 550, w: 120, h: 40, text: 'SOUND: ON [O]' }
		btn_pause:   Button{ x: 260, y: 550, w: 100, h: 40, text: 'PAUSE [P]' }
		btn_menu:    Button{ x: 370, y: 550, w: 100, h: 40, text: 'MENU [M]' }
		last_tick:   time.ticks()
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.game.update(f64(dt), mut app.sound_mgr)
	app.sound_mgr.update()

	render_mathmunchers_game(&app.renderer, &app.game)
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
					app.game.start_new_game()
				} else if app.btn_sound.contains(mx, my) {
					muted := !app.sound_mgr.toggle_sound()
					app.btn_sound.text = if muted { 'SOUND: OFF [O]' } else { 'SOUND: ON [O]' }
				} else if app.btn_pause.contains(mx, my) {
					if app.game.state == .playing { app.game.state = .paused }
					else if app.game.state == .paused { app.game.state = .playing }
				} else if app.btn_menu.contains(mx, my) {
					app.game.state = .start_menu
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
				.escape { exit(0) }
				.m {
					app.game.state = .start_menu
					app.sound_mgr.play_sound('move')
				}
				.d {
					app.game.cycle_difficulty()
					app.sound_mgr.play_sound('move')
				}
				.a, .left {
					if app.game.state == .playing && app.game.player.grid_x > 0 {
						app.game.player.grid_x--
						app.game.player.facing_right = false
						app.sound_mgr.play_sound('move')
					}
				}
				.right {
					if app.game.state == .playing && app.game.player.grid_x < grid_cols - 1 {
						app.game.player.grid_x++
						app.game.player.facing_right = true
						app.sound_mgr.play_sound('move')
					}
				}
				.w, .up {
					if app.game.state == .playing && app.game.player.grid_y > 0 {
						app.game.player.grid_y--
						app.sound_mgr.play_sound('move')
					}
				}
				.down {
					if app.game.state == .playing && app.game.player.grid_y < grid_rows - 1 {
						app.game.player.grid_y++
						app.sound_mgr.play_sound('move')
					}
				}
				.space, .enter {
					if app.game.state == .start_menu {
						app.game.start_new_game()
					} else if app.game.state == .level_clear {
						app.game.next_level()
					} else if app.game.state == .game_over {
						app.game.start_new_game()
					} else if app.game.state == .playing {
						app.game.munch_cell(mut app.sound_mgr)
					}
				}
				.r { app.game.start_new_game() }
				.o {
					muted := !app.sound_mgr.toggle_sound()
					app.btn_sound.text = if muted { 'SOUND: OFF [O]' } else { 'SOUND: ON [O]' }
				}
				.p {
					if app.game.state == .playing { app.game.state = .paused }
					else if app.game.state == .paused { app.game.state = .playing }
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
		window_title: 'Math Munchers - Retro Educational Arcade'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 15, g: 20, b: 35, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  800
		height: 600
	}
	ctx.run()
}
