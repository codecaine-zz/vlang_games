module main

import math
import os



pub struct FlappyTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn new_flappy_texture_manager() FlappyTextureManager {
	return FlappyTextureManager{}
}

pub fn (mut tm FlappyTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/flappy.png',
		'./assets/sprites/flappy.png',
		'../assets/sprites/flappy.png',
		'flappy/assets/sprites/flappy.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('flappy Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

// 16x16 Pixel Art Flappy Bird Sprites (0 = trans, 1 = outline, 2 = yellow body, 3 = orange belly, 4 = beak, 5 = eye white, 6 = pupil, 7 = wing white)
const bird_f0 = [
	[0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0],
	[0,0,0,1,1,2,2,2,2,2,1,0,0,0,0,0],
	[0,0,1,2,2,2,2,5,5,5,1,1,0,0,0,0],
	[0,1,2,2,2,2,5,5,6,6,5,1,0,0,0,0],
	[0,1,2,2,2,2,5,5,6,6,5,1,4,4,4,0],
	[1,2,2,7,7,2,2,5,5,5,1,4,4,4,4,1],
	[1,2,7,7,7,7,2,2,2,1,4,4,4,4,4,1],
	[1,2,7,7,7,7,3,3,3,1,1,4,4,4,1,0],
	[1,2,2,7,7,3,3,3,3,3,3,1,1,1,0,0],
	[0,1,2,2,3,3,3,3,3,3,1,0,0,0,0,0],
	[0,0,1,1,3,3,3,3,3,1,0,0,0,0,0,0],
	[0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
]

// Wing Up Frame
const bird_f1 = [
	[0,0,0,0,7,7,7,1,1,1,0,0,0,0,0,0],
	[0,0,0,7,7,7,7,2,2,2,1,0,0,0,0,0],
	[0,0,1,7,7,2,2,5,5,5,1,1,0,0,0,0],
	[0,1,2,2,2,2,5,5,6,6,5,1,0,0,0,0],
	[0,1,2,2,2,2,5,5,6,6,5,1,4,4,4,0],
	[1,2,2,2,2,2,2,5,5,5,1,4,4,4,4,1],
	[1,2,2,2,2,2,2,2,2,1,4,4,4,4,4,1],
	[1,2,2,2,3,3,3,3,3,1,1,4,4,4,1,0],
	[1,2,3,3,3,3,3,3,3,3,3,1,1,1,0,0],
	[0,1,3,3,3,3,3,3,3,3,1,0,0,0,0,0],
	[0,0,1,1,3,3,3,3,3,1,0,0,0,0,0,0],
	[0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
]

// Wing Down Frame
const bird_f2 = [
	[0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0],
	[0,0,0,1,1,2,2,2,2,2,1,0,0,0,0,0],
	[0,0,1,2,2,2,2,5,5,5,1,1,0,0,0,0],
	[0,1,2,2,2,2,5,5,6,6,5,1,0,0,0,0],
	[0,1,2,2,2,2,5,5,6,6,5,1,4,4,4,0],
	[1,2,2,2,2,2,2,5,5,5,1,4,4,4,4,1],
	[1,2,2,2,2,2,2,2,2,1,4,4,4,4,4,1],
	[1,7,7,2,3,3,3,3,3,1,1,4,4,4,1,0],
	[1,7,7,7,7,3,3,3,3,3,3,1,1,1,0,0],
	[0,1,7,7,7,7,3,3,3,3,1,0,0,0,0,0],
	[0,0,1,1,1,1,3,3,3,1,0,0,0,0,0,0],
	[0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
]

pub fn draw_flappy_bird(renderer &Renderer, cx f64, cy f64, angle f64, wing_frame int, tex &Texture) {
	if tex != unsafe { nil } {
		frame := (wing_frame % 3)
		src := Rect{ x: frame * 32, y: 0, w: 32, h: 32 }
		dst := Rect{ x: int(cx - 24), y: int(cy - 24), w: 48, h: 48 }
		deg := angle * 180.0 / math.pi
		render_copy_ex(renderer, tex, &src, &dst, deg, unsafe { nil }, .none)
		return
	}

	matrix := match wing_frame {
		0 { bird_f0 }
		1 { bird_f1 }
		else { bird_f2 }
	}

	scale := 2.2
	cos_a := math.cos(angle)
	sin_a := math.sin(angle)

	for r in 0 .. 16 {
		for c in 0 .. 16 {
			val := matrix[r][c]
			if val == 0 {
				continue
			}

			col := match val {
				1 { Color{ r: 40, g: 30, b: 15 } }
				2 { Color{ r: 250, g: 210, b: 40 } }
				3 { Color{ r: 240, g: 130, b: 25 } }
				4 { Color{ r: 255, g: 75, b: 20 } }
				5 { Color{ r: 255, g: 255, b: 255 } }
				6 { Color{ r: 15, g: 15, b: 20 } }
				7 { Color{ r: 255, g: 255, b: 240 } }
				else { Color{ r: 250, g: 210, b: 40 } }
			}

			lx := (f64(c) - 7.5) * scale
			ly := (f64(r) - 5.5) * scale

			rx := cx + (lx * cos_a - ly * sin_a)
			ry := cy + (lx * sin_a + ly * cos_a)

			set_render_draw_color(renderer, col.r, col.g, col.b, 255)
			rect := Rect{ x: int(rx), y: int(ry), w: int(scale) + 1, h: int(scale) + 1 }
			render_fill_rect(renderer, &rect)
		}
	}
}

pub fn draw_retro_pipe(renderer &Renderer, px f64, top_h f64, gap f64, win_h int) {
	ix := int(px)
	iw := int(pipe_width)
	rim_h := 26
	rim_out := 4
	gh := int(ground_height)

	body_col := Color{ r: 110, g: 195, b: 45 }
	light_col := Color{ r: 185, g: 240, b: 90 }
	shadow_col := Color{ r: 60, g: 120, b: 25 }
	dark_border := Color{ r: 25, g: 55, b: 15 }

	// 1. Top Pipe Shaft
	top_shaft_h := int(top_h) - rim_h
	if top_shaft_h > 0 {
		shaft_rect := Rect{ x: ix, y: 0, w: iw, h: top_shaft_h }
		set_render_draw_color(renderer, body_col.r, body_col.g, body_col.b, 255)
		render_fill_rect(renderer, &shaft_rect)

		set_render_draw_color(renderer, light_col.r, light_col.g, light_col.b, 255)
		render_fill_rect(renderer, &Rect{ x: ix + 4, y: 0, w: 8, h: top_shaft_h })
		set_render_draw_color(renderer, shadow_col.r, shadow_col.g, shadow_col.b, 255)
		render_fill_rect(renderer, &Rect{ x: ix + iw - 10, y: 0, w: 8, h: top_shaft_h })

		set_render_draw_color(renderer, dark_border.r, dark_border.g, dark_border.b, 255)
		render_draw_rect(renderer, &shaft_rect)
	}

	// 2. Top Pipe Collar Cap
	top_collar := Rect{ x: ix - rim_out, y: int(top_h) - rim_h, w: iw + rim_out * 2, h: rim_h }
	set_render_draw_color(renderer, body_col.r, body_col.g, body_col.b, 255)
	render_fill_rect(renderer, &top_collar)
	set_render_draw_color(renderer, light_col.r, light_col.g, light_col.b, 255)
	render_fill_rect(renderer, &Rect{ x: ix - rim_out + 4, y: int(top_h) - rim_h + 2, w: 10, h: rim_h - 4 })
	set_render_draw_color(renderer, shadow_col.r, shadow_col.g, shadow_col.b, 255)
	render_fill_rect(renderer, &Rect{ x: ix + iw + rim_out - 12, y: int(top_h) - rim_h + 2, w: 10, h: rim_h - 4 })
	set_render_draw_color(renderer, dark_border.r, dark_border.g, dark_border.b, 255)
	render_draw_rect(renderer, &top_collar)

	// 3. Bottom Pipe Collar Cap
	bot_y := int(top_h + gap)
	bot_collar := Rect{ x: ix - rim_out, y: bot_y, w: iw + rim_out * 2, h: rim_h }
	set_render_draw_color(renderer, body_col.r, body_col.g, body_col.b, 255)
	render_fill_rect(renderer, &bot_collar)
	set_render_draw_color(renderer, light_col.r, light_col.g, light_col.b, 255)
	render_fill_rect(renderer, &Rect{ x: ix - rim_out + 4, y: bot_y + 2, w: 10, h: rim_h - 4 })
	set_render_draw_color(renderer, shadow_col.r, shadow_col.g, shadow_col.b, 255)
	render_fill_rect(renderer, &Rect{ x: ix + iw + rim_out - 12, y: bot_y + 2, w: 10, h: rim_h - 4 })
	set_render_draw_color(renderer, dark_border.r, dark_border.g, dark_border.b, 255)
	render_draw_rect(renderer, &bot_collar)

	// 4. Bottom Pipe Shaft
	bot_shaft_y := bot_y + rim_h
	bot_shaft_h := win_h - gh - bot_shaft_y
	if bot_shaft_h > 0 {
		bshaft_rect := Rect{ x: ix, y: bot_shaft_y, w: iw, h: bot_shaft_h }
		set_render_draw_color(renderer, body_col.r, body_col.g, body_col.b, 255)
		render_fill_rect(renderer, &bshaft_rect)
		set_render_draw_color(renderer, light_col.r, light_col.g, light_col.b, 255)
		render_fill_rect(renderer, &Rect{ x: ix + 4, y: bot_shaft_y, w: 8, h: bot_shaft_h })
		set_render_draw_color(renderer, shadow_col.r, shadow_col.g, shadow_col.b, 255)
		render_fill_rect(renderer, &Rect{ x: ix + iw - 10, y: bot_shaft_y, w: 8, h: bot_shaft_h })
		set_render_draw_color(renderer, dark_border.r, dark_border.g, dark_border.b, 255)
		render_draw_rect(renderer, &bshaft_rect)
	}
}

pub fn draw_pixel_cloud(renderer &Renderer, x int, y int, scale int) {
	set_render_draw_color(renderer, 245, 250, 255, 220)
	c_base := Rect{ x: x, y: y + 8 * scale, w: 32 * scale, h: 10 * scale }
	render_fill_rect(renderer, &c_base)
	c_top1 := Rect{ x: x + 6 * scale, y: y + 2 * scale, w: 12 * scale, h: 8 * scale }
	render_fill_rect(renderer, &c_top1)
	c_top2 := Rect{ x: x + 16 * scale, y: y + 4 * scale, w: 10 * scale, h: 6 * scale }
	render_fill_rect(renderer, &c_top2)
}

pub fn draw_flappy_background(renderer &Renderer, scroll_x f64, win_w int, win_h int) {
	gh := int(ground_height)
	sky_h := win_h - gh

	// Sky Gradient
	for y := 0; y < sky_h; y += 4 {
		pct := f64(y) / f64(sky_h)
		r := u8(80.0 + pct * 60.0)
		g := u8(170.0 + pct * 55.0)
		b := u8(230.0 + pct * 25.0)
		set_render_draw_color(renderer, r, g, b, 255)
		rect := Rect{ x: 0, y: y, w: win_w, h: 4 }
		render_fill_rect(renderer, &rect)
	}

	// Parallax Pixel Clouds
	cloud_offset := int(scroll_x * 0.3) % 400
	draw_pixel_cloud(renderer, 60 - cloud_offset, 60, 2)
	draw_pixel_cloud(renderer, 300 - cloud_offset, 90, 1)
	draw_pixel_cloud(renderer, 460 - cloud_offset, 50, 2)
	draw_pixel_cloud(renderer, 700 - cloud_offset, 80, 2)

	// Ground
	gy := win_h - gh
	ground_rect := Rect{ x: 0, y: gy, w: win_w, h: gh }
	set_render_draw_color(renderer, 220, 175, 100, 255)
	render_fill_rect(renderer, &ground_rect)

	// Grass Ribbon on Ground
	grass_rect := Rect{ x: 0, y: gy, w: win_w, h: 14 }
	set_render_draw_color(renderer, 115, 200, 50, 255)
	render_fill_rect(renderer, &grass_rect)
	set_render_draw_color(renderer, 175, 240, 90, 255)
	render_draw_line(renderer, 0, gy, win_w, gy)

	// Scrolling Ground Pattern
	g_offset := int(scroll_x) % 24
	set_render_draw_color(renderer, 190, 145, 75, 255)
	for x := -g_offset; x < win_w; x += 24 {
		render_draw_line(renderer, x, gy + 14, x + 10, gy + gh)
	}
}

pub fn draw_flappy_hud(renderer &Renderer, score int, high_score int, state GameState, win_w int, win_h int) {
	if state == .playing {
		score_str := '${score}'
		draw_text_centered(renderer, win_w / 2, 40, score_str, 4, Color{ r: 255, g: 255, b: 255 })
	} else if state == .ready {
		draw_text_centered(renderer, win_w / 2, 160, 'FLAPPY BIRD', 4, Color{ r: 255, g: 220, b: 0 })
		draw_text_centered(renderer, win_w / 2, 230, 'SPRITE EDITION', 2, Color{ r: 80, g: 240, b: 120 })
		draw_text_centered(renderer, win_w / 2, 320, 'PRESS SPACE / CLICK TO FLAP', 2, Color{ r: 255, g: 255, b: 255 })
		draw_text_centered(renderer, win_w / 2, 380, 'BEST: ${high_score}', 2, Color{ r: 255, g: 215, b: 0 })
	} else if state == .game_over || state == .dead {
		draw_text_centered(renderer, win_w / 2, 160, 'GAME OVER', 4, Color{ r: 255, g: 60, b: 60 })
		draw_text_centered(renderer, win_w / 2, 230, 'SCORE: ${score}   BEST: ${high_score}', 2, Color{ r: 255, g: 255, b: 255 })
		draw_text_centered(renderer, win_w / 2, 310, 'PRESS SPACE OR [R] TO RETRY', 2, Color{ r: 80, g: 240, b: 120 })
	}
}

pub fn render_flappy_game(renderer &Renderer, game &FlappyGame, win_w int, win_h int, tex &Texture) {
	draw_flappy_background(renderer, game.scroll_x, win_w, win_h)

	for p in game.pipes {
		draw_retro_pipe(renderer, p.x, p.top_h, pipe_gap, win_h)
	}

	draw_flappy_bird(renderer, game.bird.x, game.bird.y, game.bird.angle, game.bird.wing_frame, tex)

	draw_flappy_hud(renderer, game.score, game.best_score, game.state, win_w, win_h)
}
