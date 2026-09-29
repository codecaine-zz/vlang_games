module main

import math
import rand
import gg
import time

const win_width = 1000
const win_height = 840

enum PlayMode {
	strikes
	zen
}

struct Particle {
mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	life  f64
	color Color
	size  int
}

struct App {
mut:
	ctx           &gg.Context = unsafe { nil }
	renderer      Renderer
	last_tick     i64
	mouse_x       int
	mouse_y       int
	sound_mgr     SoundManager
	puzzles       []Puzzle
	current_idx   int
	cursor_r      int
	cursor_c      int
	mouse_down    bool
	mouse_button  u8
	drag_fill_mode CellState = .empty
	hover_r       int       = -1
	hover_c       int       = -1
	mode          PlayMode  = .zen
	strikes_count int
	max_strikes   int = 3
	game_over     bool
	start_time    time.Time
	elapsed_sec   int
	particles     []Particle
	btn_prev      Button
	btn_next      Button
	btn_reset     Button
	btn_hint      Button
	btn_mode      Button
	btn_sound     Button
}

fn new_app() App {
	catalog := get_puzzle_catalog()
	btn_y := 770

	return App{
		last_tick: time.ticks()
		sound_mgr:   new_sound_manager()
		puzzles:     catalog
		current_idx: 0
		start_time:  time.now()
		btn_prev:    Button{
			x: 50, y: 70, w: 160, h: 36, text: 'PREV [P]',
			bg_color: Color{r: 30, g: 45, b: 70},
			hover_color: Color{r: 50, g: 75, b: 110},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 70, g: 100, b: 150},
		}
		btn_next:    Button{
			x: win_width - 210, y: 70, w: 160, h: 36, text: 'NEXT [N]',
			bg_color: Color{r: 30, g: 45, b: 70},
			hover_color: Color{r: 50, g: 75, b: 110},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 70, g: 100, b: 150},
		}
		btn_reset:   Button{
			x: 60, y: btn_y, w: 180, h: 42, text: 'RESET [R]',
			bg_color: Color{r: 40, g: 40, b: 60},
			hover_color: Color{r: 65, g: 65, b: 90},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 90, g: 90, b: 130},
		}
		btn_hint:    Button{
			x: 270, y: btn_y, w: 180, h: 42, text: 'HINT [H]',
			bg_color: Color{r: 40, g: 60, b: 40},
			hover_color: Color{r: 60, g: 90, b: 60},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 80, g: 140, b: 80},
		}
		btn_mode:    Button{
			x: 480, y: btn_y, w: 230, h: 42, text: 'MODE: ZEN [M]',
			bg_color: Color{r: 45, g: 40, b: 70},
			hover_color: Color{r: 70, g: 60, b: 110},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 100, g: 85, b: 150},
		}
		btn_sound:   Button{
			x: 740, y: btn_y, w: 200, h: 42, text: 'SOUND: ON [S]',
			bg_color: Color{r: 35, g: 50, b: 70},
			hover_color: Color{r: 55, g: 80, b: 110},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 80, g: 115, b: 160},
		}
	}
}

fn (mut app App) change_puzzle(offset int) {
	new_idx := app.current_idx + offset
	if new_idx >= 0 && new_idx < app.puzzles.len {
		app.current_idx = new_idx
		app.cursor_r = 0
		app.cursor_c = 0
		app.strikes_count = 0
		app.game_over = false
		app.start_time = time.now()
		app.sound_mgr.play_fill_sound()
	}
}

fn (mut app App) spawn_win_particles() {
	p := app.puzzles[app.current_idx]
	for _ in 0 .. 60 {
		angle := rand.f64() * 2.0 * math.pi
		speed := 80.0 + rand.f64() * 240.0
		app.particles << Particle{
			x: f64(win_width / 2)
			y: f64(win_height / 2)
			vx: math.cos(angle) * speed
			vy: math.sin(angle) * speed
			life: 1.0
			color: p.art_color
			size: 3 + rand.int_in_range(1, 4) or { 2 }
		}
	}
}

fn (mut app App) apply_cell_action(r int, c int, action CellState) {
	mut p := unsafe { &app.puzzles[app.current_idx] }
	if p.completed || app.game_over {
		return
	}
	if r < 0 || r >= p.height || c < 0 || c >= p.width {
		return
	}

	curr := p.grid[r][c]
	mut target := action

	if curr == action {
		target = .empty
	}

	if app.mode == .strikes && target == .filled && !p.solution[r][c] {
		// Mistake in challenge mode!
		p.grid[r][c] = .crossed
		app.strikes_count++
		app.sound_mgr.play_error_sound()
		if app.strikes_count >= app.max_strikes {
			app.game_over = true
		}
		p.update_status()
		return
	}

	p.grid[r][c] = target

	match target {
		.filled { app.sound_mgr.play_fill_sound() }
		.crossed { app.sound_mgr.play_cross_sound() }
		.empty { app.sound_mgr.play_erase_sound() }
	}

	was_completed := p.completed
	if p.update_status() && !was_completed {
		app.sound_mgr.play_win_sound()
		app.spawn_win_particles()
	}
}

fn (mut app App) calculate_grid_metrics() (int, int, int, int, int) {
	p := app.puzzles[app.current_idx]
	
	// Max clue lengths
	mut max_row_clues := 1
	for row in p.row_clues {
		if row.len > max_row_clues {
			max_row_clues = row.len
		}
	}
	mut max_col_clues := 1
	for col in p.col_clues {
		if col.len > max_col_clues {
			max_col_clues = col.len
		}
	}

	clue_col_w := max_row_clues * 22 + 16
	clue_row_h := max_col_clues * 20 + 16

	mut cell_size := 38
	if p.width == 5 {
		cell_size = 64
	} else if p.width == 10 {
		cell_size = 40
	} else if p.width == 15 {
		cell_size = 28
	}

	total_grid_w := p.width * cell_size
	total_grid_h := p.height * cell_size

	start_x := (win_width - total_grid_w + clue_col_w) / 2
	start_y := 130 + clue_row_h + (560 - clue_row_h - total_grid_h) / 2

	return cell_size, start_x, start_y, clue_col_w, clue_row_h
}

fn (mut app App) get_cell_under_mouse(mx int, my int) (int, int) {
	cell_size, start_x, start_y, _, _ := app.calculate_grid_metrics()
	p := app.puzzles[app.current_idx]

	if mx >= start_x && mx < start_x + p.width * cell_size &&
	   my >= start_y && my < start_y + p.height * cell_size {
		c := (mx - start_x) / cell_size
		r := (my - start_y) / cell_size
		return r, c
	}
	return -1, -1
}

fn (mut app App) render() {
	renderer := &app.renderer
	p := app.puzzles[app.current_idx]

	// Background gradient / dark slate
	set_render_draw_color(renderer, 15, 18, 28, 255)
	render_clear(renderer)

	// Top Title
	draw_text_centered(renderer, win_width / 2, 20, 'PICROSS PRO // NONOGRAM LOGIC', 3, Color{r: 90, g: 180, b: 255})

	// Puzzle Name & Progress
	diff_str := 'PUZZLE ${app.current_idx + 1}/${app.puzzles.len}: ${p.name.to_upper()}'
	draw_text_centered(renderer, win_width / 2, 76, diff_str, 2, Color{r: 255, g: 255, b: 255})

	// Timer / Strikes
	if !p.completed && !app.game_over {
		app.elapsed_sec = int(time.since(app.start_time).seconds())
	}
	time_str := 'TIME: ${app.elapsed_sec / 60:02d}:${app.elapsed_sec % 60:02d}'
	draw_text(renderer, 40, 115, time_str, 2, Color{r: 160, g: 210, b: 255})

	if app.mode == .strikes {
		mut strike_str := 'STRIKES: '
		for i in 0 .. app.max_strikes {
			strike_str += if i < app.strikes_count { 'X ' } else { '- ' }
		}
		draw_text_right(renderer, win_width - 40, 115, strike_str, 2, Color{r: 255, g: 90, b: 90})
	} else {
		draw_text_right(renderer, win_width - 40, 115, 'ZEN LOGIC MODE', 2, Color{r: 100, g: 230, b: 150})
	}

	cell_size, start_x, start_y, _, clue_row_h := app.calculate_grid_metrics()

	// Hover highlight background bars
	if app.hover_r >= 0 && app.hover_c >= 0 && !p.completed {
		// Row highlight
		row_rect := Rect{
			x: start_x
			y: start_y + app.hover_r * cell_size
			w: p.width * cell_size
			h: cell_size
		}
		set_render_draw_color(renderer, 30, 42, 65, 120)
		render_fill_rect(renderer, &row_rect)

		// Column highlight
		col_rect := Rect{
			x: start_x + app.hover_c * cell_size
			y: start_y
			w: cell_size
			h: p.height * cell_size
		}
		render_fill_rect(renderer, &col_rect)
	}

	// Draw Column Clues (Above grid)
	for c in 0 .. p.width {
		clues := p.col_clues[c]
		col_solved := p.col_solved[c]
		clue_color := if col_solved { Color{r: 80, g: 100, b: 120} } else { Color{r: 230, g: 235, b: 245} }

		// Box behind clues
		col_bg := Rect{
			x: start_x + c * cell_size
			y: start_y - clue_row_h
			w: cell_size
			h: clue_row_h
		}
		set_render_draw_color(renderer, 22, 27, 40, 255)
		render_fill_rect(renderer, &col_bg)
		set_render_draw_color(renderer, 45, 55, 80, 255)
		render_draw_rect(renderer, &col_bg)

		for i in 0 .. clues.len {
			clue_val := clues[clues.len - 1 - i]
			num_str := '${clue_val}'
			cx := start_x + c * cell_size + cell_size / 2
			cy := start_y - 20 - i * 18
			draw_text_centered(renderer, cx, cy, num_str, 2, clue_color)
		}
	}

	// Draw Row Clues (Left of grid)
	for r in 0 .. p.height {
		clues := p.row_clues[r]
		row_solved := p.row_solved[r]
		clue_color := if row_solved { Color{r: 80, g: 100, b: 120} } else { Color{r: 230, g: 235, b: 245} }

		// Box behind clues
		row_bg := Rect{
			x: start_x - clues.len * 22 - 12
			y: start_y + r * cell_size
			w: clues.len * 22 + 12
			h: cell_size
		}
		set_render_draw_color(renderer, 22, 27, 40, 255)
		render_fill_rect(renderer, &row_bg)
		set_render_draw_color(renderer, 45, 55, 80, 255)
		render_draw_rect(renderer, &row_bg)

		for i in 0 .. clues.len {
			clue_val := clues[clues.len - 1 - i]
			num_str := '${clue_val}'
			cx := start_x - 14 - i * 22
			cy := start_y + r * cell_size + (cell_size - 16) / 2
			draw_text_centered(renderer, cx, cy, num_str, 2, clue_color)
		}
	}

	// Draw Cells
	for r in 0 .. p.height {
		for c in 0 .. p.width {
			cell_rect := Rect{
				x: start_x + c * cell_size
				y: start_y + r * cell_size
				w: cell_size
				h: cell_size
			}

			// Cell Background
			state := p.grid[r][c]
			match state {
				.filled {
					fill_color := if p.completed { p.art_color } else { Color{r: 70, g: 140, b: 245} }
					set_render_draw_color(renderer, fill_color.r, fill_color.g, fill_color.b, 255)
					render_fill_rect(renderer, &cell_rect)
				}
				.crossed {
					set_render_draw_color(renderer, 25, 30, 45, 255)
					render_fill_rect(renderer, &cell_rect)
					// Draw X cross
					set_render_draw_color(renderer, 220, 80, 80, 255)
					pad := cell_size / 4
					x1 := cell_rect.x + pad
					y1 := cell_rect.y + pad
					x2 := cell_rect.x + cell_size - pad
					y2 := cell_rect.y + cell_size - pad
					render_draw_line(renderer, x1, y1, x2, y2)
					render_draw_line(renderer, x1 + 1, y1, x2 + 1, y2)
					render_draw_line(renderer, x1, y2, x2, y1)
					render_draw_line(renderer, x1 + 1, y2, x2 + 1, y1)
				}
				.empty {
					set_render_draw_color(renderer, 32, 38, 55, 255)
					render_fill_rect(renderer, &cell_rect)
				}
			}

			// Minor grid border
			set_render_draw_color(renderer, 50, 60, 85, 255)
			render_draw_rect(renderer, &cell_rect)
		}
	}

	// Draw 5x5 Major Grid Lines
	for r in 0 .. p.height + 1 {
		if r % 5 == 0 {
			y := start_y + r * cell_size
			set_render_draw_color(renderer, 120, 160, 220, 255)
			render_draw_line(renderer, start_x, y, start_x + p.width * cell_size, y)
			render_draw_line(renderer, start_x, y - 1, start_x + p.width * cell_size, y - 1)
		}
	}
	for c in 0 .. p.width + 1 {
		if c % 5 == 0 {
			x := start_x + c * cell_size
			set_render_draw_color(renderer, 120, 160, 220, 255)
			render_draw_line(renderer, x, start_y, x, start_y + p.height * cell_size)
			render_draw_line(renderer, x - 1, start_y, x - 1, start_y + p.height * cell_size)
		}
	}

	// Keyboard cursor highlight
	if !p.completed && !app.game_over {
		cur_rect := Rect{
			x: start_x + app.cursor_c * cell_size
			y: start_y + app.cursor_r * cell_size
			w: cell_size
			h: cell_size
		}
		set_render_draw_color(renderer, 255, 220, 60, 255)
		render_draw_rect(renderer, &cur_rect)
		inner := Rect{x: cur_rect.x + 1, y: cur_rect.y + 1, w: cur_rect.w - 2, h: cur_rect.h - 2}
		render_draw_rect(renderer, &inner)
	}

	// Completion Banner
	if p.completed {
		banner := Rect{
			x: 0
			y: 690
			w: win_width
			h: 60
		}
		set_render_draw_color(renderer, 15, 65, 40, 230)
		render_fill_rect(renderer, &banner)
		draw_text_centered(renderer, win_width / 2, 708, '*** PUZZLE SOLVED! EXCELLENT WORK! ***', 2, Color{r: 100, g: 255, b: 150})
	} else if app.game_over {
		banner := Rect{
			x: 0
			y: 690
			w: win_width
			h: 60
		}
		set_render_draw_color(renderer, 75, 20, 20, 230)
		render_fill_rect(renderer, &banner)
		draw_text_centered(renderer, win_width / 2, 708, '3 STRIKES! GAME OVER - PRESS [R] TO RETRY', 2, Color{r: 255, g: 100, b: 100})
	}

	// Render UI Buttons
	mx := app.mouse_x
	my := app.mouse_y

	app.btn_prev.render(renderer, mx, my)
	app.btn_next.render(renderer, mx, my)
	app.btn_reset.render(renderer, mx, my)
	app.btn_hint.render(renderer, mx, my)

	app.btn_mode.text = if app.mode == .zen { 'MODE: ZEN [M]' } else { 'MODE: STRIKES [M]' }
	app.btn_mode.render(renderer, mx, my)

	app.btn_sound.text = if app.sound_mgr.sound_enabled { 'SOUND: ON [S]' } else { 'SOUND: OFF [S]' }
	app.btn_sound.render(renderer, mx, my)

	// Render Particles
	for p_idx in 0 .. app.particles.len {
		part := app.particles[p_idx]
		rect := Rect{
			x: int(part.x)
			y: int(part.y)
			w: part.size
			h: part.size
		}
		set_render_draw_color(renderer, part.color.r, part.color.g, part.color.b, u8(part.life * 255.0))
		render_fill_rect(renderer, &rect)
	}

	
	
}

fn (mut app App) update(dt f64) {
	// Update particles
	for i := app.particles.len - 1; i >= 0; i-- {
		mut part := unsafe { &app.particles[i] }
		part.x += part.vx * dt
		part.y += part.vy * dt
		part.life -= dt * 1.2
		if part.life <= 0 {
			app.particles.delete(i)
		}
	}
}


fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.update(f64(dt))
	app.sound_mgr.update()

	app.render()
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
			app.hover_r, app.hover_c = app.get_cell_under_mouse(app.mouse_x, app.mouse_y)
			if app.mouse_down && app.hover_r >= 0 && app.hover_c >= 0 {
				app.apply_cell_action(app.hover_r, app.hover_c, app.drag_fill_mode)
			}
		}
		.mouse_down {
			mx := int(e.mouse_x)
			my := int(e.mouse_y)
			app.mouse_x = mx
			app.mouse_y = my
			if app.btn_prev.is_hovered(mx, my) {
				app.change_puzzle(-1)
			} else if app.btn_next.is_hovered(mx, my) {
				app.change_puzzle(1)
			} else if app.btn_reset.is_hovered(mx, my) {
				mut p := unsafe { &app.puzzles[app.current_idx] }
				p.reset()
				app.strikes_count = 0
				app.game_over = false
				app.start_time = time.now()
				app.sound_mgr.play_erase_sound()
			} else if app.btn_hint.is_hovered(mx, my) {
				mut p := unsafe { &app.puzzles[app.current_idx] }
				_, _, ok := p.use_hint()
				if ok {
					app.sound_mgr.play_fill_sound()
				}
			} else if app.btn_mode.is_hovered(mx, my) {
				app.mode = if app.mode == .zen { .strikes } else { .zen }
				app.strikes_count = 0
				app.game_over = false
				app.sound_mgr.play_fill_sound()
			} else if app.btn_sound.is_hovered(mx, my) {
				app.sound_mgr.toggle_sound()
			} else {
				r, c := app.get_cell_under_mouse(mx, my)
				if r >= 0 && c >= 0 {
					app.mouse_down = true
					app.mouse_button = if e.mouse_button == .left { u8(1) } else { u8(3) }
					app.drag_fill_mode = if e.mouse_button == .left { CellState.filled } else { CellState.crossed }
					app.apply_cell_action(r, c, app.drag_fill_mode)
				}
			}
		}
		.mouse_up {
			app.mouse_down = false
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
					exit(0)
				}
				.f5 {
					mut p := unsafe { &app.puzzles[app.current_idx] }
					p.save_state(app.current_idx)
				}
				.f9 {
					mut p := unsafe { &app.puzzles[app.current_idx] }
					p.load_state(app.current_idx)
				}
				.r {
					mut p := unsafe { &app.puzzles[app.current_idx] }
					p.reset()
					app.strikes_count = 0
					app.game_over = false
					app.start_time = time.now()
					app.sound_mgr.play_erase_sound()
				}
				.h {
					mut p := unsafe { &app.puzzles[app.current_idx] }
					_, _, ok := p.use_hint()
					if ok {
						app.sound_mgr.play_fill_sound()
					}
				}
				.m {
					app.mode = if app.mode == .zen { .strikes } else { .zen }
					app.strikes_count = 0
					app.game_over = false
					app.sound_mgr.play_fill_sound()
				}
				.s {
					app.sound_mgr.toggle_sound()
				}
				.p, .left_bracket {
					app.change_puzzle(-1)
				}
				.n, .right_bracket {
					app.change_puzzle(1)
				}
				.up, .w {
					p := app.puzzles[app.current_idx]
					if app.cursor_r > 0 { app.cursor_r-- } else { app.cursor_r = p.height - 1 }
				}
				.down {
					p := app.puzzles[app.current_idx]
					if app.cursor_r < p.height - 1 { app.cursor_r++ } else { app.cursor_r = 0 }
				}
				.left, .a {
					p := app.puzzles[app.current_idx]
					if app.cursor_c > 0 { app.cursor_c-- } else { app.cursor_c = p.width - 1 }
				}
				.right, .d {
					p := app.puzzles[app.current_idx]
					if app.cursor_c < p.width - 1 { app.cursor_c++ } else { app.cursor_c = 0 }
				}
				.space, .z, .enter {
					app.apply_cell_action(app.cursor_r, app.cursor_c, .filled)
				}
				.x, .f {
					app.apply_cell_action(app.cursor_r, app.cursor_c, .crossed)
				}
				.c {
					app.apply_cell_action(app.cursor_r, app.cursor_c, .empty)
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
		width: win_width
		height: win_height
		resizable:     true
		window_title: 'Picross Pro // Nonogram Logic Grid'
		user_data: &app
		frame_fn: on_frame
		event_fn: on_event
		bg_color: gg.Color{15, 18, 28, 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{ctx: ctx}
	ctx.run()
}
