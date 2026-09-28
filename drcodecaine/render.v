module main

import math

pub fn render_dr_mario_game(renderer &Renderer, mut g DrMarioGame) {
	// Screen shake offsets
	shake_x := if g.screen_shake > 0.0 { int(math.sin(f64(g.anim_timer * 40.0)) * 5.0) } else { 0 }
	shake_y := if g.screen_shake > 0.0 { int(math.cos(f64(g.anim_timer * 40.0)) * 5.0) } else { 0 }

	// 1. Arcade Clinic Background
	render_clinic_background(renderer)

	// 2. Microscope Petri Dish on Left (Dancing Giant Viruses)
	render_microscope_dish(renderer, mut g)

	// 3. Medicine Bottle Frame & Neck (With Screen Shake)
	render_medicine_bottle(renderer, shake_x, shake_y)

	// 4. Grid Cells (Viruses and Locked Pills)
	render_grid_cells(renderer, mut g, shake_x, shake_y)

	// 5. Active & Ghost Pills
	if g.has_active_pill && g.state in [.playing, .clearing_matches, .cascade_falling] {
		// Ghost Projection Shadow
		if g.ghost_enabled {
			render_ghost_pill(renderer, mut g, shake_x, shake_y)
		}
		render_active_pill(renderer, mut g, shake_x, shake_y)
	}

	// 5b. Hold Pill Tray
	render_hold_tray(renderer, mut g)

	// 6. Dr. Mario Mascot on Right (Holding & Throwing Next Pill)
	render_dr_mario_mascot(renderer, mut g)

	// 7. Clipboard HUD (Score, Level, Speed, Virus Count)
	render_clipboard_hud(renderer, mut g)

	// 8. Particles & Popups
	render_particles(renderer, mut g)
	render_score_popups(renderer, mut g)

	// 9. CRT Filter
	if g.crt_filter {
		render_crt_overlay(renderer)
	}

	// 10. Game State Overlays
	if g.state == .title {
		render_title_screen(renderer, mut g)
	} else if g.state == .paused {
		render_paused_screen(renderer)
	} else if g.state == .stage_clear {
		render_stage_clear_screen(renderer, mut g)
	} else if g.state == .game_over {
		render_game_over_screen(renderer, mut g)
	}
}

fn render_ghost_pill(renderer &Renderer, mut g DrMarioGame, ox int, oy int) {
	bx := 300 + ox
	by := 120 + oy
	p := g.active_pill
	gy := g.get_ghost_y()

	// Only render ghost if target is below current pill
	if gy <= p.y {
		return
	}

	set_render_draw_blend_mode(renderer, .blend)

	match p.orientation {
		.horizontal {
			render_ghost_half(renderer, bx + p.x * 24, by + gy * 24, p.c1)
			render_ghost_half(renderer, bx + (p.x + 1) * 24, by + gy * 24, p.c2)
		}
		.vertical {
			render_ghost_half(renderer, bx + p.x * 24, by + gy * 24, p.c1)
			if gy > 0 {
				render_ghost_half(renderer, bx + p.x * 24, by + (gy - 1) * 24, p.c2)
			}
		}
	}
}

fn render_ghost_half(renderer &Renderer, x int, y int, color PillColor) {
	// Translucent outline + tint
	gc := match color {
		.red { Color{ r: 255, g: 80, b: 80, a: 95 } }
		.yellow { Color{ r: 255, g: 235, b: 80, a: 95 } }
		.blue { Color{ r: 80, g: 180, b: 255, a: 95 } }
	}

	set_render_draw_color(renderer, gc.r, gc.g, gc.b, gc.a)
	// Outer border wireframe
	render_draw_rect(renderer, &Rect{ x: x + 2, y: y + 2, w: 20, h: 20 })
	// Inner subtle glow
	set_render_draw_color(renderer, gc.r, gc.g, gc.b, 35)
	render_fill_rect(renderer, &Rect{ x: x + 4, y: y + 4, w: 16, h: 16 })
}

fn render_hold_tray(renderer &Renderer, mut g DrMarioGame) {
	hx := 228
	hy := 140

	// Beaker Stand Glass Tray
	set_render_draw_color(renderer, 30, 48, 68, 255)
	render_fill_rect(renderer, &Rect{ x: hx, y: hy, w: 60, h: 48 })

	// Steel Rim
	set_render_draw_color(renderer, 150, 175, 195, 255)
	render_draw_rect(renderer, &Rect{ x: hx, y: hy, w: 60, h: 48 })

	draw_text_centered_shadow(renderer, hx + 30, hy - 14, 'HOLD', 1,
		Color{ r: 255, g: 235, b: 60, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, hx + 30, hy + 52, '[SHIFT]', 1,
		Color{ r: 160, g: 190, b: 220, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	if g.has_hold_pill {
		// Draw held pill centered inside tray
		render_pill_half(renderer, g.sprite_texture, hx + 6, hy + 12, g.hold_c1, .left)
		render_pill_half(renderer, g.sprite_texture, hx + 30, hy + 12, g.hold_c2, .right)
	}
}

fn render_clinic_background(renderer &Renderer) {
	// Deep retro teal-slate clinic tile background
	set_render_draw_color(renderer, 22, 38, 54, 255)
	render_clear(renderer)

	// Checkerboard tile grid with subtle bevel
	set_render_draw_color(renderer, 28, 48, 66, 255)
	for r := 0; r < 20; r++ {
		for c := 0; c < 26; c++ {
			if (r + c) % 2 == 0 {
				rect := Rect{ x: c * 32, y: r * 32, w: 32, h: 32 }
				render_fill_rect(renderer, &rect)
			}
		}
	}
}

fn render_medicine_bottle(renderer &Renderer, ox int, oy int) {
	bx := 296 + ox
	by := 116 + oy
	bw := 208
	bh := 392

	// Bottle Dark Glass Interior
	set_render_draw_color(renderer, 10, 16, 24, 255)
	bottle_body := Rect{ x: bx, y: by, w: bw, h: bh }
	render_fill_rect(renderer, &bottle_body)

	// Glass reflection gradient strip on left side
	set_render_draw_color(renderer, 40, 70, 95, 120)
	render_fill_rect(renderer, &Rect{ x: bx + 12, y: by + 10, w: 18, h: bh - 20 })

	// Top Bottle Neck
	neck_x := bx + 72
	neck_y := by - 24
	neck_w := 64
	neck_h := 24
	set_render_draw_color(renderer, 10, 16, 24, 255)
	neck_rect := Rect{ x: neck_x, y: neck_y, w: neck_w, h: neck_h }
	render_fill_rect(renderer, &neck_rect)

	// Outer White Glass Rim
	set_render_draw_color(renderer, 225, 240, 250, 255)
	// Outer Border
	render_draw_line(renderer, bx - 4, by, bx - 4, by + bh + 4)
	render_draw_line(renderer, bx + bw + 4, by, bx + bw + 4, by + bh + 4)
	render_draw_line(renderer, bx - 4, by + bh + 4, bx + bw + 4, by + bh + 4)

	// Shoulders
	render_draw_line(renderer, bx - 4, by, neck_x, by)
	render_draw_line(renderer, neck_x + neck_w, by, bx + bw + 4, by)
	// Neck lip
	render_draw_line(renderer, neck_x, neck_y, neck_x, by)
	render_draw_line(renderer, neck_x + neck_w, neck_y, neck_x + neck_w, by)
	render_draw_line(renderer, neck_x - 8, neck_y, neck_x + neck_w + 8, neck_y)

	// Measurement gradations on right wall
	set_render_draw_color(renderer, 130, 175, 210, 255)
	for i := 1; i <= 6; i++ {
		my := by + i * 56
		render_draw_line(renderer, bx + bw - 14, my, bx + bw - 2, my)
	}
}

fn render_grid_cells(renderer &Renderer, mut g DrMarioGame, ox int, oy int) {
	bx := 300 + ox
	by := 120 + oy

	for r in 0 .. 16 {
		for c in 0 .. 8 {
			cell := g.grid[r][c]
			cell_x := bx + c * 24
			cell_y := by + r * 24

			if cell.cell_type == .empty {
				continue
			}

			if cell.cell_type == .virus {
				render_virus_cell(renderer, g.sprite_texture, cell_x, cell_y, cell.color, g.anim_timer)
			} else {
				half_type := match cell.cell_type {
					.pill_left { PillHalfType.left }
					.pill_right { PillHalfType.right }
					.pill_top { PillHalfType.top }
					.pill_bottom { PillHalfType.bottom }
					else { PillHalfType.single }
				}
				render_pill_half(renderer, g.sprite_texture, cell_x, cell_y, cell.color, half_type)
			}
		}
	}
}

enum PillHalfType {
	left
	right
	top
	bottom
	single
}

fn render_pill_half(renderer &Renderer, texture &Texture, x int, y int, color PillColor, half_type PillHalfType) {
	if texture != unsafe { nil } {
		col_row := match color {
			.red { 0 }
			.yellow { 1 }
			.blue { 2 }
		}
		shape_col := match half_type {
			.left { 0 }
			.right { 1 }
			.top { 2 }
			.bottom { 3 }
			.single { 4 }
		}
		src := Rect{ x: shape_col * 32, y: col_row * 32, w: 32, h: 32 }
		dst := Rect{ x: x, y: y, w: 24, h: 24 }
		render_copy(renderer, texture, &src, &dst)
		return
	}

	base_c, hl_c, sd_c := get_pill_colors(color)

	// 1. Pill Body Base
	set_render_draw_color(renderer, base_c.r, base_c.g, base_c.b, 255)
	body := Rect{ x: x + 2, y: y + 2, w: 20, h: 20 }
	render_fill_rect(renderer, &body)

	// 2. Glossy Highlight & Drop Shadows
	set_render_draw_color(renderer, hl_c.r, hl_c.g, hl_c.b, 255)
	hl := Rect{ x: x + 4, y: y + 4, w: 16, h: 4 }
	render_fill_rect(renderer, &hl)

	set_render_draw_color(renderer, sd_c.r, sd_c.g, sd_c.b, 255)
	sd := Rect{ x: x + 4, y: y + 16, w: 16, h: 4 }
	render_fill_rect(renderer, &sd)

	// 3. Rounded Capsule Caps & Chamfers
	set_render_draw_color(renderer, 10, 16, 24, 255)
	match half_type {
		.left {
			render_draw_point(renderer, x + 2, y + 2)
			render_draw_point(renderer, x + 2, y + 21)
			set_render_draw_color(renderer, 20, 20, 20, 255)
			render_fill_rect(renderer, &Rect{ x: x + 20, y: y + 2, w: 2, h: 20 })
		}
		.right {
			render_draw_point(renderer, x + 21, y + 2)
			render_draw_point(renderer, x + 21, y + 21)
			set_render_draw_color(renderer, 20, 20, 20, 255)
			render_fill_rect(renderer, &Rect{ x: x + 2, y: y + 2, w: 2, h: 20 })
		}
		.top {
			render_draw_point(renderer, x + 2, y + 2)
			render_draw_point(renderer, x + 21, y + 2)
			set_render_draw_color(renderer, 20, 20, 20, 255)
			render_fill_rect(renderer, &Rect{ x: x + 2, y: y + 20, w: 20, h: 2 })
		}
		.bottom {
			render_draw_point(renderer, x + 2, y + 21)
			render_draw_point(renderer, x + 21, y + 21)
			set_render_draw_color(renderer, 20, 20, 20, 255)
			render_fill_rect(renderer, &Rect{ x: x + 2, y: y + 2, w: 20, h: 2 })
		}
		.single {
			render_draw_point(renderer, x + 2, y + 2)
			render_draw_point(renderer, x + 21, y + 2)
			render_draw_point(renderer, x + 2, y + 21)
			render_draw_point(renderer, x + 21, y + 21)
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rect(renderer, &Rect{ x: x + 8, y: y + 7, w: 5, h: 4 })
		}
	}
}

fn get_pill_colors(color PillColor) (Color, Color, Color) {
	return match color {
		.red {
			Color{ r: 235, g: 45, b: 45, a: 255 },
			Color{ r: 255, g: 150, b: 150, a: 255 },
			Color{ r: 150, g: 20, b: 20, a: 255 }
		}
		.yellow {
			Color{ r: 245, g: 215, b: 35, a: 255 },
			Color{ r: 255, g: 250, b: 160, a: 255 },
			Color{ r: 170, g: 130, b: 15, a: 255 }
		}
		.blue {
			Color{ r: 45, g: 135, b: 245, a: 255 },
			Color{ r: 160, g: 210, b: 255, a: 255 },
			Color{ r: 20, g: 70, b: 160, a: 255 }
		}
	}
}

fn render_virus_cell(renderer &Renderer, texture &Texture, x int, y int, color PillColor, anim_timer f32) {
	if texture != unsafe { nil } {
		frame := int(anim_timer * 4.0) % 2
		v_base := match color {
			.red { 0 }
			.yellow { 2 }
			.blue { 4 }
		}
		src := Rect{ x: (v_base + frame) * 32, y: 96, w: 32, h: 32 }
		dst := Rect{ x: x, y: y, w: 24, h: 24 }
		render_copy(renderer, texture, &src, &dst)
		return
	}

	blink := int(anim_timer) % 4 == 0

	match color {
		.red {
			// Fever Red Virus (Spiky Angry Face)
			set_render_draw_color(renderer, 240, 40, 40, 255)
			render_fill_rect(renderer, &Rect{ x: x + 4, y: y + 4, w: 16, h: 16 })
			render_fill_rect(renderer, &Rect{ x: x + 1, y: y + 8, w: 3, h: 8 })
			render_fill_rect(renderer, &Rect{ x: x + 20, y: y + 8, w: 3, h: 8 })
			render_fill_rect(renderer, &Rect{ x: x + 8, y: y + 1, w: 8, h: 3 })
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rect(renderer, &Rect{ x: x + 6, y: y + 6, w: 4, h: 6 })
			render_fill_rect(renderer, &Rect{ x: x + 14, y: y + 6, w: 4, h: 6 })
			set_render_draw_color(renderer, 10, 10, 10, 255)
			if !blink {
				render_fill_rect(renderer, &Rect{ x: x + 8, y: y + 8, w: 2, h: 3 })
				render_fill_rect(renderer, &Rect{ x: x + 14, y: y + 8, w: 2, h: 3 })
			}
			render_fill_rect(renderer, &Rect{ x: x + 8, y: y + 15, w: 8, h: 2 })
		}
		.yellow {
			// Chill Yellow Virus (Mischievous Grinning Face)
			set_render_draw_color(renderer, 245, 215, 30, 255)
			render_fill_rect(renderer, &Rect{ x: x + 3, y: y + 5, w: 18, h: 14 })
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rect(renderer, &Rect{ x: x + 6, y: y + 7, w: 4, h: 4 })
			render_fill_rect(renderer, &Rect{ x: x + 14, y: y + 7, w: 4, h: 4 })
			set_render_draw_color(renderer, 10, 10, 10, 255)
			if !blink {
				render_fill_rect(renderer, &Rect{ x: x + 7, y: y + 8, w: 2, h: 2 })
				render_fill_rect(renderer, &Rect{ x: x + 15, y: y + 8, w: 2, h: 2 })
			}
			render_fill_rect(renderer, &Rect{ x: x + 7, y: y + 14, w: 10, h: 3 })
		}
		.blue {
			// Weird Blue Virus (Round Wide-Eyed Face)
			set_render_draw_color(renderer, 45, 140, 245, 255)
			render_fill_rect(renderer, &Rect{ x: x + 4, y: y + 4, w: 16, h: 16 })
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rect(renderer, &Rect{ x: x + 5, y: y + 6, w: 5, h: 5 })
			render_fill_rect(renderer, &Rect{ x: x + 14, y: y + 6, w: 5, h: 5 })
			set_render_draw_color(renderer, 10, 10, 10, 255)
			if !blink {
				render_fill_rect(renderer, &Rect{ x: x + 7, y: y + 8, w: 2, h: 2 })
				render_fill_rect(renderer, &Rect{ x: x + 15, y: y + 8, w: 2, h: 2 })
			}
			render_fill_rect(renderer, &Rect{ x: x + 9, y: y + 14, w: 6, h: 4 })
		}
	}
}

fn render_active_pill(renderer &Renderer, mut g DrMarioGame, ox int, oy int) {
	bx := 300 + ox
	by := 120 + oy
	p := g.active_pill

	match p.orientation {
		.horizontal {
			render_pill_half(renderer, g.sprite_texture, bx + p.x * 24, by + p.y * 24, p.c1, .left)
			render_pill_half(renderer, g.sprite_texture, bx + (p.x + 1) * 24, by + p.y * 24, p.c2, .right)
		}
		.vertical {
			render_pill_half(renderer, g.sprite_texture, bx + p.x * 24, by + p.y * 24, p.c1, .bottom)
			if p.y > 0 {
				render_pill_half(renderer, g.sprite_texture, bx + p.x * 24, by + (p.y - 1) * 24, p.c2, .top)
			}
		}
	}
}

fn render_microscope_dish(renderer &Renderer, mut g DrMarioGame) {
	mx := 140
	my := 320

	// Metal Circular Microscope Bezel
	set_render_draw_color(renderer, 160, 175, 195, 255)
	render_fill_rect(renderer, &Rect{ x: mx - 74, y: my - 74, w: 148, h: 148 })

	// Shiny metallic corners
	set_render_draw_color(renderer, 220, 235, 250, 255)
	render_fill_rect(renderer, &Rect{ x: mx - 72, y: my - 72, w: 144, h: 6 })

	// Glass Petri Interior
	set_render_draw_color(renderer, 8, 14, 22, 255)
	render_fill_rect(renderer, &Rect{ x: mx - 66, y: my - 66, w: 132, h: 132 })

	// Wooden Stand
	set_render_draw_color(renderer, 130, 70, 30, 255)
	render_fill_rect(renderer, &Rect{ x: mx - 8, y: my + 74, w: 16, h: 56 })
	render_fill_rect(renderer, &Rect{ x: mx - 30, y: my + 124, w: 60, h: 10 })

	// Dancing Giant Viruses
	wiggle := int(math.sin(f64(g.anim_timer * 3.0)) * 6.0)
	arm_w := int(math.cos(f64(g.anim_timer * 4.0)) * 6.0)
	big_frame := int(g.anim_timer * 3.0) % 2

	// 1. Red Virus (Top)
	if g.red_viruses > 0 {
		rx := mx - 24 + wiggle
		ry := my - 54
		if g.sprite_texture != unsafe { nil } {
			src := Rect{ x: big_frame * 64, y: 128, w: 64, h: 64 }
			dst := Rect{ x: rx, y: ry, w: 48, h: 48 }
			render_copy(renderer, g.sprite_texture, &src, &dst)
		} else {
			set_render_draw_color(renderer, 240, 45, 45, 255)
			render_fill_rect(renderer, &Rect{ x: rx + 6, y: ry + 10, w: 36, h: 32 })
			render_fill_rect(renderer, &Rect{ x: rx, y: ry + 20 + arm_w, w: 6, h: 10 })
			render_fill_rect(renderer, &Rect{ x: rx + 42, y: ry + 20 - arm_w, w: 6, h: 10 })
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rect(renderer, &Rect{ x: rx + 12, y: ry + 16, w: 8, h: 10 })
			render_fill_rect(renderer, &Rect{ x: rx + 28, y: ry + 16, w: 8, h: 10 })
			set_render_draw_color(renderer, 10, 10, 10, 255)
			render_fill_rect(renderer, &Rect{ x: rx + 14, y: ry + 20, w: 4, h: 4 })
			render_fill_rect(renderer, &Rect{ x: rx + 30, y: ry + 20, w: 4, h: 4 })
		}
	}

	// 2. Yellow Virus (Bottom Left)
	if g.yellow_viruses > 0 {
		yx := mx - 54
		yy := my - 2 - wiggle
		if g.sprite_texture != unsafe { nil } {
			src := Rect{ x: (2 + big_frame) * 64, y: 128, w: 64, h: 64 }
			dst := Rect{ x: yx, y: yy, w: 48, h: 48 }
			render_copy(renderer, g.sprite_texture, &src, &dst)
		} else {
			set_render_draw_color(renderer, 245, 220, 35, 255)
			render_fill_rect(renderer, &Rect{ x: yx + 6, y: yy + 8, w: 34, h: 28 })
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rect(renderer, &Rect{ x: yx + 10, y: yy + 13, w: 8, h: 8 })
			render_fill_rect(renderer, &Rect{ x: yx + 26, y: yy + 13, w: 8, h: 8 })
			set_render_draw_color(renderer, 10, 10, 10, 255)
			render_fill_rect(renderer, &Rect{ x: yx + 12, y: yy + 15, w: 4, h: 4 })
			render_fill_rect(renderer, &Rect{ x: yx + 28, y: yy + 15, w: 4, h: 4 })
		}
	}

	// 3. Blue Virus (Bottom Right)
	if g.blue_viruses > 0 {
		bx := mx + 6
		by := my - wiggle
		if g.sprite_texture != unsafe { nil } {
			src := Rect{ x: (4 + big_frame) * 64, y: 128, w: 64, h: 64 }
			dst := Rect{ x: bx, y: by, w: 48, h: 48 }
			render_copy(renderer, g.sprite_texture, &src, &dst)
		} else {
			set_render_draw_color(renderer, 45, 140, 245, 255)
			render_fill_rect(renderer, &Rect{ x: bx + 8, y: by + 8, w: 32, h: 30 })
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rect(renderer, &Rect{ x: bx + 12, y: by + 14, w: 8, h: 8 })
			render_fill_rect(renderer, &Rect{ x: bx + 26, y: by + 14, w: 8, h: 8 })
			set_render_draw_color(renderer, 10, 10, 10, 255)
			render_fill_rect(renderer, &Rect{ x: bx + 14, y: by + 16, w: 4, h: 4 })
			render_fill_rect(renderer, &Rect{ x: bx + 28, y: by + 16, w: 4, h: 4 })
		}
	}
}

fn render_dr_mario_mascot(renderer &Renderer, mut g DrMarioGame) {
	mx := 630
	my := 230

	if g.sprite_texture != unsafe { nil } {
		frame := if g.has_active_pill && g.active_pill.y < 3 { 1 } else { 0 }
		src := Rect{ x: frame * 64, y: 224, w: 64, h: 96 }
		dst := Rect{ x: mx, y: my, w: 64, h: 96 }
		render_copy(renderer, g.sprite_texture, &src, &dst)

		// Next Pill held/tossed by Dr. Mario
		render_pill_half(renderer, g.sprite_texture, mx - 32, my + 30, g.next_c1, .left)
		render_pill_half(renderer, g.sprite_texture, mx - 8, my + 30, g.next_c2, .right)
		return
	}

	// 1. Dr. Mario Head & Cap Mirror (Fallback)
	set_render_draw_color(renderer, 255, 195, 140, 255)
	face := Rect{ x: mx + 10, y: my, w: 36, h: 32 }
	render_fill_rect(renderer, &face)

	// Doctor's Head Mirror
	set_render_draw_color(renderer, 210, 225, 240, 255)
	mirror := Rect{ x: mx + 4, y: my - 6, w: 16, h: 16 }
	render_fill_rect(renderer, &mirror)

	// Eyes & Nose
	set_render_draw_color(renderer, 20, 20, 30, 255)
	render_fill_rect(renderer, &Rect{ x: mx + 16, y: my + 8, w: 4, h: 6 })
	set_render_draw_color(renderer, 255, 180, 120, 255)
	render_fill_rect(renderer, &Rect{ x: mx + 6, y: my + 10, w: 8, h: 8 })

	// Brown Hair & Mustache
	set_render_draw_color(renderer, 100, 50, 20, 255)
	hair := Rect{ x: mx + 16, y: my - 8, w: 32, h: 10 }
	render_fill_rect(renderer, &hair)
	mustache := Rect{ x: mx + 6, y: my + 18, w: 28, h: 8 }
	render_fill_rect(renderer, &mustache)

	// 2. White Doctor's Lab Coat
	set_render_draw_color(renderer, 245, 245, 245, 255)
	coat := Rect{ x: mx + 4, y: my + 32, w: 48, h: 64 }
	render_fill_rect(renderer, &coat)

	// Stethoscope
	set_render_draw_color(renderer, 60, 60, 70, 255)
	steth := Rect{ x: mx + 18, y: my + 34, w: 20, h: 24 }
	render_fill_rect(renderer, &steth)

	// 3. Tossing Arm with Next Pill
	set_render_draw_color(renderer, 245, 245, 245, 255)
	arm := Rect{ x: mx - 20, y: my + 36, w: 26, h: 14 }
	render_fill_rect(renderer, &arm)

	// Next Pill in Hand
	render_pill_half(renderer, unsafe { nil }, mx - 34, my + 32, g.next_c1, .left)
	render_pill_half(renderer, unsafe { nil }, mx - 12, my + 32, g.next_c2, .right)
}

fn render_clipboard_hud(renderer &Renderer, mut g DrMarioGame) {
	// Top Header Bar
	draw_text_shadow(renderer, 30, 20, 'TOP', 2, Color{ r: 240, g: 215, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_shadow(renderer, 30, 42, '${g.high_score:06d}', 2, Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	draw_text_shadow(renderer, 150, 20, 'SCORE', 2, Color{ r: 80, g: 210, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_shadow(renderer, 150, 42, '${g.score:06d}', 2, Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	// Right Clipboard Frame (Level, Speed, Virus Count)
	cx := 570
	cy := 370

	// Wooden Board
	set_render_draw_color(renderer, 140, 85, 45, 255)
	board := Rect{ x: cx, y: cy, w: 180, h: 160 }
	render_fill_rect(renderer, &board)

	// Paper Sheet
	set_render_draw_color(renderer, 240, 240, 225, 255)
	paper := Rect{ x: cx + 8, y: cy + 12, w: 164, h: 136 }
	render_fill_rect(renderer, &paper)

	// Clip
	set_render_draw_color(renderer, 180, 190, 200, 255)
	clip := Rect{ x: cx + 60, y: cy + 4, w: 60, h: 14 }
	render_fill_rect(renderer, &clip)

	// Text Info on Clipboard
	speed_str := match g.speed {
		.low { 'LOW' }
		.med { 'MED' }
		.hi { 'HI' }
	}
	bgm_str := match g.sound_mgr.bgm_type {
		.fever { 'FEVER' }
		.chill { 'CHILL' }
		.off { 'OFF' }
	}

	draw_text_shadow(renderer, cx + 16, cy + 24, 'LEVEL', 2, Color{ r: 40, g: 40, b: 50, a: 255 }, Color{ r: 200, g: 200, b: 200, a: 255 })
	draw_text_shadow(renderer, cx + 105, cy + 24, '${g.level:02d}', 2, Color{ r: 20, g: 80, b: 180, a: 255 }, Color{ r: 200, g: 200, b: 200, a: 255 })

	draw_text_shadow(renderer, cx + 16, cy + 54, 'SPEED', 2, Color{ r: 40, g: 40, b: 50, a: 255 }, Color{ r: 200, g: 200, b: 200, a: 255 })
	draw_text_shadow(renderer, cx + 105, cy + 54, speed_str, 2, Color{ r: 180, g: 30, b: 30, a: 255 }, Color{ r: 200, g: 200, b: 200, a: 255 })

	draw_text_shadow(renderer, cx + 16, cy + 84, 'VIRUS', 2, Color{ r: 40, g: 40, b: 50, a: 255 }, Color{ r: 200, g: 200, b: 200, a: 255 })
	draw_text_shadow(renderer, cx + 105, cy + 84, '${g.viruses_left:02d}', 2, Color{ r: 180, g: 120, b: 20, a: 255 }, Color{ r: 200, g: 200, b: 200, a: 255 })

	draw_text_shadow(renderer, cx + 16, cy + 114, 'BGM', 2, Color{ r: 40, g: 40, b: 50, a: 255 }, Color{ r: 200, g: 200, b: 200, a: 255 })
	draw_text_shadow(renderer, cx + 75, cy + 114, bgm_str, 2, Color{ r: 40, g: 140, b: 60, a: 255 }, Color{ r: 200, g: 200, b: 200, a: 255 })
}

fn render_particles(renderer &Renderer, mut g DrMarioGame) {
	for pt in g.particles {
		if !pt.active {
			continue
		}
		set_render_draw_color(renderer, pt.color.r, pt.color.g, pt.color.b, 255)
		rect := Rect{
			x: int(pt.x)
			y: int(pt.y)
			w: int(pt.size)
			h: int(pt.size)
		}
		render_fill_rect(renderer, &rect)
	}
}

fn render_score_popups(renderer &Renderer, mut g DrMarioGame) {
	for sp in g.score_popups {
		if !sp.active {
			continue
		}
		draw_text_centered_shadow(renderer, int(sp.x), int(sp.y), sp.text, 2,
			sp.color, Color{ r: 0, g: 0, b: 0, a: 255 })
	}
}

fn render_crt_overlay(renderer &Renderer) {
	set_render_draw_blend_mode(renderer, .blend)
	set_render_draw_color(renderer, 0, 0, 0, 24)
	for y := 0; y < 600; y += 3 {
		line := Rect{ x: 0, y: y, w: 800, h: 1 }
		render_fill_rect(renderer, &line)
	}
}

fn render_title_screen(renderer &Renderer, mut g DrMarioGame) {
	set_render_draw_blend_mode(renderer, .blend)
	set_render_draw_color(renderer, 10, 18, 28, 225)
	scrim := Rect{ x: 0, y: 0, w: 800, h: 600 }
	render_fill_rect(renderer, &scrim)

	// Retro Title
	draw_text_centered_shadow(renderer, 400, 40, 'DR. CODECAINE', 5,
		Color{ r: 255, g: 60, b: 60, a: 255 }, Color{ r: 245, g: 220, b: 40, a: 255 })

	draw_text_centered_shadow(renderer, 400, 96, 'VIRUS ELIMINATION PUZZLE (ENHANCED)', 2,
		Color{ r: 80, g: 210, b: 255, a: 255 }, Color{ r: 10, g: 20, b: 40, a: 255 })

	// Start Game Config Box
	spd_name := match g.speed {
		.low { 'LOW' }
		.med { 'MED' }
		.hi { 'HI' }
	}
	bgm_name := match g.sound_mgr.bgm_type {
		.fever { 'FEVER' }
		.chill { 'CHILL' }
		.off { 'OFF' }
	}

	draw_text_centered_shadow(renderer, 400, 138, 'START LEVEL: ${g.level:02d}  (LEFT / RIGHT ARROWS)', 2,
		Color{ r: 255, g: 235, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 164, 'SPEED: ${spd_name} (1/2/3)  |  MUSIC: ${bgm_name} (T KEY)', 2,
		Color{ r: 80, g: 230, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	draw_text_centered_shadow(renderer, 400, 205, 'PRESS SPACE OR ENTER TO START', 2,
		Color{ r: 110, g: 255, b: 130, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	// Modern Controls Box
	draw_text_centered_shadow(renderer, 400, 250, 'MODERN ENHANCED CONTROLS', 2,
		Color{ r: 255, g: 175, b: 45, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 282, 'A / D (LEFT / RIGHT) : MOVE CAPSULE', 1,
		Color{ r: 230, g: 230, b: 230, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 304, 'S (DOWN) : SOFT DROP  |  SPACE / ENTER : HARD DROP', 1,
		Color{ r: 255, g: 235, b: 60, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 326, 'W / UP / J : ROTATE CW  |  K / X : ROTATE CCW', 1,
		Color{ r: 110, g: 255, b: 130, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 348, 'LSHIFT / H : HOLD CAPSULE QUEUE (STASH / SWAP)', 1,
		Color{ r: 255, g: 160, b: 220, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 370, 'G : TOGGLE GHOST PROJECTION SHADOW', 1,
		Color{ r: 100, g: 220, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 392, 'T : SWITCH SOUNDTRACK (FEVER / CHILL / OFF)', 1,
		Color{ r: 255, g: 215, b: 110, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 420, '[P] PAUSE  [M] MUTE  [C] CRT SCANLINES  [R] RESTART  [F11] Fullscreen', 1,
		Color{ r: 180, g: 180, b: 190, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	draw_text_centered_shadow(renderer, 400, 560, '(C) 1990 NINTENDO R&D1', 1,
		Color{ r: 150, g: 150, b: 160, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}

fn render_paused_screen(renderer &Renderer) {
	set_render_draw_blend_mode(renderer, .blend)
	set_render_draw_color(renderer, 0, 0, 0, 190)
	scrim := Rect{ x: 0, y: 0, w: 800, h: 600 }
	render_fill_rect(renderer, &scrim)

	draw_text_centered_shadow(renderer, 400, 270, 'PAUSED', 4,
		Color{ r: 255, g: 230, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 320, 'PRESS P TO RESUME', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}

fn render_stage_clear_screen(renderer &Renderer, mut g DrMarioGame) {
	set_render_draw_blend_mode(renderer, .blend)
	set_render_draw_color(renderer, 0, 0, 0, 185)
	scrim := Rect{ x: 0, y: 0, w: 800, h: 600 }
	render_fill_rect(renderer, &scrim)

	// Flashing Victory Banner
	set_render_draw_color(renderer, 240, 210, 40, 255)
	render_fill_rect(renderer, &Rect{ x: 120, y: 190, w: 560, h: 6 })
	render_fill_rect(renderer, &Rect{ x: 120, y: 390, w: 560, h: 6 })

	draw_text_centered_shadow(renderer, 400, 220, 'STAGE CLEAR!', 4,
		Color{ r: 80, g: 255, b: 110, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 280, 'ALL VIRUSES ERADICATED!', 2,
		Color{ r: 255, g: 235, b: 60, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	next_lvl := if g.level < 20 { g.level + 1 } else { 20 }
	draw_text_centered_shadow(renderer, 400, 335, 'ADVANCING TO LEVEL ${next_lvl:02d}', 2,
		Color{ r: 100, g: 230, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 365, 'PRESS SPACE OR WAIT TO PROCEED', 1,
		Color{ r: 240, g: 240, b: 240, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}

fn render_game_over_screen(renderer &Renderer, mut g DrMarioGame) {
	set_render_draw_blend_mode(renderer, .blend)
	set_render_draw_color(renderer, 0, 0, 0, 210)
	scrim := Rect{ x: 0, y: 0, w: 800, h: 600 }
	render_fill_rect(renderer, &scrim)

	draw_text_centered_shadow(renderer, 400, 230, 'GAME OVER', 5,
		Color{ r: 255, g: 40, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 300, 'FINAL SCORE: ${g.score}', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 360, 'PRESS SPACE TO RETRY', 2,
		Color{ r: 255, g: 230, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}
