module main

import gg
import math
import os

pub struct SnakeTextureManager {
pub mut:
	sprite_img  gg.Image
	has_texture bool
}

pub fn new_snake_texture_manager() SnakeTextureManager {
	return SnakeTextureManager{}
}

pub fn (mut tm SnakeTextureManager) init(ctx &gg.Context) {
	paths := [
		'assets/sprites/snake.png',
		'../assets/sprites/snake.png',
		'snake/assets/sprites/snake.png',
		os.join_path('assets', 'sprites', 'snake.png'),
		os.join_path('..', 'assets', 'sprites', 'snake.png'),
	]
	for p in paths {
		if os.exists(p) {
			img := ctx.create_image(p) or { continue }
			tm.sprite_img = img
			tm.has_texture = true
			println('Snake Texture Loaded Successfully: ' + p)
			return
		}
	}
}

// 16x16 Pixel Art Apple Matrix
const apple_sprite = [
	[0,0,0,0,0,0,4,4,5,5,0,0,0,0,0,0],
	[0,0,0,0,0,4,4,5,5,5,5,0,0,0,0,0],
	[0,0,0,0,4,4,0,0,5,5,0,0,0,0,0,0],
	[0,0,1,1,1,2,2,0,2,2,1,1,1,0,0,0],
	[0,1,2,2,2,2,3,3,2,2,2,2,2,1,0,0],
	[1,2,2,2,3,3,3,3,3,2,2,2,2,2,1,0],
	[1,2,2,3,3,3,3,2,2,2,2,2,2,2,1,0],
	[1,2,2,3,3,2,2,2,2,2,2,2,2,2,1,0],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,2,1,0],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,2,1,0],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,2,1,0],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,2,1,0],
	[0,1,2,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[0,1,2,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[0,0,1,1,2,2,2,1,2,2,2,1,1,0,0,0],
	[0,0,0,0,1,1,1,0,1,1,1,0,0,0,0,0]
]

// 16x16 Pixel Art Golden Star Apple Matrix
const gold_apple_sprite = [
	[0,0,0,0,0,0,4,4,5,5,0,0,0,0,0,0],
	[0,0,0,0,0,4,4,5,5,5,5,0,0,0,0,0],
	[0,0,0,0,4,4,0,0,5,5,0,0,0,0,0,0],
	[0,0,1,1,1,2,2,0,2,2,1,1,1,0,0,0],
	[0,1,2,2,2,2,3,3,2,2,2,2,2,1,0,0],
	[1,2,2,2,3,3,3,3,3,2,2,2,2,2,1,0],
	[1,2,2,3,3,3,3,2,2,2,2,2,2,2,1,0],
	[1,2,2,3,3,2,2,2,2,2,2,2,2,2,1,0],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,2,1,0],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,2,1,0],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,2,1,0],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,2,1,0],
	[0,1,2,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[0,1,2,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[0,0,1,1,2,2,2,1,2,2,2,1,1,0,0,0],
	[0,0,0,0,1,1,1,0,1,1,1,0,0,0,0,0]
]

pub fn draw_food_sprite(ren &Renderer, x int, y int, sz int, is_gold bool, tm &SnakeTextureManager) {
	if tm.has_texture {
		col_idx := if is_gold { 1 } else { 0 }
		ren.draw_image_with_config(gg.DrawImageConfig{
			img:       &tm.sprite_img
			img_rect:  gg.Rect{
				x:      f32(x)
				y:      f32(y)
				width:  f32(sz)
				height: f32(sz)
			}
			part_rect: gg.Rect{
				x:      f32(col_idx * 32)
				y:      f32(2 * 32)
				width:  32
				height: 32
			}
		})
		return
	}

	scale_x := f32(sz) / 16.0
	scale_y := f32(sz) / 16.0

	for r in 0 .. 16 {
		for c in 0 .. 16 {
			val := if is_gold { gold_apple_sprite[r][c] } else { apple_sprite[r][c] }
			if val == 0 {
				continue
			}

			col := if is_gold {
				match val {
					1 { gg.Color{r: 160, g: 110, b: 0, a: 255} }
					2 { gg.Color{r: 255, g: 215, b: 0, a: 255} }
					3 { gg.Color{r: 255, g: 255, b: 180, a: 255} }
					4 { gg.Color{r: 120, g: 80, b: 20, a: 255} }
					5 { gg.Color{r: 100, g: 230, b: 60, a: 255} }
					else { gg.Color{r: 255, g: 215, b: 0, a: 255} }
				}
			} else {
				match val {
					1 { gg.Color{r: 120, g: 15, b: 25, a: 255} }
					2 { gg.Color{r: 235, g: 35, b: 50, a: 255} }
					3 { gg.Color{r: 255, g: 150, b: 160, a: 255} }
					4 { gg.Color{r: 100, g: 60, b: 20, a: 255} }
					5 { gg.Color{r: 50, g: 190, b: 40, a: 255} }
					else { gg.Color{r: 235, g: 35, b: 50, a: 255} }
				}
			}

			px := f32(x) + f32(c) * scale_x
			py := f32(y) + f32(r) * scale_y
			pw := scale_x
			ph := scale_y

			ren.draw_rect_filled(px, py, if pw > 0 { pw } else { 1 }, if ph > 0 { ph } else { 1 }, col)
		}
	}
}

pub fn draw_snake_head_sprite(ren &Renderer, x int, y int, sz int, dir Direction, tm &SnakeTextureManager) {
	if tm.has_texture {
		dir_idx := match dir {
			.up { 0 }
			.right { 1 }
			.down { 2 }
			.left { 3 }
		}
		ren.draw_image_with_config(gg.DrawImageConfig{
			img:       &tm.sprite_img
			img_rect:  gg.Rect{
				x:      f32(x)
				y:      f32(y)
				width:  f32(sz)
				height: f32(sz)
			}
			part_rect: gg.Rect{
				x:      f32(dir_idx * 32)
				y:      0
				width:  32
				height: 32
			}
		})
		return
	}

	// Cyber Serpent Head with Beveled Scales and Glowing Eyes
	ren.draw_rounded_rect_filled(f32(x + 1), f32(y + 1), f32(sz - 2), f32(sz - 2), 4, gg.Color{r: 0, g: 190, b: 180, a: 255})
	ren.draw_rounded_rect_filled(f32(x + 3), f32(y + 3), f32(sz - 6), f32(sz - 6), 3, gg.Color{r: 60, g: 240, b: 230, a: 255})
	ren.draw_rounded_rect_empty(f32(x + 1), f32(y + 1), f32(sz - 2), f32(sz - 2), 4, gg.Color{r: 0, g: 120, b: 120, a: 255})

	// Directional Eyes & Forked Tongue
	eye_col := gg.white
	pupil_col := gg.Color{r: 255, g: 40, b: 60, a: 255}

	cx := f32(x + sz / 2)
	cy := f32(y + sz / 2)

	mut e1_x, mut e1_y := cx - 4, cy - 4
	mut e2_x, mut e2_y := cx + 2, cy - 4

	match dir {
		.up {
			e1_x, e1_y = cx - 5, cy - 5
			e2_x, e2_y = cx + 3, cy - 5
			ren.draw_line(cx, f32(y), cx, f32(y - 4), pupil_col)
			ren.draw_line(cx, f32(y - 4), cx - 2, f32(y - 6), pupil_col)
			ren.draw_line(cx, f32(y - 4), cx + 2, f32(y - 6), pupil_col)
		}
		.down {
			e1_x, e1_y = cx - 5, cy + 3
			e2_x, e2_y = cx + 3, cy + 3
			ren.draw_line(cx, f32(y + sz), cx, f32(y + sz + 4), pupil_col)
			ren.draw_line(cx, f32(y + sz + 4), cx - 2, f32(y + sz + 6), pupil_col)
			ren.draw_line(cx, f32(y + sz + 4), cx + 2, f32(y + sz + 6), pupil_col)
		}
		.left {
			e1_x, e1_y = cx - 5, cy - 5
			e2_x, e2_y = cx - 5, cy + 3
			ren.draw_line(f32(x), cy, f32(x - 4), cy, pupil_col)
			ren.draw_line(f32(x - 4), cy, f32(x - 6), cy - 2, pupil_col)
			ren.draw_line(f32(x - 4), cy, f32(x - 6), cy + 2, pupil_col)
		}
		.right {
			e1_x, e1_y = cx + 3, cy - 5
			e2_x, e2_y = cx + 3, cy + 3
			ren.draw_line(f32(x + sz), cy, f32(x + sz + 4), cy, pupil_col)
			ren.draw_line(f32(x + sz + 4), cy, f32(x + sz + 6), cy - 2, pupil_col)
			ren.draw_line(f32(x + sz + 4), cy, f32(x + sz + 6), cy + 2, pupil_col)
		}
	}

	ren.draw_rect_filled(e1_x, e1_y, 3, 3, eye_col)
	ren.draw_rect_filled(e2_x, e2_y, 3, 3, eye_col)
	ren.draw_rect_filled(e1_x + 1, e1_y + 1, 1, 1, pupil_col)
	ren.draw_rect_filled(e2_x + 1, e2_y + 1, 1, 1, pupil_col)
}

pub fn draw_snake_body_sprite(ren &Renderer, x int, y int, sz int, seg_idx int, total_segs int, tm &SnakeTextureManager) {
	if tm.has_texture {
		ren.draw_image_with_config(gg.DrawImageConfig{
			img:       &tm.sprite_img
			img_rect:  gg.Rect{
				x:      f32(x)
				y:      f32(y)
				width:  f32(sz)
				height: f32(sz)
			}
			part_rect: gg.Rect{
				x:      0
				y:      32
				width:  32
				height: 32
			}
		})
		return
	}

	pct := f64(seg_idx) / f64(math.max(1, total_segs))
	r := u8(20.0 + pct * 20.0)
	g := u8(180.0 - pct * 60.0)
	b := u8(160.0 - pct * 50.0)

	ren.draw_rounded_rect_filled(f32(x + 2), f32(y + 2), f32(sz - 4), f32(sz - 4), 3, gg.Color{r: r, g: g, b: b, a: 255})
	ren.draw_rounded_rect_filled(f32(x + 4), f32(y + 4), f32(sz - 8), f32(sz - 8), 2, gg.Color{
		r: u8(math.min(255, int(r) + 30))
		g: u8(math.min(255, int(g) + 30))
		b: u8(math.min(255, int(b) + 30))
		a: 255
	})
	ren.draw_rounded_rect_empty(f32(x + 2), f32(y + 2), f32(sz - 4), f32(sz - 4), 3, gg.Color{
		r: u8(math.max(0, int(r) - 20))
		g: u8(math.max(0, int(g) - 30))
		b: u8(math.max(0, int(b) - 30))
		a: 255
	})
}

fn draw_filled_circle(ren &Renderer, cx int, cy int, r int, color gg.Color) {
	if r <= 0 {
		return
	}
	ren.draw_circle_filled(f32(cx), f32(cy), f32(r), color)
}

fn draw_glass_card(ren &Renderer, x int, y int, w int, h int, border_color gg.Color) {
	ren.draw_rounded_rect_filled(f32(x), f32(y), f32(w), f32(h), 6, gg.Color{r: 24, g: 30, b: 50, a: 230})
	ren.draw_rounded_rect_empty(f32(x), f32(y), f32(w), f32(h), 6, border_color)
}

struct Button {
	x int
	y int
	w int
	h int
mut:
	text         string
	bg_color     gg.Color
	hover_color  gg.Color
	text_color   gg.Color
	border_color gg.Color
}

fn (btn &Button) is_hovered(mx int, my int) bool {
	return mx >= btn.x && mx <= btn.x + btn.w && my >= btn.y && my <= btn.y + btn.h
}

fn (btn &Button) draw(ren &Renderer, mx int, my int) {
	hovered := btn.is_hovered(mx, my)
	current_bg := if hovered { btn.hover_color } else { btn.bg_color }

	if hovered {
		ren.draw_rounded_rect_empty(f32(btn.x - 2), f32(btn.y - 2), f32(btn.w + 4), f32(btn.h + 4), 6, gg.Color{
			r: btn.border_color.r
			g: btn.border_color.g
			b: btn.border_color.b
			a: 90
		})
	}

	ren.draw_rounded_rect_filled(f32(btn.x), f32(btn.y), f32(btn.w), f32(btn.h), 4, current_bg)
	ren.draw_rounded_rect_empty(f32(btn.x), f32(btn.y), f32(btn.w), f32(btn.h), 4, btn.border_color)

	cx := btn.x + btn.w / 2
	cy := btn.y + btn.h / 2
	ren.draw_text(cx, cy, btn.text,
		size:          16
		color:         btn.text_color
		align:         .center
		vertical_align: .middle
	)
}
