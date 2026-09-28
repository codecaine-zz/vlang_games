module main

import math
import rand

pub fn render_mathmunchers_game(renderer &Renderer, game &MathMunchersGame) {
	// Screen shake calculation
	mut shake_x := 0
	mut shake_y := 0
	if game.screen_shake_timer > 0 {
		shake_x = rand.intn(13) or { 0 } - 6
		shake_y = rand.intn(13) or { 0 } - 6
	}

	// 1. Fill background (cyber retro arcade grid backdrop)
	bg_r := if game.freeze_timer > 0 { u8(6) } else { u8(8) }
	bg_g := if game.freeze_timer > 0 { u8(30) } else { u8(14) }
	bg_b := if game.freeze_timer > 0 { u8(55) } else { u8(26) }
	set_render_draw_color(renderer, bg_r, bg_g, bg_b, 255)
	render_clear(renderer)

	// Draw subtle retro grid background lines
	set_render_draw_color(renderer, 18, 30, 50, 255)
	for x := 0; x < 800; x += 40 {
		render_draw_line(renderer, x + shake_x, 0, x + shake_x, 600)
	}
	for y := 0; y < 600; y += 40 {
		render_draw_line(renderer, 0, y + shake_y, 800, y + shake_y)
	}

	// 2. Render Header Rule Banner
	render_rule_header(renderer, game, shake_x, shake_y)

	// 3. Render HUD (Score, Level, Combo, Lives, Difficulty)
	render_hud(renderer, game, shake_x, shake_y)

	// Special Bonus Round rendering
	if game.state == .bonus_round {
		render_bonus_round(renderer, game, shake_x, shake_y)
		render_effects(renderer, game, shake_x, shake_y)
		return
	}

	// 4. Render Math Grid & Cells
	render_grid(renderer, game, shake_x, shake_y)

	// 5. Render Troggle Entry Warning Indicators
	render_troggle_warnings(renderer, game, shake_x, shake_y)

	// 6. Render Troggle Enemies
	for troggle in game.troggles {
		render_troggle(renderer, &troggle, game.freeze_timer > 0, game.global_anim_time,
			shake_x, shake_y)
	}

	// 7. Render Player Muncher
	render_muncher(renderer, &game.player, game.global_anim_time, shake_x, shake_y)

	// 8. Render Particles & Floating Texts
	render_effects(renderer, game, shake_x, shake_y)

	// 9. Render Game State Overlays (Start Menu, Pause, Level Clear, Game Over)
	render_overlays(renderer, game)
}

fn render_rule_header(renderer &Renderer, game &MathMunchersGame, sx int, sy int) {
	banner_rect := Rect{
		x: 30 + sx
		y: 10 + sy
		w: 740
		h: 60
	}

	shadow := Rect{
		x: banner_rect.x + 3
		y: banner_rect.y + 3
		w: banner_rect.w
		h: banner_rect.h
	}
	set_render_draw_color(renderer, 0, 0, 0, 160)
	render_fill_rect(renderer, &shadow)

	set_render_draw_color(renderer, 20, 42, 80, 255)
	render_fill_rect(renderer, &banner_rect)

	set_render_draw_color(renderer, 60, 150, 250, 255)
	render_draw_rect(renderer, &banner_rect)

	inner := Rect{
		x: banner_rect.x + 3
		y: banner_rect.y + 3
		w: banner_rect.w - 6
		h: banner_rect.h - 6
	}
	set_render_draw_color(renderer, 40, 95, 170, 255)
	render_draw_rect(renderer, &inner)

	rule_icon := match game.current_rule.rule_type {
		.multiples { '[x]' }
		.factors { '[/]' }
		.primes { '[P]' }
		.equals { '[=]' }
		.greater_than { '[>]' }
		.less_than { '[<]' }
		.squares { '[^2]' }
	}

	draw_text_centered(renderer, 400 + sx, 18 + sy, '${rule_icon} RULE: ${game.current_rule.title} ${rule_icon}',
		2, Color{
		r: 255
		g: 225
		b: 70
	})
	draw_text_centered(renderer, 400 + sx, 44 + sy, game.current_rule.description, 1, Color{
		r: 190
		g: 230
		b: 255
	})
}

fn render_hud(renderer &Renderer, game &MathMunchersGame, sx int, sy int) {
	hud_rect := Rect{
		x: 30 + sx
		y: 75 + sy
		w: 740
		h: 34
	}
	set_render_draw_color(renderer, 14, 24, 44, 220)
	render_fill_rect(renderer, &hud_rect)
	set_render_draw_color(renderer, 45, 75, 120, 255)
	render_draw_rect(renderer, &hud_rect)

	diff_label := match game.difficulty {
		.easy { 'EASY' }
		.hard { 'HARD' }
		else { 'NORMAL' }
	}

	draw_text(renderer, 45 + sx, 84 + sy, 'STAGE: ${game.level}', 1, Color{
		r: 100
		g: 220
		b: 255
	})
	draw_text(renderer, 135 + sx, 84 + sy, 'MODE: ${diff_label}', 1, Color{
		r: 255
		g: 220
		b: 80
	})
	draw_text(renderer, 265 + sx, 84 + sy, 'SCORE: ${game.score}', 1, Color{
		r: 255
		g: 255
		b: 255
	})
	draw_text(renderer, 395 + sx, 84 + sy, 'HIGH: ${game.high_score}', 1, Color{
		r: 255
		g: 215
		b: 0
	})

	if game.freeze_timer > 0 {
		draw_text(renderer, 500 + sx, 84 + sy, 'FROZEN! ${int(game.freeze_timer)}s', 1,
			Color{
			r: 100
			g: 230
			b: 255
		})
	} else if game.player.combo > 1 {
		pulse := int(math.sin(game.global_anim_time * 10.0) * 20.0)
		draw_text(renderer, 500 + sx, 84 + sy, 'x${game.player.combo}!', 1, Color{
			r: u8(255)
			g: u8(100 + pulse)
			b: u8(200 + pulse)
		})
	}

	draw_text(renderer, 580 + sx, 84 + sy, 'LIVES:', 1, Color{
		r: 180
		g: 180
		b: 200
	})
	for i in 0 .. game.player.lives {
		lx := 640 + i * 24 + sx
		ly := 82 + sy
		head_rect := Rect{
			x: lx
			y: ly
			w: 18
			h: 18
		}
		set_render_draw_color(renderer, 40, 220, 80, 255)
		render_fill_rect(renderer, &head_rect)
		set_render_draw_color(renderer, 10, 90, 30, 255)
		render_draw_rect(renderer, &head_rect)
		e1 := Rect{
			x: lx + 3
			y: ly + 3
			w: 4
			h: 5
		}
		e2 := Rect{
			x: lx + 11
			y: ly + 3
			w: 4
			h: 5
		}
		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_fill_rect(renderer, &e1)
		render_fill_rect(renderer, &e2)
		p1 := Rect{
			x: lx + 4
			y: ly + 5
			w: 2
			h: 2
		}
		p2 := Rect{
			x: lx + 12
			y: ly + 5
			w: 2
			h: 2
		}
		set_render_draw_color(renderer, 0, 0, 0, 255)
		render_fill_rect(renderer, &p1)
		render_fill_rect(renderer, &p2)
	}
}

fn render_grid(renderer &Renderer, game &MathMunchersGame, sx int, sy int) {
	start_x := 45 + sx
	start_y := 118 + sy
	cell_w := 115
	cell_h := 78
	gap := 7

	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			cx := start_x + c * (cell_w + gap)
			cy := start_y + r * (cell_h + gap)
			cell_rect := Rect{
				x: cx
				y: cy
				w: cell_w
				h: cell_h
			}

			cell := &game.grid[r][c]

			if cell.eaten {
				set_render_draw_color(renderer, 14, 20, 32, 255)
				render_fill_rect(renderer, &cell_rect)
				set_render_draw_color(renderer, 26, 36, 56, 255)
				render_draw_rect(renderer, &cell_rect)
				render_draw_line(renderer, cx + 8, cy + 8, cx + cell_w - 8, cy + cell_h - 8)
				render_draw_line(renderer, cx + cell_w - 8, cy + 8, cx + 8, cy + cell_h - 8)
			} else if cell.flash_timer > 0 {
				if cell.is_wrong_flash {
					set_render_draw_color(renderer, 220, 40, 40, 255)
				} else {
					set_render_draw_color(renderer, 40, 220, 100, 255)
				}
				render_fill_rect(renderer, &cell_rect)
			} else {
				set_render_draw_color(renderer, 28, 44, 72, 255)
				render_fill_rect(renderer, &cell_rect)

				set_render_draw_color(renderer, 55, 85, 135, 255)
				render_draw_line(renderer, cx, cy, cx + cell_w, cy)
				render_draw_line(renderer, cx, cy, cx, cy + cell_h)

				if cell.power_up == .freeze {
					freeze_icon := Rect{
						x: cx + cell_w - 20
						y: cy + 4
						w: 16
						h: 16
					}
					set_render_draw_color(renderer, 100, 220, 255, 255)
					render_fill_rect(renderer, &freeze_icon)
				} else if cell.power_up == .safe_zone {
					safe_icon := Rect{
						x: cx + cell_w - 20
						y: cy + 4
						w: 16
						h: 16
					}
					set_render_draw_color(renderer, 255, 215, 0, 255)
					render_fill_rect(renderer, &safe_icon)
				}

				set_render_draw_color(renderer, 42, 68, 110, 255)
				render_draw_rect(renderer, &cell_rect)
			}

			if game.player.grid_x == c && game.player.grid_y == r {
				render_selection_reticle(renderer, cx, cy, cell_w, cell_h, game.global_anim_time)
			}

			if !cell.eaten {
				scale := if cell.expr.len > 6 { 1 } else { 2 }
				ty := cy + (cell_h - (8 * scale)) / 2
				draw_text_centered(renderer, cx + cell_w / 2 + 1, ty + 1, cell.expr, scale,
					Color{
					r: 0
					g: 0
					b: 0
					a: 180
				})
				draw_text_centered(renderer, cx + cell_w / 2, ty, cell.expr, scale, Color{
					r: 255
					g: 255
					b: 255
				})
			}
		}
	}
}

fn render_selection_reticle(renderer &Renderer, cx int, cy int, cw int, ch int, anim_t f64) {
	pulse := int(math.sin(anim_t * 8.0) * 3.0)
	pad := 3 + pulse
	x := cx - pad
	y := cy - pad
	w := cw + pad * 2
	h := ch + pad * 2

	len := 12
	set_render_draw_color(renderer, 255, 230, 80, 255)

	render_draw_line(renderer, x, y, x + len, y)
	render_draw_line(renderer, x, y, x, y + len)

	render_draw_line(renderer, x + w - len, y, x + w, y)
	render_draw_line(renderer, x + w, y, x + w, y + len)

	render_draw_line(renderer, x, y + h - len, x, y + h)
	render_draw_line(renderer, x, y + h, x + len, y + h)

	render_draw_line(renderer, x + w - len, y + h, x + w, y + h)
	render_draw_line(renderer, x + w, y + h - len, x + w, y + h)
}

fn render_troggle_warnings(renderer &Renderer, game &MathMunchersGame, sx int, sy int) {
	start_x := 45 + sx
	start_y := 118 + sy
	cell_w := 115
	cell_h := 78
	gap := 7

	for w in game.troggle_warnings {
		if int(w.timer * 10.0) % 2 == 0 {
			wx := start_x + w.grid_x * (cell_w + gap) + cell_w / 2 - 10
			wy := start_y + w.grid_y * (cell_h + gap) + cell_h / 2 - 10
			draw_text(renderer, wx, wy, '[!]', 2, Color{
				r: 255
				g: 50
				b: 50
			})
		}
	}
}

fn render_muncher(renderer &Renderer, p &Player, anim_t f64, sx int, sy int) {
	start_x := 45 + sx
	start_y := 118 + sy
	cell_w := 115
	cell_h := 78
	gap := 7

	bob_y := int(math.sin(anim_t * 6.0) * 2.0)
	mx := start_x + int(p.real_x * f64(cell_w + gap)) + 12
	my := start_y + int(p.real_y * f64(cell_h + gap)) + 8 + bob_y
	mw := cell_w - 24
	mh := cell_h - 16

	if p.invincibility_timer > 0 {
		if int(p.invincibility_timer * 15.0) % 2 == 0 {
			aura := Rect{
				x: mx - 4
				y: my - 4
				w: mw + 8
				h: mh + 8
			}
			set_render_draw_color(renderer, 100, 255, 180, 180)
			render_fill_rect(renderer, &aura)
		}
	}

	body_rect := Rect{
		x: mx
		y: my
		w: mw
		h: mh
	}
	set_render_draw_color(renderer, 50, 215, 75, 255)
	render_fill_rect(renderer, &body_rect)

	highlight := Rect{
		x: mx + 2
		y: my + 2
		w: mw - 4
		h: 6
	}
	set_render_draw_color(renderer, 120, 255, 140, 255)
	render_fill_rect(renderer, &highlight)

	set_render_draw_color(renderer, 15, 95, 35, 255)
	render_draw_rect(renderer, &body_rect)

	leg_step := int(math.sin(anim_t * 12.0) * 3.0)
	foot1 := Rect{
		x: mx + 10
		y: my + mh
		w: 16
		h: 6 + leg_step
	}
	foot2 := Rect{
		x: mx + mw - 26
		y: my + mh
		w: 16
		h: 6 - leg_step
	}
	set_render_draw_color(renderer, 35, 160, 55, 255)
	render_fill_rect(renderer, &foot1)
	render_fill_rect(renderer, &foot2)

	cheek1 := Rect{
		x: mx + 6
		y: my + 24
		w: 8
		h: 6
	}
	cheek2 := Rect{
		x: mx + mw - 14
		y: my + 24
		w: 8
		h: 6
	}
	set_render_draw_color(renderer, 255, 140, 160, 220)
	render_fill_rect(renderer, &cheek1)
	render_fill_rect(renderer, &cheek2)

	is_blinking := p.blink_timer < 0.15

	if is_blinking {
		set_render_draw_color(renderer, 15, 95, 35, 255)
		render_draw_line(renderer, mx + 14, my + 14, mx + 28, my + 14)
		render_draw_line(renderer, mx + 42, my + 14, mx + 56, my + 14)
	} else {
		eye1 := Rect{
			x: mx + 12
			y: my + 8
			w: 18
			h: 18
		}
		eye2 := Rect{
			x: mx + mw - 30
			y: my + 8
			w: 18
			h: 18
		}
		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_fill_rect(renderer, &eye1)
		render_fill_rect(renderer, &eye2)
		set_render_draw_color(renderer, 15, 95, 35, 255)
		render_draw_rect(renderer, &eye1)
		render_draw_rect(renderer, &eye2)

		pupil_off := if p.facing_right { 3 } else { 0 }
		pupil1 := Rect{
			x: mx + 15 + pupil_off
			y: my + 12
			w: 10
			h: 10
		}
		pupil2 := Rect{
			x: mx + mw - 27 + pupil_off
			y: my + 12
			w: 10
			h: 10
		}
		set_render_draw_color(renderer, 10, 20, 45, 255)
		render_fill_rect(renderer, &pupil1)
		render_fill_rect(renderer, &pupil2)

		c1 := Rect{
			x: mx + 16 + pupil_off
			y: my + 13
			w: 3
			h: 3
		}
		c2 := Rect{
			x: mx + mw - 26 + pupil_off
			y: my + 13
			w: 3
			h: 3
		}
		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_fill_rect(renderer, &c1)
		render_fill_rect(renderer, &c2)
	}

	if p.munch_anim_timer > 0 {
		mouth := Rect{
			x: mx + 10
			y: my + 30
			w: mw - 20
			h: 24
		}
		set_render_draw_color(renderer, 210, 35, 55, 255)
		render_fill_rect(renderer, &mouth)

		t1 := Rect{
			x: mx + 14
			y: my + 30
			w: 8
			h: 8
		}
		t2 := Rect{
			x: mx + 28
			y: my + 30
			w: 8
			h: 8
		}
		t3 := Rect{
			x: mx + 42
			y: my + 30
			w: 8
			h: 8
		}
		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_fill_rect(renderer, &t1)
		render_fill_rect(renderer, &t2)
		render_fill_rect(renderer, &t3)
	} else {
		smile := Rect{
			x: mx + 18
			y: my + 36
			w: mw - 36
			h: 10
		}
		set_render_draw_color(renderer, 15, 60, 25, 255)
		render_fill_rect(renderer, &smile)
	}
}

fn render_troggle(renderer &Renderer, tr &Troggle, is_frozen bool, _anim_t f64, sx int, sy int) {
	start_x := 45 + sx
	start_y := 118 + sy
	cell_w := 115
	cell_h := 78
	gap := 7

	tx := start_x + int(tr.real_x * f64(cell_w + gap)) + 16
	ty := start_y + int(tr.real_y * f64(cell_h + gap)) + 12
	tw := cell_w - 32
	th := cell_h - 24

	body := Rect{
		x: tx
		y: ty
		w: tw
		h: th
	}

	match tr.kind {
		.reggie {
			set_render_draw_color(renderer, 190, 50, 210, 255)
			render_fill_rect(renderer, &body)

			hi := Rect{
				x: tx + 2
				y: ty + 2
				w: tw - 4
				h: 5
			}
			set_render_draw_color(renderer, 230, 100, 250, 255)
			render_fill_rect(renderer, &hi)

			set_render_draw_color(renderer, 110, 20, 130, 255)
			render_draw_rect(renderer, &body)

			antenna_dx := int(math.sin(tr.anim_timer * 8.0) * 5.0)
			ant1 := Rect{
				x: tx + 6 + antenna_dx
				y: ty - 8
				w: 6
				h: 9
			}
			ant2 := Rect{
				x: tx + tw - 12 + antenna_dx
				y: ty - 8
				w: 6
				h: 9
			}
			set_render_draw_color(renderer, 240, 90, 255, 255)
			render_fill_rect(renderer, &ant1)
			render_fill_rect(renderer, &ant2)

			e1 := Rect{
				x: tx + 5
				y: ty + 8
				w: 10
				h: 10
			}
			e2 := Rect{
				x: tx + 20
				y: ty + 8
				w: 10
				h: 10
			}
			e3 := Rect{
				x: tx + 35
				y: ty + 8
				w: 10
				h: 10
			}
			set_render_draw_color(renderer, 255, 235, 60, 255)
			render_fill_rect(renderer, &e1)
			render_fill_rect(renderer, &e2)
			render_fill_rect(renderer, &e3)
			set_render_draw_color(renderer, 110, 20, 130, 255)
			render_draw_rect(renderer, &e1)
			render_draw_rect(renderer, &e2)
			render_draw_rect(renderer, &e3)

			p1 := Rect{
				x: tx + 8
				y: ty + 10
				w: 5
				h: 5
			}
			p2 := Rect{
				x: tx + 23
				y: ty + 10
				w: 5
				h: 5
			}
			p3 := Rect{
				x: tx + 38
				y: ty + 10
				w: 5
				h: 5
			}
			set_render_draw_color(renderer, 20, 10, 30, 255)
			render_fill_rect(renderer, &p1)
			render_fill_rect(renderer, &p2)
			render_fill_rect(renderer, &p3)

			mouth := Rect{
				x: tx + 8
				y: ty + 24
				w: tw - 16
				h: 14
			}
			set_render_draw_color(renderer, 200, 30, 60, 255)
			render_fill_rect(renderer, &mouth)

			t1 := Rect{
				x: tx + 12
				y: ty + 24
				w: 5
				h: 5
			}
			t2 := Rect{
				x: tx + tw - 17
				y: ty + 24
				w: 5
				h: 5
			}
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rect(renderer, &t1)
			render_fill_rect(renderer, &t2)

			foot1 := Rect{
				x: tx + 6
				y: ty + th
				w: 12
				h: 5
			}
			foot2 := Rect{
				x: tx + tw - 18
				y: ty + th
				w: 12
				h: 5
			}
			set_render_draw_color(renderer, 140, 30, 160, 255)
			render_fill_rect(renderer, &foot1)
			render_fill_rect(renderer, &foot2)
		}
		.smartie {
			set_render_draw_color(renderer, 255, 120, 20, 255)
			render_fill_rect(renderer, &body)

			hi := Rect{
				x: tx + 2
				y: ty + 2
				w: tw - 4
				h: 5
			}
			set_render_draw_color(renderer, 255, 170, 70, 255)
			render_fill_rect(renderer, &hi)

			set_render_draw_color(renderer, 160, 60, 10, 255)
			render_draw_rect(renderer, &body)

			h1 := Rect{
				x: tx + 4
				y: ty - 9
				w: 8
				h: 11
			}
			h2 := Rect{
				x: tx + tw - 12
				y: ty - 9
				w: 8
				h: 11
			}
			set_render_draw_color(renderer, 255, 30, 30, 255)
			render_fill_rect(renderer, &h1)
			render_fill_rect(renderer, &h2)

			e1 := Rect{
				x: tx + 8
				y: ty + 10
				w: 12
				h: 10
			}
			e2 := Rect{
				x: tx + tw - 20
				y: ty + 10
				w: 12
				h: 10
			}
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rect(renderer, &e1)
			render_fill_rect(renderer, &e2)

			p1 := Rect{
				x: tx + 12
				y: ty + 12
				w: 6
				h: 6
			}
			p2 := Rect{
				x: tx + tw - 18
				y: ty + 12
				w: 6
				h: 6
			}
			set_render_draw_color(renderer, 220, 0, 0, 255)
			render_fill_rect(renderer, &p1)
			render_fill_rect(renderer, &p2)

			set_render_draw_color(renderer, 160, 60, 10, 255)
			render_draw_line(renderer, tx + 6, ty + 8, tx + 20, ty + 13)
			render_draw_line(renderer, tx + tw - 6, ty + 8, tx + tw - 20, ty + 13)

			mouth := Rect{
				x: tx + 10
				y: ty + 25
				w: tw - 20
				h: 14
			}
			set_render_draw_color(renderer, 180, 20, 20, 255)
			render_fill_rect(renderer, &mouth)

			fang1 := Rect{
				x: tx + 12
				y: ty + 25
				w: 5
				h: 7
			}
			fang2 := Rect{
				x: tx + tw - 17
				y: ty + 25
				w: 5
				h: 7
			}
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rect(renderer, &fang1)
			render_fill_rect(renderer, &fang2)
		}
		.glutton {
			set_render_draw_color(renderer, 30, 160, 240, 255)
			render_fill_rect(renderer, &body)
			set_render_draw_color(renderer, 10, 80, 150, 255)
			render_draw_rect(renderer, &body)

			e1 := Rect{
				x: tx + 8
				y: ty + 4
				w: 10
				h: 10
			}
			e2 := Rect{
				x: tx + tw - 18
				y: ty + 4
				w: 10
				h: 10
			}
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rect(renderer, &e1)
			render_fill_rect(renderer, &e2)

			p1 := Rect{
				x: tx + 11
				y: ty + 6
				w: 5
				h: 5
			}
			p2 := Rect{
				x: tx + tw - 15
				y: ty + 6
				w: 5
				h: 5
			}
			set_render_draw_color(renderer, 10, 20, 45, 255)
			render_fill_rect(renderer, &p1)
			render_fill_rect(renderer, &p2)

			jaw_open := int(math.sin(tr.anim_timer * 10.0) * 4.0)
			jaw := Rect{
				x: tx + 6
				y: ty + 16 - jaw_open
				w: tw - 12
				h: 20 + jaw_open * 2
			}
			set_render_draw_color(renderer, 20, 15, 35, 255)
			render_fill_rect(renderer, &jaw)

			for i in 0 .. 4 {
				tx_top := Rect{
					x: tx + 8 + i * 10
					y: ty + 16 - jaw_open
					w: 5
					h: 6
				}
				tx_bot := Rect{
					x: tx + 8 + i * 10
					y: ty + 30 + jaw_open
					w: 5
					h: 6
				}
				set_render_draw_color(renderer, 255, 255, 255, 255)
				render_fill_rect(renderer, &tx_top)
				render_fill_rect(renderer, &tx_bot)
			}
		}
		.bashful {
			set_render_draw_color(renderer, 40, 220, 220, 255)
			render_fill_rect(renderer, &body)
			set_render_draw_color(renderer, 10, 140, 140, 255)
			render_draw_rect(renderer, &body)

			ch1 := Rect{
				x: tx + 4
				y: ty + 16
				w: 8
				h: 6
			}
			ch2 := Rect{
				x: tx + tw - 12
				y: ty + 16
				w: 8
				h: 6
			}
			set_render_draw_color(renderer, 255, 140, 180, 255)
			render_fill_rect(renderer, &ch1)
			render_fill_rect(renderer, &ch2)

			e1 := Rect{
				x: tx + 10
				y: ty + 8
				w: 9
				h: 9
			}
			e2 := Rect{
				x: tx + tw - 19
				y: ty + 8
				w: 9
				h: 9
			}
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rect(renderer, &e1)
			render_fill_rect(renderer, &e2)

			p1 := Rect{
				x: tx + 11
				y: ty + 10
				w: 4
				h: 5
			}
			p2 := Rect{
				x: tx + tw - 18
				y: ty + 10
				w: 4
				h: 5
			}
			set_render_draw_color(renderer, 10, 30, 45, 255)
			render_fill_rect(renderer, &p1)
			render_fill_rect(renderer, &p2)

			m := Rect{
				x: tx + tw / 2 - 3
				y: ty + 24
				w: 6
				h: 7
			}
			set_render_draw_color(renderer, 10, 80, 80, 255)
			render_fill_rect(renderer, &m)
		}
		.helper {
			set_render_draw_color(renderer, 80, 240, 140, 255)
			render_fill_rect(renderer, &body)
			set_render_draw_color(renderer, 20, 140, 60, 255)
			render_draw_rect(renderer, &body)

			draw_text_centered(renderer, tx + tw / 2, ty - 12, '*', 2, Color{
				r: 255
				g: 235
				b: 60
			})

			e1 := Rect{
				x: tx + 10
				y: ty + 10
				w: 9
				h: 9
			}
			e2 := Rect{
				x: tx + tw - 19
				y: ty + 10
				w: 9
				h: 9
			}
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_fill_rect(renderer, &e1)
			render_fill_rect(renderer, &e2)

			p1 := Rect{
				x: tx + 13
				y: ty + 12
				w: 4
				h: 5
			}
			p2 := Rect{
				x: tx + tw - 16
				y: ty + 12
				w: 4
				h: 5
			}
			set_render_draw_color(renderer, 10, 50, 20, 255)
			render_fill_rect(renderer, &p1)
			render_fill_rect(renderer, &p2)

			m := Rect{
				x: tx + 12
				y: ty + 24
				w: tw - 24
				h: 8
			}
			set_render_draw_color(renderer, 10, 60, 25, 255)
			render_fill_rect(renderer, &m)
		}
	}

	if is_frozen {
		ice := Rect{
			x: tx - 2
			y: ty - 2
			w: tw + 4
			h: th + 4
		}
		set_render_draw_color(renderer, 140, 220, 255, 160)
		render_fill_rect(renderer, &ice)
	}
}

fn render_bonus_round(renderer &Renderer, game &MathMunchersGame, sx int, sy int) {
	draw_text_centered(renderer, 400 + sx, 140 + sy, 'BONUS ROUND!', 3, Color{
		r: 255
		g: 220
		b: 50
	})
	draw_text_centered(renderer, 400 + sx, 185 + sy, 'Catch falling bonus stars! Time: ${int(game.bonus_timer)}s',
		1, Color{
		r: 200
		g: 240
		b: 255
	})

	for bs in game.bonus_stars {
		s_rect := Rect{
			x: int(bs.x) - 15 + sx
			y: int(bs.y) - 15 + sy
			w: 30
			h: 30
		}
		set_render_draw_color(renderer, 255, 220, 50, 255)
		render_fill_rect(renderer, &s_rect)
		draw_text_centered(renderer, int(bs.x) + sx, int(bs.y) - 6 + sy, '+200', 1, Color{
			r: 20
			g: 20
			b: 20
		})
	}

	render_muncher(renderer, &game.player, game.global_anim_time, sx, sy)
}

fn render_effects(renderer &Renderer, game &MathMunchersGame, sx int, sy int) {
	for p in game.particles {
		prect := Rect{
			x: int(p.x) + sx
			y: int(p.y) + sy
			w: p.size
			h: p.size
		}
		set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, p.color.a)
		render_fill_rect(renderer, &prect)
	}

	for ft in game.floating_texts {
		draw_text_centered(renderer, int(ft.x) + sx, int(ft.y) + sy, ft.text, 2, ft.color)
	}
}

fn render_overlays(renderer &Renderer, game &MathMunchersGame) {
	match game.state {
		.start_menu {
			render_start_menu_overlay(renderer, game)
		}
		.paused {
			render_overlay_box(renderer, 'PAUSED', [
				'Game is paused.',
				'Difficulty: ${game.difficulty}',
				'Press [P] or [SPACE] to resume.',
				'Press [D] to Cycle Difficulty Mode.',
				'Press [M] or [ESC] to return to Main Menu.',
			], Color{
				r: 255
				g: 215
				b: 0
			})
		}
		.level_clear {
			render_overlay_box(renderer, 'STAGE CLEAR!', [
				'Great job! All target numbers cleared!',
				'Stage Bonus: +${500 * game.level} Points!',
				'Press [SPACE] to Advance to Stage ${game.level + 1}',
			], Color{
				r: 100
				g: 255
				b: 140
			})
		}
		.game_over {
			render_overlay_box(renderer, 'GAME OVER', [
				'Final Score: ${game.score}',
				'High Score: ${game.high_score}',
				'Press [R] or [SPACE] to Try Again!',
			], Color{
				r: 255
				g: 80
				b: 80
			})
		}
		else {}
	}
}

fn render_start_menu_overlay(renderer &Renderer, game &MathMunchersGame) {
	overlay := Rect{
		x: 80
		y: 110
		w: 640
		h: 380
	}

	set_render_draw_color(renderer, 0, 0, 0, 220)
	render_fill_rect(renderer, &overlay)

	set_render_draw_color(renderer, 15, 25, 45, 255)
	inner := Rect{
		x: 84
		y: 114
		w: 632
		h: 372
	}
	render_fill_rect(renderer, &inner)

	set_render_draw_color(renderer, 50, 215, 75, 255)
	render_draw_rect(renderer, &overlay)

	// Title
	draw_text_centered(renderer, 400, 135, 'MATH MUNCHERS', 3, Color{
		r: 50
		g: 215
		b: 75
	})
	draw_text_centered(renderer, 400, 175, 'SELECT DIFFICULTY LEVEL:', 1, Color{
		r: 255
		g: 225
		b: 70
	})

	// Difficulty Selector Tabs
	easy_color := if game.difficulty == .easy {
		Color{
			r: 50
			g: 220
			b: 100
		}
	} else {
		Color{
			r: 60
			g: 90
			b: 120
		}
	}
	med_color := if game.difficulty == .medium {
		Color{
			r: 255
			g: 220
			b: 70
		}
	} else {
		Color{
			r: 60
			g: 90
			b: 120
		}
	}
	hard_color := if game.difficulty == .hard {
		Color{
			r: 255
			g: 80
			b: 80
		}
	} else {
		Color{
			r: 60
			g: 90
			b: 120
		}
	}

	// Easy Tab
	e_rect := Rect{
		x: 120
		y: 200
		w: 160
		h: 40
	}
	set_render_draw_color(renderer, easy_color.r, easy_color.g, easy_color.b, 255)
	render_draw_rect(renderer, &e_rect)
	draw_text_centered(renderer, 200, 212, '[1] EASY', 2, easy_color)

	// Normal Tab
	m_rect := Rect{
		x: 320
		y: 200
		w: 160
		h: 40
	}
	set_render_draw_color(renderer, med_color.r, med_color.g, med_color.b, 255)
	render_draw_rect(renderer, &m_rect)
	draw_text_centered(renderer, 400, 212, '[2] NORMAL', 2, med_color)

	// Hard Tab
	h_rect := Rect{
		x: 520
		y: 200
		w: 160
		h: 40
	}
	set_render_draw_color(renderer, hard_color.r, hard_color.g, hard_color.b, 255)
	render_draw_rect(renderer, &h_rect)
	draw_text_centered(renderer, 600, 212, '[3] HARD', 2, hard_color)

	// Active difficulty summary description
	desc := match game.difficulty {
		.easy { 'EASY: 4 Lives | Slow Troggles (Max 1) | Grade 1-3 Math' }
		.hard { 'HARD: 2 Lives | Fast Troggles (Max 3) | 2.0x Score Bonus' }
		else { 'NORMAL: 3 Lives | Standard Troggles (Max 2) | 1.5x Score Bonus' }
	}
	draw_text_centered(renderer, 400, 260, desc, 1, Color{
		r: 180
		g: 220
		b: 255
	})

	draw_text_centered(renderer, 400, 310, 'Controls: [WASD / ARROWS] Move | [SPACE / ENTER] Chomp',
		1, Color{
		r: 200
		g: 200
		b: 220
	})
	draw_text_centered(renderer, 400, 340, 'Keys: [1] Easy | [2] Normal | [3] Hard', 1, Color{
		r: 200
		g: 200
		b: 220
	})

	pulse := int(math.sin(game.global_anim_time * 8.0) * 20.0)
	draw_text_centered(renderer, 400, 420, 'PRESS [SPACE] TO START PLAYING!', 2, Color{
		r: u8(255)
		g: u8(230 + pulse)
		b: u8(80)
	})
}

fn render_overlay_box(renderer &Renderer, title string, lines []string, title_color Color) {
	overlay := Rect{
		x: 100
		y: 140
		w: 600
		h: 320
	}

	set_render_draw_color(renderer, 0, 0, 0, 210)
	render_fill_rect(renderer, &overlay)

	set_render_draw_color(renderer, 15, 25, 45, 255)
	inner := Rect{
		x: 104
		y: 144
		w: 592
		h: 312
	}
	render_fill_rect(renderer, &inner)

	set_render_draw_color(renderer, title_color.r, title_color.g, title_color.b, 255)
	render_draw_rect(renderer, &overlay)

	draw_text_centered(renderer, 400, 170, title, 3, title_color)

	mut ly := 240
	for line in lines {
		draw_text_centered(renderer, 400, ly, line, 1, Color{
			r: 230
			g: 240
			b: 255
		})
		ly += 30
	}
}
