module main

import gg
import time

struct Button {
	x            int
	y            int
	w            int
	h            int
	text         string
	bg_color     Color
	hover_color  Color
	text_color   Color
	border_color Color
}

fn (b &Button) contains(px int, py int) bool {
	return px >= b.x && px <= b.x + b.w && py >= b.y && py <= b.y + b.h
}

fn (b &Button) draw(renderer &Renderer, mouse_x int, mouse_y int) {
	is_hover := b.contains(mouse_x, mouse_y)
	c := if is_hover { b.hover_color } else { b.bg_color }
	rect := Rect{ x: b.x, y: b.y, w: b.w, h: b.h }
	set_render_draw_color(renderer, c.r, c.g, c.b, 255)
	render_fill_rect(renderer, &rect)
	set_render_draw_color(renderer, b.border_color.r, b.border_color.g, b.border_color.b, 255)
	render_draw_rect(renderer, &rect)
	draw_text_centered(renderer, b.x + b.w / 2, b.y + (b.h - 8) / 2, b.text, 1, b.text_color)
}

struct App {
mut:
	ctx           &gg.Context = unsafe { nil }
	renderer      Renderer
	game          RacerGame
	sound_mgr     SoundManager
	key_accel     bool
	key_brake     bool
	key_left      bool
	key_right     bool
	key_handbrake bool
	paused        bool
	mouse_x       int
	mouse_y       int
	btn_restart   Button
	btn_sound     Button
	last_tick     i64
}

fn new_app() App {
	return App{
		game:        new_racer_game()
		sound_mgr:   new_sound_manager()
		btn_restart: Button{ x: 10, y: 10, w: 90, h: 32, text: 'RESTART', bg_color: Color{r: 200, g: 50, b: 50}, hover_color: Color{r: 240, g: 70, b: 70}, text_color: Color{r: 255, g: 255, b: 255}, border_color: Color{r: 255, g: 255, b: 255} }
		btn_sound:   Button{ x: 110, y: 10, w: 90, h: 32, text: 'AUDIO', bg_color: Color{r: 50, g: 150, b: 50}, hover_color: Color{r: 70, g: 190, b: 70}, text_color: Color{r: 255, g: 255, b: 255}, border_color: Color{r: 255, g: 255, b: 255} }
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

	if !app.paused {
		app.game.update(f64(dt), app.key_accel, app.key_brake, app.key_left, app.key_right, app.key_handbrake)

		if app.game.sound_event_engine {
			speed_ratio := app.game.player.speed / app.game.player.max_speed
			app.sound_mgr.play_engine_sound(speed_ratio)
		}
		if app.game.sound_event_skid { app.sound_mgr.play_skid_sound() }
		if app.game.sound_event_crash { app.sound_mgr.play_crash_sound() }
		if app.game.sound_event_boost { app.sound_mgr.play_boost_sound() }
		if app.game.sound_event_gate { app.sound_mgr.play_gate_sound() }
	}
	app.sound_mgr.update()

	app.game.render(&app.renderer)
	app.btn_restart.draw(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_sound.draw(&app.renderer, app.mouse_x, app.mouse_y)

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
					app.game = new_racer_game()
				} else if app.btn_sound.contains(mx, my) {
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
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.escape { exit(0) }
				.up, .w { app.key_accel = true }
				.down, .s { app.key_brake = true }
				.left, .a { app.key_left = true }
				.right, .d { app.key_right = true }
				.space, .k { app.key_handbrake = true }
				.r { app.game = new_racer_game() }
				.p { app.paused = !app.paused }
				.m { app.sound_mgr.toggle_music() }
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.up, .w { app.key_accel = false }
				.down, .s { app.key_brake = false }
				.left, .a { app.key_left = false }
				.right, .d { app.key_right = false }
				.space, .k { app.key_handbrake = false }
				else {}
			}
		}
		else {}
	}
}

fn main() {
	mut app := new_app()
	mut ctx := gg.new_context(
		width:        960
		height:       640
		resizable:     true
		window_title: 'Outrun / Ridge Racer 2.5D Retro Arcade'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 20, g: 20, b: 30, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  960
		height: 640
	}
	ctx.run()
}
