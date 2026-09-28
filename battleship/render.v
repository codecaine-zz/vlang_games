module main

import os



const col_ocean_bg = Color{ r: 10, g: 25, b: 45, a: 255 }
const col_ocean_grid = Color{ r: 20, g: 60, b: 95, a: 255 }
const col_ocean_line = Color{ r: 35, g: 90, b: 130, a: 255 }
const col_radar_green = Color{ r: 40, g: 240, b: 120, a: 255 }
const col_radar_bg = Color{ r: 8, g: 28, b: 22, a: 255 }
const col_steel = Color{ r: 45, g: 55, b: 65, a: 255 }
const col_steel_light = Color{ r: 90, g: 110, b: 130, a: 255 }
const col_ship_hull = Color{ r: 130, g: 140, b: 155, a: 255 }
const col_ship_deck = Color{ r: 95, g: 105, b: 115, a: 255 }
const col_hit_fire = Color{ r: 255, g: 60, b: 40, a: 255 }
const col_miss_white = Color{ r: 220, g: 235, b: 245, a: 255 }

pub struct BattleshipTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn new_battleship_texture_manager() BattleshipTextureManager {
	return BattleshipTextureManager{}
}

pub fn (mut tm BattleshipTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/battleship.png',
		'./assets/sprites/battleship.png',
		'../assets/sprites/battleship.png',
		'battleship/assets/sprites/battleship.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('battleship Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

pub fn render_battleship_game(renderer &Renderer, mut g BattleshipGame, w int, h int, mx int, my int, tex &Texture) {
	// Military steel bridge background
	draw_beveled_box(renderer, 0, 0, w, h, Color{r:15,g:18,b:24}, col_steel_light, Color{r:5,g:6,b:8})

	// Top Command Banner
	draw_beveled_box(renderer, 24, 16, w - 48, 55, Color{r:18,g:28,b:38}, col_radar_green, Color{r:8,g:14,b:20})
	draw_text_centered(renderer, w / 2, 26, 'BATTLESHIP PRO: TACTICAL NAVAL COMMAND', 2, col_radar_green)
	draw_text(renderer, 40, 48, 'FLEET ADMIRAL RADAR SYSTEM', 1, Color{r:140,g:180,b:200})

	if tex != unsafe { nil } {
		// Admiral Medal Badge
		src_medal := Rect{320, 320, 32, 32}
		dst_medal := Rect{w - 70, 24, 36, 36}
		render_copy(renderer, tex, &src_medal, &dst_medal)
	}

	acc := if g.shots_fired_p1 > 0 { int((f64(g.shots_hit_p1) / f64(g.shots_fired_p1)) * 100.0) } else { 0 }
	draw_text(renderer, w - 280, 48, 'SHOTS: ${g.shots_fired_p1} | ACCURACY: ${acc}%', 1, Color{r:255,g:220,b:100})

	// Dual 10x10 Grids Setup
	grid_pix := 32
	left_gx := 50
	left_gy := 120
	right_gx := 520
	right_gy := 120

	// Left Grid: Your Fleet Waters
	draw_beveled_box(renderer, left_gx - 10, left_gy - 30, grid_pix * 10 + 20, grid_pix * 10 + 40, col_steel, col_steel_light, Color{r:10,g:12,b:15})
	draw_text_centered(renderer, left_gx + (grid_pix * 10) / 2, left_gy - 22, 'FRIENDLY WATERS (YOUR FLEET)', 1, Color{r:120,g:200,b:255})

	// Right Grid: Enemy Radar Tracking
	draw_beveled_box(renderer, right_gx - 10, right_gy - 30, grid_pix * 10 + 20, grid_pix * 10 + 40, Color{r:15,g:35,b:25}, col_radar_green, Color{r:5,g:12,b:8})
	draw_text_centered(renderer, right_gx + (grid_pix * 10) / 2, right_gy - 22, 'ENEMY WATERS (TARGETING RADAR)', 1, col_radar_green)

	// Column Coordinates (A-J) and Row Coordinates (1-10)
	for i in 0 .. grid_size {
		letter := u8(`A` + i).ascii_str()
		num := '${i + 1}'

		// Left grid coords
		draw_text_centered(renderer, left_gx + i * grid_pix + grid_pix / 2, left_gy - 10, letter, 1, Color{r:180,g:200,b:220})
		draw_text_centered(renderer, left_gx - 14, left_gy + i * grid_pix + grid_pix / 2 - 4, num, 1, Color{r:180,g:200,b:220})

		// Right grid coords
		draw_text_centered(renderer, right_gx + i * grid_pix + grid_pix / 2, right_gy - 10, letter, 1, col_radar_green)
		draw_text_centered(renderer, right_gx - 14, right_gy + i * grid_pix + grid_pix / 2 - 4, num, 1, col_radar_green)
	}

	// 1. Render Left Grid (Player Fleet)
	for gy in 0 .. grid_size {
		for gx in 0 .. grid_size {
			cx := left_gx + gx * grid_pix
			cy := left_gy + gy * grid_pix
			c_state := g.p1_grid.cells[gy][gx]

			if tex != unsafe { nil } {
				// Water background tile
				src_water := Rect{0, 320, 32, 32}
				dst_cell := Rect{cx, cy, grid_pix, grid_pix}
				render_copy(renderer, tex, &src_water, &dst_cell)
			} else {
				draw_beveled_box(renderer, cx, cy, grid_pix, grid_pix, col_ocean_bg, col_ocean_grid, col_ocean_line)
			}

			// Ship body (if fallback without whole ship sprite)
			if tex == unsafe { nil } && c_state == cell_ship {
				draw_beveled_box(renderer, cx + 2, cy + 2, grid_pix - 4, grid_pix - 4, col_ship_hull, Color{r:180,g:190,b:205}, col_ship_deck)
				draw_filled_circle(renderer, cx + grid_pix / 2, cy + grid_pix / 2, 4, Color{r:50,g:60,b:70})
			}
		}
	}

	// Render Placed Warship Sprites on Left Grid
	for s_idx, s in g.p1_grid.ships {
		if s.placed {
			render_warship_sprite(renderer, s, s_idx, left_gx, left_gy, grid_pix, tex)
		}
	}

	// Render Hit/Miss/Sunk Markers on Left Grid
	for gy in 0 .. grid_size {
		for gx in 0 .. grid_size {
			cx := left_gx + gx * grid_pix
			cy := left_gy + gy * grid_pix
			c_state := g.p1_grid.cells[gy][gx]

			if c_state == cell_hit {
				if tex != unsafe { nil } {
					src_hit := Rect{96, 320, 32, 32}
					dst_hit := Rect{cx, cy, grid_pix, grid_pix}
					render_copy(renderer, tex, &src_hit, &dst_hit)
				} else {
					draw_beveled_box(renderer, cx + 2, cy + 2, grid_pix - 4, grid_pix - 4, Color{r:120,g:30,b:20}, col_hit_fire, Color{r:60,g:10,b:10})
					draw_filled_circle(renderer, cx + grid_pix / 2, cy + grid_pix / 2, 8, col_hit_fire)
					draw_filled_circle(renderer, cx + grid_pix / 2, cy + grid_pix / 2, 4, Color{r:255,g:220,b:80})
				}
			} else if c_state == cell_sunk {
				if tex != unsafe { nil } {
					src_sunk := Rect{128, 320, 32, 32}
					dst_sunk := Rect{cx, cy, grid_pix, grid_pix}
					render_copy(renderer, tex, &src_sunk, &dst_sunk)
				} else {
					draw_beveled_box(renderer, cx + 2, cy + 2, grid_pix - 4, grid_pix - 4, Color{r:40,g:15,b:15}, Color{r:180,g:30,b:30}, Color{r:20,g:5,b:5})
					draw_text_centered(renderer, cx + grid_pix / 2, cy + grid_pix / 2 - 4, 'X', 1, Color{r:255,g:80,b:80})
				}
			} else if c_state == cell_miss {
				if tex != unsafe { nil } {
					src_splash := Rect{64, 320, 32, 32}
					dst_splash := Rect{cx, cy, grid_pix, grid_pix}
					render_copy(renderer, tex, &src_splash, &dst_splash)
				} else {
					draw_filled_circle(renderer, cx + grid_pix / 2, cy + grid_pix / 2, 5, col_miss_white)
				}
			}
		}
	}

	// Render Placement Hologram if in Placement Phase
	if g.phase == .placement && g.selected_ship_idx >= 0 && g.selected_ship_idx < g.p1_grid.ships.len {
		s_size := g.p1_grid.ships[g.selected_ship_idx].size
		if mx >= left_gx && mx < left_gx + grid_pix * 10 && my >= left_gy && my < left_gy + grid_pix * 10 {
			hover_gx := (mx - left_gx) / grid_pix
			hover_gy := (my - left_gy) / grid_pix
			can_p := g.p1_grid.can_place(s_size, hover_gx, hover_gy, g.place_horizontal)
			holo_col := if can_p { Color{r:40,g:220,b:100,a:160} } else { Color{r:240,g:50,b:50,a:160} }

			for i in 0 .. s_size {
				hx := if g.place_horizontal { hover_gx + i } else { hover_gx }
				hy := if g.place_horizontal { hover_gy } else { hover_gy + i }
				if hx < grid_size && hy < grid_size {
					hcx := left_gx + hx * grid_pix
					hcy := left_gy + hy * grid_pix
					draw_beveled_box(renderer, hcx + 2, hcy + 2, grid_pix - 4, grid_pix - 4, holo_col, Color{r:255,g:255,b:255}, holo_col)
				}
			}
		}
	}

	// 2. Render Right Grid (Targeting Radar)
	for gy in 0 .. grid_size {
		for gx in 0 .. grid_size {
			cx := right_gx + gx * grid_pix
			cy := right_gy + gy * grid_pix
			c_state := g.p2_grid.cells[gy][gx]

			if tex != unsafe { nil } {
				src_radar := Rect{32, 320, 32, 32}
				dst_radar := Rect{cx, cy, grid_pix, grid_pix}
				render_copy(renderer, tex, &src_radar, &dst_radar)
			} else {
				draw_beveled_box(renderer, cx, cy, grid_pix, grid_pix, col_radar_bg, Color{r:18,g:50,b:35}, Color{r:10,g:30,b:20})
				set_render_draw_color(renderer, 25, 60, 40, 255)
				render_draw_point(renderer, cx + grid_pix / 2, cy + grid_pix / 2)
			}

			// Highlight if revealed by radar scan
			for r_pt in g.radar_revealed {
				if r_pt[0] == gx && r_pt[1] == gy {
					if tex != unsafe { nil } {
						src_sonar := Rect{160, 320, 32, 32}
						dst_sonar := Rect{cx, cy, grid_pix, grid_pix}
						render_copy(renderer, tex, &src_sonar, &dst_sonar)
					} else {
						draw_beveled_box(renderer, cx + 1, cy + 1, grid_pix - 2, grid_pix - 2, Color{r:20,g:90,b:50}, col_radar_green, Color{r:10,g:40,b:25})
					}
					if c_state == cell_ship || c_state == cell_hit {
						if tex != unsafe { nil } {
							src_star := Rect{224, 320, 32, 32}
							dst_star := Rect{cx, cy, grid_pix, grid_pix}
							render_copy(renderer, tex, &src_star, &dst_star)
						} else {
							draw_text_centered(renderer, cx + grid_pix / 2, cy + grid_pix / 2 - 4, '!', 1, Color{r:255,g:220,b:80})
						}
					}
				}
			}

			if c_state == cell_hit {
				if tex != unsafe { nil } {
					src_hit := Rect{96, 320, 32, 32}
					dst_hit := Rect{cx, cy, grid_pix, grid_pix}
					render_copy(renderer, tex, &src_hit, &dst_hit)
				} else {
					draw_beveled_box(renderer, cx + 2, cy + 2, grid_pix - 4, grid_pix - 4, Color{r:140,g:30,b:20}, col_hit_fire, Color{r:70,g:15,b:10})
					draw_filled_circle(renderer, cx + grid_pix / 2, cy + grid_pix / 2, 7, col_hit_fire)
				}
			} else if c_state == cell_sunk {
				if tex != unsafe { nil } {
					src_sunk := Rect{128, 320, 32, 32}
					dst_sunk := Rect{cx, cy, grid_pix, grid_pix}
					render_copy(renderer, tex, &src_sunk, &dst_sunk)
				} else {
					draw_beveled_box(renderer, cx + 2, cy + 2, grid_pix - 4, grid_pix - 4, Color{r:50,g:15,b:15}, Color{r:220,g:40,b:40}, Color{r:20,g:5,b:5})
					draw_text_centered(renderer, cx + grid_pix / 2, cy + grid_pix / 2 - 4, 'SUNK', 1, Color{r:255,g:120,b:120})
				}
			} else if c_state == cell_miss {
				if tex != unsafe { nil } {
					src_splash := Rect{64, 320, 32, 32}
					dst_splash := Rect{cx, cy, grid_pix, grid_pix}
					render_copy(renderer, tex, &src_splash, &dst_splash)
				} else {
					draw_filled_circle(renderer, cx + grid_pix / 2, cy + grid_pix / 2, 5, col_miss_white)
				}
			}

			// Target Reticle Cursor on Hover
			if g.phase == .battle && g.current_turn == 1 {
				if mx >= cx && mx < cx + grid_pix && my >= cy && my < cy + grid_pix {
					if tex != unsafe { nil } {
						reticle_src := if g.radar_active { Rect{160, 320, 32, 32} } else { Rect{192, 320, 32, 32} }
						dst_ret := Rect{cx, cy, grid_pix, grid_pix}
						render_copy(renderer, tex, &reticle_src, &dst_ret)
					} else {
						reticle_col := if g.radar_active { Color{r:255,g:220,b:40} } else { col_radar_green }
						draw_circle_outline(renderer, cx + grid_pix / 2, cy + grid_pix / 2, grid_pix / 2 - 2, reticle_col)
						set_render_draw_color(renderer, reticle_col.r, reticle_col.g, reticle_col.b, reticle_col.a)
						render_draw_line(renderer, cx + grid_pix / 2, cy + 2, cx + grid_pix / 2, cy + grid_pix - 2)
						render_draw_line(renderer, cx + 2, cy + grid_pix / 2, cx + grid_pix - 2, cy + grid_pix / 2)
					}
				}
			}
		}
	}

	// 3. Bottom Command Interface & Fleet Status Panel
	panel_y := h - 170
	draw_beveled_box(renderer, 24, panel_y, w - 48, 110, Color{r:20,g:25,b:35}, col_steel_light, Color{r:10,g:12,b:16})

	if g.phase == .placement {
		draw_text(renderer, 40, panel_y + 12, 'FLEET DEPLOYMENT: CLICK SHIP OR CELL TO PLACE', 1, Color{r:255,g:220,b:100})
		draw_text(renderer, 40, panel_y + 30, 'ORIENTATION: ${if g.place_horizontal { "HORIZONTAL [R to rotate]" } else { "VERTICAL [R to rotate]" }}', 1, Color{r:200,g:220,b:240})

		// Ship Select Buttons
		for i, s in g.p1_grid.ships {
			bx := 40 + i * 140
			by := panel_y + 52
			is_sel := (g.selected_ship_idx == i)
			btn_bg := if is_sel { Color{r:40,g:100,b:60} } else { Color{r:30,g:40,b:50} }
			border := if is_sel { col_radar_green } else { Color{r:80,g:90,b:100} }
			draw_beveled_box(renderer, bx, by, 130, 42, btn_bg, border, Color{r:15,g:20,b:25})
			status_icon := if s.placed { '✓ ' } else { '• ' }
			draw_text(renderer, bx + 8, by + 8, '${status_icon}${s.name}', 1, Color{r:255,g:255,b:255})
			draw_text(renderer, bx + 8, by + 24, '${s.size} CELLS', 1, if s.placed { Color{r:120,g:240,b:140} } else { Color{r:240,g:180,b:80} })
		}

		// Auto-Place & Launch Battle Buttons
		draw_beveled_box(renderer, 760, panel_y + 14, 130, 36, Color{r:40,g:60,b:80}, col_steel_light, Color{r:15,g:20,b:30})
		draw_text_centered(renderer, 825, panel_y + 26, 'AUTO-PLACE [F]', 1, Color{r:255,g:255,b:255})

		draw_beveled_box(renderer, 760, panel_y + 58, 130, 36, Color{r:30,g:120,b:50}, col_radar_green, Color{r:15,g:50,b:20})
		draw_text_centered(renderer, 825, panel_y + 70, 'START BATTLE', 1, Color{r:255,g:255,b:255})
	} else {
		// Battle Fleet Status
		draw_text(renderer, 40, panel_y + 12, 'ENEMY FLEET STATUS:', 1, Color{r:255,g:140,b:140})
		for i, s in g.p2_grid.ships {
			bx := 40 + i * 150
			by := panel_y + 32
			status_str := if s.is_sunk { 'SUNK' } else { '${s.size - s.hits}/${s.size} HP' }
			status_col := if s.is_sunk { Color{r:255,g:70,b:70} } else { Color{r:140,g:220,b:160} }
			draw_text(renderer, bx, by, s.name, 1, Color{r:220,g:220,b:220})
			draw_text(renderer, bx, by + 16, status_str, 1, status_col)
		}

		// Special Radar Recon button
		radar_btn_bg := if g.radar_active { Color{r:200,g:160,b:30} } else if g.radar_left_p1 > 0 { Color{r:30,g:80,b:120} } else { Color{r:50,g:50,b:50} }
		draw_beveled_box(renderer, 750, panel_y + 35, 140, 42, radar_btn_bg, col_radar_green, Color{r:10,g:30,b:40})
		radar_label := if g.radar_active { 'CLICK RADAR CELL' } else { 'RADAR RECON (${g.radar_left_p1})' }
		draw_text_centered(renderer, 820, panel_y + 50, radar_label, 1, Color{r:255,g:255,b:255})
	}

	// Status Message Ticker at Bottom
	draw_beveled_box(renderer, 24, h - 45, w - 48, 32, Color{r:12,g:16,b:22}, col_radar_green, Color{r:5,g:8,b:10})
	draw_text_centered(renderer, w / 2, h - 34, g.status_message, 1, col_radar_green)
}

fn render_warship_sprite(renderer &Renderer, s Ship, ship_idx int, gx int, gy int, grid_pix int, tex &Texture) {
	if tex == unsafe { nil } {
		return
	}

	// Row and size for ship sprite
	// Carrier (idx 0, size 5, 160x32): Row 0 (Y=0)
	// Battleship (idx 1, size 4, 128x32): Row 2 (Y=64)
	// Cruiser (idx 2, size 3, 96x32): Row 4 (Y=128)
	// Submarine (idx 3, size 3, 96x32): Row 6 (Y=192)
	// Destroyer (idx 4, size 2, 64x32): Row 8 (Y=256)
	mut src_y := 0
	match ship_idx {
		0 { src_y = if s.is_sunk { 32 } else { 0 } }
		1 { src_y = if s.is_sunk { 96 } else { 64 } }
		2 { src_y = if s.is_sunk { 160 } else { 128 } }
		3 { src_y = if s.is_sunk { 224 } else { 192 } }
		4 { src_y = if s.is_sunk { 288 } else { 256 } }
		else { src_y = 0 }
	}

	src_w := s.size * 32
	src_h := 32
	src_rect := Rect{0, src_y, src_w, src_h}

	px := gx + s.x * grid_pix
	py := gy + s.y * grid_pix

	if s.horizontal {
		dst_rect := Rect{px, py, s.size * grid_pix, grid_pix}
		render_copy(renderer, tex, &src_rect, &dst_rect)
	} else {
		// Vertical rotation: rotate 90 degrees with center pivot
		dst_rect := Rect{
			px - (s.size * grid_pix - grid_pix) / 2,
			py + (s.size * grid_pix - grid_pix) / 2,
			s.size * grid_pix,
			grid_pix
		}
		center := Point{ (s.size * grid_pix) / 2, grid_pix / 2 }
		render_copy_ex(renderer, tex, &src_rect, &dst_rect, 90.0, &center, .none)
	}
}
