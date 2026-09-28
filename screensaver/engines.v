module main

import math
import rand


pub fn fill_rect_c(renderer &Renderer, x int, y int, w int, h int, c Color) {
	set_render_draw_color(renderer, c.r, c.g, c.b, c.a)
	rect := Rect{ x: x, y: y, w: w, h: h }
	render_fill_rect(renderer, &rect)
}

pub fn draw_rect_c(renderer &Renderer, x int, y int, w int, h int, c Color) {
	set_render_draw_color(renderer, c.r, c.g, c.b, c.a)
	rect := Rect{ x: x, y: y, w: w, h: h }
	render_draw_rect(renderer, &rect)
}

pub fn draw_line_c(renderer &Renderer, x1 int, y1 int, x2 int, y2 int, c Color) {
	set_render_draw_color(renderer, c.r, c.g, c.b, c.a)
	render_draw_line(renderer, x1, y1, x2, y2)
}

// ----------------------------------------------------------------------
// 1. Matrix Digital Rain Engine
// ----------------------------------------------------------------------
pub fn render_matrix(renderer &Renderer, t &ScreensaverTemplate, mut state ScreensaverState, w int, h int) {
	cols := w / 16
	if state.particles.len < cols {
		state.particles.clear()
		for x in 0 .. cols {
			state.particles << Particle{
				x: f64(x * 16)
				y: f64(rand.int_in_range(-500, 0) or { 0 })
				vy: 4.0 + f64(rand.int_in_range(2, 7) or { 3 }) * t.speed
				size: rand.int_in_range(8, 24) or { 14 }
				active: true
			}
		}
	}

	fill_rect_c(renderer, 0, 0, w, h, Color{ r: 5, g: 8, b: 5, a: 255 })

	for mut p in state.particles {
		p.y += p.vy
		if p.y > f64(h + p.size * 16) {
			p.y = f64(rand.int_in_range(-100, 0) or { 0 })
			p.vy = 4.0 + f64(rand.int_in_range(2, 7) or { 3 }) * t.speed
		}

		head_y := int(p.y)
		for seg := 0; seg < p.size; seg++ {
			gy := head_y - seg * 16
			if gy >= 0 && gy < h {
				mut char_code := u8(33 + (int(p.x) / 16 + seg + int(state.frame_count / 4)) % 90)
				if t.sub_mode == 2 {
					char_code = if (seg + int(state.frame_count)) % 2 == 0 { `0` } else { `1` }
				}
				c := if seg == 0 {
					t.accent_color // Glowing tip
				} else if seg < 3 {
					t.primary_color
				} else {
					fade := f64(p.size - seg) / f64(p.size)
					Color{
						r: u8(f64(t.secondary_color.r) * fade)
						g: u8(f64(t.secondary_color.g) * fade)
						b: u8(f64(t.secondary_color.b) * fade)
						a: 255
					}
				}
				draw_char(renderer, int(p.x), gy, char_code, 2, c)
			}
		}
	}
}

// ----------------------------------------------------------------------
// 2. 3D Pipes Engine
// ----------------------------------------------------------------------
pub fn render_pipes(renderer &Renderer, t &ScreensaverTemplate, mut state ScreensaverState, w int, h int) {
	if state.pipes.len == 0 {
		fill_rect_c(renderer, 0, 0, w, h, Color{ r: 10, g: 10, b: 12, a: 255 })
		for _ in 0 .. t.density {
			state.pipes << PipeJoint{
				x: rand.int_in_range(40, w - 40) or { 100 }
				y: rand.int_in_range(40, h - 40) or { 100 }
				z: 0
				dir: rand.int_in_range(0, 4) or { 0 }
				color: if state.pipes.len % 2 == 0 { t.primary_color } else { t.secondary_color }
			}
		}
	}

	for mut p in state.pipes {
		// Draw previous joint sphere
		fill_rect_c(renderer, p.x - 7, p.y - 7, 14, 14, p.color)
		fill_rect_c(renderer, p.x - 3, p.y - 3, 6, 6, t.accent_color)

		// Step pipe forward
		step := 16
		mut next_x := p.x
		mut next_y := p.y

		match p.dir {
			0 { next_x += step } // Right
			1 { next_x -= step } // Left
			2 { next_y += step } // Down
			3 { next_y -= step } // Up
			else {}
		}

		// Draw pipe segment
		if p.dir == 0 || p.dir == 1 {
			fill_rect_c(renderer, math.min(p.x, next_x), p.y - 5, step, 10, p.color)
			fill_rect_c(renderer, math.min(p.x, next_x), p.y - 2, step, 4, t.accent_color)
		} else {
			fill_rect_c(renderer, p.x - 5, math.min(p.y, next_y), 10, step, p.color)
			fill_rect_c(renderer, p.x - 2, math.min(p.y, next_y), 4, step, t.accent_color)
		}

		p.x = next_x
		p.y = next_y

		// Random turn or edge bounce
		if rand.int_in_range(0, 5) or { 0 } == 0 || p.x < 30 || p.x > w - 30 || p.y < 30 || p.y > h - 30 {
			p.dir = rand.int_in_range(0, 4) or { 0 }
			if p.x < 30 { p.x = 30; p.dir = 0 }
			if p.x > w - 30 { p.x = w - 30; p.dir = 1 }
			if p.y < 30 { p.y = 30; p.dir = 2 }
			if p.y > h - 30 { p.y = h - 30; p.dir = 3 }
		}
	}

	// Reset screen periodically when full
	state.custom_int1++
	if state.custom_int1 > 1800 {
		state.pipes.clear()
		state.custom_int1 = 0
	}
}

// ----------------------------------------------------------------------
// 3. Starfield & Hyperspace Engine
// ----------------------------------------------------------------------
pub fn render_starfield(renderer &Renderer, t &ScreensaverTemplate, mut state ScreensaverState, w int, h int) {
	fill_rect_c(renderer, 0, 0, w, h, Color{ r: 0, g: 0, b: 5, a: 255 })
	cx := f64(w) / 2.0
	cy := f64(h) / 2.0

	if state.particles.len < t.density {
		for _ in state.particles.len .. t.density {
			state.particles << Particle{
				x: f64(rand.int_in_range(-w, w) or { 1 }),
				y: f64(rand.int_in_range(-h, h) or { 1 }),
				z: f64(rand.int_in_range(50, 1000) or { 500 }),
				vz: 8.0 * t.speed,
				color: t.primary_color
			}
		}
	}

	for mut p in state.particles {
		p.z -= p.vz
		if p.z <= 2.0 {
			p.x = f64(rand.int_in_range(-w, w) or { 1 })
			p.y = f64(rand.int_in_range(-h, h) or { 1 })
			p.z = 1000.0
		}

		k := 300.0 / p.z
		sx := cx + p.x * k
		sy := cy + p.y * k

		if sx >= 0 && sx < f64(w) && sy >= 0 && sy < f64(h) {
			size := int(math.max(1.0, (1.0 - p.z / 1000.0) * 4.0))
			prev_k := 300.0 / (p.z + p.vz * 2.0)
			prev_sx := cx + p.x * prev_k
			prev_sy := cy + p.y * prev_k

			// Warp streak line
			draw_line_c(renderer, int(prev_sx), int(prev_sy), int(sx), int(sy), t.secondary_color)
			fill_rect_c(renderer, int(sx), int(sy), size, size, t.accent_color)
		}
	}
}

// ----------------------------------------------------------------------
// 4. Mystify / Polyline Engine
// ----------------------------------------------------------------------
pub fn render_mystify(renderer &Renderer, t &ScreensaverTemplate, mut state ScreensaverState, w int, h int) {
	fill_rect_c(renderer, 0, 0, w, h, Color{ r: 0, g: 0, b: 0, a: 255 })

	if state.poly_verts.len < 4 {
		state.poly_verts.clear()
		for _ in 0 .. 4 {
			state.poly_verts << PolyVertex{
				x: f64(rand.int_in_range(100, w - 100) or { 200 })
				y: f64(rand.int_in_range(100, h - 100) or { 200 })
				vx: (3.0 + f64(rand.int_in_range(1, 4) or { 2 })) * t.speed
				vy: (2.5 + f64(rand.int_in_range(1, 4) or { 2 })) * t.speed
			}
		}
	}

	// Update vertices
	for mut v in state.poly_verts {
		v.x += v.vx
		v.y += v.vy
		if v.x <= 20 || v.x >= f64(w - 20) { v.vx = -v.vx }
		if v.y <= 20 || v.y >= f64(h - 20) { v.vy = -v.vy }
	}

	// Color shift
	hue_t := state.time_elapsed * 0.8
	poly_col := Color{
		r: u8(127.0 + 127.0 * math.sin(hue_t))
		g: u8(127.0 + 127.0 * math.sin(hue_t + 2.09))
		b: u8(127.0 + 127.0 * math.sin(hue_t + 4.18))
		a: 255
	}

	state.trails << TrailPoint{
		p1: state.poly_verts[0]
		p2: state.poly_verts[1]
		p3: state.poly_verts[2]
		p4: state.poly_verts[3]
		c: poly_col
	}

	max_trails := 16
	if state.trails.len > max_trails {
		state.trails.delete(0)
	}

	for idx, tr in state.trails {
		fade := f64(idx + 1) / f64(state.trails.len)
		c := Color{
			r: u8(f64(tr.c.r) * fade)
			g: u8(f64(tr.c.g) * fade)
			b: u8(f64(tr.c.b) * fade)
			a: 255
		}
		draw_line_c(renderer, int(tr.p1.x), int(tr.p1.y), int(tr.p2.x), int(tr.p2.y), c)
		draw_line_c(renderer, int(tr.p2.x), int(tr.p2.y), int(tr.p3.x), int(tr.p3.y), c)
		draw_line_c(renderer, int(tr.p3.x), int(tr.p3.y), int(tr.p4.x), int(tr.p4.y), c)
		draw_line_c(renderer, int(tr.p4.x), int(tr.p4.y), int(tr.p1.x), int(tr.p1.y), c)
	}
}

// ----------------------------------------------------------------------
// 5. 3D Maze Engine
// ----------------------------------------------------------------------
pub fn render_maze(renderer &Renderer, t &ScreensaverTemplate, mut state ScreensaverState, w int, h int) {
	// 3D Corridor Perspective
	fill_rect_c(renderer, 0, 0, w, h / 2, Color{ r: 40, g: 40, b: 50, a: 255 }) // Ceiling
	fill_rect_c(renderer, 0, h / 2, w, h / 2, Color{ r: 30, g: 30, b: 35, a: 255 }) // Floor

	anim := math.sin(state.time_elapsed * 1.5) * 40.0
	fwd := (int(state.time_elapsed * 120.0) % 100)

	// Draw Receding Brick Wall Frames
	for i := 4; i >= 0; i-- {
		inset := i * 70 + fwd / 2
		wall_w := w - inset * 2
		wall_h := h - inset * 2
		if wall_w > 20 && wall_h > 20 {
			wx := inset + int(anim * (f64(4 - i) / 4.0))
			wy := inset

			// Side walls
			fill_rect_c(renderer, wx, wy, 25, wall_h, t.secondary_color)
			fill_rect_c(renderer, wx + wall_w - 25, wy, 25, wall_h, t.secondary_color)

			// Brick outlines
			draw_rect_c(renderer, wx, wy, wall_w, wall_h, t.primary_color)
		}
	}

	// Centered Smiley or Rat in Corridor
	cx := w / 2 + int(anim)
	cy := h / 2
	fill_rect_c(renderer, cx - 30, cy - 30, 60, 60, t.accent_color)
	fill_rect_c(renderer, cx - 15, cy - 15, 8, 12, Color{ r: 0, g: 0, b: 0 })
	fill_rect_c(renderer, cx + 7, cy - 15, 8, 12, Color{ r: 0, g: 0, b: 0 })
	fill_rect_c(renderer, cx - 15, cy + 10, 30, 6, Color{ r: 0, g: 0, b: 0 })

	draw_text_centered(renderer, w / 2, 40, '3D MAZE EXPLORATION', 2, t.accent_color)
}

// ----------------------------------------------------------------------
// 6. 3D Text & Marquee Engine
// ----------------------------------------------------------------------
pub fn render_3d_text(renderer &Renderer, t &ScreensaverTemplate, mut state ScreensaverState, w int, h int) {
	fill_rect_c(renderer, 0, 0, w, h, Color{ r: 0, g: 0, b: 0, a: 255 })
	text := if t.custom_text.len > 0 { t.custom_text } else { 'V ARCADE' }

	rot := state.time_elapsed * 1.5 * t.speed
	scale_val := 3.0 + math.sin(rot) * 1.2

	cx := f64(w) / 2.0 + math.sin(rot * 0.7) * 150.0
	cy := f64(h) / 2.0 + math.cos(rot * 0.9) * 80.0

	// 3D Extrusion Layers
	for layer := 10; layer >= 0; layer-- {
		off_x := int(cx + f64(layer) * math.cos(rot) * 2.0)
		off_y := int(cy + f64(layer) * math.sin(rot) * 2.0)

		c := if layer == 0 {
			t.accent_color
		} else {
			shade := f64(10 - layer) / 10.0
			Color{
				r: u8(f64(t.primary_color.r) * shade)
				g: u8(f64(t.primary_color.g) * shade)
				b: u8(f64(t.primary_color.b) * shade)
				a: 255
			}
		}
		draw_text_centered(renderer, off_x, off_y, text, int(scale_val), c)
	}
}

// ----------------------------------------------------------------------
// 7. Flying Objects Engine (Windows Logo / Toasters)
// ----------------------------------------------------------------------
pub fn render_flying_objects(renderer &Renderer, t &ScreensaverTemplate, mut state ScreensaverState, w int, h int) {
	fill_rect_c(renderer, 0, 0, w, h, Color{ r: 5, g: 5, b: 15, a: 255 })

	if state.particles.len < t.density {
		for _ in state.particles.len .. t.density {
			state.particles << Particle{
				x: f64(rand.int_in_range(50, w - 50) or { 200 })
				y: f64(rand.int_in_range(50, h - 50) or { 200 })
				vx: f64(rand.int_in_range(-3, 4) or { 2 }) * t.speed
				vy: f64(rand.int_in_range(-3, 4) or { 2 }) * t.speed
				size: 48
				life: f64(rand.int_in_range(0, 100) or { 0 })
			}
		}
	}

	for mut p in state.particles {
		p.x += p.vx
		p.y += p.vy
		p.life += 0.05
		if p.x < 30 || p.x > f64(w - 70) { p.vx = -p.vx }
		if p.y < 30 || p.y > f64(h - 70) { p.vy = -p.vy }

		px := int(p.x)
		py := int(p.y)

		// 4-Pane Windows Logo or Rotating Quad
		fill_rect_c(renderer, px, py, 20, 20, Color{ r: 242, g: 80, b: 34 }) // Red
		fill_rect_c(renderer, px + 24, py, 20, 20, Color{ r: 127, g: 186, b: 0 }) // Green
		fill_rect_c(renderer, px, py + 24, 20, 20, Color{ r: 0, g: 164, b: 239 }) // Blue
		fill_rect_c(renderer, px + 24, py + 24, 20, 20, Color{ r: 255, g: 185, b: 0 }) // Yellow

		draw_rect_c(renderer, px - 2, py - 2, 48, 48, t.accent_color)
	}
}

// ----------------------------------------------------------------------
// 8. Flying Toasters Engine
// ----------------------------------------------------------------------
pub fn render_toasters(renderer &Renderer, t &ScreensaverTemplate, mut state ScreensaverState, w int, h int) {
	fill_rect_c(renderer, 0, 0, w, h, Color{ r: 8, g: 10, b: 22, a: 255 })

	if state.particles.len < t.density {
		for _ in state.particles.len .. t.density {
			state.particles << Particle{
				x: f64(rand.int_in_range(w, w + 300) or { 900 })
				y: f64(rand.int_in_range(20, h - 100) or { 200 })
				vx: -(2.5 + f64(rand.int_in_range(1, 3) or { 2 })) * t.speed
				vy: (1.5 + f64(rand.int_in_range(1, 3) or { 2 })) * t.speed
				life: f64(rand.int_in_range(0, 10) or { 0 })
			}
		}
	}

	for mut p in state.particles {
		p.x += p.vx
		p.y += p.vy
		p.life += 0.15
		if p.x < -80 || p.y > f64(h + 80) {
			p.x = f64(w + rand.int_in_range(20, 200) or { 100 })
			p.y = f64(rand.int_in_range(-40, h - 200) or { 50 })
		}

		tx := int(p.x)
		ty := int(p.y)
		wing_flap := int(math.sin(p.life) * 12.0)

		// Chrome Toaster Body
		fill_rect_c(renderer, tx, ty, 44, 30, t.primary_color)
		fill_rect_c(renderer, tx + 4, ty + 4, 36, 6, Color{ r: 60, g: 60, b: 70 }) // Toast slots
		draw_rect_c(renderer, tx, ty, 44, 30, Color{ r: 40, g: 40, b: 50 })

		// Golden Toast sticking out
		fill_rect_c(renderer, tx + 8, ty - 8, 28, 10, t.secondary_color)

		// Flapping Wings
		fill_rect_c(renderer, tx + 6, ty - 12 + wing_flap, 14, 8, t.accent_color)
		fill_rect_c(renderer, tx + 24, ty - 12 - wing_flap, 14, 8, t.accent_color)
	}
}

// ----------------------------------------------------------------------
// 9. BSOD Engine
// ----------------------------------------------------------------------
pub fn render_bsod(renderer &Renderer, t &ScreensaverTemplate, mut state ScreensaverState, w int, h int) {
	fill_rect_c(renderer, 0, 0, w, h, t.primary_color)

	match t.sub_mode {
		0 {
			// Windows 95 Fatal Exception
			fill_rect_c(renderer, w / 2 - 120, 180, 240, 26, t.secondary_color)
			draw_text_centered(renderer, w / 2, 185, ' Windows ', 2, t.primary_color)
			draw_text_centered(renderer, w / 2, 240, 'A fatal exception 0E has occurred at 0028:C0011E36 in VXD VMM(01) +', 1, t.secondary_color)
			draw_text_centered(renderer, w / 2, 260, '00010E36. The current application will be terminated.', 1, t.secondary_color)
			draw_text_centered(renderer, w / 2, 310, '*  Press any key to terminate the current application.', 1, t.secondary_color)
			draw_text_centered(renderer, w / 2, 330, '*  Press CTRL+ALT+DEL again to restart your computer.', 1, t.secondary_color)
			draw_text_centered(renderer, w / 2, 390, 'Press any key to continue _', 1, t.secondary_color)
		}
		1 {
			// Windows XP Kernel Trap
			draw_text(renderer, 50, 80, 'A problem has been detected and Windows has been shut down to prevent damage.', 1, t.secondary_color)
			draw_text(renderer, 50, 120, 'DRIVER_IRQL_NOT_LESS_OR_EQUAL', 2, t.secondary_color)
			draw_text(renderer, 50, 180, 'Technical information:', 1, t.secondary_color)
			draw_text(renderer, 50, 210, '*** STOP: 0x000000D1 (0x0000000C, 0x00000002, 0x00000000, 0xF86B5A89)', 1, t.secondary_color)
			draw_text(renderer, 50, 240, '*** gv3.sys - Address F86B5A89 base at F86B5000, DateStamp 3dd991eb', 1, t.secondary_color)
			draw_text(renderer, 50, 320, 'Beginning dump of physical memory...', 1, t.secondary_color)
			draw_text(renderer, 50, 340, 'Physical memory dump complete. Contact system admin.', 1, t.secondary_color)
		}
		2 {
			// Amiga Guru Meditation
			blink := (int(state.time_elapsed * 2) % 2) == 0
			border_c := if blink { t.secondary_color } else { Color{ r: 0, g: 0, b: 0 } }
			draw_rect_c(renderer, 40, 200, w - 80, 80, border_c)
			draw_rect_c(renderer, 42, 202, w - 84, 76, border_c)
			draw_text_centered(renderer, w / 2, 220, 'Software Failure.  Press left mouse button to continue.', 1, border_c)
			draw_text_centered(renderer, w / 2, 245, 'Guru Meditation #00000004.00004845', 1, border_c)
		}
		else {
			draw_text_centered(renderer, w / 2, h / 2, 'SYSTEM HALTED - FATAL TRAP', 2, t.secondary_color)
		}
	}
}

// ----------------------------------------------------------------------
// 10. Synthwave Outrun Grid Engine
// ----------------------------------------------------------------------
pub fn render_synthwave(renderer &Renderer, t &ScreensaverTemplate, mut state ScreensaverState, w int, h int) {
	fill_rect_c(renderer, 0, 0, w, h / 2, Color{ r: 20, g: 5, b: 35, a: 255 })
	fill_rect_c(renderer, 0, h / 2, w, h / 2, Color{ r: 10, g: 0, b: 20, a: 255 })

	// Neon Sun with Horizontal Blinds
	sun_x := w / 2
	sun_y := h / 2 - 40
	sun_r := 70
	for dy := -sun_r; dy <= sun_r; dy++ {
		line_w := int(math.sqrt(f64(sun_r * sun_r - dy * dy)))
		if (dy + 100) % 8 < 5 {
			sun_c := if dy < 0 { t.accent_color } else { t.primary_color }
			draw_line_c(renderer, sun_x - line_w, sun_y + dy, sun_x + line_w, sun_y + dy, sun_c)
		}
	}

	// Horizon Grid Lines
	horizon_y := h / 2
	fwd := math.fmod(state.time_elapsed * 60.0 * t.speed, 40.0)

	// Perspective horizontal scanlines
	for row := 0; row < 12; row++ {
		y_pos := horizon_y + int(math.pow(f64(row) + fwd / 40.0, 2.2) * 2.8)
		if y_pos < h {
			draw_line_c(renderer, 0, y_pos, w, y_pos, t.secondary_color)
		}
	}

	// Perspective vanishing lines
	for col := -8; col <= 8; col++ {
		bottom_x := w / 2 + col * 90
		draw_line_c(renderer, w / 2, horizon_y, bottom_x, h, t.secondary_color)
	}
}

// ----------------------------------------------------------------------
// 11. Doom Fire Engine
// ----------------------------------------------------------------------
pub fn render_doom_fire(renderer &Renderer, t &ScreensaverTemplate, mut state ScreensaverState, w int, h int) {
	cols := 80
	rows := 50
	cell_w := w / cols + 1
	cell_h := h / rows + 1

	if state.grid_state.len != rows {
		state.grid_state = [][]u8{len: rows, init: []u8{len: cols, init: 0}}
		// Bottom row is max heat (36)
		for x in 0 .. cols {
			state.grid_state[rows - 1][x] = 36
		}
	}

	// Update fire propagation
	for y := 0; y < rows - 1; y++ {
		for x in 0 .. cols {
			rand_idx := rand.int_in_range(0, 3) or { 0 }
			src_x := (x + rand_idx - 1 + cols) % cols
			src_heat := state.grid_state[y + 1][src_x]
			decay := u8(rand.int_in_range(0, 2) or { 1 })
			state.grid_state[y][x] = if src_heat >= decay { src_heat - decay } else { 0 }
		}
	}

	// Draw fire buffer
	for y in 0 .. rows {
		for x in 0 .. cols {
			heat := state.grid_state[y][x]
			if heat > 0 {
				norm := f64(heat) / 36.0
				c := Color{
					r: u8(math.min(255.0, norm * 2.0 * f64(t.primary_color.r)))
					g: u8(math.min(255.0, norm * f64(t.secondary_color.g)))
					b: u8(math.min(255.0, math.pow(norm, 3.0) * f64(t.accent_color.b)))
					a: 255
				}
				fill_rect_c(renderer, x * cell_w, y * cell_h, cell_w, cell_h, c)
			}
		}
	}
}

// ----------------------------------------------------------------------
// 12. Bouncing DVD Logo Engine
// ----------------------------------------------------------------------
pub fn render_dvd_logo(renderer &Renderer, t &ScreensaverTemplate, mut state ScreensaverState, w int, h int) {
	fill_rect_c(renderer, 0, 0, w, h, Color{ r: 0, g: 0, b: 0, a: 255 })

	box_w := 140
	box_h := 70

	state.dvd_x += state.dvd_vx * t.speed
	state.dvd_y += state.dvd_vy * t.speed

	mut hit_x := false
	mut hit_y := false

	if state.dvd_x <= 0 {
		state.dvd_x = 0
		state.dvd_vx = -state.dvd_vx
		hit_x = true
	} else if state.dvd_x >= f64(w - box_w) {
		state.dvd_x = f64(w - box_w)
		state.dvd_vx = -state.dvd_vx
		hit_x = true
	}

	if state.dvd_y <= 0 {
		state.dvd_y = 0
		state.dvd_vy = -state.dvd_vy
		hit_y = true
	} else if state.dvd_y >= f64(h - box_h) {
		state.dvd_y = f64(h - box_h)
		state.dvd_vy = -state.dvd_vy
		hit_y = true
	}

	if hit_x || hit_y {
		if hit_x && hit_y {
			state.dvd_corner_hits++ // EXACT CORNER HIT!
		}
		// Cycle RGB colors on hit
		colors := [
			Color{ r: 255, g: 50, b: 50 },
			Color{ r: 50, g: 255, b: 50 },
			Color{ r: 50, g: 150, b: 255 },
			Color{ r: 255, g: 220, b: 0 },
			Color{ r: 255, g: 0, b: 255 },
			Color{ r: 0, g: 255, b: 255 }
		]
		state.dvd_color = colors[rand.int_in_range(0, colors.len) or { 0 }]
	}

	dx := int(state.dvd_x)
	dy := int(state.dvd_y)

	// DVD Emblem Capsule
	fill_rect_c(renderer, dx, dy, box_w, box_h, state.dvd_color)
	fill_rect_c(renderer, dx + 6, dy + 6, box_w - 12, box_h - 12, Color{ r: 10, g: 10, b: 10 })
	draw_text_centered(renderer, dx + box_w / 2, dy + 18, 'DVD', 3, state.dvd_color)
	draw_text_centered(renderer, dx + box_w / 2, dy + 46, 'VIDEO', 1, state.dvd_color)

	// Corner hit counter in corner
	if state.dvd_corner_hits > 0 {
		draw_text(renderer, 20, 20, 'CORNER HITS: ${state.dvd_corner_hits}', 2, Color{ r: 255, g: 215, b: 0 })
	}
}

// ----------------------------------------------------------------------
// 13. Gargantua Black Hole Relativistic Lensing Engine
// ----------------------------------------------------------------------
pub fn render_black_hole(renderer &Renderer, t &ScreensaverTemplate, mut state ScreensaverState, w int, h int) {
	fill_rect_c(renderer, 0, 0, w, h, Color{ r: 2, g: 2, b: 6, a: 255 })
	cx := if state.mouse_down { f64(state.mouse_x) } else { f64(w) / 2.0 + math.sin(state.time_elapsed * 0.3) * 60.0 }
	cy := if state.mouse_down { f64(state.mouse_y) } else { f64(h) / 2.0 + math.cos(state.time_elapsed * 0.2) * 30.0 }
	rs := 55.0 // Schwarzschild radius

	// Accretion disk particles
	if state.particles.len < t.density {
		for _ in state.particles.len .. t.density {
			r := f64(rand.int_in_range(int(rs * 1.2), int(rs * 5.0)) or { 150 })
			theta := f64(rand.int_in_range(0, 628) or { 0 }) / 100.0
			state.particles << Particle{
				x: r * math.cos(theta)
				y: r * math.sin(theta)
				vz: r // stored orbital radius
				life: theta
				color: if rand.int_in_range(0, 2) or { 0 } == 0 { t.primary_color } else { t.secondary_color }
			}
		}
	}

	// Draw Background Starfield warped by gravitational lensing
	for i in 0 .. 120 {
		bx := f64((i * 97) % w)
		by := f64((i * 131) % h)
		dx := bx - cx
		dy := by - cy
		dist := math.sqrt(dx * dx + dy * dy)
		if dist > rs {
			// Einstein deflection angle ~ 4GM / (c^2 r)
			deflect := (rs * rs * 1.8) / dist
			lx := bx + (dx / dist) * deflect
			ly := by + (dy / dist) * deflect
			fill_rect_c(renderer, int(lx), int(ly), 2, 2, Color{ r: 180, g: 200, b: 240, a: 255 })
		}
	}

	// Update & render orbiting accretion disk with relativistic Doppler beaming
	disk_tilt := 0.35
	for mut p in state.particles {
		omega := 2.2 / math.sqrt(p.vz / rs) * t.speed // Keplerian speed
		p.life += omega * 0.02
		r := p.vz

		// 3D tilted disk projection
		px := cx + r * math.cos(p.life)
		py := cy + r * math.sin(p.life) * disk_tilt

		// Doppler beaming factor: matter moving toward observer (x < 0) is blue-shifted & brighter
		doppler := 1.0 - math.sin(p.life) * 0.45
		mut c := Color{
			r: u8(math.min(255.0, f64(p.color.r) * doppler))
			g: u8(math.min(255.0, f64(p.color.g) * doppler))
			b: u8(math.min(255.0, f64(p.color.b) * doppler))
			a: 255
		}
		if doppler > 1.2 {
			c = t.accent_color // Relativistic blueshift hotspot
		}

		// Gravitational lensed secondary arc above and below black hole
		if py > cy - rs && py < cy + rs && px > cx - rs * 1.5 && px < cx + rs * 1.5 {
			lensed_y1 := cy - rs * 1.15 - (r - rs) * 0.2
			lensed_y2 := cy + rs * 1.15 + (r - rs) * 0.2
			fill_rect_c(renderer, int(px), int(lensed_y1), 3, 2, c)
			fill_rect_c(renderer, int(px), int(lensed_y2), 3, 2, c)
		}

		fill_rect_c(renderer, int(px), int(py), 3, 3, c)
	}

	// Luminous Photon Sphere Ring (1.5 Rs)
	photon_r := int(rs * 1.4)
	for a := 0; a < 64; a++ {
		ang := f64(a) * (math.pi * 2.0 / 64.0)
		rx := int(cx + f64(photon_r) * math.cos(ang))
		ry := int(cy + f64(photon_r) * math.sin(ang))
		fill_rect_c(renderer, rx, ry, 2, 2, t.accent_color)
	}

	// Black Hole Shadow / Event Horizon (pure black void)
	for dy := -int(rs); dy <= int(rs); dy++ {
		span := int(math.sqrt(math.max(0.0, rs * rs - f64(dy * dy))))
		fill_rect_c(renderer, int(cx) - span, int(cy) + dy, span * 2, 1, Color{ r: 0, g: 0, b: 0, a: 255 })
	}

	// Relativistic Polar Plasma Jets
	for jet_dir in [-1.0, 1.0] {
		for j := 0; j < 30; j++ {
			jy := cy + jet_dir * (rs + f64(j * 8))
			jx := cx + math.sin(state.time_elapsed * 10.0 + f64(j)) * 6.0
			jw := int(math.max(2.0, 16.0 - f64(j) * 0.4))
			fill_rect_c(renderer, int(jx) - jw / 2, int(jy), jw, 4, t.accent_color)
		}
	}
}

// ----------------------------------------------------------------------
// 14. SPH Fluid Hydrodynamics Engine
// ----------------------------------------------------------------------
pub fn render_fluid_sph(renderer &Renderer, t &ScreensaverTemplate, mut state ScreensaverState, w int, h int) {
	fill_rect_c(renderer, 0, 0, w, h, Color{ r: 8, g: 14, b: 24, a: 255 })

	if state.particles.len < t.density {
		for _ in state.particles.len .. t.density {
			state.particles << Particle{
				x: f64(rand.int_in_range(w / 4, 3 * w / 4) or { 400 })
				y: f64(rand.int_in_range(40, h / 3) or { 150 })
				vx: f64(rand.int_in_range(-2, 3) or { 0 })
				vy: f64(rand.int_in_range(0, 3) or { 1 })
				size: 10
				color: t.primary_color
			}
		}
	}

	gravity := 0.28 * t.speed
	damping := 0.75

	// Mouse interaction: spray fluid or stir
	if state.mouse_down {
		for _ in 0 .. 3 {
			if state.particles.len < 600 {
				state.particles << Particle{
					x: f64(state.mouse_x)
					y: f64(state.mouse_y)
					vx: f64(rand.int_in_range(-8, 9) or { 0 })
					vy: f64(rand.int_in_range(-12, -4) or { -8 })
					size: 10
					color: t.accent_color
				}
			}
		}
	}

	// Physics step
	for i := 0; i < state.particles.len; i++ {
		mut p1 := &state.particles[i]
		p1.vy += gravity
		p1.x += p1.vx * t.speed
		p1.y += p1.vy * t.speed

		// Wall & floor boundary collisions with restitution
		if p1.x < 30 { p1.x = 30; p1.vx = -p1.vx * damping }
		if p1.x > f64(w - 30) { p1.x = f64(w - 30); p1.vx = -p1.vx * damping }
		if p1.y > f64(h - 40) { p1.y = f64(h - 40); p1.vy = -p1.vy * damping; p1.vx *= 0.96 }

		// SPH inter-particle pressure repulsion (local neighborhood)
		for j := i + 1; j < math.min(state.particles.len, i + 12); j++ {
			mut p2 := &state.particles[j]
			dx := p2.x - p1.x
			dy := p2.y - p1.y
			dist_sq := dx * dx + dy * dy
			h_rad := 18.0
			if dist_sq < h_rad * h_rad && dist_sq > 0.1 {
				dist := math.sqrt(dist_sq)
				overlap := (h_rad - dist) / h_rad
				repel := overlap * 0.6
				nx := dx / dist
				ny := dy / dist
				p1.vx -= nx * repel
				p1.vy -= ny * repel
				p2.vx += nx * repel
				p2.vy += ny * repel
			}
		}

		// Draw liquid drop
		fill_rect_c(renderer, int(p1.x) - 4, int(p1.y) - 4, 8, 8, p1.color)
		fill_rect_c(renderer, int(p1.x) - 1, int(p1.y) - 1, 3, 3, t.accent_color)
	}

	// Pool floor reflection
	fill_rect_c(renderer, 0, h - 35, w, 35, Color{ r: 4, g: 8, b: 16, a: 255 })
	draw_line_c(renderer, 0, h - 36, w, h - 36, t.secondary_color)
}

// ----------------------------------------------------------------------
// 15. Elastic Soft-Body Jelly Lattice Engine
// ----------------------------------------------------------------------
pub fn render_softbody_jelly(renderer &Renderer, t &ScreensaverTemplate, mut state ScreensaverState, w int, h int) {
	fill_rect_c(renderer, 0, 0, w, h, Color{ r: 12, g: 15, b: 20, a: 255 })

	grid_dim := 5
	spacing := 28.0

	// Initialize spring lattice
	if state.spring_pts.len == 0 {
		start_x := f64(w) / 2.0 - f64(grid_dim * 14)
		start_y := 120.0
		for gy in 0 .. grid_dim {
			for gx in 0 .. grid_dim {
				px := start_x + f64(gx) * spacing
				py := start_y + f64(gy) * spacing
				state.spring_pts << SpringPoint{ x: px, y: py, prev_x: px, prev_y: py, fixed: false }
			}
		}
		// Create spring links (structural + diagonal shear)
		for gy in 0 .. grid_dim {
			for gx in 0 .. grid_dim {
				idx := gy * grid_dim + gx
				if gx + 1 < grid_dim {
					state.spring_links << SpringLink{ p1: idx, p2: idx + 1, length: spacing }
				}
				if gy + 1 < grid_dim {
					state.spring_links << SpringLink{ p1: idx, p2: idx + grid_dim, length: spacing }
				}
				if gx + 1 < grid_dim && gy + 1 < grid_dim {
					state.spring_links << SpringLink{ p1: idx, p2: idx + grid_dim + 1, length: spacing * 1.414 }
					state.spring_links << SpringLink{ p1: idx + 1, p2: idx + grid_dim, length: spacing * 1.414 }
				}
			}
		}
	}

	gravity := 0.35 * t.speed
	floor_y := f64(h - 60)

	// Verlet integration
	for mut p in state.spring_pts {
		vx := (p.x - p.prev_x) * 0.99
		vy := (p.y - p.prev_y) * 0.99 + gravity
		p.prev_x = p.x
		p.prev_y = p.y
		p.x += vx
		p.y += vy

		// Mouse grab / pull
		if state.mouse_down {
			mdx := f64(state.mouse_x) - p.x
			mdy := f64(state.mouse_y) - p.y
			mdist := math.sqrt(mdx * mdx + mdy * mdy)
			if mdist < 120.0 && mdist > 1.0 {
				p.x += (mdx / mdist) * 4.0
				p.y += (mdy / mdist) * 4.0
			}
		}

		// Floor & wall bounce
		if p.y > floor_y {
			p.y = floor_y
			p.prev_y = p.y + vy * 0.65
		}
		if p.x < 50.0 { p.x = 50.0; p.prev_x = p.x + vx * 0.65 }
		if p.x > f64(w - 50) { p.x = f64(w - 50); p.prev_x = p.x + vx * 0.65 }
	}

	// Spring constraint relaxation iterations
	for _ in 0 .. 5 {
		for link in state.spring_links {
			p1 := state.spring_pts[link.p1]
			p2 := state.spring_pts[link.p2]
			dx := p2.x - p1.x
			dy := p2.y - p1.y
			dist := math.sqrt(dx * dx + dy * dy)
			if dist > 0.001 {
				diff := (dist - link.length) / dist * 0.5
				state.spring_pts[link.p1].x += dx * diff
				state.spring_pts[link.p1].y += dy * diff
				state.spring_pts[link.p2].x -= dx * diff
				state.spring_pts[link.p2].y -= dy * diff
			}
		}
	}

	// Draw Spring Struts
	for link in state.spring_links {
		p1 := state.spring_pts[link.p1]
		p2 := state.spring_pts[link.p2]
		draw_line_c(renderer, int(p1.x), int(p1.y), int(p2.x), int(p2.y), t.primary_color)
	}

	// Draw Jelly Nodes
	for p in state.spring_pts {
		fill_rect_c(renderer, int(p.x) - 4, int(p.y) - 4, 8, 8, t.accent_color)
	}

	// Obstacle peg in the middle
	fill_rect_c(renderer, w / 2 - 20, h / 2 + 50, 40, 20, t.secondary_color)
	draw_rect_c(renderer, w / 2 - 20, h / 2 + 50, 40, 20, Color{ r: 255, g: 255, b: 255 })

	// Ground
	fill_rect_c(renderer, 0, int(floor_y), w, 60, Color{ r: 20, g: 24, b: 32 })
	draw_line_c(renderer, 0, int(floor_y), w, int(floor_y), t.secondary_color)
}

// ----------------------------------------------------------------------
// 16. N-Body Galactic Collision Engine
// ----------------------------------------------------------------------
pub fn render_galaxy_nbody(renderer &Renderer, t &ScreensaverTemplate, mut state ScreensaverState, w int, h int) {
	fill_rect_c(renderer, 0, 0, w, h, Color{ r: 2, g: 2, b: 8, a: 255 })

	if state.particles.len < t.density {
		state.particles.clear()
		// Galaxy 1 (Milky Way)
		for _ in 0 .. t.density / 2 {
			r := f64(rand.int_in_range(10, 180) or { 50 })
			ang := f64(rand.int_in_range(0, 628) or { 0 }) / 100.0 + r * 0.04
			state.particles << Particle{
				x: f64(w) * 0.35 + r * math.cos(ang)
				y: f64(h) * 0.5 + r * math.sin(ang) * 0.6
				vx: -math.sin(ang) * (3.0 / math.sqrt(r * 0.05 + 1.0))
				vy: math.cos(ang) * (3.0 / math.sqrt(r * 0.05 + 1.0)) * 0.6 + 0.3
				color: t.primary_color
			}
		}
		// Galaxy 2 (Andromeda)
		for _ in 0 .. t.density / 2 {
			r := f64(rand.int_in_range(10, 180) or { 50 })
			ang := f64(rand.int_in_range(0, 628) or { 0 }) / 100.0 - r * 0.04
			state.particles << Particle{
				x: f64(w) * 0.65 + r * math.cos(ang)
				y: f64(h) * 0.5 + r * math.sin(ang) * 0.6
				vx: math.sin(ang) * (3.0 / math.sqrt(r * 0.05 + 1.0))
				vy: -math.cos(ang) * (3.0 / math.sqrt(r * 0.05 + 1.0)) * 0.6 - 0.3
				color: t.secondary_color
			}
		}
	}

	// Supermassive Core positions
	core1_x := f64(w) * 0.35 + math.sin(state.time_elapsed * 0.5) * 120.0
	core1_y := f64(h) * 0.5 + math.cos(state.time_elapsed * 0.4) * 80.0
	core2_x := f64(w) * 0.65 - math.sin(state.time_elapsed * 0.5) * 120.0
	core2_y := f64(h) * 0.5 - math.cos(state.time_elapsed * 0.4) * 80.0

	soften := 40.0
	g_const := 80.0 * t.speed

	for mut p in state.particles {
		// Attraction toward Core 1
		d1x := core1_x - p.x
		d1y := core1_y - p.y
		r1 := math.sqrt(d1x * d1x + d1y * d1y + soften * soften)
		f1 := g_const / (r1 * r1)
		p.vx += (d1x / r1) * f1
		p.vy += (d1y / r1) * f1

		// Attraction toward Core 2
		d2x := core2_x - p.x
		d2y := core2_y - p.y
		r2 := math.sqrt(d2x * d2x + d2y * d2y + soften * soften)
		f2 := g_const / (r2 * r2)
		p.vx += (d2x / r2) * f2
		p.vy += (d2y / r2) * f2

		p.x += p.vx * t.speed
		p.y += p.vy * t.speed

		fill_rect_c(renderer, int(p.x), int(p.y), 2, 2, p.color)
	}

	// Draw Galactic Nuclei
	fill_rect_c(renderer, int(core1_x) - 6, int(core1_y) - 6, 12, 12, t.accent_color)
	fill_rect_c(renderer, int(core2_x) - 6, int(core2_y) - 6, 12, 12, t.accent_color)
}

// ----------------------------------------------------------------------
// 17. Double Pendulum Chaos Engine
// ----------------------------------------------------------------------
pub fn render_double_pendulum(renderer &Renderer, t &ScreensaverTemplate, mut state ScreensaverState, w int, h int) {
	fill_rect_c(renderer, 0, 0, w, h, Color{ r: 5, g: 5, b: 10, a: 255 })
	pivot_x := f64(w) / 2.0
	pivot_y := f64(h) / 3.0
	l1 := 140.0
	l2 := 120.0

	// Initialize angles and angular velocities
	if state.custom_f1 == 0.0 {
		state.custom_f1 = math.pi / 2.0 // theta 1
		state.custom_f2 = math.pi / 2.0 // theta 2
		state.custom_f3 = 0.0           // omega 1
		state.custom_f4 = 0.0           // omega 2
	}

	// Physics equations of motion for double pendulum
	g := 9.81 * 0.06 * t.speed
	dt := 0.15 * t.speed

	th1 := state.custom_f1
	th2 := state.custom_f2
	w1 := state.custom_f3
	w2 := state.custom_f4

	delta := th1 - th2
	den1 := 2.0 - math.cos(2.0 * th1 - 2.0 * th2)

	num1 := -g * 3.0 * math.sin(th1) - g * math.sin(th1 - 2.0 * th2) - 2.0 * math.sin(delta) * (w2 * w2 * l2 + w1 * w1 * l1 * math.cos(delta))
	alpha1 := num1 / (l1 * den1)

	num2 := 2.0 * math.sin(delta) * (w1 * w1 * l1 * 2.0 + g * 2.0 * math.cos(th1) + w2 * w2 * l2 * math.cos(delta))
	alpha2 := num2 / (l2 * den1)

	state.custom_f3 += alpha1 * dt
	state.custom_f4 += alpha2 * dt
	state.custom_f3 *= 0.9995 // Damping
	state.custom_f4 *= 0.9995
	state.custom_f1 += state.custom_f3 * dt
	state.custom_f2 += state.custom_f4 * dt

	// Compute joint positions
	x1 := pivot_x + l1 * math.sin(state.custom_f1)
	y1 := pivot_y + l1 * math.cos(state.custom_f1)
	x2 := x1 + l2 * math.sin(state.custom_f2)
	y2 := y1 + l2 * math.cos(state.custom_f2)

	// Add to phase-space trail
	state.trails << TrailPoint{
		p1: PolyVertex{ x: x1, y: y1 },
		p2: PolyVertex{ x: x2, y: y2 },
		c: t.accent_color
	}
	if state.trails.len > 120 {
		state.trails.delete(0)
	}

	// Draw Trails
	for idx := 1; idx < state.trails.len; idx++ {
		prev := state.trails[idx - 1]
		curr := state.trails[idx]
		fade := f64(idx) / f64(state.trails.len)
		c := Color{
			r: u8(f64(t.primary_color.r) * fade)
			g: u8(f64(t.primary_color.g) * fade)
			b: u8(f64(t.primary_color.b) * fade)
			a: 255
		}
		draw_line_c(renderer, int(prev.p2.x), int(prev.p2.y), int(curr.p2.x), int(curr.p2.y), c)
	}

	// Draw Rods & Bobs
	draw_line_c(renderer, int(pivot_x), int(pivot_y), int(x1), int(y1), t.secondary_color)
	draw_line_c(renderer, int(x1), int(y1), int(x2), int(y2), t.secondary_color)
	fill_rect_c(renderer, int(pivot_x) - 4, int(pivot_y) - 4, 8, 8, Color{ r: 255, g: 255, b: 255 })
	fill_rect_c(renderer, int(x1) - 8, int(y1) - 8, 16, 16, t.primary_color)
	fill_rect_c(renderer, int(x2) - 10, int(y2) - 10, 20, 20, t.accent_color)
}

// ----------------------------------------------------------------------
// 18. Optics Refraction & Dispersion Prism Engine
// ----------------------------------------------------------------------
pub fn render_optics_prism(renderer &Renderer, t &ScreensaverTemplate, mut state ScreensaverState, w int, h int) {
	fill_rect_c(renderer, 0, 0, w, h, Color{ r: 6, g: 8, b: 12, a: 255 })

	cx := f64(w) / 2.0
	cy := f64(h) / 2.0
	prism_rot := state.time_elapsed * 0.4 * t.speed
	prism_size := 90.0

	// 3 vertices of equilateral prism
	mut pv := []PolyVertex{cap: 3}
	for i in 0 .. 3 {
		ang := prism_rot + f64(i) * (2.0 * math.pi / 3.0)
		pv << PolyVertex{ x: cx + prism_size * math.cos(ang), y: cy + prism_size * math.sin(ang) }
	}

	// Incident Collimated White Light Beam
	beam_y := cy - 20.0
	draw_line_c(renderer, 0, int(beam_y) - 1, int(cx - 50), int(beam_y) - 1, Color{ r: 255, g: 255, b: 255 })
	draw_line_c(renderer, 0, int(beam_y), int(cx - 50), int(beam_y), Color{ r: 255, g: 255, b: 255 })
	draw_line_c(renderer, 0, int(beam_y) + 1, int(cx - 50), int(beam_y) + 1, Color{ r: 255, g: 255, b: 255 })

	// Refracted Rainbow Spectrum Rays leaving the prism
	spectrum := [
		Color{ r: 255, g: 0, b: 0 },     // Red (least bent)
		Color{ r: 255, g: 127, b: 0 },   // Orange
		Color{ r: 255, g: 255, b: 0 },   // Yellow
		Color{ r: 0, g: 255, b: 0 },     // Green
		Color{ r: 0, g: 180, b: 255 },   // Cyan
		Color{ r: 0, g: 0, b: 255 },     // Blue
		Color{ r: 180, g: 0, b: 255 }    // Violet (most bent)
	]

	for idx, col in spectrum {
		bend_angle := 0.25 + f64(idx) * 0.08 + math.sin(prism_rot) * 0.15
		end_x := cx + math.cos(bend_angle) * f64(w)
		end_y := cy + math.sin(bend_angle) * f64(h)
		draw_line_c(renderer, int(cx + 30), int(cy), int(end_x), int(end_y), col)
	}

	// Draw Glass Prism Polygon
	draw_line_c(renderer, int(pv[0].x), int(pv[0].y), int(pv[1].x), int(pv[1].y), Color{ r: 180, g: 220, b: 255 })
	draw_line_c(renderer, int(pv[1].x), int(pv[1].y), int(pv[2].x), int(pv[2].y), Color{ r: 180, g: 220, b: 255 })
	draw_line_c(renderer, int(pv[2].x), int(pv[2].y), int(pv[0].x), int(pv[0].y), Color{ r: 180, g: 220, b: 255 })
}

// ----------------------------------------------------------------------
// Master Dispatcher for All 44 Engines
// ----------------------------------------------------------------------
pub fn render_screensaver_engine(renderer &Renderer, t &ScreensaverTemplate, mut state ScreensaverState, w int, h int) {
	match t.engine {
		.engine_matrix { render_matrix(renderer, t, mut state, w, h) }
		.engine_pipes { render_pipes(renderer, t, mut state, w, h) }
		.engine_starfield { render_starfield(renderer, t, mut state, w, h) }
		.engine_mystify { render_mystify(renderer, t, mut state, w, h) }
		.engine_maze { render_maze(renderer, t, mut state, w, h) }
		.engine_3d_text { render_3d_text(renderer, t, mut state, w, h) }
		.engine_flying_objects { render_flying_objects(renderer, t, mut state, w, h) }
		.engine_toasters { render_toasters(renderer, t, mut state, w, h) }
		.engine_bsod { render_bsod(renderer, t, mut state, w, h) }
		.engine_synthwave { render_synthwave(renderer, t, mut state, w, h) }
		.engine_doom_fire { render_doom_fire(renderer, t, mut state, w, h) }
		.engine_dvd_logo { render_dvd_logo(renderer, t, mut state, w, h) }
		.engine_black_hole { render_black_hole(renderer, t, mut state, w, h) }
		.engine_fluid_sph { render_fluid_sph(renderer, t, mut state, w, h) }
		.engine_softbody_jelly { render_softbody_jelly(renderer, t, mut state, w, h) }
		.engine_galaxy_nbody { render_galaxy_nbody(renderer, t, mut state, w, h) }
		.engine_double_pendulum { render_double_pendulum(renderer, t, mut state, w, h) }
		.engine_optics_prism { render_optics_prism(renderer, t, mut state, w, h) }
		.engine_ferrofluid { render_black_hole(renderer, t, mut state, w, h) }
		.engine_granules_sand { render_fluid_sph(renderer, t, mut state, w, h) }
		.engine_marble_run { render_softbody_jelly(renderer, t, mut state, w, h) }
		.engine_wave_interference { render_optics_prism(renderer, t, mut state, w, h) }
		else {
			render_starfield(renderer, t, mut state, w, h)
			draw_text_centered(renderer, w / 2, h / 2 - 20, t.name, 3, t.accent_color)
			draw_text_centered(renderer, w / 2, h / 2 + 20, t.description, 1, t.primary_color)
		}
	}
}

