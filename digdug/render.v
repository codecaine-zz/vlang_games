import os
import rand

pub struct DigDugTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm DigDugTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/digdug.png',
		'./assets/sprites/digdug.png',
		'../assets/sprites/digdug.png',
		'digdug/assets/sprites/digdug.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('digdug Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

const dirt_colors = [
	Color{ r: 230, g: 190, b: 50, a: 255 },  // Layer 0: Gold Yellow Dirt
	Color{ r: 210, g: 130, b: 30, a: 255 },  // Layer 1: Orange Dirt
	Color{ r: 170, g: 80, b: 30, a: 255 },   // Layer 2: Brown Dirt
	Color{ r: 130, g: 40, b: 20, a: 255 },   // Layer 3: Dark Red Dirt
]

fn render_digdug_game(renderer &Renderer, mut g DigDugGame, tex &Texture) {
	mut ren := unsafe { &Renderer(renderer) }
	mut sx := f32(0.0)
	mut sy := f32(0.0)
	if g.shake_trauma > 0 {
		mag := g.shake_trauma * g.shake_trauma * 16.0
		sx = (f32(rand.intn(200) or { 100 }) - 100.0) * 0.01 * mag
		sy = (f32(rand.intn(200) or { 100 }) - 100.0) * 0.01 * mag
	}
	ren.offset_x += sx
	ren.offset_y += sy
	defer {
		ren.offset_x -= sx
		ren.offset_y -= sy
	}

	// Sky blue background
	set_render_draw_color(renderer, 20, 20, 30, 255)
	render_clear(renderer)

	// Sky Zone (Row 0)
	set_render_draw_color(renderer, 60, 160, 240, 255)
	sky := Rect{ x: offset_x, y: offset_y, w: grid_cols * tile_size, h: tile_size }
	render_fill_rect(renderer, &sky)

	// 1. Draw Subterranean Soil Strata Grid & Tunnels
	for r in 1 .. grid_rows {
		for c in 0 .. grid_cols {
			tx := offset_x + c * tile_size
			ty := offset_y + r * tile_size

			tile := g.grid[r][c]

			if tile.is_dug {
				// Deep Subterranean Tunnel with Ambient Dark Shading
				set_render_draw_color(renderer, 10, 8, 14, 255)
				rect := Rect{ x: tx, y: ty, w: tile_size, h: tile_size }
				render_fill_rect(renderer, &rect)

				// Subtle tunnel floor line
				set_render_draw_color(renderer, 25, 20, 30, 255)
				render_draw_line(renderer, tx, ty + tile_size - 1, tx + tile_size, ty + tile_size - 1)
			} else {
				// Layered Soil Strata with Gold Mineral Flecks
				col := dirt_colors[tile.layer % 4]
				set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
				rect := Rect{ x: tx, y: ty, w: tile_size, h: tile_size }
				render_fill_rect(renderer, &rect)

				// Top highlight strata strip
				hr := if int(col.r) + 30 > 255 { u8(255) } else { u8(col.r + 30) }
				hg := if int(col.g) + 30 > 255 { u8(255) } else { u8(col.g + 30) }
				set_render_draw_color(renderer, hr, hg, col.b, 255)
				render_draw_line(renderer, tx, ty, tx + tile_size - 1, ty)

				// Mineral specks
				if (r + c * 3) % 4 == 0 {
					set_render_draw_color(renderer, 254, 240, 138, 200)
					render_draw_point(renderer, tx + 8, ty + 12)
					render_draw_point(renderer, tx + 24, ty + 28)
				}
			}
		}
	}

	// Dynamic Flashlight Glow from Dig Dug
	if g.state == .playing || g.state == .paused {
		px := int(g.player_x)
		py := int(g.player_y)
		set_render_draw_blend_mode(renderer, .blend)
		set_render_draw_color(renderer, 255, 240, 160, 45)
		glow := Rect{ x: px - 35, y: py - 35, w: 70, h: 70 }
		render_fill_rect(renderer, &glow)
		set_render_draw_blend_mode(renderer, .none)
	}

	// 2. Draw Boulders
	for b in g.boulders {
		if !b.active { continue }
		bx := offset_x + b.grid_x * tile_size + 4
		by := int(b.y) + 4

		if tex != unsafe { nil } {
			src := Rect{x: 0, y: 192, w: 64, h: 64}
			dst := Rect{x: bx, y: by, w: 32, h: 32}
			render_copy(renderer, tex, &src, &dst)
			continue
		}

		set_render_draw_color(renderer, 160, 140, 120, 255)
		rock := Rect{ x: bx, y: by, w: 32, h: 32 }
		render_fill_rect(renderer, &rock)

		set_render_draw_color(renderer, 100, 80, 60, 255)
		crack := Rect{ x: bx + 8, y: by + 8, w: 16, h: 16 }
		render_fill_rect(renderer, &crack)
	}

	// 3. Draw High-Pressure Air Pump Hose Line & Harpoon
	if g.pump.active {
		px := int(g.player_x)
		py := int(g.player_y)

		hx := px + match g.pump.dir {
			.left { -int(g.pump.length) }
			.right { int(g.pump.length) }
			else { 0 }
		}
		hy := py + match g.pump.dir {
			.up { -int(g.pump.length) }
			.down { int(g.pump.length) }
			else { 0 }
		}

		// Neon Harpoon Wire Cable
		set_render_draw_color(renderer, 255, 235, 60, 255)
		render_draw_line(renderer, px, py, hx, hy)
		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_draw_line(renderer, px + 1, py, hx + 1, hy)

		// Dart Tip Needle
		set_render_draw_color(renderer, 239, 68, 68, 255)
		tip := Rect{ x: hx - 3, y: hy - 3, w: 6, h: 6 }
		render_fill_rect(renderer, &tip)
	}

	// 4. 16-Bit Enemies (Pooka & Fygar)
	for e in g.enemies {
		if !e.active { continue }
		ex := int(e.x)
		ey := int(e.y)
		scale := 1.0 + f32(e.inflate_stage) * 0.25

		if tex != unsafe { nil } {
			row_y := if e.enemy_type == .pooka { 64 } else { 128 }
			col_x := if e.is_ghost {
				4 * 64
			} else if e.is_breathing_fire {
				1 * 64
			} else if e.inflate_stage > 3 {
				3 * 64
			} else {
				e.inflate_stage * 64
			}
			src := Rect{x: col_x, y: row_y, w: 64, h: 64}
			dst := Rect{x: ex - int(16.0 * scale), y: ey - int(16.0 * scale), w: int(32.0 * scale), h: int(32.0 * scale)}
			flip := if e.dir == .left { RendererFlip.horizontal } else { RendererFlip.none }
			render_copy_ex(renderer, tex, &src, &dst, 0.0, unsafe { nil }, flip)
			continue
		}

		if e.enemy_type == .pooka {
			// 16-Bit Pooka (Red sphere with yellow diving goggles)
			color := if e.is_ghost { Color{ r: 255, g: 255, b: 255, a: 180 } } else { Color{ r: 235, g: 35, b: 40, a: 255 } }
			set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
			body := Rect{ x: ex - int(12.0 * scale), y: ey - int(12.0 * scale), w: int(24.0 * scale), h: int(24.0 * scale) }
			render_fill_rect(renderer, &body)

			// Highlight on Head
			if !e.is_ghost {
				set_render_draw_color(renderer, 255, 120, 130, 255)
				render_draw_line(renderer, ex - int(8.0 * scale), ey - int(10.0 * scale), ex + int(8.0 * scale), ey - int(10.0 * scale))
			}

			// Yellow Oversized Diving Goggles with Glint
			set_render_draw_color(renderer, 255, 215, 0, 255)
			gog := Rect{ x: ex - int(9.0 * scale), y: ey - int(6.0 * scale), w: int(18.0 * scale), h: int(9.0 * scale) }
			render_fill_rect(renderer, &gog)

			// Goggle Lenses
			set_render_draw_color(renderer, 20, 30, 40, 255)
			render_fill_rect(renderer, &Rect{ x: ex - int(7.0 * scale), y: ey - int(4.0 * scale), w: int(5.0 * scale), h: int(5.0 * scale) })
			render_fill_rect(renderer, &Rect{ x: ex + int(2.0 * scale), y: ey - int(4.0 * scale), w: int(5.0 * scale), h: int(5.0 * scale) })
		} else {
			// 16-Bit Fygar (Emerald Green Fire-Breathing Dragon)
			color := if e.is_ghost { Color{ r: 255, g: 255, b: 255, a: 180 } } else { Color{ r: 35, g: 195, b: 65, a: 255 } }
			set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
			body := Rect{ x: ex - int(14.0 * scale), y: ey - int(11.0 * scale), w: int(28.0 * scale), h: int(22.0 * scale) }
			render_fill_rect(renderer, &body)

			// Yellow Belly Scales
			if !e.is_ghost {
				set_render_draw_color(renderer, 255, 230, 50, 255)
				belly := Rect{ x: ex - int(6.0 * scale), y: ey, w: int(12.0 * scale), h: int(9.0 * scale) }
				render_fill_rect(renderer, &belly)
			}

			// White Bat Wings
			set_render_draw_color(renderer, 255, 255, 255, 255)
			wings := Rect{ x: ex - int(6.0 * scale), y: ey - int(16.0 * scale), w: int(12.0 * scale), h: int(6.0 * scale) }
			render_fill_rect(renderer, &wings)

			// Red Eyes
			set_render_draw_color(renderer, 255, 30, 30, 255)
			render_draw_point(renderer, ex - int(8.0 * scale), ey - int(5.0 * scale))

			// Fygar Flame Blast
			if e.is_breathing_fire {
				flame_w := 60
				flame_h := 14
				fx := if e.dir == .right { ex + 14 } else { ex - 14 - flame_w }
				fy := ey - 7
				set_render_draw_color(renderer, 255, 80, 0, 230)
				render_fill_rect(renderer, &Rect{ x: fx, y: fy, w: flame_w, h: flame_h })
				set_render_draw_color(renderer, 255, 230, 40, 255)
				render_fill_rect(renderer, &Rect{ x: fx + 4, y: fy + 3, w: flame_w - 8, h: flame_h - 6 })
			}
		}
	}

	// 5. 16-Bit Dig Dug (Taizo Hori) Miner Sprite
	if g.state == .playing || g.state == .paused {
		px := int(g.player_x)
		py := int(g.player_y)

		if tex != unsafe { nil } {
			col_x := if g.pump.active {
				3 * 64
			} else {
				0
			}
			src := Rect{x: col_x, y: 0, w: 64, h: 64}
			dst := Rect{x: px - 16, y: py - 16, w: 32, h: 32}
			flip := if g.player_dir == .left { RendererFlip.horizontal } else { RendererFlip.none }
			render_copy_ex(renderer, tex, &src, &dst, 0.0, unsafe { nil }, flip)
		} else {
			// White Miner Suit with Cyan Bevels
			set_render_draw_color(renderer, 245, 245, 250, 255)
			suit := Rect{ x: px - 11, y: py - 11, w: 22, h: 22 }
			render_fill_rect(renderer, &suit)

			// Cobalt Blue Hardhat with Visor
			set_render_draw_color(renderer, 20, 110, 240, 255)
			cap := Rect{ x: px - 10, y: py - 14, w: 20, h: 8 }
			render_fill_rect(renderer, &cap)

			// Visor Highlight
			set_render_draw_color(renderer, 100, 200, 255, 255)
			render_draw_line(renderer, px - 8, py - 13, px + 8, py - 13)

			// Face Visor Glass
			set_render_draw_color(renderer, 30, 40, 60, 255)
			visor := Rect{ x: px - 5, y: py - 6, w: 10, h: 5 }
			render_fill_rect(renderer, &visor)
		}
	}

	// 6. Draw HUD
	draw_text(renderer, 20, 15, "SCORE: ${g.score}", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
	draw_text(renderer, 320, 15, "HIGH: ${g.high_score}", 2, Color{ r: 255, g: 215, b: 0, a: 255 })
	draw_text(renderer, 650, 15, "STAGE ${g.stage}", 2, Color{ r: 0, g: 255, b: 255, a: 255 })

	// Lives
	for l in 0 .. g.lives {
		set_render_draw_color(renderer, 255, 255, 255, 255)
		icon := Rect{ x: 30 + l * 22, y: 570, w: 14, h: 14 }
		render_fill_rect(renderer, &icon)
	}

	// 7. Overlay Menus
	if g.state == .menu {
		draw_text_centered(renderer, 400, 180, "DIG DUG ARCADE", 4, Color{ r: 255, g: 200, b: 0, a: 255 })
		draw_text_centered(renderer, 400, 240, "SUBTERRANEAN EXCAVATION", 2, Color{ r: 0, g: 200, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 340, "PRESS SPACE TO START", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 400, "CONTROLS: WASD / ARROWS DIG | SPACE PUMP HOSE", 1, Color{ r: 180, g: 180, b: 180, a: 255 })
		draw_text_centered(renderer, 400, 420, "DIG TUNNELS & INFLATE ENEMIES OR DROP BOULDERS!", 1, Color{ r: 180, g: 180, b: 180, a: 255 })
	} else if g.state == .game_over {
		draw_text_centered(renderer, 400, 240, "GAME OVER", 4, Color{ r: 255, g: 50, b: 50, a: 255 })
		draw_text_centered(renderer, 400, 310, "FINAL SCORE: ${g.score}", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 370, "PRESS SPACE OR R TO RESTART", 2, Color{ r: 0, g: 255, b: 100, a: 255 })
	} else if g.state == .paused {
		draw_text_centered(renderer, 400, 280, "- PAUSED -", 3, Color{ r: 255, g: 255, b: 0, a: 255 })
	}

	if renderer.ctx != unsafe { nil } { prod_fx_render(renderer.ctx) }
	render_present(renderer)
}
