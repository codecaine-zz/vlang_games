module main

import math
import os

pub struct PoolTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm PoolTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/pool.png',
		'./assets/sprites/pool.png',
		'../assets/sprites/pool.png',
		'pool/assets/sprites/pool.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('pool Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

fn draw_pool_game(renderer &Renderer, g &PoolGame, tex &Texture) {
	// VIP Billiard Lounge with hardwood floor & overhead pendant lamp illumination
	draw_room_background(renderer, g)

	draw_table_wood_rim(renderer, g)
	draw_table_felt(renderer, g)
	draw_pockets(renderer, g)
	draw_balls(renderer, g, tex)
	draw_cue_stick(renderer, g)
	draw_aiming_guideline(renderer, g)
	draw_pool_hud(renderer, g)
	draw_celebration(renderer, g)
}

fn draw_room_background(renderer &Renderer, g &PoolGame) {
	// Deep retro pool hall background with subtle wooden floor planks
	for y := 0; y < 600; y += 4 {
		shade := u8(12 + (y * 8) / 600)
		set_render_draw_color(renderer, shade + 2, shade, shade + 6, 255)
		rect := Rect{ x: 0, y: y, w: 800, h: 4 }
		render_fill_rect(renderer, &rect)
	}

	// Floor plank lines
	for y := 0; y < 600; y += 50 {
		set_render_draw_color(renderer, 8, 7, 12, 255)
		render_draw_line(renderer, 0, y, 800, y)
	}

	// Overhead table pendant lamp spotlight cone (illuminating table center)
	cx := int(g.table_x + g.table_w / 2.0)
	cy := int(g.table_y + g.table_h / 2.0)

	// Translucent warm overhead glow
	for r := 260; r > 100; r -= 20 {
		alpha := u8((260 - r) / 8)
		set_render_draw_color(renderer, 255, 245, 200, alpha)
		draw_circle_wire(renderer, cx, cy, r, Color{ r: 255, g: 245, b: 200, a: alpha })
	}
}

fn draw_table_wood_rim(renderer &Renderer, g &PoolGame) {
	tx := int(g.table_x)
	ty := int(g.table_y)
	tw := int(g.table_w)
	th := int(g.table_h)

	// Polished Mahogany Outer Cushion Frame
	set_render_draw_color(renderer, 58, 28, 16, 255)
	rim_rect := Rect{ x: tx, y: ty, w: tw, h: th }
	render_fill_rect(renderer, &rim_rect)

	// Wood Grain Bevel Layer
	set_render_draw_color(renderer, 85, 42, 24, 255)
	inner_rim1 := Rect{ x: tx + 4, y: ty + 4, w: tw - 8, h: th - 8 }
	render_draw_rect(renderer, &inner_rim1)

	set_render_draw_color(renderer, 35, 16, 10, 255)
	inner_rim2 := Rect{ x: tx + 8, y: ty + 8, w: tw - 16, h: th - 16 }
	render_draw_rect(renderer, &inner_rim2)

	// Inlaid Mother-of-Pearl Diamond Sights (3 along short rails, 6 along long rails)
	// Top & Bottom Rails
	for i := 1; i <= 6; i++ {
		dx := tx + int(f64(tw) * (f64(i) / 7.0))
		draw_pearl_diamond(renderer, dx, ty + 10)
		draw_pearl_diamond(renderer, dx, ty + th - 14)
	}
	// Left & Right Rails
	for i := 1; i <= 3; i++ {
		dy := ty + int(f64(th) * (f64(i) / 4.0))
		draw_pearl_diamond(renderer, tx + 10, dy)
		draw_pearl_diamond(renderer, tx + tw - 14, dy)
	}

	// Brass Corner Castings & Pocket Rim Plates
	draw_brass_corner_plate(renderer, tx, ty, 32, 32, 0)
	draw_brass_corner_plate(renderer, tx + tw - 32, ty, 32, 32, 1)
	draw_brass_corner_plate(renderer, tx, ty + th - 32, 32, 32, 2)
	draw_brass_corner_plate(renderer, tx + tw - 32, ty + th - 32, 32, 32, 3)

	// Middle Pocket Brass Castings
	draw_brass_side_plate(renderer, tx + tw / 2 - 16, ty, 32, 14)
	draw_brass_side_plate(renderer, tx + tw / 2 - 16, ty + th - 14, 32, 14)
}

fn draw_pearl_diamond(renderer &Renderer, x int, y int) {
	// Diamond Shape Mother of Pearl Inlay
	set_render_draw_color(renderer, 245, 242, 230, 255)
	render_draw_line(renderer, x, y - 3, x + 3, y)
	render_draw_line(renderer, x + 3, y, x, y + 3)
	render_draw_line(renderer, x, y + 3, x - 3, y)
	render_draw_line(renderer, x - 3, y, x, y - 3)

	set_render_draw_color(renderer, 255, 255, 255, 255)
	render_draw_point(renderer, x, y)
	render_draw_point(renderer, x, y - 1)
}

fn draw_brass_corner_plate(renderer &Renderer, x int, y int, w int, h int, _corner int) {
	set_render_draw_color(renderer, 185, 150, 55, 255)
	rect := Rect{ x: x, y: y, w: w, h: h }
	render_fill_rect(renderer, &rect)

	set_render_draw_color(renderer, 240, 215, 115, 255)
	render_draw_line(renderer, x, y, x + w, y)
	render_draw_line(renderer, x, y, x, y + h)

	set_render_draw_color(renderer, 90, 60, 20, 255)
	render_draw_line(renderer, x, y + h - 1, x + w, y + h - 1)
	render_draw_line(renderer, x + w - 1, y, x + w - 1, y + h)

	// Rivet
	set_render_draw_color(renderer, 40, 25, 10, 255)
	render_draw_point(renderer, x + w / 2, y + h / 2)
}

fn draw_brass_side_plate(renderer &Renderer, x int, y int, w int, h int) {
	set_render_draw_color(renderer, 185, 150, 55, 255)
	rect := Rect{ x: x, y: y, w: w, h: h }
	render_fill_rect(renderer, &rect)

	set_render_draw_color(renderer, 240, 215, 115, 255)
	render_draw_rect(renderer, &rect)
}

fn draw_table_felt(renderer &Renderer, g &PoolGame) {
	fx := int(g.table_x + g.cushion_thick)
	fy := int(g.table_y + g.cushion_thick)
	fw := int(g.table_w - g.cushion_thick * 2.0)
	fh := int(g.table_h - g.cushion_thick * 2.0)

	// Tournament Green Woolen Baize (Gradient with spotlight center)
	for y := 0; y < fh; y += 4 {
		// Vignette factor: darker at table boundaries, rich emerald in center
		norm_y := f64(y) / f64(fh) - 0.5
		vignette := math.max(0.0, 1.0 - (norm_y * norm_y * 1.8))

		r := u8(14.0 + vignette * 10.0)
		gr := u8(105.0 + vignette * 35.0)
		b := u8(55.0 + vignette * 25.0)

		set_render_draw_color(renderer, r, gr, b, 255)
		f_strip := Rect{ x: fx, y: fy + y, w: fw, h: 4 }
		render_fill_rect(renderer, &f_strip)
	}

	// Cushion Nose Edge Shadow (Under rail drop bevel)
	set_render_draw_color(renderer, 8, 45, 25, 180)
	render_draw_line(renderer, fx, fy, fx + fw, fy)
	render_draw_line(renderer, fx, fy + 1, fx + fw, fy + 1)
	render_draw_line(renderer, fx, fy, fx, fy + fh)
	render_draw_line(renderer, fx + 1, fy, fx + 1, fy + fh)

	// Head String Line & Head Spot
	set_render_draw_color(renderer, 45, 175, 105, 140)
	hx := int(g.table_x + g.table_w * 0.28)
	render_draw_line(renderer, hx, fy + 2, hx, fy + fh - 2)

	// Head Spot & Foot Spot
	draw_felt_spot(renderer, hx, fy + fh / 2)
	fx_spot := int(g.table_x + g.table_w * 0.72)
	draw_felt_spot(renderer, fx_spot, fy + fh / 2)
}

fn draw_felt_spot(renderer &Renderer, x int, y int) {
	set_render_draw_color(renderer, 240, 245, 255, 220)
	spot := Rect{ x: x - 2, y: y - 2, w: 4, h: 4 }
	render_fill_rect(renderer, &spot)
	set_render_draw_color(renderer, 10, 60, 30, 255)
	render_draw_point(renderer, x, y)
}

fn draw_pockets(renderer &Renderer, g &PoolGame) {
	for p in g.pockets {
		px := int(p.x)
		py := int(p.y)
		r := int(p.radius)

		// Deep Dark Pocket Interior Drop Hole
		draw_filled_circle(renderer, px, py, r + 2, Color{ r: 6, g: 8, b: 12 })

		// Leather Drop Netting Ring
		draw_circle_wire(renderer, px, py, r, Color{ r: 35, g: 25, b: 20 })

		// Polished Brass Pocket Bevel Outer Ring
		draw_circle_wire(renderer, px, py, r + 1, Color{ r: 210, g: 175, b: 70 })
	}
}

fn draw_balls(renderer &Renderer, g &PoolGame, tex &Texture) {
	for b in g.balls {
		if b.potted { continue }

		bx := int(b.x)
		by := int(b.y)
		r := int(b.radius)

		// Dynamic Multi-Layer Contact Shadow on Felt
		set_render_draw_color(renderer, 0, 0, 0, 80)
		s_outer := Rect{ x: bx - r + 3, y: by - r + 5, w: r * 2, h: r * 2 }
		render_fill_rect(renderer, &s_outer)
		set_render_draw_color(renderer, 0, 0, 0, 140)
		s_inner := Rect{ x: bx - r + 4, y: by - r + 6, w: r * 2 - 4, h: r * 2 - 4 }
		render_fill_rect(renderer, &s_inner)

		if tex != unsafe { nil } {
			row := if b.id < 8 { 0 } else { 1 }
			col := if b.id < 8 { b.id } else { b.id - 8 }
			src := Rect{ x: col * 32, y: row * 32, w: 32, h: 32 }
			dst := Rect{ x: bx - r, y: by - r, w: r * 2, h: r * 2 }
			render_copy(renderer, tex, &src, &dst)

			if b.id > 0 {
				num_str := '${b.id}'
				draw_text_centered(renderer, bx, by - 3, num_str, 1, Color{ r: 10, g: 12, b: 16 })
			}
			continue
		}

		// Base Ball Color Palette
		c := get_ball_color(b.id)

		// 16-Bit Radial Spherical Shading
		for dy := -r; dy <= r; dy++ {
			for dx := -r; dx <= r; dx++ {
				dist_sq := dx * dx + dy * dy
				if dist_sq <= r * r {
					// Light from top-left (-r/3, -r/3)
					lx := dx + (r / 3)
					ly := dy + (r / 3)
					light_dist := math.sqrt(f64(lx * lx + ly * ly))
					norm_light := math.max(0.0, 1.0 - (light_dist / f64(r * 2)))

					// Stepped shading factor
					shade_step := int(norm_light * 6.0)
					factor := 0.45 + (f64(shade_step) / 6.0) * 0.85

					// Determine if this pixel is inside the stripe zone for striped balls (9-15)
					is_stripe_ball := (!b.is_solid && !b.is_cue && !b.is_eight)
					mut pixel_color := c

					if is_stripe_ball {
						// Horizontal stripe belt across middle (-4 .. +4)
						if dy < -4 || dy > 4 {
							// Polar cap: Ivory White
							pixel_color = Color{ r: 245, g: 242, b: 235 }
						}
					}

					mut pr := u8(math.min(255.0, f64(pixel_color.r) * factor))
					mut pg := u8(math.min(255.0, f64(pixel_color.g) * factor))
					mut pb := u8(math.min(255.0, f64(pixel_color.b) * factor))

					// Specular glossy highlight glint
					if lx * lx + ly * ly <= (r * r) / 10 {
						pr = 255
						pg = 255
						pb = 255
					}

					set_render_draw_color(renderer, pr, pg, pb, 255)
					render_draw_point(renderer, bx + dx, by + dy)
				}
			}
		}

		// Number Badge Circle (Except Cue Ball)
		if !b.is_cue {
			badge_r := 5
			draw_filled_circle(renderer, bx, by, badge_r, Color{ r: 252, g: 250, b: 245 })
			num_str := '${b.id}'
			// Crisp 16-bit number label
			draw_text_centered(renderer, bx, by - 3, num_str, 1, Color{ r: 10, g: 12, b: 16 })
		} else {
			// Red dot on cue ball for spin indicator
			set_render_draw_color(renderer, 220, 40, 40, 255)
			render_draw_point(renderer, bx + 1, by)
		}
	}
}

fn get_ball_color(id int) Color {
	return match id {
		0      { Color{ r: 250, g: 248, b: 242 } } // Cue Ball (Ivory White)
		1, 9   { Color{ r: 250, g: 215, b: 35 } }  // 1 & 9: Canary Yellow
		2, 10  { Color{ r: 30, g: 85, b: 220 } }   // 2 & 10: Cobalt Blue
		3, 11  { Color{ r: 225, g: 45, b: 45 } }   // 3 & 11: Crimson Red
		4, 12  { Color{ r: 125, g: 40, b: 170 } }  // 4 & 12: Royal Violet
		5, 13  { Color{ r: 245, g: 120, b: 25 } }  // 5 & 13: Tangerine Orange
		6, 14  { Color{ r: 28, g: 145, b: 55 } }   // 6 & 14: Emerald Green
		7, 15  { Color{ r: 145, g: 30, b: 38 } }   // 7 & 15: Deep Burgundy
		8      { Color{ r: 20, g: 22, b: 28 } }    // 8: Ebony Black
		else   { Color{ r: 210, g: 210, b: 210 } }
	}
}

fn draw_aiming_guideline(renderer &Renderer, g &PoolGame) {
	if g.state != .aiming && g.state != .power_pull {
		return
	}
	if g.balls.len == 0 || g.balls[0].potted {
		return
	}

	cx := g.balls[0].x
	cy := g.balls[0].y

	// Raycast forward to find first object ball hit or cushion
	mut ray_len := 420.0
	mut hit_ball_idx := -1

	for idx, b in g.balls {
		if idx == 0 || b.potted { continue }

		dx := b.x - cx
		dy := b.y - cy

		aim_dir_x := math.cos(g.aim_angle)
		aim_dir_y := math.sin(g.aim_angle)
		dot := dx * aim_dir_x + dy * aim_dir_y

		if dot > 0.0 && dot < ray_len {
			perp_dist := math.abs(dx * aim_dir_y - dy * aim_dir_x)
			if perp_dist < 22.0 {
				ray_len = dot - math.sqrt(484.0 - perp_dist * perp_dist)
				hit_ball_idx = idx
			}
		}
	}

	end_x := cx + math.cos(g.aim_angle) * ray_len
	end_y := cy + math.sin(g.aim_angle) * ray_len

	// Dotted Glowing Aiming Line
	dots := int(ray_len / 12.0)
	for i := 0; i <= dots; i++ {
		t := f64(i) / f64(dots)
		dx := cx + (end_x - cx) * t
		dy := cy + (end_y - cy) * t

		set_render_draw_color(renderer, 255, 255, 255, 200)
		render_draw_point(renderer, int(dx), int(dy))
		render_draw_point(renderer, int(dx + 1), int(dy))
	}

	// Ghost Ball Projection at Impact Point
	if hit_ball_idx != -1 {
		draw_circle_wire(renderer, int(end_x), int(end_y), 11, Color{ r: 255, g: 255, b: 255, a: 220 })
		draw_circle_wire(renderer, int(end_x), int(end_y), 12, Color{ r: 0, g: 230, b: 255, a: 180 })

		// Deflection trajectory vector for object ball
		tb := g.balls[hit_ball_idx]
		obj_dir_x := tb.x - end_x
		obj_dir_y := tb.y - end_y
		obj_dist := math.sqrt(obj_dir_x * obj_dir_x + obj_dir_y * obj_dir_y)
		if obj_dist > 0.001 {
			nx := obj_dir_x / obj_dist
			ny := obj_dir_y / obj_dist
			deflect_x := tb.x + nx * 70.0
			deflect_y := tb.y + ny * 70.0

			// Golden object ball rebound vector
			set_render_draw_color(renderer, 255, 215, 0, 240)
			render_draw_line(renderer, int(tb.x), int(tb.y), int(deflect_x), int(deflect_y))
			render_draw_line(renderer, int(tb.x + 1), int(tb.y), int(deflect_x + 1), int(deflect_y))

			// Arrowhead
			render_draw_line(renderer, int(deflect_x), int(deflect_y), int(deflect_x - nx * 8.0 + ny * 4.0), int(deflect_y - ny * 8.0 - nx * 4.0))
			render_draw_line(renderer, int(deflect_x), int(deflect_y), int(deflect_x - nx * 8.0 - ny * 4.0), int(deflect_y - ny * 8.0 + nx * 4.0))
		}
	}
}

fn draw_cue_stick(renderer &Renderer, g &PoolGame) {
	if g.state != .aiming && g.state != .power_pull {
		return
	}
	if g.balls.len == 0 || g.balls[0].potted {
		return
	}

	cx := g.balls[0].x
	cy := g.balls[0].y

	// Pull-back offset based on shot power
	pull_offset := 20.0 + g.cue_power * 45.0
	cue_len := 200.0

	tip_x := cx - math.cos(g.aim_angle) * pull_offset
	tip_y := cy - math.sin(g.aim_angle) * pull_offset
	butt_x := tip_x - math.cos(g.aim_angle) * cue_len
	butt_y := tip_y - math.sin(g.aim_angle) * cue_len

	// 16-Bit Tapered Maple Cue Stick

	// Cue Shaft (Hard Rock Maple)
	set_render_draw_color(renderer, 225, 195, 150, 255)
	render_draw_line(renderer, int(tip_x), int(tip_y), int(butt_x), int(butt_y))
	render_draw_line(renderer, int(tip_x + 1), int(tip_y), int(butt_x + 1), int(butt_y))

	// Brass Ferrule
	ferrule_x := tip_x - math.cos(g.aim_angle) * 8.0
	ferrule_y := tip_y - math.sin(g.aim_angle) * 8.0
	set_render_draw_color(renderer, 240, 210, 80, 255)
	render_draw_line(renderer, int(tip_x), int(tip_y), int(ferrule_x), int(ferrule_y))

	// Blue Chalk Tip
	set_render_draw_color(renderer, 30, 140, 230, 255)
	render_draw_line(renderer, int(tip_x), int(tip_y), int(tip_x - math.cos(g.aim_angle) * 3.0), int(tip_y - math.sin(g.aim_angle) * 3.0))

	// Irish Linen Grip Wrap (Textured Black & White Speckle)
	grip_len := 70.0
	grip_start_x := butt_x + math.cos(g.aim_angle) * grip_len
	grip_start_y := butt_y + math.sin(g.aim_angle) * grip_len

	set_render_draw_color(renderer, 32, 28, 25, 255)
	render_draw_line(renderer, int(grip_start_x), int(grip_start_y), int(butt_x), int(butt_y))
	set_render_draw_color(renderer, 180, 175, 160, 255)
	render_draw_point(renderer, int((grip_start_x + butt_x) / 2), int((grip_start_y + butt_y) / 2))

	// Cue Butt Cap (White Phenolic)
	set_render_draw_color(renderer, 245, 245, 250, 255)
	render_draw_point(renderer, int(butt_x), int(butt_y))
}

fn draw_pool_hud(renderer &Renderer, g &PoolGame) {
	// Top Header Arcade Scoreboard
	panel_w := 760
	panel_h := 66
	px := (800 - panel_w) / 2
	py := 8

	// Beveled Arcade HUD Box
	draw_pool_box(renderer, px, py, panel_w, panel_h)

	mode_str := match g.typ {
		.eight_ball  { '8-BALL TOURNAMENT POOL' }
		.nine_ball   { '9-BALL SPEED POOL' }
		.practice    { 'FREE PRACTICE / TRICK SHOTS' }
	}
	draw_text(renderer, px + 14, py + 8, mode_str, 1, Color{ r: 255, g: 215, b: 0 })

	// Active Player and Assigned Ball Group
	p := g.players[g.current_p_idx]
	group_str := match p.group {
		.solids   { 'SOLIDS (1-7)' }
		.stripes  { 'STRIPES (9-15)' }
		else      { 'OPEN TABLE' }
	}
	draw_text(renderer, px + 14, py + 26, '${p.name.to_upper()} TURN: ${group_str}', 1, Color{ r: 0, g: 255, b: 190 })

	// Power Gauge Meter (Right side of HUD)
	bar_w := 150
	bar_h := 16
	bar_x := px + panel_w - bar_w - 20
	bar_y := py + 26

	draw_text(renderer, bar_x, py + 8, 'SHOT POWER', 1, Color{ r: 210, g: 225, b: 255 })
	bg_rect := Rect{ x: bar_x, y: bar_y, w: bar_w, h: bar_h }
	set_render_draw_color(renderer, 20, 24, 36, 255)
	render_fill_rect(renderer, &bg_rect)

	// Multi-tone Power Fill
	fill_w := int(f64(bar_w) * g.cue_power)
	for pw := 0; pw < fill_w; pw++ {
		progress := f64(pw) / f64(bar_w)
		col := if progress > 0.8 {
			Color{ r: 255, g: 50, b: 60 }
		} else if progress > 0.5 {
			Color{ r: 255, g: 200, b: 30 }
		} else {
			Color{ r: 40, g: 210, b: 120 }
		}
		set_render_draw_color(renderer, col.r, col.g, col.b, 255)
		render_draw_line(renderer, bar_x + pw, bar_y + 1, bar_x + pw, bar_y + bar_h - 2)
	}

	set_render_draw_color(renderer, 130, 145, 175, 255)
	render_draw_rect(renderer, &bg_rect)

	// Bottom Controls Guide Bar
	help_text := '[MOUSE / ARROWS] AIM  |  [HOLD SPACE / CLICK DRAG] STRIKE  |  [1-3] MODES  |  [M] SOUND  |  [R] RE-RACK'
	draw_text_centered(renderer, 400, 568, help_text, 1, Color{ r: 160, g: 180, b: 210 })

	if g.state == .ball_in_hand {
		draw_text_centered(renderer, 400, 500, 'BALL IN HAND: CLICK TABLE TO PLACE CUE BALL', 1, Color{ r: 255, g: 225, b: 50 })
	}
}

fn draw_pool_box(renderer &Renderer, x int, y int, w int, h int) {
	bg := Rect{ x: x, y: y, w: w, h: h }
	set_render_draw_color(renderer, 14, 18, 30, 245)
	render_fill_rect(renderer, &bg)

	// Metallic Bevel Highlights
	set_render_draw_color(renderer, 75, 90, 120, 255)
	render_draw_line(renderer, x, y, x + w, y)
	render_draw_line(renderer, x, y, x, y + h)

	set_render_draw_color(renderer, 8, 10, 16, 255)
	render_draw_line(renderer, x, y + h - 1, x + w, y + h - 1)
	render_draw_line(renderer, x + w - 1, y, x + w - 1, y + h)

	// Cyan accent line
	set_render_draw_color(renderer, 0, 190, 240, 200)
	inner := Rect{ x: x + 2, y: y + 2, w: w - 4, h: h - 4 }
	render_draw_rect(renderer, &inner)
}

fn draw_celebration(renderer &Renderer, g &PoolGame) {
	if g.celebration != '' {
		box_w := 480
		box_h := 64
		bx := (800 - box_w) / 2
		by := 250

		draw_pool_box(renderer, bx, by, box_w, box_h)

		// Gold Border
		set_render_draw_color(renderer, 255, 215, 0, 255)
		inner := Rect{ x: bx + 4, y: by + 4, w: box_w - 8, h: box_h - 8 }
		render_draw_rect(renderer, &inner)

		draw_text_centered(renderer, 402, by + 24, g.celebration, 2, Color{ r: 35, g: 15, b: 0 })
		draw_text_centered(renderer, 400, by + 22, g.celebration, 2, Color{ r: 255, g: 225, b: 50 })
	}
}

fn draw_filled_circle(renderer &Renderer, cx int, cy int, r int, c Color) {
	set_render_draw_color(renderer, c.r, c.g, c.b, c.a)
	for dy := -r; dy <= r; dy++ {
		for dx := -r; dx <= r; dx++ {
			if dx * dx + dy * dy <= r * r {
				render_draw_point(renderer, cx + dx, cy + dy)
			}
		}
	}
}

fn draw_circle_wire(renderer &Renderer, cx int, cy int, r int, c Color) {
	set_render_draw_color(renderer, c.r, c.g, c.b, c.a)
	steps := 48
	for i := 0; i < steps; i++ {
		a1 := f64(i) * 2.0 * math.pi / f64(steps)
		a2 := f64(i + 1) * 2.0 * math.pi / f64(steps)
		x1 := int(f64(cx) + math.cos(a1) * f64(r))
		y1 := int(f64(cy) + math.sin(a1) * f64(r))
		x2 := int(f64(cx) + math.cos(a2) * f64(r))
		y2 := int(f64(cy) + math.sin(a2) * f64(r))
		render_draw_line(renderer, x1, y1, x2, y2)
	}
}
