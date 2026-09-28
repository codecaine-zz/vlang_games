module main

import math

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

struct FloatText {
mut:
	x     f64
	y     f64
	text  string
	life  f64
	color Color
	scale int
}

const block_colors = [
	Color{
		r: 0
		g: 0
		b: 0
		a: 0
	}, // 0: Empty
	Color{
		r: 40
		g: 220
		b: 240
	}, // 1: Cyan (I)
	Color{
		r: 40
		g: 80
		b: 230
	}, // 2: Blue (J)
	Color{
		r: 240
		g: 140
		b: 30
	}, // 3: Orange (L)
	Color{
		r: 245
		g: 215
		b: 40
	}, // 4: Yellow (O)
	Color{
		r: 40
		g: 220
		b: 80
	}, // 5: Green (S)
	Color{
		r: 170
		g: 50
		b: 230
	}, // 6: Purple (T)
	Color{
		r: 240
		g: 45
		b: 65
	}, // 7: Red (Z)
]

fn draw_filled_circle(renderer &Renderer, cx int, cy int, r int, color Color) {
	if r <= 0 {
		return
	}
	set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	r_sq := r * r
	for dy := -r; dy <= r; dy++ {
		dx := int(math.sqrt(f64(r_sq - dy * dy)))
		if dx < 0 {
			continue
		}
		rect := Rect{
			x: cx - dx
			y: cy + dy
			w: dx * 2 + 1
			h: 1
		}
		render_fill_rect(renderer, &rect)
	}
}

fn draw_block(renderer &Renderer, x int, y int, size int, kind int, is_ghost bool) {
	if kind <= 0 || kind >= block_colors.len {
		return
	}
	c := block_colors[kind]

	rect := Rect{
		x: x
		y: y
		w: size
		h: size
	}

	if is_ghost {
		set_render_draw_color(renderer, c.r, c.g, c.b, 50)
		render_fill_rect(renderer, &rect)
		set_render_draw_color(renderer, c.r, c.g, c.b, 200)
		render_draw_rect(renderer, &rect)
		return
	}

	// 16-Bit Beveled Jewel Tetromino Block
	// Base fill
	set_render_draw_color(renderer, c.r, c.g, c.b, c.a)
	render_fill_rect(renderer, &rect)

	// Top/Left 3D Highlight Bevel
	high_r := u8(math.min(255, int(c.r) + 80))
	high_g := u8(math.min(255, int(c.g) + 80))
	high_b := u8(math.min(255, int(c.b) + 80))
	set_render_draw_color(renderer, high_r, high_g, high_b, 255)
	for t in 0 .. 3 {
		render_draw_line(renderer, x + t, y + t, x + size - 1 - t, y + t)
		render_draw_line(renderer, x + t, y + t, x + t, y + size - 1 - t)
	}

	// Bottom/Right 3D Shadow Bevel
	shad_r := u8(math.max(0, int(c.r) - 80))
	shad_g := u8(math.max(0, int(c.g) - 80))
	shad_b := u8(math.max(0, int(c.b) - 80))
	set_render_draw_color(renderer, shad_r, shad_g, shad_b, 255)
	for t in 0 .. 3 {
		render_draw_line(renderer, x + t, y + size - 1 - t, x + size - 1 - t, y + size - 1 - t)
		render_draw_line(renderer, x + size - 1 - t, y + t, x + size - 1 - t, y + size - 1 - t)
	}

	// Inner Jewel Diamond Center Core & Specular Dot
	inner := Rect{ x: x + 6, y: y + 6, w: size - 12, h: size - 12 }
	set_render_draw_color(renderer, high_r, high_g, high_b, 160)
	render_draw_rect(renderer, &inner)

	set_render_draw_color(renderer, 255, 255, 255, 220)
	render_draw_point(renderer, x + 4, y + 4)
	render_draw_point(renderer, x + 5, y + 4)

	// Outer border
	set_render_draw_color(renderer, 15, 18, 25, 255)
	render_draw_rect(renderer, &rect)
}

fn draw_glass_card(renderer &Renderer, x int, y int, w int, h int, border_color Color) {
	bg_rect := Rect{
		x: x
		y: y
		w: w
		h: h
	}
	set_render_draw_color(renderer, 24, 30, 50, 230)
	render_fill_rect(renderer, &bg_rect)

	set_render_draw_color(renderer, border_color.r, border_color.g, border_color.b,
		border_color.a)
	render_draw_rect(renderer, &bg_rect)

	inner_rect := Rect{
		x: x + 1
		y: y + 1
		w: w - 2
		h: h - 2
	}
	set_render_draw_color(renderer, border_color.r, border_color.g, border_color.b,
		60)
	render_draw_rect(renderer, &inner_rect)
}

struct Button {
	x int
	y int
	w int
	h int
mut:
	text         string
	bg_color     Color
	hover_color  Color
	text_color   Color
	border_color Color
}

fn (btn &Button) is_hovered(mx int, my int) bool {
	return mx >= btn.x && mx <= btn.x + btn.w && my >= btn.y && my <= btn.y + btn.h
}

fn (btn &Button) draw(renderer &Renderer, mx int, my int) {
	hovered := btn.is_hovered(mx, my)
	current_bg := if hovered { btn.hover_color } else { btn.bg_color }

	if hovered {
		glow_rect := Rect{
			x: btn.x - 2
			y: btn.y - 2
			w: btn.w + 4
			h: btn.h + 4
		}
		set_render_draw_color(renderer, btn.border_color.r, btn.border_color.g, btn.border_color.b,
			90)
		render_draw_rect(renderer, &glow_rect)
	}

	bg_rect := Rect{
		x: btn.x
		y: btn.y
		w: btn.w
		h: btn.h
	}
	set_render_draw_color(renderer, current_bg.r, current_bg.g, current_bg.b, current_bg.a)
	render_fill_rect(renderer, &bg_rect)

	top_line_rect := Rect{
		x: btn.x + 1
		y: btn.y + 1
		w: btn.w - 2
		h: 2
	}
	set_render_draw_color(renderer, 255, 255, 255, 60)
	render_fill_rect(renderer, &top_line_rect)

	set_render_draw_color(renderer, btn.border_color.r, btn.border_color.g, btn.border_color.b,
		btn.border_color.a)
	render_draw_rect(renderer, &bg_rect)

	cx := btn.x + btn.w / 2
	ty := btn.y + (btn.h - 16) / 2
	draw_text_centered(renderer, cx, ty, btn.text, 2, btn.text_color)
}
