module main

import math

pub fn render_ski_game(renderer &Renderer, mut g SkiGame, win_w int, win_h int) {
	// Camera centers on player
	cam_x := g.x - f64(win_w) / 2.0
	cam_y := g.y - f64(win_h) / 2.0 + 80.0 // Player positioned slightly above center

	// 1. Draw Pristine White Snow Playfield
	set_render_draw_color(renderer, 245, 248, 252, 255)
	clear_rect := Rect{0, 0, win_w, win_h}
	render_fill_rect(renderer, &clear_rect)

	// Subtle snow sparkle / texture dots
	set_render_draw_color(renderer, 220, 230, 245, 120)
	for sy := 0; sy < win_h; sy += 32 {
		for sx := 0; sx < win_w; sx += 32 {
			world_gx := int(cam_x) + sx
			world_gy := int(cam_y) + sy
			if (world_gx * 73 + world_gy * 37) % 17 == 0 {
				render_draw_point(renderer, sx, sy)
			}
		}
	}

	// 2. Draw Ski Tracks on Snow
	set_render_draw_color(renderer, 205, 218, 235, 255)
	for t in g.tracks {
		x1 := int(t.x1 - cam_x)
		y1 := int(t.y1 - cam_y)
		x2 := int(t.x2 - cam_x)
		y2 := int(t.y2 - cam_y)

		// Left ski trail
		render_draw_line(renderer, x1 - 3, y1, x2 - 3, y2)
		// Right ski trail
		render_draw_line(renderer, x1 + 3, y1, x2 + 3, y2)
	}

	// 3. Draw Obstacles Sorted by Y for Proper Depth Stacking
	for ob in g.obstacles {
		ox := int(ob.x - cam_x)
		oy := int(ob.y - cam_y)

		// Culling
		if ox < -80 || ox > win_w + 80 || oy < -80 || oy > win_h + 80 {
			continue
		}

		render_obstacle(renderer, ob, ox, oy)
	}

	// 4. Draw Snow Puff Particles
	for p in g.particles {
		px := int(p.x - cam_x)
		py := int(p.y - cam_y)
		set_render_draw_color(renderer, 255, 255, 255, 255)
		p_rect := Rect{px, py, p.size, p.size}
		render_fill_rect(renderer, &p_rect)
		set_render_draw_color(renderer, 180, 200, 225, 255)
		render_draw_rect(renderer, &p_rect)
	}

	// 5. Draw Skier Player
	px := int(g.x - cam_x)
	py := int(g.y - cam_y)

	// Shadow if airborne
	if g.altitude > 0.0 {
		shadow_w := int(18.0 / (1.0 + g.altitude * 0.05))
		set_render_draw_color(renderer, 190, 205, 225, 180)
		s_rect := Rect{px - shadow_w / 2, py + 12, shadow_w, 4}
		render_fill_rect(renderer, &s_rect)
	}

	render_skier(renderer, g, px, py - int(g.altitude))

	// 6. Draw The Yeti Monster if Active
	if g.yeti.active {
		yx := int(g.yeti.x - cam_x)
		yy := int(g.yeti.y - cam_y)
		render_yeti(renderer, g.yeti, yx, yy)
	}

	// 7. Shareware Vintage HUD Top Banner
	render_ski_hud(renderer, g, win_w)
}

fn render_obstacle(renderer &Renderer, ob Obstacle, x int, y int) {
	match ob.kind {
		.large_pine {
			// Tree shadow
			set_render_draw_color(renderer, 200, 215, 235, 200)
			sh_rect := Rect{x - 12, y + 10, 24, 6}
			render_fill_rect(renderer, &sh_rect)

			// Trunk
			set_render_draw_color(renderer, 105, 55, 20, 255)
			trunk := Rect{x - 3, y + 2, 6, 10}
			render_fill_rect(renderer, &trunk)

			// 3 Foliage tiers
			draw_pine_tier(renderer, x, y - 20, 10, 12, Color{28, 115, 45, 255})
			draw_pine_tier(renderer, x, y - 10, 16, 14, Color{24, 100, 38, 255})
			draw_pine_tier(renderer, x, y + 2, 22, 16, Color{18, 85, 30, 255})

			// Snow on tips
			set_render_draw_color(renderer, 255, 255, 255, 255)
			snow_cap := Rect{x - 3, y - 22, 6, 3}
			render_fill_rect(renderer, &snow_cap)
		}
		.small_tree {
			// Trunk
			set_render_draw_color(renderer, 115, 65, 25, 255)
			trunk := Rect{x - 2, y + 2, 4, 6}
			render_fill_rect(renderer, &trunk)

			// Foliage
			draw_pine_tier(renderer, x, y - 8, 8, 10, Color{45, 145, 55, 255})
			draw_pine_tier(renderer, x, y + 1, 14, 11, Color{35, 125, 45, 255})
		}
		.tree_stump {
			set_render_draw_color(renderer, 130, 80, 35, 255)
			stump := Rect{x - 6, y - 4, 12, 8}
			render_fill_rect(renderer, &stump)
			// Snow top
			set_render_draw_color(renderer, 250, 250, 255, 255)
			stump_top := Rect{x - 5, y - 5, 10, 3}
			render_fill_rect(renderer, &stump_top)
		}
		.rock {
			set_render_draw_color(renderer, 100, 105, 115, 255)
			rock_rect := Rect{x - 8, y - 4, 16, 8}
			render_fill_rect(renderer, &rock_rect)
			// Highlight
			set_render_draw_color(renderer, 160, 170, 185, 255)
			rock_hi := Rect{x - 6, y - 5, 12, 3}
			render_fill_rect(renderer, &rock_hi)
		}
		.snow_mogul {
			set_render_draw_color(renderer, 210, 225, 245, 255)
			draw_filled_circle(renderer, x, y, 9, Color{215, 228, 248, 255})
			draw_filled_circle(renderer, x, y - 2, 7, Color{250, 252, 255, 255})
		}
		.jump_ramp {
			// Wooden kicker ramp
			set_render_draw_color(renderer, 160, 95, 45, 255)
			ramp := Rect{x - 12, y - 6, 24, 10}
			render_fill_rect(renderer, &ramp)
			// Red warning edge
			set_render_draw_color(renderer, 230, 40, 40, 255)
			lip := Rect{x - 12, y + 2, 24, 3}
			render_fill_rect(renderer, &lip)
		}
		.slalom_blue {
			// Blue Slalom Pole & Flag (Pass Left)
			set_render_draw_color(renderer, 30, 110, 225, 255)
			pole := Rect{x - 1, y - 22, 3, 24}
			render_fill_rect(renderer, &pole)
			flag := Rect{x + 2, y - 22, 10, 8}
			render_fill_rect(renderer, &flag)
		}
		.slalom_red {
			// Red Slalom Pole & Flag (Pass Right)
			set_render_draw_color(renderer, 225, 35, 45, 255)
			pole := Rect{x - 1, y - 22, 3, 24}
			render_fill_rect(renderer, &pole)
			flag := Rect{x - 12, y - 22, 10, 8}
			render_fill_rect(renderer, &flag)
		}
		.dog {
			// Running brown dog
			set_render_draw_color(renderer, 150, 85, 30, 255)
			body := Rect{x - 6, y - 4, 12, 6}
			render_fill_rect(renderer, &body)
			head := Rect{x + 4, y - 7, 5, 5}
			render_fill_rect(renderer, &head)
			// Tail
			render_draw_line(renderer, x - 6, y - 3, x - 10, y - 6)
		}
		else {}
	}
}

fn draw_pine_tier(renderer &Renderer, cx int, cy int, half_w int, h int, col Color) {
	set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
	for dy in 0 .. h {
		w := int(f64(half_w) * (f64(dy) / f64(h)))
		line := Rect{cx - w, cy + dy, w * 2 + 1, 1}
		render_fill_rect(renderer, &line)
	}
}

fn render_skier(renderer &Renderer, g SkiGame, x int, y int) {
	suit_blue := Color{35, 100, 215, 255}
	hat_red := Color{235, 45, 45, 255}
	skin_col := Color{255, 205, 160, 255}
	ski_yellow := Color{245, 215, 20, 255}
	pole_black := Color{30, 30, 35, 255}

	match g.pose {
		.stopped {
			// Skier standing facing slightly left
			render_skier_body(renderer, x, y, suit_blue, hat_red, skin_col)
			// Skis crossed / snowplow
			set_render_draw_color(renderer, ski_yellow.r, ski_yellow.g, ski_yellow.b, 255)
			render_draw_line(renderer, x - 6, y + 4, x - 3, y + 14)
			render_draw_line(renderer, x + 6, y + 4, x + 3, y + 14)
		}
		.ski_straight {
			// Straight Downhill
			render_skier_body(renderer, x, y, suit_blue, hat_red, skin_col)
			// Two parallel vertical skis
			set_render_draw_color(renderer, ski_yellow.r, ski_yellow.g, ski_yellow.b, 255)
			s1 := Rect{x - 4, y + 2, 2, 14}
			s2 := Rect{x + 2, y + 2, 2, 14}
			render_fill_rect(renderer, &s1)
			render_fill_rect(renderer, &s2)
			// Poles
			set_render_draw_color(renderer, pole_black.r, pole_black.g, pole_black.b, 255)
			render_draw_line(renderer, x - 7, y, x - 9, y + 12)
			render_draw_line(renderer, x + 7, y, x + 9, y + 12)
		}
		.tuck_fast {
			// Speed aerodynamic tuck (crouched)
			set_render_draw_color(renderer, hat_red.r, hat_red.g, hat_red.b, 255)
			head := Rect{x - 3, y - 2, 6, 5}
			render_fill_rect(renderer, &head)

			set_render_draw_color(renderer, suit_blue.r, suit_blue.g, suit_blue.b, 255)
			body := Rect{x - 5, y + 2, 10, 6}
			render_fill_rect(renderer, &body)

			set_render_draw_color(renderer, ski_yellow.r, ski_yellow.g, ski_yellow.b, 255)
			s1 := Rect{x - 4, y + 5, 2, 15}
			s2 := Rect{x + 2, y + 5, 2, 15}
			render_fill_rect(renderer, &s1)
			render_fill_rect(renderer, &s2)
		}
		.turn_diag_left, .turn_left {
			render_skier_body(renderer, x, y, suit_blue, hat_red, skin_col)
			set_render_draw_color(renderer, ski_yellow.r, ski_yellow.g, ski_yellow.b, 255)
			render_draw_line(renderer, x - 9, y + 6, x + 1, y + 14)
			render_draw_line(renderer, x - 6, y + 3, x + 4, y + 11)
		}
		.turn_hard_left {
			render_skier_body(renderer, x, y, suit_blue, hat_red, skin_col)
			set_render_draw_color(renderer, ski_yellow.r, ski_yellow.g, ski_yellow.b, 255)
			s := Rect{x - 10, y + 8, 16, 2}
			render_fill_rect(renderer, &s)
		}
		.turn_diag_right, .turn_right {
			render_skier_body(renderer, x, y, suit_blue, hat_red, skin_col)
			set_render_draw_color(renderer, ski_yellow.r, ski_yellow.g, ski_yellow.b, 255)
			render_draw_line(renderer, x + 9, y + 6, x - 1, y + 14)
			render_draw_line(renderer, x + 6, y + 3, x - 4, y + 11)
		}
		.turn_hard_right {
			render_skier_body(renderer, x, y, suit_blue, hat_red, skin_col)
			set_render_draw_color(renderer, ski_yellow.r, ski_yellow.g, ski_yellow.b, 255)
			s := Rect{x - 6, y + 8, 16, 2}
			render_fill_rect(renderer, &s)
		}
		.airborne {
			render_skier_body(renderer, x, y, suit_blue, hat_red, skin_col)
			set_render_draw_color(renderer, ski_yellow.r, ski_yellow.g, ski_yellow.b, 255)
			render_draw_line(renderer, x - 5, y + 5, x - 7, y + 16)
			render_draw_line(renderer, x + 5, y + 5, x + 7, y + 16)
		}
		.trick_daffy {
			// Daffy trick (one ski up, one ski down)
			render_skier_body(renderer, x, y, suit_blue, hat_red, skin_col)
			set_render_draw_color(renderer, ski_yellow.r, ski_yellow.g, ski_yellow.b, 255)
			render_draw_line(renderer, x - 8, y - 8, x - 4, y + 6)
			render_draw_line(renderer, x + 4, y + 4, x + 8, y + 18)
			draw_text_centered(renderer, x, y - 24, 'DAFFY!', 1, Color{255, 215, 0, 255})
		}
		.trick_spread {
			// Spread eagle (wide splits)
			render_skier_body(renderer, x, y, suit_blue, hat_red, skin_col)
			set_render_draw_color(renderer, ski_yellow.r, ski_yellow.g, ski_yellow.b, 255)
			render_draw_line(renderer, x - 14, y + 8, x - 2, y + 5)
			render_draw_line(renderer, x + 2, y + 5, x + 14, y + 8)
			draw_text_centered(renderer, x, y - 24, 'SPREAD EAGLE!', 1, Color{0, 240, 255, 255})
		}
		.trick_backflip, .trick_spin {
			// Inverted / rotating somersault
			render_skier_body(renderer, x, y, suit_blue, hat_red, skin_col)
			set_render_draw_color(renderer, ski_yellow.r, ski_yellow.g, ski_yellow.b, 255)
			render_draw_line(renderer, x - 10, y - 4, x + 10, y - 4)
			draw_text_centered(renderer, x, y - 24, '360 FLIP!', 1, Color{255, 80, 220, 255})
		}
		.crashed {
			// Sprawled face down with detached skis and cartoon dazed stars
			set_render_draw_color(renderer, suit_blue.r, suit_blue.g, suit_blue.b, 255)
			body := Rect{x - 8, y + 2, 16, 6}
			render_fill_rect(renderer, &body)
			set_render_draw_color(renderer, skin_col.r, skin_col.g, skin_col.b, 255)
			head := Rect{x - 4, y - 2, 8, 5}
			render_fill_rect(renderer, &head)

			// Detached broken skis
			set_render_draw_color(renderer, ski_yellow.r, ski_yellow.g, ski_yellow.b, 255)
			render_draw_line(renderer, x - 14, y - 6, x - 6, y - 14)
			render_draw_line(renderer, x + 6, y - 10, x + 14, y - 4)

			// Dazed stars
			draw_text_centered(renderer, x, y - 16, '* @ ! *', 1, Color{255, 220, 50, 255})
		}
		.eaten {
			// Hidden in Yeti's jaws
		}
	}
}

fn render_skier_body(renderer &Renderer, x int, y int, suit Color, hat Color, skin Color) {
	// Head & Hat
	set_render_draw_color(renderer, hat.r, hat.g, hat.b, 255)
	cap := Rect{x - 3, y - 8, 6, 4}
	render_fill_rect(renderer, &cap)

	set_render_draw_color(renderer, skin.r, skin.g, skin.b, 255)
	face := Rect{x - 3, y - 4, 6, 4}
	render_fill_rect(renderer, &face)

	// Goggles
	set_render_draw_color(renderer, 20, 20, 25, 255)
	goggles := Rect{x - 3, y - 4, 6, 2}
	render_fill_rect(renderer, &goggles)

	// Blue Suit Torso
	set_render_draw_color(renderer, suit.r, suit.g, suit.b, 255)
	torso := Rect{x - 4, y, 8, 8}
	render_fill_rect(renderer, &torso)
}

fn render_yeti(renderer &Renderer, y_mon Yeti, x int, y int) {
	// Fur White Body
	fur_col := Color{235, 240, 248, 255}
	face_col := Color{160, 185, 215, 255}
	eye_col := Color{255, 30, 30, 255}

	// Giant Yeti Torso
	set_render_draw_color(renderer, fur_col.r, fur_col.g, fur_col.b, 255)
	body := Rect{x - 14, y - 16, 28, 30}
	render_fill_rect(renderer, &body)

	// Head
	head := Rect{x - 10, y - 28, 20, 14}
	render_fill_rect(renderer, &head)

	// Face mask
	set_render_draw_color(renderer, face_col.r, face_col.g, face_col.b, 255)
	face := Rect{x - 7, y - 24, 14, 8}
	render_fill_rect(renderer, &face)

	// Red Glowing Eyes
	set_render_draw_color(renderer, eye_col.r, eye_col.g, eye_col.b, 255)
	e1 := Rect{x - 5, y - 22, 3, 3}
	e2 := Rect{x + 2, y - 22, 3, 3}
	render_fill_rect(renderer, &e1)
	render_fill_rect(renderer, &e2)

	// Sharp teeth
	set_render_draw_color(renderer, 255, 255, 255, 255)
	mouth := Rect{x - 5, y - 18, 10, 3}
	render_fill_rect(renderer, &mouth)

	// Waving Giant Arms (Running animation)
	set_render_draw_color(renderer, fur_col.r, fur_col.g, fur_col.b, 255)
	if y_mon.frame == 0 {
		// Arms up
		a1 := Rect{x - 22, y - 24, 8, 20}
		a2 := Rect{x + 14, y - 10, 8, 20}
		render_fill_rect(renderer, &a1)
		render_fill_rect(renderer, &a2)
	} else {
		// Arms alternate
		a1 := Rect{x - 22, y - 10, 8, 20}
		a2 := Rect{x + 14, y - 24, 8, 20}
		render_fill_rect(renderer, &a1)
		render_fill_rect(renderer, &a2)
	}

	// Stomping Feet
	l1 := Rect{x - 12, y + 14, 9, 12}
	l2 := Rect{x + 3, y + 14, 9, 12}
	render_fill_rect(renderer, &l1)
	render_fill_rect(renderer, &l2)
}

fn render_ski_hud(renderer &Renderer, g SkiGame, win_w int) {
	// Top Header Bar (Classic 90s Shareware Grey Toolstrip)
	set_render_draw_color(renderer, 192, 192, 192, 255)
	bar_rect := Rect{0, 0, win_w, 36}
	render_fill_rect(renderer, &bar_rect)

	// Bevel highlights
	set_render_draw_color(renderer, 255, 255, 255, 255)
	render_draw_line(renderer, 0, 0, win_w, 0)
	set_render_draw_color(renderer, 128, 128, 128, 255)
	render_draw_line(renderer, 0, 35, win_w, 35)

	// Status metrics
	min := int(g.time_elapsed) / 60
	sec := int(g.time_elapsed) % 60
	speed_kmh := int(math.sqrt(g.vx * g.vx + g.vy * g.vy) * 0.1)

	mode_str := match g.mode {
		.free_ski { 'FREE SKI' }
		.slalom { 'SLALOM (${g.slalom_gates_passed}/${g.slalom_gates_total})' }
		.tree_slalom { 'TREE SLALOM' }
		.yeti_survival { 'YETI ESCAPE!' }
	}

	draw_text(renderer, 12, 12, 'DIST: ${g.distance_m}m', 1, Color{20, 20, 20, 255})
	draw_text(renderer, 130, 12, 'SPD: ${speed_kmh} km/h', 1, Color{20, 20, 20, 255})
	draw_text(renderer, 260, 12, 'TIME: ${min:02d}:${sec:02d}', 1, Color{20, 20, 20, 255})
	draw_text(renderer, 390, 12, 'SCORE: ${g.score}', 1, Color{180, 20, 20, 255})
	draw_text(renderer, 530, 12, 'MODE: ${mode_str} [M]', 1, Color{0, 80, 180, 255})
	draw_text(renderer, win_w - 100, 12, 'RESET: [R]', 1, Color{80, 80, 80, 255})

	// Animated In-Game Banner Message
	if g.banner_timer > 0.0 && g.banner_text != '' {
		banner_w := g.banner_text.len * 8 * 2 + 30
		bx := win_w / 2 - banner_w / 2
		by := 50

		set_render_draw_color(renderer, 20, 25, 35, 230)
		bg_rect := Rect{bx, by, banner_w, 32}
		render_fill_rect(renderer, &bg_rect)

		set_render_draw_color(renderer, 255, 215, 0, 255)
		render_draw_rect(renderer, &bg_rect)

		draw_text_centered(renderer, win_w / 2, by + 8, g.banner_text, 2, Color{255, 230, 80, 255})
	}
}
