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
	ctx        &gg.Context = unsafe { nil }
	renderer   Renderer
	game       RainGame
	sound_mgr  SoundManager
	mouse_x    int
	mouse_y    int
	btn_theme  Button
	btn_mode   Button
	btn_preset Button
	btn_sound  Button
	last_tick  i64
}

fn new_app() App {
	return App{
		game:       new_rain_game()
		sound_mgr:  new_sound_manager()
		btn_theme:  Button{ x: 10, y: 60, w: 110, h: 28, text: 'THEME [TAB]', bg_color: Color{r: 25, g: 35, b: 55}, hover_color: Color{r: 45, g: 65, b: 100}, text_color: Color{r: 255, g: 255, b: 255}, border_color: Color{r: 0, g: 180, b: 255} }
		btn_mode:   Button{ x: 130, y: 60, w: 110, h: 28, text: 'MODE [B]', bg_color: Color{r: 25, g: 35, b: 55}, hover_color: Color{r: 45, g: 65, b: 100}, text_color: Color{r: 255, g: 255, b: 255}, border_color: Color{r: 0, g: 180, b: 255} }
		btn_preset: Button{ x: 250, y: 60, w: 110, h: 28, text: 'STRESS [5]', bg_color: Color{r: 45, g: 25, b: 55}, hover_color: Color{r: 85, g: 45, b: 110}, text_color: Color{r: 255, g: 220, b: 100}, border_color: Color{r: 255, g: 0, b: 180} }
		btn_sound:  Button{ x: 370, y: 60, w: 110, h: 28, text: 'SOUND [M]', bg_color: Color{r: 25, g: 35, b: 55}, hover_color: Color{r: 45, g: 65, b: 100}, text_color: Color{r: 255, g: 255, b: 255}, border_color: Color{r: 0, g: 180, b: 255} }
		last_tick:  time.ticks()
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.game.update(f64(dt))
	app.sound_mgr.update()

	render_rain_game(&app.renderer, mut app.game)
	app.btn_theme.draw(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_mode.draw(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_preset.draw(&app.renderer, app.mouse_x, app.mouse_y)
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
			app.game.umbrella.x = f64(app.mouse_x)
			app.game.umbrella.y = f64(app.mouse_y)
		}
		.mouse_down {
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				if app.btn_theme.contains(mx, my) {
					app.game.cycle_theme()
				} else if app.btn_mode.contains(mx, my) {
					app.game.mode = match app.game.mode {
						.atmospheric { GameMode.defense }
						.defense { GameMode.benchmark }
						.benchmark { GameMode.atmospheric }
					}
				} else if app.btn_preset.contains(mx, my) {
					app.game.set_intensity_preset(5)
				} else if app.btn_sound.contains(mx, my) {
					app.sound_mgr.toggle_sound()
				} else {
					app.game.trigger_lightning()
					app.sound_mgr.play_lightning_strike()
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
				.tab { app.game.cycle_theme() }
				.b {
					app.game.mode = match app.game.mode {
						.atmospheric { GameMode.defense }
						.defense { GameMode.benchmark }
						.benchmark { GameMode.atmospheric }
					}
				}
				._5 { app.game.set_intensity_preset(5) }
				.m { app.sound_mgr.toggle_music() }
				.r { app.game = new_rain_game() }
				.space {
					app.game.trigger_lightning()
					app.sound_mgr.play_lightning_strike()
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
		width:        960
		height:       640
		resizable:     true
		window_title: 'Monsoon Overdrive - Realistic Rain Simulator & M4 Hardware Benchmark'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 5, g: 8, b: 15, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  960
		height: 640
	}
	ctx.run()
}
