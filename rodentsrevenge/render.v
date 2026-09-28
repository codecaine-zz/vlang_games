module main

import math
import os

const cell_sz = 32

pub struct TextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn new_texture_manager() TextureManager {
	return TextureManager{}
}

pub fn (mut tm TextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/rodentsrevenge.png',
		'./assets/sprites/rodentsrevenge.png',
		'../assets/sprites/rodentsrevenge.png',
		'rodentsrevenge/assets/sprites/rodentsrevenge.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('rodentsrevenge Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

pub fn render_rodent_game(renderer &Renderer, mut g RodentGame, win_w int, win_h int, sound_enabled bool, tex &Texture) {
	// 1. Classic Windows Teal / Slate Backdrop
	set_render_draw_color(renderer, 24, 64, 84, 255)
	clear_rect := Rect{0, 0, win_w, win_h}
	render_fill_rect(renderer, &clear_rect)

	tile_s := 28
	board_x := (win_w - grid_w * tile_s) / 2
	board_y := 58
	board_w := grid_w * tile_s
	board_h := grid_h * tile_s

	// 2. Warehouse Playfield Canvas
	set_render_draw_color(renderer, 228, 232, 238, 255)
	board_bg := Rect{board_x, board_y, board_w, board_h}
	render_fill_rect(renderer, &board_bg)

	// Playfield 3D Sunken Frame
	set_render_draw_color(renderer, 15, 25, 35, 255)
	frame := Rect{board_x - 3, board_y - 3, board_w + 6, board_h + 6}
	render_draw_rect(renderer, &frame)

	// 3. Render 20x20 Tiles
	for x in 0 .. grid_w {
		for y in 0 .. grid_h {
			px := board_x + x * tile_s
			py := board_y + y * tile_s
			render_rodent_tile(renderer, g.grid[x][y], px, py, tile_s, tex)
		}
	}

	// 4. Render Cats
	for c in g.cats {
		cx := board_x + c.x * tile_s
		cy := board_y + c.y * tile_s
		render_cat(renderer, c, cx, cy, tile_s, tex)
	}

	// 5. Render Mouse (Player)
	mx := board_x + g.player_x * tile_s
	my := board_y + g.player_y * tile_s
	render_mouse(renderer, mx, my, tile_s, g.facing_dx, g.facing_dy, tex)

	// 6. Top Status Header Bar
	render_header(renderer, g, win_w, sound_enabled)

	// 7. Announcement Banner
	if g.banner_timer > 0.0 && g.banner_text != '' {
		bw := g.banner_text.len * 8 * 2 + 40
		bx := win_w / 2 - bw / 2
		by := 300

		set_render_draw_color(renderer, 20, 25, 35, 240)
		bg := Rect{bx, by, bw, 44}
		render_fill_rect(renderer, &bg)
		set_render_draw_color(renderer, 255, 215, 0, 255)
		render_draw_rect(renderer, &bg)

		draw_text_centered(renderer, win_w / 2, by + 14, g.banner_text, 2, Color{255, 230, 80, 255})
	}
}

fn draw_sprite_tile(renderer &Renderer, tex &Texture, src_x int, src_y int, dst_x int, dst_y int, s int) {
	src := Rect{src_x, src_y, cell_sz, cell_sz}
	dst := Rect{dst_x, dst_y, s, s}
	render_copy(renderer, tex, &src, &dst)
}

fn render_rodent_tile(renderer &Renderer, t TileType, x int, y int, s int, tex &Texture) {
	match t {
		.wall {
			if tex != unsafe { nil } {
				draw_sprite_tile(renderer, tex, 1 * cell_sz, 2 * cell_sz, x, y, s)
			} else {
				set_render_draw_color(renderer, 100, 100, 110, 255)
				r := Rect{x, y, s, s}
				render_fill_rect(renderer, &r)
				set_render_draw_color(renderer, 60, 60, 70, 255)
				render_draw_rect(renderer, &r)
			}
		}
		.block {
			if tex != unsafe { nil } {
				draw_sprite_tile(renderer, tex, 0 * cell_sz, 2 * cell_sz, x, y, s)
			} else {
				set_render_draw_color(renderer, 210, 180, 130, 255)
				r := Rect{x + 1, y + 1, s - 2, s - 2}
				render_fill_rect(renderer, &r)
				set_render_draw_color(renderer, 160, 120, 80, 255)
				render_draw_rect(renderer, &r)
				render_draw_line(renderer, x + 3, y + 3, x + s - 4, y + s - 4)
				render_draw_line(renderer, x + 3, y + s - 4, x + s - 4, y + 3)
			}
		}
		.cheese {
			if tex != unsafe { nil } {
				draw_sprite_tile(renderer, tex, 0 * cell_sz, 3 * cell_sz, x, y, s)
			} else {
				set_render_draw_color(renderer, 255, 215, 0, 255)
				c_rect := Rect{x + 3, y + 3, s - 6, s - 6}
				render_fill_rect(renderer, &c_rect)
				draw_filled_circle(renderer, x + 8, y + 8, 2, Color{210, 160, 0, 255})
				draw_filled_circle(renderer, x + 16, y + 14, 3, Color{210, 160, 0, 255})
				draw_filled_circle(renderer, x + 10, y + 20, 2, Color{210, 160, 0, 255})
			}
		}
		.mousetrap {
			if tex != unsafe { nil } {
				draw_sprite_tile(renderer, tex, 1 * cell_sz, 3 * cell_sz, x, y, s)
			} else {
				set_render_draw_color(renderer, 150, 90, 40, 255)
				r := Rect{x + 2, y + 6, s - 4, s - 12}
				render_fill_rect(renderer, &r)
				set_render_draw_color(renderer, 220, 40, 40, 255)
				render_draw_line(renderer, x + 4, y + s / 2, x + s - 5, y + s / 2)
			}
		}
		.empty {
			set_render_draw_color(renderer, 215, 220, 228, 255)
			r := Rect{x, y, s, s}
			render_draw_rect(renderer, &r)
		}
	}
}

fn render_cat(renderer &Renderer, c Cat, x int, y int, s int, tex &Texture) {
	if tex != unsafe { nil } {
		col_idx := if c.is_trapped {
			2
		} else if c.is_sleeping {
			1
		} else {
			0
		}
		draw_sprite_tile(renderer, tex, col_idx * cell_sz, 1 * cell_sz, x, y, s)
		return
	}

	// Fallback procedural Cat
	set_render_draw_color(renderer, 235, 120, 30, 255)
	body := Rect{x + 5, y + 6, s - 10, s - 12}
	render_fill_rect(renderer, &body)

	draw_filled_circle(renderer, x + 7, y + 6, 3, Color{235, 120, 30, 255})
	draw_filled_circle(renderer, x + s - 8, y + 6, 3, Color{235, 120, 30, 255})

	eye_col := if c.is_trapped { Color{255, 50, 50, 255} } else { Color{50, 220, 80, 255} }
	draw_filled_circle(renderer, x + 9, y + 12, 2, eye_col)
	draw_filled_circle(renderer, x + s - 10, y + 12, 2, eye_col)
}

fn render_mouse(renderer &Renderer, x int, y int, s int, dx int, dy int, tex &Texture) {
	if tex != unsafe { nil } {
		col_idx := if dy < 0 {
			0 // Up
		} else if dy > 0 {
			1 // Down
		} else if dx < 0 {
			2 // Left
		} else {
			3 // Right
		}
		draw_sprite_tile(renderer, tex, col_idx * cell_sz, 0 * cell_sz, x, y, s)
		return
	}

	// Fallback procedural Mouse
	set_render_draw_color(renderer, 130, 130, 140, 255)
	body := Rect{x + 6, y + 6, s - 12, s - 12}
	render_fill_rect(renderer, &body)

	draw_filled_circle(renderer, x + 7, y + 7, 3, Color{255, 160, 180, 255})
	draw_filled_circle(renderer, x + s - 8, y + 7, 3, Color{255, 160, 180, 255})

	draw_filled_circle(renderer, x + s / 2 + dx * 3, y + s / 2 + 2 + dy * 3, 2, Color{255, 100, 130, 255})
}

fn render_header(renderer &Renderer, g RodentGame, win_w int, sound_enabled bool) {
	// Classic Windows Grey Panel with 3D Bevel
	set_render_draw_color(renderer, 205, 205, 210, 255)
	bar := Rect{0, 0, win_w, 46}
	render_fill_rect(renderer, &bar)

	set_render_draw_color(renderer, 255, 255, 255, 255)
	render_draw_line(renderer, 0, 0, win_w, 0)
	set_render_draw_color(renderer, 120, 120, 130, 255)
	render_draw_line(renderer, 0, 45, win_w, 45)

	// Title
	draw_text(renderer, 18, 14, "RODENT'S REVENGE", 2, Color{25, 30, 50, 255})

	// Level & Score
	draw_text(renderer, 310, 16, 'LEVEL: ${g.level}', 1, Color{20, 40, 120, 255})
	draw_text(renderer, 410, 16, 'SCORE: ${g.score}', 1, Color{0, 100, 30, 255})
	draw_text(renderer, 540, 16, 'LIVES: ${g.lives}', 1, Color{180, 30, 30, 255})
	draw_text(renderer, 645, 16, 'TIME: ${int(math.max(0.0, g.time_left))}S', 1, Color{80, 60, 0, 255})

	// Sound toggle badge
	sound_x := win_w - 130
	if sound_enabled {
		set_render_draw_color(renderer, 35, 125, 60, 255)
		btn := Rect{sound_x, 10, 115, 26}
		render_fill_rect(renderer, &btn)
		draw_text_centered(renderer, sound_x + 57, 15, 'SOUND: ON [M]', 1, Color{255, 255, 255, 255})
	} else {
		set_render_draw_color(renderer, 130, 40, 45, 255)
		btn := Rect{sound_x, 10, 115, 26}
		render_fill_rect(renderer, &btn)
		draw_text_centered(renderer, sound_x + 57, 15, 'MUTED [M]', 1, Color{255, 180, 180, 255})
	}
}
