module main

import math
import os
import rand



pub struct AsteroidsTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm AsteroidsTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/asteroids.png',
		'./assets/sprites/asteroids.png',
		'../assets/sprites/asteroids.png',
		'asteroids/assets/sprites/asteroids.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('asteroids Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

struct Particle {
pub mut:
	x        f64
	y        f64
	dx       f64
	dy       f64
	life     f64
	max_life f64
	color    Color
}

struct Button {
	x            int
	y            int
	w            int
	h            int
	bg_color     Color
	hover_color  Color
	text_color   Color
	border_color Color
mut:
	text string
}

fn (b Button) contains(x int, y int) bool {
	return x >= b.x && x <= b.x + b.w && y >= b.y && y <= b.y + b.h
}

fn (b Button) render(renderer &Renderer, mouse_x int, mouse_y int) {
	is_hover := b.contains(mouse_x, mouse_y)
	color := if is_hover { b.hover_color } else { b.bg_color }

	rect := Rect{
		x: b.x
		y: b.y
		w: b.w
		h: b.h
	}
	set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	render_fill_rect(renderer, &rect)

	set_render_draw_color(renderer, b.border_color.r, b.border_color.g, b.border_color.b, b.border_color.a)
	render_draw_rect(renderer, &rect)

	text_x := b.x + (b.w - b.text.len * 8 * 2) / 2
	text_y := b.y + (b.h - 16) / 2
	draw_text(renderer, text_x, text_y, b.text, 2, b.text_color)
}

// 16x16 Ship Sprite Matrix (0 = transparent, 1 = hull light, 2 = hull dark, 3 = cockpit glass, 4 = weapon/accent, 5 = engine)
const ship_sprite = [
	[0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0],
	[0,0,0,0,0,0,1,3,3,1,0,0,0,0,0,0],
	[0,0,0,0,0,1,1,3,3,1,1,0,0,0,0,0],
	[0,0,0,0,0,1,2,3,3,2,1,0,0,0,0,0],
	[0,0,0,0,1,1,2,2,2,2,1,1,0,0,0,0],
	[0,0,0,0,1,2,2,1,1,2,2,1,0,0,0,0],
	[0,0,0,1,1,2,1,1,1,1,2,1,1,0,0,0],
	[0,0,0,1,2,2,1,4,4,1,2,2,1,0,0,0],
	[0,0,1,1,2,1,1,4,4,1,1,2,1,1,0,0],
	[0,1,1,2,2,1,1,1,1,1,1,2,2,1,1,0],
	[1,1,2,2,1,1,2,5,5,2,1,1,2,2,1,1],
	[1,4,2,1,1,2,5,5,5,5,2,1,1,2,4,1],
	[1,4,1,1,0,0,5,5,5,5,0,0,1,1,4,1],
	[0,1,0,0,0,0,2,5,5,2,0,0,0,0,1,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
]

// 16x10 UFO Saucer Sprite Matrix
const ufo_sprite = [
	[0,0,0,0,0,3,3,3,3,3,3,0,0,0,0,0],
	[0,0,0,0,3,3,4,4,4,4,3,3,0,0,0,0],
	[0,0,0,3,3,4,4,4,4,4,4,3,3,0,0,0],
	[0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
	[1,1,2,2,1,1,2,2,1,1,2,2,1,1,2,1],
	[1,2,5,5,2,2,5,5,2,2,5,5,2,2,5,1],
	[1,1,2,2,1,1,2,2,1,1,2,2,1,1,2,1],
	[0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
	[0,0,0,2,2,2,2,2,2,2,2,2,2,0,0,0],
	[0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0]
]

// Asteroid 16x16 Base Sprite Matrix (0 = trans, 1 = light crater, 2 = base rock, 3 = shadow, 4 = dark crater)
const asteroid_sprite = [
	[0,0,0,0,2,2,2,1,1,2,2,2,0,0,0,0],
	[0,0,2,2,1,1,1,1,2,2,2,2,2,2,0,0],
	[0,2,1,1,1,2,2,2,2,4,4,2,2,2,2,0],
	[0,2,1,2,2,2,2,2,4,4,3,3,2,2,2,0],
	[2,1,1,2,2,4,4,2,2,3,3,2,2,2,3,2],
	[2,2,2,2,4,4,3,3,2,2,2,2,2,3,3,2],
	[2,2,2,2,2,3,3,2,2,2,1,1,2,3,3,2],
	[2,2,4,4,2,2,2,2,2,1,1,1,1,2,3,2],
	[2,4,4,3,3,2,2,2,1,1,2,2,2,3,3,2],
	[2,2,3,3,2,2,2,2,2,2,2,2,3,3,2,2],
	[2,2,2,2,2,4,4,2,2,2,2,3,3,3,2,0],
	[0,2,2,2,4,4,3,3,2,2,3,3,3,2,2,0],
	[0,2,2,2,2,3,3,2,2,3,3,3,2,2,0,0],
	[0,0,2,2,2,2,2,2,3,3,3,2,2,0,0,0],
	[0,0,0,2,2,2,3,3,3,2,2,0,0,0,0,0],
	[0,0,0,0,0,2,2,2,0,0,0,0,0,0,0,0]
]

fn draw_sprite_pixel(renderer &Renderer, px int, py int, scale int, c Color) {
	if scale == 1 {
		set_render_draw_color(renderer, c.r, c.g, c.b, c.a)
		render_draw_point(renderer, px, py)
	} else {
		set_render_draw_color(renderer, c.r, c.g, c.b, c.a)
		rect := Rect{ x: px, y: py, w: scale, h: scale }
		render_fill_rect(renderer, &rect)
	}
}

fn draw_rotated_ship_sprite(renderer &Renderer, cx f64, cy f64, angle f64, scale int, accent_col Color, has_thrust bool, has_shield bool, tex &Texture) {
	if tex != unsafe { nil } {
		src := if has_shield {
			Rect{x: 128, y: 0, w: 64, h: 64}
		} else if has_thrust {
			Rect{x: 64, y: 0, w: 64, h: 64}
		} else {
			Rect{x: 0, y: 0, w: 64, h: 64}
		}
		w := 24 * scale
		h := 24 * scale
		dst := Rect{x: int(cx) - w / 2, y: int(cy) - h / 2, w: w, h: h}
		deg := (angle + math.pi / 2.0) * (180.0 / math.pi)
		center := Point{x: w / 2, y: h / 2}
		render_copy_ex(renderer, tex, &src, &dst, deg, &center, RendererFlip.none)
		return
	}

	cos_a := math.cos(angle + math.pi / 2.0)
	sin_a := math.sin(angle + math.pi / 2.0)

	// Draw Ship Body Pixels
	for row in 0 .. 16 {
		for col in 0 .. 16 {
			val := ship_sprite[row][col]
			if val == 0 {
				continue
			}

			col_val := match val {
				1 { Color{ r: 240, g: 245, b: 255 } }
				2 { Color{ r: 120, g: 140, b: 175 } }
				3 { Color{ r: 0, g: 220, b: 255 } }
				4 { accent_col }
				5 { Color{ r: 60, g: 70, b: 90 } }
				else { Color{ r: 255, g: 255, b: 255 } }
			}

			// Local coordinate relative to sprite center
			lx := (f64(col) - 7.5) * f64(scale)
			ly := (f64(row) - 7.5) * f64(scale)

			// Rotated world coordinate
			rx := cx + (lx * cos_a - ly * sin_a)
			ry := cy + (lx * sin_a + ly * cos_a)

			draw_sprite_pixel(renderer, int(rx), int(ry), scale, col_val)
		}
	}

	// Draw Thruster Flame Sprite if thrusting
	if has_thrust {
		flame_len := 4 + rand.int_in_range(0, 4) or { 2 }
		for i in 0 .. flame_len {
			lx := (f64(rand.int_in_range(-2, 3) or { 0 })) * f64(scale)
			ly := (8.0 + f64(i * 2)) * f64(scale)
			rx := cx + (lx * cos_a - ly * sin_a)
			ry := cy + (lx * sin_a + ly * cos_a)
			flame_col := if i < 2 {
				Color{ r: 255, g: 255, b: 180 }
			} else if i < 4 {
				Color{ r: 255, g: 160, b: 20 }
			} else {
				Color{ r: 255, g: 50, b: 10 }
			}
			draw_sprite_pixel(renderer, int(rx), int(ry), scale, flame_col)
		}
	}
}

fn draw_ufo_sprite(renderer &Renderer, cx f64, cy f64, is_hunter bool, tex &Texture) {
	if tex != unsafe { nil } {
		src := if is_hunter { Rect{x: 192, y: 128, w: 32, h: 32} } else { Rect{x: 128, y: 128, w: 48, h: 32} }
		w := if is_hunter { 32 } else { 48 }
		h := if is_hunter { 24 } else { 32 }
		dst := Rect{x: int(cx) - w / 2, y: int(cy) - h / 2, w: w, h: h}
		render_copy(renderer, tex, &src, &dst)
		return
	}

	scale := 2
	for row in 0 .. 10 {
		for col in 0 .. 16 {
			val := ufo_sprite[row][col]
			if val == 0 {
				continue
			}

			col_val := match val {
				1 { if is_hunter { Color{ r: 255, g: 100, b: 100 } } else { Color{ r: 255, g: 220, b: 50 } } }
				2 { if is_hunter { Color{ r: 180, g: 30, b: 30 } } else { Color{ r: 190, g: 140, b: 20 } } }
				3 { Color{ r: 100, g: 230, b: 255 } }
				4 { Color{ r: 220, g: 255, b: 255 } }
				5 { if is_hunter { Color{ r: 255, g: 255, b: 100 } } else { Color{ r: 0, g: 255, b: 180 } } }
				else { Color{ r: 255, g: 255, b: 255 } }
			}

			px := int(cx) - 8 * scale + col * scale
			py := int(cy) - 5 * scale + row * scale
			draw_sprite_pixel(renderer, px, py, scale, col_val)
		}
	}
}

fn draw_asteroid_sprite(renderer &Renderer, cx f64, cy f64, rot f64, size AsteroidSize, tex &Texture) {
	if tex != unsafe { nil } {
		src := match size {
			.large { Rect{x: 0, y: 64, w: 64, h: 64} }
			.medium { Rect{x: 0, y: 128, w: 48, h: 48} }
			.small { Rect{x: 64, y: 128, w: 32, h: 32} }
		}
		w, h := match size {
			.large { 56, 56 }
			.medium { 38, 38 }
			.small { 24, 24 }
		}
		dst := Rect{x: int(cx) - w / 2, y: int(cy) - h / 2, w: w, h: h}
		deg := rot * (180.0 / math.pi)
		center := Point{x: w / 2, y: h / 2}
		render_copy_ex(renderer, tex, &src, &dst, deg, &center, RendererFlip.none)
		return
	}

	scale := match size {
		.large { 3 }
		.medium { 2 }
		.small { 1 }
	}

	cos_a := math.cos(rot)
	sin_a := math.sin(rot)

	for row in 0 .. 16 {
		for col in 0 .. 16 {
			val := asteroid_sprite[row][col]
			if val == 0 {
				continue
			}

			col_val := match val {
				1 { Color{ r: 200, g: 220, b: 245 } }
				2 { Color{ r: 140, g: 160, b: 185 } }
				3 { Color{ r: 85, g: 100, b: 125 } }
				4 { Color{ r: 50, g: 60, b: 80 } }
				else { Color{ r: 150, g: 170, b: 190 } }
			}

			lx := (f64(col) - 7.5) * f64(scale)
			ly := (f64(row) - 7.5) * f64(scale)

			rx := cx + (lx * cos_a - ly * sin_a)
			ry := cy + (lx * sin_a + ly * cos_a)

			draw_sprite_pixel(renderer, int(rx), int(ry), scale, col_val)
		}
	}
}

fn draw_powerup_sprite(renderer &Renderer, cx f64, cy f64, kind PowerUpType, timer f64, tex &Texture) {
	if tex != unsafe { nil } {
		idx := match kind {
			.shield { 0 }
			.spread_shot { 1 }
			.rapid_fire { 2 }
			.emp_nuke { 3 }
			.plasma_beam { 4 }
			.extra_life { 5 }
		}
		src := Rect{x: idx * 40, y: 192, w: 40, h: 40}
		dst := Rect{x: int(cx) - 16, y: int(cy) - 16, w: 32, h: 32}
		render_copy(renderer, tex, &src, &dst)
		return
	}

	base_color := match kind {
		.spread_shot { Color{ r: 255, g: 180, b: 0 } }
		.shield { Color{ r: 0, g: 200, b: 255 } }
		.rapid_fire { Color{ r: 255, g: 50, b: 100 } }
		.emp_nuke { Color{ r: 220, g: 100, b: 255 } }
		.plasma_beam { Color{ r: 0, g: 255, b: 150 } }
		.extra_life { Color{ r: 50, g: 255, b: 50 } }
	}

	// Draw outer pulsing glowing diamond sprite
	pulse := int(math.sin(timer * 8.0) * 2.0)
	sz := 10 + pulse
	rect := Rect{ x: int(cx) - sz / 2, y: int(cy) - sz / 2, w: sz, h: sz }
	set_render_draw_color(renderer, base_color.r, base_color.g, base_color.b, 200)
	render_fill_rect(renderer, &rect)

	inner := Rect{ x: int(cx) - sz / 4, y: int(cy) - sz / 4, w: sz / 2, h: sz / 2 }
	set_render_draw_color(renderer, 255, 255, 255, 255)
	render_fill_rect(renderer, &inner)

	label := match kind {
		.spread_shot { '3X' }
		.shield { 'SH' }
		.rapid_fire { 'RF' }
		.emp_nuke { 'EMP' }
		.plasma_beam { 'PB' }
		.extra_life { '+1' }
	}
	draw_text_centered(renderer, int(cx), int(cy) - 4, label, 1, Color{ r: 20, g: 20, b: 30 })
}

fn draw_bullet_sprite(renderer &Renderer, b &Bullet) {
	if b.is_plasma {
		// Glowing green plasma orb sprite
		rect := Rect{ x: int(b.x) - 4, y: int(b.y) - 4, w: 8, h: 8 }
		set_render_draw_color(renderer, 0, 255, 160, 255)
		render_fill_rect(renderer, &rect)
		core := Rect{ x: int(b.x) - 2, y: int(b.y) - 2, w: 4, h: 4 }
		set_render_draw_color(renderer, 220, 255, 240, 255)
		render_fill_rect(renderer, &core)
	} else if b.is_ufo {
		// Red enemy plasma sprite
		rect := Rect{ x: int(b.x) - 3, y: int(b.y) - 3, w: 6, h: 6 }
		set_render_draw_color(renderer, 255, 60, 60, 255)
		render_fill_rect(renderer, &rect)
		core := Rect{ x: int(b.x) - 1, y: int(b.y) - 1, w: 2, h: 2 }
		set_render_draw_color(renderer, 255, 220, 220, 255)
		render_fill_rect(renderer, &core)
	} else {
		// Cyan laser bolt sprite
		rect := Rect{ x: int(b.x) - 2, y: int(b.y) - 2, w: 4, h: 4 }
		set_render_draw_color(renderer, 0, 240, 255, 255)
		render_fill_rect(renderer, &rect)
	}
}

fn render_asteroids_game(renderer &Renderer, game &AsteroidsGame, particles []Particle, tex &Texture) {
	shake_mag := game.shake_trauma * game.shake_trauma * 16.0
	sx := if shake_mag > 0.01 { f32((rand.f64() * 2.0 - 1.0) * shake_mag) } else { f32(0.0) }
	sy := if shake_mag > 0.01 { f32((rand.f64() * 2.0 - 1.0) * shake_mag) } else { f32(0.0) }
	unsafe {
		mut ren := &Renderer(renderer)
		ren.offset_x += sx
		ren.offset_y += sy
	}
	defer {
		unsafe {
			mut ren := &Renderer(renderer)
			ren.offset_x -= sx
			ren.offset_y -= sy
		}
	}

	// Clear background (Deep Space)
	set_render_draw_color(renderer, 10, 12, 22, 255)
	render_clear(renderer)

	// Stars background grid with subtle twinkle spanning widescreen
	min_x, min_y, max_x, max_y := renderer.visible_bounds()
	w_span := int(math.max(f32(world_w), max_x - min_x))
	h_span := int(math.max(f32(world_h), max_y - min_y))
	for i in 0 .. 80 {
		sx := int(min_x) + (i * 137 + 50) % w_span
		sy := int(min_y) + (i * 263 + 30) % h_span
		set_render_draw_color(renderer, 100, 130, 180, 200)
		render_draw_point(renderer, sx, sy)
	}

	// Render Power-ups with glowing sprite badges
	for p in game.powerups {
		draw_powerup_sprite(renderer, p.x, p.y, p.kind, p.timer, tex)
	}

	// Render Asteroid Sprites with rotation
	for ast in game.asteroids {
		draw_asteroid_sprite(renderer, ast.x, ast.y, ast.rot, ast.size, tex)
	}

	// Render UFO Sprites
	for ufo in game.ufos {
		draw_ufo_sprite(renderer, ufo.x, ufo.y, ufo.is_hunter, tex)
	}

	// Render Bullet Sprites
	for b in game.bullets {
		draw_bullet_sprite(renderer, b)
	}

	// Render Particle Sprites
	for part in particles {
		alpha := u8(255.0 * (part.life / part.max_life))
		color := Color{
			r: part.color.r
			g: part.color.g
			b: part.color.b
			a: alpha
		}
		set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
		render_draw_point(renderer, int(part.x), int(part.y))
	}

	// Render Ship Sprite
	if !game.game_over && (game.ship.invuln_timer <= 0.0 || int(game.ship.invuln_timer * 10.0) % 2 == 0) {
		accent_col := if game.ship.has_powerup {
			match game.ship.active_powerup {
				.spread_shot { Color{ r: 255, g: 200, b: 0 } }
				.rapid_fire { Color{ r: 255, g: 80, b: 120 } }
				.plasma_beam { Color{ r: 0, g: 255, b: 180 } }
				else { Color{ r: 0, g: 255, b: 255 } }
			}
		} else {
			Color{ r: 0, g: 255, b: 255 }
		}

		draw_rotated_ship_sprite(renderer, game.ship.x, game.ship.y, game.ship.angle, 2, accent_col, game.ship.thrusting, game.ship.shield_active, tex)

		// Shield forcefield sprite ring
		if game.ship.shield_active {
			shield_rect := Rect{
				x: int(game.ship.x) - 22
				y: int(game.ship.y) - 22
				w: 44
				h: 44
			}
			set_render_draw_color(renderer, 0, 200, 255, 140)
			render_draw_rect(renderer, &shield_rect)
		}
	}

	// HUD overlay
	draw_text(renderer, 20, 20, 'SCORE: ${game.score}', 2, Color{ r: 255, g: 255, b: 255 })
	draw_text(renderer, 20, 45, 'WAVE:  ${game.wave}', 2, Color{ r: 0, g: 220, b: 255 })

	// Lives as small pixel ship sprites
	for i in 0 .. game.lives {
		lx := 700.0 + f64(i * 20)
		ly := 30.0
		draw_rotated_ship_sprite(renderer, lx, ly, -math.pi / 2.0, 1, Color{ r: 0, g: 255, b: 255 }, false, false, tex)
	}

	// Active Power-up indicator
	if game.ship.has_powerup {
		name := match game.ship.active_powerup {
			.spread_shot { 'TRIPLE SPREAD' }
			.rapid_fire { 'RAPID FIRE' }
			.plasma_beam { 'PLASMA BEAM' }
			else { '' }
		}
		rem := int(game.ship.powerup_timer) + 1
		draw_text_centered(renderer, world_w / 2, 20, '${name} [${rem}s]', 2, Color{
			r: 255
			g: 220
			b: 0
		})
	}

	// Game Over screen
	if game.game_over {
		draw_text_centered(renderer, world_w / 2, 220, 'GAME OVER', 4, Color{
			r: 255
			g: 50
			b: 50
		})
		draw_text_centered(renderer, world_w / 2, 280, 'FINAL SCORE: ${game.score}', 2,
			Color{ r: 255, g: 255, b: 255 })
		draw_text_centered(renderer, world_w / 2, 320, 'PRESS [R] TO RESTART  [F11] Fullscreen', 2, Color{
			r: 0,
			g: 255,
			b: 200
		})
	}
}
