module main

import math
import os
import rand

pub struct Particle {
pub mut:
	x        f64
	y        f64
	dx       f64
	dy       f64
	life     f64
	max_life f64
	color    Color
	size     f64
	is_spark bool
}

pub fn create_explosion_particles(cx f64, cy f64) []Particle {
	mut parts := []Particle{cap: 60}
	for _ in 0 .. 50 {
		angle := (f64(rand.intn(360) or { 0 }) * math.pi) / 180.0
		speed := 50.0 + f64(rand.intn(200) or { 100 })
		life := 0.4 + f64(rand.intn(40) or { 20 }) / 100.0
		r_val := u8(220 + rand.intn(35) or { 30 })
		g_val := u8(rand.intn(180) or { 100 })
		parts << Particle{
			x:        cx
			y:        cy
			dx:       math.cos(angle) * speed
			dy:       math.sin(angle) * speed
			life:     life
			max_life: life
			color:    Color{r: r_val, g: g_val, b: 20}
			size:     3.0 + f64(rand.intn(4) or { 2 })
			is_spark: rand.intn(2) or { 0 } == 1
		}
	}
	return parts
}

pub fn create_confetti_particles(win_w int, win_h int) []Particle {
	mut parts := []Particle{cap: 80}
	palette := [
		Color{r: 255, g: 70, b: 120},
		Color{r: 70, g: 220, b: 255},
		Color{r: 255, g: 230, b: 80},
		Color{r: 80, g: 255, b: 130},
		Color{r: 180, g: 100, b: 255},
	]
	for _ in 0 .. 70 {
		px := f64(rand.intn(win_w) or { win_w / 2 })
		py := f64(rand.intn(100) or { 50 })
		speed_x := -40.0 + f64(rand.intn(80) or { 40 })
		speed_y := 60.0 + f64(rand.intn(140) or { 80 })
		life := 1.5 + f64(rand.intn(150) or { 100 }) / 100.0
		col := palette[rand.intn(palette.len) or { 0 }]
		parts << Particle{
			x:        px
			y:        py
			dx:       speed_x
			dy:       speed_y
			life:     life
			max_life: life
			color:    col
			size:     4.0 + f64(rand.intn(4) or { 2 })
		}
	}
	return parts
}

pub fn update_particles(mut particles []Particle, dt f64) {
	for mut p in particles {
		p.x += p.dx * dt
		p.y += p.dy * dt
		p.dy += 80.0 * dt // Gravity
		p.life -= dt
	}
	// Filter expired particles
	mut alive := []Particle{cap: particles.len}
	for p in particles {
		if p.life > 0 {
			alive << p
		}
	}
	particles = alive.clone()
}

pub fn render_particles(renderer &Renderer, particles []Particle) {
	for p in particles {
		alpha := u8(math.clamp(p.life / p.max_life * 255.0, 0, 255))
		set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, alpha)
		sz := int(p.size)
		rect := Rect{
			x: int(p.x) - sz / 2
			y: int(p.y) - sz / 2
			w: sz
			h: sz
		}
		render_fill_rect(renderer, &rect)
	}
}

// 3D Beveled Box Helper
pub fn draw_bevel_rect(renderer &Renderer, x int, y int, w int, h int, is_raised bool, bg Color, light Color, dark Color, border_thick int) {
	// Background
	set_render_draw_color(renderer, bg.r, bg.g, bg.b, bg.a)
	rect := Rect{x: x, y: y, w: w, h: h}
	render_fill_rect(renderer, &rect)

	tl_color := if is_raised { light } else { dark }
	br_color := if is_raised { dark } else { light }

	// Top & Left borders
	set_render_draw_color(renderer, tl_color.r, tl_color.g, tl_color.b, tl_color.a)
	for t in 0 .. border_thick {
		// Top line
		render_draw_line(renderer, x + t, y + t, x + w - 1 - t, y + t)
		// Left line
		render_draw_line(renderer, x + t, y + t, x + t, y + h - 1 - t)
	}

	// Bottom & Right borders
	set_render_draw_color(renderer, br_color.r, br_color.g, br_color.b, br_color.a)
	for t in 0 .. border_thick {
		// Bottom line
		render_draw_line(renderer, x + t, y + h - 1 - t, x + w - 1 - t, y + h - 1 - t)
		// Right line
		render_draw_line(renderer, x + w - 1 - t, y + t, x + w - 1 - t, y + h - 1 - t)
	}
}

pub struct MinesweeperTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm MinesweeperTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/minesweeper.png',
		'./assets/sprites/minesweeper.png',
		'../assets/sprites/minesweeper.png',
		'minesweeper/assets/sprites/minesweeper.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('minesweeper Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

pub fn draw_mine_icon(renderer &Renderer, cx int, cy int, size int, exploded bool, tex &Texture) {
	if tex != unsafe { nil } {
		col_x := if exploded { 128 } else { 64 }
		src := Rect{ x: col_x, y: 64, w: 64, h: 64 }
		dst := Rect{ x: cx - size / 2, y: cy - size / 2, w: size, h: size }
		render_copy(renderer, tex, &src, &dst)
		return
	}

	r := size / 3

	if exploded {
		// Red blast background glow
		set_render_draw_color(renderer, 255, 40, 40, 255)
		glow := Rect{x: cx - size / 2, y: cy - size / 2, w: size, h: size}
		render_fill_rect(renderer, &glow)
	}

	// Black mine body
	set_render_draw_color(renderer, 20, 20, 25, 255)
	body := Rect{x: cx - r, y: cy - r, w: r * 2 + 1, h: r * 2 + 1}
	render_fill_rect(renderer, &body)

	// Spikes
	spike_len := size / 2 - 2
	render_draw_line(renderer, cx - spike_len, cy, cx + spike_len, cy)
	render_draw_line(renderer, cx, cy - spike_len, cx, cy + spike_len)
	diag := int(f64(spike_len) * 0.707)
	render_draw_line(renderer, cx - diag, cy - diag, cx + diag, cy + diag)
	render_draw_line(renderer, cx - diag, cy + diag, cx + diag, cy - diag)

	// Specular highlight spot
	set_render_draw_color(renderer, 255, 255, 255, 255)
	spec := Rect{x: cx - r / 2, y: cy - r / 2, w: 2, h: 2}
	render_fill_rect(renderer, &spec)
}

pub fn draw_flag_icon(renderer &Renderer, cx int, cy int, size int, tex &Texture) {
	if tex != unsafe { nil } {
		src := Rect{ x: 192, y: 64, w: 64, h: 64 }
		dst := Rect{ x: cx - size / 2, y: cy - size / 2, w: size, h: size }
		render_copy(renderer, tex, &src, &dst)
		return
	}

	// Base
	set_render_draw_color(renderer, 20, 20, 20, 255)
	base_w := size / 2
	base_rect := Rect{x: cx - base_w / 2, y: cy + size / 3, w: base_w, h: 3}
	render_fill_rect(renderer, &base_rect)

	// Pole
	pole_h := int(f64(size) * 0.65)
	pole_rect := Rect{x: cx - 1, y: cy - size / 3, w: 2, h: pole_h}
	render_fill_rect(renderer, &pole_rect)

	// Triangular Red Flag
	set_render_draw_color(renderer, 240, 20, 30, 255)
	flag_h := size / 3
	flag_w := size / 3 + 2
	for i in 0 .. flag_w {
		h_line := flag_h - (i * flag_h) / flag_w
		y_start := cy - size / 3
		render_draw_line(renderer, cx - 1 - i, y_start, cx - 1 - i, y_start + h_line)
	}
}

pub fn draw_wrong_flag_icon(renderer &Renderer, cx int, cy int, size int, tex &Texture) {
	if tex != unsafe { nil } {
		src := Rect{ x: 256, y: 64, w: 64, h: 64 }
		dst := Rect{ x: cx - size / 2, y: cy - size / 2, w: size, h: size }
		render_copy(renderer, tex, &src, &dst)
		return
	}

	draw_flag_icon(renderer, cx, cy, size, tex)

	// Draw Big Red X across the flag
	set_render_draw_color(renderer, 220, 0, 0, 255)
	pad := size / 4
	render_draw_line(renderer, cx - pad, cy - pad, cx + pad, cy + pad)
	render_draw_line(renderer, cx - pad + 1, cy - pad, cx + pad + 1, cy + pad)
	render_draw_line(renderer, cx - pad, cy + pad, cx + pad, cy - pad)
	render_draw_line(renderer, cx - pad + 1, cy + pad, cx + pad + 1, cy - pad)
}

pub fn draw_smiley_face(renderer &Renderer, cx int, cy int, r int, face FaceState, is_pressed bool, tex &Texture) {
	if tex != unsafe { nil } {
		col_x := match face {
			.normal { 0 }
			.shock { 64 }
			.cool { 128 }
			.dead { 192 }
		}
		src := Rect{ x: col_x, y: 128, w: 64, h: 64 }
		dst := Rect{ x: cx - r, y: cy - r, w: r * 2, h: r * 2 }
		render_copy(renderer, tex, &src, &dst)
		return
	}
	// Yellow Face Circle
	set_render_draw_color(renderer, 255, 215, 0, 255)
	for dy in -r .. r + 1 {
		dx_max := int(math.sqrt(f64(r * r - dy * dy)))
		render_draw_line(renderer, cx - dx_max, cy + dy, cx + dx_max, cy + dy)
	}

	// Black Outline
	set_render_draw_color(renderer, 40, 40, 20, 255)
	// Circle outline approximate
	for deg in 0 .. 360 {
		rad := f64(deg) * math.pi / 180.0
		px := cx + int(f64(r) * math.cos(rad))
		py := cy + int(f64(r) * math.sin(rad))
		render_draw_point(renderer, px, py)
	}

	eye_off_x := r / 3
	eye_off_y := r / 3

	match face {
		.normal {
			// Two dots for eyes
			set_render_draw_color(renderer, 20, 20, 20, 255)
			render_draw_point(renderer, cx - eye_off_x, cy - eye_off_y)
			render_draw_point(renderer, cx - eye_off_x, cy - eye_off_y + 1)
			render_draw_point(renderer, cx + eye_off_x, cy - eye_off_y)
			render_draw_point(renderer, cx + eye_off_x, cy - eye_off_y + 1)

			// Smile arc
			mouth_w := r / 2
			mouth_y := cy + r / 3
			render_draw_line(renderer, cx - mouth_w, mouth_y, cx + mouth_w, mouth_y)
			render_draw_point(renderer, cx - mouth_w - 1, mouth_y - 1)
			render_draw_point(renderer, cx + mouth_w + 1, mouth_y - 1)
		}
		.shock {
			// Shocked wide eyes
			set_render_draw_color(renderer, 20, 20, 20, 255)
			e_sz := 2
			render_draw_rect(renderer, &Rect{x: cx - eye_off_x - 1, y: cy - eye_off_y - 1, w: e_sz + 1, h: e_sz + 1})
			render_draw_rect(renderer, &Rect{x: cx + eye_off_x - 1, y: cy - eye_off_y - 1, w: e_sz + 1, h: e_sz + 1})

			// O-shaped mouth
			m_r := r / 4
			render_draw_rect(renderer, &Rect{x: cx - m_r, y: cy + r / 4, w: m_r * 2, h: m_r * 2})
		}
		.cool {
			// Sunglasses!
			set_render_draw_color(renderer, 15, 15, 20, 255)
			glass_w := r * 2 / 3
			glass_h := r / 3
			glass_left := Rect{x: cx - eye_off_x - glass_w / 2, y: cy - eye_off_y - 1, w: glass_w, h: glass_h}
			glass_right := Rect{x: cx + eye_off_x - glass_w / 2, y: cy - eye_off_y - 1, w: glass_w, h: glass_h}
			render_fill_rect(renderer, &glass_left)
			render_fill_rect(renderer, &glass_right)
			render_draw_line(renderer, cx - 2, cy - eye_off_y + 1, cx + 2, cy - eye_off_y + 1)

			// Smirk
			mouth_w := r / 2
			mouth_y := cy + r / 3
			render_draw_line(renderer, cx - mouth_w, mouth_y, cx + mouth_w, mouth_y + 1)
		}
		.dead {
			// X eyes
			set_render_draw_color(renderer, 20, 20, 20, 255)
			d_sz := 2
			// Left X
			render_draw_line(renderer, cx - eye_off_x - d_sz, cy - eye_off_y - d_sz, cx - eye_off_x + d_sz, cy - eye_off_y + d_sz)
			render_draw_line(renderer, cx - eye_off_x - d_sz, cy - eye_off_y + d_sz, cx - eye_off_x + d_sz, cy - eye_off_y - d_sz)
			// Right X
			render_draw_line(renderer, cx + eye_off_x - d_sz, cy - eye_off_y - d_sz, cx + eye_off_x + d_sz, cy - eye_off_y + d_sz)
			render_draw_line(renderer, cx + eye_off_x - d_sz, cy - eye_off_y + d_sz, cx + eye_off_x + d_sz, cy - eye_off_y - d_sz)

			// Frown
			mouth_w := r / 2
			mouth_y := cy + r / 2
			render_draw_line(renderer, cx - mouth_w, mouth_y, cx + mouth_w, mouth_y)
			render_draw_point(renderer, cx - mouth_w - 1, mouth_y + 1)
			render_draw_point(renderer, cx + mouth_w + 1, mouth_y + 1)
		}
	}
}
