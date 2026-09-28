module main

import math

pub struct Particle {
pub mut:
	x           f64
	y           f64
	vx          f64
	vy          f64
	life        f64
	max_life    f64 = 1.0
	color       Color
	size        f64
	is_bubble   bool
	is_smoke    bool
	is_shrapnel bool
	is_fire     bool
	is_splash   bool
	rot         f64
	vrot        f64
}

pub struct ShockwaveRing {
pub mut:
	x        f64
	y        f64
	r        f64
	max_r    f64
	life     f64
	max_life f64
	col      Color
}

pub struct FloatText {
pub mut:
	x     f64
	y     f64
	text  string
	life  f64
	color Color
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

fn draw_circle_outline(renderer &Renderer, cx int, cy int, r int, thickness int, color Color) {
	if r <= 0 {
		return
	}
	set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	for t := 0; t < thickness; t++ {
		radius := r - t
		if radius <= 0 {
			break
		}
		mut x := radius
		mut y := 0
		mut err := 0

		for x >= y {
			render_draw_point(renderer, cx + x, cy + y)
			render_draw_point(renderer, cx + y, cy + x)
			render_draw_point(renderer, cx - y, cy + x)
			render_draw_point(renderer, cx - x, cy + y)
			render_draw_point(renderer, cx - x, cy - y)
			render_draw_point(renderer, cx - y, cy - x)
			render_draw_point(renderer, cx + y, cy - x)
			render_draw_point(renderer, cx + x, cy - y)

			if err <= 0 {
				y++
				err += 2 * y + 1
			}
			if err > 0 {
				x--
				err -= 2 * x + 1
			}
		}
	}
}

fn draw_glass_card(renderer &Renderer, x int, y int, w int, h int, border_color Color) {
	bg_rect := Rect{
		x: x
		y: y
		w: w
		h: h
	}
	set_render_draw_color(renderer, 15, 23, 42, 230)
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

fn (b Button) is_hovered(mx int, my int) bool {
	return mx >= b.x && mx <= b.x + b.w && my >= b.y && my <= b.y + b.h
}

fn (b Button) render(renderer &Renderer, mx int, my int) {
	hover := b.is_hovered(mx, my)
	col := if hover { b.hover_color } else { b.bg_color }

	bg_rect := Rect{
		x: b.x
		y: b.y
		w: b.w
		h: b.h
	}
	set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
	render_fill_rect(renderer, &bg_rect)

	top_line_rect := Rect{
		x: b.x + 1
		y: b.y + 1
		w: b.w - 2
		h: 2
	}
	set_render_draw_color(renderer, 255, 255, 255, 60)
	render_fill_rect(renderer, &top_line_rect)

	set_render_draw_color(renderer, b.border_color.r, b.border_color.g, b.border_color.b,
		b.border_color.a)
	render_draw_rect(renderer, &bg_rect)

	cx := b.x + b.w / 2
	ty := b.y + (b.h - 16) / 2
	draw_text_centered(renderer, cx, ty, b.text, 2, b.text_color)
}

fn render_ocean_background(renderer &Renderer, ticks u32) {
	// Sky (0 to water_level_y)
	sky_rect := Rect{
		x: 0
		y: 0
		w: ocean_width
		h: water_level_y
	}
	set_render_draw_color(renderer, 10, 15, 32, 255)
	render_fill_rect(renderer, &sky_rect)

	// Stars in Sky
	set_render_draw_color(renderer, 220, 235, 255, 180)
	for i in 0 .. 25 {
		sx := (i * 47) % ocean_width
		sy := 20 + (i * 31) % (water_level_y - 40)
		render_draw_point(renderer, sx, sy)
	}

	// Water Deep Ocean Gradient
	water_rect := Rect{
		x: 0
		y: water_level_y
		w: ocean_width
		h: ocean_height - water_level_y
	}
	set_render_draw_color(renderer, 2, 12, 35, 255)
	render_fill_rect(renderer, &water_rect)

	// Animated Sunbeams Filtering Down
	set_render_draw_color(renderer, 34, 211, 238, 25)
	for beam in 0 .. 5 {
		bx := (beam * 220 + int(ticks / 40)) % ocean_width
		beam_rect := Rect{
			x: bx
			y: water_level_y
			w: 60
			h: ocean_height - water_level_y
		}
		render_fill_rect(renderer, &beam_rect)
	}

	// Animated Water Surface Wave Crests
	set_render_draw_color(renderer, 34, 211, 238, 220)
	surf_y := water_level_y
	for x := 0; x < ocean_width; x += 16 {
		wave_off := int(math.sin(f64(ticks) * 0.005 + f64(x) * 0.05) * 3.0)
		wave_rect := Rect{
			x: x
			y: surf_y + wave_off
			w: 16
			h: 3
		}
		render_fill_rect(renderer, &wave_rect)
	}

	// Swaying Kelp Forests on Seabed
	set_render_draw_color(renderer, 16, 185, 129, 140)
	for k in 0 .. 8 {
		kx := k * 130 + 40
		sway := int(math.sin(f64(ticks) * 0.003 + f64(k)) * 12.0)
		for h := 0; h < 70; h += 4 {
			cur_x := kx + (sway * h) / 70
			cur_y := ocean_height - h
			kelp_rect := Rect{
				x: cur_x
				y: cur_y
				w: 5
				h: 4
			}
			render_fill_rect(renderer, &kelp_rect)
		}
	}
}

fn render_ship(renderer &Renderer, ship Ship, has_shield bool, ticks u32, tex &Texture) {
	sx := int(ship.x - ship.w / 2.0)
	sy := int(ship.y)
	sw := int(ship.w)
	sh := int(ship.h)

	// Arc Shield Concentric Forcefield Bubble
	if has_shield {
		pulse := int(math.sin(f64(ticks) * 0.02) * 3.0)
		draw_circle_outline(renderer, int(ship.x), sy + sh / 2, sw / 2 + 10 + pulse, 3,
			Color{ r: 34, g: 211, b: 238 })
		draw_circle_outline(renderer, int(ship.x), sy + sh / 2, sw / 2 + 6 + pulse, 2,
			Color{ r: 100, g: 240, b: 255 })
	}

	// Water Wake Spray at Stern
	if math.abs(ship.speed) > 0.5 {
		wake_x := if ship.dir == 1 { sx - 12 } else { sx + sw + 4 }
		draw_filled_circle(renderer, wake_x, sy + sh - 4, 6, Color{ r: 255, g: 255, b: 255, a: 160 })
	}

	if tex != unsafe { nil } {
		src := Rect{x: 4, y: 16, w: 88, h: 28}
		dst := Rect{x: sx, y: sy, w: sw, h: sh}
		flip := if ship.dir == -1 { RendererFlip.horizontal } else { RendererFlip.none }
		render_copy_ex(renderer, tex, &src, &dst, 0.0, unsafe { nil }, flip)
		return
	}

	// Procedural Fallback
	hull_rect := Rect{
		x: sx
		y: sy + 10
		w: sw
		h: sh - 10
	}
	set_render_draw_color(renderer, 51, 65, 85, 255)
	render_fill_rect(renderer, &hull_rect)

	top_highlight := Rect{
		x: sx + 2
		y: sy + 11
		w: sw - 4
		h: 3
	}
	set_render_draw_color(renderer, 148, 163, 184, 255)
	render_fill_rect(renderer, &top_highlight)

	stripe_rect := Rect{
		x: sx + sw / 2 - 4
		y: sy + 10
		w: 8
		h: sh - 10
	}
	set_render_draw_color(renderer, 250, 204, 21, 255)
	render_fill_rect(renderer, &stripe_rect)

	cabin_rect := Rect{
		x: sx + sw / 4
		y: sy
		w: sw / 2
		h: 12
	}
	set_render_draw_color(renderer, 30, 41, 59, 255)
	render_fill_rect(renderer, &cabin_rect)

	radar_cx := sx + sw / 2
	radar_sway := int(math.sin(f64(ticks) * 0.08) * 8.0)
	set_render_draw_color(renderer, 34, 211, 238, 255)
	render_draw_line(renderer, radar_cx, sy - 4, radar_cx + radar_sway, sy - 4)

	cannon_x := if ship.dir == 1 { sx + sw - 6 } else { sx + 2 }
	cannon_rect := Rect{
		x: cannon_x
		y: sy + 6
		w: 8
		h: 4
	}
	set_render_draw_color(renderer, 15, 23, 42, 255)
	render_fill_rect(renderer, &cannon_rect)

	set_render_draw_color(renderer, 148, 163, 184, 255)
	render_draw_rect(renderer, &hull_rect)
}

fn render_submarine(renderer &Renderer, sub Submarine, ticks u32, tex &Texture) {
	sx := int(sub.x)
	sy := int(sub.y)
	sw := int(sub.w)
	sh := int(sub.h)

	// Headlight Cone Beam Underwater
	beam_dir := if sub.speed > 0 { 1 } else { -1 }
	beam_start_x := if sub.speed > 0 { sx + sw } else { sx }
	set_render_draw_color(renderer, 255, 255, 200, 30)
	for b := 0; b < 60; b += 4 {
		bx := beam_start_x + beam_dir * b
		by := sy + sh / 2 - b / 3
		bh := b * 2 / 3 + 4
		beam_rect := Rect{
			x: if sub.speed > 0 { bx } else { bx - 4 }
			y: by
			w: 4
			h: bh
		}
		render_fill_rect(renderer, &beam_rect)
	}

	if tex != unsafe { nil } {
		src := match sub.kind {
			.standard { Rect{x: 4, y: 76, w: 68, h: 22} }
			.fast { Rect{x: 84, y: 78, w: 60, h: 18} }
			.heavy { Rect{x: 164, y: 72, w: 84, h: 26} }
			.boss { Rect{x: 264, y: 66, w: 108, h: 34} }
		}
		dst := Rect{x: sx, y: sy, w: sw, h: sh}
		flip := if sub.speed < 0 { RendererFlip.horizontal } else { RendererFlip.none }
		render_copy_ex(renderer, tex, &src, &dst, 0.0, unsafe { nil }, flip)
		return
	}

	// Procedural Fallback
	rect := Rect{
		x: sx
		y: sy
		w: sw
		h: sh
	}
	set_render_draw_color(renderer, sub.color.r, sub.color.g, sub.color.b, sub.color.a)
	render_fill_rect(renderer, &rect)

	top_line := Rect{
		x: sx + 2
		y: sy + 1
		w: sw - 4
		h: 2
	}
	set_render_draw_color(renderer, 255, 255, 255, 90)
	render_fill_rect(renderer, &top_line)

	tower_rect := Rect{
		x: sx + sw / 2 - 6
		y: sy - 8
		w: 12
		h: 8
	}
	set_render_draw_color(renderer, sub.color.r, sub.color.g, sub.color.b, 255)
	render_fill_rect(renderer, &tower_rect)

	for p := 0; p < 3; p++ {
		px := sx + 12 + p * (sw / 4)
		py := sy + sh / 2
		draw_filled_circle(renderer, px, py, 3, Color{ r: 250, g: 204, b: 21, a: 220 })
	}

	beacon_x := if sub.speed > 0 { sx + 4 } else { sx + sw - 4 }
	draw_filled_circle(renderer, beacon_x, sy + 3, 3, Color{ r: 239, g: 68, b: 68, a: 255 })

	prop_x := if sub.speed > 0 { sx - 4 } else { sx + sw }
	prop_phase := int(math.sin(f64(ticks) * 0.3) * 6.0)
	prop_rect := Rect{
		x: prop_x
		y: sy + sh / 2 - 3 + prop_phase / 2
		w: 4
		h: 6
	}
	set_render_draw_color(renderer, 200, 200, 200, 255)
	render_fill_rect(renderer, &prop_rect)

	set_render_draw_color(renderer, 255, 255, 255, 120)
	render_draw_rect(renderer, &rect)
}

fn render_supply_crate(renderer &Renderer, crate Crate, _ u32, tex &Texture) {
	cx := int(crate.x)
	cy := int(crate.y)

	// Canvas Parachute Canopy Overhead (if falling above water)
	if crate.y < f64(water_level_y - 10) {
		set_render_draw_color(renderer, 255, 255, 255, 220)
		for px := -14; px <= 14; px++ {
			py := int(math.sqrt(f64(196 - px * px)))
			render_draw_point(renderer, cx + px, cy - 20 - py / 2)
		}
		set_render_draw_color(renderer, 200, 200, 200, 180)
		render_draw_line(renderer, cx - 12, cy - 20, cx - 8, cy - 8)
		render_draw_line(renderer, cx + 12, cy - 20, cx + 8, cy - 8)
	}

	if tex != unsafe { nil } {
		src_x := match crate.kind {
			.shield { 0 }
			.triple { 32 }
			.hyper { 64 }
			.nuke { 96 }
		}
		src := Rect{x: src_x, y: 160, w: 32, h: 32}
		dst := Rect{x: cx - 10, y: cy - 10, w: 20, h: 20}
		render_copy(renderer, tex, &src, &dst)
		return
	}

	// Procedural Fallback
	c_rect := Rect{
		x: cx - 10
		y: cy - 10
		w: 20
		h: 20
	}

	c_color := match crate.kind {
		.shield { Color{ r: 34, g: 211, b: 238 } }
		.triple { Color{ r: 99, g: 102, b: 241 } }
		.hyper { Color{ r: 245, g: 158, b: 11 } }
		.nuke { Color{ r: 239, g: 68, b: 68 } }
	}

	set_render_draw_color(renderer, c_color.r, c_color.g, c_color.b, 255)
	render_fill_rect(renderer, &c_rect)

	set_render_draw_color(renderer, 255, 255, 255, 160)
	render_draw_rect(renderer, &c_rect)

	emblem := match crate.kind {
		.shield { 'S' }
		.triple { '3' }
		.hyper { 'H' }
		.nuke { 'N' }
	}
	draw_text_centered(renderer, cx, cy - 6, emblem, 1, Color{ r: 15, g: 23, b: 42 })
}

fn render_depth_charge(renderer &Renderer, dc DepthCharge, ticks u32, tex &Texture) {
	cx := int(dc.x)
	cy := int(dc.y)

	if tex != unsafe { nil } {
		src := Rect{x: 0, y: 128, w: 32, h: 32}
		dst := Rect{x: cx - 8, y: cy - 8, w: 16, h: 16}
		render_copy(renderer, tex, &src, &dst)
		// Blinking LED fuse
		if (ticks / 100) % 2 == 0 {
			draw_filled_circle(renderer, cx, cy - 4, 2, Color{ r: 239, g: 68, b: 68 })
		}
		return
	}

	draw_filled_circle(renderer, cx, cy, 6, Color{ r: 245, g: 158, b: 11 })
	draw_circle_outline(renderer, cx, cy, 6, 1, Color{ r: 180, g: 83, b: 9 })
	if (ticks / 100) % 2 == 0 {
		draw_filled_circle(renderer, cx, cy - 3, 2, Color{ r: 239, g: 68, b: 68 })
	}
}

fn render_torpedo(renderer &Renderer, torp Torpedo, _ u32, tex &Texture) {
	tx := int(torp.x)
	ty := int(torp.y)

	if tex != unsafe { nil } {
		src := Rect{x: 32, y: 128, w: 32, h: 32}
		dst := Rect{x: tx - 8, y: ty - 8, w: 16, h: 16}
		render_copy_ex(renderer, tex, &src, &dst, -90.0, unsafe { nil }, RendererFlip.none)
		draw_filled_circle(renderer, tx, ty + 7, 2, Color{ r: 255, g: 255, b: 255, a: 180 })
		return
	}

	draw_filled_circle(renderer, tx, ty, 5, Color{ r: 239, g: 68, b: 68 })
	draw_circle_outline(renderer, tx, ty, 5, 1, Color{ r: 255, g: 255, b: 255 })
	draw_filled_circle(renderer, tx, ty + 6, 2, Color{ r: 255, g: 255, b: 255, a: 180 })
}

fn render_mine(renderer &Renderer, mine Mine, _ u32, tex &Texture) {
	mx := int(mine.x)
	my := int(mine.y)

	if tex != unsafe { nil } {
		src := Rect{x: 64, y: 128, w: 32, h: 32}
		dst := Rect{x: mx - 10, y: my - 10, w: 20, h: 20}
		render_copy(renderer, tex, &src, &dst)
		return
	}

	draw_filled_circle(renderer, mx, my, 6, Color{ r: 220, g: 38, b: 38 })
	draw_circle_outline(renderer, mx, my, 6, 1, Color{ r: 153, g: 27, b: 27 })
	set_render_draw_color(renderer, 220, 38, 38, 255)
	render_draw_line(renderer, mx - 8, my, mx + 8, my)
	render_draw_line(renderer, mx, my - 8, mx, my + 8)
}

fn render_particles(renderer &Renderer, particles []Particle) {
	for p in particles {
		px := int(p.x)
		py := int(p.y)
		sz := int(p.size)

		if p.is_shrapnel {
			// Rotating jagged metal chunk
			set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, p.color.a)
			rect := Rect{
				x: px - sz / 2
				y: py - sz / 2
				w: sz
				h: int(math.max(2.0, f64(sz) * 0.6))
			}
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 255, 255, 255, 140)
			render_draw_rect(renderer, &rect)
		} else if p.is_bubble {
			// Translucent bubble with light highlight
			draw_circle_outline(renderer, px, py, sz, 1, p.color)
			draw_filled_circle(renderer, px - 1, py - 1, int(math.max(1.0, f64(sz) * 0.4)), Color{255, 255, 255, 200})
		} else if p.is_splash {
			// Water droplets
			set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, p.color.a)
			drop := Rect{x: px - 1, y: py - 2, w: 2, h: 4}
			render_fill_rect(renderer, &drop)
		} else if p.is_fire {
			draw_filled_circle(renderer, px, py, sz, p.color)
			if sz > 2 {
				draw_filled_circle(renderer, px, py, sz / 2, Color{255, 255, 220, 240})
			}
		} else {
			draw_filled_circle(renderer, px, py, sz, p.color)
		}
	}
}

fn render_shockwaves(renderer &Renderer, shockwaves []ShockwaveRing) {
	for sw in shockwaves {
		cx := int(sw.x)
		cy := int(sw.y)
		r := int(sw.r)
		if r > 1 {
			alpha := u8(math.clamp((1.0 - (sw.life / sw.max_life)) * 255.0, 0.0, 255.0))
			draw_circle_outline(renderer, cx, cy, r, 2, Color{sw.col.r, sw.col.g, sw.col.b, alpha})
		}
	}
}

fn render_float_texts(renderer &Renderer, float_texts []FloatText) {
	for ft in float_texts {
		draw_text_centered(renderer, int(ft.x), int(ft.y), ft.text, 2, ft.color)
	}
}

fn render_damage_vignette(renderer &Renderer, timer f64, win_w int, win_h int) {
	if timer <= 0.0 {
		return
	}
	alpha := u8(math.clamp((timer / 0.45) * 160.0, 0.0, 160.0))
	set_render_draw_color(renderer, 239, 68, 68, alpha)

	// Thick red border pulse
	border_w := 12
	top_bar := Rect{0, 0, win_w, border_w}
	bot_bar := Rect{0, win_h - border_w, win_w, border_w}
	left_bar := Rect{0, 0, border_w, win_h}
	right_bar := Rect{win_w - border_w, 0, border_w, win_h}

	render_fill_rect(renderer, &top_bar)
	render_fill_rect(renderer, &bot_bar)
	render_fill_rect(renderer, &left_bar)
	render_fill_rect(renderer, &right_bar)
}
