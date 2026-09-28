import os
import rand

pub struct BombermanTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm BombermanTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/bomberman.png',
		'./assets/sprites/bomberman.png',
		'../assets/sprites/bomberman.png',
		'bomberman/assets/sprites/bomberman.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('bomberman Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

fn render_bomberman_game(renderer &Renderer, mut g BombermanGame, tex &Texture) {
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

	// Background field dark grey
	set_render_draw_color(renderer, 30, 35, 45, 255)
	render_clear(renderer)

	// 1. Draw Grid Tiles
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			tx := grid_offset_x + c * tile_size
			ty := grid_offset_y + r * tile_size

			match g.grid[r][c] {
				.empty {
					// Checkerboard floor
					col_val := if (r + c) % 2 == 0 { u8(45) } else { u8(55) }
					set_render_draw_color(renderer, col_val, col_val + 10, col_val, 255)
					rect := Rect{ x: tx, y: ty, w: tile_size, h: tile_size }
					render_fill_rect(renderer, &rect)
				}
				.hard_wall {
					if tex != unsafe { nil } {
						src := Rect{ x: 0, y: 192, w: 64, h: 64 }
						dst := Rect{ x: tx, y: ty, w: tile_size, h: tile_size }
						render_copy(renderer, tex, &src, &dst)
						continue
					}
					// 3D Bevel Hard Wall
					set_render_draw_color(renderer, 80, 90, 105, 255)
					rect := Rect{ x: tx, y: ty, w: tile_size, h: tile_size }
					render_fill_rect(renderer, &rect)

					set_render_draw_color(renderer, 130, 140, 160, 255)
					top := Rect{ x: tx, y: ty, w: tile_size, h: 4 }
					left := Rect{ x: tx, y: ty, w: 4, h: tile_size }
					render_fill_rect(renderer, &top)
					render_fill_rect(renderer, &left)
				}
				.soft_block {
					if tex != unsafe { nil } {
						src := Rect{ x: 64, y: 192, w: 64, h: 64 }
						dst := Rect{ x: tx, y: ty, w: tile_size, h: tile_size }
						render_copy(renderer, tex, &src, &dst)
						continue
					}
					// 16-Bit Destructible Brick Block with Mortar Lines
					set_render_draw_color(renderer, 195, 95, 45, 255)
					rect := Rect{ x: tx + 1, y: ty + 1, w: tile_size - 2, h: tile_size - 2 }
					render_fill_rect(renderer, &rect)

					// Brick Mortar Highlights & Shadows
					set_render_draw_color(renderer, 240, 140, 80, 255)
					render_draw_line(renderer, tx + 2, ty + 2, tx + tile_size - 3, ty + 2)
					render_draw_line(renderer, tx + 2, ty + tile_size / 2, tx + tile_size - 3, ty + tile_size / 2)

					set_render_draw_color(renderer, 120, 50, 20, 255)
					render_draw_line(renderer, tx + tile_size / 2, ty + 2, tx + tile_size / 2, ty + tile_size / 2)
					render_draw_line(renderer, tx + tile_size / 4, ty + tile_size / 2, tx + tile_size / 4, ty + tile_size - 2)
					render_draw_line(renderer, tx + tile_size * 3 / 4, ty + tile_size / 2, tx + tile_size * 3 / 4, ty + tile_size - 2)
				}
			}
		}
	}

	// 2. 16-Bit Power-Ups
	for p in g.powerups {
		if !p.active { continue }
		px := grid_offset_x + p.grid_x * tile_size + 6
		py := grid_offset_y + p.grid_y * tile_size + 6

		if tex != unsafe { nil } {
			col_x := match p.power_type {
				.flame { 128 }
				.bomb_cap { 192 }
				.speed { 256 }
				else { 128 }
			}
			src := Rect{ x: col_x, y: 192, w: 64, h: 64 }
			dst := Rect{ x: px - 2, y: py - 2, w: 32, h: 32 }
			render_copy(renderer, tex, &src, &dst)
			continue
		}

		color := match p.power_type {
			.flame { Color{ r: 255, g: 70, b: 0, a: 255 } }
			.bomb_cap { Color{ r: 0, g: 170, b: 245, a: 255 } }
			.speed { Color{ r: 255, g: 215, b: 0, a: 255 } }
			else { Color{ r: 200, g: 200, b: 200, a: 255 } }
		}
		set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
		rect := Rect{ x: px, y: py, w: 28, h: 28 }
		render_fill_rect(renderer, &rect)
		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_draw_rect(renderer, &rect)

		// Icon label
		icon_text := match p.power_type {
			.flame { 'F' }
			.bomb_cap { 'B' }
			.speed { 'S' }
			else { '+' }
		}
		draw_text_centered(renderer, px + 14, py + 6, icon_text, 2, Color{ r: 255, g: 255, b: 255, a: 255 })
	}

	// 3. 16-Bit Spherical Shaded Bombs
	for b in g.bombs {
		if !b.active { continue }
		bx := grid_offset_x + b.grid_x * tile_size + 6
		by := grid_offset_y + b.grid_y * tile_size + 6

		pulse := int(b.fuse_timer * 10.0) % 2 == 0

		if tex != unsafe { nil } {
			col_x := if pulse { 64 } else { 0 }
			src := Rect{ x: col_x, y: 128, w: 64, h: 64 }
			dst := Rect{ x: bx - 2, y: by - 2, w: 32, h: 32 }
			render_copy(renderer, tex, &src, &dst)
			continue
		}

		color := if pulse { Color{ r: 35, g: 35, b: 45, a: 255 } } else { Color{ r: 120, g: 25, b: 25, a: 255 } }
		set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
		body := Rect{ x: bx, y: by + 2, w: 28, h: 26 }
		render_fill_rect(renderer, &body)

		// Specular Bomb Highlight
		set_render_draw_color(renderer, 255, 255, 255, 200)
		render_draw_point(renderer, bx + 6, by + 6)
		render_draw_point(renderer, bx + 7, by + 6)

		// Glowing Spark Fuse
		set_render_draw_color(renderer, 255, 220, 30, 255)
		fuse := Rect{ x: bx + 12, y: by - 4, w: 4, h: 6 }
		render_fill_rect(renderer, &fuse)
		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_draw_point(renderer, bx + 13, by - 5)
	}

	// 4. 16-Bit Multi-Tone Flame Explosions
	for f in g.flames {
		fx := grid_offset_x + f.grid_x * tile_size
		fy := grid_offset_y + f.grid_y * tile_size

		if tex != unsafe { nil } {
			src := Rect{ x: 128, y: 128, w: 64, h: 64 }
			dst := Rect{ x: fx, y: fy, w: tile_size, h: tile_size }
			render_copy(renderer, tex, &src, &dst)
			continue
		}

		alpha := u8(f.timer / 0.5 * 255.0)
		// Outer Fiery Edge
		set_render_draw_color(renderer, 245, 60, 20, alpha)
		center := Rect{ x: fx + 2, y: fy + 2, w: tile_size - 4, h: tile_size - 4 }
		render_fill_rect(renderer, &center)

		// Mid Orange Flame
		set_render_draw_color(renderer, 255, 160, 30, alpha)
		mid := Rect{ x: fx + 6, y: fy + 6, w: tile_size - 12, h: tile_size - 12 }
		render_fill_rect(renderer, &mid)

		// Inner Incandescent Core
		set_render_draw_color(renderer, 255, 255, 200, alpha)
		inner := Rect{ x: fx + 12, y: fy + 12, w: tile_size - 24, h: tile_size - 24 }
		render_fill_rect(renderer, &inner)
	}

	// 5. 16-Bit Bomberman Player Sprite
	for pl in g.players {
		if !pl.active { continue }
		px := int(pl.x)
		py := int(pl.y)

		if tex != unsafe { nil } {
			row_y := if pl.id == 1 { 0 } else { 64 }
			src := Rect{ x: 0, y: row_y, w: 64, h: 64 }
			dst := Rect{ x: px - 16, y: py - 18, w: 32, h: 32 }
			render_copy(renderer, tex, &src, &dst)
			continue
		}

		body_color := if pl.id == 1 { Color{ r: 0, g: 140, b: 245, a: 255 } } else { Color{ r: 245, g: 45, b: 45, a: 255 } }

		// Player Body (Blue / Red Jumpsuit)
		set_render_draw_color(renderer, body_color.r, body_color.g, body_color.b, body_color.a)
		body := Rect{ x: px - 11, y: py - 6, w: 22, h: 18 }
		render_fill_rect(renderer, &body)

		// White Head / Helmet
		set_render_draw_color(renderer, 250, 250, 252, 255)
		helmet := Rect{ x: px - 12, y: py - 16, w: 24, h: 14 }
		render_fill_rect(renderer, &helmet)

		// Pink Antenna Sphere on top of helmet
		set_render_draw_color(renderer, 255, 100, 160, 255)
		ant := Rect{ x: px - 3, y: py - 20, w: 6, h: 5 }
		render_fill_rect(renderer, &ant)

		// Black Visor Eyes
		set_render_draw_color(renderer, 20, 25, 35, 255)
		e1 := Rect{ x: px - 6, y: py - 11, w: 3, h: 5 }
		e2 := Rect{ x: px + 3, y: py - 11, w: 3, h: 5 }
		render_fill_rect(renderer, &e1)
		render_fill_rect(renderer, &e2)
	}

	// 6. Draw HUD
	draw_text(renderer, 20, 10, "BOMBERMAN", 2, Color{ r: 255, g: 220, b: 0, a: 255 })
	draw_text(renderer, 200, 10, "LIVES: ${g.players[0].lives}  |  BOMBS: ${g.players[0].max_bombs}  |  FLAME: ${g.players[0].flame_radius}", 2, Color{ r: 0, g: 200, b: 255, a: 255 })
	draw_text_centered(renderer, 400, 575, "[SPACE] BOMB  |  [WASD] MOVE  |  [P] PAUSE  |  [M] MUTE  |  [R] RESTART", 1, Color{ r: 220, g: 220, b: 220, a: 255 })

	// 7. Overlay Menus
	if g.state == .menu {
		draw_text_centered(renderer, 400, 180, "CYBER BOMBERMAN", 4, Color{ r: 255, g: 200, b: 0, a: 255 })
		draw_text_centered(renderer, 400, 240, "GRID TACTICAL MAZE BATTLE", 2, Color{ r: 0, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 310, "GOAL: DROP BOMBS TO DESTROY WALLS & ENEMIES!", 2, Color{ r: 255, g: 100, b: 100, a: 255 })
		draw_text_centered(renderer, 400, 380, "PRESS SPACE TO START", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 440, "P1: WASD MOVE, SPACE DROP BOMB | P2: ARROWS MOVE, ENTER DROP BOMB", 1, Color{ r: 180, g: 180, b: 180, a: 255 })
	} else if g.state == .game_over {
		draw_text_centered(renderer, 400, 260, "GAME OVER - DEFEATED!", 3, Color{ r: 255, g: 50, b: 50, a: 255 })
		draw_text_centered(renderer, 400, 340, "PRESS SPACE OR R TO RESTART", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
	} else if g.state == .victory {
		draw_text_centered(renderer, 400, 260, "VICTORY! ENEMY DESTROYED!", 3, Color{ r: 0, g: 255, b: 100, a: 255 })
		draw_text_centered(renderer, 400, 340, "PRESS SPACE OR R TO RESTART", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
	} else if g.state == .paused {
		draw_text_centered(renderer, 400, 280, "- PAUSED -", 3, Color{ r: 255, g: 255, b: 0, a: 255 })
	}

	if renderer.ctx != unsafe { nil } { prod_fx_render(renderer.ctx) }
	render_present(renderer)
}
