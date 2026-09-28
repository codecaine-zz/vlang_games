module main

import gg
import time

const win_width = 860
const win_height = 680

struct Button {
	x            int
	y            int
	w            int
	h            int
	bg_color     Color = Color{r: 30, g: 40, b: 60, a: 255}
	hover_color  Color = Color{r: 50, g: 70, b: 100, a: 255}
	text_color   Color = Color{r: 255, g: 255, b: 255, a: 255}
	border_color Color = Color{r: 80, g: 110, b: 160, a: 255}
mut:
	text string
}

fn (b Button) contains(x int, y int) bool {
	return x >= b.x && x <= b.x + b.w && y >= b.y && y <= b.y + b.h
}

fn (b Button) render(renderer &Renderer, mouse_x int, mouse_y int) {
	is_hover := b.contains(mouse_x, mouse_y)
	color := if is_hover { b.hover_color } else { b.bg_color }

	rect := Rect{
		x: b.x
		y: b.y
		w: b.w
		h: b.h
	}
	set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	render_fill_rect(renderer, &rect)

	set_render_draw_color(renderer, b.border_color.r, b.border_color.g, b.border_color.b, b.border_color.a)
	render_draw_rect(renderer, &rect)

	scale := if b.text.len * 8 * 2 > b.w - 8 { 1 } else { 2 }
	text_x := b.x + (b.w - b.text.len * 8 * scale) / 2
	text_y := b.y + (b.h - 8 * scale) / 2
	draw_text(renderer, text_x, text_y, b.text, scale, b.text_color)
}

struct App {
mut:
	ctx         &gg.Context = unsafe { nil }
	renderer    Renderer
	game        Minesweeper
	sound_mgr   SoundManager
	tex_mgr     MinesweeperTextureManager
	particles   []Particle
	mouse_x     int
	mouse_y     int
	mouse_down  bool
	mouse_rdown bool
	curs_r      int
	curs_c      int
	btn_beg     Button
	btn_int     Button
	btn_exp     Button
	btn_sound   Button
	btn_theme   Button
	btn_reset   Button
	face_rect   Rect
	cell_size   int = 28
	board_x     int
	board_y     int
	last_tick   i64
}

fn new_app() App {
	mut app := App{
		game:      new_minesweeper(.beginner)
		sound_mgr: new_sound_manager()
		btn_beg:   Button{
			x: 20, y: 620, w: 125, h: 38, text: '1: BEG',
			bg_color: Color{r: 30, g: 40, b: 60, a: 255}, hover_color: Color{r: 50, g: 70, b: 100, a: 255},
			text_color: Color{r: 255, g: 255, b: 255, a: 255}, border_color: Color{r: 80, g: 110, b: 160, a: 255},
		}
		btn_int:   Button{
			x: 155, y: 620, w: 125, h: 38, text: '2: INT',
			bg_color: Color{r: 30, g: 40, b: 60, a: 255}, hover_color: Color{r: 50, g: 70, b: 100, a: 255},
			text_color: Color{r: 255, g: 255, b: 255, a: 255}, border_color: Color{r: 80, g: 110, b: 160, a: 255},
		}
		btn_exp:   Button{
			x: 290, y: 620, w: 125, h: 38, text: '3: EXP',
			bg_color: Color{r: 30, g: 40, b: 60, a: 255}, hover_color: Color{r: 50, g: 70, b: 100, a: 255},
			text_color: Color{r: 255, g: 255, b: 255, a: 255}, border_color: Color{r: 80, g: 110, b: 160, a: 255},
		}
		btn_theme: Button{
			x: 425, y: 620, w: 135, h: 38, text: 'THEME [T]',
			bg_color: Color{r: 30, g: 40, b: 60, a: 255}, hover_color: Color{r: 50, g: 70, b: 100, a: 255},
			text_color: Color{r: 255, g: 255, b: 255, a: 255}, border_color: Color{r: 80, g: 110, b: 160, a: 255},
		}
		btn_sound: Button{
			x: 570, y: 620, w: 135, h: 38, text: 'SOUND [S]',
			bg_color: Color{r: 30, g: 40, b: 60, a: 255}, hover_color: Color{r: 50, g: 70, b: 100, a: 255},
			text_color: Color{r: 255, g: 255, b: 255, a: 255}, border_color: Color{r: 80, g: 110, b: 160, a: 255},
		}
		btn_reset: Button{
			x: 715, y: 620, w: 125, h: 38, text: 'RESET [R]',
			bg_color: Color{r: 80, g: 30, b: 40, a: 255}, hover_color: Color{r: 120, g: 40, b: 50, a: 255},
			text_color: Color{r: 255, g: 255, b: 255, a: 255}, border_color: Color{r: 180, g: 60, b: 80, a: 255},
		}
		last_tick: time.ticks()
	}
	app.recalc_layout()
	return app
}

fn (mut app App) recalc_layout() {
	match app.game.difficulty {
		.beginner { app.cell_size = 40 }
		.intermediate { app.cell_size = 28 }
		.expert { app.cell_size = 24 }
		.custom { app.cell_size = 24 }
	}
	board_w := app.game.cols * app.cell_size
	app.board_x = (win_width - board_w) / 2
	app.board_y = 138
	app.face_rect = Rect{ x: win_width / 2 - 20, y: 85, w: 40, h: 40 }
}

fn (mut app App) restart_game() {
	app.game.reset()
	app.particles.clear()
	app.recalc_layout()
}

fn (mut app App) change_diff(diff Difficulty) {
	app.game.set_difficulty(diff)
	app.restart_game()
}

fn (mut app App) handle_cell_click(r int, c int, is_right bool) {
	if !app.game.is_valid(r, c) { return }

	if is_right {
		old_state := app.game.cells[r][c].state
		new_state := app.game.toggle_flag(r, c)
		if new_state == .flagged {
			app.sound_mgr.play_flag_sound()
		} else if old_state == .flagged {
			app.sound_mgr.play_unflag_sound()
		}
		if app.game.state == .won {
			app.sound_mgr.play_win_sound()
			app.particles << create_confetti_particles(win_width, win_height)
		}
		return
	}

	cell := app.game.cells[r][c]
	if cell.state == .revealed {
		hit_mine, opened := app.game.chord_cell(r, c)
		if hit_mine {
			app.sound_mgr.play_explode_sound()
			cx := f64(app.board_x + c * app.cell_size + app.cell_size / 2)
			cy := f64(app.board_y + r * app.cell_size + app.cell_size / 2)
			app.particles << create_explosion_particles(cx, cy)
		} else if opened > 0 {
			if opened > 2 {
				app.sound_mgr.play_cascade_sound()
			} else {
				app.sound_mgr.play_click_sound()
			}
			if app.game.state == .won {
				app.sound_mgr.play_win_sound()
				app.particles << create_confetti_particles(win_width, win_height)
			}
		}
		return
	}

	hit_mine, opened := app.game.reveal_cell(r, c)
	if hit_mine {
		app.sound_mgr.play_explode_sound()
		cx := f64(app.board_x + c * app.cell_size + app.cell_size / 2)
		cy := f64(app.board_y + r * app.cell_size + app.cell_size / 2)
		app.particles << create_explosion_particles(cx, cy)
	} else if opened > 0 {
		if opened > 3 {
			app.sound_mgr.play_cascade_sound()
		} else {
			app.sound_mgr.play_click_sound()
		}
		if app.game.state == .won {
			app.sound_mgr.play_win_sound()
			app.particles << create_confetti_particles(win_width, win_height)
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

	app.game.update_timer(u32(now))
	update_particles(mut app.particles, f64(dt))
	app.sound_mgr.update()

	r := &app.renderer
	is_neon := app.game.theme_neon
	bg_color := if is_neon { Color{r: 12, g: 15, b: 24, a: 255} } else { Color{r: 192, g: 192, b: 192, a: 255} }
	panel_bg := if is_neon { Color{r: 20, g: 26, b: 40, a: 255} } else { Color{r: 192, g: 192, b: 192, a: 255} }
	light_bev := if is_neon { Color{r: 60, g: 80, b: 130, a: 255} } else { Color{r: 255, g: 255, b: 255, a: 255} }
	dark_bev := if is_neon { Color{r: 10, g: 12, b: 20, a: 255} } else { Color{r: 128, g: 128, b: 128, a: 255} }
	title_col := if is_neon { Color{r: 80, g: 220, b: 255, a: 255} } else { Color{r: 20, g: 30, b: 60, a: 255} }

	set_render_draw_color(r, bg_color.r, bg_color.g, bg_color.b, bg_color.a)
	render_clear(r)

	draw_text_centered(r, win_width / 2, 18, 'MINESWEEPER PRO', 3, title_col)
	draw_text_centered(r, win_width / 2, 48, 'RETRO ARCADE PUZZLE', 1, if is_neon { Color{r: 160, g: 180, b: 210, a: 255} } else { Color{r: 80, g: 80, b: 90, a: 255} })

	frame_w := app.game.cols * app.cell_size + 24
	frame_h := app.game.rows * app.cell_size + 80
	frame_x := (win_width - frame_w) / 2
	frame_y := 70

	draw_bevel_rect(r, frame_x, frame_y, frame_w, frame_h, true, panel_bg, light_bev, dark_bev, 4)

	status_x := frame_x + 10
	status_y := frame_y + 10
	status_w := frame_w - 20
	status_h := 50
	draw_bevel_rect(r, status_x, status_y, status_w, status_h, false, panel_bg, light_bev, dark_bev, 3)

	led_on := Color{r: 255, g: 25, b: 25, a: 255}
	led_off := Color{r: 45, g: 10, b: 10, a: 255}
	led_box_w := 74
	led_box_h := 40
	led_y := status_y + 5

	led_left_x := status_x + 8
	draw_bevel_rect(r, led_left_x, led_y, led_box_w, led_box_h, false, Color{r: 0, g: 0, b: 0, a: 255}, dark_bev, light_bev, 2)
	draw_number_7seg(r, led_left_x + 6, led_y + 4, app.game.get_remaining_mines(), 3, 18, 32, 4, led_on, led_off)

	led_right_x := status_x + status_w - led_box_w - 8
	draw_bevel_rect(r, led_right_x, led_y, led_box_w, led_box_h, false, Color{r: 0, g: 0, b: 0, a: 255}, dark_bev, light_bev, 2)
	draw_number_7seg(r, led_right_x + 6, led_y + 4, app.game.timer_ticks, 3, 18, 32, 4, led_on, led_off)

	face_pressed := app.face_rect.x <= app.mouse_x && app.mouse_x <= app.face_rect.x + app.face_rect.w &&
		app.face_rect.y <= app.mouse_y && app.mouse_y <= app.face_rect.y + app.face_rect.h && app.mouse_down
	draw_bevel_rect(r, app.face_rect.x, app.face_rect.y, app.face_rect.w, app.face_rect.h, !face_pressed, panel_bg, light_bev, dark_bev, 3)

	mut face_state := app.game.face_state
	if app.mouse_down && app.game.state == .playing {
		face_state = .shock
	}
	draw_smiley_face(r, app.face_rect.x + 20, app.face_rect.y + 20, 14, face_state, face_pressed, app.tex_mgr.sprite_texture)

	grid_x := frame_x + 10
	grid_y := frame_y + 66
	grid_w := app.game.cols * app.cell_size + 4
	grid_h := app.game.rows * app.cell_size + 4
	draw_bevel_rect(r, grid_x, grid_y, grid_w, grid_h, false, panel_bg, light_bev, dark_bev, 3)

	number_colors := [
		Color{r: 0, g: 0, b: 0, a: 255},
		Color{r: 25, g: 50, b: 230, a: 255},
		Color{r: 20, g: 140, b: 30, a: 255},
		Color{r: 220, g: 30, b: 30, a: 255},
		Color{r: 10, g: 20, b: 130, a: 255},
		Color{r: 130, g: 15, b: 15, a: 255},
		Color{r: 15, g: 150, b: 150, a: 255},
		Color{r: 20, g: 20, b: 20, a: 255},
		Color{r: 120, g: 120, b: 120, a: 255},
	]

	cell_bg_hidden := if is_neon { Color{r: 28, g: 36, b: 56, a: 255} } else { Color{r: 192, g: 192, b: 192, a: 255} }
	cell_bg_revealed := if is_neon { Color{r: 18, g: 22, b: 34, a: 255} } else { Color{r: 192, g: 192, b: 192, a: 255} }

	for row in 0 .. app.game.rows {
		for col in 0 .. app.game.cols {
			cx := app.board_x + col * app.cell_size
			cy := app.board_y + row * app.cell_size
			cell := app.game.cells[row][col]

			if cell.state == .revealed {
				draw_bevel_rect(r, cx, cy, app.cell_size, app.cell_size, false, cell_bg_revealed, light_bev, dark_bev, 1)

				if cell.is_mine {
					draw_mine_icon(r, cx + app.cell_size / 2, cy + app.cell_size / 2, app.cell_size - 4, cell.exploded, app.tex_mgr.sprite_texture)
				} else if cell.neighbor_mines > 0 {
					num_str := '${cell.neighbor_mines}'
					scale := if app.cell_size >= 32 { 2 } else { 1 }
					num_col := number_colors[cell.neighbor_mines]
					tx := cx + (app.cell_size - 8 * scale) / 2
					ty := cy + (app.cell_size - 8 * scale) / 2
					draw_text(r, tx, ty, num_str, scale, num_col)
				}
			} else {
				draw_bevel_rect(r, cx, cy, app.cell_size, app.cell_size, true, cell_bg_hidden, light_bev, dark_bev, 2)

				if cell.state == .flagged {
					if cell.wrong_flag {
						draw_wrong_flag_icon(r, cx + app.cell_size / 2, cy + app.cell_size / 2, app.cell_size - 6, app.tex_mgr.sprite_texture)
					} else {
						draw_flag_icon(r, cx + app.cell_size / 2, cy + app.cell_size / 2, app.cell_size - 6, app.tex_mgr.sprite_texture)
					}
				} else if cell.state == .question {
					scale := if app.cell_size >= 32 { 2 } else { 1 }
					tx := cx + (app.cell_size - 8 * scale) / 2
					ty := cy + (app.cell_size - 8 * scale) / 2
					draw_text(r, tx, ty, '?', scale, Color{r: 20, g: 20, b: 30, a: 255})
				}
			}

			if row == app.curs_r && col == app.curs_c {
				set_render_draw_color(r, 255, 220, 50, 200)
				curs_box := Rect{x: cx + 1, y: cy + 1, w: app.cell_size - 2, h: app.cell_size - 2}
				render_draw_rect(r, &curs_box)
			}
		}
	}

	render_particles(r, app.particles)

	app.btn_beg.render(r, app.mouse_x, app.mouse_y)
	app.btn_int.render(r, app.mouse_x, app.mouse_y)
	app.btn_exp.render(r, app.mouse_x, app.mouse_y)
	app.btn_theme.render(r, app.mouse_x, app.mouse_y)
	app.btn_sound.render(r, app.mouse_x, app.mouse_y)
	app.btn_reset.render(r, app.mouse_x, app.mouse_y)

	if app.game.state == .won {
		draw_text_centered(r, win_width / 2, frame_y + frame_h + 8, 'VICTORY! ALL MINES CLEARED!', 2, Color{r: 40, g: 220, b: 80, a: 255})
	} else if app.game.state == .lost {
		draw_text_centered(r, win_width / 2, frame_y + frame_h + 8, 'GAME OVER - MINE DETONATED', 2, Color{r: 240, g: 50, b: 50, a: 255})
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
			if app.cell_size > 0 {
				col := (app.mouse_x - app.board_x) / app.cell_size
				row := (app.mouse_y - app.board_y) / app.cell_size
				if app.game.is_valid(row, col) {
					app.curs_r = row
					app.curs_c = col
				} else {
					app.curs_r = -1
					app.curs_c = -1
				}
			}
		}
		.mouse_down {
			mx := int(e.mouse_x)
			my := int(e.mouse_y)
			app.mouse_x = mx
			app.mouse_y = my

			if e.mouse_button == .left {
				app.mouse_down = true
				if app.btn_beg.contains(mx, my) {
					app.change_diff(.beginner)
				} else if app.btn_int.contains(mx, my) {
					app.change_diff(.intermediate)
				} else if app.btn_exp.contains(mx, my) {
					app.change_diff(.expert)
				} else if app.btn_theme.contains(mx, my) {
					app.game.theme_neon = !app.game.theme_neon
				} else if app.btn_sound.contains(mx, my) {
					muted := !app.sound_mgr.toggle_sound()
					app.btn_sound.text = if muted { 'SOUND: OFF' } else { 'SOUND: ON' }
				} else if app.btn_reset.contains(mx, my) || (mx >= app.face_rect.x && mx <= app.face_rect.x + app.face_rect.w && my >= app.face_rect.y && my <= app.face_rect.y + app.face_rect.h) {
					app.restart_game()
				} else if app.cell_size > 0 {
					col := (mx - app.board_x) / app.cell_size
					row := (my - app.board_y) / app.cell_size
					app.handle_cell_click(row, col, false)
				}
			} else if e.mouse_button == .right {
				app.mouse_rdown = true
				if app.cell_size > 0 {
					col := (mx - app.board_x) / app.cell_size
					row := (my - app.board_y) / app.cell_size
					app.handle_cell_click(row, col, true)
				}
			}
		}
		.mouse_up {
			if e.mouse_button == .left {
				app.mouse_down = false
			} else if e.mouse_button == .right {
				app.mouse_rdown = false
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
				.r { app.restart_game() }
				._1 { app.change_diff(.beginner) }
				._2 { app.change_diff(.intermediate) }
				._3 { app.change_diff(.expert) }
				.t { app.game.theme_neon = !app.game.theme_neon }
				.s {
					muted := !app.sound_mgr.toggle_sound()
					app.btn_sound.text = if muted { 'SOUND: OFF' } else { 'SOUND: ON' }
				}
				.space {
					if app.game.is_valid(app.curs_r, app.curs_c) {
						app.handle_cell_click(app.curs_r, app.curs_c, false)
					}
				}
				.f {
					if app.game.is_valid(app.curs_r, app.curs_c) {
						app.handle_cell_click(app.curs_r, app.curs_c, true)
					}
				}
				.up, .w { if app.curs_r > 0 { app.curs_r-- } }
				.down { if app.curs_r < app.game.rows - 1 { app.curs_r++ } }
				.left, .a { if app.curs_c > 0 { app.curs_c-- } }
				.right, .d { if app.curs_c < app.game.cols - 1 { app.curs_c++ } }
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
		window_title: 'Minesweeper Deluxe (Cyber-Enhanced)'
		user_data:    &app
		init_fn:      on_init
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 20, g: 25, b: 35, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_width
		height: win_height
	}
	ctx.run()
}
