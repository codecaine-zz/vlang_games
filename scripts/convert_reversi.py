#!/usr/bin/env python3
import os
import re

with open('/tmp/vlang_sdl2_games/reversi/main.v') as f:
    src = f.read()

# Find where fn main() starts
idx = src.find('fn main()')
pre_main = src[:idx]

# Clean up imports and types in pre_main
pre_main = re.sub(r'import\s+sdl\b', 'import gg\nimport time', pre_main)
pre_main = re.sub(r'&sdl\.Window', 'voidptr', pre_main)
pre_main = re.sub(r'&sdl\.Renderer', '&Renderer', pre_main)
pre_main = re.sub(r'sdl\.Rect\b', 'Rect', pre_main)
pre_main = re.sub(r'sdl\.Color\b', 'Color', pre_main)
pre_main = re.sub(r'sdl\.Point\b', 'Point', pre_main)
pre_main = re.sub(r'sdl\.set_render_draw_color\s*\(', 'set_render_draw_color(', pre_main)
pre_main = re.sub(r'sdl\.render_fill_rect\s*\(', 'render_fill_rect(', pre_main)
pre_main = re.sub(r'sdl\.render_draw_rect\s*\(', 'render_draw_rect(', pre_main)
pre_main = re.sub(r'sdl\.render_draw_line\s*\(', 'render_draw_line(', pre_main)
pre_main = re.sub(r'sdl\.render_draw_point\s*\(', 'render_draw_point(', pre_main)
pre_main = re.sub(r'sdl\.render_clear\s*\(', 'render_clear(', pre_main)
pre_main = re.sub(r'sdl\.render_copy_ex\s*\(', 'render_copy_ex(', pre_main)
pre_main = re.sub(r'sdl\.render_copy\s*\(', 'render_copy(', pre_main)
pre_main = re.sub(r'sdl\.render_present\s*\(.*?\)', '', pre_main)
pre_main = re.sub(r'sdl\.get_ticks\s*\(\)', 'u32(time.ticks())', pre_main)
pre_main = re.sub(r'sdl\.delay\s*\(.*?\)', '', pre_main)

# App struct modifications: replace window/renderer with gg ctx/renderer and last_tick
pre_main = re.sub(r'window\s+voidptr\s*=\s*unsafe\s*\{\s*nil\s*\}', 'ctx       &gg.Context = unsafe { nil }', pre_main)
pre_main = re.sub(r'renderer\s+&Renderer\s*=\s*unsafe\s*\{\s*nil\s*\}', 'renderer  Renderer\n\tlast_tick i64', pre_main)

# In new_app:
pre_main = re.sub(r'return App\{', 'return App{\n\t\tlast_tick: time.ticks()', pre_main)

post_main = '''
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
'''

full_code = pre_main + post_main
with open('/Users/codecaine/vlang_games/reversi/main.v', 'w') as f:
    f.write(full_code)
print("Wrote reversi/main.v")
