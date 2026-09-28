module main

import gg
import math
import os
import rand
import time

pub struct ZumaTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm ZumaTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/zuma.png',
		'./assets/sprites/zuma.png',
		'../assets/sprites/zuma.png',
		'zuma/assets/sprites/zuma.png',
	]
	for p in candidates {
		if os.exists(p) {
			tex := load_texture(renderer.ctx, p)
			if tex != unsafe { nil } && tex.valid {
				tm.sprite_texture = tex
				println('Zuma Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

const win_width = 880
const win_height = 840

const render_ball_r = 16

struct ZumaParticle {
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

struct App {
mut:
	ctx           &gg.Context = unsafe { nil }
	renderer      Renderer
	last_tick     i64
	mouse_x       int
	mouse_y       int
	sound_mgr   SoundManager
	tex_mgr     ZumaTextureManager
	game        ZumaGame
	particles   []ZumaParticle
	float_texts []FloatText
	shake_timer f64
	paused      bool
	btn_reset   Button
	btn_sound   Button
	btn_pause   Button
}

fn new_app() App {
	btn_y := 770
	return App{
		last_tick: time.ticks()
		sound_mgr: new_sound_manager()
		game:      new_zuma_game()
		btn_reset: Button{
			x: 40, y: btn_y, w: 160, h: 42, text: 'RESET [R]',
			bg_color: Color{r: 45, g: 30, b: 25},
			hover_color: Color{r: 80, g: 48, b: 38},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 180, g: 90, b: 60},
		}
		btn_sound: Button{
			x: 220, y: btn_y, w: 160, h: 42, text: 'SOUND [M]',
			bg_color: Color{r: 25, g: 42, b: 45},
			hover_color: Color{r: 45, g: 72, b: 78},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 75, g: 140, b: 155},
		}
		btn_pause: Button{
			x: 400, y: btn_y, w: 160, h: 42, text: 'PAUSE [P]',
			bg_color: Color{r: 45, g: 42, b: 25},
			hover_color: Color{r: 78, g: 72, b: 40},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 165, g: 155, b: 70},
		}
	}
}

fn get_ball_colors(color_id int) (Color, Color, Color, Color) {
	match color_id {
		1 { // Ruby Red
			return Color{r: 235, g: 35, b: 50}, Color{r: 255, g: 140, b: 155}, Color{r: 130, g: 10, b: 20}, Color{r: 255, g: 230, b: 240}
		}
		2 { // Sapphire Blue
			return Color{r: 30, g: 135, b: 245}, Color{r: 120, g: 200, b: 255}, Color{r: 15, g: 65, b: 160}, Color{r: 215, g: 240, b: 255}
		}
		3 { // Emerald Green
			return Color{r: 35, g: 215, b: 75}, Color{r: 130, g: 255, b: 155}, Color{r: 15, g: 120, b: 35}, Color{r: 220, g: 255, b: 230}
		}
		4 { // Topaz Yellow
			return Color{r: 250, g: 215, b: 30}, Color{r: 255, g: 245, b: 135}, Color{r: 155, g: 130, b: 15}, Color{r: 255, g: 255, b: 220}
		}
		5 { // Amethyst Purple
			return Color{r: 200, g: 45, b: 240}, Color{r: 240, g: 140, b: 255}, Color{r: 120, g: 20, b: 150}, Color{r: 250, g: 220, b: 255}
		}
		else {
			return Color{r: 110, g: 110, b: 120}, Color{r: 165, g: 165, b: 175}, Color{r: 60, g: 60, b: 70}, Color{r: 220, g: 220, b: 230}
		}
	}
}

// Draw a 3D Sphere with Specular Highlight and Power-Up Glyphs
fn draw_marble(renderer &Renderer, cx int, cy int, color_id int, power PowerupType, tex &Texture) {
	if color_id == 0 {
		return
	}
	r := render_ball_r

	if tex != unsafe { nil } {
		col_idx := match power {
			.bomb { 5 }
			.reverse { 6 }
			.slow { 7 }
			else { color_id - 1 }
		}
		src := Rect{x: col_idx * 64, y: 0, w: 64, h: 64}
		dst := Rect{x: cx - r, y: cy - r, w: r * 2, h: r * 2}
		render_copy(renderer, tex, &src, &dst)
		return
	}

	main_c, high_c, shadow_c, glint_c := get_ball_colors(color_id)

	// Outer Shadow Disc
	for dy := -r; dy <= r; dy++ {
		dx_max := int(math.sqrt(f64(r * r - dy * dy)))
		s_rect := Rect{x: cx - dx_max, y: cy + dy, w: dx_max * 2, h: 1}
		dist_norm := f64(dy + r) / f64(2 * r)
		red := u8(f64(shadow_c.r) * (1.0 - dist_norm) + f64(main_c.r) * dist_norm)
		green := u8(f64(shadow_c.g) * (1.0 - dist_norm) + f64(main_c.g) * dist_norm)
		blue := u8(f64(shadow_c.b) * (1.0 - dist_norm) + f64(main_c.b) * dist_norm)

		set_render_draw_color(renderer, red, green, blue, 255)
		render_fill_rect(renderer, &s_rect)
	}

	// Inner Top Highlight Glow
	hl_r := r / 2
	hl_cx := cx - r / 3
	hl_cy := cy - r / 3
	for dy := -hl_r; dy <= hl_r; dy++ {
		dx_max := int(math.sqrt(f64(hl_r * hl_r - dy * dy)))
		h_rect := Rect{x: hl_cx - dx_max, y: hl_cy + dy, w: dx_max * 2, h: 1}
		set_render_draw_color(renderer, high_c.r, high_c.g, high_c.b, 180)
		render_fill_rect(renderer, &h_rect)
	}

	// Specular Glint Point
	set_render_draw_color(renderer, glint_c.r, glint_c.g, glint_c.b, 255)
	render_draw_point(renderer, cx - r / 3, cy - r / 3)
	render_draw_point(renderer, cx - r / 3 + 1, cy - r / 3)
	render_draw_point(renderer, cx - r / 3, cy - r / 3 + 1)

	// Powerup Symbols
	match power {
		.slow {
			set_render_draw_color(renderer, 255, 255, 255, 240)
			render_draw_line(renderer, cx - 4, cy, cx + 4, cy)
			render_draw_line(renderer, cx, cy - 4, cx, cy + 4)
			render_draw_line(renderer, cx - 3, cy - 3, cx + 3, cy + 3)
			render_draw_line(renderer, cx - 3, cy + 3, cx + 3, cy - 3)
		}
		.reverse {
			set_render_draw_color(renderer, 255, 255, 255, 240)
			render_draw_line(renderer, cx + 2, cy - 3, cx - 2, cy)
			render_draw_line(renderer, cx - 2, cy, cx + 2, cy + 3)
			render_draw_line(renderer, cx + 5, cy - 3, cx + 1, cy)
			render_draw_line(renderer, cx + 1, cy, cx + 5, cy + 3)
		}
		.bomb {
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_draw_line(renderer, cx - 5, cy, cx + 5, cy)
			render_draw_line(renderer, cx, cy - 5, cx, cy + 5)
		}
		.none {}
	}
}

fn (mut app App) spawn_burst(cx int, cy int, color_id int) {
	main_c, _, _, _ := get_ball_colors(color_id)
	for _ in 0 .. 18 {
		ang := rand.f64_in_range(0.0, 2.0 * math.pi) or { 0.0 }
		spd := rand.f64_in_range(90.0, 310.0) or { 160.0 }
		life := rand.f64_in_range(0.35, 0.7) or { 0.5 }
		app.particles << ZumaParticle{
			x:     f64(cx)
			y:     f64(cy)
			vx:    math.cos(ang) * spd
			vy:    math.sin(ang) * spd
			life:  life
			max_l: life
			color: main_c
			size:  rand.int_in_range(3, 6) or { 4 }
		}
	}
}

fn (mut app App) update(dt f64) {
	if app.paused {
		return
	}

	if app.shake_timer > 0 {
		app.shake_timer -= dt
	}

	prev_combo := app.game.combo_count
	app.game.update(dt)

	if app.game.combo_count > prev_combo && app.game.combo_count > 0 {
		app.sound_mgr.play_match_sound(app.game.combo_count)
		if app.game.combo_count > 1 {
			app.shake_timer = 0.2
			app.float_texts << FloatText{
				x:     f64(app.game.shooter_x)
				y:     f64(app.game.shooter_y - 45)
				text:  'COMBO x${app.game.combo_count}!'
				life:  1.1
				max_l: 1.1
				scale: 3
				color: Color{r: 255, g: 230, b: 60}
			}
		}
	}

	// Update Particles
	mut active_particles := []ZumaParticle{}
	for mut p in app.particles {
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.vy += 380.0 * dt
		p.vx *= 0.985
		p.life -= dt
		if p.life > 0 {
			active_particles << p
		}
	}
	app.particles = active_particles

	// Update Floating Texts
	mut active_texts := []FloatText{}
	for mut ft in app.float_texts {
		ft.y -= 35.0 * dt
		ft.life -= dt
		if ft.life > 0 {
			active_texts << ft
		}
	}
	app.float_texts = active_texts
}

fn (mut app App) render() {
	renderer := &app.renderer
	ticks := u32(time.ticks())

	// Ancient Aztec Jungle Midnight Background
	set_render_draw_color(renderer, 15, 20, 18, 255)
	render_clear(renderer)

	// Screen Shake Offset
	mut sx := 0
	mut sy := 0
	if app.shake_timer > 0 {
		mag := app.shake_timer * 16.0
		sx = int((rand.f64() * 2.0 - 1.0) * mag)
		sy = int((rand.f64() * 2.0 - 1.0) * mag)
	}

	// Header Banner
	draw_text_centered_fitted(renderer, win_width / 2 + sx, 20 + sy, 'ZUMA // TEMPLE OF THE STONE IDOL', 3, win_width - 60, Color{r: 255, g: 195, b: 50})
	draw_text_centered_fitted(renderer, win_width / 2 + sx, 56 + sy, 'AIM 360 STONE FROG & PREVENT SPHERES FROM REACHING THE SKULL!', 2, win_width - 60, Color{r: 170, g: 235, b: 215})

	// Render Carved Spiral Path Trench
	for i := 0; i < app.game.track.len - 1; i++ {
		p1 := app.game.track[i]
		p2 := app.game.track[i + 1]

		// Trench Shadow
		set_render_draw_color(renderer, 8, 12, 10, 255)
		for w := -render_ball_r - 4; w <= render_ball_r + 4; w++ {
			render_draw_line(renderer, int(p1.x) + w + sx, int(p1.y) + w + sy, int(p2.x) + w + sx, int(p2.y) + w + sy)
		}
		// Trench Inner Stone Bed
		set_render_draw_color(renderer, 32, 42, 38, 255)
		for w := -render_ball_r; w <= render_ball_r; w++ {
			render_draw_line(renderer, int(p1.x) + w + sx, int(p1.y) + sy, int(p2.x) + w + sx, int(p2.y) + sy)
		}
	}

	// Golden Skull Danger Pit (at end of track)
	if app.game.track.len > 0 {
		skull_pt := app.game.track[app.game.track.len - 1]
		sk_x := int(skull_pt.x) + sx
		sk_y := int(skull_pt.y) + sy

		// Golden Skull Frame
		sk_rect := Rect{x: sk_x - 30, y: sk_y - 30, w: 60, h: 60}
		if app.tex_mgr.sprite_texture != unsafe { nil } {
			sk_src := Rect{x: 0, y: 128, w: 64, h: 64}
			render_copy(renderer, app.tex_mgr.sprite_texture, &sk_src, &sk_rect)
		} else {
			set_render_draw_color(renderer, 45, 35, 15, 255)
			render_fill_rect(renderer, &sk_rect)
			set_render_draw_color(renderer, 240, 195, 50, 255)
			render_draw_rect(renderer, &sk_rect)

			// Glowing Red Eyes
			eye_pulse := u8((math.sin(f64(ticks) * 0.008) * 0.5 + 0.5) * 155.0 + 100.0)
			set_render_draw_color(renderer, eye_pulse, 20, 20, 255)
			eye1 := Rect{x: sk_x - 14, y: sk_y - 12, w: 8, h: 12}
			eye2 := Rect{x: sk_x + 6, y: sk_y - 12, w: 8, h: 12}
			render_fill_rect(renderer, &eye1)
			render_fill_rect(renderer, &eye2)
		}
	}

	// Render Rolling Balls Train
	for ball in app.game.balls {
		pos_x, pos_y := app.game.get_track_pos(ball.dist)
		draw_marble(renderer, int(pos_x) + sx, int(pos_y) + sy, ball.color, ball.powerup, app.tex_mgr.sprite_texture)
	}

	// Render Flying Projectile
	if app.game.projectile.active {
		draw_marble(renderer, int(app.game.projectile.x) + sx, int(app.game.projectile.y) + sy, app.game.projectile.color, .none, app.tex_mgr.sprite_texture)
	}

	// Stone Frog Turret in Center
	turret_cx := int(app.game.shooter_x) + sx
	turret_cy := int(app.game.shooter_y) + sy

	// Laser Aiming Guide Line
	mx := app.mouse_x
	my := app.mouse_y
	aim_dx := f64(mx - turret_cx)
	aim_dy := f64(my - turret_cy)
	aim_len := math.sqrt(aim_dx * aim_dx + aim_dy * aim_dy)
	if aim_len > 0.1 {
		ux := aim_dx / aim_len
		uy := aim_dy / aim_len
		set_render_draw_color(renderer, 255, 255, 255, 120)
		for d := 45; d < 300; d += 15 {
			gx := turret_cx + int(ux * f64(d))
			gy := turret_cy + int(uy * f64(d))
			g_dot := Rect{x: gx - 1, y: gy - 1, w: 3, h: 3}
			render_fill_rect(renderer, &g_dot)
		}
	}

	// Stone Frog Base
	frog_r := 34
	f_rect := Rect{x: turret_cx - frog_r, y: turret_cy - frog_r, w: frog_r * 2, h: frog_r * 2}
	if app.tex_mgr.sprite_texture != unsafe { nil } {
		frog_src := Rect{x: 0, y: 64, w: 64, h: 64}
		frog_deg := app.game.turret_angle * 180.0 / math.pi + 90.0
		render_copy_ex(renderer, app.tex_mgr.sprite_texture, &frog_src, &f_rect, frog_deg, unsafe { nil }, RendererFlip.none)
	} else {
		set_render_draw_color(renderer, 42, 54, 48, 255)
		render_fill_rect(renderer, &f_rect)
		set_render_draw_color(renderer, 95, 135, 115, 255)
		render_draw_rect(renderer, &f_rect)
	}

	// Loaded Ball inside Frog Mouth
	draw_marble(renderer, turret_cx, turret_cy, app.game.current_ball, .none, app.tex_mgr.sprite_texture)

	// Next Ball on Frog's Back
	back_bx := turret_cx - int(math.cos(app.game.turret_angle) * 22.0)
	back_by := turret_cy - int(math.sin(app.game.turret_angle) * 22.0)
	draw_marble(renderer, back_bx, back_by, app.game.next_ball, .none, app.tex_mgr.sprite_texture)

	// Left HUD Card: Score & Level
	card_x := 32
	card_y := 120
	card_w := 180
	card_h := 320
	card_rect := Rect{x: card_x, y: card_y, w: card_w, h: card_h}
	set_render_draw_color(renderer, 22, 32, 28, 240)
	render_fill_rect(renderer, &card_rect)
	set_render_draw_color(renderer, 75, 115, 95, 255)
	render_draw_rect(renderer, &card_rect)

	info_x := card_x + 14
	draw_text(renderer, info_x, card_y + 16, 'SCORE', 2, Color{r: 180, g: 220, b: 200})
	draw_text(renderer, info_x, card_y + 40, '${app.game.score}', 3, Color{r: 255, g: 230, b: 70})

	draw_text(renderer, info_x, card_y + 90, 'HIGH SCORE', 2, Color{r: 180, g: 220, b: 200})
	draw_text(renderer, info_x, card_y + 114, '${app.game.high_score}', 3, Color{r: 255, g: 160, b: 60})

	draw_text(renderer, info_x, card_y + 165, 'LEVEL', 2, Color{r: 180, g: 220, b: 200})
	draw_text(renderer, info_x, card_y + 188, '${app.game.level}', 3, Color{r: 90, g: 240, b: 215})

	draw_text(renderer, info_x, card_y + 240, 'BALLS LEFT', 2, Color{r: 180, g: 220, b: 200})
	draw_text(renderer, info_x, card_y + 264, '${app.game.balls.len}', 3, Color{r: 255, g: 255, b: 255})

	// Right HUD Card: Controls & Powerups
	rcard_x := 668
	rcard_y := 120
	rcard_w := 180
	rcard_h := 320
	rcard_rect := Rect{x: rcard_x, y: rcard_y, w: rcard_w, h: rcard_h}
	set_render_draw_color(renderer, 22, 32, 28, 240)
	render_fill_rect(renderer, &rcard_rect)
	set_render_draw_color(renderer, 75, 115, 95, 255)
	render_draw_rect(renderer, &rcard_rect)

	rhud_x := rcard_x + 14
	draw_text(renderer, rhud_x, rcard_y + 16, 'CONTROLS', 2, Color{r: 255, g: 255, b: 255})
	draw_text(renderer, rhud_x, rcard_y + 42, 'MOUSE: AIM 360', 1, Color{r: 190, g: 225, b: 210})
	draw_text(renderer, rhud_x, rcard_y + 64, 'CLICK/SPACE: SHOOT', 1, Color{r: 190, g: 225, b: 210})
	draw_text(renderer, rhud_x, rcard_y + 86, 'RCLICK/TAB: SWAP', 1, Color{r: 190, g: 225, b: 210})

	draw_text(renderer, rhud_x, rcard_y + 130, 'POWERUPS', 2, Color{r: 255, g: 215, b: 90})
	draw_text(renderer, rhud_x, rcard_y + 154, '* SLOWDOWN', 1, Color{r: 120, g: 235, b: 255})
	draw_text(renderer, rhud_x, rcard_y + 174, '<< REVERSE ROLL', 1, Color{r: 255, g: 220, b: 80})
	draw_text(renderer, rhud_x, rcard_y + 194, '+ BOMB EXPLOSION', 1, Color{r: 255, g: 100, b: 110})

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
	app.btn_reset.render(renderer, mx, my)
	app.btn_sound.render(renderer, mx, my)
	app.btn_pause.render(renderer, mx, my)

	// Overlays
	if app.game.state == .level_won {
		box := Rect{x: win_width / 2 - 200, y: win_height / 2 - 60, w: 400, h: 120}
		set_render_draw_color(renderer, 20, 35, 25, 245)
		render_fill_rect(renderer, &box)
		set_render_draw_color(renderer, 60, 240, 100, 255)
		render_draw_rect(renderer, &box)
		draw_text_centered(renderer, win_width / 2, win_height / 2 - 35, 'STAGE CLEARED!', 3, Color{r: 80, g: 255, b: 120})
		draw_text_centered(renderer, win_width / 2, win_height / 2 + 15, 'PRESS [SPACE] FOR NEXT STAGE', 2, Color{r: 255, g: 255, b: 255})
	} else if app.game.state == .game_over {
		box := Rect{x: win_width / 2 - 200, y: win_height / 2 - 60, w: 400, h: 120}
		set_render_draw_color(renderer, 35, 15, 20, 245)
		render_fill_rect(renderer, &box)
		set_render_draw_color(renderer, 255, 60, 70, 255)
		render_draw_rect(renderer, &box)
		draw_text_centered(renderer, win_width / 2, win_height / 2 - 35, 'SKULL BREACH! GAME OVER', 2, Color{r: 255, g: 70, b: 90})
		draw_text_centered(renderer, win_width / 2, win_height / 2 + 15, 'PRESS [R] TO RESTART  [F11] Fullscreen', 2, Color{r: 255, g: 255, b: 255})
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
			turret_cx := app.game.shooter_x
			turret_cy := app.game.shooter_y
			dx := f64(e.mouse_x) - turret_cx
			dy := f64(e.mouse_y) - turret_cy
			app.game.turret_angle = math.atan2(dy, dx)
		}
		.mouse_down {
			mx := int(e.mouse_x)
			my := int(e.mouse_y)
			if app.btn_reset.is_hovered(mx, my) {
				app.game = new_zuma_game()
			} else if app.btn_sound.is_hovered(mx, my) {
				app.sound_mgr.toggle_sound()
			} else if app.btn_pause.is_hovered(mx, my) {
				app.paused = !app.paused
			} else if e.mouse_button == .left {
				if app.game.state == .level_won {
					app.game.init_level(app.game.level + 1)
				} else {
					if app.game.shoot_ball() {
						app.sound_mgr.play_shoot_sound()
					}
				}
			} else if e.mouse_button == .right {
				app.game.swap_current_ball()
				app.sound_mgr.play_swap_sound()
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
				.escape {
					exit(0)
				}
				.r {
					app.game = new_zuma_game()
				}
				.p {
					app.paused = !app.paused
				}
				.m {
					app.sound_mgr.toggle_music()
				}
				.tab {
					app.game.swap_current_ball()
					app.sound_mgr.play_swap_sound()
				}
				.space {
					if app.game.state == .level_won {
						app.game.init_level(app.game.level + 1)
					} else {
						if app.game.shoot_ball() {
							app.sound_mgr.play_shoot_sound()
						}
					}
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
		window_title: 'ZUMA // PopCap Stone Idol Classic'
		user_data: &app
		frame_fn: on_frame
		event_fn: on_event
		bg_color: gg.Color{15, 20, 25, 255}
	)
	app.ctx = ctx
	app.renderer = Renderer{ctx: ctx}
	app.tex_mgr.init(&app.renderer)
	ctx.run()
}
