#!/usr/bin/env python3
import os
import re

with open('/tmp/vlang_sdl2_games/samegame/main.v') as f:
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
pre_main = re.sub(r'renderer\s+&Renderer\s*=\s*unsafe\s*\{\s*nil\s*\}', 'renderer  Renderer\n\tlast_tick i64\n\tmouse_x   int\n\tmouse_y   int', pre_main)

# Replace sdl.get_mouse_state
pre_main = re.sub(r'mut\s+mx,\s*mut\s+my\s*:=\s*0,\s*0\s*\n\s*sdl\.get_mouse_state\(&mx,\s*&my\)', 'mx := app.mouse_x\n\tmy := app.mouse_y', pre_main)
pre_main = re.sub(r'prod_fx_render\s*\(renderer\)', '', pre_main)

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
			app.mouse_x = int(e.mouse_x)
			app.mouse_y = int(e.mouse_y)
			r, c := app.get_cell_under_mouse(app.mouse_x, app.mouse_y)
			app.game.update_hover(r, c)
		}
		.mouse_down {
			if e.mouse_button == .left {
				mx := int(e.mouse_x)
				my := int(e.mouse_y)
				if app.btn_reset.is_hovered(mx, my) {
					app.game = new_same_game(app.game.mode)
				} else if app.btn_sound.is_hovered(mx, my) {
					app.sound_mgr.toggle_sound()
				} else if app.btn_mode.is_hovered(mx, my) {
					new_mode := if app.game.mode == .puzzle { GameMode.arcade_collapse } else { GameMode.puzzle }
					app.game = new_same_game(new_mode)
				} else {
					r, c := app.get_cell_under_mouse(mx, my)
					if r >= 0 && c >= 0 {
						cluster := app.game.find_cluster(r, c)
						if cluster.len >= 2 {
							col := app.game.grid[r][c]
							cleared := app.game.click_cell(r, c)
							if cleared > 0 {
								app.sound_mgr.play_shatter_sound(cleared)
								app.shake_timer = 0.15
								for p in cluster {
									cx := board_x + p.c * cell_size + cell_size / 2
									cy := board_y + p.r * cell_size + cell_size / 2
									app.spawn_burst(cx, cy, col)
								}
								pts := (cleared - 2) * (cleared - 2) * 100 + cleared * 50
								app.float_texts << FloatText{
									x:     f64(board_x + c * cell_size + cell_size / 2)
									y:     f64(board_y + r * cell_size)
									text:  '+${pts}'
									life:  0.8
									max_l: 0.8
									scale: 2
									color: Color{r: 255, g: 230, b: 80}
								}
								if app.game.state == .cleared_all {
									app.sound_mgr.play_clear_all_sound()
								}
							}
						}
					}
				}
			}
		}
		.key_down {
			match e.key_code {
				.escape { exit(0) }
				.r {
					app.game = new_same_game(app.game.mode)
				}
				.m {
					app.sound_mgr.toggle_sound()
				}
				.t {
					new_mode := if app.game.mode == .puzzle { GameMode.arcade_collapse } else { GameMode.puzzle }
					app.game = new_same_game(new_mode)
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
		window_title: 'SAMEGAME // Gem Cluster Collapse Classic'
		user_data:    &app
		frame_fn:     on_frame
		event_fn:     on_event
		bg_color:     gg.Color{r: 16, g: 14, b: 24, a: 255}
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
with open('/Users/codecaine/vlang_games/samegame/main.v', 'w') as f:
    f.write(full_code)
print("Wrote samegame/main.v")
