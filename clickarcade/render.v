module main

import math
import time


// Circle rendering helper
pub fn fill_circle(renderer &Renderer, cx int, cy int, radius int, color Color) {
	set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	r2 := radius * radius
	for dy in -radius .. radius + 1 {
		dx_max := int(math.sqrt(f64(r2 - dy * dy)))
		rect := Rect{
			x: cx - dx_max
			y: cy + dy
			w: dx_max * 2 + 1
			h: 1
		}
		render_fill_rect(renderer, &rect)
	}
}

pub fn draw_circle_outline(renderer &Renderer, cx int, cy int, radius int, thickness int, color Color) {
	set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	for t in 0 .. thickness {
		r := radius - t
		if r <= 0 {
			break
		}
		mut x := r
		mut y := 0
		mut err := 0

		for x >= y {
			render_draw_point(renderer, cx + x, cy + y)
			render_draw_point(renderer, cx + y, cy + x)
			render_draw_point(renderer, cx - y, cy + x)
			render_draw_point(renderer, cx - x, cy + y)
			render_draw_point(renderer, cx - x, cy - y)
			render_draw_point(renderer, cx - y, cy - x)
			render_draw_point(renderer, cx + y, cy - x)
			render_draw_point(renderer, cx + x, cy - y)

			if err <= 0 {
				y += 1
				err += 2 * y + 1
			}
			if err > 0 {
				x -= 1
				err -= 2 * x + 1
			}
		}
	}
}

pub fn draw_rect_outline(renderer &Renderer, rect &Rect, thickness int, color Color) {
	set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	for t in 0 .. thickness {
		r := Rect{
			x: rect.x + t
			y: rect.y + t
			w: math.max(rect.w - 2 * t, 1)
			h: math.max(rect.h - 2 * t, 1)
		}
		render_draw_rect(renderer, &r)
	}
}

pub fn draw_progress_bar(renderer &Renderer, x int, y int, w int, h int, progress f64, fill_col Color, bg_col Color) {
	bg_rect := Rect{ x: x, y: y, w: w, h: h }
	set_render_draw_color(renderer, bg_col.r, bg_col.g, bg_col.b, bg_col.a)
	render_fill_rect(renderer, &bg_rect)

	clamped_p := math.max(0.0, math.min(1.0, progress))
	fill_w := int(f64(w) * clamped_p)
	if fill_w > 0 {
		fill_rect := Rect{ x: x, y: y, w: fill_w, h: h }
		set_render_draw_color(renderer, fill_col.r, fill_col.g, fill_col.b, fill_col.a)
		render_fill_rect(renderer, &fill_rect)
	}

	draw_rect_outline(renderer, &bg_rect, 1, col_white)
}

// -------------------------------------------------------------
// MAIN MENU RENDER
// -------------------------------------------------------------
pub fn render_arcade_menu(renderer &Renderer, am &ArcadeManager, win_w int, win_h int) {
	// Dark cyber background
	set_render_draw_color(renderer, 15, 17, 26, 255)
	render_clear(renderer)

	// Draw starfield
	for s in am.stars {
		fill_circle(renderer, int(s.x), int(s.y), s.size, s.color)
	}

	// Title Header
	draw_text_centered(renderer, win_w / 2, 35, 'CLICK ARCADE', 4, col_gold)
	draw_text_centered(renderer, win_w / 2, 78, 'THE ULTIMATE MOUSE CLICKING MINI-GAME COLLECTION', 1, col_cyan)

	// Top Stats Bar
	stats_text := 'TOTAL CLICKS: ${am.total_clicks}  |  BEST GEM RUSH: ${int(am.gem_rush_best)}  |  CHAIN BEST: ${am.chain_best_score}'
	draw_text_centered(renderer, win_w / 2, 105, stats_text, 1, col_gray)

	// Render the 4 Game Cards
	for i, btn in am.buttons {
		is_hover := am.hovered_btn == i
		card_rect := Rect{ x: btn.x, y: btn.y, w: btn.w, h: btn.h }

		// Card background
		card_bg := if is_hover {
			Color{ r: 35, g: 40, b: 62, a: 255 }
		} else {
			Color{ r: 24, g: 27, b: 42, a: 255 }
		}
		set_render_draw_color(renderer, card_bg.r, card_bg.g, card_bg.b, 255)
		render_fill_rect(renderer, &card_rect)

		// Border glow
		border_col := if is_hover { btn.color } else { col_dark_gray }
		border_thk := if is_hover { 3 } else { 1 }
		draw_rect_outline(renderer, &card_rect, border_thk, border_col)

		// Tag badge
		tag_rect := Rect{ x: btn.x + 18, y: btn.y + 16, w: btn.tag.len * 8 + 16, h: 20 }
		set_render_draw_color(renderer, btn.color.r / 3, btn.color.g / 3, btn.color.b / 3, 255)
		render_fill_rect(renderer, &tag_rect)
		draw_text(renderer, btn.x + 26, btn.y + 20, btn.tag, 1, btn.color)

		// Game Title
		draw_text(renderer, btn.x + 18, btn.y + 48, btn.title, 2, if is_hover { col_white } else { btn.color })

		// Subtitle description
		draw_text(renderer, btn.x + 18, btn.y + 78, btn.subtitle, 1, col_gray)

		// Best score in card
		mut best_str := 'BEST: 0'
		match i {
			0 { best_str = 'BEST: ${int(am.gem_rush_best)} Gems' }
			1 { best_str = 'BEST: ${am.chain_best_score} Pts (Lvl ${am.chain_best_level})' }
			2 { best_str = 'BEST: ${am.whack_best_score} Pts' }
			3 { best_str = 'BEST: ${am.blade_best_score} Pts' }
			else {}
		}
		draw_text(renderer, btn.x + 18, btn.y + 115, best_str, 1, col_yellow)

		// Action Prompt
		prompt := if is_hover { '> CLICK TO PLAY <' } else { '[ SELECT ]' }
		draw_text_right(renderer, btn.x + btn.w - 18, btn.y + 135, prompt, 1, if is_hover { col_green } else { col_gray })
	}

	// Bottom Footer
	draw_text_centered(renderer, win_w / 2, 555, 'PRESS ESC TO RETURN TO MENU AT ANY TIME  |  M TO TOGGLE AUDIO', 1, col_gray)
}

// -------------------------------------------------------------
// GEM RUSH RENDER
// -------------------------------------------------------------
pub fn render_gem_rush(renderer &Renderer, g &GemRushGame, win_w int, win_h int) {
	// Background
	set_render_draw_color(renderer, 18, 14, 28, 255)
	render_clear(renderer)

	// Header Panel
	header_rect := Rect{ x: 0, y: 0, w: win_w, h: 70 }
	set_render_draw_color(renderer, 28, 22, 44, 255)
	render_fill_rect(renderer, &header_rect)
	draw_rect_outline(renderer, &header_rect, 1, col_purple)

	draw_text(renderer, 24, 16, '< ESC: MENU', 1, col_gray)
	draw_text_centered(renderer, win_w / 2, 12, 'GEM RUSH TYCOON', 2, col_gold)

	// Gem count display
	gem_text := if g.gems >= 1000000.0 {
		'${(g.gems / 1000000.0):.2f}M GEMS'
	} else if g.gems >= 1000.0 {
		'${(g.gems / 1000.0):.1f}K GEMS'
	} else {
		'${int(g.gems)} GEMS'
	}
	draw_text_centered(renderer, win_w / 2, 38, gem_text, 2, col_yellow)

	cps_text := 'CPS: ${g.get_total_cps():.1f}/s  |  CLICK: +${g.get_click_power():.1f}'
	draw_text(renderer, win_w - 280, 24, cps_text, 1, col_cyan)

	// Left Side: Big Clickable Gem
	gem_cx := 240
	gem_cy := 290
	base_r := int(95.0 * g.gem_scale)

	// Pulsing aura
	aura_r := base_r + int(math.sin(f64(time.ticks()) * 0.005) * 8.0)
	aura_col := if g.is_frenzy { col_gold } else { col_purple }
	draw_circle_outline(renderer, gem_cx, gem_cy, aura_r, 4, aura_col)

	// Gem Body
	fill_circle(renderer, gem_cx, gem_cy, base_r, if g.is_frenzy { col_yellow } else { col_cyan })
	fill_circle(renderer, gem_cx, gem_cy, int(f64(base_r) * 0.8), if g.is_frenzy { col_gold } else { col_blue })
	fill_circle(renderer, gem_cx - base_r / 4, gem_cy - base_r / 4, int(f64(base_r) * 0.35), col_white)

	// Gem Click Prompt
	draw_text_centered(renderer, gem_cx, gem_cy + base_r + 20, 'CLICK THE GEM!', 2, col_white)

	// Combo Surge Meter
	draw_text_centered(renderer, gem_cx, gem_cy + base_r + 50, 'COMBO: ${g.combo_multiplier:.0f}x MULTIPLIER', 1, col_yellow)
	draw_progress_bar(renderer, gem_cx - 120, gem_cy + base_r + 68, 240, 14, g.combo_meter, col_gold, col_dark_gray)

	// Frenzy banner
	if g.is_frenzy {
		draw_text_centered(renderer, gem_cx, 95, '★ 7x FRENZY RUSH! (${g.frenzy_timer:.1f}s) ★', 2, col_gold)
	}

	// Golden Gem
	if g.golden_gem.active {
		fill_circle(renderer, int(g.golden_gem.x), int(g.golden_gem.y), int(g.golden_gem.radius), col_gold)
		draw_circle_outline(renderer, int(g.golden_gem.x), int(g.golden_gem.y), int(g.golden_gem.radius) + 4, 2, col_white)
		draw_text_centered(renderer, int(g.golden_gem.x), int(g.golden_gem.y) - 4, '★', 1, col_white)
	}

	// Right Side: Upgrade & Building Shop
	shop_x := 490
	shop_w := 365
	draw_text(renderer, shop_x, 85, 'MINING AUTOMATION SHOP', 2, col_gold)

	mut cur_y := 115
	for _, b in g.buildings {
		cost := g.get_building_cost(&b)
		can_afford := g.gems >= cost
		b_rect := Rect{ x: shop_x, y: cur_y, w: shop_w, h: 56 }

		card_col := if can_afford { Color{ r: 35, g: 45, b: 65, a: 255 } } else { Color{ r: 24, g: 26, b: 36, a: 255 } }
		set_render_draw_color(renderer, card_col.r, card_col.g, card_col.b, 255)
		render_fill_rect(renderer, &b_rect)

		draw_rect_outline(renderer, &b_rect, 1, if can_afford { col_cyan } else { col_dark_gray })

		// Building name & count
		draw_text(renderer, shop_x + 12, cur_y + 10, '${b.name} (${b.count})', 1, if can_afford { col_white } else { col_gray })
		draw_text(renderer, shop_x + 12, cur_y + 28, b.desc, 1, col_gray)

		// Cost button
		cost_str := if cost >= 1000000.0 {
			'${(cost / 1000000.0):.2f}M'
		} else if cost >= 1000.0 {
			'${(cost / 1000.0):.1f}K'
		} else {
			'${int(cost)}'
		}
		draw_text_right(renderer, shop_x + shop_w - 12, cur_y + 20, '[ ${cost_str} ]', 1, if can_afford { col_gold } else { col_red })

		cur_y += 62
	}

	// Upgrades / Ascension Row
	cur_y += 10
	if g.can_ascend() {
		asc_rect := Rect{ x: shop_x, y: cur_y, w: shop_w, h: 42 }
		set_render_draw_color(renderer, 60, 20, 80, 255)
		render_fill_rect(renderer, &asc_rect)
		draw_rect_outline(renderer, &asc_rect, 2, col_pink)
		draw_text_centered(renderer, shop_x + shop_w / 2, cur_y + 14, '★ ASCEND (PRESTIGE RESTART) ★', 1, col_gold)
	} else if g.prestige_shards > 0 {
		draw_text(renderer, shop_x, cur_y + 10, 'PRESTIGE SHARDS: ${g.prestige_shards} (+${g.prestige_shards * 10}% Bonus)', 1, col_pink)
	}

	// Render Floating Texts
	for ft in g.floating_texts {
		draw_text(renderer, int(ft.x), int(ft.y), ft.text, ft.scale, ft.color)
	}

	// Render Particles
	for p in g.particles {
		fill_circle(renderer, int(p.x), int(p.y), int(p.size), p.color)
	}
}

// -------------------------------------------------------------
// CHAIN REACTION RENDER
// -------------------------------------------------------------
pub fn render_chain_reaction(renderer &Renderer, g &ChainReactionGame, win_w int, win_h int, mouse_x int, mouse_y int) {
	set_render_draw_color(renderer, 12, 16, 26, 255)
	render_clear(renderer)

	// Top Bar
	draw_text(renderer, 24, 18, '< ESC: MENU', 1, col_gray)
	draw_text_centered(renderer, win_w / 2, 14, 'CHAIN REACTION POP - LEVEL ${g.level}', 2, col_cyan)

	draw_text(renderer, 24, 38, 'POPPED: ${g.total_popped} / ${g.stage_target} NEEDED', 1, if g.total_popped >= g.stage_target { col_green } else { col_yellow })
	draw_text_right(renderer, win_w - 24, 18, 'SCORE: ${g.score}', 2, col_gold)
	draw_text_right(renderer, win_w - 24, 40, 'MAX CHAIN: ${g.max_chain}x', 1, col_pink)

	// Arena Border
	arena_rect := Rect{ x: g.arena_x, y: g.arena_y, w: g.arena_w, h: g.arena_h }
	set_render_draw_color(renderer, 18, 24, 38, 255)
	render_fill_rect(renderer, &arena_rect)
	draw_rect_outline(renderer, &arena_rect, 2, col_cyan)

	// Draw Bouncing Atoms
	for b in g.balls {
		if !b.active {
			continue
		}
		fill_circle(renderer, int(b.x), int(b.y), int(b.radius), b.color)
		fill_circle(renderer, int(b.x - b.radius * 0.3), int(b.y - b.radius * 0.3), int(b.radius * 0.3), col_white)
	}

	// Draw Shockwaves
	for w in g.waves {
		if !w.active {
			continue
		}
		// Translucent-style filled ring
		fill_circle(renderer, int(w.x), int(w.y), int(w.radius), Color{ r: w.color.r, g: w.color.g, b: w.color.b, a: 160 })
		draw_circle_outline(renderer, int(w.x), int(w.y), int(w.radius), 3, col_white)
	}

	// Draw Crosshair Preview when in ready state
	if g.state == 'ready' && g.clicks_left > 0 {
		if mouse_x >= g.arena_x && mouse_x <= g.arena_x + g.arena_w && mouse_y >= g.arena_y && mouse_y <= g.arena_y + g.arena_h {
			draw_circle_outline(renderer, mouse_x, mouse_y, 45, 1, col_yellow)
			set_render_draw_color(renderer, col_gold.r, col_gold.g, col_gold.b, 255)
			render_draw_line(renderer, mouse_x - 12, mouse_y, mouse_x + 12, mouse_y)
			render_draw_line(renderer, mouse_x, mouse_y - 12, mouse_x, mouse_y + 12)
			draw_text_centered(renderer, mouse_x, mouse_y + 50, 'CLICK TO DETONATE', 1, col_yellow)
		}
	}

	// Particles & Floating Text
	for ft in g.floating_texts {
		draw_text(renderer, int(ft.x), int(ft.y), ft.text, ft.scale, ft.color)
	}
	for p in g.particles {
		fill_circle(renderer, int(p.x), int(p.y), int(p.size), p.color)
	}

	// Bottom Progress Bar
	prog := f64(g.total_popped) / f64(g.stage_target)
	draw_progress_bar(renderer, g.arena_x, g.arena_y + g.arena_h + 12, g.arena_w, 14, prog, col_green, col_dark_gray)

	// State overlays
	if g.state == 'cleared' {
		overlay_rect := Rect{ x: win_w / 2 - 200, y: win_h / 2 - 80, w: 400, h: 160 }
		set_render_draw_color(renderer, 20, 50, 30, 240)
		render_fill_rect(renderer, &overlay_rect)
		draw_rect_outline(renderer, &overlay_rect, 3, col_green)

		draw_text_centered(renderer, win_w / 2, win_h / 2 - 50, 'STAGE CLEARED!', 3, col_gold)
		draw_text_centered(renderer, win_w / 2, win_h / 2 - 10, 'Popped: ${g.total_popped} / ${g.stage_target} Target', 1, col_white)
		draw_text_centered(renderer, win_w / 2, win_h / 2 + 25, '[ CLICK ANYWHERE FOR NEXT STAGE ]', 1, col_green)
	} else if g.state == 'failed' {
		overlay_rect := Rect{ x: win_w / 2 - 200, y: win_h / 2 - 80, w: 400, h: 160 }
		set_render_draw_color(renderer, 60, 20, 20, 240)
		render_fill_rect(renderer, &overlay_rect)
		draw_rect_outline(renderer, &overlay_rect, 3, col_red)

		draw_text_centered(renderer, win_w / 2, win_h / 2 - 50, 'STAGE FAILED!', 3, col_red)
		draw_text_centered(renderer, win_w / 2, win_h / 2 - 10, 'Only popped ${g.total_popped} / ${g.stage_target}', 1, col_white)
		draw_text_centered(renderer, win_w / 2, win_h / 2 + 25, '[ CLICK ANYWHERE TO RETRY ]', 1, col_yellow)
	}
}

// -------------------------------------------------------------
// WHACK-A-BOSS RENDER
// -------------------------------------------------------------
pub fn render_whack_monster(renderer &Renderer, g &WhackMonsterGame, win_w int, win_h int, mouse_x int, mouse_y int) {
	// Earth / Cave background
	set_render_draw_color(renderer, 32, 22, 18, 255)
	render_clear(renderer)

	// Header
	draw_text(renderer, 24, 18, '< ESC: MENU', 1, col_gray)
	draw_text_centered(renderer, win_w / 2, 14, 'WHACK-A-BOSS MONSTER MADNESS', 2, col_green)

	// HUD
	time_col := if g.time_left <= 10.0 { col_red } else { col_yellow }
	draw_text(renderer, 24, 45, 'TIME: ${g.time_left:.1f}s', 2, time_col)

	// Lives
	mut lives_str := ''
	for _ in 0 .. g.lives {
		lives_str += '♥ '
	}
	draw_text(renderer, 220, 45, 'LIVES: ${lives_str}', 2, col_red)

	draw_text_right(renderer, win_w - 24, 18, 'SCORE: ${g.score}', 2, col_gold)
	draw_text_right(renderer, win_w - 24, 45, 'COMBO: ${g.combo}x STREAK', 1, col_pink)

	// Draw 3x3 Holes & Monsters
	for h in g.holes {
		// Hole background (dark oval)
		fill_circle(renderer, int(h.x + h.w / 2.0), int(h.y + h.h / 2.0), int(h.w / 2.0), Color{ r: 18, g: 10, b: 8, a: 255 })
		draw_circle_outline(renderer, int(h.x + h.w / 2.0), int(h.y + h.h / 2.0), int(h.w / 2.0), 3, Color{ r: 60, g: 45, b: 35, a: 255 })

		// Render Monster if active
		if h.active && h.rise_progress > 0.0 {
			m_cx := int(h.x + h.w / 2.0)
			m_cy := int(h.y - h.rise_progress * 42.0 + 20.0)
			m_rad := int(34.0 * h.rise_progress)

			match h.m_type {
				.goblin {
					// Green goblin
					fill_circle(renderer, m_cx, m_cy, m_rad, col_green)
					// Eyes
					fill_circle(renderer, m_cx - 10, m_cy - 8, 6, col_white)
					fill_circle(renderer, m_cx + 10, m_cy - 8, 6, col_white)
					fill_circle(renderer, m_cx - 10, m_cy - 8, 3, col_black)
					fill_circle(renderer, m_cx + 10, m_cy - 8, 3, col_black)
					// Teeth
					draw_text_centered(renderer, m_cx, m_cy + 4, 'vvv', 1, col_white)
				}
				.gold_gnome {
					// Golden Gnome
					fill_circle(renderer, m_cx, m_cy, m_rad, col_gold)
					draw_circle_outline(renderer, m_cx, m_cy, m_rad + 2, 2, col_white)
					fill_circle(renderer, m_cx - 10, m_cy - 8, 5, col_black)
					fill_circle(renderer, m_cx + 10, m_cy - 8, 5, col_black)
					draw_text_centered(renderer, m_cx, m_cy + 2, '$$', 1, col_yellow)
				}
				.spiky_bomb {
					// Spiky bomb
					fill_circle(renderer, m_cx, m_cy, m_rad, col_dark_gray)
					draw_circle_outline(renderer, m_cx, m_cy, m_rad, 2, col_red)
					draw_text_centered(renderer, m_cx, m_cy - 8, '!', 2, col_red)
					draw_text_centered(renderer, m_cx, m_cy + 8, 'BOMB', 1, col_white)
				}
				.armored_boss {
					// Armored Boss
					fill_circle(renderer, m_cx, m_cy, m_rad + 6, col_orange)
					draw_circle_outline(renderer, m_cx, m_cy, m_rad + 8, 3, col_red)
					draw_text_centered(renderer, m_cx, m_cy - 12, 'BOSS', 1, col_yellow)
					draw_progress_bar(renderer, m_cx - 25, m_cy + 8, 50, 8, f64(h.hp) / f64(h.max_hp), col_red, col_dark_gray)
				}
				.time_clock {
					// Time Clock
					fill_circle(renderer, m_cx, m_cy, m_rad, col_cyan)
					draw_circle_outline(renderer, m_cx, m_cy, m_rad + 2, 2, col_white)
					draw_text_centered(renderer, m_cx, m_cy - 8, '+6s', 2, col_white)
				}
			}
		}

		// Front hole rim to mask monster bottom
		hole_rim := Rect{ x: int(h.x), y: int(h.y + h.h / 2.0), w: int(h.w), h: 18 }
		set_render_draw_color(renderer, 45, 32, 25, 255)
		render_fill_rect(renderer, &hole_rim)
	}

	// Hammer cursor / animation
	if g.hammer.active {
		fill_circle(renderer, int(g.hammer.x), int(g.hammer.y), 16, col_gold)
		draw_circle_outline(renderer, int(g.hammer.x), int(g.hammer.y), 24, 2, col_white)
	} else {
		// Hammer crosshair
		fill_circle(renderer, mouse_x, mouse_y, 6, col_gold)
		draw_circle_outline(renderer, mouse_x, mouse_y, 18, 2, col_yellow)
	}

	// Particles & Floating Text
	for ft in g.floating_texts {
		draw_text(renderer, int(ft.x), int(ft.y), ft.text, ft.scale, ft.color)
	}
	for p in g.particles {
		fill_circle(renderer, int(p.x), int(p.y), int(p.size), p.color)
	}

	// Game Over screen
	if g.game_over {
		overlay_rect := Rect{ x: win_w / 2 - 220, y: win_h / 2 - 90, w: 440, h: 180 }
		set_render_draw_color(renderer, 40, 15, 15, 245)
		render_fill_rect(renderer, &overlay_rect)
		draw_rect_outline(renderer, &overlay_rect, 3, col_red)

		draw_text_centered(renderer, win_w / 2, win_h / 2 - 60, 'ROUND OVER!', 3, col_gold)
		draw_text_centered(renderer, win_w / 2, win_h / 2 - 20, 'FINAL SCORE: ${g.score}  |  WHACKED: ${g.monsters_whacked}', 1, col_white)
		draw_text_centered(renderer, win_w / 2, win_h / 2 + 5, 'MAX COMBO STREAK: ${g.max_combo}x', 1, col_yellow)
		draw_text_centered(renderer, win_w / 2, win_h / 2 + 40, '[ CLICK ANYWHERE TO REPLAY ]', 1, col_green)
	}
}

// -------------------------------------------------------------
// BLADE SLICER RENDER
// -------------------------------------------------------------
pub fn render_blade_slicer(renderer &Renderer, g &BladeSlicerGame, win_w int, win_h int) {
	// Dark dojo background
	set_render_draw_color(renderer, 16, 18, 24, 255)
	render_clear(renderer)

	// Dojo wooden lines
	set_render_draw_color(renderer, 24, 28, 38, 255)
	for y := 80; y < win_h; y += 70 {
		render_draw_line(renderer, 0, y, win_w, y)
	}

	// Header
	draw_text(renderer, 24, 18, '< ESC: MENU', 1, col_gray)
	draw_text_centered(renderer, win_w / 2, 14, 'BLADE SLICER - FRUIT NINJA', 2, col_pink)

	// HUD
	mut lives_str := ''
	for _ in 0 .. g.lives {
		lives_str += '♥ '
	}
	draw_text(renderer, 24, 45, 'LIVES: ${lives_str}', 2, col_red)
	draw_text_right(renderer, win_w - 24, 18, 'SCORE: ${g.score}', 2, col_gold)
	draw_text_right(renderer, win_w - 24, 45, 'SLICED: ${g.total_sliced}', 1, col_cyan)

	if g.is_frenzy {
		draw_text_centered(renderer, win_w / 2, 50, '★ SLOW-MO FRENZY STORM! ★', 2, col_gold)
	}

	// Render Flying Uncut Items
	for item in g.items {
		if !item.active || item.sliced {
			continue
		}
		ix := int(item.x)
		iy := int(item.y)
		ir := int(item.radius)

		fill_circle(renderer, ix, iy, ir, item.color)

		match item.item_type {
			.watermelon {
				// Dark stripes
				draw_circle_outline(renderer, ix, iy, ir, 4, Color{ r: 20, g: 120, b: 40, a: 255 })
			}
			.orange {
				fill_circle(renderer, ix, iy, ir - 4, Color{ r: 255, g: 180, b: 50, a: 255 })
			}
			.diamond_star {
				draw_circle_outline(renderer, ix, iy, ir + 3, 2, col_white)
				draw_text_centered(renderer, ix, iy - 6, '★', 1, col_white)
			}
			.dragonfruit {
				fill_circle(renderer, ix, iy, ir - 5, col_white)
				draw_text_centered(renderer, ix, iy - 4, '::', 1, col_black)
			}
			.bomb {
				fill_circle(renderer, ix, iy, ir, col_black)
				draw_circle_outline(renderer, ix, iy, ir, 3, col_red)
				draw_text_centered(renderer, ix, iy - 6, 'X', 2, col_red)
			}
			else {}
		}
	}

	// Render Sliced Halves
	for h in g.halves {
		fill_circle(renderer, int(h.x), int(h.y), int(h.radius * 0.8), h.color)
	}

	// Render Glowing Blade Swipe Trail
	if g.trail.len > 1 {
		for i in 0 .. g.trail.len - 1 {
			p1 := g.trail[i]
			p2 := g.trail[i + 1]
			thk := int(p1.life * 28.0)
			if thk > 0 {
				set_render_draw_color(renderer, col_cyan.r, col_cyan.g, col_cyan.b, 255)
				render_draw_line(renderer, int(p1.x), int(p1.y), int(p2.x), int(p2.y))
				render_draw_line(renderer, int(p1.x) + 1, int(p1.y), int(p2.x) + 1, int(p2.y))
				render_draw_line(renderer, int(p1.x), int(p1.y) + 1, int(p2.x), int(p2.y) + 1)
			}
		}
	}

	// Floating Text & Particles
	for ft in g.floating_texts {
		draw_text(renderer, int(ft.x), int(ft.y), ft.text, ft.scale, ft.color)
	}
	for p in g.particles {
		fill_circle(renderer, int(p.x), int(p.y), int(p.size), p.color)
	}

	// Game Over Screen
	if g.game_over {
		overlay_rect := Rect{ x: win_w / 2 - 220, y: win_h / 2 - 90, w: 440, h: 180 }
		set_render_draw_color(renderer, 40, 15, 15, 245)
		render_fill_rect(renderer, &overlay_rect)
		draw_rect_outline(renderer, &overlay_rect, 3, col_red)

		draw_text_centered(renderer, win_w / 2, win_h / 2 - 60, 'GAME OVER!', 3, col_red)
		draw_text_centered(renderer, win_w / 2, win_h / 2 - 20, 'FINAL SCORE: ${g.score}', 2, col_gold)
		draw_text_centered(renderer, win_w / 2, win_h / 2 + 10, 'TOTAL FRUITS SLICED: ${g.total_sliced}', 1, col_white)
		draw_text_centered(renderer, win_w / 2, win_h / 2 + 40, '[ CLICK ANYWHERE TO REPLAY ]', 1, col_green)
	}
}
