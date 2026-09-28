module main

import gg
import rand
import time

const win_w = 800
const win_h = 600

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	templates []ScreensaverTemplate
	state     ScreensaverState
	gui       GuiState
	sound_mgr SoundManager
	last_tick i64
}

fn new_app() App {
	return App{
		templates: get_all_templates()
		state:     ScreensaverState{}
		gui:       GuiState{
			show_menu:       false
			show_hud:        true
			is_fullscreen:   false
			selected_index:  0
			auto_cycle:      true
			cycle_interval:  15.0
			show_crt_filter: true
		}
		sound_mgr: new_sound_manager()
		last_tick: time.ticks()
	}
}

fn (mut app App) next_screensaver() {
	app.gui.selected_index = (app.gui.selected_index + 1) % app.templates.len
	app.state = ScreensaverState{}
	app.gui.cycle_timer = 0
	app.sound_mgr.play_switch()
}

fn (mut app App) prev_screensaver() {
	app.gui.selected_index = (app.gui.selected_index - 1 + app.templates.len) % app.templates.len
	app.state = ScreensaverState{}
	app.gui.cycle_timer = 0
	app.sound_mgr.play_switch()
}

fn (mut app App) random_screensaver() {
	app.gui.selected_index = rand.int_in_range(0, app.templates.len) or { 0 }
	app.state = ScreensaverState{}
	app.gui.cycle_timer = 0
	app.sound_mgr.play_switch()
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.state.time_elapsed += f64(dt)
	app.state.frame_count++

	if app.gui.auto_cycle && !app.gui.show_menu {
		app.gui.cycle_timer += f64(dt)
		if app.gui.cycle_timer >= app.gui.cycle_interval {
			app.next_screensaver()
		}
	}
	app.sound_mgr.update()

	draw_screensaver_scene(&app.renderer, app.templates, mut app.state, mut app.gui, win_w, win_h)
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
			app.state.mouse_x = int(e.mouse_x)
			app.state.mouse_y = int(e.mouse_y)
		}
		.mouse_down {
			app.state.mouse_x = int(e.mouse_x)
			app.state.mouse_y = int(e.mouse_y)
			if e.mouse_button == .left {
				app.state.mouse_down = true
			} else if e.mouse_button == .right {
				app.state.mouse_right_down = true
			}
		}
		.mouse_up {
			if e.mouse_button == .left {
				app.state.mouse_down = false
			} else if e.mouse_button == .right {
				app.state.mouse_right_down = false
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
					if app.gui.show_menu {
						app.gui.show_menu = false
					} else {
						exit(0)
					}
				}
				.h {
					app.gui.show_hud = !app.gui.show_hud
					if !app.gui.show_hud {
						app.gui.show_menu = false
					}
				}
				.tab {
					app.gui.show_menu = !app.gui.show_menu
				}
				.c {
					app.gui.auto_cycle = !app.gui.auto_cycle
					app.sound_mgr.play_switch()
				}
				.left, .p {
					app.prev_screensaver()
				}
				.right, .n {
					app.next_screensaver()
				}
				.r {
					app.random_screensaver()
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
		window_title: 'The Ultimate Retro Screensaver Emulator (102 Classic Templates)'
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
