module main

import gg
import os

pub struct PongTextureManager {
pub mut:
	sprite_img  gg.Image
	has_texture bool
}

pub fn (mut tm PongTextureManager) init(ctx &gg.Context) {
	candidates := [
		'assets/sprites/pong.png',
		'./assets/sprites/pong.png',
		'../assets/sprites/pong.png',
		'pong/assets/sprites/pong.png',
	]
	for p in candidates {
		if os.exists(p) {
			img := ctx.create_image(p) or { continue }
			tm.sprite_img = img
			tm.has_texture = true
			println('Pong Texture Loaded Successfully: ' + p)
			return
		}
	}
}

struct Particle {
mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	life  f64
	color gg.Color
	size  int
}

// 12x12 Ball Plasma Orb Sprite Matrix
const ball_sprite = [
	[0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0],
	[0, 0, 1, 1, 2, 2, 2, 2, 1, 1, 0, 0],
	[0, 1, 2, 2, 3, 3, 3, 2, 2, 2, 1, 0],
	[0, 1, 2, 3, 4, 4, 3, 3, 2, 2, 1, 0],
	[1, 2, 3, 4, 4, 4, 4, 3, 3, 2, 2, 1],
	[1, 2, 3, 4, 4, 4, 4, 3, 3, 2, 2, 1],
	[1, 2, 2, 3, 4, 4, 3, 3, 2, 2, 2, 1],
	[1, 2, 2, 3, 3, 3, 3, 2, 2, 2, 2, 1],
	[0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0],
	[0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0],
	[0, 0, 1, 1, 2, 2, 2, 2, 1, 1, 0, 0],
	[0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0],
]

pub fn draw_ball_trail(ren &Renderer, trail []TrailPoint, cur_x f64, cur_y f64, speed f64) {
	if trail.len < 1 {
		return
	}

	base_color := if speed >= 11.0 {
		gg.Color{r: 255, g: 220, b: 80, a: 180}
	} else if speed >= 8.5 {
		gg.Color{r: 245, g: 70, b: 235, a: 180}
	} else {
		gg.Color{r: 60, g: 200, b: 255, a: 180}
	}

	first_pt := trail[0]
	ren.draw_line(f32(cur_x), f32(cur_y), f32(first_pt.x), f32(first_pt.y), gg.white)

	for i in 0 .. trail.len {
		pt := trail[i]
		t := 1.0 - (f64(i) / f64(trail.len))
		radius := f32(f64(ball_size / 2) * t * 0.9)
		alpha := u8(t * t * 200.0)

		if radius > 0 {
			ren.draw_circle_filled(f32(pt.x), f32(pt.y), radius, gg.Color{
				r: base_color.r
				g: base_color.g
				b: base_color.b
				a: alpha
			})
		}

		if i + 1 < trail.len {
			next_pt := trail[i + 1]
			line_alpha := u8(t * 220.0)
			ren.draw_line(f32(pt.x), f32(pt.y), f32(next_pt.x), f32(next_pt.y), gg.Color{
				r: 255
				g: 255
				b: 255
				a: line_alpha
			})
		}
	}
}

pub fn draw_ball_sprite(ren &Renderer, cx int, cy int, sz int, tm &PongTextureManager) {
	if tm.has_texture {
		ren.draw_image_with_config(gg.DrawImageConfig{
			img:       &tm.sprite_img
			img_rect:  gg.Rect{
				x:      f32(cx - sz / 2)
				y:      f32(cy - sz / 2)
				width:  f32(sz)
				height: f32(sz)
			}
			part_rect: gg.Rect{
				x:      0
				y:      96
				width:  32
				height: 32
			}
		})
		return
	}

	scale := sz / 12
	eff_scale := if scale < 1 { 1 } else { scale }
	top_left_x := cx - sz / 2
	top_left_y := cy - sz / 2

	for r in 0 .. 12 {
		for c in 0 .. 12 {
			val := ball_sprite[r][c]
			if val == 0 {
				continue
			}

			col := match val {
				1 { gg.Color{r: 70, g: 180, b: 255, a: 160} }
				2 { gg.Color{r: 140, g: 220, b: 255, a: 220} }
				3 { gg.Color{r: 210, g: 245, b: 255, a: 255} }
				4 { gg.Color{r: 255, g: 255, b: 255, a: 255} }
				else { gg.Color{r: 255, g: 255, b: 255, a: 255} }
			}

			px := top_left_x + c * eff_scale
			py := top_left_y + r * eff_scale
			ren.draw_rect_filled(f32(px), f32(py), f32(eff_scale), f32(eff_scale), col)
		}
	}
}

pub fn draw_paddle_sprite(ren &Renderer, x int, y int, w int, h int, is_p1 bool, tm &PongTextureManager) {
	if tm.has_texture {
		part_x := if is_p1 { f32(0) } else { f32(32) }
		ren.draw_image_with_config(gg.DrawImageConfig{
			img:       &tm.sprite_img
			img_rect:  gg.Rect{
				x:      f32(x)
				y:      f32(y)
				width:  f32(w)
				height: f32(h)
			}
			part_rect: gg.Rect{
				x:      part_x
				y:      0
				width:  24
				height: 88
			}
		})
		return
	}

	// Base Paddle Background
	ren.draw_rounded_rect_filled(f32(x), f32(y), f32(w), f32(h), 4, gg.Color{r: 20, g: 24, b: 36, a: 255})

	cap_col := if is_p1 {
		gg.Color{r: 255, g: 70, b: 90, a: 255}
	} else {
		gg.Color{r: 50, g: 230, b: 255, a: 255}
	}

	ren.draw_rect_filled(f32(x), f32(y), f32(w), 4, cap_col)
	ren.draw_rect_filled(f32(x), f32(y + h - 4), f32(w), 4, cap_col)

	// Carbon Texture Grips & Grooves
	for seg := y + 6; seg < y + h - 6; seg += 6 {
		glow_w := if is_p1 { (x + w - 3) } else { (x + 1) }
		groove_col := if is_p1 {
			gg.Color{r: 200, g: 40, b: 60, a: 255}
		} else {
			gg.Color{r: 30, g: 190, b: 220, a: 255}
		}
		ren.draw_rect_filled(f32(glow_w), f32(seg), 2, 4, groove_col)
		ren.draw_rect_filled(f32(x + 3), f32(seg), f32(w - 6), 3, gg.Color{r: 45, g: 55, b: 75, a: 255})
	}

	ren.draw_rounded_rect_empty(f32(x), f32(y), f32(w), f32(h), 4, cap_col)
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
