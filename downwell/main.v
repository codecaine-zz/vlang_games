module main

import gg
import time

fn (b Button) render(renderer &Renderer, mx int, my int) {
	hovered := b.contains(mx, my)
	col := if hovered { b.hover_color } else { b.bg_color }
	set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
	render_fill_rect(renderer, &Rect{ x: b.x, y: b.y, w: b.w, h: b.h })
	draw_text_centered(renderer, b.x + b.w / 2, b.y + b.h / 2 - 6, b.text, 2, b.text_color)
}

struct App {
mut:
	ctx         &gg.Context = unsafe { nil }
	renderer    Renderer
	game        DownwellGame
	sound_mgr   SoundManager
	tex_mgr     DownwellTextureManager
	mouse_x     int
	mouse_y     int
	key_left    bool
	key_right   bool
	key_jump    bool
	key_shoot   bool
	paused      bool
	btn_restart Button
	btn_sound   Button
	last_tick   i64
}

fn new_app() App {
	return App{
		game:        new_downwell_game()
		sound_mgr:   new_sound_manager()
		last_tick:   time.ticks()
		btn_restart: Button{
			x:           20
			y:           540
			w:           150
			h:           40
			text:        'RESTART [R]'
			bg_color:    Color{ r: 40, g: 40, b: 50, a: 220 }
			hover_color: Color{ r: 70, g: 70, b: 85, a: 255 }
			text_color:  Color{ r: 255, g: 255, b: 255, a: 255 }
		}
		btn_sound:   Button{
			x:           180
			y:           540
			w:           150
			h:           40
			text:        'SOUND: ON [O]'
			bg_color:    Color{ r: 40, g: 40, b: 50, a: 220 }
			hover_color: Color{ r: 70, g: 70, b: 85, a: 255 }
			text_color:  Color{ r: 255, g: 255, b: 255, a: 255 }
		}
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

	if !app.paused {
		app.game.update(f64(dt), app.key_left, app.key_right, app.key_jump, app.key_shoot)
	}
	app.sound_mgr.update()

	render_downwell_game(&app.renderer, &app.game, app.tex_mgr.sprite_texture)
	app.btn_restart.render(&app.renderer, app.mouse_x, app.mouse_y)
	app.btn_sound.render(&app.renderer, app.mouse_x, app.mouse_y)
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
			mx := int(e.mouse_x)
			my := int(e.mouse_y)
			if app.btn_restart.contains(mx, my) {
				app.game.start_new_game()
			} else if app.btn_sound.contains(mx, my) {
				muted := !app.sound_mgr.toggle_sound()
				app.btn_sound.text = if muted { 'SOUND: OFF [O]' } else { 'SOUND: ON [O]' }
			} else if app.game.shop_active {
				if my >= 200 && my <= 400 {
					idx := (my - 200) / 55
					app.game.buy_shop_item(idx)
				}
			} else {
				app.key_shoot = true
			}
		}
		.mouse_up {
			app.key_shoot = false
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
				.escape {
					exit(0)
				}
				.a, .left {
					app.key_left = true
				}
				.d, .right {
					app.key_right = true
				}
				.space, .up, .z {
					app.key_jump = true
				}
				.down, .x {
					app.key_shoot = true
				}
				.r {
					app.game.start_new_game()
				}
				.o, .m {
					muted := !app.sound_mgr.toggle_sound()
					app.btn_sound.text = if muted { 'SOUND: OFF [O]' } else { 'SOUND: ON [O]' }
				}
				.p {
					app.paused = !app.paused
				}
				else {}
			}
		}
		.key_up {
			match e.key_code {
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.a, .left {
					app.key_left = false
				}
				.d, .right {
					app.key_right = false
				}
				.space, .up, .z {
					app.key_jump = false
				}
				.down, .x {
					app.key_shoot = false
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
		window_title: 'Downwell - Gunboots Vertical Descent'
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
		height: 600
	}
	ctx.run()
}
