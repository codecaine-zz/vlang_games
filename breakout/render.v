
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
}

pub struct BreakoutTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm BreakoutTextureManager) init(renderer &Renderer) {
	
	candidates := [
		'assets/sprites/breakout.png',
		'./assets/sprites/breakout.png',
		'../assets/sprites/breakout.png',
		'breakout/assets/sprites/breakout.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } {
				println('Breakout Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

pub struct Button {
pub mut:
	x            int
	y            int
	w            int
	h            int
	bg_color     Color
	hover_color  Color
	text_color   Color
	border_color Color
	text         string
}

fn (b Button) contains(x int, y int) bool {
	return x >= b.x && x <= b.x + b.w && y >= b.y && y <= b.y + b.h
}

fn (b Button) render(renderer &Renderer, mouse_x int, mouse_y int) {
	is_hover := b.contains(mouse_x, mouse_y)
	color := if is_hover { b.hover_color } else { b.bg_color }

	mut b_rect := Rect{
		x: b.x
		y: b.y
		w: b.w
		h: b.h
	}
	set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	render_fill_rect(renderer, &b_rect)

	set_render_draw_color(renderer, b.border_color.r, b.border_color.g, b.border_color.b, b.border_color.a)
	render_draw_rect(renderer, &b_rect)

	text_x := b.x + (b.w - b.text.len * 8 * 2) / 2
	text_y := b.y + (b.h - 16) / 2
	draw_text(renderer, text_x, text_y, b.text, 2, b.text_color)
}

fn draw_jewel_brick_sprite(renderer &Renderer, bx int, by int, bw int, bh int, kind BrickType, base_col Color, hp int, tex &Texture) {
	mut b_rect := Rect{ x: bx, y: by, w: bw, h: bh }

	if tex != unsafe { nil } {
		mut col_x := 192
		if kind == .steel {
			col_x = 128
		} else if kind == .armored {
			col_x = 64
		} else if kind == .tnt {
			col_x = 192
		} else {
			if base_col.r > 200 && base_col.g < 100 {
				col_x = 0
			} else if base_col.b > 200 {
				col_x = 64
			} else if base_col.g > 200 && base_col.r < 100 {
				col_x = 128
			}
		}
		row_y := if kind == .steel || kind == .armored || kind == .tnt { 128 } else { 64 }
		src := Rect{ x: col_x, y: row_y, w: 64, h: 32 }
		render_copy(renderer, tex, &src, &b_rect)
		return
	}

	if kind == .steel {
		// Metallic Gold Indestructible Steel Brick
		set_render_draw_color(renderer, 255, 200, 20, 255)
		render_fill_rect(renderer, &b_rect)

		set_render_draw_color(renderer, 255, 255, 180, 255)
		render_draw_line(renderer, bx, by, bx + bw - 1, by)
		render_draw_line(renderer, bx, by, bx, by + bh - 1)

		set_render_draw_color(renderer, 150, 100, 5, 255)
		render_draw_line(renderer, bx, by + bh - 1, bx + bw - 1, by + bh - 1)
		render_draw_line(renderer, bx + bw - 1, by, bx + bw - 1, by + bh - 1)

		set_render_draw_color(renderer, 255, 255, 220, 255)
		render_fill_rect(renderer, &Rect{ x: bx + bw / 2 - 2, y: by + bh / 2 - 2, w: 4, h: 4 })
		return
	}

	if kind == .armored {
		// Multi-Hit Armored Brick Sprite
		set_render_draw_color(renderer, 180, 195, 210, 255)
		render_fill_rect(renderer, &b_rect)

		set_render_draw_color(renderer, 240, 248, 255, 255)
		render_draw_line(renderer, bx, by, bx + bw - 1, by)
		render_draw_line(renderer, bx, by, bx, by + bh - 1)

		set_render_draw_color(renderer, 90, 105, 120, 255)
		render_draw_line(renderer, bx, by + bh - 1, bx + bw - 1, by + bh - 1)
		render_draw_line(renderer, bx + bw - 1, by, bx + bw - 1, by + bh - 1)

		if hp < 2 {
			// Surface crack sprite
			set_render_draw_color(renderer, 60, 70, 85, 255)
			render_draw_line(renderer, bx + 6, by + 3, bx + bw / 2, by + bh - 4)
			render_draw_line(renderer, bx + bw / 2, by + bh - 4, bx + bw - 8, by + 5)
		}
		return
	}

	if kind == .tnt {
		// Red Explosive TNT Crate Sprite
		set_render_draw_color(renderer, 220, 40, 40, 255)
		render_fill_rect(renderer, &b_rect)

		set_render_draw_color(renderer, 255, 120, 120, 255)
		render_draw_line(renderer, bx + 1, by + 1, bx + bw - 2, by + 1)
		render_draw_line(renderer, bx + 1, by + 1, bx + 1, by + bh - 2)

		set_render_draw_color(renderer, 120, 15, 15, 255)
		render_draw_line(renderer, bx + 1, by + bh - 1, bx + bw - 1, by + bh - 1)
		render_draw_line(renderer, bx + bw - 1, by + 1, bx + bw - 1, by + bh - 1)

		draw_text_centered(renderer, bx + bw / 2, by + 2, 'TNT', 1, Color{ r: 255, g: 255, b: 255 })
		return
	}

	// 3D Beveled Jewel Brick Sprite
	set_render_draw_color(renderer, base_col.r, base_col.g, base_col.b, 255)
	render_fill_rect(renderer, &b_rect)

	// Top & Left Gloss highlight
	lr := u8(math.min(255, int(base_col.r) + 80))
	lg := u8(math.min(255, int(base_col.g) + 80))
	lb := u8(math.min(255, int(base_col.b) + 80))
	set_render_draw_color(renderer, lr, lg, lb, 255)
	render_draw_line(renderer, bx + 1, by + 1, bx + bw - 2, by + 1)
	render_draw_line(renderer, bx + 1, by + 1, bx + 1, by + bh - 2)

	// Inner gloss pill
	pill_rect := Rect{ x: bx + 4, y: by + 3, w: bw - 8, h: bh / 2 - 2 }
	set_render_draw_color(renderer, lr, lg, lb, 120)
	render_fill_rect(renderer, &pill_rect)

	// Bottom & Right Deep shadow
	dr := u8(math.max(0, int(base_col.r) - 70))
	dg := u8(math.max(0, int(base_col.g) - 70))
	db := u8(math.max(0, int(base_col.b) - 70))
	set_render_draw_color(renderer, dr, dg, db, 255)
	render_draw_line(renderer, bx + 1, by + bh - 1, bx + bw - 1, by + bh - 1)
	render_draw_line(renderer, bx + bw - 1, by + 1, bx + bw - 1, by + bh - 1)

	// Dark Outer Border
	set_render_draw_color(renderer, 15, 18, 28, 255)
	render_draw_rect(renderer, &b_rect)
}

fn draw_sports_paddle_sprite(renderer &Renderer, px f64, py f64, pw f64, ph f64, is_laser bool, is_sticky bool, tex &Texture) {
	ix := int(px)
	iy := int(py)
	iw := int(pw)
	ih := int(ph)

	if tex != unsafe { nil } {
		col_x := if is_laser { 64 } else { 0 }
		src := Rect{ x: col_x, y: 0, w: 64, h: 20 }
		dst := Rect{ x: ix, y: iy, w: iw, h: ih }
		render_copy(renderer, tex, &src, &dst)
		return
	}

	// Base Carbon Body
	body_rect := Rect{ x: ix, y: iy, w: iw, h: ih }
	set_render_draw_color(renderer, 30, 36, 52, 255)
	render_fill_rect(renderer, &body_rect)

	// Neon Side Wing Caps
	side_col := if is_laser {
		Color{ r: 255, g: 60, b: 80 }
	} else if is_sticky {
		Color{ r: 120, g: 255, b: 60 }
	} else {
		Color{ r: 0, g: 220, b: 255 }
	}

	left_cap := Rect{ x: ix, y: iy, w: 8, h: ih }
	right_cap := Rect{ x: ix + iw - 8, y: iy, w: 8, h: ih }
	set_render_draw_color(renderer, side_col.r, side_col.g, side_col.b, 255)
	render_fill_rect(renderer, &left_cap)
	render_fill_rect(renderer, &right_cap)

	// Center Impact Energy Surface
	center_strip := Rect{ x: ix + 10, y: iy + 1, w: iw - 20, h: 3 }
	set_render_draw_color(renderer, 240, 250, 255, 255)
	render_fill_rect(renderer, &center_strip)

	// Grip Grooves
	for gx := ix + 14; gx < ix + iw - 14; gx += 8 {
		set_render_draw_color(renderer, 60, 75, 105, 255)
		render_draw_line(renderer, gx, iy + 5, gx, iy + ih - 3)
	}

	// Bevel Outline
	set_render_draw_color(renderer, side_col.r, side_col.g, side_col.b, 200)
	render_draw_rect(renderer, &body_rect)
}

fn draw_fireball_sprite(renderer &Renderer, cx f64, cy f64, r f64, is_fire bool, tex &Texture) {
	if tex != unsafe { nil } {
		col_x := if is_fire { 192 } else { 128 }
		src := Rect{ x: col_x, y: 0, w: 32, h: 32 }
		eff_r := int(r)
		dst := Rect{ x: int(cx) - eff_r, y: int(cy) - eff_r, w: eff_r * 2, h: eff_r * 2 }
		render_copy(renderer, tex, &src, &dst)
		return
	}

	ir := int(r)
	eff_r := if ir < 3 { 3 } else { ir }

	for dy in -eff_r .. eff_r + 1 {
		for dx in -eff_r .. eff_r + 1 {
			d2 := dx * dx + dy * dy
			if d2 <= eff_r * eff_r {
				col := if is_fire {
					if d2 <= (eff_r / 2) * (eff_r / 2) {
						Color{ r: 255, g: 255, b: 200 }
					} else if d2 <= (eff_r * 3 / 4) * (eff_r * 3 / 4) {
						Color{ r: 255, g: 160, b: 20 }
					} else {
						Color{ r: 235, g: 40, b: 10 }
					}
				} else {
					if d2 <= (eff_r / 2) * (eff_r / 2) {
						Color{ r: 255, g: 255, b: 255 }
					} else if d2 <= (eff_r * 3 / 4) * (eff_r * 3 / 4) {
						Color{ r: 100, g: 220, b: 255 }
					} else {
						Color{ r: 20, g: 120, b: 240 }
					}
				}
				set_render_draw_color(renderer, col.r, col.g, col.b, 255)
				render_draw_point(renderer, int(cx) + dx, int(cy) + dy)
			}
		}
	}
}

fn draw_capsule_sprite(renderer &Renderer, px f64, py f64, kind PowerUpType, tex &Texture) {
	x := int(px) - 13
	y := int(py) - 7
	w := 26
	h := 14

	if tex != unsafe { nil } {
		col_x := match kind {
			.laser_paddle { 0 }
			.expand_paddle { 64 }
			.sticky_paddle { 128 }
			.multiball { 192 }
			else { 0 }
		}
		src := Rect{ x: col_x, y: 192, w: 64, h: 64 }
		dst := Rect{ x: x - 2, y: y - 2, w: w + 4, h: h + 4 }
		render_copy(renderer, tex, &src, &dst)
		return
	}

	bg_col := match kind {
		.laser_paddle { Color{ r: 255, g: 40, b: 60 } }
		.sticky_paddle { Color{ r: 40, g: 230, b: 60 } }
		.slow_ball { Color{ r: 60, g: 150, b: 255 } }
		.expand_paddle { Color{ r: 20, g: 210, b: 235 } }
		.extra_life { Color{ r: 160, g: 60, b: 255 } }
		.multiball { Color{ r: 255, g: 220, b: 0 } }
		.fireball { Color{ r: 255, g: 90, b: 10 } }
		.bottom_shield { Color{ r: 0, g: 240, b: 180 } }
	}

	mut b_rect := Rect{ x: x, y: y, w: w, h: h }
	set_render_draw_color(renderer, bg_col.r, bg_col.g, bg_col.b, 255)
	render_fill_rect(renderer, &b_rect)

	top_h := Rect{ x: x + 2, y: y + 2, w: w - 4, h: 3 }
	set_render_draw_color(renderer, 255, 255, 255, 180)
	render_fill_rect(renderer, &top_h)

	set_render_draw_color(renderer, 255, 255, 255, 255)
	render_draw_rect(renderer, &b_rect)

	label := match kind {
		.laser_paddle { 'L' }
		.sticky_paddle { 'C' }
		.slow_ball { 'S' }
		.expand_paddle { 'E' }
		.extra_life { '+1' }
		.multiball { 'M' }
		.fireball { 'F' }
		.bottom_shield { 'B' }
	}
	draw_text_centered(renderer, int(px), y + 2, label, 1, Color{ r: 255, g: 255, b: 255 })
}

fn render_breakout_game(renderer &Renderer, game &BreakoutGame, particles []Particle, tex &Texture) {
	mut ren := unsafe { &Renderer(renderer) }
	mut sx := f32(0.0)
	mut sy := f32(0.0)
	if game.shake_trauma > 0 {
		mag := f32(game.shake_trauma * game.shake_trauma * 16.0)
		sx = (f32(rand.intn(200) or { 100 }) - 100.0) * 0.01 * mag
		sy = (f32(rand.intn(200) or { 100 }) - 100.0) * 0.01 * mag
	}
	ren.offset_x += sx
	ren.offset_y += sy
	defer {
		ren.offset_x -= sx
		ren.offset_y -= sy
	}

	// Dark grid arcade background
	set_render_draw_color(renderer, 14, 16, 28, 255)
	render_clear(renderer)

	// Top banner border line
	set_render_draw_color(renderer, 40, 55, 90, 255)
	render_draw_line(renderer, 0, 40, world_w, 40)

	// Bottom Shield line
	if game.bottom_shield_active {
		set_render_draw_color(renderer, 0, 220, 255, 255)
		render_draw_line(renderer, 0, world_h - 10, world_w, world_h - 10)
		render_draw_line(renderer, 0, world_h - 9, world_w, world_h - 9)
	}

	// Render Bricks using 3D Jewel Sprite Renderer
	for b in game.bricks {
		if !b.alive {
			continue
		}
		draw_jewel_brick_sprite(renderer, b.x, b.y, b.w, b.h, b.kind, b.color, b.hp, tex)
	}

	// Render Falling Power-Up Capsules
	for cap in game.capsules {
		draw_capsule_sprite(renderer, cap.x, cap.y, cap.kind, tex)
	}

	// Render Laser Projectiles
	for lz in game.lasers {
		set_render_draw_color(renderer, 255, 60, 80, 255)
		l_rect := Rect{ x: int(lz.x) - 2, y: int(lz.y) - 6, w: 4, h: 12 }
		render_fill_rect(renderer, &l_rect)
		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_draw_line(renderer, int(lz.x), int(lz.y) - 4, int(lz.x), int(lz.y) + 4)
	}

	// Render Sports Vaus Paddle
	draw_sports_paddle_sprite(renderer, game.paddle.x, game.paddle.y, game.paddle.w, game.paddle.h, game.paddle.has_lasers, game.paddle.has_sticky, tex)

	// Render Balls
	is_fire := game.paddle.fireball_timer > 0.0
	for b in game.balls {
		draw_fireball_sprite(renderer, b.x, b.y, b.radius, is_fire, tex)
	}

	// Render Particle Sprites
	for part in particles {
		alpha := u8(255.0 * (part.life / part.max_life))
		set_render_draw_color(renderer, part.color.r, part.color.g, part.color.b, alpha)
		render_draw_point(renderer, int(part.x), int(part.y))
	}

	// HUD overlay
	draw_text(renderer, 20, 12, 'SCORE: ${game.score}', 2, Color{ r: 255, g: 255, b: 255 })
	draw_text(renderer, 300, 12, 'LEVEL: ${game.level}', 2, Color{ r: 0, g: 220, b: 255 })

	// Lives as mini paddle icons
	for i in 0 .. game.lives {
		lx := 660.0 + f64(i * 24)
		ly := 18.0
		draw_sports_paddle_sprite(renderer, lx, ly, 18.0, 6.0, false, false, tex)
	}

	// Game Over / Victory screen
	if game.game_over {
		draw_text_centered(renderer, world_w / 2, 260, 'GAME OVER', 4, Color{ r: 255, g: 50, b: 50 })
		draw_text_centered(renderer, world_w / 2, 320, 'FINAL SCORE: ${game.score}', 2, Color{ r: 255, g: 255, b: 255 })
		draw_text_centered(renderer, world_w / 2, 360, 'PRESS [R] TO RESTART', 2, Color{ r: 0, g: 255, b: 200 })
	} else if game.level_cleared {
		draw_text_centered(renderer, world_w / 2, 260, 'LEVEL CLEARED!', 4, Color{ r: 80, g: 240, b: 120 })
		draw_text_centered(renderer, world_w / 2, 320, 'FINAL SCORE: ${game.score}', 2, Color{ r: 255, g: 255, b: 255 })
		draw_text_centered(renderer, world_w / 2, 360, 'PRESS [SPACE] FOR NEXT LEVEL', 2, Color{ r: 0, g: 255, b: 200 })
	}
}
