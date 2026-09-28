module main

import math
import rand
import gg
import time

const win_width = 960
const win_height = 840

const cell_size = 40
const p1_board_x = 70
const p2_board_x = 580
const board_y = 110

const grid_w = pf_cols * cell_size
const grid_h = pf_rows * cell_size

struct PfParticle {
mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	life  f64
	max_l f64
	color Color
	size  int
}

struct FloatText {
mut:
	x     f64
	y     f64
	text  string
	life  f64
	max_l f64
	scale int
	color Color
}

struct HadoukenFx {
mut:
	x          f64
	y          f64
	vx         f64
	color      Color
	life       f64
	is_p1      bool
	power_size int
}

struct App {
mut:
	ctx               &gg.Context = unsafe { nil }
	renderer          Renderer
	last_tick         i64
	mouse_x           int
	mouse_y           int
	sound_mgr         SoundManager
	p1                PlayerBoard
	p2                PlayerBoard
	particles         []PfParticle
	float_texts       []FloatText
	hadoukens         []HadoukenFx
	shake_timer       f64
	p1_attack_timer   f64
	p2_attack_timer   f64
	p1_super_meter    f64
	p2_super_meter    f64
	paused            bool
	btn_reset         Button
	btn_sound         Button
	btn_bgm           Button
	btn_pause         Button
}

fn new_app() App {
	btn_y := 775
	return App{
		last_tick: time.ticks()
		sound_mgr: new_sound_manager()
		p1:        new_player_board(false)
		p2:        new_player_board(true)
		btn_reset: Button{
			x: 70, y: btn_y, w: 150, h: 42, text: 'RESET [R]',
			bg_color: Color{r: 48, g: 25, b: 35},
			hover_color: Color{r: 85, g: 40, b: 55},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 180, g: 75, b: 90},
		}
		btn_sound: Button{
			x: 235, y: btn_y, w: 150, h: 42, text: 'SFX [S]',
			bg_color: Color{r: 25, g: 38, b: 55},
			hover_color: Color{r: 45, g: 68, b: 98},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 75, g: 125, b: 180},
		}
		btn_bgm: Button{
			x: 400, y: btn_y, w: 150, h: 42, text: 'BGM [M]',
			bg_color: Color{r: 55, g: 28, b: 58},
			hover_color: Color{r: 95, g: 45, b: 100},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 190, g: 80, b: 210},
		}
		btn_pause: Button{
			x: 565, y: btn_y, w: 150, h: 42, text: 'PAUSE [P]',
			bg_color: Color{r: 45, g: 42, b: 25},
			hover_color: Color{r: 78, g: 72, b: 40},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 165, g: 155, b: 70},
		}
	}
}

fn get_pf_color(color_id int) (Color, Color, Color) {
	match color_id {
		1 { // Red (Ruby)
			return Color{r: 235, g: 35, b: 50}, Color{r: 255, g: 140, b: 150}, Color{r: 120, g: 10, b: 20}
		}
		2 { // Blue (Sapphire)
			return Color{r: 30, g: 135, b: 245}, Color{r: 120, g: 205, b: 255}, Color{r: 15, g: 60, b: 150}
		}
		3 { // Green (Emerald)
			return Color{r: 35, g: 215, b: 75}, Color{r: 130, g: 255, b: 160}, Color{r: 15, g: 110, b: 30}
		}
		4 { // Yellow (Topaz)
			return Color{r: 250, g: 215, b: 30}, Color{r: 255, g: 248, b: 140}, Color{r: 150, g: 120, b: 10}
		}
		else {
			return Color{r: 110, g: 110, b: 120}, Color{r: 165, g: 165, b: 175}, Color{r: 60, g: 60, b: 70}
		}
	}
}

// Draw a 3D Faceted Puzzle Fighter Gem with Crash Orb or Counter Timer
fn draw_pf_gem(renderer &Renderer, cx int, cy int, size int, cell GemCell, ticks u32) {
	if cell.color == 0 {
		return
	}
	r := size / 2 - 2
	main_c, high_c, shadow_c := get_pf_color(cell.color)

	match cell.nature {
		.crash_orb {
			// Multi-Layer Pulsing Crash Orb Detonator
			t := f64(ticks) * 0.012
			pulse := u8((math.sin(t * 3.5) * 0.5 + 0.5) * 70.0)

			// Swirling Corona Outer Rings
			for ring in 0 .. 4 {
				c_rect := Rect{x: cx - r - ring, y: cy - r - ring, w: (r + ring) * 2, h: (r + ring) * 2}
				alpha := u8(math.max(0, 180 - ring * 40))
				set_render_draw_color(renderer, main_c.r, main_c.g, main_c.b, alpha)
				render_draw_rect(renderer, &c_rect)
			}

			// Orb Sphere Core
			orb := Rect{x: cx - r + 2, y: cy - r + 2, w: (r - 2) * 2, h: (r - 2) * 2}
			set_render_draw_color(renderer, main_c.r, main_c.g, main_c.b, 255)
			render_fill_rect(renderer, &orb)

			// Diagonal Energy Crests
			set_render_draw_color(renderer, high_c.r, high_c.g, high_c.b, 255)
			render_draw_line(renderer, cx - r + 4, cy - r + 4, cx + r - 4, cy + r - 4)
			render_draw_line(renderer, cx - r + 4, cy + r - 4, cx + r - 4, cy - r + 4)

			// White Hot Star Center
			set_render_draw_color(renderer, 255, 255, 255, u8(180 + pulse))
			render_fill_rect(renderer, &Rect{x: cx - 3, y: cy - 3, w: 6, h: 6})
			render_draw_line(renderer, cx - 6, cy, cx + 6, cy)
			render_draw_line(renderer, cx, cy - 6, cx, cy + 6)
		}
		.counter {
			// Solid Darkened Shell with Countdown Number
			rect := Rect{x: cx - r + 1, y: cy - r + 1, w: (r - 1) * 2, h: (r - 1) * 2}
			set_render_draw_color(renderer, u8(main_c.r / 3), u8(main_c.g / 3), u8(main_c.b / 3), 255)
			render_fill_rect(renderer, &rect)

			// Metallic Border & Hazard Corners
			set_render_draw_color(renderer, 80, 85, 100, 255)
			render_draw_rect(renderer, &rect)

			// Corner Chevrons
			set_render_draw_color(renderer, 255, 215, 40, 255)
			render_draw_point(renderer, cx - r + 3, cy - r + 3)
			render_draw_point(renderer, cx + r - 4, cy - r + 3)
			render_draw_point(renderer, cx - r + 3, cy + r - 4)
			render_draw_point(renderer, cx + r - 4, cy + r - 4)

			// Embedded Timer Digit (Glowing White)
			digit_str := '${cell.timer}'
			draw_text_centered(renderer, cx, cy - 7, digit_str, 2, Color{r: 255, g: 255, b: 255})
		}
		.normal, .diamond {
			// 3D Faceted Jewel Block
			rect := Rect{x: cx - r + 1, y: cy - r + 1, w: (r - 1) * 2, h: (r - 1) * 2}
			set_render_draw_color(renderer, main_c.r, main_c.g, main_c.b, 255)
			render_fill_rect(renderer, &rect)

			// Top & Left Bevel Highlight
			set_render_draw_color(renderer, high_c.r, high_c.g, high_c.b, 255)
			for i in 0 .. 3 {
				render_draw_line(renderer, cx - r + 1 + i, cy - r + 1 + i, cx + r - 1 - i, cy - r + 1 + i)
				render_draw_line(renderer, cx - r + 1 + i, cy - r + 1 + i, cx - r + 1 + i, cy + r - 1 - i)
			}

			// Bottom & Right Bevel Shadow
			set_render_draw_color(renderer, shadow_c.r, shadow_c.g, shadow_c.b, 255)
			for i in 0 .. 3 {
				render_draw_line(renderer, cx - r + 1 + i, cy + r - 1 - i, cx + r - 1 - i, cy + r - 1 - i)
				render_draw_line(renderer, cx + r - 1 - i, cy - r + 1 + i, cx + r - 1 - i, cy + r - 1 - i)
			}

			// Inner Table Facet
			center_sq := Rect{x: cx - r / 2, y: cy - r / 2, w: r, h: r}
			set_render_draw_color(renderer, main_c.r, main_c.g, main_c.b, 255)
			render_fill_rect(renderer, &center_sq)

			// Specular Crystal Glint
			set_render_draw_color(renderer, 255, 255, 255, 220)
			render_draw_point(renderer, cx - r / 3, cy - r / 3)
			render_draw_point(renderer, cx - r / 3 + 1, cy - r / 3)

			// Giant Power Gem Cross Shimmer
			if cell.power_id > 0 {
				glint_pulse := int((math.sin(f64(ticks) / 80.0) + 1.0) * 2.0)
				set_render_draw_color(renderer, 255, 255, 255, 255)
				render_draw_line(renderer, cx - 4 - glint_pulse, cy, cx + 4 + glint_pulse, cy)
				render_draw_line(renderer, cx, cy - 4 - glint_pulse, cx, cy + 4 + glint_pulse)
			}

			// Dark Outer Border
			set_render_draw_color(renderer, 15, 15, 22, 255)
			render_draw_rect(renderer, &rect)
		}
	}
}

// ----------------------------------------------------
// Chibi Street Fighter Sprite Renderers (Ryu & Morrigan)
// ----------------------------------------------------

fn draw_chibi_ryu(renderer &Renderer, x int, y int, ticks u32, is_attacking bool, is_hurt bool, is_winner bool) {
	bounce := if is_attacking { 0 } else { int(math.sin(f64(ticks) / 100.0) * 3.0) }
	by := y + bounce

	// Headband Tail Waving Physics
	hb_wave := int(math.sin(f64(ticks) / 80.0) * 4.0)
	set_render_draw_color(renderer, 225, 25, 35, 255)
	render_fill_rect(renderer, &Rect{x: x - 12, y: by + 6 + hb_wave, w: 10, h: 4})
	render_fill_rect(renderer, &Rect{x: x - 18, y: by + 9 + hb_wave, w: 8, h: 3})

	// Karate Gi Body (White)
	set_render_draw_color(renderer, 240, 242, 250, 255)
	render_fill_rect(renderer, &Rect{x: x - 10, y: by + 16, w: 20, h: 22})

	// Black Belt
	set_render_draw_color(renderer, 20, 20, 25, 255)
	render_fill_rect(renderer, &Rect{x: x - 11, y: by + 26, w: 22, h: 4})
	render_fill_rect(renderer, &Rect{x: x - 4, y: by + 30, w: 4, h: 8})

	// Chibi Head (Skin Tone)
	skin_col := if is_hurt { Color{r: 255, g: 150, b: 150} } else { Color{r: 255, g: 205, b: 165} }
	set_render_draw_color(renderer, skin_col.r, skin_col.g, skin_col.b, 255)
	render_fill_rect(renderer, &Rect{x: x - 12, y: by - 4, w: 24, h: 20})

	// Spiky Brown Hair
	set_render_draw_color(renderer, 60, 35, 20, 255)
	render_fill_rect(renderer, &Rect{x: x - 14, y: by - 10, w: 28, h: 8})
	render_fill_rect(renderer, &Rect{x: x - 12, y: by - 12, w: 8, h: 4})
	render_fill_rect(renderer, &Rect{x: x + 2, y: by - 12, w: 8, h: 4})

	// Red Headband Front Wrap
	set_render_draw_color(renderer, 225, 25, 35, 255)
	render_fill_rect(renderer, &Rect{x: x - 13, y: by - 2, w: 26, h: 4})

	// Intense Fighter Eyes & Eyebrows
	set_render_draw_color(renderer, 30, 20, 15, 255)
	render_draw_line(renderer, x - 7, by + 3, x - 2, by + 5)
	render_draw_line(renderer, x + 7, by + 3, x + 2, by + 5)
	render_fill_rect(renderer, &Rect{x: x - 6, y: by + 6, w: 3, h: 4})
	render_fill_rect(renderer, &Rect{x: x + 3, y: by + 6, w: 3, h: 4})

	// Arms / Attack Stance
	if is_attacking {
		// Hadouken Thrust Pose
		set_render_draw_color(renderer, 240, 242, 250, 255)
		render_fill_rect(renderer, &Rect{x: x + 10, y: by + 18, w: 16, h: 8})
		// Red Sparring Gloves
		set_render_draw_color(renderer, 225, 25, 35, 255)
		render_fill_rect(renderer, &Rect{x: x + 24, y: by + 16, w: 8, h: 12})
	} else if is_winner {
		// Victory Fist Raised
		set_render_draw_color(renderer, 240, 242, 250, 255)
		render_fill_rect(renderer, &Rect{x: x + 8, y: by + 2, w: 8, h: 16})
		set_render_draw_color(renderer, 225, 25, 35, 255)
		render_fill_rect(renderer, &Rect{x: x + 8, y: by - 6, w: 8, h: 8})
	} else {
		// Guard Stance
		set_render_draw_color(renderer, 225, 25, 35, 255)
		render_fill_rect(renderer, &Rect{x: x + 8, y: by + 20, w: 6, h: 8})
		render_fill_rect(renderer, &Rect{x: x - 14, y: by + 20, w: 6, h: 8})
	}

	// Legs
	set_render_draw_color(renderer, 240, 242, 250, 255)
	render_fill_rect(renderer, &Rect{x: x - 9, y: by + 38, w: 7, h: 10})
	render_fill_rect(renderer, &Rect{x: x + 2, y: by + 38, w: 7, h: 10})
}

fn draw_chibi_morrigan(renderer &Renderer, x int, y int, ticks u32, is_attacking bool, is_hurt bool, is_winner bool) {
	bounce := if is_attacking { 0 } else { int(math.sin(f64(ticks) / 100.0 + 1.5) * 3.0) }
	by := y + bounce

	// Flapping Bat Wings (Dark Purple)
	wing_flap := int(math.sin(f64(ticks) / 90.0) * 5.0)
	set_render_draw_color(renderer, 70, 20, 95, 255)
	render_fill_rect(renderer, &Rect{x: x + 10, y: by + 4 + wing_flap, w: 16, h: 10})
	render_fill_rect(renderer, &Rect{x: x + 18, y: by + 2 + wing_flap, w: 12, h: 8})
	render_fill_rect(renderer, &Rect{x: x - 26, y: by + 4 + wing_flap, w: 16, h: 10})
	render_fill_rect(renderer, &Rect{x: x - 30, y: by + 2 + wing_flap, w: 12, h: 8})

	// Leotard Body (Black with Pink Accents)
	set_render_draw_color(renderer, 28, 24, 38, 255)
	render_fill_rect(renderer, &Rect{x: x - 9, y: by + 16, w: 18, h: 22})

	// Chibi Head
	skin_col := if is_hurt { Color{r: 255, g: 150, b: 150} } else { Color{r: 255, g: 215, b: 185} }
	set_render_draw_color(renderer, skin_col.r, skin_col.g, skin_col.b, 255)
	render_fill_rect(renderer, &Rect{x: x - 11, y: by - 4, w: 22, h: 20})

	// Long Teal/Green Hair
	set_render_draw_color(renderer, 30, 210, 150, 255)
	render_fill_rect(renderer, &Rect{x: x - 14, y: by - 12, w: 28, h: 10})
	render_fill_rect(renderer, &Rect{x: x - 16, y: by - 2, w: 6, h: 22})
	render_fill_rect(renderer, &Rect{x: x + 10, y: by - 2, w: 6, h: 22})

	// Head Bat-Wing Horns
	set_render_draw_color(renderer, 60, 25, 90, 255)
	render_fill_rect(renderer, &Rect{x: x - 15, y: by - 16, w: 6, h: 8})
	render_fill_rect(renderer, &Rect{x: x + 9, y: by - 16, w: 6, h: 8})

	// Playful Eyes
	set_render_draw_color(renderer, 190, 40, 160, 255)
	render_fill_rect(renderer, &Rect{x: x - 6, y: by + 4, w: 3, h: 5})
	render_fill_rect(renderer, &Rect{x: x + 3, y: by + 4, w: 3, h: 5})

	// Attack / Victory Poses
	if is_attacking {
		// Soul Fist Projectile Cast
		set_render_draw_color(renderer, 220, 60, 240, 255)
		render_fill_rect(renderer, &Rect{x: x - 22, y: by + 16, w: 14, h: 10})
	} else if is_winner {
		// Victory Spin Pose
		set_render_draw_color(renderer, 255, 120, 220, 255)
		render_fill_rect(renderer, &Rect{x: x - 12, y: by + 4, w: 6, h: 12})
	}

	// Legs
	set_render_draw_color(renderer, 28, 24, 38, 255)
	render_fill_rect(renderer, &Rect{x: x - 8, y: by + 38, w: 6, h: 10})
	render_fill_rect(renderer, &Rect{x: x + 2, y: by + 38, w: 6, h: 10})
}

// ----------------------------------------------------
// App Update & Event Handling
// ----------------------------------------------------

fn (mut app App) spawn_burst(cx int, cy int, color_id int) {
	main_c, _, _ := get_pf_color(color_id)
	for _ in 0 .. 20 {
		ang := rand.f64_in_range(0.0, 2.0 * math.pi) or { 0.0 }
		spd := rand.f64_in_range(120.0, 360.0) or { 200.0 }
		life := rand.f64_in_range(0.4, 0.8) or { 0.6 }
		app.particles << PfParticle{
			x:     f64(cx)
			y:     f64(cy)
			vx:    math.cos(ang) * spd
			vy:    math.sin(ang) * spd
			life:  life
			max_l: life
			color: main_c
			size:  rand.int_in_range(3, 7) or { 4 }
		}
	}
}

fn (mut app App) update(dt f64) {
	if app.paused {
		return
	}

	// Background Music Streamer
	app.sound_mgr.update_bgm(dt, true)

	if app.shake_timer > 0 {
		app.shake_timer -= dt
	}
	if app.p1_attack_timer > 0 {
		app.p1_attack_timer -= dt
	}
	if app.p2_attack_timer > 0 {
		app.p2_attack_timer -= dt
	}

	prev_p1_chain := app.p1.chain_count
	prev_p2_chain := app.p2.chain_count

	p1_garbage := app.p1.update(dt)
	p2_garbage := app.p2.update(dt)

	if p1_garbage > 0 {
		app.p2.receive_garbage(p1_garbage)
		app.sound_mgr.play_garbage_drop_sound()
	}
	if p2_garbage > 0 {
		app.p1.receive_garbage(p2_garbage)
		app.sound_mgr.play_garbage_drop_sound()
	}

	// Attack & Combo Triggers for P1
	if app.p1.chain_count > prev_p1_chain && app.p1.chain_count > 0 {
		app.sound_mgr.play_crash_sound(app.p1.chain_count)
		app.sound_mgr.play_hadouken_sound()
		app.shake_timer = 0.28
		app.p1_attack_timer = 0.6
		app.p1_super_meter = math.min(100.0, app.p1_super_meter + f64(app.p1.chain_count * 25))

		// Launch Glowing Hadouken Projectile
		app.hadoukens << HadoukenFx{
			x:          f64(p1_board_x + grid_w + 20)
			y:          f64(board_y + 460)
			vx:         450.0
			color:      Color{r: 80, g: 200, b: 255}
			life:       0.7
			is_p1:      true
			power_size: app.p1.chain_count
		}

		combo_label := if app.p1.chain_count >= 3 { 'HADOUKEN!!' } else { 'CHAIN x${app.p1.chain_count}!' }
		app.float_texts << FloatText{
			x:     f64(p1_board_x + grid_w / 2)
			y:     f64(board_y + grid_h / 2 - 20)
			text:  combo_label
			life:  1.2
			max_l: 1.2
			scale: 3
			color: Color{r: 255, g: 230, b: 60}
		}
	}

	// Attack & Combo Triggers for P2
	if app.p2.chain_count > prev_p2_chain && app.p2.chain_count > 0 {
		app.sound_mgr.play_crash_sound(app.p2.chain_count)
		app.sound_mgr.play_hadouken_sound()
		app.shake_timer = 0.28
		app.p2_attack_timer = 0.6
		app.p2_super_meter = math.min(100.0, app.p2_super_meter + f64(app.p2.chain_count * 25))

		// Launch Glowing Soul Fist Projectile
		app.hadoukens << HadoukenFx{
			x:          f64(p2_board_x - 20)
			y:          f64(board_y + 460)
			vx:         -450.0
			color:      Color{r: 220, g: 80, b: 240}
			life:       0.7
			is_p1:      false
			power_size: app.p2.chain_count
		}

		combo_label := if app.p2.chain_count >= 3 { 'SOUL FIST!!' } else { 'CHAIN x${app.p2.chain_count}!' }
		app.float_texts << FloatText{
			x:     f64(p2_board_x + grid_w / 2)
			y:     f64(board_y + grid_h / 2 - 20)
			text:  combo_label
			life:  1.2
			max_l: 1.2
			scale: 3
			color: Color{r: 255, g: 90, b: 120}
		}
	}

	// Update Hadouken Fireball Projectiles
	mut active_hadoukens := []HadoukenFx{}
	for mut h in app.hadoukens {
		h.x += h.vx * dt
		h.life -= dt
		if h.life > 0 {
			active_hadoukens << h
		}
	}
	app.hadoukens = active_hadoukens

	// Update Particles
	mut active_particles := []PfParticle{}
	for mut p in app.particles {
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.vy += 420.0 * dt
		p.vx *= 0.98
		p.life -= dt
		if p.life > 0 {
			active_particles << p
		}
	}
	app.particles = active_particles

	// Update Floating Texts
	mut active_texts := []FloatText{}
	for mut ft in app.float_texts {
		ft.y -= 38.0 * dt
		ft.life -= dt
		if ft.life > 0 {
			active_texts << ft
		}
	}
	app.float_texts = active_texts
}

// Render a Single Player Board
fn render_player_board(renderer &Renderer, bx int, by int, board &PlayerBoard, ticks u32, is_p1 bool) {
	// Frame with 3D Arcade Cabinet Bevel
	frame := Rect{x: bx - 8, y: by - 8, w: grid_w + 16, h: grid_h + 16}
	set_render_draw_color(renderer, 28, 24, 42, 255)
	render_fill_rect(renderer, &frame)

	frame_c := if is_p1 { Color{r: 60, g: 150, b: 245} } else { Color{r: 245, g: 70, b: 110} }
	set_render_draw_color(renderer, frame_c.r, frame_c.g, frame_c.b, 255)
	render_draw_rect(renderer, &frame)

	// Inner Board Background
	bg := Rect{x: bx, y: by, w: grid_w, h: grid_h}
	set_render_draw_color(renderer, 10, 8, 18, 255)
	render_fill_rect(renderer, &bg)

	// Grid Lines
	set_render_draw_color(renderer, 24, 18, 36, 255)
	for r in 0 .. pf_rows + 1 {
		render_draw_line(renderer, bx, by + r * cell_size, bx + grid_w, by + r * cell_size)
	}
	for c in 0 .. pf_cols + 1 {
		render_draw_line(renderer, bx + c * cell_size, by, bx + c * cell_size, by + grid_h)
	}

	// Warning Line at top (Row 0 / Danger zone)
	set_render_draw_color(renderer, 255, 30, 60, 150)
	render_draw_line(renderer, bx, by + cell_size, bx + grid_w, by + cell_size)

	// Render Settled Gems
	for r in 0 .. pf_rows {
		for c in 0 .. pf_cols {
			cell := board.grid[r][c]
			if cell.color != 0 {
				cx := bx + c * cell_size + cell_size / 2
				cy := by + r * cell_size + cell_size / 2
				draw_pf_gem(renderer, cx, cy, cell_size, cell, ticks)
			}
		}
	}

	// Render Active Falling Pair
	if board.state == .falling {
		// Main Gem
		if board.pair.r1 >= 0 && board.pair.r1 < f64(pf_rows) {
			cx := bx + board.pair.c1 * cell_size + cell_size / 2
			cy := by + int(board.pair.r1 * f64(cell_size)) + cell_size / 2
			draw_pf_gem(renderer, cx, cy, cell_size, GemCell{color: board.pair.color1, nature: board.pair.nat1}, ticks)
		}
		// Sub Gem
		if board.pair.r2 >= 0 && board.pair.r2 < f64(pf_rows) && board.pair.c2 >= 0 && board.pair.c2 < pf_cols {
			cx := bx + board.pair.c2 * cell_size + cell_size / 2
			cy := by + int(board.pair.r2 * f64(cell_size)) + cell_size / 2
			draw_pf_gem(renderer, cx, cy, cell_size, GemCell{color: board.pair.color2, nature: board.pair.nat2}, ticks)
		}
	}

	// Header Label
	p_title := if is_p1 { '1P RYU (YOU)' } else { '2P CPU (MORRIGAN)' }
	draw_text_centered(renderer, bx + grid_w / 2, by - 36, p_title, 2, frame_c)

	// Bottom Score
	draw_text_centered(renderer, bx + grid_w / 2, by + grid_h + 12, 'SCORE: ${board.score}', 2, Color{r: 255, g: 235, b: 120})
}

fn (mut app App) render() {
	renderer := &app.renderer
	ticks := u32(time.ticks())

	// Capcom Arcade Midnight Arena with Animated Grid Floor
	set_render_draw_color(renderer, 12, 10, 20, 255)
	render_clear(renderer)

	// Perspective Cyber Grid Floor
	grid_offset := int((ticks / 30) % 24)
	for y := 620; y < win_height; y += 24 {
		set_render_draw_color(renderer, 24, 18, 44, 255)
		render_draw_line(renderer, 0, y + grid_offset, win_width, y + grid_offset)
	}

	// Screen Shake Offset
	mut sx := 0
	mut sy := 0
	if app.shake_timer > 0 {
		mag := app.shake_timer * 18.0
		sx = int((rand.f64() * 2.0 - 1.0) * mag)
		sy = int((rand.f64() * 2.0 - 1.0) * mag)
	}

	// Title Banner
	draw_text_centered_fitted(renderer, win_width / 2 + sx, 20 + sy, 'SUPER PUZZLE FIGHTER II TURBO', 3, win_width - 60, Color{r: 255, g: 195, b: 40})
	draw_text_centered_fitted(renderer, win_width / 2 + sx, 56 + sy, 'ARCADE GEM BATTLER // CAPCOM TURBO EDITION', 2, win_width - 60, Color{r: 170, g: 215, b: 255})

	// Render P1 and P2 Boards
	render_player_board(renderer, p1_board_x + sx, board_y + sy, &app.p1, ticks, true)
	render_player_board(renderer, p2_board_x + sx, board_y + sy, &app.p2, ticks, false)

	// Center Arena HUD: Next Queue, Super Meter & VS Emblem
	center_x := win_width / 2 + sx

	// Glowing "VS" Emblem with Fire Aura
	vs_pulse := int(math.sin(f64(ticks) / 90.0) * 4.0)
	draw_text_centered(renderer, center_x, board_y + 10 + vs_pulse, 'VS', 4, Color{r: 255, g: 60, b: 75})

	// Next Pair Preview Box (P1)
	draw_text_centered(renderer, center_x, board_y + 65, 'NEXT', 2, Color{r: 190, g: 200, b: 230})
	nbox := Rect{x: center_x - cell_size / 2 - 4, y: board_y + 88, w: cell_size + 8, h: cell_size * 2 + 8}
	set_render_draw_color(renderer, 24, 20, 36, 255)
	render_fill_rect(renderer, &nbox)
	set_render_draw_color(renderer, 85, 75, 120, 255)
	render_draw_rect(renderer, &nbox)

	draw_pf_gem(renderer, center_x, board_y + 92 + cell_size / 2, cell_size, GemCell{color: app.p1.next_pair.color1, nature: app.p1.next_pair.nat1}, ticks)
	draw_pf_gem(renderer, center_x, board_y + 92 + cell_size + cell_size / 2, cell_size, GemCell{color: app.p1.next_pair.color2, nature: app.p1.next_pair.nat2}, ticks)

	// Center Stage Chibi Fighters (Ryu vs Morrigan)
	p1_hurt := app.p2_attack_timer > 0.1
	p2_hurt := app.p1_attack_timer > 0.1
	p1_win := app.p2.state == .game_over
	p2_win := app.p1.state == .game_over

	draw_chibi_ryu(renderer, center_x - 55, board_y + 460, ticks, app.p1_attack_timer > 0, p1_hurt, p1_win)
	draw_chibi_morrigan(renderer, center_x + 55, board_y + 460, ticks, app.p2_attack_timer > 0, p2_hurt, p2_win)

	// Super Combo Meter (Dual Bars)
	meter_w := 140
	meter_h := 16
	m_rect := Rect{x: center_x - meter_w / 2, y: board_y + 205, w: meter_w, h: meter_h}
	set_render_draw_color(renderer, 20, 20, 30, 255)
	render_fill_rect(renderer, &m_rect)

	p1_ratio := math.min(1.0, app.p1_super_meter / 100.0)
	if p1_ratio > 0 {
		fill_w := int(f64(meter_w - 4) * p1_ratio)
		set_render_draw_color(renderer, 255, 180, 40, 255)
		render_fill_rect(renderer, &Rect{x: m_rect.x + 2, y: m_rect.y + 2, w: fill_w, h: meter_h - 4})
	}
	set_render_draw_color(renderer, 255, 255, 255, 255)
	render_draw_rect(renderer, &m_rect)
	draw_text_centered(renderer, center_x, board_y + 226, 'SUPER COMBO', 1, Color{r: 255, g: 255, b: 255})

	// Controls Panel in Center Bottom
	draw_text_centered(renderer, center_x, board_y + 265, 'CONTROLS', 2, Color{r: 255, g: 215, b: 90})
	draw_text_centered(renderer, center_x, board_y + 292, 'A / D: MOVE', 1, Color{r: 190, g: 200, b: 230})
	draw_text_centered(renderer, center_x, board_y + 310, 'W / UP: ROTATE', 1, Color{r: 190, g: 200, b: 230})
	draw_text_centered(renderer, center_x, board_y + 328, 'S / DOWN: SOFT DROP', 1, Color{r: 190, g: 200, b: 230})
	draw_text_centered(renderer, center_x, board_y + 346, 'SPACE: HARD DROP', 1, Color{r: 190, g: 200, b: 230})
	draw_text_centered(renderer, center_x, board_y + 364, 'M: TOGGLE BGM', 1, Color{r: 255, g: 140, b: 220})

	// Render Hadouken Fireball Projectiles
	for h in app.hadoukens {
		pulse := int(math.sin(f64(ticks) / 40.0) * 4.0)
		r := 10 + pulse
		set_render_draw_color(renderer, h.color.r, h.color.g, h.color.b, 255)
		render_fill_rect(renderer, &Rect{x: int(h.x) - r, y: int(h.y) - r, w: r * 2, h: r * 2})
		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_fill_rect(renderer, &Rect{x: int(h.x) - r / 2, y: int(h.y) - r / 2, w: r, h: r})
	}

	// Render Particles
	for p in app.particles {
		prect := Rect{x: int(p.x), y: int(p.y), w: p.size, h: p.size}
		alpha := u8((p.life / p.max_l) * 255.0)
		set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, alpha)
		render_fill_rect(renderer, &prect)
	}

	// Render Floating Texts
	for ft in app.float_texts {
		draw_text_centered(renderer, int(ft.x), int(ft.y), ft.text, ft.scale, ft.color)
	}

	// Buttons
	mx := app.mouse_x
	my := app.mouse_y
	app.btn_reset.render(renderer, mx, my)
	app.btn_sound.render(renderer, mx, my)
	app.btn_bgm.render(renderer, mx, my)
	app.btn_pause.render(renderer, mx, my)

	// Overlays
	if app.p1.state == .game_over || app.p2.state == .game_over {
		box := Rect{x: win_width / 2 - 200, y: win_height / 2 - 60, w: 400, h: 120}
		set_render_draw_color(renderer, 25, 15, 25, 245)
		render_fill_rect(renderer, &box)
		set_render_draw_color(renderer, 255, 190, 40, 255)
		render_draw_rect(renderer, &box)
		winner_text := if app.p2.state == .game_over { 'YOU WIN! K.O.!' } else { 'CPU WINS! K.O.!' }
		win_c := if app.p2.state == .game_over { Color{r: 80, g: 255, b: 120} } else { Color{r: 255, g: 80, b: 90} }
		draw_text_centered(renderer, win_width / 2, win_height / 2 - 35, winner_text, 3, win_c)
		draw_text_centered(renderer, win_width / 2, win_height / 2 + 15, 'PRESS [R] TO REMATCH', 2, Color{r: 255, g: 255, b: 255})
	} else if app.paused {
		box := Rect{x: win_width / 2 - 160, y: win_height / 2 - 50, w: 320, h: 100}
		set_render_draw_color(renderer, 20, 25, 40, 245)
		render_fill_rect(renderer, &box)
		draw_text_centered(renderer, win_width / 2, win_height / 2 - 25, 'PAUSED', 3, Color{r: 255, g: 220, b: 80})
		draw_text_centered(renderer, win_width / 2, win_height / 2 + 15, 'PRESS [P] TO RESUME', 2, Color{r: 200, g: 220, b: 255})
	}

	
	
}


fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	app.ctx.begin()

	now := time.ticks()
	raw_dt := f32(now - app.last_tick) / 1000.0
	app.last_tick = now
	dt := if raw_dt > 0.05 { f32(0.05) } else { raw_dt }

	app.update(f64(dt))
	app.sound_mgr.update()

	app.render()
	prod_fx_render(app.ctx)
	app.ctx.end()
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	if e.typ in [.mouse_move, .mouse_down, .mouse_up, .mouse_scroll] && app.renderer.scale > 0.001 {
		mut me := unsafe { &gg.Event(e) }
		me.mouse_x = (e.mouse_x - app.renderer.offset_x) / app.renderer.scale
		me.mouse_y = (e.mouse_y - app.renderer.offset_y) / app.renderer.scale
	}
	match e.typ {
		.mouse_move {
			app.mouse_x = int(e.mouse_x)
			app.mouse_y = int(e.mouse_y)
		}
		.mouse_down {
			mx := int(e.mouse_x)
			my := int(e.mouse_y)
			app.mouse_x = mx
			app.mouse_y = my
			if app.btn_reset.is_hovered(mx, my) {
				app.p1 = new_player_board(false)
				app.p2 = new_player_board(true)
				app.p1_super_meter = 0
				app.p2_super_meter = 0
				app.hadoukens.clear()
			} else if app.btn_sound.is_hovered(mx, my) {
				app.sound_mgr.toggle_sound()
			} else if app.btn_bgm.is_hovered(mx, my) {
				app.sound_mgr.toggle_bgm()
			} else if app.btn_pause.is_hovered(mx, my) {
				app.paused = !app.paused
			}
		}
		.key_down {
			match e.key_code {
				.f11, .grave_accent {
					gg.toggle_fullscreen()
				}
				.f10 {
					prod_fx_cycle_mode()
				}
				.n {
					app.sound_mgr.toggle_sfx()
				}
				.escape {
					app.sound_mgr.cleanup()
					exit(0)
				}
				.r {
					app.p1 = new_player_board(false)
					app.p2 = new_player_board(true)
					app.p1_super_meter = 0
					app.p2_super_meter = 0
					app.hadoukens.clear()
				}
				.p {
					app.paused = !app.paused
				}
				.s {
					app.sound_mgr.toggle_sound()
				}
				.m, .b {
					app.sound_mgr.toggle_bgm()
				}
				.left, .a {
					if app.p1.move_pair(-1) {
						app.sound_mgr.play_move_sound()
					}
				}
				.right, .d {
					if app.p1.move_pair(1) {
						app.sound_mgr.play_move_sound()
					}
				}
				.up, .w {
					app.p1.rotate(1)
					app.sound_mgr.play_rotate_sound()
				}
				.x {
					app.p1.rotate(-1)
					app.sound_mgr.play_rotate_sound()
				}
				.down {
					if app.p1.state == .falling {
						app.p1.pair.r1 += 0.8
					}
				}
				.space {
					app.p1.hard_drop()
				}
				else {}
			}
		}
		else {}
	}
}

fn main() {
	mut app := new_app()
	mut ctx := gg.new_context(
		width: win_width
		height: win_height
		resizable:     true
		window_title: 'SUPER PUZZLE FIGHTER II TURBO // Arcade Gem Battler'
		user_data: &app
		frame_fn: on_frame
		event_fn: on_event
		bg_color: gg.Color{12, 10, 20, 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{ctx: ctx}
	ctx.run()
}
