module main

import math
import rand

pub enum ToolMode {
	freehand
	spirograph
	stencil
	symmetry
}

pub enum ColorTheme {
	classic_silver
	amber_phosphor
	emerald_matrix
	cyber_neon
	rainbow_gradient
	chalkboard
}

pub enum SymmetryMode {
	mirror_h
	mirror_v
	quad
	kaleidoscope
}

pub struct Point {
pub mut:
	x     f64
	y     f64
	col   Color = Color{40, 40, 42, 255}
	start bool
}

pub struct PowderParticle {
pub mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	life  f64
	max_l f64
	size  int
	alpha u8
}

pub struct Stencil {
pub:
	name   string
	desc   string
	points []Point // Normalized 0.0 - 1.0 coordinates
}

pub struct SpiroParams {
pub mut:
	r_outer f64 = 140.0
	r_inner f64 = 84.0
	d_pen   f64 = 65.0
	theta   f64
	speed   f64 = 0.04
	running bool
	preset  int
}

pub struct EtchGame {
pub mut:
	// Screen boundaries in window coordinates
	screen_x int = 110
	screen_y int = 70
	screen_w int = 700
	screen_h int = 440

	// Cursor & Knobs
	pen_x        f64 = 350.0
	pen_y        f64 = 220.0
	knob_l_angle f64 // Left knob controls X (Horizontal)
	knob_r_angle f64 // Right knob controls Y (Vertical)
	speed        f64 = 3.2

	// Drawing data
	points     []Point
	is_drawing bool = true

	// Mode & Style
	tool_mode   ToolMode     = .freehand
	theme       ColorTheme   = .classic_silver
	sym_mode    SymmetryMode = .mirror_h
	rainbow_hue f64

	// Shake Erase
	is_shaking     bool
	shake_time     f64
	shake_offset_x f64
	shake_offset_y f64
	particles      []PowderParticle

	// Spirograph
	spiro SpiroParams

	// Stencils
	stencils        []Stencil
	current_stencil int
	stencil_score   f64
	stencil_stars   int
	stencil_cleared bool

	// Replay / Time-lapse
	is_replaying    bool
	replay_idx      int
	replay_speed    int = 4
	recorded_points []Point

	// Stats
	total_distance f64
	stroke_count   int
	toast_msg      string
	toast_timer    f64
}

pub fn new_etch_game() EtchGame {
	mut g := EtchGame{
		pen_x: 350.0
		pen_y: 220.0
	}
	g.init_stencils()
	g.reset_screen()
	return g
}

pub fn (mut g EtchGame) reset_screen() {
	g.points.clear()
	g.recorded_points.clear()
	g.pen_x = f64(g.screen_w) / 2.0
	g.pen_y = f64(g.screen_h) / 2.0
	g.points << Point{
		x: g.pen_x
		y: g.pen_y
		col: g.get_current_color()
		start: true
	}
	g.recorded_points << g.points.last()
	g.total_distance = 0
	g.stroke_count = 1
	g.is_replaying = false
	g.replay_idx = 0
	g.spiro.theta = 0
	g.spiro.running = false
	g.stencil_score = 0
	g.stencil_stars = 0
	g.stencil_cleared = false
}

pub fn (mut g EtchGame) get_current_color() Color {
	match g.theme {
		.classic_silver {
			return Color{45, 45, 48, 255}
		}
		.amber_phosphor {
			return Color{255, 176, 0, 255}
		}
		.emerald_matrix {
			return Color{57, 255, 20, 255}
		}
		.cyber_neon {
			return Color{0, 245, 255, 255}
		}
		.rainbow_gradient {
			h := g.rainbow_hue
			r, gr, b := hsv_to_rgb(h, 0.9, 1.0)
			return Color{r, gr, b, 255}
		}
		.chalkboard {
			return Color{240, 240, 245, 255}
		}
	}
}

pub fn (mut g EtchGame) get_screen_bg_color() Color {
	match g.theme {
		.classic_silver {
			return Color{205, 208, 212, 255}
		}
		.amber_phosphor {
			return Color{28, 20, 5, 255}
		}
		.emerald_matrix {
			return Color{8, 24, 12, 255}
		}
		.cyber_neon {
			return Color{15, 12, 35, 255}
		}
		.rainbow_gradient {
			return Color{20, 20, 25, 255}
		}
		.chalkboard {
			return Color{36, 48, 40, 255}
		}
	}
}

pub fn (mut g EtchGame) move_pen(dx f64, dy f64) bool {
	if g.is_shaking || g.is_replaying {
		return false
	}
	new_x := math.clamp(g.pen_x + dx, 4.0, f64(g.screen_w - 4))
	new_y := math.clamp(g.pen_y + dy, 4.0, f64(g.screen_h - 4))

	moved := (new_x != g.pen_x) || (new_y != g.pen_y)
	if !moved {
		return false
	}

	dist := math.sqrt(dx * dx + dy * dy)
	g.total_distance += dist
	g.rainbow_hue = math.fmod(g.rainbow_hue + dist * 0.005, 1.0)

	g.knob_l_angle += dx * 0.08
	g.knob_r_angle += dy * 0.08

	g.pen_x = new_x
	g.pen_y = new_y

	col := g.get_current_color()

	if g.tool_mode == .symmetry {
		g.add_symmetry_points(new_x, new_y, col)
	} else {
		pt := Point{
			x: new_x
			y: new_y
			col: col
			start: false
		}
		g.points << pt
		g.recorded_points << pt
	}

	if g.tool_mode == .stencil {
		g.evaluate_stencil_progress()
	}

	return true
}

fn (mut g EtchGame) add_symmetry_points(x f64, y f64, col Color) {
	cx := f64(g.screen_w) / 2.0
	cy := f64(g.screen_h) / 2.0
	dx := x - cx
	dy := y - cy

	match g.sym_mode {
		.mirror_h {
			g.points << Point{x: cx + dx, y: cy + dy, col: col}
			g.points << Point{x: cx - dx, y: cy + dy, col: col, start: true}
		}
		.mirror_v {
			g.points << Point{x: cx + dx, y: cy + dy, col: col}
			g.points << Point{x: cx + dx, y: cy - dy, col: col, start: true}
		}
		.quad {
			g.points << Point{x: cx + dx, y: cy + dy, col: col}
			g.points << Point{x: cx - dx, y: cy + dy, col: col, start: true}
			g.points << Point{x: cx + dx, y: cy - dy, col: col, start: true}
			g.points << Point{x: cx - dx, y: cy - dy, col: col, start: true}
		}
		.kaleidoscope {
			angles := [0.0, math.pi * 0.5, math.pi, math.pi * 1.5]
			for a in angles {
				rx := dx * math.cos(a) - dy * math.sin(a)
				ry := dx * math.sin(a) + dy * math.cos(a)
				g.points << Point{x: cx + rx, y: cy + ry, col: col, start: a > 0}
				g.points << Point{x: cx - rx, y: cy + ry, col: col, start: true}
			}
		}
	}
	g.recorded_points << Point{x: x, y: y, col: col}
}

pub fn (mut g EtchGame) trigger_shake() {
	if g.is_shaking {
		return
	}
	g.is_shaking = true
	g.shake_time = 0.0
	g.particles.clear()

	particle_count := 350
	for _ in 0 .. particle_count {
		g.particles << PowderParticle{
			x: rand.f64() * f64(g.screen_w)
			y: rand.f64() * f64(g.screen_h)
			vx: (rand.f64() * 2.0 - 1.0) * 180.0
			vy: (rand.f64() * 2.0 - 1.0) * 180.0
			life: 0.0
			max_l: 0.6 + rand.f64() * 0.4
			size: 2 + rand.int_in_range(0, 3) or { 1 }
			alpha: u8(180 + rand.int_in_range(0, 75) or { 50 })
		}
	}
}

pub fn (mut g EtchGame) update(dt f64) {
	// 1. Shake erase physics
	if g.is_shaking {
		g.shake_time += dt
		intensity := math.sin(g.shake_time * 25.0) * math.max(0.0, 1.0 - g.shake_time / 0.8)
		g.shake_offset_x = intensity * 12.0
		g.shake_offset_y = math.cos(g.shake_time * 22.0) * intensity * 8.0

		for mut p in g.particles {
			p.life += dt
			p.x += p.vx * dt
			p.y += p.vy * dt
			p.vx *= 0.94
			p.vy += 80.0 * dt
			fade := math.max(0.0, 1.0 - p.life / p.max_l)
			p.alpha = u8(f64(220) * fade)
		}

		if g.shake_time >= 0.8 {
			g.is_shaking = false
			g.shake_offset_x = 0
			g.shake_offset_y = 0
			g.reset_screen()
		}
		return
	}

	// 2. Spirograph Auto-turner
	if g.tool_mode == .spirograph && g.spiro.running {
		steps := 4
		for _ in 0 .. steps {
			g.spiro.theta += g.spiro.speed / f64(steps)
			cx := f64(g.screen_w) / 2.0
			cy := f64(g.screen_h) / 2.0
			r_out_val := g.spiro.r_outer
			r_in_val := g.spiro.r_inner
			d_val := g.spiro.d_pen
			t := g.spiro.theta

			// Epitrochoid / Hypotrochoid math
			mut nx := 0.0
			mut ny := 0.0
			if g.spiro.preset % 2 == 0 {
				// Hypotrochoid
				nx = cx + (r_out_val - r_in_val) * math.cos(t) + d_val * math.cos((r_out_val - r_in_val) * t / r_in_val)
				ny = cy - (r_out_val - r_in_val) * math.sin(t) + d_val * math.sin((r_out_val - r_in_val) * t / r_in_val)
			} else {
				// Epitrochoid
				nx = cx + (r_out_val + r_in_val) * math.cos(t) - d_val * math.cos((r_out_val + r_in_val) * t / r_in_val)
				ny = cy + (r_out_val + r_in_val) * math.sin(t) - d_val * math.sin((r_out_val + r_in_val) * t / r_in_val)
			}

			nx = math.clamp(nx, 8.0, f64(g.screen_w - 8))
			ny = math.clamp(ny, 8.0, f64(g.screen_h - 8))

			dx := nx - g.pen_x
			dy := ny - g.pen_y
			g.knob_l_angle += dx * 0.08
			g.knob_r_angle += dy * 0.08
			g.pen_x = nx
			g.pen_y = ny
			g.rainbow_hue = math.fmod(g.rainbow_hue + 0.003, 1.0)

			pt := Point{
				x: nx
				y: ny
				col: g.get_current_color()
				start: false
			}
			g.points << pt
			g.recorded_points << pt
		}
	}

	// 3. Time-lapse Replay
	if g.is_replaying {
		advance := g.replay_speed
		for _ in 0 .. advance {
			if g.replay_idx < g.recorded_points.len {
				pt := g.recorded_points[g.replay_idx]
				g.points << pt
				g.pen_x = pt.x
				g.pen_y = pt.y
				g.replay_idx++
			} else {
				g.is_replaying = false
				break
			}
		}
	}
}

pub fn (mut g EtchGame) start_replay() {
	if g.recorded_points.len == 0 {
		return
	}
	g.points.clear()
	g.is_replaying = true
	g.replay_idx = 0
}

pub fn (mut g EtchGame) next_spiro_preset() {
	g.spiro.preset = (g.spiro.preset + 1) % 6
	match g.spiro.preset {
		0 {
			g.spiro.r_outer = 150.0
			g.spiro.r_inner = 90.0
			g.spiro.d_pen = 70.0
		}
		1 {
			g.spiro.r_outer = 130.0
			g.spiro.r_inner = 52.0
			g.spiro.d_pen = 80.0
		}
		2 {
			g.spiro.r_outer = 160.0
			g.spiro.r_inner = 100.0
			g.spiro.d_pen = 45.0
		}
		3 {
			g.spiro.r_outer = 140.0
			g.spiro.r_inner = 40.0
			g.spiro.d_pen = 90.0
		}
		4 {
			g.spiro.r_outer = 155.0
			g.spiro.r_inner = 115.0
			g.spiro.d_pen = 85.0
		}
		5 {
			g.spiro.r_outer = 120.0
			g.spiro.r_inner = 72.0
			g.spiro.d_pen = 50.0
		}
		else {}
	}
	g.spiro.theta = 0
}

fn (mut g EtchGame) init_stencils() {
	g.stencils.clear()

	// 1. Classic House
	mut house := []Point{}
	house << Point{x: 0.25, y: 0.75, start: true}
	house << Point{x: 0.75, y: 0.75}
	house << Point{x: 0.75, y: 0.45}
	house << Point{x: 0.50, y: 0.20}
	house << Point{x: 0.25, y: 0.45}
	house << Point{x: 0.25, y: 0.75}
	// Door
	house << Point{x: 0.44, y: 0.75, start: true}
	house << Point{x: 0.44, y: 0.55}
	house << Point{x: 0.56, y: 0.55}
	house << Point{x: 0.56, y: 0.75}
	// Window
	house << Point{x: 0.30, y: 0.50, start: true}
	house << Point{x: 0.40, y: 0.50}
	house << Point{x: 0.40, y: 0.60}
	house << Point{x: 0.30, y: 0.60}
	house << Point{x: 0.30, y: 0.50}
	g.stencils << Stencil{
		name: 'Classic House'
		desc: 'Home sweet home with gable roof and door'
		points: house
	}

	// 2. Space Rocket
	mut rocket := []Point{}
	rocket << Point{x: 0.50, y: 0.15, start: true}
	rocket << Point{x: 0.58, y: 0.35}
	rocket << Point{x: 0.58, y: 0.65}
	rocket << Point{x: 0.70, y: 0.75}
	rocket << Point{x: 0.58, y: 0.72}
	rocket << Point{x: 0.54, y: 0.75}
	rocket << Point{x: 0.50, y: 0.88}
	rocket << Point{x: 0.46, y: 0.75}
	rocket << Point{x: 0.42, y: 0.72}
	rocket << Point{x: 0.30, y: 0.75}
	rocket << Point{x: 0.42, y: 0.65}
	rocket << Point{x: 0.42, y: 0.35}
	rocket << Point{x: 0.50, y: 0.15}
	// Window
	rocket << Point{x: 0.50, y: 0.38, start: true}
	rocket << Point{x: 0.54, y: 0.42}
	rocket << Point{x: 0.50, y: 0.46}
	rocket << Point{x: 0.46, y: 0.42}
	rocket << Point{x: 0.50, y: 0.38}
	g.stencils << Stencil{
		name: 'Space Rocket'
		desc: 'Apollo capsule with booster fins & flame'
		points: rocket
	}

	// 3. Sailboat
	mut boat := []Point{}
	boat << Point{x: 0.20, y: 0.70, start: true}
	boat << Point{x: 0.80, y: 0.70}
	boat << Point{x: 0.70, y: 0.82}
	boat << Point{x: 0.30, y: 0.82}
	boat << Point{x: 0.20, y: 0.70}
	boat << Point{x: 0.50, y: 0.70, start: true}
	boat << Point{x: 0.50, y: 0.20}
	boat << Point{x: 0.50, y: 0.22, start: true}
	boat << Point{x: 0.74, y: 0.65}
	boat << Point{x: 0.50, y: 0.65}
	boat << Point{x: 0.48, y: 0.25, start: true}
	boat << Point{x: 0.32, y: 0.65}
	boat << Point{x: 0.48, y: 0.65}
	g.stencils << Stencil{
		name: 'Sailing Yacht'
		desc: 'Graceful regatta sloop with full sails'
		points: boat
	}

	// 4. 5-Pointed Star Mandala
	mut star := []Point{}
	cx := 0.50
	cy := 0.50
	r_out := 0.35
	r_in := 0.15
	for i in 0 .. 11 {
		a := f64(i) * math.pi / 5.0 - math.pi / 2.0
		r := if i % 2 == 0 { r_out } else { r_in }
		px := cx + r * math.cos(a)
		py := cy + r * math.sin(a)
		star << Point{x: px, y: py, start: i == 0}
	}
	g.stencils << Stencil{
		name: 'Star of Wonder'
		desc: 'Geometric 5-pointed symmetry star'
		points: star
	}

	// 5. Retro Sports Car
	mut car := []Point{}
	car << Point{x: 0.15, y: 0.65, start: true}
	car << Point{x: 0.25, y: 0.65}
	car << Point{x: 0.35, y: 0.55}
	car << Point{x: 0.65, y: 0.55}
	car << Point{x: 0.75, y: 0.65}
	car << Point{x: 0.85, y: 0.65}
	car << Point{x: 0.88, y: 0.72}
	car << Point{x: 0.78, y: 0.72}
	car << Point{x: 0.74, y: 0.78}
	car << Point{x: 0.66, y: 0.78}
	car << Point{x: 0.62, y: 0.72}
	car << Point{x: 0.38, y: 0.72}
	car << Point{x: 0.34, y: 0.78}
	car << Point{x: 0.26, y: 0.78}
	car << Point{x: 0.22, y: 0.72}
	car << Point{x: 0.12, y: 0.72}
	car << Point{x: 0.15, y: 0.65}
	g.stencils << Stencil{
		name: 'Cyber Roadster'
		desc: 'Sleek aerodynamic fastback coupe'
		points: car
	}
}

pub fn (mut g EtchGame) evaluate_stencil_progress() {
	if g.stencils.len == 0 || g.points.len < 10 {
		return
	}
	st := g.stencils[g.current_stencil]
	if st.points.len == 0 {
		return
	}

	mut matched := 0
	threshold := 18.0

	for tp in st.points {
		target_px := tp.x * f64(g.screen_w)
		target_py := tp.y * f64(g.screen_h)

		mut found := false
		for pt in g.points {
			dx := pt.x - target_px
			dy := pt.y - target_py
			if dx * dx + dy * dy < threshold * threshold {
				found = true
				break
			}
		}
		if found {
			matched++
		}
	}

	g.stencil_score = math.min(100.0, (f64(matched) / f64(st.points.len)) * 100.0)
	if g.stencil_score >= 85.0 {
		g.stencil_stars = 3
		g.stencil_cleared = true
	} else if g.stencil_score >= 60.0 {
		g.stencil_stars = 2
	} else if g.stencil_score >= 35.0 {
		g.stencil_stars = 1
	} else {
		g.stencil_stars = 0
	}
}

fn hsv_to_rgb(h f64, s f64, v f64) (u8, u8, u8) {
	i := int(h * 6.0)
	f := h * 6.0 - f64(i)
	p := v * (1.0 - s)
	q := v * (1.0 - f * s)
	t := v * (1.0 - (1.0 - f) * s)

	mut r := 0.0
	mut g := 0.0
	mut b := 0.0

	match i % 6 {
		0 { r = v; g = t; b = p }
		1 { r = q; g = v; b = p }
		2 { r = p; g = v; b = t }
		3 { r = p; g = q; b = v }
		4 { r = t; g = p; b = v }
		5 { r = v; g = p; b = q }
		else {}
	}
	return u8(r * 255.0), u8(g * 255.0), u8(b * 255.0)
}

pub fn (mut g EtchGame) save_state() {
	mut saved := load_etch_save()
	saved.save_state_valid = true
	mut lines := []string{}
	for pt in g.points {
		st := if pt.start { 1 } else { 0 }
		lines << '${pt.x},${pt.y},${pt.col.r},${pt.col.g},${pt.col.b},${st}'
	}
	saved.point_lines = lines
	save_etch_data(&saved)

	g.toast_msg = 'DRAWING SAVED (F5)'
	g.toast_timer = 2.0
}

pub fn (mut g EtchGame) load_state() {
	saved := load_etch_save()
	if !saved.save_state_valid || saved.point_lines.len == 0 {
		g.toast_msg = 'NO SAVED DRAWING'
		g.toast_timer = 2.0
		return
	}
	g.points.clear()
	for line in saved.point_lines {
		tokens := line.split(',')
		if tokens.len == 6 {
			x := tokens[0].f64()
			y := tokens[1].f64()
			r := u8(tokens[2].int())
			g_val := u8(tokens[3].int())
			b := u8(tokens[4].int())
			st := tokens[5] == '1'
			g.points << Point{
				x: x
				y: y
				col: Color{r, g_val, b, 255}
				start: st
			}
		}
	}
	g.toast_msg = 'DRAWING LOADED (F9)'
	g.toast_timer = 2.0
}
