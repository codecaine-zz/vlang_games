module main

import math
import os
import rand
import gg
import time

const win_width = 1000
const win_height = 840

const cell_size = 70
const grid_w = 8 * cell_size
const grid_h = 8 * cell_size
const board_x = 70
const board_y = 140

enum GameMode {
	pve
	pvp
}

struct AnimFlip {
mut:
	r         int
	c         int
	from_p    int
	to_p      int
	progress  f64 // 0.0 to 1.0
	speed     f64
	active    bool
}

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	last_tick i64
	mouse_x   int
	mouse_y   int
	sound_mgr     SoundManager
	board         Board
	mode          GameMode   = .pve
	diff          Difficulty = .tactician
	ai_player     int        = piece_white
	human_player  int        = piece_black
	hover_r       int        = -1
	hover_c       int        = -1
	ai_timer      u32
	ai_thinking   bool
	flips         []AnimFlip
	btn_reset     Button
	btn_undo      Button
	btn_mode      Button
	btn_diff      Button
	btn_sound     Button
	btn_hint      Button
	show_hint     bool
	hint_move     Point = Point{r: -1, c: -1}
}

fn new_app() App {
	btn_y := 765

	return App{
		last_tick: time.ticks()
		sound_mgr: new_sound_manager()
		board:     new_board()
		btn_reset: Button{
			x: 25, y: btn_y, w: 145, h: 42, text: 'RESET [R]',
			bg_color: Color{r: 35, g: 45, b: 65},
			hover_color: Color{r: 55, g: 70, b: 100},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 80, g: 105, b: 145},
		}
		btn_undo:  Button{
			x: 185, y: btn_y, w: 145, h: 42, text: 'UNDO [U]',
			bg_color: Color{r: 35, g: 45, b: 65},
			hover_color: Color{r: 55, g: 70, b: 100},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 80, g: 105, b: 145},
		}
		btn_hint:  Button{
			x: 345, y: btn_y, w: 140, h: 42, text: 'HINT [H]',
			bg_color: Color{r: 40, g: 60, b: 50},
			hover_color: Color{r: 60, g: 90, b: 75},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 80, g: 135, b: 110},
		}
		btn_mode:  Button{
			x: 500, y: btn_y, w: 155, h: 42, text: '1P (AI) [M]',
			bg_color: Color{r: 50, g: 45, b: 75},
			hover_color: Color{r: 75, g: 65, b: 115},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 110, g: 95, b: 165},
		}
		btn_diff:  Button{
			x: 670, y: btn_y, w: 155, h: 42, text: 'DIFF: MED',
			bg_color: Color{r: 60, g: 45, b: 35},
			hover_color: Color{r: 90, g: 65, b: 50},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 135, g: 95, b: 70},
		}
		btn_sound: Button{
			x: 840, y: btn_y, w: 135, h: 42, text: 'SOUND: ON',
			bg_color: Color{r: 35, g: 50, b: 70},
			hover_color: Color{r: 55, g: 80, b: 110},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 80, g: 115, b: 160},
		}
	}
}

fn (mut app App) handle_move(r int, c int) bool {
	if app.board.game_over || app.ai_thinking {
		return false
	}
	current_p := app.board.current_player
	flips, ok := app.board.make_move(r, c)
	if !ok {
		app.sound_mgr.play_flip_sound()
		return false
	}

	app.show_hint = false
	app.sound_mgr.play_drop_sound()

	// Trigger 3D flip animation for all flipped pieces
	for pt in flips {
		app.flips << AnimFlip{
			r:        pt.r
			c:        pt.c
			from_p:   opponent_of(current_p)
			to_p:     current_p
			progress: 0.0
			speed:    4.0 + rand.f64() * 2.0
			active:   true
		}
	}

	if app.board.game_over {
		app.sound_mgr.play_win_sound()
	}

	return true
}

fn (mut app App) update(dt f64) {
	// Update flip animations
	for i := app.flips.len - 1; i >= 0; i-- {
		mut f := unsafe { &app.flips[i] }
		f.progress += dt * f.speed
		if f.progress >= 1.0 {
			app.flips.delete(i)
		}
	}

	// AI turn logic
	if app.mode == .pve && !app.board.game_over && app.board.current_player == app.ai_player {
		if !app.ai_thinking {
			app.ai_thinking = true
			app.ai_timer = u32(time.ticks()) + 450 // slight natural pause
		} else if u32(time.ticks()) >= app.ai_timer {
			app.ai_thinking = false
			best_move := get_ai_best_move(&app.board, app.ai_player, app.diff)
			if best_move.r >= 0 && best_move.c >= 0 {
				app.handle_move(best_move.r, best_move.c)
			}
		}
	}
}

fn draw_circle_disc(renderer &Renderer, cx int, cy int, radius int, color Color, scale_y f64) {
	ry := int(f64(radius) * math.abs(scale_y))
	if ry <= 0 {
		return
	}

	set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	for y := -ry; y <= ry; y++ {
		norm_y := f64(y) / f64(ry)
		max_x := int(f64(radius) * math.sqrt(math.max(0.0, 1.0 - norm_y * norm_y)))
		rect := Rect{
			x: cx - max_x
			y: cy + y
			w: max_x * 2
			h: 1
		}
		render_fill_rect(renderer, &rect)
	}

	// Gloss shine highlight on top half
	if color.r > 200 {
		// White disc subtle outer ring
		set_render_draw_color(renderer, 180, 185, 195, 255)
		render_draw_line(renderer, cx - radius + 2, cy, cx + radius - 2, cy)
	} else {
		// Black disc sheen
		set_render_draw_color(renderer, 65, 75, 95, 255)
		shine_rect := Rect{
			x: cx - radius / 3
			y: cy - ry / 2
			w: radius * 2 / 3
			h: ry / 3
		}
		if shine_rect.h > 0 {
			render_fill_rect(renderer, &shine_rect)
		}
	}
}

fn (mut app App) render() {
	renderer := app.renderer

	// Deep rich background
	set_render_draw_color(renderer, 16, 20, 30, 255)
	render_clear(renderer)

	// Top Title
	draw_text_centered(renderer, win_width / 2, 25, 'REVERSI // OTHELLO MASTER', 3, Color{r: 90, g: 190, b: 255})
	draw_text_centered(renderer, win_width / 2, 65, 'CLASSIC 8X8 STRATEGY BOARD GAME', 2, Color{r: 160, g: 180, b: 210})

	// Outer Wood Frame
	frame_pad := 24
	frame_rect := Rect{
		x: board_x - frame_pad
		y: board_y - frame_pad
		w: grid_w + frame_pad * 2
		h: grid_h + frame_pad * 2
	}
	set_render_draw_color(renderer, 70, 42, 25, 255) // Mahogany wood
	render_fill_rect(renderer, &frame_rect)
	set_render_draw_color(renderer, 105, 65, 40, 255)
	render_draw_rect(renderer, &frame_rect)

	// Green Felt Playfield
	felt_rect := Rect{
		x: board_x
		y: board_y
		w: grid_w
		h: grid_h
	}
	set_render_draw_color(renderer, 24, 115, 60, 255)
	render_fill_rect(renderer, &felt_rect)

	// Coordinate Labels (A-H & 1-8)
	col_names := ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']
	for i in 0 .. 8 {
		col_char := col_names[i]
		cx := board_x + i * cell_size + cell_size / 2
		draw_text_centered(renderer, cx, board_y - 18, col_char, 2, Color{r: 220, g: 200, b: 170})
		draw_text_centered(renderer, cx, board_y + grid_h + 6, col_char, 2, Color{r: 220, g: 200, b: 170})

		row_char := '${i + 1}'
		cy := board_y + i * cell_size + (cell_size - 16) / 2
		draw_text_centered(renderer, board_x - 14, cy, row_char, 2, Color{r: 220, g: 200, b: 170})
		draw_text_centered(renderer, board_x + grid_w + 14, cy, row_char, 2, Color{r: 220, g: 200, b: 170})
	}

	// Grid Lines
	set_render_draw_color(renderer, 15, 75, 40, 255)
	for i in 0 .. 9 {
		// Vertical lines
		x := board_x + i * cell_size
		render_draw_line(renderer, x, board_y, x, board_y + grid_h)
		// Horizontal lines
		y := board_y + i * cell_size
		render_draw_line(renderer, board_x, y, board_x + grid_w, y)
	}

	// Star / Landmark dots
	star_dots := [Point{r: 2, c: 2}, Point{r: 2, c: 6}, Point{r: 6, c: 2}, Point{r: 6, c: 6}]
	for pt in star_dots {
		sx := board_x + pt.c * cell_size
		sy := board_y + pt.r * cell_size
		dot_rect := Rect{x: sx - 3, y: sy - 3, w: 6, h: 6}
		set_render_draw_color(renderer, 12, 50, 28, 255)
		render_fill_rect(renderer, &dot_rect)
	}

	// Legal Move Markers
	valid_moves := app.board.get_valid_moves(app.board.current_player)
	is_human_turn := (app.mode == .pvp) || (app.mode == .pve && app.board.current_player == app.human_player)

	if !app.board.game_over && is_human_turn {
		for pt in valid_moves {
			cx := board_x + pt.c * cell_size + cell_size / 2
			cy := board_y + pt.r * cell_size + cell_size / 2
			dot_r := 7
			dot_rect := Rect{x: cx - dot_r, y: cy - dot_r, w: dot_r * 2, h: dot_r * 2}
			set_render_draw_color(renderer, 60, 220, 110, 180)
			render_fill_rect(renderer, &dot_rect)
		}
	}

	// Hint move indicator
	if app.show_hint && app.hint_move.r >= 0 {
		hx := board_x + app.hint_move.c * cell_size
		hy := board_y + app.hint_move.r * cell_size
		h_rect := Rect{x: hx + 2, y: hy + 2, w: cell_size - 4, h: cell_size - 4}
		set_render_draw_color(renderer, 255, 220, 50, 255)
		render_draw_rect(renderer, &h_rect)
	}

	// Hover highlight
	if app.hover_r >= 0 && app.hover_c >= 0 && !app.board.game_over {
		hx := board_x + app.hover_c * cell_size
		hy := board_y + app.hover_r * cell_size
		h_rect := Rect{x: hx + 1, y: hy + 1, w: cell_size - 2, h: cell_size - 2}
		set_render_draw_color(renderer, 255, 255, 255, 60)
		render_draw_rect(renderer, &h_rect)
	}

	// Render Discs
	for r in 0 .. board_size {
		for c in 0 .. board_size {
			p := app.board.cells[r][c]
			if p == piece_empty {
				continue
			}

			// Check if disc is in flipping animation
			mut scale_y := 1.0
			mut disc_p := p
			for f in app.flips {
				if f.r == r && f.c == c && f.active {
					// Cosine flip progression
					scale_y = math.cos(f.progress * math.pi)
					disc_p = if scale_y >= 0.0 { f.to_p } else { f.from_p }
					break
				}
			}

			color := if disc_p == piece_black { Color{r: 25, g: 25, b: 30} } else { Color{r: 240, g: 242, b: 245} }
			cx := board_x + c * cell_size + cell_size / 2
			cy := board_y + r * cell_size + cell_size / 2
			draw_circle_disc(renderer, cx, cy, cell_size / 2 - 6, color, scale_y)

			// Highlight last move with golden center dot
			if app.board.last_move.r == r && app.board.last_move.c == c {
				set_render_draw_color(renderer, 255, 215, 0, 255)
				center_dot := Rect{x: cx - 4, y: cy - 4, w: 8, h: 8}
				render_fill_rect(renderer, &center_dot)
			}
		}
	}

	// Right HUD Panel (Scores & Status)
	hud_x := 680
	hud_y := 140

	// Black Player Score Card
	b_active := app.board.current_player == piece_black && !app.board.game_over
	b_card := Rect{x: hud_x, y: hud_y, w: 260, h: 100}
	set_render_draw_color(renderer, if b_active { u8(35) } else { u8(22) }, if b_active { u8(45) } else { u8(26) }, if b_active { u8(65) } else { u8(38) }, 255)
	render_fill_rect(renderer, &b_card)
	set_render_draw_color(renderer, if b_active { u8(90) } else { u8(50) }, if b_active { u8(130) } else { u8(60) }, if b_active { u8(200) } else { u8(90) }, 255)
	render_draw_rect(renderer, &b_card)

	draw_circle_disc(renderer, hud_x + 40, hud_y + 50, 22, Color{r: 25, g: 25, b: 30}, 1.0)
	draw_text(renderer, hud_x + 75, hud_y + 25, 'BLACK (P1)', 2, Color{r: 255, g: 255, b: 255})
	draw_text(renderer, hud_x + 75, hud_y + 55, 'DISCS: ${app.board.black_count}', 2, Color{r: 100, g: 200, b: 255})
	if b_active {
		draw_text_right(renderer, hud_x + 245, hud_y + 12, 'TURN', 1, Color{r: 80, g: 255, b: 120})
	}

	// White Player Score Card
	w_active := app.board.current_player == piece_white && !app.board.game_over
	w_card := Rect{x: hud_x, y: hud_y + 120, w: 260, h: 100}
	set_render_draw_color(renderer, if w_active { u8(35) } else { u8(22) }, if w_active { u8(45) } else { u8(26) }, if w_active { u8(65) } else { u8(38) }, 255)
	render_fill_rect(renderer, &w_card)
	set_render_draw_color(renderer, if w_active { u8(90) } else { u8(50) }, if w_active { u8(130) } else { u8(60) }, if w_active { u8(200) } else { u8(90) }, 255)
	render_draw_rect(renderer, &w_card)

	draw_circle_disc(renderer, hud_x + 40, hud_y + 170, 22, Color{r: 240, g: 242, b: 245}, 1.0)
	w_title := if app.mode == .pve { 'WHITE (AI)' } else { 'WHITE (P2)' }
	draw_text(renderer, hud_x + 75, hud_y + 145, w_title, 2, Color{r: 255, g: 255, b: 255})
	draw_text(renderer, hud_x + 75, hud_y + 175, 'DISCS: ${app.board.white_count}', 2, Color{r: 100, g: 200, b: 255})
	if w_active {
		status_str := if app.ai_thinking { 'THINKING...' } else { 'TURN' }
		draw_text_right(renderer, hud_x + 245, hud_y + 132, status_str, 1, Color{r: 255, g: 215, b: 60})
	}

	// Status / Game Over Box
	status_card := Rect{x: hud_x, y: hud_y + 245, w: 260, h: 140}
	set_render_draw_color(renderer, 22, 26, 38, 255)
	render_fill_rect(renderer, &status_card)
	set_render_draw_color(renderer, 55, 65, 95, 255)
	render_draw_rect(renderer, &status_card)

	draw_text_centered(renderer, hud_x + 130, hud_y + 260, 'MATCH STATUS', 2, Color{r: 160, g: 190, b: 230})

	if app.board.game_over {
		if app.board.winner == piece_black {
			draw_text_centered(renderer, hud_x + 130, hud_y + 300, 'BLACK WINS!', 2, Color{r: 100, g: 255, b: 140})
		} else if app.board.winner == piece_white {
			draw_text_centered(renderer, hud_x + 130, hud_y + 300, 'WHITE WINS!', 2, Color{r: 255, g: 220, b: 100})
		} else {
			draw_text_centered(renderer, hud_x + 130, hud_y + 300, 'TIE GAME / DRAW!', 2, Color{r: 200, g: 200, b: 255})
		}
		draw_text_centered(renderer, hud_x + 130, hud_y + 340, 'PRESS [R] TO PLAY AGAIN', 1, Color{r: 255, g: 255, b: 255})
	} else {
		valid_cnt := valid_moves.len
		draw_text_centered(renderer, hud_x + 130, hud_y + 300, 'VALID MOVES: ${valid_cnt}', 2, Color{r: 240, g: 245, b: 255})
		curr_name := if app.board.current_player == piece_black { 'BLACK' } else { 'WHITE' }
		draw_text_centered(renderer, hud_x + 130, hud_y + 335, '${curr_name} TO MOVE', 2, Color{r: 100, g: 200, b: 255})
	}

	// Instructions box
	inst_card := Rect{x: hud_x, y: hud_y + 405, w: 260, h: 175}
	set_render_draw_color(renderer, 20, 24, 35, 255)
	render_fill_rect(renderer, &inst_card)
	set_render_draw_color(renderer, 45, 55, 80, 255)
	render_draw_rect(renderer, &inst_card)

	draw_text_centered(renderer, hud_x + 130, hud_y + 418, 'CONTROLS', 2, Color{r: 200, g: 215, b: 240})
	draw_text(renderer, hud_x + 16, hud_y + 448, '- Click: Place Disc', 1, Color{r: 180, g: 195, b: 220})
	draw_text(renderer, hud_x + 16, hud_y + 472, '- U: Undo Previous Move', 1, Color{r: 180, g: 195, b: 220})
	draw_text(renderer, hud_x + 16, hud_y + 496, '- H: Show Best Hint', 1, Color{r: 180, g: 195, b: 220})
	draw_text(renderer, hud_x + 16, hud_y + 520, '- M: 1P AI vs 2P Local', 1, Color{r: 180, g: 195, b: 220})
	draw_text(renderer, hud_x + 16, hud_y + 544, '- D: Cycle AI Difficulty', 1, Color{r: 180, g: 195, b: 220})

	// Render Buttons
	mx := app.mouse_x
	my := app.mouse_y

	app.btn_reset.render(renderer, mx, my)
	app.btn_undo.render(renderer, mx, my)
	app.btn_hint.render(renderer, mx, my)

	app.btn_mode.text = if app.mode == .pve { '1P (AI) [M]' } else { '2P LOCAL [M]' }
	app.btn_mode.render(renderer, mx, my)

	diff_text := match app.diff {
		.novice { 'DIFF: EASY [D]' }
		.tactician { 'DIFF: MED [D]' }
		.grandmaster { 'DIFF: HARD [D]' }
	}
	app.btn_diff.text = diff_text
	app.btn_diff.render(renderer, mx, my)

	app.btn_sound.text = if app.sound_mgr.sound_enabled { 'SOUND [S]' } else { 'MUTED [S]' }
	app.btn_sound.render(renderer, mx, my)
}

fn (mut app App) get_cell_under_mouse(mx int, my int) (int, int) {
	if mx >= board_x && mx < board_x + grid_w && my >= board_y && my < board_y + grid_h {
		c := (mx - board_x) / cell_size
		r := (my - board_y) / cell_size
		return r, c
	}
	return -1, -1
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
			app.hover_r, app.hover_c = app.get_cell_under_mouse(int(e.mouse_x), int(e.mouse_y))
		}
		.mouse_down {
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				if app.btn_reset.is_hovered(mx, my) {
					app.board = new_board()
					app.flips.clear()
					app.show_hint = false
					app.ai_thinking = false
					app.sound_mgr.play_drop_sound()
				} else if app.btn_undo.is_hovered(mx, my) {
					if app.board.undo() {
						if app.mode == .pve && app.board.current_player == app.ai_player {
							app.board.undo()
						}
						app.flips.clear()
						app.show_hint = false
						app.sound_mgr.play_drop_sound()
					}
				} else if app.btn_hint.is_hovered(mx, my) {
					best := get_ai_best_move(&app.board, app.board.current_player, .grandmaster)
					app.hint_move = best
					app.show_hint = true
					app.sound_mgr.play_drop_sound()
				} else if app.btn_mode.is_hovered(mx, my) {
					app.mode = if app.mode == .pve { .pvp } else { .pve }
					app.sound_mgr.play_drop_sound()
				} else if app.btn_diff.is_hovered(mx, my) {
					app.diff = match app.diff {
						.novice { .tactician }
						.tactician { .grandmaster }
						.grandmaster { .novice }
					}
					app.sound_mgr.play_drop_sound()
				} else if app.btn_sound.is_hovered(mx, my) {
					app.sound_mgr.toggle_sound()
				} else {
					r, c := app.get_cell_under_mouse(mx, my)
					if r >= 0 && c >= 0 {
						app.handle_move(r, c)
					}
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
				.r {
					app.board = new_board()
					app.flips.clear()
					app.show_hint = false
					app.ai_thinking = false
					app.sound_mgr.play_drop_sound()
				}
				.u {
					if app.board.undo() {
						if app.mode == .pve && app.board.current_player == app.ai_player {
							app.board.undo()
						}
						app.flips.clear()
						app.show_hint = false
						app.sound_mgr.play_drop_sound()
					}
				}
				.h {
					best := get_ai_best_move(&app.board, app.board.current_player, .grandmaster)
					app.hint_move = best
					app.show_hint = true
					app.sound_mgr.play_drop_sound()
				}
				.m {
					app.mode = if app.mode == .pve { .pvp } else { .pve }
					app.sound_mgr.play_drop_sound()
				}
				.d {
					app.diff = match app.diff {
						.novice { .tactician }
						.tactician { .grandmaster }
						.grandmaster { .novice }
					}
					app.sound_mgr.play_drop_sound()
				}
				.s {
					app.sound_mgr.toggle_sound()
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
		window_title: 'Reversi // Othello Master'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 16, g: 20, b: 30, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_width
		height: win_height
	}
	ctx.run()
}
