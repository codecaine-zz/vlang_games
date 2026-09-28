module main

import math

const col_bg_arcade = Color{ r: 28, g: 18, b: 48, a: 255 }
const col_panel = Color{ r: 42, g: 26, b: 72, a: 255 }
const col_fuse_bar = Color{ r: 255, g: 70, b: 40, a: 255 }
const col_fuse_bg = Color{ r: 30, g: 15, b: 20, a: 255 }
const col_heart = Color{ r: 255, g: 50, b: 80, a: 255 }
const col_gem = Color{ r: 60, g: 220, b: 255, a: 255 }
const col_yellow_gold = Color{ r: 255, g: 220, b: 40, a: 255 }

pub fn render_micromayhem_game(renderer &Renderer, mut g MicroMayhemGame, w int, h int, mx int, my int) {
	// Background
	draw_beveled_box(renderer, 0, 0, w, h, col_bg_arcade, Color{r:80,g:50,b:130}, Color{r:10,g:5,b:20})

	// Top HUD (Lives, Score, Streak, Speed Gauge)
	draw_beveled_box(renderer, 24, 15, w - 48, 55, col_panel, col_yellow_gold, Color{r:15,g:10,b:25})

	// Lives (Hearts)
	draw_text(renderer, 45, 26, 'LIVES:', 1, Color{r:255,g:200,b:200})
	for i in 0 .. 4 {
		hx := 105 + i * 26
		hy := 28
		if i < g.lives {
			draw_filled_circle(renderer, hx, hy, 8, col_heart)
			draw_filled_circle(renderer, hx + 8, hy, 8, col_heart)
			draw_filled_circle(renderer, hx + 4, hy + 8, 8, col_heart)
		} else {
			draw_circle_outline(renderer, hx + 4, hy + 4, 8, Color{r:100,g:50,b:60})
		}
	}

	// Score & Streak
	draw_text(renderer, 260, 26, 'SCORE: ${g.score}', 2, Color{r:255,g:255,b:255})
	draw_text(renderer, 480, 26, 'STREAK: ${g.streak}x', 2, col_yellow_gold)
	draw_text(renderer, w - 240, 26, 'SPEED: ${g.speed_multiplier:.1f}x', 2, Color{r:100,g:255,b:160})

	// Title Screen Phase
	if g.phase == .title {
		draw_beveled_box(renderer, w / 2 - 280, h / 2 - 140, 560, 280, col_panel, col_yellow_gold, Color{r:20,g:10,b:35})
		draw_text_centered(renderer, w / 2, h / 2 - 100, 'MICRO MAYHEM', 4, col_yellow_gold)
		draw_text_centered(renderer, w / 2, h / 2 - 40, 'WARIOWARE-STYLE RAPID PARTY GAUNTLET', 1, Color{r:200,g:230,b:255})
		draw_text_centered(renderer, w / 2, h / 2 + 10, '4-SECOND CHALLENGES • ESCALATING BPM', 1, Color{r:255,g:140,b:180})
		draw_beveled_box(renderer, w / 2 - 180, h / 2 + 60, 360, 48, Color{r:40,g:140,b:70}, col_yellow_gold, Color{r:15,g:50,b:25})
		draw_text_centered(renderer, w / 2, h / 2 + 76, 'PRESS SPACE OR CLICK TO START!', 1, Color{r:255,g:255,b:255})
		return
	}

	// Intermission Elevator Phase
	if g.phase == .intermission {
		draw_beveled_box(renderer, w / 2 - 220, h / 2 - 80, 440, 160, col_panel, col_yellow_gold, Color{r:15,g:10,b:25})
		draw_text_centered(renderer, w / 2, h / 2 - 50, 'GAME #${g.games_cleared + 1}', 2, Color{r:180,g:220,b:255})
		draw_text_centered(renderer, w / 2, h / 2 - 10, 'GET READY!', 3, col_yellow_gold)
		draw_text_centered(renderer, w / 2, h / 2 + 40, 'SPEED: ${g.speed_multiplier:.1f}x', 1, Color{r:100,g:255,b:140})
		return
	}

	// Game Over Phase
	if g.phase == .game_over {
		draw_beveled_box(renderer, w / 2 - 240, h / 2 - 100, 480, 200, col_panel, Color{r:255,g:70,b:70}, Color{r:25,g:10,b:15})
		draw_text_centered(renderer, w / 2, h / 2 - 60, 'GAME OVER', 4, Color{r:255,g:80,b:80})
		draw_text_centered(renderer, w / 2, h / 2, 'FINAL SCORE: ${g.score} | CLEARED: ${g.games_cleared}', 2, Color{r:255,g:255,b:255})
		draw_text_centered(renderer, w / 2, h / 2 + 50, 'PRESS SPACE OR R TO PLAY AGAIN', 1, col_yellow_gold)
		return
	}

	// Active Micro-Game Playfield
	draw_beveled_box(renderer, 24, 85, w - 48, 475, Color{r:20,g:14,b:35}, Color{r:70,g:45,b:110}, Color{r:10,g:5,b:18})

	// Big Instruction Header Banner
	draw_beveled_box(renderer, 50, 95, w - 100, 48, Color{r:240,g:190,b:30}, Color{r:255,g:255,b:255}, Color{r:150,g:110,b:10})
	draw_text_centered(renderer, w / 2, 108, g.instruction, 2, Color{r:20,g:20,b:30})

	// Micro-Game Specific Renderers
	match g.current_micro {
		.defuse_bomb {
			// Giant ticking bomb
			bx := w / 2
			by := 320
			draw_filled_circle(renderer, bx, by, 75, Color{r:30,g:30,b:35})
			draw_circle_outline(renderer, bx, by, 75, Color{r:80,g:80,b:90})
			// Fuse wick
			set_render_draw_color(renderer, 200, 160, 80, 255)
			render_draw_line(renderer, bx, by - 75, bx + 30, by - 120)
			draw_filled_circle(renderer, bx + 30, by - 120, 10, col_fuse_bar)

			// 3 Wires (1: Red, 2: Green, 3: Blue)
			wire_colors := [Color{r:240,g:50,b:50}, Color{r:50,g:220,b:80}, Color{r:60,g:120,b:240}]
			for i in 0 .. 3 {
				wx := bx - 140 + i * 140
				wy := by + 120
				is_cut := (g.bomb_cut_wire == i)
				draw_beveled_box(renderer, wx - 40, wy, 80, 36, Color{r:40,g:40,b:50}, wire_colors[i], Color{r:15,g:15,b:20})
				draw_text_centered(renderer, wx, wy + 12, 'WIRE ${i + 1}', 1, wire_colors[i])
				if is_cut {
					draw_text_centered(renderer, wx, wy - 20, 'CUT!', 1, Color{r:255,g:255,b:255})
				}
			}
		}
		.catch_gem {
			// Falling shiny diamond gem
			draw_filled_circle(renderer, int(g.gem_x), int(g.gem_y), 18, col_gem)
			draw_circle_outline(renderer, int(g.gem_x), int(g.gem_y), 18, Color{r:255,g:255,b:255})
			draw_text_centered(renderer, int(g.gem_x), int(g.gem_y) - 4, '◆', 2, Color{r:255,g:255,b:255})

			// Player basket at y = 475 (160px wide)
			bx := int(g.gem_basket_x)
			draw_beveled_box(renderer, bx - 80, 475, 160, 36, Color{r:180,g:120,b:50}, col_yellow_gold, Color{r:90,g:50,b:15})
			draw_text_centered(renderer, bx, 486, 'BASKET', 1, Color{r:255,g:255,b:255})
		}
		.dodge_laser {
			lane_w := 260
			for lane in 0 .. 3 {
				lx := 80 + lane * lane_w
				is_danger := (lane == g.laser_danger_lane)
				lane_bg := if is_danger { Color{r:140,g:30,b:30,a:200} } else { Color{r:30,g:40,b:60,a:180} }
				draw_beveled_box(renderer, lx, 160, lane_w - 10, 360, lane_bg, if is_danger { col_fuse_bar } else { Color{r:60,g:80,b:120} }, Color{r:10,g:15,b:25})
				if is_danger {
					draw_text_centered(renderer, lx + lane_w / 2, 180, '⚠ DANGER LANE ⚠', 2, col_fuse_bar)
					draw_text_centered(renderer, lx + lane_w / 2, 210, 'MOVE AWAY!', 1, Color{r:255,g:200,b:200})
				}
				if g.player_lane == lane {
					// Player character
					draw_beveled_box(renderer, lx + lane_w / 2 - 35, 420, 70, 70, Color{r:50,g:220,b:120}, Color{r:255,g:255,b:255}, Color{r:20,g:100,b:50})
					draw_text_centered(renderer, lx + lane_w / 2, 445, 'YOU', 2, Color{r:20,g:30,b:20})
				}
			}
		}
		.arm_wrestle {
			// Big Power Gauge
			gw := 500
			gh := 50
			gx := w / 2 - gw / 2
			gy := 300

			draw_beveled_box(renderer, gx - 6, gy - 6, gw + 12, gh + 12, Color{r:20,g:20,b:30}, col_yellow_gold, Color{r:10,g:10,b:15})
			fill_w := int(f64(gw) * g.wrestle_meter)
			fill_col := if g.wrestle_meter >= 0.65 { Color{r:60,g:240,b:100} } else { Color{r:240,g:160,b:40} }
			draw_beveled_box(renderer, gx, gy, fill_w, gh, fill_col, Color{r:255,g:255,b:255}, fill_col)

			// Goal marker at 65%
			goal_x := gx + int(f64(gw) * 0.65)
			set_render_draw_color(renderer, 255, 50, 50, 255)
			render_draw_line(renderer, goal_x, gy - 12, goal_x, gy + gh + 12)
			draw_text_centered(renderer, goal_x, gy - 24, 'WIN (65%)', 1, Color{r:255,g:100,b:100})
			draw_text_centered(renderer, w / 2, gy + gh + 30, 'RAPID MASH: ${int(g.wrestle_meter * 100.0)}% / 65%', 2, Color{r:255,g:255,b:255})
		}
		.stop_needle {
			// Arc / Slider Bar
			bar_w := 600
			bar_x := w / 2 - bar_w / 2
			bar_y := 320
			draw_beveled_box(renderer, bar_x, bar_y, bar_w, 40, Color{r:30,g:30,b:40}, Color{r:80,g:80,b:100}, Color{r:10,g:10,b:15})

			// Target Green Zone
			t_x1 := bar_x + int(f64(bar_w) * g.needle_target_min)
			t_x2 := bar_x + int(f64(bar_w) * g.needle_target_max)
			draw_beveled_box(renderer, t_x1, bar_y + 2, t_x2 - t_x1, 36, Color{r:50,g:220,b:100}, Color{r:255,g:255,b:255}, Color{r:20,g:120,b:50})
			draw_text_centered(renderer, (t_x1 + t_x2) / 2, bar_y + 12, 'HIT HERE', 1, Color{r:20,g:40,b:20})

			// Oscillating Needle
			nx := bar_x + int(f64(bar_w) * g.needle_pos)
			draw_beveled_box(renderer, nx - 5, bar_y - 20, 10, 80, Color{r:255,g:50,b:50}, Color{r:255,g:200,b:200}, Color{r:150,g:20,b:20})
		}
		.unicycle_balance {
			cx := w / 2
			cy := 440

			// Unicycle wheel
			draw_filled_circle(renderer, cx, cy, 28, Color{r:50,g:50,b:60})
			draw_circle_outline(renderer, cx, cy, 28, Color{r:200,g:200,b:220})

			// Tilting pole
			pole_len := 160.0
			tip_x := cx + int(math.sin(g.unicycle_tilt) * pole_len)
			tip_y := cy - int(math.cos(g.unicycle_tilt) * pole_len)

			set_render_draw_color(renderer, 240, 180, 40, 255)
			render_draw_line(renderer, cx, cy, tip_x, tip_y)
			draw_filled_circle(renderer, tip_x, tip_y, 16, Color{r:240,g:70,b:70})
		}
		.pattern_match {
			cols := [Color{r:240,g:50,b:50}, Color{r:50,g:220,b:80}, Color{r:60,g:120,b:240}]
			// Flash sequence targets
			draw_text_centered(renderer, w / 2, 200, 'TARGET PATTERN:', 1, Color{r:200,g:220,b:255})
			for i, val in g.pattern_seq {
				px := w / 2 - 120 + i * 120
				draw_beveled_box(renderer, px - 35, 230, 70, 70, cols[val - 1], Color{r:255,g:255,b:255}, Color{r:10,g:10,b:10})
				draw_text_centered(renderer, px, 255, '${val}', 2, Color{r:255,g:255,b:255})
			}

			// Player entered sequence
			draw_text_centered(renderer, w / 2, 340, 'YOUR INPUT:', 1, col_yellow_gold)
			for i, val in g.player_seq {
				px := w / 2 - 120 + i * 120
				draw_beveled_box(renderer, px - 25, 370, 50, 50, cols[val - 1], Color{r:255,g:255,b:255}, Color{r:10,g:10,b:10})
				draw_text_centered(renderer, px, 385, '${val}', 2, Color{r:255,g:255,b:255})
			}
		}
		.pop_targets {
			for i, t in g.pop_targets_list {
				tx := int(t[0])
				ty := int(t[1])
				tr := int(t[2])
				is_pop := (t[3] == 1.0)
				if !is_pop {
					draw_filled_circle(renderer, tx, ty, tr, Color{r:240,g:60,b:80})
					draw_circle_outline(renderer, tx, ty, tr, Color{r:255,g:220,b:220})
					draw_text_centered(renderer, tx, ty - 6, '${i + 1}', 2, Color{r:255,g:255,b:255})
				} else {
					draw_text_centered(renderer, tx, ty - 6, 'POP!', 2, col_yellow_gold)
				}
			}
		}
	}

	// Result Splash (Success / Fail)
	if g.phase == .round_result {
		res_box_y := h / 2 - 60
		if g.is_success {
			draw_beveled_box(renderer, w / 2 - 220, res_box_y, 440, 110, Color{r:30,g:120,b:50}, Color{r:100,g:255,b:140}, Color{r:10,g:40,b:15})
			draw_text_centered(renderer, w / 2, res_box_y + 20, '★ SUCCESS! ★', 4, Color{r:255,g:255,b:255})
			draw_text_centered(renderer, w / 2, res_box_y + 70, '+${int(100.0 * g.speed_multiplier)} PTS!', 2, col_yellow_gold)
		} else {
			draw_beveled_box(renderer, w / 2 - 220, res_box_y, 440, 110, Color{r:160,g:30,b:30}, Color{r:255,g:100,b:100}, Color{r:60,g:10,b:10})
			draw_text_centered(renderer, w / 2, res_box_y + 20, 'FAIL!', 4, Color{r:255,g:255,b:255})
			draw_text_centered(renderer, w / 2, res_box_y + 70, 'LOST 1 LIFE!', 2, Color{r:255,g:200,b:200})
		}
	}

	// Bottom Countdown Fuse Bar
	bar_w := w - 48
	draw_beveled_box(renderer, 24, h - 55, bar_w, 24, col_fuse_bg, col_yellow_gold, Color{r:10,g:5,b:10})
	time_ratio := math.clamp(g.game_timer / g.game_duration, 0.0, 1.0)
	fuse_fill := int(f64(bar_w) * time_ratio)
	fuse_color := if time_ratio < 0.25 { col_fuse_bar } else { col_yellow_gold }
	draw_beveled_box(renderer, 24, h - 55, fuse_fill, 24, fuse_color, Color{r:255,g:255,b:255}, fuse_color)
}
