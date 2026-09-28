module main

import os

pub struct TowerDefenseTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm TowerDefenseTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/towerdefense.png',
		'./assets/sprites/towerdefense.png',
		'../assets/sprites/towerdefense.png',
		'towerdefense/assets/sprites/towerdefense.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('towerdefense Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

fn render_towerdefense_game(renderer &Renderer, mut g TowerDefenseGame, tex &Texture) {
	// Dark Sci-Fi Command Background
	set_render_draw_color(renderer, 15, 20, 30, 255)
	render_clear(renderer)

	// 1. Draw Grid Tiles
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			tx := offset_x + c * tile_size
			ty := offset_y + r * tile_size

			if g.path_grid[r][c] {
				// Dirt Creep Path
				set_render_draw_color(renderer, 60, 50, 40, 255)
				rect := Rect{ x: tx, y: ty, w: tile_size, h: tile_size }
				render_fill_rect(renderer, &rect)
			} else {
				// Green Grass / Build Slot
				is_sel := c == g.selected_gx && r == g.selected_gy
				col_val := if is_sel { u8(80) } else { u8(35) }
				set_render_draw_color(renderer, 20, col_val, 30, 255)
				rect := Rect{ x: tx + 1, y: ty + 1, w: tile_size - 2, h: tile_size - 2 }
				render_fill_rect(renderer, &rect)
			}
		}
	}

	// 2. Draw Castle Base Core at (14, 9)
	base_x := offset_x + 14 * tile_size
	base_y := offset_y + 9 * tile_size
	if tex != unsafe { nil } {
		src := Rect{ x: 0, y: 128, w: 48, h: 48 }
		dst := Rect{ x: base_x + 2, y: base_y + 2, w: 36, h: 36 }
		render_copy(renderer, tex, &src, &dst)
	} else {
		set_render_draw_color(renderer, 0, 255, 200, 255)
		base_rect := Rect{ x: base_x + 4, y: base_y + 4, w: 32, h: 32 }
		render_fill_rect(renderer, &base_rect)
	}

	// 3. Draw Turrets & Firing Lasers
	for t in g.turrets {
		tx := offset_x + t.grid_x * tile_size + 20
		ty := offset_y + t.grid_y * tile_size + 20

		if tex != unsafe { nil } {
			idx := match t.turret_type {
				.laser { 0 }
				.cannon { 1 }
				.frost { 2 }
			}
			src := Rect{ x: idx * 48, y: 0, w: 48, h: 48 }
			dst := Rect{ x: tx - 18, y: ty - 18, w: 36, h: 36 }
			render_copy(renderer, tex, &src, &dst)
		} else {
			// Turret Base
			set_render_draw_color(renderer, 90, 100, 120, 255)
			base := Rect{ x: tx - 14, y: ty - 14, w: 28, h: 28 }
			render_fill_rect(renderer, &base)

			// Turret Barrel / Color
			color := match t.turret_type {
				.laser { Color{ r: 255, g: 50, b: 50, a: 255 } }
				.cannon { Color{ r: 255, g: 200, b: 0, a: 255 } }
				.frost { Color{ r: 0, g: 200, b: 255, a: 255 } }
			}
			set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
			barrel := Rect{ x: tx - 8, y: ty - 8, w: 16, h: 16 }
			render_fill_rect(renderer, &barrel)
		}

		// Firing Ray if target connected
		if t.target_id > 0 {
			color := match t.turret_type {
				.laser { Color{ r: 255, g: 50, b: 50, a: 255 } }
				.cannon { Color{ r: 255, g: 200, b: 0, a: 255 } }
				.frost { Color{ r: 0, g: 200, b: 255, a: 255 } }
			}
			set_render_draw_color(renderer, color.r, color.g, color.b, 255)
			render_draw_line(renderer, tx, ty, int(t.target_x), int(t.target_y))
		}
	}

	// 4. Draw Creeps & Health Bars
	for c in g.creeps {
		if !c.active { continue }
		cx := int(c.x)
		cy := int(c.y)

		if tex != unsafe { nil } {
			idx := match c.creep_type {
				.normal { 0 }
				.scout { 1 }
				.tank { 2 }
				.boss { 3 }
			}
			src := Rect{ x: idx * 48, y: 64, w: 48, h: 48 }
			dst := Rect{ x: cx - 14, y: cy - 14, w: 28, h: 28 }
			render_copy(renderer, tex, &src, &dst)
		} else {
			body_color := match c.creep_type {
				.normal { Color{ r: 200, g: 200, b: 50, a: 255 } }
				.scout { Color{ r: 50, g: 220, b: 255, a: 255 } }
				.tank { Color{ r: 220, g: 50, b: 50, a: 255 } }
				.boss { Color{ r: 200, g: 50, b: 200, a: 255 } }
			}
			set_render_draw_color(renderer, body_color.r, body_color.g, body_color.b, body_color.a)
			rect := Rect{ x: cx - 10, y: cy - 10, w: 20, h: 20 }
			render_fill_rect(renderer, &rect)
		}

		// Health Bar
		hp_ratio := c.hp / c.max_hp
		if hp_ratio > 0 {
			set_render_draw_color(renderer, 0, 255, 100, 255)
			hp_w := int(hp_ratio * 22.0)
			bar := Rect{ x: cx - 11, y: cy - 15, w: hp_w, h: 4 }
			render_fill_rect(renderer, &bar)
		}
	}

	// 5. Build Selection Box
	sel_x := offset_x + g.selected_gx * tile_size
	sel_y := offset_y + g.selected_gy * tile_size
	set_render_draw_color(renderer, 255, 255, 0, 255)
	box := Rect{ x: sel_x, y: sel_y, w: tile_size, h: tile_size }
	render_draw_rect(renderer, &box)

	// 6. HUD
	draw_text(renderer, 20, 15, "GOLD: $${g.gold}", 2, Color{ r: 255, g: 215, b: 0, a: 255 })
	draw_text(renderer, 250, 15, "BASE LIVES: ${g.lives}", 2, Color{ r: 255, g: 50, b: 50, a: 255 })
	draw_text(renderer, 500, 15, "WAVE ${g.wave}", 2, Color{ r: 0, g: 255, b: 255, a: 255 })

	// Build Menu Footer Bar
	draw_text(renderer, 20, 535, "[1/L] LASER ($100)  [2/C] CANNON ($150)  [3/F] FROST ($125)", 1, Color{ r: 220, g: 220, b: 220, a: 255 })
	draw_text(renderer, 20, 555, "ARROWS/WASD: MOVE  |  SPACE/ENTER/B: BUILD  |  U: UPGRADE  |  X: SELL", 1, Color{ r: 0, g: 255, b: 200, a: 255 })
	draw_text(renderer, 20, 575, "P: PAUSE  |  R: RESTART  |  M: MUTE  |  ESC: QUIT", 1, Color{ r: 180, g: 180, b: 180, a: 255 })

	// Selected Turret Details Overlay in HUD
	mut sel_info := ""
	for t in g.turrets {
		if t.grid_x == g.selected_gx && t.grid_y == g.selected_gy {
			base_cost := match t.turret_type {
				.laser { 100 }
				.cannon { 150 }
				.frost { 125 }
			}
			upg_cost := (base_cost * t.level) / 2
			sell_val := (base_cost + (t.level - 1) * (base_cost / 2)) * 7 / 10
			sel_info = "SEL: LVL ${t.level} ${t.turret_type} (UPG: $${upg_cost} | SELL: $${sell_val})"
			break
		}
	}
	if sel_info != "" {
		draw_text(renderer, 480, 535, sel_info, 1, Color{ r: 255, g: 255, b: 0, a: 255 })
	}

	// 7. Overlay Menus
	if g.state == .menu {
		draw_text_centered(renderer, 400, 180, "CYBER TOWER DEFENSE", 4, Color{ r: 0, g: 255, b: 200, a: 255 })
		draw_text_centered(renderer, 400, 240, "TACTICAL CREEP WAVE DEFENSE", 2, Color{ r: 255, g: 215, b: 0, a: 255 })
		draw_text_centered(renderer, 400, 340, "PRESS SPACE OR ENTER TO START", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
	} else if g.state == .game_over {
		draw_text_centered(renderer, 400, 220, "GAME OVER - BASE DESTROYED", 4, Color{ r: 255, g: 50, b: 50, a: 255 })
		draw_text_centered(renderer, 400, 310, "FINAL DEFENSE SCORE: ${g.score}", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 370, "PRESS SPACE OR R TO RESTART", 2, Color{ r: 0, g: 255, b: 100, a: 255 })
	} else if g.state == .victory {
		draw_text_centered(renderer, 400, 220, "VICTORY! ALL WAVES DEFEATED", 4, Color{ r: 0, g: 255, b: 100, a: 255 })
		draw_text_centered(renderer, 400, 310, "FINAL SCORE: ${g.score}", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 370, "PRESS SPACE OR R TO PLAY AGAIN", 2, Color{ r: 0, g: 255, b: 200, a: 255 })
	} else if g.state == .paused {
		draw_text_centered(renderer, 400, 280, "- PAUSED -", 3, Color{ r: 255, g: 255, b: 0, a: 255 })
	}

	if renderer.ctx != unsafe { nil } { prod_fx_render(renderer.ctx) }
	render_present(renderer)
}
