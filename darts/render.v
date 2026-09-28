module main

import gg
import math
import os



pub struct DartsTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn new_darts_texture_manager() DartsTextureManager {
	return DartsTextureManager{}
}

pub fn (mut tm DartsTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/darts.png',
		'./assets/sprites/darts.png',
		'../assets/sprites/darts.png',
		'darts/assets/sprites/darts.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('darts Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

fn draw_darts_game(renderer &Renderer, g &DartsGame, tex &Texture) {
	draw_pub_background(renderer)
	draw_dartboard_cabinet(renderer, g)
	draw_dartboard(renderer, g)
	draw_board_darts(renderer, g, tex)
	draw_aim_reticle(renderer, g, tex)
	draw_chalkboard_hud(renderer, g, tex)
	draw_celebration(renderer, g, tex)
}

fn draw_pub_background(renderer &Renderer) {
	min_x, _, max_x, _ := renderer.visible_bounds()
	bg_x := int(min_x) - 4
	bg_w := int(math.max(800.0, max_x - min_x)) + 8

	for y := 0; y < 620; y += 4 {
		shade := u8(16 + (y * 10) / 620)
		set_render_draw_color(renderer, shade + 4, shade, shade - 2, 255)
		rect := Rect{ x: bg_x, y: y, w: bg_w, h: 4 }
		render_fill_rect(renderer, &rect)
	}

	for x := bg_x; x < bg_x + bg_w; x += 160 {
		set_render_draw_color(renderer, 10, 8, 6, 255)
		render_draw_line(renderer, x, 0, x, 620)
		set_render_draw_color(renderer, 35, 25, 18, 255)
		render_draw_line(renderer, x + 1, 0, x + 1, 620)
	}
}

fn draw_dartboard_cabinet(renderer &Renderer, g &DartsGame) {
	cx := int(g.board_center_x)
	cy := int(g.board_center_y)

	cabinet_w := 480
	cabinet_h := 480
	cab_x := cx - cabinet_w / 2
	cab_y := cy - cabinet_h / 2

	set_render_draw_color(renderer, 48, 26, 16, 255)
	cab_rect := Rect{ x: cab_x, y: cab_y, w: cabinet_w, h: cabinet_h }
	render_fill_rect(renderer, &cab_rect)

	set_render_draw_color(renderer, 75, 42, 24, 255)
	render_draw_rect(renderer, &cab_rect)
	set_render_draw_color(renderer, 25, 14, 8, 255)
	inner_rim := Rect{ x: cab_x + 3, y: cab_y + 3, w: cabinet_w - 6, h: cabinet_h - 6 }
	render_draw_rect(renderer, &inner_rim)

	draw_brass_bracket(renderer, cab_x + 6, cab_y + 6)
	draw_brass_bracket(renderer, cab_x + cabinet_w - 22, cab_y + 6)
	draw_brass_bracket(renderer, cab_x + 6, cab_y + cabinet_h - 22)
	draw_brass_bracket(renderer, cab_x + cabinet_w - 22, cab_y + cabinet_h - 22)

	for r := int(r_board_outer) + 20; r > int(r_board_outer); r -= 4 {
		alpha := u8((int(r_board_outer) + 24 - r) * 4)
		set_render_draw_color(renderer, 255, 240, 190, alpha)
		draw_circle_wire(renderer, cx, cy, r, Color{ r: 255, g: 240, b: 190, a: alpha })
	}
}

fn draw_brass_bracket(renderer &Renderer, x int, y int) {
	set_render_draw_color(renderer, 180, 140, 45, 255)
	rect := Rect{ x: x, y: y, w: 16, h: 16 }
	render_fill_rect(renderer, &rect)
	set_render_draw_color(renderer, 240, 210, 80, 255)
	render_draw_line(renderer, x, y, x + 16, y)
	render_draw_line(renderer, x, y, x, y + 16)
	set_render_draw_color(renderer, 100, 75, 20, 255)
	render_draw_line(renderer, x + 15, y, x + 15, y + 16)
	render_draw_line(renderer, x, y + 15, x + 16, y + 15)
}

fn draw_dartboard(renderer &Renderer, g &DartsGame) {
	cx := int(g.board_center_x)
	cy := int(g.board_center_y)

	draw_filled_circle(renderer, cx, cy, int(r_board_outer), Color{ r: 18, g: 18, b: 18 })
	draw_filled_circle(renderer, cx, cy, int(r_double_out), Color{ r: 25, g: 25, b: 25 })

	angle_step := (2.0 * math.pi) / 20.0
	start_offset := -math.pi / 2.0 - (angle_step / 2.0)

	for i := 0; i < 20; i++ {
		a1 := start_offset + f64(i) * angle_step
		a2 := a1 + angle_step

		is_even := i % 2 == 0
		col_single := if is_even { Color{ r: 245, g: 235, b: 210 } } else { Color{ r: 20, g: 20, b: 20 } }
		col_ring := if is_even { Color{ r: 220, g: 30, b: 30 } } else { Color{ r: 35, g: 155, b: 65 } }

		draw_pie_slice(renderer, cx, cy, r_outer_bull, r_triple_in, a1, a2, col_single)
		draw_pie_slice(renderer, cx, cy, r_triple_in, r_triple_out, a1, a2, col_ring)
		draw_pie_slice(renderer, cx, cy, r_triple_out, r_double_in, a1, a2, col_single)
		draw_pie_slice(renderer, cx, cy, r_double_in, r_double_out, a1, a2, col_ring)
	}

	draw_filled_circle(renderer, cx, cy, int(r_outer_bull), Color{ r: 35, g: 155, b: 65 })
	draw_filled_circle(renderer, cx, cy, int(r_double_bull), Color{ r: 220, g: 30, b: 30 })

	wire_col := Color{ r: 210, g: 215, b: 220 }
	draw_circle_wire(renderer, cx, cy, int(r_double_bull), wire_col)
	draw_circle_wire(renderer, cx, cy, int(r_outer_bull), wire_col)
	draw_circle_wire(renderer, cx, cy, int(r_triple_in), wire_col)
	draw_circle_wire(renderer, cx, cy, int(r_triple_out), wire_col)
	draw_circle_wire(renderer, cx, cy, int(r_double_in), wire_col)
	draw_circle_wire(renderer, cx, cy, int(r_double_out), wire_col)

	for i := 0; i < 20; i++ {
		a := start_offset + f64(i) * angle_step
		x1 := cx + int(r_outer_bull * math.cos(a))
		y1 := cy + int(r_outer_bull * math.sin(a))
		x2 := cx + int(r_double_out * math.cos(a))
		y2 := cy + int(r_double_out * math.sin(a))
		set_render_draw_color(renderer, wire_col.r, wire_col.g, wire_col.b, 255)
		render_draw_line(renderer, x1, y1, x2, y2)
	}

	num_r := (r_double_out + r_board_outer) / 2.0
	for i := 0; i < 20; i++ {
		mid_a := -math.pi / 2.0 + f64(i) * angle_step
		nx := cx + int(num_r * math.cos(mid_a))
		ny := cy + int(num_r * math.sin(mid_a))
		num_str := '${dart_segments[i]}'
		draw_text_centered(renderer, nx, ny - 6, num_str, 2, Color{ r: 240, g: 240, b: 240 })
	}
}

fn draw_pie_slice(renderer &Renderer, cx int, cy int, r_in f64, r_out f64, a1 f64, a2 f64, col Color) {
	steps := 12
	da := (a2 - a1) / f64(steps)

	mut ren := unsafe { &Renderer(renderer) }
	ren.update_viewport()

	for s := 0; s < steps; s++ {
		sa1 := a1 + f64(s) * da
		sa2 := sa1 + da

		x1 := ren.offset_x + f32(cx + int(r_in * math.cos(sa1))) * ren.scale
		y1 := ren.offset_y + f32(cy + int(r_in * math.sin(sa1))) * ren.scale
		x2 := ren.offset_x + f32(cx + int(r_out * math.cos(sa1))) * ren.scale
		y2 := ren.offset_y + f32(cy + int(r_out * math.sin(sa1))) * ren.scale
		x3 := ren.offset_x + f32(cx + int(r_out * math.cos(sa2))) * ren.scale
		y3 := ren.offset_y + f32(cy + int(r_out * math.sin(sa2))) * ren.scale
		x4 := ren.offset_x + f32(cx + int(r_in * math.cos(sa2))) * ren.scale
		y4 := ren.offset_y + f32(cy + int(r_in * math.sin(sa2))) * ren.scale

		gg_col := gg.Color{ r: col.r, g: col.g, b: col.b, a: col.a }
		if renderer.ctx != unsafe { nil } {
			renderer.ctx.draw_triangle_filled(x1, y1, x2, y2, x3, y3, gg_col)
			renderer.ctx.draw_triangle_filled(x1, y1, x3, y3, x4, y4, gg_col)
		}
	}
}

fn draw_board_darts(renderer &Renderer, g &DartsGame, tex &Texture) {
	cx := int(g.board_center_x)
	cy := int(g.board_center_y)

	for p in g.players {
		for h in p.current_turn {
			dx := cx + int(h.x)
			dy := cy + int(h.y)

			if tex != unsafe { nil } {
				src := Rect{0, 64, 32, 32}
				dst := Rect{dx - 8, dy - 20, 28, 28}
				render_copy(renderer, tex, &src, &dst)
			} else {
				draw_filled_circle(renderer, dx + 4, dy + 6, 3, Color{ r: 10, g: 10, b: 10, a: 120 })
				draw_filled_circle(renderer, dx, dy, 3, Color{ r: 220, g: 30, b: 30 })
				set_render_draw_color(renderer, 240, 200, 80, 255)
				render_draw_line(renderer, dx, dy, dx + 8, dy - 14)
				set_render_draw_color(renderer, 220, 30, 30, 255)
				render_draw_line(renderer, dx + 8, dy - 14, dx + 14, dy - 20)
			}
		}
	}
}

fn draw_aim_reticle(renderer &Renderer, g &DartsGame, tex &Texture) {
	if g.phase != .aiming && g.phase != .power_meter {
		return
	}

	rx := int(g.aim_x + g.wobble_x)
	ry := int(g.aim_y + g.wobble_y)

	if tex != unsafe { nil } {
		src := if g.phase == .power_meter { Rect{64, 128, 48, 48} } else { Rect{0, 128, 48, 48} }
		dst := Rect{rx - 24, ry - 24, 48, 48}
		render_copy(renderer, tex, &src, &dst)
	} else {
		ret_col := if g.phase == .power_meter { Color{ r: 255, g: 220, b: 40 } } else { Color{ r: 34, g: 211, b: 238 } }
		draw_circle_wire(renderer, rx, ry, 14, ret_col)
		draw_circle_wire(renderer, rx, ry, 3, ret_col)
		set_render_draw_color(renderer, ret_col.r, ret_col.g, ret_col.b, 255)
		render_draw_line(renderer, rx - 18, ry, rx - 6, ry)
		render_draw_line(renderer, rx + 6, ry, rx + 18, ry)
		render_draw_line(renderer, rx, ry - 18, rx, ry - 6)
		render_draw_line(renderer, rx, ry + 6, rx, ry + 18)
	}

	if g.phase == .power_meter {
		// Draw vertical power meter gauge next to reticle
		gx := rx + 32
		gy := ry - 30
		set_render_draw_color(renderer, 20, 20, 20, 200)
		render_fill_rect(renderer, &Rect{ x: gx, y: gy, w: 10, h: 60 })
		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_draw_rect(renderer, &Rect{ x: gx, y: gy, w: 10, h: 60 })

		// Sweet spot center line
		set_render_draw_color(renderer, 50, 255, 50, 255)
		render_draw_line(renderer, gx - 2, gy + 30, gx + 12, gy + 30)

		// Power cursor
		cursor_y := gy + int(g.power * 60.0)
		set_render_draw_color(renderer, 255, 60, 60, 255)
		render_fill_rect(renderer, &Rect{ x: gx - 3, y: cursor_y - 2, w: 16, h: 4 })
	}
}

fn draw_chalkboard_hud(renderer &Renderer, g &DartsGame, tex &Texture) {
	panel_x := 530
	panel_y := 20
	panel_w := 250
	panel_h := 560

	set_render_draw_color(renderer, 24, 38, 30, 255)
	rect := Rect{ x: panel_x, y: panel_y, w: panel_w, h: panel_h }
	render_fill_rect(renderer, &rect)

	set_render_draw_color(renderer, 85, 50, 28, 255)
	render_draw_rect(renderer, &rect)

	draw_text_centered(renderer, panel_x + panel_w / 2, panel_y + 16, 'CHAMPIONSHIP DARTS', 1, Color{ r: 255, g: 215, b: 80 })

	phase_msg := match g.phase {
		.aiming { 'AIM & LOCK [SPACE]' }
		.power_meter { 'TIMING RELEASE [SPACE]' }
		.flying { 'IN FLIGHT...' }
		.scored { 'SCORED!' }
		.bust { 'BUST!' }
		.leg_won { 'LEG WON!' }
	}
	draw_text_centered(renderer, panel_x + panel_w / 2, panel_y + 36, phase_msg, 1, Color{ r: 180, g: 240, b: 200 })

	if g.checkout_hint != '' {
		draw_text_centered(renderer, panel_x + panel_w / 2, panel_y + 54, 'CHECKOUT: ${g.checkout_hint}', 1, Color{ r: 255, g: 230, b: 100 })
	}

	// Scores
	if g.players.len > 0 {
		draw_text(renderer, panel_x + 20, panel_y + 80, '${g.players[0].name}:', 1, Color{ r: 240, g: 240, b: 240 })
		draw_text(renderer, panel_x + 20, panel_y + 104, '${g.players[0].score_left}', 3, Color{ r: 255, g: 255, b: 255 })
	}

	if g.players.len > 1 {
		draw_text(renderer, panel_x + 130, panel_y + 80, '${g.players[1].name}:', 1, Color{ r: 200, g: 200, b: 200 })
		draw_text(renderer, panel_x + 130, panel_y + 104, '${g.players[1].score_left}', 3, Color{ r: 255, g: 180, b: 180 })
	}

	// Darts Remaining in turn
	current_thrown := if g.players.len > g.current_p_idx { g.players[g.current_p_idx].current_turn.len } else { 0 }
	draw_text(renderer, panel_x + 20, panel_y + 160, 'DARTS THIS TURN:', 1, Color{ r: 255, g: 215, b: 80 })
	for d := 0; d < 3; d++ {
		is_thrown := d < current_thrown
		if tex != unsafe { nil } {
			src := if is_thrown { Rect{32, 64, 32, 32} } else { Rect{0, 4, 64, 24} }
			dst := Rect{panel_x + 20 + d * 70, panel_y + 185, 40, 24}
			render_copy(renderer, tex, &src, &dst)
		} else {
			col := if is_thrown { Color{ r: 100, g: 100, b: 100 } } else { Color{ r: 220, g: 40, b: 40 } }
			draw_filled_circle(renderer, panel_x + 35 + d * 40, panel_y + 195, 8, col)
		}
	}

	// Turn summary hits
	if g.players.len > g.current_p_idx {
		for i, hit in g.players[g.current_p_idx].current_turn {
			hit_desc := if hit.is_double_bull { 'D-BULL (50)' } else if hit.is_bull { 'BULL (25)' } else if hit.multiplier == 3 { 'T${hit.base_num} (${hit.score})' } else if hit.multiplier == 2 { 'D${hit.base_num} (${hit.score})' } else if hit.multiplier == 1 { 'S${hit.base_num} (${hit.score})' } else { 'MISS (0)' }
			draw_text(renderer, panel_x + 20, panel_y + 225 + i * 22, 'Dart ${i + 1}: ${hit_desc}', 1, Color{ r: 220, g: 240, b: 220 })
		}
	}

	// Controls
	draw_text(renderer, panel_x + 20, panel_y + 470, 'SPACE: Aim / Throw', 1, Color{ r: 180, g: 200, b: 220 })
	draw_text(renderer, panel_x + 20, panel_y + 490, '1: 501  2: 301  3: Cricket', 1, Color{ r: 180, g: 200, b: 220 })
	draw_text(renderer, panel_x + 20, panel_y + 510, 'C: CPU  P: 2-Player', 1, Color{ r: 180, g: 200, b: 220 })
	draw_text(renderer, panel_x + 20, panel_y + 530, 'M: Audio  R: Restart', 1, Color{ r: 180, g: 200, b: 220 })
}

fn draw_celebration(renderer &Renderer, g &DartsGame, tex &Texture) {
	if g.celeb_timer <= 0.0 || g.celebration == '' {
		return
	}

	cx := int(g.board_center_x)
	cy := int(g.board_center_y)

	if tex != unsafe { nil } {
		if g.celebration.contains('180') {
			src := Rect{64, 192, 64, 32}
			dst := Rect{cx - 80, cy - 40, 160, 80}
			render_copy(renderer, tex, &src, &dst)
		} else {
			src := Rect{0, 192, 48, 48}
			dst := Rect{cx - 50, cy - 50, 100, 100}
			render_copy(renderer, tex, &src, &dst)
		}
	}

	draw_text_centered(renderer, cx, cy + 40, g.celebration, 2, Color{ r: 255, g: 215, b: 0 })
}

fn draw_filled_circle(renderer &Renderer, cx int, cy int, radius int, col Color) {
	renderer.draw_circle_filled(f32(cx), f32(cy), f32(radius), gg.Color{ r: col.r, g: col.g, b: col.b, a: col.a })
}

fn draw_circle_wire(renderer &Renderer, cx int, cy int, radius int, col Color) {
	renderer.draw_circle_empty(f32(cx), f32(cy), f32(radius), gg.Color{ r: col.r, g: col.g, b: col.b, a: col.a })
}
