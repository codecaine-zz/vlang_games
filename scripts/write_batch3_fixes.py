#!/usr/bin/env python3
import os

DST = '/Users/codecaine/vlang_games'

def write_file(game, code):
    p = os.path.join(DST, game, 'main.v')
    with open(p, 'w') as fp:
        fp.write(code)
    print(f"Wrote {game}/main.v")

# 1. lolo
def gen_lolo():
    code = '''module main

import gg
import time

const win_w = 960
const win_h = 720

struct App {
mut:
	ctx              &gg.Context = unsafe { nil }
	renderer         Renderer
	game             Game
	sound_mgr        SoundManager
	btn_editor       Button
	btn_restart      Button
	btn_sound        Button
	btn_prev         Button
	btn_next         Button
	btn_test         Button
	btn_clear        Button
	btn_undo         Button
	btn_level_select Button
	mouse_x          int
	mouse_y          int
	last_tick        i64
}

fn new_app() App {
	return App{
		game:             new_game()
		sound_mgr:        new_sound_manager()
		btn_editor:       Button{ x: 740, y: 30, w: 180, h: 40, text: 'DESIGNER [TAB]' }
		btn_restart:      Button{ x: 740, y: 80, w: 180, h: 40, text: 'RESTART [R]' }
		btn_sound:        Button{ x: 740, y: 130, w: 180, h: 40, text: 'AUDIO: ON [S]' }
		btn_prev:         Button{ x: 740, y: 180, w: 85, h: 40, text: '< PREV' }
		btn_next:         Button{ x: 835, y: 180, w: 85, h: 40, text: 'NEXT >' }
		btn_undo:         Button{ x: 740, y: 230, w: 180, h: 40, text: 'UNDO [U]' }
		btn_level_select: Button{ x: 740, y: 280, w: 180, h: 40, text: 'LEVELS [P]' }
		btn_test:         Button{ x: 740, y: 330, w: 180, h: 40, text: 'PLAYTEST' }
		btn_clear:        Button{ x: 740, y: 380, w: 180, h: 40, text: 'CLEAR' }
		last_tick:        time.ticks()
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

	draw_game(&app.renderer, app.game, app.mouse_x, app.mouse_y, app.btn_editor, app.btn_restart, app.btn_sound, app.btn_prev, app.btn_next, app.btn_test, app.btn_clear, app.btn_undo, app.btn_level_select)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.mouse_move {
			app.mouse_x = int(e.mouse_x)
			app.mouse_y = int(e.mouse_y)
		}
		.mouse_down {
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				if app.btn_editor.contains(mx, my) {
					app.game.toggle_editor_mode()
				} else if app.btn_sound.contains(mx, my) {
					app.sound_mgr.toggle_sound()
				} else if app.btn_undo.contains(mx, my) {
					if app.game.undo() {
						app.sound_mgr.play_undo()
					}
				} else if app.btn_restart.contains(mx, my) {
					app.game.restart_level()
				} else if app.btn_prev.contains(mx, my) {
					if app.game.current_level_idx > 0 {
						app.game.load_level(app.game.current_level_idx - 1)
					}
				} else if app.btn_next.contains(mx, my) {
					app.game.next_level()
				}
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.tab { app.game.toggle_editor_mode() }
				.s { app.sound_mgr.toggle_sound() }
				.u, .z {
					if app.game.undo() {
						app.sound_mgr.play_undo()
					}
				}
				.r { app.game.restart_level() }
				.up, .w { app.game.move_lolo(.up) }
				.down { app.game.move_lolo(.down) }
				.left, .a { app.game.move_lolo(.left) }
				.right, .d { app.game.move_lolo(.right) }
				.space {
					if app.game.fire_magic_shot() {
						app.sound_mgr.play_shot()
					}
				}
				.p, .left_bracket {
					if app.game.current_level_idx > 0 {
						app.game.load_level(app.game.current_level_idx - 1)
					}
				}
				.n, .right_bracket { app.game.next_level() }
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
		window_title: 'Adventures of Lolo - Cyber Puzzle Odyssey'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 5, g: 10, b: 20, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
'''
    write_file('lolo', code)

# 2. mathmunchers
def gen_mathmunchers():
    code = '''module main

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

	app.game.update(f64(dt), &app.sound_mgr)
	app.sound_mgr.update()

	render_mathmunchers_game(&app.renderer, &app.game)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
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
'''
    write_file('mathmunchers', code)

# 3. memorymatch
def gen_memorymatch():
    code = '''module main

import gg
import time

const win_w = 900
const win_h = 650

struct App {
mut:
	ctx       &gg.Context = unsafe { nil }
	renderer  Renderer
	game      MemoryGame
	sound_mgr SoundManager
	hover_idx int = -1
	last_tick i64
}

fn new_app() App {
	return App{
		game:      new_memory_game()
		sound_mgr: new_sound_manager()
		last_tick: time.ticks()
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.game.update(dt)
	app.sound_mgr.update()

	render_memory_match(&app.renderer, &app.game, win_w, win_h, app.hover_idx)
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.mouse_move {
			mx := int(e.mouse_x)
			my := int(e.mouse_y)
			app.hover_idx = get_card_index_at(mx, my, &app.game, win_w, win_h)
		}
		.mouse_down {
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				if app.game.state == .game_won {
					app.game.reset_game()
				} else {
					if my < 54 {
						if mx >= 220 && mx <= 360 {
							app.game.toggle_grid_mode()
							app.sound_mgr.play_click_sound()
						} else if mx >= 380 && mx <= 490 {
							app.sound_mgr.toggle_sound()
						} else if mx >= win_w - 140 && mx <= win_w - 20 {
							app.game.reset_game()
							app.sound_mgr.play_click_sound()
						}
					} else {
						clicked_idx := get_card_index_at(mx, my, &app.game, win_w, win_h)
						if clicked_idx >= 0 {
							_, ev := app.game.flip_card(clicked_idx)
							if ev.card_flipped {
								app.sound_mgr.play_flip_sound()
							}
							if ev.cards_matched {
								app.sound_mgr.play_match_sound(ev.combo_level)
							}
							if ev.cards_mismatch {
								app.sound_mgr.play_mismatch_sound()
							}
							if ev.game_won {
								app.sound_mgr.play_win_fanfare()
							}
						}
					}
				}
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.r { app.game.reset_game() }
				.g { app.game.toggle_grid_mode() }
				.s { app.sound_mgr.toggle_sound() }
				.space {
					if app.game.state == .game_won {
						app.game.reset_game()
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
		width:        win_w
		height:       win_h
		window_title: 'Memory Match Pro - 3D Card Flip Pair Memory Training'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 15, g: 20, b: 35, a: 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{
		ctx:    ctx
		width:  win_w
		height: win_h
	}
	ctx.run()
}
'''
    write_file('memorymatch', code)

# 4. minesweeper
def gen_minesweeper():
    code = '''module main

import gg
import time

const win_width = 860
const win_height = 680

struct Button {
	x            int
	y            int
	w            int
	h            int
	bg_color     Color = Color{r: 40, g: 50, b: 70, a: 255}
	hover_color  Color = Color{r: 60, g: 80, b: 110, a: 255}
	text_color   Color = Color{r: 255, g: 255, b: 255, a: 255}
	border_color Color = Color{r: 80, g: 110, b: 150, a: 255}
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

	draw_text(renderer, b.x + 10, b.y + 10, b.text, 2, b.text_color)
}

struct App {
mut:
	ctx          &gg.Context = unsafe { nil }
	renderer     Renderer
	game         Minesweeper
	sound_mgr    SoundManager
	tex_mgr      MinesweeperTextureManager
	btn_beg      Button
	btn_int      Button
	btn_exp      Button
	btn_theme    Button
	btn_sound    Button
	btn_reset    Button
	mouse_x      int
	mouse_y      int
	mouse_down   bool
	cell_size    int = 32
	face_rect    Rect
	board_x      int
	board_y      int
	last_tick    i64
}

fn new_app() App {
	mut app := App{
		game:      new_minesweeper(.beginner)
		sound_mgr: new_sound_manager()
		btn_beg:   Button{ x: 20, y: 620, w: 125, h: 38, text: '1: BEG' }
		btn_int:   Button{ x: 155, y: 620, w: 125, h: 38, text: '2: INT' }
		btn_exp:   Button{ x: 290, y: 620, w: 125, h: 38, text: '3: EXP' }
		btn_theme: Button{ x: 425, y: 620, w: 135, h: 38, text: 'THEME [T]' }
		btn_sound: Button{ x: 570, y: 620, w: 135, h: 38, text: 'SOUND [S]' }
		btn_reset: Button{ x: 715, y: 620, w: 125, h: 38, text: 'RESET [R]' }
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
	app.face_rect = Rect{ x: win_width / 2 - 20, y: 80, w: 40, h: 40 }
}

fn (mut app App) restart_game() {
	app.game.reset()
	app.recalc_layout()
}

fn (mut app App) change_diff(diff Difficulty) {
	app.game.change_difficulty(diff)
	app.recalc_layout()
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

	app.game.update(f64(dt))
	app.sound_mgr.update()

	app.render_minesweeper()
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn (mut app App) render_minesweeper() {
	r := &app.renderer
	theme := get_theme(app.game.theme_idx)

	bg_col := theme.bg_color
	set_render_draw_color(r, bg_col.r, bg_col.g, bg_col.b, bg_col.a)
	render_clear(r)

	panel_bg := theme.panel_bg
	light_bev := theme.light_bevel
	dark_bev := theme.dark_bevel

	draw_top_bar(r, 0, 0, win_width, 60, theme)

	face_icon := match app.game.face_state {
		.normal { ':-)' }
		.worried { ':-o' }
		.won { 'B-)' }
		.lost { 'X-(' }
	}
	draw_bevel_rect(r, app.face_rect.x, app.face_rect.y, app.face_rect.w, app.face_rect.h, true, panel_bg, light_bev, dark_bev, 2)
	draw_text_centered(r, app.face_rect.x + 20, app.face_rect.y + 10, face_icon, 2, Color{r: 255, g: 220, b: 0, a: 255})

	frame_w := app.game.cols * app.cell_size + 20
	frame_h := app.game.rows * app.cell_size + 80
	frame_x := (win_width - frame_w) / 2
	frame_y := 70

	draw_bevel_rect(r, frame_x, frame_y, frame_w, frame_h, true, panel_bg, light_bev, dark_bev, 4)

	grid_x := frame_x + 10
	grid_y := frame_y + 66
	for row in 0 .. app.game.rows {
		for col in 0 .. app.game.cols {
			cx := grid_x + col * app.cell_size
			cy := grid_y + row * app.cell_size
			cell := app.game.board[row][col]

			if cell.revealed {
				if cell.has_mine {
					draw_bevel_rect(r, cx, cy, app.cell_size, app.cell_size, false, Color{r: 240, g: 50, b: 50, a: 255}, light_bev, dark_bev, 1)
					draw_mine_icon(r, cx + app.cell_size / 2, cy + app.cell_size / 2, app.cell_size - 8, true, app.tex_mgr.sprite_texture)
				} else {
					draw_bevel_rect(r, cx, cy, app.cell_size, app.cell_size, false, panel_bg, light_bev, dark_bev, 1)
					if cell.neighbor_mines > 0 {
						draw_text_centered(r, cx + app.cell_size / 2, cy + 4, '${cell.neighbor_mines}', 2, Color{r: 30, g: 120, b: 255, a: 255})
					}
				}
			} else {
				draw_bevel_rect(r, cx, cy, app.cell_size, app.cell_size, true, panel_bg, light_bev, dark_bev, 2)
				if cell.flagged {
					draw_flag_icon(r, cx + app.cell_size / 2, cy + app.cell_size / 2, app.cell_size - 8, app.tex_mgr.sprite_texture)
				}
			}
		}
	}

	app.btn_beg.render(r, app.mouse_x, app.mouse_y)
	app.btn_int.render(r, app.mouse_x, app.mouse_y)
	app.btn_exp.render(r, app.mouse_x, app.mouse_y)
	app.btn_theme.render(r, app.mouse_x, app.mouse_y)
	app.btn_sound.render(r, app.mouse_x, app.mouse_y)
	app.btn_reset.render(r, app.mouse_x, app.mouse_y)
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	match e.typ {
		.mouse_move {
			app.mouse_x = int(e.mouse_x)
			app.mouse_y = int(e.mouse_y)
		}
		.mouse_down {
			mx := int(e.mouse_x)
			my := int(e.mouse_y)
			if e.mouse_button == .left {
				if app.btn_beg.contains(mx, my) {
					app.change_diff(.beginner)
				} else if app.btn_int.contains(mx, my) {
					app.change_diff(.intermediate)
				} else if app.btn_exp.contains(mx, my) {
					app.change_diff(.expert)
				} else if app.btn_theme.contains(mx, my) {
					app.game.cycle_theme()
				} else if app.btn_sound.contains(mx, my) {
					muted := !app.sound_mgr.toggle_sound()
					app.btn_sound.text = if muted { 'SOUND: OFF' } else { 'SOUND: ON' }
				} else if app.btn_reset.contains(mx, my) || (mx >= app.face_rect.x && mx <= app.face_rect.x + app.face_rect.w && my >= app.face_rect.y && my <= app.face_rect.y + app.face_rect.h) {
					app.restart_game()
				} else {
					frame_w := app.game.cols * app.cell_size + 20
					frame_x := (win_width - frame_w) / 2
					frame_y := 70
					grid_x := frame_x + 10
					grid_y := frame_y + 66
					if mx >= grid_x && mx < grid_x + app.game.cols * app.cell_size && my >= grid_y && my < grid_y + app.game.rows * app.cell_size {
						col := (mx - grid_x) / app.cell_size
						row := (my - grid_y) / app.cell_size
						app.game.reveal_cell(row, col)
					}
				}
			} else if e.mouse_button == .right {
				frame_w := app.game.cols * app.cell_size + 20
				frame_x := (win_width - frame_w) / 2
				frame_y := 70
				grid_x := frame_x + 10
				grid_y := frame_y + 66
				if mx >= grid_x && mx < grid_x + app.game.cols * app.cell_size && my >= grid_y && my < grid_y + app.game.rows * app.cell_size {
					col := (mx - grid_x) / app.cell_size
					row := (my - grid_y) / app.cell_size
					app.game.toggle_flag(row, col)
				}
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.r { app.restart_game() }
				._1 { app.change_diff(.beginner) }
				._2 { app.change_diff(.intermediate) }
				._3 { app.change_diff(.expert) }
				.t { app.game.cycle_theme() }
				.s {
					muted := !app.sound_mgr.toggle_sound()
					app.btn_sound.text = if muted { 'SOUND: OFF' } else { 'SOUND: ON' }
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
'''
    write_file('minesweeper', code)

# 5. paneldepon
def gen_paneldepon():
    code = '''module main

import gg
import math
import rand
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
				.escape { exit(0) }
				.r { app.game = new_panel_game() }
				.p { app.paused = !app.paused }
				.m { app.sound_mgr.toggle_sound() }
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
'''
    write_file('paneldepon', code)

gen_lolo()
gen_mathmunchers()
gen_memorymatch()
gen_minesweeper()
gen_paneldepon()
print("All 5 custom generators completed.")
