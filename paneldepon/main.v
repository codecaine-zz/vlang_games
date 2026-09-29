module main

import gg
import os
import time

const win_width = 860
const win_height = 840

const cell_size = 46
const grid_w = pdp_cols * cell_size
const grid_h = pdp_rows * cell_size

const board_x = 240
const board_y = 110

pub struct PanelDePonTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

struct PopParticle {
mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	life  f64
	max_l f64
	color Color
	size  int
}

struct FloatText {
mut:
	x     f64
	y     f64
	text  string
	life  f64
	max_l f64
	scale int
	color Color
}

struct App {
mut:
	ctx         &gg.Context = unsafe { nil }
	renderer    Renderer
	sound_mgr   SoundManager
	game        PanelGame
	tex_mgr     PanelDePonTextureManager
	particles   []PopParticle
	float_texts []FloatText
	shake_timer f64
	paused      bool
	btn_reset   Button
	btn_sound   Button
	btn_pause   Button
	mouse_x     int
	mouse_y     int
	last_tick   i64
}

fn (mut tm PanelDePonTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/paneldepon.png',
		'./assets/sprites/paneldepon.png',
		'../assets/sprites/paneldepon.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				return
			}
		}
	}
}

fn new_app() App {
	btn_y := 770
	return App{
		sound_mgr: new_sound_manager()
		game:      new_panel_game()
		btn_reset: Button{
			x: 40, y: btn_y, w: 160, h: 42, text: 'RESET [R]',
			bg_color: Color{r: 45, g: 30, b: 55, a: 255},
			hover_color: Color{r: 75, g: 45, b: 90, a: 255},
			text_color: Color{r: 255, g: 255, b: 255, a: 255},
			border_color: Color{r: 160, g: 80, b: 180, a: 255},
		}
		btn_sound: Button{
			x: 220, y: btn_y, w: 160, h: 42, text: 'SOUND [M]',
			bg_color: Color{r: 30, g: 45, b: 50, a: 255},
			hover_color: Color{r: 50, g: 75, b: 85, a: 255},
			text_color: Color{r: 255, g: 255, b: 255, a: 255},
			border_color: Color{r: 80, g: 140, b: 160, a: 255},
		}
		btn_pause: Button{
			x: 400, y: btn_y, w: 160, h: 42, text: 'PAUSE [P]',
			bg_color: Color{r: 45, g: 45, b: 30, a: 255},
			hover_color: Color{r: 75, g: 75, b: 45, a: 255},
			text_color: Color{r: 255, g: 255, b: 255, a: 255},
			border_color: Color{r: 160, g: 160, b: 70, a: 255},
		}
		last_tick: time.ticks()
	}
}

fn get_panel_colors(panel_type int) (Color, Color, Color) {
	match panel_type {
		1 { return Color{r: 240, g: 40, b: 65, a: 255}, Color{r: 255, g: 140, b: 160, a: 255}, Color{r: 145, g: 15, b: 30, a: 255} }
		2 { return Color{r: 250, g: 215, b: 35, a: 255}, Color{r: 255, g: 245, b: 145, a: 255}, Color{r: 160, g: 135, b: 15, a: 255} }
		3 { return Color{r: 35, g: 195, b: 245, a: 255}, Color{r: 130, g: 235, b: 255, a: 255}, Color{r: 15, g: 110, b: 165, a: 255} }
		4 { return Color{r: 40, g: 215, b: 75, a: 255}, Color{r: 140, g: 255, b: 160, a: 255}, Color{r: 15, g: 130, b: 40, a: 255} }
		5 { return Color{r: 195, g: 45, b: 240, a: 255}, Color{r: 235, g: 140, b: 255, a: 255}, Color{r: 115, g: 20, b: 150, a: 255} }
		else { return Color{r: 90, g: 90, b: 90, a: 255}, Color{r: 140, g: 140, b: 140, a: 255}, Color{r: 50, g: 50, b: 50, a: 255} }
	}
}

fn draw_panel(renderer &Renderer, cx int, cy int, size int, panel_type int) {
	if panel_type == 0 { return }
	r := size / 2 - 2

	main_c, high_c, _ := get_panel_colors(panel_type)

	rect := Rect{ x: cx - r + 1, y: cy - r + 1, w: (r - 1) * 2, h: (r - 1) * 2 }
	set_render_draw_color(renderer, main_c.r, main_c.g, main_c.b, 255)
	render_fill_rect(renderer, &rect)

	set_render_draw_color(renderer, high_c.r, high_c.g, high_c.b, 255)
	for i in 0 .. 3 {
		render_draw_line(renderer, cx - r + 1 + i, cy - r + 1 + i, cx + r - 1 - i, cy - r + 1 + i)
		render_draw_line(renderer, cx - r + 1 + i, cy - r + 1 + i, cx - r + 1 + i, cy + r - 1 - i)
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

	if !app.paused && app.game.state == .playing {
		app.game.update(f64(dt))
	}
	app.sound_mgr.update()

	renderer := &app.renderer
	set_render_draw_color(renderer, 15, 12, 25, 255)
	render_clear(renderer)

	// Outer Board Frame
	frame := Rect{x: board_x - 8, y: board_y - 8, w: grid_w + 16, h: grid_h + 16}
	set_render_draw_color(renderer, 45, 35, 65, 255)
	render_fill_rect(renderer, &frame)
	set_render_draw_color(renderer, 130, 90, 190, 255)
	render_draw_rect(renderer, &frame)

	// Inner Grid Area
	grid_bg := Rect{x: board_x, y: board_y, w: grid_w, h: grid_h}
	set_render_draw_color(renderer, 12, 8, 22, 255)
	render_fill_rect(renderer, &grid_bg)

	// Vertical rise shift
	rise_px := int(app.game.rise_offset * f64(cell_size))

	// Panels
	for r in 0 .. pdp_rows {
		for c in 0 .. pdp_cols {
			p_val := app.game.grid[r][c]
			if p_val != 0 {
				cx := board_x + c * cell_size + cell_size / 2
				cy := board_y + r * cell_size - rise_px + cell_size / 2
				if cy >= board_y {
					draw_panel(renderer, cx, cy, cell_size, p_val)
				}
			}
		}
	}

	// Rising Preview Row
	for c in 0 .. pdp_cols {
		cx := board_x + c * cell_size + cell_size / 2
		cy := board_y + pdp_rows * cell_size - rise_px + cell_size / 2
		draw_panel(renderer, cx, cy, cell_size, app.game.next_row[c])
	}

	// Cursor
	cur_px := board_x + app.game.cur_c * cell_size
	cur_py := board_y + app.game.cur_r * cell_size - rise_px
	cur_w := cell_size * 2
	cur_h := cell_size
	c_box := Rect{ x: cur_px - 2, y: cur_py - 2, w: cur_w + 4, h: cur_h + 4 }
	set_render_draw_color(renderer, 255, 255, 255, 255)
	render_draw_rect(renderer, &c_box)

	// HUD
	draw_text(renderer, 40, 140, 'SCORE', 2, Color{r: 180, g: 190, b: 220, a: 255})
	draw_text(renderer, 40, 170, '${app.game.score}', 3, Color{r: 255, g: 220, b: 70, a: 255})
	draw_text(renderer, 40, 230, 'CHAIN', 2, Color{r: 180, g: 190, b: 220, a: 255})
	draw_text(renderer, 40, 260, '${app.game.chain_count}x', 3, Color{r: 70, g: 220, b: 255, a: 255})

	app.btn_reset.render(renderer, app.mouse_x, app.mouse_y)
	app.btn_sound.render(renderer, app.mouse_x, app.mouse_y)
	app.btn_pause.render(renderer, app.mouse_x, app.mouse_y)

	if app.game.state == .game_over {
		box := Rect{x: board_x + 10, y: board_y + grid_h / 2 - 60, w: grid_w - 20, h: 120}
		set_render_draw_color(renderer, 35, 15, 20, 245)
		render_fill_rect(renderer, &box)
		set_render_draw_color(renderer, 255, 60, 70, 255)
		render_draw_rect(renderer, &box)
		draw_text_centered(renderer, board_x + grid_w / 2, board_y + grid_h / 2 - 35, 'GAME OVER', 3, Color{r: 255, g: 70, b: 90, a: 255})
		draw_text_centered(renderer, board_x + grid_w / 2, board_y + grid_h / 2 + 15, 'PRESS [R] TO RESTART', 2, Color{r: 255, g: 255, b: 255, a: 255})
	}

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
				if app.btn_reset.is_hovered(mx, my) {
					app.game = new_panel_game()
				} else if app.btn_sound.is_hovered(mx, my) {
					app.sound_mgr.toggle_sound()
				} else if app.btn_pause.is_hovered(mx, my) {
					app.paused = !app.paused
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
				.r { app.game = new_panel_game() }
				.p { app.paused = !app.paused }
				.m { app.sound_mgr.toggle_music() }
				.left, .a {
					app.game.move_cursor(0, -1)
					app.sound_mgr.play_move_sound()
				}
				.right, .d {
					app.game.move_cursor(0, 1)
					app.sound_mgr.play_move_sound()
				}
				.up, .w {
					app.game.move_cursor(-1, 0)
					app.sound_mgr.play_move_sound()
				}
				.down, .s {
					app.game.move_cursor(1, 0)
					app.sound_mgr.play_move_sound()
				}
				.space, .j {
					if app.game.swap_panels() {
						app.sound_mgr.play_swap_sound()
					}
				}
				.left_shift, .k {
					if app.game.push_stack_up() {
						app.sound_mgr.play_push_sound()
					}
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
		width:        win_width
		height:       win_height
		resizable:     true
		window_title: 'PANEL DE PON // Puzzle League Classic'
		user_data:    &app
		init_fn:      on_init
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 15, g: 12, b: 25, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_width
		height: win_height
	}
	ctx.run()
}
