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
	game          RagdollGame
	sound_mgr     SoundManager
	mouse_x       int
	mouse_y       int
	mouse_down    bool
	mouse_clicked bool
	paused        bool
	btn_restart   Button
	btn_sound     Button
	last_tick     i64
}

fn new_app() App {
	return App{
		game:        new_ragdoll_game()
		sound_mgr:   new_sound_manager()
		btn_restart: Button{ x: 10, y: 10, w: 90, h: 32, text: 'RESET', bg_color: Color{r: 200, g: 50, b: 50}, hover_color: Color{r: 240, g: 70, b: 70}, text_color: Color{r: 255, g: 255, b: 255}, border_color: Color{r: 255, g: 255, b: 255} }
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
		app.game.update(f64(dt), app.mouse_x, app.mouse_y, app.mouse_down, app.mouse_clicked)
		app.mouse_clicked = false

		if app.game.sound_event_thud { app.sound_mgr.play_thud_sound(app.game.thud_intensity) }
		if app.game.sound_event_crunch { app.sound_mgr.play_crunch_sound() }
		if app.game.sound_event_explosion { app.sound_mgr.play_explosion_sound() }
		if app.game.sound_event_zap { app.sound_mgr.play_gravgun_zap() }
		if app.game.sound_event_boing { app.sound_mgr.play_boing_sound() }
		if app.game.sound_event_bumper { app.sound_mgr.play_bumper_chime() }
		if app.game.sound_event_tether { app.sound_mgr.play_tether_snap() }
	}
	app.sound_mgr.update()

	app.game.render(&app.renderer, app.mouse_x, app.mouse_y)
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
				app.mouse_down = true
				app.mouse_clicked = true
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				if app.btn_restart.contains(mx, my) {
					app.game.load_arena(app.game.active_arena)
				} else if app.btn_sound.contains(mx, my) {
					app.sound_mgr.toggle_sound()
				}
			}
		}
		.mouse_up {
			if e.mouse_button == .left {
				app.mouse_down = false
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
				._1 { app.game.load_arena(.funhouse) }
				._2 { app.game.load_arena(.staircase) }
				._3 { app.game.load_arena(.zero_g) }
				.g { app.game.active_tool = .grab }
				.t { app.game.active_tool = .tether }
				.b { app.game.active_tool = .bomb }
				.r { app.game.load_arena(app.game.active_arena) }
				.p { app.paused = !app.paused }
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
		width:        800
		height:       600
		resizable:     true
		window_title: 'Ragdoll Sandbox Physics Playground'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 15, g: 20, b: 30, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  800
		height: 600
	}
	ctx.run()
}
