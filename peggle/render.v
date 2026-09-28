import math
import os

pub struct PeggleTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm PeggleTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/peggle.png',
		'./assets/sprites/peggle.png',
		'../assets/sprites/peggle.png',
		'peggle/assets/sprites/peggle.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('peggle Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

pub fn render_peggle_game(renderer &Renderer, mut g PeggleGame, win_w int, win_h int, sound_enabled bool, tex &Texture) {
	// 1. Magical Deep Purple/Blue Gradient
	for y in 0 .. win_h {
		factor := f64(y) / f64(win_h)
		r := u8(20.0 + factor * 25.0)
		gr := u8(15.0 + factor * 20.0)
		b := u8(45.0 + factor * 55.0)
		set_render_draw_color(renderer, r, gr, b, 255)
		render_draw_line(renderer, 0, y, win_w, y)
	}

	// 2. Side Golden Columns
	set_render_draw_color(renderer, 180, 130, 40, 255)
	col_l := Rect{45, 0, 15, win_h}
	col_r := Rect{win_w - 60, 0, 15, win_h}
	render_fill_rect(renderer, &col_l)
	render_fill_rect(renderer, &col_r)

	// 3. Aiming Guide Trajectory (when ready to shoot)
	if g.active_balls.len == 0 && g.balls_left > 0 && !g.is_game_over {
		cannon_x := f64(win_w) / 2.0
		cannon_y := 45.0
		set_render_draw_color(renderer, 255, 230, 100, 140)
		for step in 1 .. 14 {
			dist := f64(step * 24)
			gx := int(cannon_x + math.cos(g.cannon_angle) * dist)
			gy := int(cannon_y + math.sin(g.cannon_angle) * dist)
			draw_filled_circle(renderer, gx, gy, 2, Color{255, 230, 100, 140})
		}
	}

	// 4. Render Pegs
	for p in g.pegs {
		render_peg(renderer, p, tex)
	}

	// 5. Render Moving Bottom Catcher Bucket
	render_bucket(renderer, g.bucket_x, f64(win_h - 25), g.bucket_w, tex)

	// 6. Render Active Balls
	for b in g.active_balls {
		if b.active {
			bx := int(b.x)
			by := int(b.y)
			draw_filled_circle(renderer, bx, by, int(b.radius), Color{240, 240, 250, 255})
			draw_filled_circle(renderer, bx - 2, by - 2, 3, Color{255, 255, 255, 255})
		}
	}

	// 7. Render Overhead Rotating Cannon
	render_cannon(renderer, f64(win_w) / 2.0, 45.0, g.cannon_angle)

	// 8. Top Header & Status Meters
	render_peggle_hud(renderer, g, win_w, sound_enabled)

	// 9. Announcement Banner
	if g.banner_timer > 0.0 && g.banner_text != '' {
		bw := g.banner_text.len * 8 * 2 + 40
		bx := win_w / 2 - bw / 2
		by := 240

		set_render_draw_color(renderer, 15, 20, 35, 240)
		bg := Rect{bx, by, bw, 44}
		render_fill_rect(renderer, &bg)
		set_render_draw_color(renderer, 255, 215, 0, 255)
		render_draw_rect(renderer, &bg)

		draw_text_centered(renderer, win_w / 2, by + 14, g.banner_text, 2, Color{255, 230, 80, 255})
	}
}

fn render_peg(renderer &Renderer, p Peg, tex &Texture) {
	px := int(p.x)
	py := int(p.y)
	r := int(p.radius)

	if tex != unsafe { nil } {
		col_x := match p.ptype {
			.blue { if p.is_hit { 64 } else { 0 } }
			.orange { if p.is_hit { 192 } else { 128 } }
			.purple { 256 }
			.green { 320 }
		}
		src := Rect{ x: col_x, y: 0, w: 64, h: 64 }
		dst := Rect{ x: px - r, y: py - r, w: r * 2, h: r * 2 }
		render_copy(renderer, tex, &src, &dst)
		return
	}

	// Glow aura if hit
	if p.is_hit {
		draw_filled_circle(renderer, px, py, r + 4, Color{255, 255, 255, 180})
	}

	col := match p.ptype {
		.blue { Color{40, 140, 255, 255} }
		.orange { Color{255, 140, 20, 255} }
		.purple { Color{210, 40, 240, 255} }
		.green { Color{40, 230, 100, 255} }
	}

	draw_filled_circle(renderer, px, py, r, col)
	draw_filled_circle(renderer, px - 2, py - 2, r / 3, Color{255, 255, 255, 200})
}

fn render_bucket(renderer &Renderer, cx f64, cy f64, w f64, tex &Texture) {
	bx := int(cx - w / 2.0)
	by := int(cy)

	if tex != unsafe { nil } {
		src := Rect{ x: 0, y: 192, w: 64, h: 64 }
		dst := Rect{ x: bx, y: by - 4, w: int(w), h: 26 }
		render_copy(renderer, tex, &src, &dst)
		draw_text_centered(renderer, int(cx), by + 5, 'FREE BALL', 1, Color{255, 255, 255, 255})
		return
	}

	// Golden Bucket Catcher
	set_render_draw_color(renderer, 220, 175, 40, 255)
	b_rect := Rect{bx, by, int(w), 20}
	render_fill_rect(renderer, &b_rect)

	set_render_draw_color(renderer, 80, 40, 10, 255)
	render_draw_rect(renderer, &b_rect)

	draw_text_centered(renderer, int(cx), by + 6, 'FREE BALL', 1, Color{30, 20, 5, 255})
}

fn render_cannon(renderer &Renderer, cx f64, cy f64, angle f64) {
	// Cannon Base Dome
	draw_filled_circle(renderer, int(cx), int(cy), 22, Color{180, 140, 40, 255})

	// Rotating Barrel
	barrel_len := 30.0
	bx := int(cx + math.cos(angle) * barrel_len)
	by := int(cy + math.sin(angle) * barrel_len)

	set_render_draw_color(renderer, 220, 220, 230, 255)
	for i in -2 .. 3 {
		render_draw_line(renderer, int(cx) + i, int(cy), bx + i, by)
	}
}

fn render_peggle_hud(renderer &Renderer, g PeggleGame, win_w int, sound_enabled bool) {
	set_render_draw_color(renderer, 15, 20, 32, 220)
	bar := Rect{0, 0, win_w, 42}
	render_fill_rect(renderer, &bar)

	set_render_draw_color(renderer, 180, 140, 40, 255)
	render_draw_line(renderer, 0, 41, win_w, 41)

	// Title
	draw_text(renderer, 20, 14, '★ PEGGLE EXTREME ★', 1, Color{255, 215, 0, 255})

	// Stats
	draw_text(renderer, 210, 14, 'BALLS: ${g.balls_left}', 1, Color{100, 240, 255, 255})
	draw_text(renderer, 330, 14, 'ORANGE LEFT: ${g.orange_left}', 1, Color{255, 160, 40, 255})
	draw_text(renderer, 520, 14, 'SCORE: ${g.score}', 1, Color{100, 255, 140, 255})

	// Sound toggle badge
	sound_x := win_w - 140
	if sound_enabled {
		set_render_draw_color(renderer, 40, 120, 60, 255)
		btn := Rect{sound_x, 8, 120, 24}
		render_fill_rect(renderer, &btn)
		draw_text_centered(renderer, sound_x + 60, 13, 'SOUND: ON [M]', 1, Color{255, 255, 255, 255})
	} else {
		set_render_draw_color(renderer, 120, 35, 40, 255)
		btn := Rect{sound_x, 8, 120, 24}
		render_fill_rect(renderer, &btn)
		draw_text_centered(renderer, sound_x + 60, 13, 'MUTED [M]', 1, Color{255, 180, 180, 255})
	}
}
