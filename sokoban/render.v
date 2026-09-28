module main

import math
import os

const tile_size = 48

pub struct SokobanTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm SokobanTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/sokoban.png',
		'./assets/sprites/sokoban.png',
		'../assets/sprites/sokoban.png',
		'sokoban/assets/sprites/sokoban.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('sokoban Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

pub fn draw_wall_tile(renderer &Renderer, x int, y int, tex &Texture) {
	if tex != unsafe { nil } {
		src := Rect{x: 0, y: 192, w: 64, h: 64}
		dst := Rect{x: x, y: y, w: tile_size, h: tile_size}
		render_copy(renderer, tex, &src, &dst)
		return
	}

	// Dark stone base
	set_render_draw_color(renderer, 50, 60, 80, 255)
	rect := Rect{x: x, y: y, w: tile_size, h: tile_size}
	render_fill_rect(renderer, &rect)

	// Top light bevel
	set_render_draw_color(renderer, 95, 115, 150, 255)
	for t in 0 .. 4 {
		render_draw_line(renderer, x + t, y + t, x + tile_size - 1 - t, y + t)
		render_draw_line(renderer, x + t, y + t, x + t, y + tile_size - 1 - t)
	}

	// Bottom shadow bevel
	set_render_draw_color(renderer, 25, 30, 45, 255)
	for t in 0 .. 4 {
		render_draw_line(renderer, x + t, y + tile_size - 1 - t, x + tile_size - 1 - t, y + tile_size - 1 - t)
		render_draw_line(renderer, x + tile_size - 1 - t, y + t, x + tile_size - 1 - t, y + tile_size - 1 - t)
	}
}

pub fn draw_floor_tile(renderer &Renderer, x int, y int) {
	// Clean industrial concrete floor
	set_render_draw_color(renderer, 25, 28, 38, 255)
	rect := Rect{x: x, y: y, w: tile_size, h: tile_size}
	render_fill_rect(renderer, &rect)

	// Subtle grid border
	set_render_draw_color(renderer, 35, 40, 52, 255)
	render_draw_rect(renderer, &rect)
}

pub fn draw_target_pad(renderer &Renderer, x int, y int, pulse f64, tex &Texture) {
	if tex != unsafe { nil } {
		src := Rect{x: 0, y: 128, w: 64, h: 64}
		dst := Rect{x: x, y: y, w: tile_size, h: tile_size}
		render_copy(renderer, tex, &src, &dst)
		return
	}

	draw_floor_tile(renderer, x, y)
	cx := x + tile_size / 2
	cy := y + tile_size / 2

	p_val := u8(180.0 + 75.0 * math.sin(pulse * 5.0))
	set_render_draw_color(renderer, 255, 60, 100, p_val)

	r := tile_size / 3
	for dy in -r .. r + 1 {
		dx_max := int(math.sqrt(f64(r * r - dy * dy)))
		render_draw_line(renderer, cx - dx_max, cy + dy, cx + dx_max, cy + dy)
	}

	set_render_draw_color(renderer, 255, 240, 240, 255)
	inner := Rect{x: cx - 3, y: cy - 3, w: 7, h: 7}
	render_fill_rect(renderer, &inner)
}

pub fn draw_crate(renderer &Renderer, x int, y int, on_target bool, tex &Texture) {
	if tex != unsafe { nil } {
		src := if on_target { Rect{x: 64, y: 64, w: 64, h: 64} } else { Rect{x: 0, y: 64, w: 64, h: 64} }
		dst := Rect{x: x + 2, y: y + 2, w: tile_size - 4, h: tile_size - 4}
		render_copy(renderer, tex, &src, &dst)
		return
	}

	pad := 3
	w := tile_size - pad * 2
	h := tile_size - pad * 2

	bg_color := if on_target { Color{r: 255, g: 195, b: 0} } else { Color{r: 180, g: 115, b: 50} }
	light_col := if on_target { Color{r: 255, g: 240, b: 120} } else { Color{r: 225, g: 160, b: 90} }
	dark_col := if on_target { Color{r: 180, g: 120, b: 0} } else { Color{r: 110, g: 65, b: 20} }

	set_render_draw_color(renderer, bg_color.r, bg_color.g, bg_color.b, 255)
	rect := Rect{x: x + pad, y: y + pad, w: w, h: h}
	render_fill_rect(renderer, &rect)

	set_render_draw_color(renderer, light_col.r, light_col.g, light_col.b, 255)
	render_draw_line(renderer, x + pad, y + pad, x + pad + w - 1, y + pad)
	render_draw_line(renderer, x + pad, y + pad, x + pad, y + pad + h - 1)

	set_render_draw_color(renderer, dark_col.r, dark_col.g, dark_col.b, 255)
	render_draw_line(renderer, x + pad, y + pad + h - 1, x + pad + w - 1, y + pad + h - 1)
	render_draw_line(renderer, x + pad + w - 1, y + pad, x + pad + w - 1, y + pad + h - 1)

	border_col := if on_target { Color{r: 220, g: 140, b: 0} } else { Color{r: 90, g: 50, b: 15} }
	set_render_draw_color(renderer, border_col.r, border_col.g, border_col.b, 255)
	render_draw_rect(renderer, &Rect{x: x + pad + 3, y: y + pad + 3, w: w - 6, h: h - 6})
	render_draw_line(renderer, x + pad + 3, y + pad + 3, x + pad + w - 4, y + pad + h - 4)
	render_draw_line(renderer, x + pad + 3, y + pad + h - 4, x + pad + w - 4, y + pad + 3)
}

pub fn draw_player_sprite(renderer &Renderer, x int, y int, dir int, tex &Texture) {
	if tex != unsafe { nil } {
		idx := math.max(0, math.min(dir, 3))
		src := Rect{x: idx * 64, y: 0, w: 64, h: 64}
		dst := Rect{x: x, y: y, w: tile_size, h: tile_size}
		render_copy(renderer, tex, &src, &dst)
		return
	}

	cx := x + tile_size / 2
	cy := y + tile_size / 2

	set_render_draw_color(renderer, 30, 100, 220, 255)
	body := Rect{x: cx - 10, y: cy - 4, w: 20, h: 18}
	render_fill_rect(renderer, &body)

	set_render_draw_color(renderer, 255, 120, 20, 255)
	vest := Rect{x: cx - 7, y: cy - 2, w: 14, h: 12}
	render_fill_rect(renderer, &vest)

	set_render_draw_color(renderer, 255, 205, 160, 255)
	head := Rect{x: cx - 8, y: cy - 16, w: 16, h: 12}
	render_fill_rect(renderer, &head)

	set_render_draw_color(renderer, 255, 220, 0, 255)
	helmet := Rect{x: cx - 10, y: cy - 20, w: 20, h: 7}
	render_fill_rect(renderer, &helmet)
	brim := Rect{x: cx - 12, y: cy - 14, w: 24, h: 3}
	render_fill_rect(renderer, &brim)
}

pub fn render_sokoban_game(renderer &Renderer, game &SokobanGame, win_w int, win_h int, pulse f64, tex &Texture) {
	// Dark cyber warehouse background
	set_render_draw_color(renderer, 15, 18, 25, 255)
	render_clear(renderer)

	// Center board
	board_w := game.cols * tile_size
	board_h := game.rows * tile_size
	board_x := (win_w - board_w) / 2
	board_y := 120 + (win_h - 200 - board_h) / 2

	// Render Base Floor & Grid
	for r in 0 .. game.rows {
		for c in 0 .. game.cols {
			tx := board_x + c * tile_size
			ty := board_y + r * tile_size
			tile := game.grid[r][c]

			match tile {
				.empty {}
				.wall {
					draw_wall_tile(renderer, tx, ty, tex)
				}
				.floor {
					draw_floor_tile(renderer, tx, ty)
				}
				.target {
					draw_target_pad(renderer, tx, ty, pulse, tex)
				}
				.crate {
					draw_floor_tile(renderer, tx, ty)
					draw_crate(renderer, tx, ty, false, tex)
				}
				.crate_on_target {
					draw_target_pad(renderer, tx, ty, pulse, tex)
					draw_crate(renderer, tx, ty, true, tex)
				}
				.player {
					draw_floor_tile(renderer, tx, ty)
				}
				.player_on_target {
					draw_target_pad(renderer, tx, ty, pulse, tex)
				}
			}
		}
	}

	// Render Smooth Animated Player
	px := board_x + int(game.anim_px * f64(tile_size))
	py := board_y + int(game.anim_py * f64(tile_size))
	draw_player_sprite(renderer, px, py, game.player_dir, tex)

	// Top HUD
	lvl_name := if game.current_level < sokoban_levels.len {
		sokoban_levels[game.current_level].name
	} else {
		'Custom Level'
	}
	draw_text_centered(renderer, win_w / 2, 20, 'SOKOBAN MASTER', 3, Color{r: 255, g: 215, b: 0})
	draw_text_centered(renderer, win_w / 2, 52, lvl_name, 2, Color{r: 80, g: 220, b: 255})

	// Stats Panel (Steps, Pushes, Par, Target Progress)
	par := if game.current_level < sokoban_levels.len { sokoban_levels[game.current_level].par_pushes } else { 0 }
	stats_y := 85
	draw_text(renderer, 60, stats_y, 'STEPS: ${game.steps:03d}', 2, Color{r: 255, g: 255, b: 255})
	draw_text(renderer, 240, stats_y, 'PUSHES: ${game.pushes:03d} (PAR: ${par})', 2, Color{r: 255, g: 220, b: 80})
	draw_text(renderer, 620, stats_y, 'TARGETS: ${game.targets_filled}/${game.total_targets}', 2, if game.level_cleared { Color{r: 80, g: 255, b: 120} } else { Color{r: 255, g: 100, b: 120} })

	// Bottom Controls Bar
	draw_text_centered(renderer, win_w / 2, win_h - 40, '[ARROWS/WASD] MOVE  [U] UNDO  [F5] SAVE  [F9] LOAD  [R] RESET  [N] NEXT  [P] PREV', 1, Color{r: 160, g: 180, b: 210})

	// Toast Notification Overlay
	if game.toast_timer > 0 {
		tw := 260
		th := 36
		tx := (win_w - tw) / 2
		ty := 125
		set_render_draw_color(renderer, 20, 20, 30, 220)
		t_rect := Rect{x: tx, y: ty, w: tw, h: th}
		render_fill_rect(renderer, &t_rect)
		set_render_draw_color(renderer, 0, 220, 255, 255)
		render_draw_rect(renderer, &t_rect)
		draw_text_centered(renderer, win_w / 2, ty + 10, game.toast_msg, 2, Color{r: 0, g: 220, b: 255})
	}

	// Victory Modal Overlay
	if game.level_cleared {
		set_render_draw_color(renderer, 0, 0, 0, 180)
		scrim := Rect{x: 0, y: 0, w: win_w, h: win_h}
		render_fill_rect(renderer, &scrim)

		modal_w := 480
		modal_h := 220
		mx := (win_w - modal_w) / 2
		my := (win_h - modal_h) / 2
		set_render_draw_color(renderer, 25, 32, 50, 255)
		modal_rect := Rect{x: mx, y: my, w: modal_w, h: modal_h}
		render_fill_rect(renderer, &modal_rect)
		set_render_draw_color(renderer, 255, 215, 0, 255)
		render_draw_rect(renderer, &modal_rect)

		draw_text_centered(renderer, win_w / 2, my + 25, 'LEVEL COMPLETE!', 3, Color{r: 255, g: 215, b: 0})

		stars := game.calculate_stars()
		star_str := match stars {
			3 { '*** (3/3 STARS)' }
			2 { '**  (2/3 STARS)' }
			else { '*   (1/3 STARS)' }
		}
		draw_text_centered(renderer, win_w / 2, my + 65, star_str, 2, Color{r: 255, g: 230, b: 60})
		draw_text_centered(renderer, win_w / 2, my + 100, 'Total Pushes: ${game.pushes} | Par: ${par}', 2, Color{r: 220, g: 220, b: 240})
		draw_text_centered(renderer, win_w / 2, my + 140, 'PRESS [SPACE] OR [N] FOR NEXT LEVEL', 2, Color{r: 80, g: 255, b: 140})
	}

	if renderer.ctx != unsafe { nil } { prod_fx_render(renderer.ctx) }
	render_present(renderer)
}
