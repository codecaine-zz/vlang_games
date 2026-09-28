module main

import time
import math

pub struct Button {
pub mut:
	x            int
	y            int
	w            int
	h            int
	text         string
	bg_color     Color
	hover_color  Color
	text_color   Color
	border_color Color
}

pub fn (b Button) contains(mx int, my int) bool {
	return mx >= b.x && mx <= b.x + b.w && my >= b.y && my <= b.y + b.h
}

pub fn (b Button) draw(renderer &Renderer, mx int, my int) {
	is_hover := b.contains(mx, my)
	bg := if is_hover { b.hover_color } else { b.bg_color }

	rect := Rect{ x: b.x, y: b.y, w: b.w, h: b.h }
	set_render_draw_color(renderer, bg.r, bg.g, bg.b, bg.a)
	render_fill_rect(renderer, &rect)

	// Top/Left Neon Bevel
	br := if is_hover { b.border_color } else { Color{ r: u8(math_min(int(bg.r) + 50, 255)), g: u8(math_min(int(bg.g) + 50, 255)), b: u8(math_min(int(bg.b) + 50, 255)) } }
	set_render_draw_color(renderer, br.r, br.g, br.b, 255)
	render_draw_line(renderer, b.x, b.y, b.x + b.w, b.y)
	render_draw_line(renderer, b.x, b.y, b.x, b.y + b.h)

	// Border outline
	set_render_draw_color(renderer, b.border_color.r, b.border_color.g, b.border_color.b, b.border_color.a)
	render_draw_rect(renderer, &rect)

	text_scale := if b.text.len * 16 > b.w - 10 { 1 } else { 2 }
	text_h := 8 * text_scale
	draw_text_centered(renderer, b.x + b.w / 2, b.y + (b.h - text_h) / 2, b.text, text_scale, b.text_color)
}

fn math_min(a int, b int) int {
	return if a < b { a } else { b }
}

// --------------------------------------------------
// Main Masterpiece Render Loop
// --------------------------------------------------

pub fn draw_game(
	renderer &Renderer,
	game Game,
	mx int,
	my int,
	btn_editor Button,
	btn_restart Button,
	btn_sound Button,
	btn_prev Button,
	btn_next Button,
	btn_test Button,
	btn_clear Button,
	btn_undo Button,
	btn_level_select Button,
	btn_ghost Button,
	btn_map Button,
	btn_manual Button
) {
	ticks := u32(time.ticks())

	// 1. Dark Cyber Backdrop with Ambient Grid
	draw_cyber_backdrop(renderer, ticks)

	// 2. Holographic Top HUD Header Bar
	draw_hud_header(renderer, game, ticks)

	// 3. Main Cyber Playfield (Dynamic grid_size scaling)
	draw_playfield(renderer, game, ticks)

	// 4. Laser Rays & Aim Sightlines
	draw_lasers(renderer, game, ticks)

	// 5. Holographic Ghost Guide Conduit
	if game.ghost.active {
		draw_ghost_conduit(renderer, game, ticks)
	}

	// 6. Particles & Floating Texts
	draw_particles(renderer, game)

	// 7. Right Control Sidebar
	draw_sidebar(renderer, mx, my, btn_ghost, btn_undo, btn_restart, btn_prev, btn_next, btn_level_select, btn_map, btn_manual, btn_editor, btn_sound)

	// 8. Modals & Overlays
	if game.level_selector_open {
		draw_level_selector_modal(renderer, game, mx, my)
	} else if game.sector_map_open {
		draw_sector_map_modal(renderer, game, mx, my)
	} else if game.field_manual_open {
		draw_field_manual_modal(renderer, game, mx, my)
	} else if game.status == .stage_cleared {
		draw_stage_cleared_banner(renderer, game, ticks)
	} else if game.status == .lost {
		draw_lost_banner(renderer, game, ticks)
	} else if game.status == .won {
		draw_campaign_victory(renderer, game, ticks)
	}

	// 9. Status Toast Message
	if game.status_msg_timer > 0 {
		draw_status_toast(renderer, game.status_msg)
	}

	// 10. Subtle Cyber CRT Scanlines
	draw_crt_scanlines(renderer)
}

// --------------------------------------------------
// Backdrop & Atmosphere
// --------------------------------------------------

fn draw_cyber_backdrop(renderer &Renderer, ticks u32) {
	set_render_draw_color(renderer, 5, 8, 16, 255)
	render_clear(renderer)

	// Grid pattern
	set_render_draw_color(renderer, 10, 18, 32, 255)
	for x := 0; x < win_w; x += 32 {
		render_draw_line(renderer, x, 0, x, win_h)
	}
	for y := 0; y < win_h; y += 32 {
		render_draw_line(renderer, 0, y, win_w, y)
	}

	// Ambient pulsing stars / data motes
	for i in 0 .. 16 {
		sx := (i * 61 + int(ticks / 25)) % win_w
		sy := (i * 47 + int(ticks / 35)) % win_h
		set_render_draw_color(renderer, 0, 180, 255, 120)
		render_draw_point(renderer, sx, sy)
	}
}

fn draw_crt_scanlines(renderer &Renderer) {
	set_render_draw_color(renderer, 0, 0, 0, 35)
	for y := 0; y < win_h; y += 3 {
		render_draw_line(renderer, 0, y, win_w, y)
	}
}

// --------------------------------------------------
// HUD Header Bar
// --------------------------------------------------

fn draw_hud_header(renderer &Renderer, game Game, _ticks u32) {
	// Top Header Bar Container
	set_render_draw_color(renderer, 8, 14, 26, 240)
	render_fill_rect(renderer, &Rect{ x: 0, y: 0, w: win_w, h: 64 })

	set_render_draw_color(renderer, 0, 240, 255, 200)
	render_draw_line(renderer, 0, 63, win_w, 63)
	render_draw_line(renderer, 0, 64, win_w, 64)

	// Game Title & Sector Lore
	sector_num, sector_title := get_sector_for_stage(game.active_level.id)
	draw_text(renderer, 20, 14, 'ADVENTURES OF LOLO // CYBERPUNK REMASTER', 1, Color{ r: 0, g: 240, b: 255 })
	stage_title := 'SECTOR ${sector_num}: ${sector_title.to_upper()} - STAGE ${game.active_level.id}: ${game.active_level.name.to_upper()}'
	draw_text(renderer, 20, 34, stage_title, 1, Color{ r: 255, g: 215, b: 0 })

	// Status Pills on Top Right
	pill_x := 560
	rem_hearts := game.count_remaining_hearts()
	tot_hearts := game.count_total_hearts()
	draw_hud_pill(renderer, pill_x, 14, 85, 36, 'CORES', '${rem_hearts}/${tot_hearts}', Color{ r: 255, g: 40, b: 100 })
	draw_hud_pill(renderer, pill_x + 95, 14, 75, 36, 'AMMO', '${game.lolo.ammo}', Color{ r: 0, g: 240, b: 255 })
	draw_hud_pill(renderer, pill_x + 180, 14, 75, 36, 'MOVES', '${game.moves_count}', Color{ r: 0, g: 255, b: 150 })
	
	secs := int(game.time_elapsed)
	min := secs / 60
	s := secs % 60
	time_str := '${min:02d}:${s:02d}'
	draw_hud_pill(renderer, pill_x + 265, 14, 80, 36, 'TIME', time_str, Color{ r: 255, g: 190, b: 40 })
}

fn draw_hud_pill(renderer &Renderer, x int, y int, w int, h int, label string, val string, col Color) {
	set_render_draw_color(renderer, 14, 22, 38, 255)
	render_fill_rect(renderer, &Rect{ x: x, y: y, w: w, h: h })
	set_render_draw_color(renderer, col.r, col.g, col.b, 200)
	render_draw_rect(renderer, &Rect{ x: x, y: y, w: w, h: h })

	draw_text(renderer, x + 6, y + 5, label, 1, Color{ r: 160, g: 180, b: 210 })
	draw_text(renderer, x + 6, y + 18, val, 1, col)
}

// --------------------------------------------------
// Main Playfield & Tile Rendering
// --------------------------------------------------

fn draw_playfield(renderer &Renderer, game Game, ticks u32) {
	grid_sz := game.grid_size
	cell_sz := int(520.0 / f32(grid_sz))
	board_w := grid_sz * cell_sz
	board_h := grid_sz * cell_sz
	shake_x := int(game.screen_shake * f32(math.sin(f64(ticks) / 20.0)))
	shake_y := int(game.screen_shake * f32(math.cos(f64(ticks) / 20.0)))
	start_x := 24 + (520 - board_w) / 2 + shake_x
	start_y := 80 + (520 - board_h) / 2 + shake_y

	// Outer Chamber Frame
	set_render_draw_color(renderer, 10, 16, 28, 255)
	render_fill_rect(renderer, &Rect{ x: start_x - 6, y: start_y - 6, w: board_w + 12, h: board_h + 12 })
	set_render_draw_color(renderer, 0, 240, 255, 180)
	render_draw_rect(renderer, &Rect{ x: start_x - 6, y: start_y - 6, w: board_w + 12, h: board_h + 12 })

	// Draw Tiles
	for r in 0 .. grid_sz {
		for c in 0 .. grid_sz {
			tx := start_x + c * cell_sz
			ty := start_y + r * cell_sz
			tile := game.grid[r][c]
			draw_tile(renderer, tx, ty, cell_sz, tile, game.anim_tick, game.blink_phase, game.pressure_plates, r, c)
		}
	}

	// Draw Blocks
	for b in game.blocks {
		bx := start_x + int(b.render_x * f32(cell_sz))
		by := start_y + int(b.render_y * f32(cell_sz))
		draw_block(renderer, bx, by, cell_sz, b.typ, b.dir, game.anim_tick)
	}

	// Draw Enemies with rich character models and animations
	for e in game.enemies {
		if e.is_vaporized { continue }
		ex := start_x + int(e.render_x * f32(cell_sz))
		ey := start_y + int(e.render_y * f32(cell_sz))
		draw_enemy(renderer, ex, ey, cell_sz, e, game.anim_tick, game.count_remaining_hearts() == 0)
	}

	// Draw Lolo with rich expressive animations
	lx := start_x + int(game.lolo.render_x * f32(cell_sz))
	ly := start_y + int(game.lolo.render_y * f32(cell_sz))
	draw_lolo(renderer, lx, ly, cell_sz, game)
}

fn draw_tile(renderer &Renderer, x int, y int, sz int, tile TileType, anim_tick u32, blink_phase bool, plates PressurePlates, r int, c int) {
	rect := Rect{ x: x, y: y, w: sz, h: sz }
	cx := f32(x) + f32(sz) / 2.0
	cy := f32(y) + f32(sz) / 2.0
	size := f32(sz)

	match tile {
		.floor {
			// Carbon-Composite Floor with nano-grid seams
			set_render_draw_color(renderer, 9, 14, 26, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 15, 23, 42, 255)
			render_draw_rect(renderer, &rect)

			// Animated Micro-Circuit Energy Pulse traveling along floor grid
			circuit_pulse := math.sin(f64(anim_tick) * 0.04 + f64(r) * 0.8 + f64(c) * 1.2)
			if circuit_pulse > 0.72 {
				c_alpha := u8(math.min(255, int((circuit_pulse - 0.72) * 2.8 * 200.0)))
				set_render_draw_color(renderer, 0, 240, 255, c_alpha)
				render_draw_line(renderer, x + 2, int(cy), int(cx), int(cy))
				render_draw_line(renderer, int(cx), int(cy), int(cx), y + sz - 2)
				set_render_draw_color(renderer, 56, 189, 248, 255)
				render_fill_rect(renderer, &Rect{ x: int(cx - 1), y: int(cy - 1), w: 2, h: 2 })
			}

			// Specular corner rivets
			set_render_draw_color(renderer, 56, 189, 248, 50)
			render_fill_rect(renderer, &Rect{ x: x + 2, y: y + 2, w: 1, h: 1 })
			render_fill_rect(renderer, &Rect{ x: x + sz - 3, y: y + 2, w: 1, h: 1 })
			render_fill_rect(renderer, &Rect{ x: x + 2, y: y + sz - 3, w: 1, h: 1 })
			render_fill_rect(renderer, &Rect{ x: x + sz - 3, y: y + sz - 3, w: 1, h: 1 })
		}
		.wall {
			// 3D Volumetric Reinforced Titanium Blast Block with Bevels
			set_render_draw_color(renderer, 2, 6, 18, 190)
			render_fill_rect(renderer, &Rect{ x: x + 2, y: y + 2, w: sz, h: sz })

			// Fortified Beveled Body
			set_render_draw_color(renderer, 15, 23, 42, 255)
			render_fill_rect(renderer, &Rect{ x: x, y: y, w: sz - 1, h: sz - 1 })

			// Specular Highlight Bevel (Top-Left)
			set_render_draw_color(renderer, 255, 255, 255, 70)
			render_draw_line(renderer, x, y + sz - 1, x, y)
			render_draw_line(renderer, x, y, x + sz - 1, y)

			// Deep Shadow Bevel (Bottom-Right)
			set_render_draw_color(renderer, 0, 0, 0, 180)
			render_draw_line(renderer, x + sz - 1, y, x + sz - 1, y + sz - 1)
			render_draw_line(renderer, x, y + sz - 1, x + sz - 1, y + sz - 1)

			// Inner Armored Steel Plate
			set_render_draw_color(renderer, 23, 37, 84, 255)
			render_fill_rect(renderer, &Rect{ x: x + 4, y: y + 4, w: sz - 8, h: sz - 8 })

			// Hex rivets with animated status flicker
			led_blink := math.sin(f64(anim_tick) * 0.08 + f64(r * 2 + c * 3)) > 0.6
			led_col := if led_blink { Color{ r: 56, g: 189, b: 248 } } else { Color{ r: 2, g: 132, b: 199 } }
			set_render_draw_color(renderer, led_col.r, led_col.g, led_col.b, 255)
			render_fill_rect(renderer, &Rect{ x: x + 5, y: y + 5, w: 2, h: 2 })
			render_fill_rect(renderer, &Rect{ x: x + sz - 7, y: y + 5, w: 2, h: 2 })
			render_fill_rect(renderer, &Rect{ x: x + 5, y: y + sz - 7, w: 2, h: 2 })
			render_fill_rect(renderer, &Rect{ x: x + sz - 7, y: y + sz - 7, w: 2, h: 2 })

			// Center Recessed Pulsing Neon Datalink Conduit
			conduit_a := u8(100 + int(math.sin(f64(anim_tick) * 0.1 + f64(r + c)) * 60.0))
			set_render_draw_color(renderer, 0, 240, 255, conduit_a)
			render_draw_line(renderer, x + 7, int(cy), x + sz - 7, int(cy))
		}
		.tree {
			// Emerald Cyber-Biosphere Canopy
			set_render_draw_color(renderer, 6, 12, 24, 255)
			render_fill_rect(renderer, &rect)

			// Outer Bioluminescent Canopy Ring
			set_render_draw_color(renderer, 5, 150, 105, 255)
			render_fill_circle(renderer, cx, cy, size * 0.38)
			set_render_draw_color(renderer, 52, 211, 153, 255)
			render_draw_circle(renderer, cx, cy, size * 0.38)

			// Inner Emerald Foliage Diamond
			set_render_draw_color(renderer, 16, 185, 129, 255)
			render_fill_polygon(renderer, cx, cy, size * 0.24, 4, 45.0)

			// Bio-Scanner Pulsing Center
			b_pulse := f32(math.sin(f64(anim_tick) * 0.15) * 1.5)
			set_render_draw_color(renderer, 167, 243, 208, 255)
			render_fill_circle(renderer, cx, cy, 3.0 + b_pulse)
		}
		.water {
			// Animated Fluid Ripples with Wave Kinematics
			wave := f32(math.sin(f64(anim_tick) * 0.08 + f64(x + y) * 0.05) * 4.0)
			set_render_draw_color(renderer, 2, 132, 199, 255)
			render_fill_rect(renderer, &rect)

			// Deep refractive trench
			set_render_draw_color(renderer, 3, 105, 161, 255)
			render_fill_rect(renderer, &Rect{ x: x + 2, y: int(cy - 4 + wave), w: sz - 4, h: 8 })

			// Dynamic Ripple Caustics
			set_render_draw_color(renderer, 186, 230, 253, 200)
			render_draw_line(renderer, x + 3, int(cy + wave), x + sz - 3, int(cy + wave))
			render_draw_line(renderer, x + 5, int(cy + 6 - wave), x + sz - 5, int(cy + 6 - wave))
		}
		.lava {
			// Incandescent Magma Fissure
			glow := f32(math.sin(f64(anim_tick) * 0.12 + f64(x + y) * 0.08) * 15.0)
			set_render_draw_color(renderer, u8(math.min(255, 200 + int(glow))), 30, 10, 255)
			render_fill_rect(renderer, &rect)

			// Molten Core Fissure
			set_render_draw_color(renderer, 251, 146, 60, 255)
			render_fill_circle(renderer, cx, cy, size * 0.28)

			// Blazing Solar Center
			set_render_draw_color(renderer, 254, 240, 138, 255)
			render_fill_circle(renderer, cx, cy, size * 0.14)

			// Bubbling Heat Embers
			if anim_tick % 4 == 0 {
				set_render_draw_color(renderer, 255, 255, 255, 220)
				render_fill_circle(renderer, cx + f32((anim_tick % 11) - 5), cy - 4, 1.5)
			}
		}
		.slime {
			// Bio-Hazard Nanite Slime Pool
			set_render_draw_color(renderer, 20, 83, 45, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 74, 222, 128, 200)
			render_fill_circle(renderer, cx, cy, size * 0.32)
			set_render_draw_color(renderer, 187, 247, 208, 255)
			render_fill_circle(renderer, cx - 3, cy - 3, 2.5)
		}
		.sand {
			set_render_draw_color(renderer, 120, 53, 15, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 217, 119, 6, 120)
			render_draw_rect(renderer, &Rect{ x: x + 2, y: y + 2, w: sz - 4, h: sz - 4 })
		}
		.grass, .high_grass {
			set_render_draw_color(renderer, 6, 78, 59, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 16, 185, 129, 255)
			render_draw_line(renderer, int(cx), int(cy - 6), int(cx), int(cy + 6))
			render_draw_line(renderer, int(cx - 5), int(cy), int(cx + 5), int(cy))
		}
		.ice {
			// Crystal-Sheen Ice Slab
			set_render_draw_color(renderer, 30, 58, 138, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 186, 230, 253, 255)
			render_draw_rect(renderer, &rect)
			// Reflective Sheen Angle
			set_render_draw_color(renderer, 255, 255, 255, 180)
			render_draw_line(renderer, x + 4, y + sz - 4, x + sz - 4, y + 4)
			render_draw_line(renderer, x + 8, y + sz - 4, x + sz - 4, y + 8)
		}
		.cracked_wall {
			// Fissured Blast Wall
			set_render_draw_color(renderer, 30, 41, 59, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 249, 115, 22, 255)
			render_draw_line(renderer, x + 4, y + 4, int(cx), int(cy))
			render_draw_line(renderer, int(cx), int(cy), x + sz - 6, y + 6)
			render_draw_line(renderer, int(cx), int(cy), x + 6, y + sz - 6)
			render_draw_line(renderer, int(cx), int(cy), x + sz - 4, y + sz - 4)
		}
		.heart, .heart_ammo {
			set_render_draw_color(renderer, 9, 14, 26, 255)
			render_fill_rect(renderer, &rect)

			// Pulsing Cyber-Heart Memory Core
			pulse := f32(math.sin(f64(anim_tick) * 0.12) * 2.0)
			hr := size * 0.26 + pulse

			// Outer Crimson Aura
			set_render_draw_color(renderer, 244, 63, 94, 200)
			render_fill_circle(renderer, cx - hr * 0.35, cy - hr * 0.2, hr * 0.45)
			render_fill_circle(renderer, cx + hr * 0.35, cy - hr * 0.2, hr * 0.45)
			render_fill_triangle(renderer, cx - hr * 0.8, cy - hr * 0.1, cx + hr * 0.8, cy - hr * 0.1, cx, cy + hr * 0.8)

			// Radiant Core Highlight
			set_render_draw_color(renderer, 255, 255, 255, 220)
			render_fill_circle(renderer, cx - hr * 0.3, cy - hr * 0.25, 2.5)

			// Ammo indicator ring
			if tile == .heart_ammo {
				set_render_draw_color(renderer, 0, 240, 255, 255)
				render_draw_circle(renderer, cx, cy, size * 0.42)
			}
		}
		.chest_closed {
			// Golden Security Vault
			set_render_draw_color(renderer, 30, 41, 59, 255)
			render_fill_rounded_rect(renderer, cx - size * 0.38, cy - size * 0.32, size * 0.76, size * 0.64, 4.0)
			set_render_draw_color(renderer, 234, 179, 8, 255)
			render_draw_rounded_rect(renderer, cx - size * 0.38, cy - size * 0.32, size * 0.76, size * 0.64, 4.0)

			// Status beacon LED
			set_render_draw_color(renderer, 250, 204, 21, 255)
			render_fill_circle(renderer, cx, cy, size * 0.12)
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_circle(renderer, cx, cy, 3.0)
		}
		.chest_opened {
			// Open Golden Vault with Holographic Core
			set_render_draw_color(renderer, 234, 179, 8, 255)
			render_fill_rounded_rect(renderer, cx - size * 0.38, cy - size * 0.32, size * 0.76, size * 0.64, 4.0)
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_circle(renderer, cx, cy, size * 0.22)
			set_render_draw_color(renderer, 0, 240, 255, 255)
			render_draw_circle(renderer, cx, cy, size * 0.28)
		}
		.door_closed {
			// Heavy Blast Door with Crimson Laser Lock
			set_render_draw_color(renderer, 15, 23, 42, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 244, 63, 94, 255)
			render_draw_rect(renderer, &rect)
			render_draw_line(renderer, x + 4, int(cy), x + sz - 4, int(cy))
			render_fill_circle(renderer, cx, cy, 4.0)
		}
		.door_open {
			// Radiant Open Cyan Gate
			set_render_draw_color(renderer, 0, 240, 255, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rounded_rect(renderer, cx - size * 0.30, cy - size * 0.30, size * 0.60, size * 0.60, 3.0)
		}
		.portal_a {
			// Quantum Wormhole Cyan
			p_rot := f64(anim_tick) * 0.1
			set_render_draw_color(renderer, 9, 14, 26, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 0, 240, 255, 255)
			render_fill_circle(renderer, cx, cy, size * 0.32)
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_circle(renderer, cx, cy, size * 0.16)
			// Rotating vortex arms
			set_render_draw_color(renderer, 186, 230, 253, 200)
			render_draw_line(renderer, int(cx - size * 0.35 * f32(math.cos(p_rot))), int(cy - size * 0.35 * f32(math.sin(p_rot))), int(cx + size * 0.35 * f32(math.cos(p_rot))), int(cy + size * 0.35 * f32(math.sin(p_rot))))
		}
		.portal_b {
			// Quantum Wormhole Magenta
			p_rot := -f64(anim_tick) * 0.1
			set_render_draw_color(renderer, 9, 14, 26, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 244, 63, 94, 255)
			render_fill_circle(renderer, cx, cy, size * 0.32)
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_circle(renderer, cx, cy, size * 0.16)
			// Rotating vortex arms
			set_render_draw_color(renderer, 254, 205, 211, 200)
			render_draw_line(renderer, int(cx - size * 0.35 * f32(math.cos(p_rot))), int(cy - size * 0.35 * f32(math.sin(p_rot))), int(cx + size * 0.35 * f32(math.cos(p_rot))), int(cy + size * 0.35 * f32(math.sin(p_rot))))
		}
		.pressure_plate_cyan {
			set_render_draw_color(renderer, 15, 23, 42, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 0, 240, 255, 255)
			render_draw_rounded_rect(renderer, cx - size * 0.32, cy - size * 0.32, size * 0.64, size * 0.64, 3.0)
			render_fill_circle(renderer, cx, cy, 3.5)
		}
		.pressure_plate_magenta {
			set_render_draw_color(renderer, 15, 23, 42, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 244, 63, 94, 255)
			render_draw_rounded_rect(renderer, cx - size * 0.32, cy - size * 0.32, size * 0.64, size * 0.64, 3.0)
			render_fill_circle(renderer, cx, cy, 3.5)
		}
		.laser_gate_cyan {
			set_render_draw_color(renderer, 9, 14, 26, 255)
			render_fill_rect(renderer, &rect)
			if !plates.cyan {
				set_render_draw_color(renderer, 0, 240, 255, 255)
				render_draw_line(renderer, int(cx), y, int(cx), y + sz)
				set_render_draw_color(renderer, 255, 255, 255, 255)
				render_draw_line(renderer, int(cx - 1), y, int(cx - 1), y + sz)
			}
		}
		.laser_gate_magenta {
			set_render_draw_color(renderer, 9, 14, 26, 255)
			render_fill_rect(renderer, &rect)
			if !plates.magenta {
				set_render_draw_color(renderer, 244, 63, 94, 255)
				render_draw_line(renderer, int(cx), y, int(cx), y + sz)
				set_render_draw_color(renderer, 255, 255, 255, 255)
				render_draw_line(renderer, int(cx - 1), y, int(cx - 1), y + sz)
			}
		}
		.blink_floor {
			if blink_phase {
				set_render_draw_color(renderer, 2, 132, 199, 255)
				render_fill_rect(renderer, &rect)
				set_render_draw_color(renderer, 56, 189, 248, 255)
				render_draw_rect(renderer, &rect)
			} else {
				set_render_draw_color(renderer, 4, 7, 14, 255)
				render_fill_rect(renderer, &rect)
			}
		}
		.turret_socket {
			set_render_draw_color(renderer, 30, 41, 59, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 148, 163, 184, 255)
			render_draw_rect(renderer, &rect)
			render_draw_circle(renderer, cx, cy, size * 0.28)
		}
		.one_way_up, .one_way_down, .one_way_left, .one_way_right {
			set_render_draw_color(renderer, 15, 23, 42, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 0, 240, 255, 220)
			mid := sz / 2
			match tile {
				.one_way_up {
					render_draw_line(renderer, x + mid, y + 4, x + 4, y + sz - 6)
					render_draw_line(renderer, x + mid, y + 4, x + sz - 4, y + sz - 6)
				}
				.one_way_down {
					render_draw_line(renderer, x + mid, y + sz - 4, x + 4, y + 6)
					render_draw_line(renderer, x + mid, y + sz - 4, x + sz - 4, y + 6)
				}
				.one_way_left {
					render_draw_line(renderer, x + 4, y + mid, x + sz - 6, y + 4)
					render_draw_line(renderer, x + 4, y + mid, x + sz - 6, y + sz - 4)
				}
				.one_way_right {
					render_draw_line(renderer, x + sz - 4, y + mid, x + 6, y + 4)
					render_draw_line(renderer, x + sz - 4, y + mid, x + 6, y + sz - 4)
				}
				else {}
			}
		}
		else {
			set_render_draw_color(renderer, 9, 14, 26, 255)
			render_fill_rect(renderer, &rect)
		}
	}
}

fn draw_block(renderer &Renderer, x int, y int, sz int, typ BlockType, dir string, anim_tick u32) {
	cx := f32(x) + f32(sz) / 2.0
	cy := f32(y) + f32(sz) / 2.0
	size := f32(sz)

	match typ {
		.reflector {
			// Polished Prismatic Reflector Block
			set_render_draw_color(renderer, 15, 23, 42, 255)
			render_fill_rounded_rect(renderer, f32(x + 2), f32(y + 2), size - 4, size - 4, 3.0)
			set_render_draw_color(renderer, 0, 240, 255, 255)
			render_draw_rounded_rect(renderer, f32(x + 2), f32(y + 2), size - 4, size - 4, 3.0)

			// 45° Reflector Mirror Beam
			set_render_draw_color(renderer, 255, 255, 255, 255)
			if dir == 'up_right' || dir == 'down_left' {
				render_draw_line(renderer, x + 4, y + sz - 6, x + sz - 6, y + 4)
				render_draw_line(renderer, x + 5, y + sz - 6, x + sz - 6, y + 5)
			} else {
				render_draw_line(renderer, x + 4, y + 4, x + sz - 6, y + sz - 6)
				render_draw_line(renderer, x + 5, y + 4, x + sz - 6, y + sz - 5)
			}
		}
		.bomb {
			// Nitro Demolition Explosive
			set_render_draw_color(renderer, 185, 28, 28, 255)
			render_fill_rounded_rect(renderer, f32(x + 2), f32(y + 2), size - 4, size - 4, 3.0)
			// Hazard warning stripes
			set_render_draw_color(renderer, 250, 204, 21, 255)
			render_draw_line(renderer, x + 6, y + sz - 6, x + sz - 6, y + 6)
			render_draw_line(renderer, x + 10, y + sz - 6, x + sz - 6, y + 10)

			// Pulsing core detonator LED
			b_pulse := f32(math.sin(f64(anim_tick) * 0.3) * 1.5)
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_circle(renderer, cx, cy, 3.5 + b_pulse)
		}
		.heavy {
			// Tungsten Heavy Push Block
			set_render_draw_color(renderer, 30, 41, 59, 255)
			render_fill_rounded_rect(renderer, f32(x + 2), f32(y + 2), size - 4, size - 4, 3.0)
			set_render_draw_color(renderer, 100, 116, 139, 255)
			render_draw_rounded_rect(renderer, f32(x + 2), f32(y + 2), size - 4, size - 4, 3.0)
			// Heavy industrial cross
			set_render_draw_color(renderer, 71, 85, 105, 255)
			render_draw_line(renderer, x + 6, y + 6, x + sz - 6, y + sz - 6)
			render_draw_line(renderer, x + sz - 6, y + 6, x + 6, y + sz - 6)
		}
		else {
			// Alloy Standard Movable Block
			set_render_draw_color(renderer, 30, 58, 138, 255)
			render_fill_rounded_rect(renderer, f32(x + 2), f32(y + 2), size - 4, size - 4, 3.0)
			set_render_draw_color(renderer, 56, 189, 248, 255)
			render_draw_rounded_rect(renderer, f32(x + 2), f32(y + 2), size - 4, size - 4, 3.0)

			// Inner Core Plate
			set_render_draw_color(renderer, 14, 165, 233, 200)
			render_fill_rounded_rect(renderer, cx - size * 0.22, cy - size * 0.22, size * 0.44, size * 0.44, 2.0)
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_circle(renderer, cx, cy, 2.5)
		}
	}
}

fn draw_egg(renderer &Renderer, x int, y int, sz int, timer f64, anim_tick u32) {
	size := f32(sz)
	cx := f32(x) + size / 2.0
	cy := f32(y) + size / 2.0

	pulse := 1.0 + f32(math.sin(f64(anim_tick) * 0.22) * 0.05)
	is_expiring := timer < 5.0
	is_flash := is_expiring && (anim_tick % 10 < 5)
	egg_col := if is_flash { Color{ r: 244, g: 63, b: 94 } } else { Color{ r: 0, g: 240, b: 255 } }
	egg_core := if is_flash { Color{ r: 253, g: 164, b: 175 } } else { Color{ r: 207, g: 250, b: 254 } }

	ew := (size * 0.30) * pulse
	eh := (size * 0.40) * pulse

	// 1. Soft Ambient Ground Contact Shadow
	set_render_draw_color(renderer, 2, 6, 18, 160)
	render_fill_ellipse(renderer, cx, cy + size * 0.38, size * 0.32, size * 0.10)

	// 2. High-Tech Polycarbonate Bio-Stasis Capsule Chamber
	body_col := if is_flash { Color{ r: 190, g: 18, b: 60 } } else { Color{ r: 2, g: 132, b: 199 } }
	set_render_draw_color(renderer, body_col.r, body_col.g, body_col.b, 180)
	render_fill_ellipse(renderer, cx, cy, ew, eh)

	// Inner Stasis Core
	set_render_draw_color(renderer, egg_core.r, egg_core.g, egg_core.b, 140)
	render_fill_ellipse(renderer, cx, cy, ew * 0.7, eh * 0.7)

	// Outer Cryo-Barrier Rim
	set_render_draw_color(renderer, egg_col.r, egg_col.g, egg_col.b, 255)
	render_draw_ellipse(renderer, cx, cy, ew, eh)

	// 3. Top & Bottom Titanium Containment Bulkhead Collars
	collar_w := ew * 1.5
	collar_h := size * 0.09
	// Top collar
	set_render_draw_color(renderer, 100, 116, 139, 255)
	render_fill_rounded_rect(renderer, cx - collar_w / 2.0, cy - eh - 2.0, collar_w, collar_h, 2.0)
	set_render_draw_color(renderer, 255, 255, 255, 180)
	render_draw_rounded_rect(renderer, cx - collar_w / 2.0, cy - eh - 2.0, collar_w, collar_h, 2.0)

	// Bottom collar
	set_render_draw_color(renderer, 100, 116, 139, 255)
	render_fill_rounded_rect(renderer, cx - collar_w / 2.0, cy + eh - collar_h + 2.0, collar_w, collar_h, 2.0)
	set_render_draw_color(renderer, 255, 255, 255, 180)
	render_draw_rounded_rect(renderer, cx - collar_w / 2.0, cy + eh - collar_h + 2.0, collar_w, collar_h, 2.0)

	// Status LEDs on collars
	led_col := if is_flash { Color{ r: 244, g: 63, b: 94 } } else { Color{ r: 56, g: 189, b: 248 } }
	set_render_draw_color(renderer, led_col.r, led_col.g, led_col.b, 255)
	render_fill_rect(renderer, &Rect{ x: int(cx - collar_w * 0.35), y: int(cy - eh), w: 3, h: 3 })
	render_fill_rect(renderer, &Rect{ x: int(cx + collar_w * 0.35 - 3), y: int(cy - eh), w: 3, h: 3 })
	render_fill_rect(renderer, &Rect{ x: int(cx - collar_w * 0.35), y: int(cy + eh - 2), w: 3, h: 3 })
	render_fill_rect(renderer, &Rect{ x: int(cx + collar_w * 0.35 - 3), y: int(cy + eh - 2), w: 3, h: 3 })

	// 4. Trapped Organic Creature Embryo Silhouette with Fluid Breathing Bob
	c_breath := f32(math.sin(f64(anim_tick) * 0.15) * 1.5)
	set_render_draw_color(renderer, 15, 23, 42, 200)
	render_fill_circle(renderer, cx, cy + c_breath, size * 0.15)
	// Embryo optic glint
	glint_col := if is_flash { Color{ r: 255, g: 255, b: 255 } } else { Color{ r: 254, g: 240, b: 138 } }
	set_render_draw_color(renderer, glint_col.r, glint_col.g, glint_col.b, 255)
	render_fill_rect(renderer, &Rect{ x: int(cx - size * 0.05), y: int(cy - 2.0 + c_breath), w: 3, h: 2 })
	render_fill_rect(renderer, &Rect{ x: int(cx + size * 0.02), y: int(cy - 2.0 + c_breath), w: 3, h: 2 })

	// 5. Equatorial Gyroscopic Magnetic Confinement Rings
	band_rot := f32(math.sin(f64(anim_tick) * 0.08) * f64(eh * 0.35))
	set_render_draw_color(renderer, 255, 255, 255, 180)
	render_draw_ellipse(renderer, cx, cy + band_rot, ew * 0.85, size * 0.07)
	set_render_draw_color(renderer, egg_col.r, egg_col.g, egg_col.b, 160)
	render_draw_ellipse(renderer, cx, cy - band_rot, ew * 0.75, size * 0.05)

	// 6. Specular Highlight Arc
	set_render_draw_color(renderer, 255, 255, 255, 140)
	render_fill_ellipse(renderer, cx - ew * 0.45, cy - eh * 0.35, ew * 0.25, size * 0.06)
}

fn draw_enemy(renderer &Renderer, x int, y int, sz int, e Enemy, anim_tick u32, is_awakened bool) {
	if e.is_egg {
		draw_egg(renderer, x, y, sz, e.egg_timer, anim_tick)
		return
	}

	size := f32(sz)
	cx := f32(x) + size / 2.0
	cy := f32(y) + size / 2.0

	match e.typ {
		.snake {
			// Undulating 5-segment tail coils with fluid sinusoidal kinematics
			t := f64(anim_tick) * 0.12
			for s := 4; s >= 1; s-- {
				sx := cx + f32(math.sin(t + f64(s) * 0.9) * f64(size * 0.15))
				sy := cy + (f32(s) * size * 0.085) - size * 0.04
				set_render_draw_color(renderer, 6, 95, 70, 255)
				render_fill_circle(renderer, sx, sy, size * (0.24 - f32(s) * 0.025))
				set_render_draw_color(renderer, 52, 211, 153, 255)
				render_draw_circle(renderer, sx, sy, size * (0.24 - f32(s) * 0.025))
			}

			// Head with breathing bob
			head_bob := f32(math.sin(t) * 2.5)
			hx := cx
			hy := cy - size * 0.08 + head_bob

			// Bio-stasis dashed aura rectangle (tells player it's shootable/pushable)
			set_render_draw_color(renderer, 52, 211, 153, 100)
			render_draw_rounded_rect(renderer, cx - size * 0.36, cy - size * 0.36, size * 0.72, size * 0.72, 4.0)

			// Head armored sphere
			set_render_draw_color(renderer, 5, 150, 105, 255)
			render_fill_circle(renderer, hx, hy, size * 0.22)
			// Emerald scaled armor crown
			set_render_draw_color(renderer, 52, 211, 153, 255)
			render_fill_circle(renderer, hx, hy - size * 0.04, size * 0.14)

			// Docile Green Cyber Eyes
			set_render_draw_color(renderer, 0, 255, 157, 255)
			render_fill_rect(renderer, &Rect{ x: int(hx - size * 0.12), y: int(hy - size * 0.04), w: 4, h: 4 })
			render_fill_rect(renderer, &Rect{ x: int(hx + size * 0.08), y: int(hy - size * 0.04), w: 4, h: 4 })

			// Extending/retracting infrared sensor tongue
			if anim_tick % 60 < 25 {
				set_render_draw_color(renderer, 255, 0, 85, 255)
				render_draw_line(renderer, int(hx), int(hy + size * 0.16), int(hx), int(hy + size * 0.28))
				render_draw_line(renderer, int(hx), int(hy + size * 0.28), int(hx - 3), int(hy + size * 0.33))
				render_draw_line(renderer, int(hx), int(hy + size * 0.28), int(hx + 3), int(hy + size * 0.33))
			}
		}

		.medusa {
			bob := f32(math.sin(f64(anim_tick) * 0.08) * 3.0)
			my := cy + bob

			// 1. Anti-Gravity Magnetic Repulsion Ground Rings
			grav_pulse := f32(f64(anim_tick % 20) / 20.0)
			set_render_draw_color(renderer, 255, 0, 127, 120)
			render_draw_ellipse(renderer, cx, f32(y) + size * 0.88, (size * 0.35) * (0.6 + grav_pulse * 0.4), (size * 0.10) * (0.6 + grav_pulse * 0.4))

			// 2. High-Contrast Cardinal Hazard Brackets [^] [v] [<] [>]
			n_dist := size * 0.42
			set_render_draw_color(renderer, 255, 0, 127, 220)
			// North [^]
			render_draw_line(renderer, int(cx - 5), int(my - n_dist), int(cx), int(my - n_dist - 3))
			render_draw_line(renderer, int(cx), int(my - n_dist - 3), int(cx + 5), int(my - n_dist))
			// South [v]
			render_draw_line(renderer, int(cx - 5), int(my + n_dist), int(cx), int(my + n_dist + 3))
			render_draw_line(renderer, int(cx), int(my + n_dist + 3), int(cx + 5), int(my + n_dist))
			// West [<]
			render_draw_line(renderer, int(cx - n_dist), int(my - 5), int(cx - n_dist - 3), int(my))
			render_draw_line(renderer, int(cx - n_dist - 3), int(my), int(cx - n_dist), int(my + 5))
			// East [>]
			render_draw_line(renderer, int(cx + n_dist), int(my - 5), int(cx + n_dist + 3), int(my))
			render_draw_line(renderer, int(cx + n_dist + 3), int(my), int(cx + n_dist), int(my + 5))

			// 3. 4 Heavy Cardinal Rail Collimators (N, S, E, W)
			set_render_draw_color(renderer, 131, 24, 67, 255)
			// North
			render_fill_rect(renderer, &Rect{ x: int(cx - 4), y: int(my - size * 0.41), w: 8, h: int(size * 0.18) })
			// South
			render_fill_rect(renderer, &Rect{ x: int(cx - 4), y: int(my + size * 0.23), w: 8, h: int(size * 0.18) })
			// West
			render_fill_rect(renderer, &Rect{ x: int(cx - size * 0.41), y: int(my - 4), w: int(size * 0.18), h: 8 })
			// East
			render_fill_rect(renderer, &Rect{ x: int(cx + size * 0.23), y: int(my - 4), w: int(size * 0.18), h: 8 })

			// Collimator plasma sparks
			set_render_draw_color(renderer, 255, 0, 127, 255)
			render_fill_circle(renderer, cx, my - size * 0.40, 2.5)
			render_fill_circle(renderer, cx, my + size * 0.40, 2.5)
			render_fill_circle(renderer, cx - size * 0.40, my, 2.5)
			render_fill_circle(renderer, cx + size * 0.40, my, 2.5)

			// 4. Heavy Spherical Armored Core Hull
			set_render_draw_color(renderer, 30, 27, 75, 255)
			render_fill_circle(renderer, cx, my, size * 0.28)
			set_render_draw_color(renderer, 255, 0, 127, 255)
			render_draw_circle(renderer, cx, my, size * 0.28)

			// Inner concentric crimson shield
			set_render_draw_color(renderer, 80, 7, 36, 255)
			render_fill_circle(renderer, cx, my, size * 0.18)

			// 5. Cardinal [+] Crosshair Reticle in Core
			cr := size * 0.12
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_draw_line(renderer, int(cx), int(my - cr), int(cx), int(my + cr))
			render_draw_line(renderer, int(cx - cr), int(my), int(cx + cr), int(my))

			// Pulsing cardinal laser eye
			eye_pulse := f32(math.sin(f64(anim_tick) * 0.15) * 1.5)
			set_render_draw_color(renderer, 255, 0, 85, 255)
			render_fill_circle(renderer, cx, my, size * 0.07 + eye_pulse)
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_circle(renderer, cx, my, 2.5)
		}

		.medusa_diag {
			bob := f32(math.sin(f64(anim_tick) * 0.08) * 3.0)
			my := cy + bob

			// 1. High-Contrast 4-Corner Diagonal Hazard Chevrons [NW ↖, NE ↗, SW ↙, SE ↘]
			c_dist := size * 0.44
			c_arm := f32(6.0)
			set_render_draw_color(renderer, 192, 132, 252, 230)
			// NW
			render_draw_line(renderer, int(cx - c_dist), int(my - c_dist + c_arm), int(cx - c_dist), int(my - c_dist))
			render_draw_line(renderer, int(cx - c_dist), int(my - c_dist), int(cx - c_dist + c_arm), int(my - c_dist))
			// NE
			render_draw_line(renderer, int(cx + c_dist - c_arm), int(my - c_dist), int(cx + c_dist), int(my - c_dist))
			render_draw_line(renderer, int(cx + c_dist), int(my - c_dist), int(cx + c_dist), int(my - c_dist + c_arm))
			// SW
			render_draw_line(renderer, int(cx - c_dist), int(my + c_dist - c_arm), int(cx - c_dist), int(my + c_dist))
			render_draw_line(renderer, int(cx - c_dist), int(my + c_dist), int(cx - c_dist + c_arm), int(my + c_dist))
			// SE
			render_draw_line(renderer, int(cx + c_dist - c_arm), int(my + c_dist), int(cx + c_dist), int(my + c_dist))
			render_draw_line(renderer, int(cx + c_dist), int(my + c_dist), int(cx + c_dist), int(my + c_dist - c_arm))

			// 2. 4 Heavy Diagonal Rail-Cannon Pylons (45°, 135°, 225°, 315°) forming "✕"
			diag_off := size * 0.28
			set_render_draw_color(renderer, 46, 16, 101, 255)
			render_fill_circle(renderer, cx - diag_off, my - diag_off, 4.5)
			render_fill_circle(renderer, cx + diag_off, my - diag_off, 4.5)
			render_fill_circle(renderer, cx - diag_off, my + diag_off, 4.5)
			render_fill_circle(renderer, cx + diag_off, my + diag_off, 4.5)

			set_render_draw_color(renderer, 217, 70, 239, 255)
			render_draw_line(renderer, int(cx), int(my), int(cx - diag_off), int(my - diag_off))
			render_draw_line(renderer, int(cx), int(my), int(cx + diag_off), int(my - diag_off))
			render_draw_line(renderer, int(cx), int(my), int(cx - diag_off), int(my + diag_off))
			render_draw_line(renderer, int(cx), int(my), int(cx + diag_off), int(my + diag_off))

			// Amethyst Capacitor tips
			set_render_draw_color(renderer, 250, 232, 255, 255)
			render_fill_circle(renderer, cx - diag_off, my - diag_off, 2.5)
			render_fill_circle(renderer, cx + diag_off, my - diag_off, 2.5)
			render_fill_circle(renderer, cx - diag_off, my + diag_off, 2.5)
			render_fill_circle(renderer, cx + diag_off, my + diag_off, 2.5)

			// 3. 8-Sided Octagonal Obsidian-Amethyst Shield Chassis
			set_render_draw_color(renderer, 30, 27, 75, 255)
			render_fill_polygon(renderer, cx, my, size * 0.26, 8, 22.5)
			set_render_draw_color(renderer, 192, 132, 252, 255)
			render_draw_circle(renderer, cx, my, size * 0.24)

			// Inner Amethyst Energy Core
			set_render_draw_color(renderer, 59, 7, 100, 255)
			render_fill_circle(renderer, cx, my, size * 0.15)

			// 4. Static Diagonal Crosshair Reticle [✕] in Core
			rx := size * 0.11
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_draw_line(renderer, int(cx - rx), int(my - rx), int(cx + rx), int(my + rx))
			render_draw_line(renderer, int(cx + rx), int(my - rx), int(cx - rx), int(my + rx))

			// Center radiant violet lens
			set_render_draw_color(renderer, 244, 114, 182, 255)
			render_fill_circle(renderer, cx, my, size * 0.06)
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_circle(renderer, cx, my, 2.5)
		}

		.medusa_omni {
			bob := f32(math.sin(f64(anim_tick) * 0.08) * 3.0)
			my := cy + bob

			// 8 Perimeter Firing Collimators
			for a in 0 .. 8 {
				ang := f64(a) * math.pi / 4.0
				is_diag := (a % 2 != 0)
				col_r := if is_diag { u8(255) } else { u8(0) }
				col_g := if is_diag { u8(0) } else { u8(240) }
				col_b := if is_diag { u8(127) } else { u8(255) }

				px := cx + f32(math.cos(ang) * f64(size * 0.35))
				py := my + f32(math.sin(ang) * f64(size * 0.35))
				set_render_draw_color(renderer, col_r, col_g, col_b, 255)
				render_fill_circle(renderer, px, py, 3.5)
			}

			// Rotating dual-color halo ring
			set_render_draw_color(renderer, 0, 240, 255, 120)
			render_draw_circle(renderer, cx, my, size * 0.38)

			// Heavy Octagonal Apex Fortress Shell
			set_render_draw_color(renderer, 9, 13, 22, 255)
			render_fill_polygon(renderer, cx, my, size * 0.27, 8, 0.0)
			set_render_draw_color(renderer, 56, 189, 248, 255)
			render_draw_circle(renderer, cx, my, size * 0.27)

			// 8-Way Star Reticle [★] in Core
			sr := size * 0.14
			sdr := sr * 0.72
			set_render_draw_color(renderer, 253, 224, 71, 255)
			// +
			render_draw_line(renderer, int(cx), int(my - sr), int(cx), int(my + sr))
			render_draw_line(renderer, int(cx - sr), int(my), int(cx + sr), int(my))
			// ✕
			render_draw_line(renderer, int(cx - sdr), int(my - sdr), int(cx + sdr), int(my + sdr))
			render_draw_line(renderer, int(cx + sdr), int(my - sdr), int(cx - sdr), int(my + sdr))

			// Hyper-matter core
			set_render_draw_color(renderer, 0, 240, 255, 255)
			render_fill_circle(renderer, cx, my, size * 0.08)
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_circle(renderer, cx, my, 3.0)
		}

		.turret {
			// Fortified Hexagonal Base Anchored to Ground
			set_render_draw_color(renderer, 30, 41, 59, 255)
			render_fill_polygon(renderer, cx, cy, size * 0.34, 6, 0.0)
			set_render_draw_color(renderer, 56, 189, 248, 255)
			render_draw_circle(renderer, cx, cy, size * 0.34)

			// Directional Railgun Barrels
			dirs := if e.dirs.len > 0 { e.dirs } else { [e.dir] }
			for d in dirs {
				dx, dy := d.to_offset()
				is_diag := dx != 0 && dy != 0
				b_r := if is_diag { u8(192) } else { u8(56) }
				b_g := if is_diag { u8(132) } else { u8(189) }
				b_b := if is_diag { u8(252) } else { u8(248) }

				// Barrel
				bx := cx + f32(dx) * (size * 0.26)
				by := cy + f32(dy) * (size * 0.26)
				set_render_draw_color(renderer, 3, 105, 161, 255)
				render_fill_rect(renderer, &Rect{ x: int(bx - 3.5), y: int(by - 3.5), w: 7, h: 7 })
				set_render_draw_color(renderer, b_r, b_g, b_b, 255)
				render_draw_rect(renderer, &Rect{ x: int(bx - 3.5), y: int(by - 3.5), w: 7, h: 7 })

				// Glowing Muzzle Tip
				set_render_draw_color(renderer, 0, 240, 255, 255)
				render_fill_circle(renderer, cx + f32(dx) * (size * 0.33), cy + f32(dy) * (size * 0.33), 2.5)

				// Dashed threat guidelines
				set_render_draw_color(renderer, b_r, b_g, b_b, 100)
				render_draw_line(renderer, int(cx + f32(dx) * (size * 0.35)), int(cy + f32(dy) * (size * 0.35)), int(cx + f32(dx) * (size * 0.65)), int(cy + f32(dy) * (size * 0.65)))
			}

			// Center Targeting Turret Dome with Hazard LED
			set_render_draw_color(renderer, 2, 132, 199, 255)
			render_fill_circle(renderer, cx, cy, size * 0.16)
			set_render_draw_color(renderer, 255, 0, 127, 255)
			render_fill_circle(renderer, cx, cy, 3.5)
		}

		.don_medusa {
			bob := f32(math.sin(f64(anim_tick) * 0.10) * 3.0)
			dy := cy + bob

			// Dual Anti-Grav Repulsor Thrusters
			t_pulse := f32(math.sin(f64(anim_tick) * 0.6) * 3.0)
			set_render_draw_color(renderer, 0, 240, 255, 230)
			render_fill_circle(renderer, cx - size * 0.20, dy + size * 0.24 + t_pulse, 5.0)
			render_fill_circle(renderer, cx + size * 0.20, dy + size * 0.24 + t_pulse, 5.0)

			// Heavy Armored Hull with Spiked Blast Wings
			set_render_draw_color(renderer, 30, 27, 75, 255)
			render_fill_rounded_rect(renderer, cx - size * 0.34, dy - size * 0.24, size * 0.68, size * 0.48, 5.0)
			set_render_draw_color(renderer, 255, 0, 85, 255)
			render_draw_rounded_rect(renderer, cx - size * 0.34, dy - size * 0.24, size * 0.68, size * 0.48, 5.0)

			// Motion Vector Direction Arrows on Wings
			is_vert := e.axis == 'vertical' || e.axis == 'y'
			set_render_draw_color(renderer, 56, 189, 248, 255)
			if is_vert {
				render_fill_rect(renderer, &Rect{ x: int(cx - size * 0.28), y: int(dy - 6), w: 3, h: 12 })
				render_fill_rect(renderer, &Rect{ x: int(cx + size * 0.25), y: int(dy - 6), w: 3, h: 12 })
			} else {
				render_fill_rect(renderer, &Rect{ x: int(cx - size * 0.32), y: int(dy - 1.5), w: 12, h: 3 })
				render_fill_rect(renderer, &Rect{ x: int(cx + size * 0.20), y: int(dy - 1.5), w: 12, h: 3 })
			}

			// Sweeping Red Laser Radar Scanner Visor
			set_render_draw_color(renderer, 15, 23, 42, 255)
			render_fill_rect(renderer, &Rect{ x: int(cx - size * 0.24), y: int(dy - size * 0.08), w: int(size * 0.48), h: 8 })
			scan_x := cx + f32(math.sin(f64(anim_tick) * 0.15) * f64(size * 0.18))
			set_render_draw_color(renderer, 255, 0, 85, 255)
			render_fill_rect(renderer, &Rect{ x: int(scan_x - 3.5), y: int(dy - size * 0.08), w: 7, h: 8 })
		}

		.gol {
			// Dragon Head Chassis
			body_col := if is_awakened { Color{ r: 234, g: 88, b: 12 } } else { Color{ r: 51, g: 65, b: 85 } }
			set_render_draw_color(renderer, body_col.r, body_col.g, body_col.b, 255)
			render_fill_rounded_rect(renderer, cx - size * 0.28, cy - size * 0.26, size * 0.56, size * 0.56, 4.0)

			// Dragon Horns
			horn_col := if is_awakened { Color{ r: 249, g: 115, b: 22 } } else { Color{ r: 100, g: 116, b: 139 } }
			set_render_draw_color(renderer, horn_col.r, horn_col.g, horn_col.b, 255)
			render_fill_triangle(renderer, cx - size * 0.20, cy - size * 0.15, cx - size * 0.36, cy - size * 0.36, cx - size * 0.12, cy - size * 0.22)
			render_fill_triangle(renderer, cx + size * 0.20, cy - size * 0.15, cx + size * 0.36, cy - size * 0.36, cx + size * 0.12, cy - size * 0.22)

			if is_awakened {
				// AWAKENED: Blazing Solar Magma Veins & Incinerator Maw
				set_render_draw_color(renderer, 254, 240, 138, 255)
				render_fill_circle(renderer, cx - size * 0.12, cy - size * 0.06, 4.0)
				render_fill_circle(renderer, cx + size * 0.12, cy - size * 0.06, 4.0)

				// Incinerator Maw
				set_render_draw_color(renderer, 185, 28, 28, 255)
				render_fill_rect(renderer, &Rect{ x: int(cx - size * 0.14), y: int(cy + size * 0.08), w: int(size * 0.28), h: int(size * 0.18) })

				// Boiling Fireball Sphere
				fb_size := size * 0.09 + f32(math.sin(f64(anim_tick) * 0.3) * 1.5)
				set_render_draw_color(renderer, 255, 234, 0, 255)
				render_fill_circle(renderer, cx, cy + size * 0.17, fb_size)
				set_render_draw_color(renderer, 255, 255, 255, 255)
				render_fill_circle(renderer, cx, cy + size * 0.17, fb_size * 0.5)
			} else {
				// DORMANT: Sleeping Dragon with closed eyes & floating snooze text
				set_render_draw_color(renderer, 148, 163, 184, 255)
				render_draw_line(renderer, int(cx - size * 0.14), int(cy - size * 0.04), int(cx - size * 0.06), int(cy - size * 0.04))
				render_draw_line(renderer, int(cx + size * 0.06), int(cy - size * 0.04), int(cx + size * 0.14), int(cy - size * 0.04))

				// Soft cooling chest pulse
				set_render_draw_color(renderer, 255, 120, 0, 60)
				render_fill_circle(renderer, cx, cy + size * 0.14, size * 0.10)

				// Floating snooze zZ
				z_float := f32(f64(anim_tick % 25) / 25.0)
				draw_text(renderer, int(cx + size * 0.18 + z_float * 4), int(cy - size * 0.15 - z_float * 10), 'z', 1, Color{ r: 251, g: 191, b: 36 })
				draw_text(renderer, int(cx + size * 0.12 + z_float * 3), int(cy - size * 0.08 - z_float * 8), 'Z', 1, Color{ r: 251, g: 191, b: 36 })
			}
		}

		.skull {
			sk_bob := if is_awakened { f32(math.sin(f64(anim_tick) * 0.35) * 3.0) } else { f32(0.0) }
			sky := cy + sk_bob

			if is_awakened {
				// Rocket booster thruster flames
				flame_h := 6.0 + f32(math.sin(f64(anim_tick) * 0.8) * 3.0)
				set_render_draw_color(renderer, 255, 85, 0, 255)
				render_fill_triangle(renderer, cx - size * 0.16, sky + size * 0.24, cx - size * 0.10, sky + size * 0.24 + flame_h, cx - size * 0.04, sky + size * 0.24)
				render_fill_triangle(renderer, cx + size * 0.04, sky + size * 0.24, cx + size * 0.10, sky + size * 0.24 + flame_h, cx + size * 0.16, sky + size * 0.24)
			} else {
				// Ground pedestal
				set_render_draw_color(renderer, 51, 65, 85, 255)
				render_fill_rect(renderer, &Rect{ x: int(cx - size * 0.20), y: int(cy + size * 0.22), w: int(size * 0.40), h: 4 })
			}

			// Titanium Cranium
			set_render_draw_color(renderer, 241, 245, 249, 255)
			render_fill_circle(renderer, cx, sky - size * 0.04, size * 0.26)

			// Mechanical Jaw & Razor Teeth
			set_render_draw_color(renderer, 203, 213, 225, 255)
			render_fill_rect(renderer, &Rect{ x: int(cx - size * 0.14), y: int(sky + size * 0.12), w: int(size * 0.28), h: int(size * 0.14) })

			// Laser optic eye sockets
			eye_col := if is_awakened { Color{ r: 0, g: 240, b: 255 } } else { Color{ r: 15, g: 23, b: 42 } }
			set_render_draw_color(renderer, eye_col.r, eye_col.g, eye_col.b, 255)
			render_fill_rect(renderer, &Rect{ x: int(cx - size * 0.16), y: int(sky - size * 0.06), w: 7, h: 8 })
			render_fill_rect(renderer, &Rect{ x: int(cx + size * 0.05), y: int(sky - size * 0.06), w: 7, h: 8 })

			if is_awakened {
				// Chattering teeth
				jaw_open := if anim_tick % 12 < 6 { 3 } else { 0 }
				set_render_draw_color(renderer, 15, 23, 42, 255)
				render_fill_rect(renderer, &Rect{ x: int(cx - size * 0.12), y: int(sky + size * 0.16), w: int(size * 0.24), h: 2 + jaw_open })
			}
		}

		.alma {
			// Rapidly Spinning Monowheel Buzzsaw Chassis
			set_render_draw_color(renderer, 30, 64, 175, 255)
			render_fill_circle(renderer, cx, cy, size * 0.28)
			set_render_draw_color(renderer, 96, 165, 250, 255)
			render_draw_circle(renderer, cx, cy, size * 0.28)

			// 8 Tungsten Gear Teeth around perimeter
			rot_base := f64(anim_tick) * 0.25
			set_render_draw_color(renderer, 147, 197, 253, 255)
			for a in 0 .. 8 {
				ang := rot_base + f64(a) * math.pi / 4.0
				tx := cx + f32(math.cos(ang) * f64(size * 0.26))
				ty := cy + f32(math.sin(ang) * f64(size * 0.26))
				render_fill_rect(renderer, &Rect{ x: int(tx - 2.5), y: int(ty - 2.5), w: 5, h: 5 })
			}

			// Ground friction sparks
			if anim_tick % 3 == 0 {
				set_render_draw_color(renderer, 251, 191, 36, 255)
				render_fill_circle(renderer, cx + f32((anim_tick % 7) - 3), f32(y) + size * 0.84, 1.5)
			}

			// Gyro-stabilized Center Eye (Stays upright)
			set_render_draw_color(renderer, 219, 234, 254, 255)
			render_fill_circle(renderer, cx, cy, size * 0.12)
			set_render_draw_color(renderer, 239, 68, 68, 255)
			render_fill_circle(renderer, cx, cy, 3.5)
		}

		.leeper {
			if e.is_asleep {
				// ASLEEP: Heavy Solid Hexagonal EMP Ground Cover Block (0% Battery)
				set_render_draw_color(renderer, 51, 65, 85, 255)
				render_fill_rect(renderer, &Rect{ x: int(cx - size * 0.28), y: int(cy - size * 0.28), w: int(size * 0.56), h: int(size * 0.56) })
				set_render_draw_color(renderer, 100, 116, 139, 255)
				render_draw_rect(renderer, &Rect{ x: int(cx - size * 0.28), y: int(cy - size * 0.28), w: int(size * 0.56), h: int(size * 0.56) })

				// Cooling vent lines
				set_render_draw_color(renderer, 30, 41, 59, 255)
				render_draw_line(renderer, int(cx - size * 0.18), int(cy - 4), int(cx + size * 0.18), int(cy - 4))
				render_draw_line(renderer, int(cx - size * 0.18), int(cy + 4), int(cx + size * 0.18), int(cy + 4))

				// Floating snooze zZ
				lz_float := f32(f64(anim_tick % 20) / 20.0)
				draw_text(renderer, int(cx + size * 0.12 + lz_float * 3), int(cy - size * 0.20 - lz_float * 8), 'zZ', 1, Color{ r: 56, g: 189, b: 248 })

				// Residual blue discharge micro-arc
				if anim_tick % 45 < 6 {
					set_render_draw_color(renderer, 0, 240, 255, 255)
					render_draw_line(renderer, int(cx - size * 0.12), int(cy), int(cx), int(cy - 3))
					render_draw_line(renderer, int(cx), int(cy - 3), int(cx + size * 0.12), int(cy + 2))
				}
			} else {
				// ACTIVE: Bouncing Spring-Hare with Electrostatic Lightning Arcs
				hop := f32(math.abs(math.sin(f64(anim_tick) * 0.28)) * 5.0)
				ly := cy - hop

				// Twin Spring Radar Ears
				set_render_draw_color(renderer, 250, 204, 21, 255)
				render_draw_line(renderer, int(cx - size * 0.10), int(ly - size * 0.18), int(cx - size * 0.20), int(ly - size * 0.38))
				render_draw_line(renderer, int(cx + size * 0.10), int(ly - size * 0.18), int(cx + size * 0.20), int(ly - size * 0.38))

				// Electrostatic lightning between ears
				set_render_draw_color(renderer, 254, 240, 138, 255)
				render_draw_line(renderer, int(cx - size * 0.18), int(ly - size * 0.34), int(cx), int(ly - size * 0.26))
				render_draw_line(renderer, int(cx), int(ly - size * 0.26), int(cx + size * 0.18), int(ly - size * 0.34))

				// Body Sphere
				set_render_draw_color(renderer, 202, 138, 4, 255)
				render_fill_circle(renderer, cx, ly, size * 0.24)
				set_render_draw_color(renderer, 250, 204, 21, 255)
				render_draw_circle(renderer, cx, ly, size * 0.24)

				// High-Voltage EMP Warning Visor
				set_render_draw_color(renderer, 254, 240, 138, 255)
				render_fill_rect(renderer, &Rect{ x: int(cx - size * 0.14), y: int(ly - size * 0.06), w: int(size * 0.28), h: 6 })
			}
		}

		.rocky {
			step_sway := f32(math.sin(f64(anim_tick) * 0.16) * 3.0)
			step_lift := f32(math.abs(math.sin(f64(anim_tick) * 0.32)) * 3.0)

			// Heavy Industrial Chassis Body
			set_render_draw_color(renderer, 71, 85, 105, 255)
			render_fill_rect(renderer, &Rect{ x: int(cx - size * 0.30 + step_sway), y: int(cy - size * 0.26 - step_lift), w: int(size * 0.60), h: int(size * 0.52) })

			// Yellow & Black Hazard Stripes on Shoulders
			set_render_draw_color(renderer, 234, 179, 8, 255)
			render_fill_rect(renderer, &Rect{ x: int(cx - size * 0.30 + step_sway), y: int(cy - size * 0.26 - step_lift), w: int(size * 0.60), h: 5 })
			set_render_draw_color(renderer, 15, 23, 42, 255)
			for h in 0 .. 5 {
				render_fill_rect(renderer, &Rect{ x: int(cx - size * 0.26 + step_sway + f32(h * 8)), y: int(cy - size * 0.26 - step_lift), w: 4, h: 5 })
			}

			// Hydraulic Piston Cylinders on Sides
			set_render_draw_color(renderer, 203, 213, 225, 255)
			render_fill_rect(renderer, &Rect{ x: int(cx - size * 0.36 + step_sway), y: int(cy - size * 0.10 - step_lift), w: 4, h: int(size * 0.28) })
			render_fill_rect(renderer, &Rect{ x: int(cx + size * 0.32 + step_sway), y: int(cy - size * 0.10 - step_lift), w: 4, h: int(size * 0.28) })

			// Glowing Red Scanning Visor
			set_render_draw_color(renderer, 239, 68, 68, 255)
			render_fill_rect(renderer, &Rect{ x: int(cx - size * 0.16 + step_sway), y: int(cy - size * 0.08 - step_lift), w: int(size * 0.32), h: 5 })

			// Illuminated Stasis Target Core on Chest (Indicates Shootable -> Eggifiable)
			set_render_draw_color(renderer, 0, 240, 255, 255)
			render_fill_circle(renderer, cx + step_sway, cy + size * 0.08 - step_lift, size * 0.10)
			set_render_draw_color(renderer, 224, 242, 254, 255)
			render_draw_circle(renderer, cx + step_sway, cy + size * 0.08 - step_lift, size * 0.10)

			// Target Crosshair
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rect(renderer, &Rect{ x: int(cx + step_sway - 1), y: int(cy + size * 0.08 - step_lift - 3), w: 2, h: 6 })
			render_fill_rect(renderer, &Rect{ x: int(cx + step_sway - 3), y: int(cy + size * 0.08 - step_lift - 1), w: 6, h: 2 })

			// Ground impact shockwave on stomp
			if step_lift < 0.5 {
				set_render_draw_color(renderer, 234, 179, 8, 120)
				render_draw_ellipse(renderer, cx + step_sway, f32(y) + size * 0.86, size * 0.35, size * 0.10)
			}
		}

		.moby {
			bob := f32(math.sin(f64(anim_tick) * 0.10) * 2.0)
			my := cy + bob

			// Aqua Cyber-Whale Core Body
			set_render_draw_color(renderer, 2, 132, 199, 255)
			render_fill_circle(renderer, cx, my, size * 0.28)
			set_render_draw_color(renderer, 14, 165, 233, 255)
			render_draw_circle(renderer, cx, my, size * 0.28)

			// Intake Siphon Cone
			dx, dy := e.dir.to_offset()
			b_dx := if dx != 0 || dy != 0 { f32(dx) } else { f32(0.0) }
			b_dy := if dx != 0 || dy != 0 { f32(dy) } else { f32(1.0) }
			set_render_draw_color(renderer, 56, 189, 248, 255)
			render_fill_circle(renderer, cx + b_dx * (size * 0.26), my + b_dy * (size * 0.26), size * 0.14)

			// Rotating Vortex Ring
			set_render_draw_color(renderer, 224, 242, 254, 255)
			render_draw_circle(renderer, cx + b_dx * (size * 0.26), my + b_dy * (size * 0.26), size * 0.10)

			// Glowing Cyan Optic Eye
			set_render_draw_color(renderer, 56, 189, 248, 255)
			render_fill_circle(renderer, cx - size * 0.08, my - size * 0.10, 3.5)
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_circle(renderer, cx - size * 0.08, my - size * 0.10, 1.5)
		}

		.hopper {
			hop := f32(math.abs(math.sin(f64(anim_tick) * 0.30)) * 6.0)
			hy := cy - hop

			// High-Tension Coiled Spring Legs
			set_render_draw_color(renderer, 163, 230, 53, 255)
			// Left
			render_draw_line(renderer, int(cx - size * 0.20), int(hy + size * 0.14), int(cx - size * 0.28), int(hy + size * 0.26 + hop * 0.5))
			render_draw_line(renderer, int(cx - size * 0.28), int(hy + size * 0.26 + hop * 0.5), int(cx - size * 0.20), int(hy + size * 0.34 + hop))
			// Right
			render_draw_line(renderer, int(cx + size * 0.20), int(hy + size * 0.14), int(cx + size * 0.28), int(hy + size * 0.26 + hop * 0.5))
			render_draw_line(renderer, int(cx + size * 0.28), int(hy + size * 0.26 + hop * 0.5), int(cx + size * 0.20), int(hy + size * 0.34 + hop))

			// Armored Lime Beetle Carapace
			set_render_draw_color(renderer, 77, 124, 15, 255)
			render_fill_circle(renderer, cx, hy, size * 0.26)
			// Emerald Wing Shell Plates
			set_render_draw_color(renderer, 101, 163, 13, 255)
			render_fill_circle(renderer, cx - 2, hy - 2, size * 0.20)

			// Amber Sensor Antennae
			set_render_draw_color(renderer, 250, 204, 21, 255)
			render_draw_line(renderer, int(cx - size * 0.10), int(hy - size * 0.18), int(cx - size * 0.28), int(hy - size * 0.35))
			render_draw_line(renderer, int(cx + size * 0.10), int(hy - size * 0.18), int(cx + size * 0.28), int(hy - size * 0.35))

			// Optic Cluster
			set_render_draw_color(renderer, 254, 240, 138, 255)
			render_fill_circle(renderer, cx - size * 0.10, hy - size * 0.04, 3.0)
			render_fill_circle(renderer, cx + size * 0.10, hy - size * 0.04, 3.0)
		}

		.tesla_sentinel {
			// Heavy Bronze/Obsidian Chassis
			set_render_draw_color(renderer, 15, 23, 42, 255)
			render_fill_circle(renderer, cx, cy, size * 0.32)
			set_render_draw_color(renderer, 56, 189, 248, 255)
			render_draw_circle(renderer, cx, cy, size * 0.32)

			// Rotating Electrostatic Inductor Ring
			rot_base := f64(anim_tick) * 0.08
			set_render_draw_color(renderer, 245, 158, 11, 255)
			for c_idx in 0 .. 4 {
				ang := rot_base + f64(c_idx) * math.pi / 2.0
				px := cx + f32(math.cos(ang) * f64(size * 0.22))
				py := cy + f32(math.sin(ang) * f64(size * 0.22))
				render_draw_circle(renderer, px, py, 3.5)
			}

			// Supercharged Plasma Core
			core_pulse := f32(math.sin(f64(anim_tick) * 0.3) * 2.0)
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_circle(renderer, cx, cy, size * 0.14 + core_pulse)
			set_render_draw_color(renderer, 0, 240, 255, 255)
			render_draw_circle(renderer, cx, cy, size * 0.14 + core_pulse)

			// Crackling Micro-Sparks
			set_render_draw_color(renderer, 56, 189, 248, 255)
			for i in 0 .. 3 {
				s_ang := f64(anim_tick + u32(i * 47)) * 0.2
				s_rad := size * 0.30
				render_draw_line(renderer, int(cx), int(cy), int(cx + f32(math.cos(s_ang) * f64(s_rad))), int(cy + f32(math.sin(s_ang) * f64(s_rad))))
			}
		}
	}
}

fn draw_lolo_blaster(renderer &Renderer, lx f32, ly f32, dir Direction, sz f32, has_ammo bool, anim_tick u32, is_triumphant bool) {
	col_main := if is_triumphant { Color{ r: 250, g: 204, b: 21 } } else if has_ammo { Color{ r: 0, g: 240, b: 255 } } else { Color{ r: 100, g: 116, b: 139 } }
	col_glow := if is_triumphant { Color{ r: 254, g: 240, b: 138 } } else if has_ammo { Color{ r: 56, g: 189, b: 248 } } else { Color{ r: 51, g: 65, b: 85 } }

	dx, dy := dir.to_offset()
	if dx == 0 && dy == 0 { return }

	bx := lx + f32(dx) * (sz * 0.32)
	by := ly + f32(dy) * (sz * 0.32)

	// Receiver Housing
	set_render_draw_color(renderer, 30, 41, 59, 255)
	render_fill_rounded_rect(renderer, bx - 4, by - 4, 8, 8, 2.0)
	set_render_draw_color(renderer, col_glow.r, col_glow.g, col_glow.b, 200)
	render_draw_rounded_rect(renderer, bx - 4, by - 4, 8, 8, 2.0)

	// Copper accelerator coils
	coil_col := if has_ammo { Color{ r: 245, g: 158, b: 11 } } else { Color{ r: 120, g: 53, b: 15 } }
	set_render_draw_color(renderer, coil_col.r, coil_col.g, coil_col.b, 255)
	render_draw_circle(renderer, bx, by, 3.0)

	// Muzzle Emitter Ring with pulse
	pulse := if has_ammo { 1.0 + f32(math.sin(f64(anim_tick) * 0.45) * 0.2) } else { 1.0 }
	m_rad := (if has_ammo { sz * 0.10 } else { sz * 0.07 }) * pulse
	set_render_draw_color(renderer, col_main.r, col_main.g, col_main.b, 220)
	render_fill_circle(renderer, bx + f32(dx) * 4, by + f32(dy) * 4, m_rad)

	// Pure white plasma core
	core_col := if has_ammo { Color{ r: 255, g: 255, b: 255 } } else { Color{ r: 148, g: 163, b: 184 } }
	set_render_draw_color(renderer, core_col.r, core_col.g, core_col.b, 255)
	render_fill_circle(renderer, bx + f32(dx) * 4, by + f32(dy) * 4, m_rad * 0.5)

	// Corona sparks if armed
	if has_ammo && (anim_tick % 16 < 8) {
		set_render_draw_color(renderer, 255, 255, 255, 220)
		render_draw_line(renderer, int(bx + f32(dx) * 6), int(by + f32(dy) * 6 - 3), int(bx + f32(dx) * 10), int(by + f32(dy) * 6 - 6))
		render_draw_line(renderer, int(bx + f32(dx) * 6), int(by + f32(dy) * 6 + 3), int(bx + f32(dx) * 10), int(by + f32(dy) * 6 + 6))
	}
}

fn draw_lolo(renderer &Renderer, x int, y int, sz int, game Game) {
	size := f32(sz)
	lx := f32(x) + size / 2.0
	ly := f32(y) + size / 2.0

	// Movement detection
	is_moving := math.hypot(f64(game.lolo.x) - f64(game.lolo.render_x), f64(game.lolo.y) - f64(game.lolo.render_y)) > 0.02
	is_danger := game.is_lolo_in_danger()
	is_triumphant := game.count_remaining_hearts() == 0
	is_pushing := game.push_strain_timer > 0

	// Kinematic bounces & strides
	bounce_y := f32(math.abs(math.sin(f64(game.anim_tick) * 0.35))) * (if is_moving { f32(3.5) } else { f32(1.2) })
	leg_waddle := if is_moving { f32(math.sin(f64(game.anim_tick) * 0.45) * 5.0) } else { f32(0.0) }
	ear_wiggle := f32(math.sin(f64(game.anim_tick) * 0.25) * 2.5)

	mut center_x := lx
	mut center_y := ly - bounce_y

	// Push strain forward offset
	if is_pushing {
		match game.lolo.dir {
			.left { center_x -= 2.5 }
			.right { center_x += 2.5 }
			.up { center_y -= 2.5 }
			.down { center_y += 2.5 }
			else {}
		}
	}

	// 0. Dead glitch state
	if game.lolo.is_dead {
		glitch := (game.anim_tick % 10 < 5)
		dead_col := if glitch { Color{ r: 255, g: 0, b: 60 } } else { Color{ r: 80, g: 10, b: 20 } }
		set_render_draw_color(renderer, dead_col.r, dead_col.g, dead_col.b, 255)
		render_fill_circle(renderer, center_x, center_y, size * 0.38)
		set_render_draw_color(renderer, 255, 255, 255, 255)
		// Dead X_X eyes
		render_draw_line(renderer, int(center_x - 10), int(center_y - 6), int(center_x - 4), int(center_y))
		render_draw_line(renderer, int(center_x - 10), int(center_y), int(center_x - 4), int(center_y - 6))
		render_draw_line(renderer, int(center_x + 4), int(center_y - 6), int(center_x + 10), int(center_y))
		render_draw_line(renderer, int(center_x + 4), int(center_y), int(center_x + 10), int(center_y - 6))
		return
	}

	// 1. Soft Volumetric Ground Contact Shadow
	set_render_draw_color(renderer, 2, 6, 18, 160)
	render_fill_ellipse(renderer, lx, f32(y) + size * 0.88, (size / 3.0) * (1.0 - bounce_y * 0.04), (size / 9.0) * (1.0 - bounce_y * 0.04))

	// 2. Micro-Thruster Backpack (Facing UP)
	if game.lolo.dir == .up {
		t_pulse := f32(math.sin(f64(game.anim_tick) * 0.5) * 2.0)
		t_col := if is_triumphant { Color{ r: 251, g: 191, b: 36 } } else { Color{ r: 0, g: 240, b: 255 } }
		set_render_draw_color(renderer, t_col.r, t_col.g, t_col.b, 230)
		render_fill_circle(renderer, center_x - size * 0.16, center_y + size * 0.18 + t_pulse, 3.5)
		render_fill_circle(renderer, center_x + size * 0.16, center_y + size * 0.18 + t_pulse, 3.5)

		set_render_draw_color(renderer, 15, 23, 42, 255)
		render_fill_rounded_rect(renderer, center_x - size * 0.22, center_y - size * 0.10, size * 0.44, size * 0.32, 2.0)

		draw_lolo_blaster(renderer, center_x, center_y, .up, size, game.lolo.ammo > 0, game.anim_tick, is_triumphant)
	}

	// 3. Cute Floppy Cyber-Ears / Antennae
	ear_col := if is_triumphant { Color{ r: 251, g: 191, b: 36 } } else if is_danger { Color{ r: 244, g: 63, b: 94 } } else { Color{ r: 2, g: 132, b: 199 } }
	tip_col := if is_triumphant { Color{ r: 254, g: 240, b: 138 } } else if is_danger { Color{ r: 251, g: 113, b: 133 } } else { Color{ r: 0, g: 240, b: 255 } }

	// Left Ear
	set_render_draw_color(renderer, ear_col.r, ear_col.g, ear_col.b, 255)
	render_draw_line(renderer, int(center_x - size * 0.18), int(center_y - size * 0.28), int(center_x - size * 0.24 - ear_wiggle), int(center_y - size * 0.54))
	render_draw_line(renderer, int(center_x - size * 0.18 + 1), int(center_y - size * 0.28), int(center_x - size * 0.24 - ear_wiggle + 1), int(center_y - size * 0.54))
	// Glowing Ear Tip
	set_render_draw_color(renderer, tip_col.r, tip_col.g, tip_col.b, 255)
	render_fill_circle(renderer, center_x - size * 0.24 - ear_wiggle, center_y - size * 0.54, 3.2)

	// Right Ear
	set_render_draw_color(renderer, ear_col.r, ear_col.g, ear_col.b, 255)
	render_draw_line(renderer, int(center_x + size * 0.18), int(center_y - size * 0.28), int(center_x + size * 0.24 + ear_wiggle), int(center_y - size * 0.54))
	render_draw_line(renderer, int(center_x + size * 0.18 + 1), int(center_y - size * 0.28), int(center_x + size * 0.24 + ear_wiggle + 1), int(center_y - size * 0.54))
	// Glowing Ear Tip
	set_render_draw_color(renderer, tip_col.r, tip_col.g, tip_col.b, 255)
	render_fill_circle(renderer, center_x + size * 0.24 + ear_wiggle, center_y - size * 0.54, 3.2)

	// 4. Tactical Cyber Boots with Tread Grip
	boot_col := if is_triumphant { Color{ r: 180, g: 83, b: 9 } } else if is_danger { Color{ r: 136, g: 19, b: 55 } } else { Color{ r: 3, g: 105, b: 161 } }
	set_render_draw_color(renderer, boot_col.r, boot_col.g, boot_col.b, 255)
	boot_y := f32(y) + size * 0.82
	if game.lolo.dir == .left || game.lolo.dir == .right {
		render_fill_circle(renderer, center_x - leg_waddle, boot_y, size * 0.14)
		render_fill_circle(renderer, center_x + leg_waddle * 0.8, boot_y, size * 0.14)
		set_render_draw_color(renderer, 2, 6, 23, 255)
		render_draw_circle(renderer, center_x - leg_waddle, boot_y, size * 0.14)
		render_draw_circle(renderer, center_x + leg_waddle * 0.8, boot_y, size * 0.14)
	} else {
		render_fill_circle(renderer, center_x - size * 0.22 + leg_waddle, boot_y, size * 0.14)
		render_fill_circle(renderer, center_x + size * 0.22 - leg_waddle, boot_y, size * 0.14)
		set_render_draw_color(renderer, 2, 6, 23, 255)
		render_draw_circle(renderer, center_x - size * 0.22 + leg_waddle, boot_y, size * 0.14)
		render_draw_circle(renderer, center_x + size * 0.22 - leg_waddle, boot_y, size * 0.14)
	}

	// 5. Main Spherical Armor Body
	body_col_dark := if is_triumphant { Color{ r: 120, g: 53, b: 15 } } else if is_danger { Color{ r: 76, g: 5, b: 25 } } else { Color{ r: 8, g: 47, b: 73 } }
	body_col_mid  := if is_triumphant { Color{ r: 217, g: 119, b: 6 } } else if is_danger { Color{ r: 190, g: 18, b: 60 } } else { Color{ r: 3, g: 105, b: 161 } }
	body_col_light:= if is_triumphant { Color{ r: 250, g: 204, b: 21 } } else if is_danger { Color{ r: 244, g: 63, b: 94 } } else { Color{ r: 2, g: 132, b: 199 } }
	body_col_glow := if is_triumphant { Color{ r: 254, g: 240, b: 138 } } else if is_danger { Color{ r: 255, g: 228, b: 230 } } else { Color{ r: 125, g: 211, b: 252 } }

	// Outer shading layer
	set_render_draw_color(renderer, body_col_dark.r, body_col_dark.g, body_col_dark.b, 255)
	render_fill_circle(renderer, center_x, center_y, size * 0.42)
	// Mid shading layer
	set_render_draw_color(renderer, body_col_mid.r, body_col_mid.g, body_col_mid.b, 255)
	render_fill_circle(renderer, center_x - size * 0.04, center_y - size * 0.04, size * 0.38)
	// Light layer
	set_render_draw_color(renderer, body_col_light.r, body_col_light.g, body_col_light.b, 255)
	render_fill_circle(renderer, center_x - size * 0.08, center_y - size * 0.08, size * 0.33)
	// Highlight layer
	set_render_draw_color(renderer, body_col_glow.r, body_col_glow.g, body_col_glow.b, 255)
	render_fill_circle(renderer, center_x - size * 0.12, center_y - size * 0.12, size * 0.22)

	// Curved Specular Glass Sheen Arc
	set_render_draw_color(renderer, 255, 255, 255, 140)
	render_fill_ellipse(renderer, center_x - size * 0.14, center_y - size * 0.16, size * 0.12, size * 0.05)

	// Outer Rim Lighting Ring
	rim_col := if is_triumphant { Color{ r: 254, g: 240, b: 138, a: 160 } } else { Color{ r: 0, g: 240, b: 255, a: 160 } }
	set_render_draw_color(renderer, rim_col.r, rim_col.g, rim_col.b, rim_col.a)
	render_draw_circle(renderer, center_x, center_y, size * 0.42)

	// 6. Directional Visor & Expressive Face
	visor_col := if is_danger { Color{ r: 251, g: 113, b: 133 } } else if is_triumphant { Color{ r: 253, g: 224, b: 71 } } else { Color{ r: 0, g: 240, b: 255 } }

	if game.lolo.dir == .down {
		// Curved 3D Glass Helmet Visor Bezel
		vw := size * 0.56
		vh := size * 0.24
		vx := center_x - vw / 2.0
		vy := center_y - size * 0.20
		set_render_draw_color(renderer, 9, 13, 22, 255)
		render_fill_rounded_rect(renderer, vx, vy, vw, vh, 4.0)
		set_render_draw_color(renderer, 255, 255, 255, 120)
		render_draw_rounded_rect(renderer, vx, vy, vw, vh, 4.0)

		// Visor Screen
		set_render_draw_color(renderer, visor_col.r, visor_col.g, visor_col.b, 220)
		render_fill_rounded_rect(renderer, vx + 2, vy + 2, vw - 4, vh - 4, 3.0)

		// Cybernetic HUD Scanline
		scan_y := vy + 2.0 + f32((game.anim_tick * 2) % u32(vh - 4.0))
		set_render_draw_color(renderer, 255, 255, 255, 180)
		render_draw_line(renderer, int(vx + 2), int(scan_y), int(vx + vw - 2), int(scan_y))

		// Telemetry Dot in Visor Corner
		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_fill_rect(renderer, &Rect{ x: int(vx + 3), y: int(vy + 3), w: 2, h: 2 })

		// Expressive Optic Eyes
		if is_triumphant {
			// Radiant Golden Star Eyes
			set_render_draw_color(renderer, 255, 255, 255, 255)
			// Left star
			render_fill_circle(renderer, center_x - size * 0.13, center_y - size * 0.08, 3.0)
			render_draw_line(renderer, int(center_x - size * 0.13 - 4), int(center_y - size * 0.08), int(center_x - size * 0.13 + 4), int(center_y - size * 0.08))
			render_draw_line(renderer, int(center_x - size * 0.13), int(center_y - size * 0.08 - 4), int(center_x - size * 0.13), int(center_y - size * 0.08 + 4))
			// Right star
			render_fill_circle(renderer, center_x + size * 0.13, center_y - size * 0.08, 3.0)
			render_draw_line(renderer, int(center_x + size * 0.13 - 4), int(center_y - size * 0.08), int(center_x + size * 0.13 + 4), int(center_y - size * 0.08))
			render_draw_line(renderer, int(center_x + size * 0.13), int(center_y - size * 0.08 - 4), int(center_x + size * 0.13), int(center_y - size * 0.08 + 4))
		} else if is_danger {
			// Wide Alarmed Optic Rects
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rect(renderer, &Rect{ x: int(center_x - size * 0.20), y: int(center_y - size * 0.16), w: int(size * 0.14), h: int(size * 0.15) })
			render_fill_rect(renderer, &Rect{ x: int(center_x + size * 0.06), y: int(center_y - size * 0.16), w: int(size * 0.14), h: int(size * 0.15) })
			set_render_draw_color(renderer, 244, 63, 94, 255)
			render_fill_rect(renderer, &Rect{ x: int(center_x - size * 0.15), y: int(center_y - size * 0.11), w: 4, h: 4 })
			render_fill_rect(renderer, &Rect{ x: int(center_x + size * 0.11), y: int(center_y - size * 0.11), w: 4, h: 4 })
			// Falling Sweat Droplet Bead Animation
			drip := f32((game.anim_tick * 2) % u32(size * 0.3))
			set_render_draw_color(renderer, 56, 189, 248, 220)
			render_fill_ellipse(renderer, center_x + size * 0.28, center_y - size * 0.18 + drip, 2.5, 4.0)
		} else if game.anim_tick % 120 > 8 {
			// Happy Blinking Cyber Eyes
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rect(renderer, &Rect{ x: int(center_x - size * 0.18), y: int(center_y - size * 0.14), w: int(size * 0.10), h: 5 })
			render_fill_rect(renderer, &Rect{ x: int(center_x + size * 0.08), y: int(center_y - size * 0.14), w: int(size * 0.10), h: 5 })
		}

		// Cute Blushing Neon Pink Cheeks
		set_render_draw_color(renderer, 244, 114, 182, 160)
		render_fill_circle(renderer, center_x - size * 0.26, center_y + size * 0.04, 3.5)
		render_fill_circle(renderer, center_x + size * 0.26, center_y + size * 0.04, 3.5)

		// Pulsing Arc Reactor Chest Core
		c_pulse := f32(math.sin(f64(game.anim_tick) * 0.1) * 1.2)
		core_c := if is_triumphant { Color{ r: 251, g: 191, b: 36 } } else { Color{ r: 0, g: 240, b: 255 } }
		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_fill_circle(renderer, center_x, center_y + size * 0.14, size * 0.11 + c_pulse)
		set_render_draw_color(renderer, core_c.r, core_c.g, core_c.b, 255)
		render_draw_circle(renderer, center_x, center_y + size * 0.14, size * 0.11 + c_pulse)

		// Forward / Downward Blaster
		draw_lolo_blaster(renderer, center_x + size * 0.12, center_y + size * 0.06, .down, size, game.lolo.ammo > 0, game.anim_tick, is_triumphant)

	} else if game.lolo.dir == .left {
		// Left Profile Visor
		set_render_draw_color(renderer, 15, 23, 42, 255)
		render_fill_rounded_rect(renderer, center_x - size * 0.38, center_y - size * 0.20, size * 0.36, size * 0.24, 3.0)
		set_render_draw_color(renderer, visor_col.r, visor_col.g, visor_col.b, 220)
		render_fill_rounded_rect(renderer, center_x - size * 0.36, center_y - size * 0.18, size * 0.32, size * 0.20, 2.0)

		if is_triumphant {
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_circle(renderer, center_x - size * 0.22, center_y - size * 0.08, 3.0)
		} else if game.anim_tick % 120 > 8 {
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rect(renderer, &Rect{ x: int(center_x - size * 0.32), y: int(center_y - size * 0.14), w: int(size * 0.10), h: 5 })
		}

		// Cheek blush
		set_render_draw_color(renderer, 244, 114, 182, 160)
		render_fill_circle(renderer, center_x - size * 0.26, center_y + size * 0.04, 3.5)

		draw_lolo_blaster(renderer, center_x, center_y, .left, size, game.lolo.ammo > 0, game.anim_tick, is_triumphant)

	} else if game.lolo.dir == .right {
		// Right Profile Visor
		set_render_draw_color(renderer, 15, 23, 42, 255)
		render_fill_rounded_rect(renderer, center_x + size * 0.02, center_y - size * 0.20, size * 0.36, size * 0.24, 3.0)
		set_render_draw_color(renderer, visor_col.r, visor_col.g, visor_col.b, 220)
		render_fill_rounded_rect(renderer, center_x + size * 0.04, center_y - size * 0.18, size * 0.32, size * 0.20, 2.0)

		if is_triumphant {
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_circle(renderer, center_x + size * 0.22, center_y - size * 0.08, 3.0)
		} else if game.anim_tick % 120 > 8 {
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rect(renderer, &Rect{ x: int(center_x + size * 0.22), y: int(center_y - size * 0.14), w: int(size * 0.10), h: 5 })
		}

		// Cheek blush
		set_render_draw_color(renderer, 244, 114, 182, 160)
		render_fill_circle(renderer, center_x + size * 0.26, center_y + size * 0.04, 3.5)

		draw_lolo_blaster(renderer, center_x, center_y, .right, size, game.lolo.ammo > 0, game.anim_tick, is_triumphant)

	} else {
		// Back View Armor Spine Plates (Up)
		set_render_draw_color(renderer, 15, 23, 42, 255)
		render_fill_rect(renderer, &Rect{ x: int(center_x - size * 0.12), y: int(center_y - size * 0.24), w: int(size * 0.24), h: int(size * 0.16) })
		p_col := if is_triumphant { Color{ r: 251, g: 191, b: 36 } } else { Color{ r: 0, g: 240, b: 255 } }
		set_render_draw_color(renderer, p_col.r, p_col.g, p_col.b, 220)
		render_fill_rect(renderer, &Rect{ x: int(center_x - size * 0.06), y: int(center_y - size * 0.20), w: int(size * 0.12), h: 3 })
	}

	// 7. Top Antenna & Status Beacon LED
	set_render_draw_color(renderer, ear_col.r, ear_col.g, ear_col.b, 255)
	render_fill_rect(renderer, &Rect{ x: int(center_x - 1.5), y: int(center_y - size * 0.42 - 3), w: 3, h: 5 })
	led_col := if is_danger { Color{ r: 239, g: 68, b: 68 } } else if is_triumphant { Color{ r: 251, g: 191, b: 36 } } else { Color{ r: 0, g: 240, b: 255 } }
	led_pulse := if is_danger { f32(math.sin(f64(game.anim_tick) * 0.5) * 1.5) } else { f32(0.0) }
	set_render_draw_color(renderer, led_col.r, led_col.g, led_col.b, 255)
	render_fill_circle(renderer, center_x, center_y - size * 0.42 - 4, 3.0 + led_pulse)
}

// --------------------------------------------------
// Laser Beam Rendering
// --------------------------------------------------

fn draw_lasers(renderer &Renderer, game Game, _ticks u32) {
	grid_sz := game.grid_size
	cell_sz := int(520.0 / f32(grid_sz))
	board_w := grid_sz * cell_sz
	board_h := grid_sz * cell_sz
	start_x := 24 + (520 - board_w) / 2
	start_y := 80 + (520 - board_h) / 2

	for seg in game.laser_segments {
		x1 := start_x + seg.x1 * cell_sz + cell_sz / 2
		y1 := start_y + seg.y1 * cell_sz + cell_sz / 2
		x2 := start_x + seg.x2 * cell_sz + cell_sz / 2
		y2 := start_y + seg.y2 * cell_sz + cell_sz / 2

		// Laser glow line
		set_render_draw_color(renderer, seg.color_r, seg.color_g, seg.color_b, 255)
		render_draw_line(renderer, x1, y1, x2, y2)
		render_draw_line(renderer, x1 + 1, y1, x2 + 1, y2)
		render_draw_line(renderer, x1, y1 + 1, x2, y2 + 1)
	}
}

// --------------------------------------------------
// Ghost Guide Conduit
// --------------------------------------------------

fn draw_ghost_conduit(renderer &Renderer, game Game, _ticks u32) {
	grid_sz := game.grid_size
	cell_sz := int(520.0 / f32(grid_sz))
	board_w := grid_sz * cell_sz
	board_h := grid_sz * cell_sz
	start_x := 24 + (520 - board_w) / 2
	start_y := 80 + (520 - board_h) / 2

	// Breadcrumb conduit path
	set_render_draw_color(renderer, 0, 240, 255, 140)
	for i in 0 .. game.ghost.waypoints.len - 1 {
		p1 := game.ghost.waypoints[i]
		p2 := game.ghost.waypoints[i + 1]
		x1 := start_x + p1.x * cell_sz + cell_sz / 2
		y1 := start_y + p1.y * cell_sz + cell_sz / 2
		x2 := start_x + p2.x * cell_sz + cell_sz / 2
		y2 := start_y + p2.y * cell_sz + cell_sz / 2
		render_draw_line(renderer, x1, y1, x2, y2)
		render_draw_point(renderer, x1, y1)
	}

	// Translucent cyber ghost runner
	gx := start_x + int(game.ghost.ghost_x * f32(cell_sz))
	gy := start_y + int(game.ghost.ghost_y * f32(cell_sz))
	set_render_draw_color(renderer, 0, 255, 240, 160)
	render_draw_rect(renderer, &Rect{ x: gx + 4, y: gy + 4, w: cell_sz - 8, h: cell_sz - 8 })
}

// --------------------------------------------------
// Particles & Floating Text
// --------------------------------------------------

fn draw_particles(renderer &Renderer, game Game) {
	grid_sz := game.grid_size
	cell_sz := int(520.0 / f32(grid_sz))
	board_w := grid_sz * cell_sz
	board_h := grid_sz * cell_sz
	start_x := 24 + (520 - board_w) / 2
	start_y := 80 + (520 - board_h) / 2

	for p in game.particles {
		px := start_x + int(p.x * f32(cell_sz))
		py := start_y + int(p.y * f32(cell_sz))
		set_render_draw_color(renderer, p.r, p.g, p.b, 255)
		render_fill_rect(renderer, &Rect{ x: px, y: py, w: int(p.size), h: int(p.size) })
	}

	for ft in game.floating_texts {
		fx := start_x + int(ft.x * f32(cell_sz))
		fy := start_y + int(ft.y * f32(cell_sz))
		draw_text_centered(renderer, fx, fy, ft.text, 1, Color{ r: ft.r, g: ft.g, b: ft.b })
	}
}

// --------------------------------------------------
// Sidebar Panel
// --------------------------------------------------

fn draw_sidebar(
	renderer &Renderer,
	mx int,
	my int,
	btn_ghost Button,
	btn_undo Button,
	btn_restart Button,
	btn_prev Button,
	btn_next Button,
	btn_level_select Button,
	btn_map Button,
	btn_manual Button,
	btn_editor Button,
	btn_sound Button
) {
	// Sidebar container
	set_render_draw_color(renderer, 10, 16, 28, 230)
	render_fill_rect(renderer, &Rect{ x: 720, y: 80, w: 220, h: 520 })
	set_render_draw_color(renderer, 0, 240, 255, 140)
	render_draw_rect(renderer, &Rect{ x: 720, y: 80, w: 220, h: 520 })

	draw_text(renderer, 735, 96, 'TACTICAL CONSOLE', 1, Color{ r: 0, g: 240, b: 255 })

	btn_ghost.draw(renderer, mx, my)
	btn_undo.draw(renderer, mx, my)
	btn_restart.draw(renderer, mx, my)
	btn_prev.draw(renderer, mx, my)
	btn_next.draw(renderer, mx, my)
	btn_level_select.draw(renderer, mx, my)
	btn_map.draw(renderer, mx, my)
	btn_manual.draw(renderer, mx, my)
	btn_editor.draw(renderer, mx, my)
	btn_sound.draw(renderer, mx, my)
}

// --------------------------------------------------
// Modals & Overlays
// --------------------------------------------------

fn draw_level_selector_modal(renderer &Renderer, game Game, _mx int, _my int) {
	set_render_draw_color(renderer, 0, 0, 0, 210)
	render_fill_rect(renderer, &Rect{ x: 0, y: 0, w: win_w, h: win_h })

	modal_rect := Rect{ x: 60, y: 40, w: 840, h: 600 }
	set_render_draw_color(renderer, 10, 16, 30, 255)
	render_fill_rect(renderer, &modal_rect)
	set_render_draw_color(renderer, 0, 240, 255, 255)
	render_draw_rect(renderer, &modal_rect)

	draw_text_centered(renderer, win_w / 2, 60, 'CAMPAIGN OPERATIONS (100 CHAMBERS)', 2, Color{ r: 255, g: 215, b: 0 })
	draw_text_centered(renderer, win_w / 2, 90, 'PAGE ${game.level_selector_page + 1} / 4 - PRESS [L] / [ESC] TO CLOSE', 1, Color{ r: 0, g: 240, b: 255 })

	start_idx := game.level_selector_page * 25
	end_idx := math_min(start_idx + 25, game.campaign_levels.len)

	for i in start_idx .. end_idx {
		rel_idx := i - start_idx
		col := rel_idx % 5
		row := rel_idx / 5
		bx := 90 + col * 150
		by := 130 + row * 85
		lvl := game.campaign_levels[i]

		is_unlocked := i <= game.save_data.max_level_unlocked
		bg_col := if is_unlocked { Color{ r: 18, g: 30, b: 54 } } else { Color{ r: 15, g: 18, b: 25 } }
		br_col := if is_unlocked { Color{ r: 0, g: 240, b: 255 } } else { Color{ r: 60, g: 70, b: 85 } }

		set_render_draw_color(renderer, bg_col.r, bg_col.g, bg_col.b, 255)
		render_fill_rect(renderer, &Rect{ x: bx, y: by, w: 135, h: 72 })
		set_render_draw_color(renderer, br_col.r, br_col.g, br_col.b, 255)
		render_draw_rect(renderer, &Rect{ x: bx, y: by, w: 135, h: 72 })

		num_col := if is_unlocked { Color{ r: 255, g: 215, b: 0 } } else { Color{ r: 120, g: 130, b: 140 } }
		draw_text(renderer, bx + 8, by + 10, 'STG ${i + 1}', 1, num_col)
		draw_text(renderer, bx + 8, by + 26, lvl.name.split(':')[1] or { lvl.name }, 1, Color{ r: 200, g: 220, b: 240 })

		if is_unlocked {
			draw_text(renderer, bx + 8, by + 46, 'UNLOCKED', 1, Color{ r: 0, g: 255, b: 120 })
		} else {
			draw_text(renderer, bx + 8, by + 46, 'LOCKED', 1, Color{ r: 180, g: 60, b: 60 })
		}
	}
}

fn draw_sector_map_modal(renderer &Renderer, game Game, _mx int, _my int) {
	set_render_draw_color(renderer, 0, 0, 0, 210)
	render_fill_rect(renderer, &Rect{ x: 0, y: 0, w: win_w, h: win_h })

	modal_rect := Rect{ x: 80, y: 50, w: 800, h: 580 }
	set_render_draw_color(renderer, 10, 16, 30, 255)
	render_fill_rect(renderer, &modal_rect)
	set_render_draw_color(renderer, 0, 240, 255, 255)
	render_draw_rect(renderer, &modal_rect)

	draw_text_centered(renderer, win_w / 2, 75, 'EGGERLAND CITADEL - TACTICAL SECTOR MAP', 2, Color{ r: 255, g: 215, b: 0 })
	draw_text_centered(renderer, win_w / 2, 105, '10 ESCALATING SECURITY SECTORS // PRESS [M] / [ESC] TO CLOSE', 1, Color{ r: 0, g: 240, b: 255 })

	sector_names := [
		'Infiltration Perimeter',
		'Laser Prism Deflection',
		'Patrol Corridor Sweeps',
		'Sub-Space Quantum Matrix',
		'Omni-Sentry Containment',
		'Hydraulic Vortex Systems',
		'High-Velocity Drone Core',
		'Labyrinthine Multi-Vault',
		'Mastermind Security Gauntlet',
		'Grand Cyber Citadel Apex',
	]

	for s in 0 .. 10 {
		sy := 140 + s * 45
		sec_num := s + 1
		sec_name := sector_names[s]
		is_unlocked := game.save_data.max_level_unlocked >= s * 10

		bg := if is_unlocked { Color{ r: 18, g: 32, b: 54 } } else { Color{ r: 14, g: 18, b: 24 } }
		set_render_draw_color(renderer, bg.r, bg.g, bg.b, 255)
		render_fill_rect(renderer, &Rect{ x: 120, y: sy, w: 720, h: 36 })
		set_render_draw_color(renderer, 0, 240, 255, u8(if is_unlocked { 200 } else { 60 }))
		render_draw_rect(renderer, &Rect{ x: 120, y: sy, w: 720, h: 36 })

		label := 'SECTOR ${sec_num}: ${sec_name.to_upper()} (STAGES ${s*10 + 1}-${(s+1)*10})'
		txt_col := if is_unlocked { Color{ r: 255, g: 215, b: 0 } } else { Color{ r: 120, g: 130, b: 140 } }
		draw_text(renderer, 140, sy + 12, label, 1, txt_col)

		status_txt := if is_unlocked { 'ACCESS AUTHORIZED' } else { 'SYSTEM LOCKED' }
		status_col := if is_unlocked { Color{ r: 0, g: 255, b: 140 } } else { Color{ r: 255, g: 60, b: 60 } }
		draw_text(renderer, 680, sy + 12, status_txt, 1, status_col)
	}
}

fn draw_field_manual_modal(renderer &Renderer, _game Game, _mx int, _my int) {
	set_render_draw_color(renderer, 0, 0, 0, 210)
	render_fill_rect(renderer, &Rect{ x: 0, y: 0, w: win_w, h: win_h })

	modal_rect := Rect{ x: 70, y: 40, w: 820, h: 600 }
	set_render_draw_color(renderer, 10, 16, 30, 255)
	render_fill_rect(renderer, &modal_rect)
	set_render_draw_color(renderer, 0, 240, 255, 255)
	render_draw_rect(renderer, &modal_rect)

	draw_text_centered(renderer, win_w / 2, 60, 'CYBER OPERATIVE FIELD MANUAL & DOSSIER', 2, Color{ r: 255, g: 215, b: 0 })
	draw_text_centered(renderer, win_w / 2, 85, 'CLEARANCE: TOP SECRET // TARGET: CITADEL CORE', 1, Color{ r: 0, g: 240, b: 255 })

	lines := [
		'DIRECTIVE 1: Collect all red Heart Framers (Memory Cores) in each chamber.',
		'DIRECTIVE 2: Ammo Hearts grant +2 Plasma Blaster shots for enemy stasis.',
		'DIRECTIVE 3: Once all hearts are collected, step onto open Key Vault.',
		'DIRECTIVE 4: Securing key freezes all hostiles and opens exit warp gate.',
		'',
		'HOSTILE INTEL BESTIARY:',
		'• SNAKEY: Harmless recon drone. 1 shot = stasis egg push block or water raft.',
		'• GOL: Dormant hydra. Wakes on last heart and breathes lethal cardinal fire.',
		'• SKULL: Nanite sentry. Awakens on last heart to aggressively hunt Lolo.',
		'• ALMA: Kinetic juggernaut. Roams and charges when in line of sight.',
		'• MEDUSA: Optical disintegration turret. Cardinal death rays on line of sight!',
		'• DON MEDUSA: Patrolling mobile gorgon firing perpendicular death rays.',
		'• LEEPER: Kinetic siphon. Touches Lolo -> curls into sleeping stone boulder.',
		'• ROCKY: Armored bouncer. Shoves Lolo backward into adjacent tiles.',
		'',
		'TERRAINS & HAZARDS:',
		'• EMERALD PRISMS: Deflect laser beams at 90-degree angles.',
		'• DEMOLITION BOMBS: Push into cracked walls to trigger nitro blast.',
		'• QUANTUM PORTALS: Warps entities between paired nodes A and B.',
		'• MAG-LEV ICE: Continuous friction-free slide until obstacle.',
		'• SHATTER GLASS: Cracks on 1st step, breaks into pit on 2nd step.',
		'',
		'CONTROLS: WASD / Arrows: Move | SPACE: Blaster | Z / U: Undo | R: Reset',
		'PRESS [F1] / [?] / [ESC] TO CLOSE DOSSIER',
	]

	for i, l in lines {
		draw_text(renderer, 100, 115 + i * 21, l, 1, Color{ r: 200, g: 220, b: 240 })
	}
}

fn draw_stage_cleared_banner(renderer &Renderer, _game Game, _ticks u32) {
	set_render_draw_color(renderer, 0, 0, 0, 180)
	render_fill_rect(renderer, &Rect{ x: 100, y: 220, w: 760, h: 180 })
	set_render_draw_color(renderer, 0, 240, 255, 255)
	render_draw_rect(renderer, &Rect{ x: 100, y: 220, w: 760, h: 180 })

	draw_text_centered(renderer, win_w / 2, 250, 'STAGE CLEARED // QUANTUM KEY SECURED!', 2, Color{ r: 0, g: 255, b: 120 })
	draw_text_centered(renderer, win_w / 2, 290, 'ORBITAL EXTRACTION BEAM ENGAGED', 2, Color{ r: 255, g: 215, b: 0 })
	draw_text_centered(renderer, win_w / 2, 340, 'PRESS [SPACE] OR [NEXT >] TO ADVANCE', 1, Color{ r: 0, g: 240, b: 255 })
}

fn draw_lost_banner(renderer &Renderer, _game Game, _ticks u32) {
	set_render_draw_color(renderer, 0, 0, 0, 180)
	render_fill_rect(renderer, &Rect{ x: 100, y: 220, w: 760, h: 180 })
	set_render_draw_color(renderer, 255, 0, 60, 255)
	render_draw_rect(renderer, &Rect{ x: 100, y: 220, w: 760, h: 180 })

	draw_text_centered(renderer, win_w / 2, 250, 'OPERATIVE COMPROMISED // CHAMBER PURGED', 2, Color{ r: 255, g: 40, b: 80 })
	draw_text_centered(renderer, win_w / 2, 290, 'PRESS [R] TO REBOOT CHAMBER OR [Z] TO REWIND', 1, Color{ r: 255, g: 215, b: 0 })
}

fn draw_campaign_victory(renderer &Renderer, game Game, _ticks u32) {
	set_render_draw_color(renderer, 0, 0, 0, 220)
	render_fill_rect(renderer, &Rect{ x: 0, y: 0, w: win_w, h: win_h })

	draw_text_centered(renderer, win_w / 2, 140, 'VICTORY! PRINCESS LALA LIBERATED!', 3, Color{ r: 255, g: 215, b: 0 })
	draw_text_centered(renderer, win_w / 2, 190, 'ALL 100 CITADEL CHAMBERS DECRYPTED', 2, Color{ r: 0, g: 240, b: 255 })
	draw_text_centered(renderer, win_w / 2, 240, 'KING EGGER HAS BEEN PURGED FROM THE MATRIX', 2, Color{ r: 0, g: 255, b: 120 })
	draw_text_centered(renderer, win_w / 2, 340, 'TOTAL MOVES: ${game.moves_count} // CONGRATULATIONS OPERATIVE!', 1, Color{ r: 255, g: 255, b: 255 })
}

fn draw_status_toast(renderer &Renderer, msg string) {
	set_render_draw_color(renderer, 10, 16, 28, 220)
	render_fill_rect(renderer, &Rect{ x: 160, y: 640, w: 640, h: 32 })
	set_render_draw_color(renderer, 0, 240, 255, 200)
	render_draw_rect(renderer, &Rect{ x: 160, y: 640, w: 640, h: 32 })

	draw_text_centered(renderer, win_w / 2, 650, msg, 1, Color{ r: 255, g: 215, b: 0 })
}
