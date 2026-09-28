module main

import math
import os

pub struct GNUJumpTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn new_gnujump_texture_manager() GNUJumpTextureManager {
	return GNUJumpTextureManager{}
}

pub fn (mut tm GNUJumpTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/gnujump.png',
		'./assets/sprites/gnujump.png',
		'../assets/sprites/gnujump.png',
		'gnujump/assets/sprites/gnujump.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('gnujump Texture Loaded Successfully: ' + p)
				return
			}
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
	color Color
	size  int
}

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

fn draw_glass_card(renderer &Renderer, x int, y int, w int, h int, border_color Color) {
	bg_rect := Rect{
		x: x
		y: y
		w: w
		h: h
	}
	set_render_draw_color(renderer, 15, 23, 42, 235)
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
		65)
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
			110)
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
	set_render_draw_color(renderer, 255, 255, 255, 75)
	render_fill_rect(renderer, &top_line_rect)

	set_render_draw_color(renderer, btn.border_color.r, btn.border_color.g, btn.border_color.b,
		btn.border_color.a)
	render_draw_rect(renderer, &bg_rect)

	cx := btn.x + btn.w / 2
	ty := btn.y + (btn.h - 16) / 2
	draw_text_centered(renderer, cx, ty, btn.text, 2, btn.text_color)
}

fn render_tower_walls(renderer &Renderer, ticks u32) {
	// Background Tower Shaft
	bg_rect := Rect{
		x: wall_w
		y: 0
		w: play_width
		h: win_height
	}
	set_render_draw_color(renderer, 15, 23, 42, 255)
	render_fill_rect(renderer, &bg_rect)

	// Vertical Grid Lines
	set_render_draw_color(renderer, 30, 41, 59, 100)
	for gx := wall_w; gx < win_width - wall_w; gx += 40 {
		render_draw_line(renderer, gx, 0, gx, win_height)
	}

	// Vertical Ascension Light Beams
	set_render_draw_color(renderer, 59, 130, 246, 12)
	for beam in 0 .. 3 {
		bx := wall_w + (beam * 240 + int(ticks / 30)) % play_width
		beam_rect := Rect{
			x: bx
			y: 0
			w: 50
			h: win_height
		}
		render_fill_rect(renderer, &beam_rect)
	}

	// Left Side Tower Wall
	left_wall := Rect{
		x: 0
		y: 0
		w: wall_w
		h: win_height
	}
	set_render_draw_color(renderer, 30, 41, 59, 255)
	render_fill_rect(renderer, &left_wall)
	set_render_draw_color(renderer, 51, 65, 85, 255)
	render_draw_rect(renderer, &left_wall)

	// Neon Cyan Edge Strip Left
	set_render_draw_color(renderer, 34, 211, 238, 220)
	render_draw_line(renderer, wall_w - 1, 0, wall_w - 1, win_height)

	// Right Side Tower Wall
	right_wall := Rect{
		x: win_width - wall_w
		y: 0
		w: wall_w
		h: win_height
	}
	set_render_draw_color(renderer, 30, 41, 59, 255)
	render_fill_rect(renderer, &right_wall)
	set_render_draw_color(renderer, 51, 65, 85, 255)
	render_draw_rect(renderer, &right_wall)

	// Neon Cyan Edge Strip Right
	set_render_draw_color(renderer, 34, 211, 238, 220)
	render_draw_line(renderer, win_width - wall_w, 0, win_width - wall_w, win_height)
}

fn render_platform(renderer &Renderer, p Platform, ticks u32, tex &Texture) {
	if p.broken {
		return
	}
	px := int(p.x)
	py := int(p.y)
	pw := int(p.w)
	ph := int(p.h)

	if tex != unsafe { nil } {
		src := match p.kind {
			.standard { Rect{0, 136, 64, 24} }
			.ice { Rect{64, 136, 64, 24} }
			.spring { Rect{128, 136, 64, 24} }
			.crumbly { Rect{192, 136, 64, 24} }
		}
		dst := Rect{px, py, pw, ph}
		render_copy(renderer, tex, &src, &dst)
		return
	}

	rect := Rect{
		x: px
		y: py
		w: pw
		h: ph
	}

	match p.kind {
		.standard {
			set_render_draw_color(renderer, 59, 130, 246, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 147, 197, 253, 255)
			render_draw_rect(renderer, &rect)
		}
		.ice {
			set_render_draw_color(renderer, 34, 211, 238, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 207, 250, 254, 255)
			render_draw_rect(renderer, &rect)
		}
		.spring {
			set_render_draw_color(renderer, 245, 158, 11, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 254, 240, 138, 255)
			render_draw_rect(renderer, &rect)
		}
		.crumbly {
			pulse := int(math.sin(f64(ticks) * 0.03) * 40.0)
			set_render_draw_color(renderer, u8(220 + pulse / 2), 38, 38, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 254, 202, 202, 255)
			render_draw_rect(renderer, &rect)
		}
	}
}

fn render_jumper(renderer &Renderer, j Jumper, tex &Texture, is_p2 bool) {
	if !j.is_alive {
		return
	}
	jx := int(j.x)
	jy := int(j.y)
	jw := int(j.w)
	jh := int(j.h)

	if tex != unsafe { nil } {
		src_y := if is_p2 { 72 } else { 8 }
		src_x := if is_p2 {
			if j.is_facing_right { 0 } else { 48 }
		} else {
			if !j.on_ground {
				if j.is_facing_right { 96 } else { 144 }
			} else {
				if j.is_facing_right { 0 } else { 48 }
			}
		}
		src := Rect{src_x, src_y, 48, 48}
		dst := Rect{jx - 6, jy - 4, jw + 12, jh + 8}
		render_copy(renderer, tex, &src, &dst)
		return
	}

	rect := Rect{
		x: jx
		y: jy
		w: jw
		h: jh
	}
	set_render_draw_color(renderer, j.color.r, j.color.g, j.color.b, j.color.a)
	render_fill_rect(renderer, &rect)

	belly_rect := Rect{
		x: jx + 6
		y: jy + 12
		w: jw - 12
		h: jh - 16
	}
	set_render_draw_color(renderer, 255, 255, 255, 255)
	render_fill_rect(renderer, &belly_rect)

	eye_x := if j.is_facing_right { jx + jw - 12 } else { jx + 6 }
	draw_filled_circle(renderer, eye_x, jy + 8, 3, Color{ r: 15, g: 23, b: 42 })

	beak_x := if j.is_facing_right { jx + jw - 4 } else { jx - 4 }
	beak_rect := Rect{
		x: beak_x
		y: jy + 10
		w: 6
		h: 5
	}
	set_render_draw_color(renderer, 245, 158, 11, 255)
	render_fill_rect(renderer, &beak_rect)
}

fn render_lava(renderer &Renderer, lava_y f64, ticks u32, tex &Texture) {
	ly := int(lava_y)
	if ly >= win_height {
		return
	}

	lava_rect := Rect{
		x: wall_w
		y: ly
		w: play_width
		h: win_height - ly
	}
	set_render_draw_color(renderer, 220, 38, 38, 255)
	render_fill_rect(renderer, &lava_rect)

	// Animated Undulating Heat Wave Crests & Bubbles
	set_render_draw_color(renderer, 250, 204, 21, 255)
	for x := wall_w; x < win_width - wall_w; x += 16 {
		wave_off := int(math.sin(f64(ticks) * 0.01 + f64(x) * 0.08) * 4.0)
		if tex != unsafe { nil } {
			bubble_src := (int(ticks / 120) + x / 16) % 4
			src := Rect{bubble_src * 48, 204, 24, 24}
			dst := Rect{x, ly + wave_off - 6, 16, 16}
			render_copy(renderer, tex, &src, &dst)
		} else {
			wave_rect := Rect{
				x: x
				y: ly + wave_off
				w: 16
				h: 5
			}
			render_fill_rect(renderer, &wave_rect)
		}
	}
}
