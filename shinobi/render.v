module main

import math
import os
import rand

pub struct ShinobiTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm ShinobiTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/shinobi.png',
		'./assets/sprites/shinobi.png',
		'../assets/sprites/shinobi.png',
		'shinobi/assets/sprites/shinobi.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('shinobi Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

fn render_shinobi_game(renderer &Renderer, mut g ShinobiGame, tex &Texture) {
	shake_mag := g.shake_trauma * g.shake_trauma * 16.0
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

	// Cyberpunk Dark Purple/Blue Night Background
	set_render_draw_color(renderer, 15, 10, 25, 255)
	render_clear(renderer)

	// Neon City Skyline Background Buildings
	for i in 0 .. 8 {
		set_render_draw_color(renderer, 25, 20, 45, 255)
		b_x := i * 110 + 10
		b_w := 90
		b_h := 220 + (i % 3) * 60
		bld := Rect{ x: b_x, y: 600 - b_h, w: b_w, h: b_h }
		render_fill_rect(renderer, &bld)

		// Neon Windows
		set_render_draw_color(renderer, 0, 200, 255, 100)
		win := Rect{ x: b_x + 15, y: 600 - b_h + 30, w: 20, h: 40 }
		render_fill_rect(renderer, &win)
	}

	// 1. Draw Rooftop Platforms
	for p in g.platforms {
		px := int(p.x)
		py := int(p.y)
		pw := int(p.width)

		// Rooftop Block
		set_render_draw_color(renderer, 40, 45, 60, 255)
		roof := Rect{ x: px, y: py, w: pw, h: 200 }
		render_fill_rect(renderer, &roof)

		// Glowing Neon Cyan Roof Ledge Line
		set_render_draw_color(renderer, 0, 255, 220, 255)
		top_line := Rect{ x: px, y: py, w: pw, h: 4 }
		render_fill_rect(renderer, &top_line)
	}

	// 2. Draw Shurikens (Spinning Cyan Star)
	for s in g.shurikens {
		if !s.active { continue }
		shur_x := int(s.x)
		shur_y := int(s.y)

		if tex != unsafe { nil } {
			rot_idx := (int(s.x / 12.0)) % 4
			src := Rect{ x: rot_idx * 32, y: 128, w: 32, h: 32 }
			dst := Rect{ x: shur_x - 10, y: shur_y - 10, w: 20, h: 20 }
			render_copy(renderer, tex, &src, &dst)
		} else {
			set_render_draw_color(renderer, 0, 255, 255, 255)
			s1 := Rect{ x: shur_x - 6, y: shur_y - 2, w: 12, h: 4 }
			s2 := Rect{ x: shur_x - 2, y: shur_y - 6, w: 4, h: 12 }
			render_fill_rect(renderer, &s1)
			render_fill_rect(renderer, &s2)
		}
	}

	// 3. Draw Drone Lasers
	for l in g.lasers {
		if !l.active { continue }
		lx := int(l.x)
		ly := int(l.y)
		set_render_draw_color(renderer, 255, 40, 40, 255)
		bolt := Rect{ x: lx - 8, y: ly - 2, w: 16, h: 4 }
		render_fill_rect(renderer, &bolt)
	}

	// 4. Draw Drone Enemies
	for d in g.drones {
		if !d.active { continue }
		dx := int(d.x)
		dy := int(d.y)

		if tex != unsafe { nil } {
			src := Rect{ x: 96, y: 64, w: 48, h: 48 }
			dst := Rect{ x: dx - 20, y: dy - 20, w: 40, h: 40 }
			render_copy(renderer, tex, &src, &dst)
		} else {
			set_render_draw_color(renderer, 140, 35, 195, 255)
			body := Rect{ x: dx - 14, y: dy - 8, w: 28, h: 16 }
			render_fill_rect(renderer, &body)

			set_render_draw_color(renderer, 100, 180, 255, 255)
			render_draw_line(renderer, dx - 18, dy - 10, dx - 6, dy - 10)
			render_draw_line(renderer, dx + 6, dy - 10, dx + 18, dy - 10)

			set_render_draw_color(renderer, 255, 0, 80, 255)
			eye := Rect{ x: dx - 8, y: dy - 4, w: 16, h: 8 }
			render_fill_rect(renderer, &eye)
			set_render_draw_color(renderer, 255, 255, 255, 200)
			render_draw_point(renderer, dx - 4, dy - 2)
		}
	}

	// 5. Ninja Player Sprite
	if g.state == .playing || g.state == .paused {
		nx := int(g.player_x)
		ny := int(g.player_y)

		if tex != unsafe { nil } {
			mut pose := 0
			if g.is_slashing {
				pose = 4
			} else if !g.is_grounded {
				pose = 3
			} else if g.player_vx != 0.0 {
				pose = 1 + (int(math.abs(g.player_x / 18.0))) % 2
			}

			src := Rect{ x: pose * 48, y: 0, w: 48, h: 64 }
			dst := Rect{ x: nx - 24, y: ny - 48, w: 48, h: 48 }
			render_copy(renderer, tex, &src, &dst)
		} else {
			set_render_draw_color(renderer, 25, 25, 35, 255)
			suit := Rect{ x: nx - 10, y: ny - 24, w: 20, h: 24 }
			render_fill_rect(renderer, &suit)

			set_render_draw_color(renderer, 160, 175, 195, 255)
			render_fill_rect(renderer, &Rect{ x: nx - 12, y: ny - 22, w: 4, h: 6 })
			render_fill_rect(renderer, &Rect{ x: nx + 8, y: ny - 22, w: 4, h: 6 })

			set_render_draw_color(renderer, 245, 25, 65, 255)
			scarf1 := Rect{ x: nx - 18, y: ny - 20, w: 10, h: 4 }
			scarf2 := Rect{ x: nx - 24, y: ny - 17, w: 8, h: 3 }
			render_fill_rect(renderer, &scarf1)
			render_fill_rect(renderer, &scarf2)

			set_render_draw_color(renderer, 0, 255, 230, 255)
			visor := Rect{ x: nx - 6, y: ny - 21, w: 12, h: 4 }
			render_fill_rect(renderer, &visor)

			if g.is_slashing {
				set_render_draw_color(renderer, 255, 255, 255, 255)
				render_draw_line(renderer, nx + 6, ny - 26, nx + 32, ny - 12)
				set_render_draw_color(renderer, 0, 230, 255, 255)
				render_draw_line(renderer, nx + 6, ny - 25, nx + 30, ny - 10)
				render_draw_line(renderer, nx + 8, ny - 28, nx + 34, ny - 14)
			}
		}
	}

	// 6. HUD
	draw_text(renderer, 20, 15, "SCORE: ${g.score}", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
	draw_text(renderer, 320, 15, "HIGH: ${g.high_score}", 2, Color{ r: 255, g: 215, b: 0, a: 255 })
	draw_text(renderer, 650, 15, "LIVES: ${g.lives}", 2, Color{ r: 255, g: 30, b: 60, a: 255 })

	// 7. Overlay Menus
	if g.state == .menu {
		draw_text_centered(renderer, 400, 180, "CYBER SHINOBI", 4, Color{ r: 0, g: 255, b: 220, a: 255 })
		draw_text_centered(renderer, 400, 240, "ROOFTOP ACTION RUNNER", 2, Color{ r: 255, g: 30, b: 60, a: 255 })
		draw_text_centered(renderer, 400, 340, "PRESS SPACE TO START", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 400, "CONTROLS: W/SPACE JUMP | J SLASH | K SHURIKEN", 1, Color{ r: 180, g: 180, b: 180, a: 255 })
	} else if g.state == .game_over {
		draw_text_centered(renderer, 400, 220, "GAME OVER - FALLEN NINJA", 4, Color{ r: 255, g: 50, b: 50, a: 255 })
		draw_text_centered(renderer, 400, 310, "FINAL SCORE: ${g.score}", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 370, "PRESS SPACE OR R TO RESTART", 2, Color{ r: 0, g: 255, b: 100, a: 255 })
	} else if g.state == .paused {
		draw_text_centered(renderer, 400, 280, "- PAUSED -", 3, Color{ r: 255, g: 255, b: 0, a: 255 })
	}

	if renderer.ctx != unsafe { nil } { prod_fx_render(renderer.ctx) }
	render_present(renderer)
}
