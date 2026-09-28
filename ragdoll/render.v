module main

import math
import rand

pub fn (g &RagdollGame) render(renderer &Renderer, mouse_x int, mouse_y int) {
	// Clear background with rich dark cyber gradient
	set_render_draw_color(renderer, 15, 20, 32, 255)
	render_clear(renderer)

	// Draw subtle background grid lines
	set_render_draw_color(renderer, 25, 35, 52, 255)
	for x := 0; x < 800; x += 40 {
		render_draw_line(renderer, x, 50, x, 550)
	}
	for y := 50; y < 550; y += 40 {
		render_draw_line(renderer, 30, y, 770, y)
	}

	// 1. Render Obstacles
	for obs in g.obstacles {
		g.render_obstacle(renderer, obs)
	}

	// 2. Render Props
	for pr in g.props {
		g.render_prop(renderer, pr)
	}

	// 3. Render Tethers
	for t in g.tethers {
		if !t.active { continue }
		mut p1x := t.p1_obs_x
		mut p1y := t.p1_obs_y
		if t.p1_ragdoll_idx >= 0 && t.p1_ragdoll_idx < g.ragdolls.len {
			p1x = g.ragdolls[t.p1_ragdoll_idx].points[t.p1_point_idx].x
			p1y = g.ragdolls[t.p1_ragdoll_idx].points[t.p1_point_idx].y
		} else if t.p1_prop_idx >= 0 && t.p1_prop_idx < g.props.len {
			p1x = g.props[t.p1_prop_idx].x
			p1y = g.props[t.p1_prop_idx].y
		}

		mut p2x := t.p2_obs_x
		mut p2y := t.p2_obs_y
		if t.p2_ragdoll_idx >= 0 && t.p2_ragdoll_idx < g.ragdolls.len {
			p2x = g.ragdolls[t.p2_ragdoll_idx].points[t.p2_point_idx].x
			p2y = g.ragdolls[t.p2_ragdoll_idx].points[t.p2_point_idx].y
		} else if t.p2_prop_idx >= 0 && t.p2_prop_idx < g.props.len {
			p2x = g.props[t.p2_prop_idx].x
			p2y = g.props[t.p2_prop_idx].y
		}

		set_render_draw_color(renderer, t.color.r, t.color.g, t.color.b, 255)
		draw_thick_line(renderer, int(p1x), int(p1y), int(p2x), int(p2y), 3)
	}

	// 4. Render Ragdolls
	for r in g.ragdolls {
		g.render_ragdoll(renderer, r)
	}

	// 5. Render Particles
	for part in g.particles {
		set_render_draw_color(renderer, part.color.r, part.color.g, part.color.b, 255)
		if part.particle_type == 'shockwave' {
			draw_circle_outline(renderer, int(part.x), int(part.y), int(part.size), part.color)
		} else {
			rect := Rect{
				x: int(part.x - part.size * 0.5)
				y: int(part.y - part.size * 0.5)
				w: int(part.size)
				h: int(part.size)
			}
			render_fill_rect(renderer, &rect)
		}
	}

	// Draft tether line when configuring
	if g.tether_active_setting {
		set_render_draw_color(renderer, 255, 255, 0, 255)
		draw_thick_line(renderer, int(g.tether_start_x), int(g.tether_start_y), mouse_x, mouse_y, 2)
	}

	// 6. Tool Reticle / Grav Gun Beam
	if g.active_tool == .grav_gun && mouse_y >= 50 && mouse_y <= 550 {
		set_render_draw_color(renderer, 0, 240, 255, 255)
		draw_circle_outline(renderer, mouse_x, mouse_y, 16, Color{r: 0, g: 240, b: 255})
		if g.grav_held_point_idx >= 0 || g.grav_held_prop_idx >= 0 {
			rx := (rand.intn(9) or { 0 }) - 4
			ry := (rand.intn(9) or { 0 }) - 4
			render_draw_line(renderer, mouse_x, mouse_y, mouse_x + rx, mouse_y + ry)
		}
	}

	// 7. Render UI Panels & Buttons
	g.render_ui(renderer, mouse_x, mouse_y)
}

fn (g &RagdollGame) render_obstacle(renderer &Renderer, obs Obstacle) {
	match obs.obs_type {
		.platform {
			set_render_draw_color(renderer, obs.color.r, obs.color.g, obs.color.b, 255)
			rect := Rect{x: int(obs.x), y: int(obs.y), w: int(obs.w), h: int(obs.h)}
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 255, 255, 255, 100)
			render_draw_rect(renderer, &rect)
			if obs.label.len > 0 {
				draw_text_centered(renderer, int(obs.x + obs.w * 0.5), int(obs.y + (obs.h - 8) * 0.5), obs.label, 1, Color{r: 220, g: 230, b: 255})
			}
		}
		.trampoline {
			set_render_draw_color(renderer, obs.color.r, obs.color.g, obs.color.b, 255)
			rect := Rect{x: int(obs.x), y: int(obs.y), w: int(obs.w), h: int(obs.h)}
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 255, 255, 255, 255)
			draw_thick_line(renderer, int(obs.x), int(obs.y), int(obs.x + obs.w), int(obs.y), 3)
			draw_text_centered(renderer, int(obs.x + obs.w * 0.5), int(obs.y + 6), obs.label, 1, Color{r: 255, g: 255, b: 255})
		}
		.spinner {
			// Center hub
			draw_filled_circle(renderer, int(obs.x), int(obs.y), 14, obs.color)
			// Rotating blades
			for i in 0 .. 4 {
				ang := obs.angle + f64(i) * (math.pi * 0.5)
				bx := obs.x + math.cos(ang) * obs.r
				by := obs.y + math.sin(ang) * obs.r
				set_render_draw_color(renderer, obs.color.r, obs.color.g, obs.color.b, 255)
				draw_thick_line(renderer, int(obs.x), int(obs.y), int(bx), int(by), 6)
			}
		}
		.fan {
			set_render_draw_color(renderer, obs.color.r, obs.color.g, obs.color.b, 100)
			rect := Rect{x: int(obs.x), y: int(obs.y), w: int(obs.w), h: int(obs.h)}
			render_draw_rect(renderer, &rect)
			draw_text_centered(renderer, int(obs.x + obs.w * 0.5), int(obs.y + obs.h - 16), obs.label, 1, Color{r: 100, g: 255, b: 200})
		}
		.gravity_well {
			draw_circle_outline(renderer, int(obs.x), int(obs.y), int(obs.r), obs.color)
			draw_circle_outline(renderer, int(obs.x), int(obs.y), int(obs.r * 0.6), obs.color)
			draw_filled_circle(renderer, int(obs.x), int(obs.y), 10, obs.color)
			draw_text_centered(renderer, int(obs.x), int(obs.y + obs.r + 6), obs.label, 1, Color{r: 200, g: 120, b: 255})
		}
		.portal {
			draw_circle_outline(renderer, int(obs.x), int(obs.y), int(obs.r), obs.color)
			draw_filled_circle(renderer, int(obs.x), int(obs.y), int(obs.r * 0.5), obs.color)
			draw_text_centered(renderer, int(obs.x), int(obs.y + obs.r + 4), obs.label, 1, Color{r: 255, g: 255, b: 255})
		}
		.bumper {
			draw_filled_circle(renderer, int(obs.x), int(obs.y), int(obs.r), obs.color)
			set_render_draw_color(renderer, 255, 255, 255, 255)
			draw_circle_outline(renderer, int(obs.x), int(obs.y), int(obs.r), Color{r: 255, g: 255, b: 255})
			draw_text_centered(renderer, int(obs.x), int(obs.y - 4), 'BUMP', 1, Color{r: 10, g: 20, b: 40})
		}
	}
}

fn (g &RagdollGame) render_prop(renderer &Renderer, pr Prop) {
	draw_filled_circle(renderer, int(pr.x), int(pr.y), int(pr.radius), pr.color)
	set_render_draw_color(renderer, 255, 255, 255, 200)
	draw_circle_outline(renderer, int(pr.x), int(pr.y), int(pr.radius), Color{r: 255, g: 255, b: 255})
}

fn (g &RagdollGame) render_ragdoll(renderer &Renderer, r Ragdoll) {
	// Draw active distance constraints (limbs)
	for c in r.constraints {
		if !c.active { continue }
		p1 := r.points[c.p1_idx]
		p2 := r.points[c.p2_idx]
		set_render_draw_color(renderer, r.color.r, r.color.g, r.color.b, 255)
		draw_thick_line(renderer, int(p1.x), int(p1.y), int(p2.x), int(p2.y), 5)
	}

	// Draw joint nodes
	for p in r.points {
		draw_filled_circle(renderer, int(p.x), int(p.y), int(p.radius), p.color)
		set_render_draw_color(renderer, 255, 255, 255, 180)
		draw_circle_outline(renderer, int(p.x), int(p.y), int(p.radius), Color{r: 255, g: 255, b: 255})
	}

	// Draw Head facial expression on point[0]
	head := r.points[0]
	hx := int(head.x)
	hy := int(head.y)

	set_render_draw_color(renderer, 20, 20, 30, 255)
	match r.expression {
		'normal' {
			// Eyes
			draw_filled_circle(renderer, hx - 4, hy - 3, 2, Color{r: 20, g: 20, b: 30})
			draw_filled_circle(renderer, hx + 4, hy - 3, 2, Color{r: 20, g: 20, b: 30})
			// Smile
			render_draw_line(renderer, hx - 4, hy + 4, hx + 4, hy + 4)
		}
		'shock' {
			// Wide eyes
			draw_circle_outline(renderer, hx - 4, hy - 3, 3, Color{r: 20, g: 20, b: 30})
			draw_circle_outline(renderer, hx + 4, hy - 3, 3, Color{r: 20, g: 20, b: 30})
			// Open mouth
			draw_circle_outline(renderer, hx, hy + 4, 3, Color{r: 20, g: 20, b: 30})
		}
		'dizzy' {
			// Cross eyes (X X)
			render_draw_line(renderer, hx - 6, hy - 5, hx - 2, hy - 1)
			render_draw_line(renderer, hx - 6, hy - 1, hx - 2, hy - 5)
			render_draw_line(renderer, hx + 2, hy - 5, hx + 6, hy - 1)
			render_draw_line(renderer, hx + 2, hy - 1, hx + 6, hy - 5)
			// Wavy mouth
			render_draw_line(renderer, hx - 4, hy + 4, hx, hy + 2)
			render_draw_line(renderer, hx, hy + 2, hx + 4, hy + 4)
		}
		else {}
	}
}

fn (g &RagdollGame) render_ui(renderer &Renderer, mouse_x int, mouse_y int) {
	// Top Header Bar (0..48 px)
	set_render_draw_color(renderer, 20, 28, 45, 255)
	top_rect := Rect{x: 0, y: 0, w: 800, h: 48}
	render_fill_rect(renderer, &top_rect)
	set_render_draw_color(renderer, 50, 70, 110, 255)
	render_draw_rect(renderer, &top_rect)

	draw_text(renderer, 15, 14, 'ADVANCED RAGDOLL PHYSICS', 2, Color{r: 0, g: 240, b: 255})

	// Tool Bar Buttons (x: 320 .. 780)
	tools := [
		ToolType.grab,
		ToolType.grav_gun,
		ToolType.impulse_blaster,
		ToolType.tether,
		ToolType.spawn_ragdoll,
		ToolType.spawn_barrel,
		ToolType.slice,
		ToolType.bomb,
	]
	tool_names := ['GRAB', 'GRAV', 'PUSH', 'ROPE', '+RAG', '+BAR', 'CUT', 'BOMB']

	for i in 0 .. tools.len {
		t := tools[i]
		bx := 315 + i * 58
		by := 8
		bw := 54
		bh := 32
		is_selected := (g.active_tool == t)
		is_hover := (mouse_x >= bx && mouse_x <= bx + bw && mouse_y >= by && mouse_y <= by + bh)

		c := if is_selected {
			Color{r: 0, g: 160, b: 220}
		} else if is_hover {
			Color{r: 45, g: 65, b: 95}
		} else {
			Color{r: 28, g: 38, b: 58}
		}

		set_render_draw_color(renderer, c.r, c.g, c.b, 255)
		b_rect := Rect{x: bx, y: by, w: bw, h: bh}
		render_fill_rect(renderer, &b_rect)

		border_c := if is_selected { Color{r: 0, g: 240, b: 255} } else { Color{r: 60, g: 85, b: 130} }
		set_render_draw_color(renderer, border_c.r, border_c.g, border_c.b, 255)
		render_draw_rect(renderer, &b_rect)

		text_c := if is_selected { Color{r: 255, g: 255, b: 255} } else { Color{r: 180, g: 200, b: 230} }
		draw_text_centered(renderer, bx + bw / 2, by + (bh - 8) / 2, tool_names[i], 1, text_c)
	}

	// Bottom Footer Bar (552..600 px)
	set_render_draw_color(renderer, 20, 28, 45, 255)
	bot_rect := Rect{x: 0, y: 552, w: 800, h: 48}
	render_fill_rect(renderer, &bot_rect)
	set_render_draw_color(renderer, 50, 70, 110, 255)
	render_draw_rect(renderer, &bot_rect)

	// Arena selection buttons
	arenas := [ArenaType.funhouse, ArenaType.staircase, ArenaType.zero_g]
	arena_names := ['FUNHOUSE [1]', 'STAIRS [2]', 'ZERO-G [3]']

	for i in 0 .. arenas.len {
		a := arenas[i]
		bx := 15 + i * 110
		by := 560
		bw := 102
		bh := 32
		is_selected := (g.active_arena == a)
		is_hover := (mouse_x >= bx && mouse_x <= bx + bw && mouse_y >= by && mouse_y <= by + bh)

		c := if is_selected {
			Color{r: 180, g: 60, b: 220}
		} else if is_hover {
			Color{r: 55, g: 55, b: 85}
		} else {
			Color{r: 30, g: 30, b: 50}
		}

		set_render_draw_color(renderer, c.r, c.g, c.b, 255)
		b_rect := Rect{x: bx, y: by, w: bw, h: bh}
		render_fill_rect(renderer, &b_rect)

		border_c := if is_selected { Color{r: 240, g: 120, b: 255} } else { Color{r: 80, g: 80, b: 120} }
		set_render_draw_color(renderer, border_c.r, border_c.g, border_c.b, 255)
		render_draw_rect(renderer, &b_rect)

		draw_text_centered(renderer, bx + bw / 2, by + (bh - 8) / 2, arena_names[i], 1, Color{r: 255, g: 255, b: 255})
	}

	// Telemetry & Parameters Info
	info_text := 'FPS:${g.fps_display} RAGDOLLS:${g.ragdolls.len} GRAV:${int(g.gravity)} SCALE:${g.timescale:.2f}x'
	draw_text(renderer, 355, 564, info_text, 1, Color{r: 0, g: 240, b: 255})
}

// Utility draw helpers
fn draw_thick_line(renderer &Renderer, x1 int, y1 int, x2 int, y2 int, thickness int) {
	half := thickness / 2
	for dx := -half; dx <= half; dx++ {
		for dy := -half; dy <= half; dy++ {
			render_draw_line(renderer, x1 + dx, y1 + dy, x2 + dx, y2 + dy)
		}
	}
}

fn draw_filled_circle(renderer &Renderer, cx int, cy int, r int, col Color) {
	set_render_draw_color(renderer, col.r, col.g, col.b, 255)
	for dy := -r; dy <= r; dy++ {
		dx := int(math.sqrt(f64(r * r - dy * dy)))
		render_draw_line(renderer, cx - dx, cy + dy, cx + dx, cy + dy)
	}
}

fn draw_circle_outline(renderer &Renderer, cx int, cy int, r int, col Color) {
	set_render_draw_color(renderer, col.r, col.g, col.b, 255)
	for i in 0 .. 32 {
		ang1 := f64(i) * (2.0 * math.pi / 32.0)
		ang2 := f64(i + 1) * (2.0 * math.pi / 32.0)
		x1 := cx + int(math.cos(ang1) * f64(r))
		y1 := cy + int(math.sin(ang1) * f64(r))
		x2 := cx + int(math.cos(ang2) * f64(r))
		y2 := cy + int(math.sin(ang2) * f64(r))
		render_draw_line(renderer, x1, y1, x2, y2)
	}
}
