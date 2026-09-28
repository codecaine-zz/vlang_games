module main

import rand
import time

fn render_galaga_game(renderer &Renderer, mut g GalagaGame) {
	shake_mag := g.shake_trauma * g.shake_trauma * 16.0
	sx := if shake_mag > 0.01 { f32((rand.f64() * 2.0 - 1.0) * shake_mag) } else { f32(0.0) }
	sy := if shake_mag > 0.01 { f32((rand.f64() * 2.0 - 1.0) * shake_mag) } else { f32(0.0) }
	unsafe {
		mut ren := &Renderer(renderer)
		ren.offset_x += sx
		ren.offset_y += sy
	}
	defer {
		unsafe {
			mut ren := &Renderer(renderer)
			ren.offset_x -= sx
			ren.offset_y -= sy
		}
	}

	// Clear screen to space black
	set_render_draw_color(renderer, 5, 5, 15, 255)
	render_clear(renderer)

	// 1. Draw Starfield
	for s in g.stars {
		set_render_draw_color(renderer, s.brightness, s.brightness, s.brightness, 255)
		rect := Rect{ x: int(s.x), y: int(s.y), w: s.size, h: s.size }
		render_fill_rect(renderer, &rect)
	}

	// 2. Draw Tractor Beam if active
	if g.tractor_active {
		for mut e in g.enemies {
			if e.id == g.tractor_enemy_id && e.active {
				for row in 0 .. 15 {
					y_pos := int(e.y + 20.0 + f32(row) * 18.0)
					width := 20 + row * 6
					x_left := int(e.x) - width / 2
					rect := Rect{ x: x_left, y: y_pos, w: width, h: 10 }
					alpha := u8(80 + (row % 2) * 80)
					set_render_draw_color(renderer, 0, 200, 255, alpha)
					render_fill_rect(renderer, &rect)
				}
			}
		}
	}

	// 3. Draw Captured Ship attached to Boss
	if g.captured_ship_x > 0 && g.captured_ship_y > 0 {
		draw_player_ship(renderer, g.sprite_texture, g.captured_ship_x, g.captured_ship_y, false, Color{ r: 255, g: 100, b: 100, a: 255 })
	}

	// 4. Draw Rescuable Ships falling down
	for rs in g.rescuable_ships {
		if !rs.active { continue }
		draw_player_ship(renderer, g.sprite_texture, rs.x, rs.y, false, Color{ r: 100, g: 255, b: 150, a: 255 })
	}

	// 5. Draw Enemies
	for e in g.enemies {
		if !e.active { continue }
		draw_enemy_ship(renderer, g.sprite_texture, e)
	}

	// 6. Draw Player Ship
	if g.state == .playing || g.state == .paused {
		if g.player.invuln_timer <= 0 || (int(g.player.invuln_timer * 10.0) % 2 == 0) {
			p_color := if g.player.is_capturing { Color{ r: 255, g: 120, b: 120, a: 255 } } else { Color{ r: 255, g: 255, b: 255, a: 255 } }
			if g.player.is_dual {
				draw_player_ship(renderer, g.sprite_texture, g.player.x - g.player.dual_offset / 2.0, g.player.y, false, p_color)
				draw_player_ship(renderer, g.sprite_texture, g.player.x + g.player.dual_offset / 2.0, g.player.y, false, p_color)
			} else {
				draw_player_ship(renderer, g.sprite_texture, g.player.x, g.player.y, false, p_color)
			}
		}
	}

	// 7. Draw Bullets with glowing laser corona
	for b in g.player_bullets {
		if !b.active { continue }
		// Yellow-orange photon aura
		set_render_draw_color(renderer, 255, 180, 40, 130)
		glow := Rect{ x: int(b.x) - 4, y: int(b.y) - 8, w: 8, h: 16 }
		render_fill_rect(renderer, &glow)

		set_render_draw_color(renderer, 255, 255, 200, 255)
		rect := Rect{ x: int(b.x) - 2, y: int(b.y) - 6, w: 4, h: 12 }
		render_fill_rect(renderer, &rect)
	}

	for eb in g.enemy_bullets {
		if !eb.active { continue }
		set_render_draw_color(renderer, 255, 30, 30, 120)
		glow := Rect{ x: int(eb.x) - 3, y: int(eb.y) - 5, w: 6, h: 10 }
		render_fill_rect(renderer, &glow)

		set_render_draw_color(renderer, 255, 180, 180, 255)
		rect := Rect{ x: int(eb.x) - 2, y: int(eb.y) - 4, w: 4, h: 8 }
		render_fill_rect(renderer, &rect)
	}

	// 8. Draw Particles
	for p in g.particles {
		alpha := u8(p.life / p.max_life * 255.0)
		set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, alpha)
		rect := Rect{ x: int(p.x) - 1, y: int(p.y) - 1, w: 3, h: 3 }
		render_fill_rect(renderer, &rect)
	}

	// 9. Draw Top HUD
	draw_text(renderer, 20, 15, "1UP ${g.score}", 2, Color{ r: 255, g: 50, b: 50, a: 255 })
	draw_text(renderer, 320, 15, "HIGH ${g.high_score}", 2, Color{ r: 255, g: 215, b: 0, a: 255 })
	draw_text(renderer, 650, 15, "STAGE ${g.stage}", 2, Color{ r: 0, g: 255, b: 255, a: 255 })

	// Lives Icons at Bottom-Left
	for l in 0 .. g.player.lives {
		draw_player_ship(renderer, g.sprite_texture, 25.0 + f32(l) * 26.0, 580.0, true, Color{ r: 255, g: 255, b: 255, a: 255 })
	}

	// Stage Flags / Badges at Bottom-Right
	draw_stage_badges(renderer, g.sprite_texture, g.stage)

	// Stage Intro Banners ("STAGE X", "READY!", "CHALLENGING STAGE")
	if g.state == .playing && g.stage_intro_timer > 0 {
		if g.is_challenge_stage {
			draw_text_centered(renderer, 400, 260, "CHALLENGING STAGE", 3, Color{ r: 0, g: 240, b: 255, a: 255 })
		} else {
			draw_text_centered(renderer, 400, 250, "STAGE ${g.stage}", 3, Color{ r: 0, g: 255, b: 255, a: 255 })
			draw_text_centered(renderer, 400, 290, "READY", 2, Color{ r: 255, g: 50, b: 50, a: 255 })
		}
	}

	// Stage Clear Banner
	if g.state == .playing && g.stage_clear_timer > 0 {
		draw_text_centered(renderer, 400, 260, "STAGE CLEAR!", 3, Color{ r: 255, g: 220, b: 40, a: 255 })
		bonus_str := if g.is_challenge_stage && g.challenge_hits == g.challenge_total {
			"PERFECT! BONUS 10000 PTS"
		} else {
			"STAGE BONUS +${1000 + g.stage * 200}"
		}
		draw_text_centered(renderer, 400, 300, bonus_str, 2, Color{ r: 100, g: 255, b: 150, a: 255 })
	}

	// 10. Overlay Menus
	if g.state == .menu {
		draw_text_centered(renderer, 400, 170, "GALAGA ARCADE", 4, Color{ r: 255, g: 50, b: 50, a: 255 })
		draw_text_centered(renderer, 400, 230, "CYBER SPACE SHOOTER", 2, Color{ r: 0, g: 200, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 320, "PRESS SPACE TO START", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 380, "CONTROLS: A/D OR ARROWS MOVE | SPACE FIRE | F11: Fullscreen", 1, Color{ r: 180, g: 180, b: 180, a: 255 })
		draw_text_centered(renderer, 400, 400, "DUAL FIGHTER RESCUE | M MUTE | R RESET", 1, Color{ r: 180, g: 180, b: 180, a: 255 })
	} else if g.state == .game_over {
		draw_text_centered(renderer, 400, 230, "GAME OVER", 4, Color{ r: 255, g: 50, b: 50, a: 255 })
		draw_text_centered(renderer, 400, 300, "FINAL SCORE: ${g.score}", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 330, "REACHED STAGE ${g.stage}", 2, Color{ r: 0, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 380, "PRESS SPACE OR R TO RESTART", 2, Color{ r: 0, g: 255, b: 100, a: 255 })
	} else if g.state == .paused {
		draw_text_centered(renderer, 400, 280, "- PAUSED -", 3, Color{ r: 255, g: 255, b: 0, a: 255 })
	}

	if renderer.ctx != unsafe { nil } { prod_fx_render(renderer.ctx) }
	render_present(renderer)
}

fn draw_stage_badges(renderer &Renderer, texture &Texture, stage int) {
	mut s := stage
	mut bx := 770
	by := 575

	if texture != unsafe { nil } {
		// Badges on Y=96: 1=0, 5=32, 10=64, 20=96, 30=128, 50=160
		badge_types := [
			struct { val: 50, sx: 160 },
			struct { val: 30, sx: 128 },
			struct { val: 20, sx: 96 },
			struct { val: 10, sx: 64 },
			struct { val: 5, sx: 32 },
			struct { val: 1, sx: 0 },
		]
		for b in badge_types {
			for s >= b.val && bx > 500 {
				src := Rect{ x: b.sx, y: 96, w: 32, h: 32 }
				dst := Rect{ x: bx - 10, y: by - 10, w: 20, h: 20 }
				render_copy(renderer, texture, &src, &dst)
				bx -= 22
				s -= b.val
			}
		}
		return
	}

	// 50-flag
	for s >= 50 && bx > 500 {
		draw_flag(renderer, bx, by, Color{ r: 255, g: 215, b: 0, a: 255 }, '50')
		bx -= 24
		s -= 50
	}
	// 30-flag
	for s >= 30 && bx > 500 {
		draw_flag(renderer, bx, by, Color{ r: 255, g: 100, b: 100, a: 255 }, '30')
		bx -= 24
		s -= 30
	}
	// 20-flag
	for s >= 20 && bx > 500 {
		draw_flag(renderer, bx, by, Color{ r: 100, g: 150, b: 255, a: 255 }, '20')
		bx -= 24
		s -= 20
	}
	// 10-flag
	for s >= 10 && bx > 500 {
		draw_flag(renderer, bx, by, Color{ r: 255, g: 50, b: 50, a: 255 }, '10')
		bx -= 24
		s -= 10
	}
	// 5-badge
	for s >= 5 && bx > 500 {
		draw_flag(renderer, bx, by, Color{ r: 255, g: 200, b: 40, a: 255 }, '5')
		bx -= 20
		s -= 5
	}
	// 1-badge
	for s >= 1 && bx > 500 {
		draw_flag(renderer, bx, by, Color{ r: 100, g: 200, b: 255, a: 255 }, '1')
		bx -= 16
		s -= 1
	}
}

fn draw_flag(renderer &Renderer, x int, y int, col Color, _ string) {
	set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
	rect := Rect{ x: x - 6, y: y - 8, w: 12, h: 16 }
	render_fill_rect(renderer, &rect)

	set_render_draw_color(renderer, 255, 255, 255, 255)
	tri := Rect{ x: x - 4, y: y - 6, w: 8, h: 8 }
	render_fill_rect(renderer, &tri)
}

// 16x16 Pixel Sprite Matrices for Galaga Arcade

// Galaga Player Fighter (16x16)
// 0: trans, 1: outline, 2: white fuselage, 3: red swept wings, 4: yellow tip/guns, 5: cyan/blue cockpit, 6: blue thruster
const galaga_player_sprite = [
	[0,0,0,0,0,0,0,4,4,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,4,4,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,1,2,2,1,0,0,0,0,0,0],
	[0,0,0,0,0,0,1,2,2,1,0,0,0,0,0,0],
	[0,0,0,0,0,1,2,5,5,2,1,0,0,0,0,0],
	[0,0,0,0,0,1,2,5,5,2,1,0,0,0,0,0],
	[0,0,0,0,1,2,2,2,2,2,2,1,0,0,0,0],
	[0,4,0,0,1,2,3,3,3,3,2,1,0,0,4,0],
	[0,4,0,1,3,3,3,3,3,3,3,3,1,0,4,0],
	[0,1,1,3,3,3,3,3,3,3,3,3,3,1,1,0],
	[1,3,3,3,3,3,1,2,2,1,3,3,3,3,3,1],
	[1,3,3,3,3,1,2,2,2,2,1,3,3,3,3,1],
	[1,3,3,3,1,2,2,2,2,2,2,1,3,3,3,1],
	[0,1,1,1,1,2,2,6,6,2,2,1,1,1,1,0],
	[0,0,0,0,1,1,6,6,6,6,1,1,0,0,0,0],
	[0,0,0,0,0,1,1,0,0,1,1,0,0,0,0,0]
]

// Zako Blue Bee Frame 0 (Wings Down)
// 0: trans, 1: outline, 2: blue body, 3: yellow wings, 4: red eyes
const galaga_zako_f0 = [
	[0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0],
	[0,0,0,0,1,1,4,4,4,4,1,1,0,0,0,0],
	[0,0,0,1,2,2,4,4,4,4,2,2,1,0,0,0],
	[0,0,1,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[0,1,3,3,2,2,2,2,2,2,2,2,3,3,1,0],
	[1,3,3,3,3,2,2,2,2,2,2,3,3,3,3,1],
	[1,3,3,3,3,3,2,2,2,2,3,3,3,3,3,1],
	[1,3,3,3,3,3,1,2,2,1,3,3,3,3,3,1],
	[0,1,3,3,3,1,2,2,2,2,1,3,3,3,1,0],
	[0,0,1,1,1,2,2,2,2,2,2,1,1,1,0,0],
	[0,0,0,1,2,2,3,3,3,3,2,2,1,0,0,0],
	[0,0,1,2,2,3,3,3,3,3,3,2,2,1,0,0],
	[0,0,1,2,3,3,3,3,3,3,3,3,2,1,0,0],
	[0,0,0,1,2,3,3,3,3,3,3,2,1,0,0,0],
	[0,0,0,0,1,1,2,2,2,2,1,1,0,0,0,0],
	[0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0]
]

// Zako Blue Bee Frame 1 (Wings Up)
const galaga_zako_f1 = [
	[0,1,3,3,0,0,1,1,1,1,0,0,3,3,1,0],
	[1,3,3,3,1,1,4,4,4,4,1,1,3,3,3,1],
	[1,3,3,3,3,2,4,4,4,4,2,3,3,3,3,1],
	[1,3,3,3,3,2,2,2,2,2,2,3,3,3,3,1],
	[0,1,3,3,2,2,2,2,2,2,2,2,3,3,1,0],
	[0,0,1,1,2,2,2,2,2,2,2,2,1,1,0,0],
	[0,0,0,1,2,2,2,2,2,2,2,2,1,0,0,0],
	[0,0,0,1,2,2,1,2,2,1,2,2,1,0,0,0],
	[0,0,0,1,2,1,2,2,2,2,1,2,1,0,0,0],
	[0,0,1,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[0,0,1,2,2,3,3,3,3,3,3,2,2,1,0,0],
	[0,0,1,2,3,3,3,3,3,3,3,3,2,1,0,0],
	[0,0,0,1,3,3,3,3,3,3,3,3,1,0,0,0],
	[0,0,0,1,2,3,3,3,3,3,3,2,1,0,0,0],
	[0,0,0,0,1,1,2,2,2,2,1,1,0,0,0,0],
	[0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0]
]

// Goei Red Butterfly Frame 0 (Wings Down)
// 0: trans, 1: outline, 2: red wings, 3: yellow body, 4: blue antennae, 5: cyan/white eyes
const galaga_goei_f0 = [
	[0,0,0,0,4,4,0,0,0,0,4,4,0,0,0,0],
	[0,0,0,0,0,4,4,0,0,4,4,0,0,0,0,0],
	[0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
	[0,0,1,1,2,2,3,3,3,3,2,2,1,1,0,0],
	[0,1,2,2,2,2,3,5,5,3,2,2,2,2,1,0],
	[1,2,2,2,2,2,3,3,3,3,2,2,2,2,2,1],
	[1,2,2,2,2,2,2,3,3,2,2,2,2,2,2,1],
	[1,2,2,2,2,1,1,3,3,1,1,2,2,2,2,1],
	[1,2,2,2,1,3,3,3,3,3,3,1,2,2,2,1],
	[0,1,2,1,3,3,3,3,3,3,3,3,1,2,1,0],
	[0,0,1,3,3,3,3,3,3,3,3,3,3,1,0,0],
	[0,1,2,1,3,3,3,3,3,3,3,3,1,2,1,0],
	[1,2,2,2,1,3,3,3,3,3,3,1,2,2,2,1],
	[1,2,2,2,2,1,1,1,1,1,1,2,2,2,2,1],
	[0,1,1,2,2,2,0,0,0,0,2,2,2,1,1,0],
	[0,0,0,1,1,1,0,0,0,0,1,1,1,0,0,0]
]

// Goei Red Butterfly Frame 1 (Wings Up)
const galaga_goei_f1 = [
	[0,1,2,2,4,4,0,0,0,0,4,4,2,2,1,0],
	[1,2,2,2,2,4,4,0,0,4,4,2,2,2,2,1],
	[1,2,2,2,1,1,1,1,1,1,1,1,2,2,2,1],
	[1,2,2,1,2,2,3,3,3,3,2,2,1,2,2,1],
	[0,1,1,2,2,2,3,5,5,3,2,2,2,1,1,0],
	[0,0,1,2,2,2,3,3,3,3,2,2,2,1,0,0],
	[0,0,1,2,2,2,2,3,3,2,2,2,2,1,0,0],
	[0,0,0,1,2,1,1,3,3,1,1,2,1,0,0,0],
	[0,0,1,2,1,3,3,3,3,3,3,1,2,1,0,0],
	[0,1,2,1,3,3,3,3,3,3,3,3,1,2,1,0],
	[1,2,2,1,3,3,3,3,3,3,3,3,1,2,2,1],
	[1,2,1,1,3,3,3,3,3,3,3,3,1,1,2,1],
	[1,2,1,0,1,3,3,3,3,3,3,1,0,1,2,1],
	[0,1,0,0,0,1,1,1,1,1,1,0,0,0,1,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
]

// Boss Galaga Frame 0
// 0: trans, 1: outline, 2: green/purple body, 3: white pincers, 4: yellow core, 5: red eyes
const galaga_boss_f0 = [
	[0,0,3,3,0,0,0,0,0,0,0,0,3,3,0,0],
	[0,3,3,3,3,0,0,1,1,0,0,3,3,3,3,0],
	[0,3,3,3,3,1,1,5,5,1,1,3,3,3,3,0],
	[0,0,3,3,1,2,2,5,5,2,2,1,3,3,0,0],
	[0,0,1,1,2,2,2,2,2,2,2,2,1,1,0,0],
	[0,1,2,2,2,4,4,4,4,4,4,2,2,2,1,0],
	[1,2,2,2,4,4,4,4,4,4,4,4,2,2,2,1],
	[1,2,2,4,4,4,5,5,5,5,4,4,4,2,2,1],
	[1,2,2,4,4,5,5,5,5,5,5,4,4,2,2,1],
	[1,2,2,4,4,4,5,5,5,5,4,4,4,2,2,1],
	[1,2,2,2,4,4,4,4,4,4,4,4,2,2,2,1],
	[0,1,2,2,2,4,4,4,4,4,4,2,2,2,1,0],
	[0,0,1,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[0,0,0,1,1,2,2,2,2,2,2,1,1,0,0,0],
	[0,0,1,3,3,1,1,1,1,1,1,3,3,1,0,0],
	[0,0,1,1,1,0,0,0,0,0,0,1,1,1,0,0]
]

// Boss Galaga Frame 1 (Wings Flapped)
const galaga_boss_f1 = [
	[0,3,3,0,0,0,0,1,1,0,0,0,0,3,3,0],
	[3,3,3,3,0,1,1,5,5,1,1,0,3,3,3,3],
	[3,3,3,3,1,2,2,5,5,2,2,1,3,3,3,3],
	[0,3,3,1,2,2,2,2,2,2,2,2,1,3,3,0],
	[1,1,1,2,2,4,4,4,4,4,4,2,2,1,1,1],
	[1,2,2,2,4,4,4,4,4,4,4,4,2,2,2,1],
	[1,2,2,4,4,4,5,5,5,5,4,4,4,2,2,1],
	[1,2,2,4,4,5,5,5,5,5,5,4,4,2,2,1],
	[1,2,2,4,4,4,5,5,5,5,4,4,4,2,2,1],
	[1,2,2,2,4,4,4,4,4,4,4,4,2,2,2,1],
	[0,1,2,2,2,4,4,4,4,4,4,2,2,2,1,0],
	[0,0,1,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[0,0,1,3,3,1,2,2,2,2,1,3,3,1,0,0],
	[0,3,3,3,3,1,1,1,1,1,1,3,3,3,3,0],
	[0,3,3,3,0,0,0,0,0,0,0,0,3,3,3,0],
	[0,0,1,1,0,0,0,0,0,0,0,0,1,1,0,0]
]

fn draw_player_ship(renderer &Renderer, texture &Texture, x f32, y f32, mini bool, color Color) {
	scale := if mini { 1 } else { 2 }
	px := int(x) - (16 * scale) / 2
	py := int(y) - (16 * scale) / 2

	if texture != unsafe { nil } {
		src_x := if color.r == 255 && color.g < 150 { 32 } else if color.g == 255 { 64 } else { 0 }
		src := Rect{ x: src_x, y: 0, w: 32, h: 32 }
		size := if mini { 16 } else { 32 }
		dst := Rect{ x: int(x) - size / 2, y: int(y) - size / 2, w: size, h: size }
		render_copy(renderer, texture, &src, &dst)

		if !mini {
			ticks := time.ticks()
			f_height := 4 + int(ticks % 6)
			set_render_draw_color(renderer, 255, 140, 30, 200)
			render_fill_rect(renderer, &Rect{ x: int(x) - 4, y: int(y) + 16, w: 8, h: f_height + 2 })
			set_render_draw_color(renderer, 0, 240, 255, 255)
			render_fill_rect(renderer, &Rect{ x: int(x) - 2, y: int(y) + 16, w: 4, h: f_height })
		}
		return
	}

	for r in 0 .. 16 {
		for c in 0 .. 16 {
			val := galaga_player_sprite[r][c]
			if val == 0 { continue }

			col := match val {
				1 { Color{ r: 20, g: 25, b: 45, a: color.a } }
				2 { color } // Fuselage tint
				3 { Color{ r: 235, g: 30, b: 45, a: color.a } }
				4 { Color{ r: 255, g: 215, b: 0, a: color.a } }
				5 { Color{ r: 0, g: 200, b: 255, a: color.a } }
				6 { Color{ r: 0, g: 255, b: 240, a: color.a } }
				else { color }
			}

			set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
			render_fill_rect(renderer, &Rect{ x: px + c * scale, y: py + r * scale, w: scale, h: scale })
		}
	}

	if !mini {
		ticks := time.ticks()
		f_height := 4 + int(ticks % 6)
		set_render_draw_color(renderer, 255, 140, 30, 200)
		render_fill_rect(renderer, &Rect{ x: int(x) - 4, y: int(y) + 16, w: 8, h: f_height + 2 })
		set_render_draw_color(renderer, 0, 240, 255, 255)
		render_fill_rect(renderer, &Rect{ x: int(x) - 2, y: int(y) + 16, w: 4, h: f_height })
	}
}

fn draw_enemy_ship(renderer &Renderer, texture &Texture, e Enemy) {
	scale := 2
	px := int(e.x) - (16 * scale) / 2
	py := int(e.y) - (16 * scale) / 2

	ticks := time.ticks()
	frame := if (ticks / 250) % 2 == 0 { 0 } else { 1 }

	if texture != unsafe { nil } {
		src_x, src_y := match e.enemy_type {
			.zako { frame * 32, 32 }
			.goei { (2 + frame) * 32, 32 }
			.boss { (if e.hp == 2 { 0 } else { 2 } + frame) * 32, 64 }
		}
		src := Rect{ x: src_x, y: src_y, w: 32, h: 32 }
		dst := Rect{ x: int(e.x) - 16, y: int(e.y) - 16, w: 32, h: 32 }
		render_copy(renderer, texture, &src, &dst)
		return
	}

	match e.enemy_type {
		.zako {
			matrix := if frame == 0 { galaga_zako_f0 } else { galaga_zako_f1 }
			for r in 0 .. 16 {
				for c in 0 .. 16 {
					val := matrix[r][c]
					if val == 0 { continue }
					col := match val {
						1 { Color{ r: 15, g: 20, b: 40, a: 255 } }
						2 { Color{ r: 35, g: 110, b: 245, a: 255 } }
						3 { Color{ r: 255, g: 215, b: 35, a: 255 } }
						4 { Color{ r: 255, g: 40, b: 50, a: 255 } }
						else { Color{ r: 35, g: 110, b: 245, a: 255 } }
					}
					set_render_draw_color(renderer, col.r, col.g, col.b, 255)
					render_fill_rect(renderer, &Rect{ x: px + c * scale, y: py + r * scale, w: scale, h: scale })
				}
			}
		}
		.goei {
			matrix := if frame == 0 { galaga_goei_f0 } else { galaga_goei_f1 }
			for r in 0 .. 16 {
				for c in 0 .. 16 {
					val := matrix[r][c]
					if val == 0 { continue }
					col := match val {
						1 { Color{ r: 35, g: 15, b: 20, a: 255 } }
						2 { Color{ r: 235, g: 35, b: 45, a: 255 } }
						3 { Color{ r: 255, g: 200, b: 30, a: 255 } }
						4 { Color{ r: 40, g: 160, b: 255, a: 255 } }
						5 { Color{ r: 255, g: 255, b: 255, a: 255 } }
						else { Color{ r: 235, g: 35, b: 45, a: 255 } }
					}
					set_render_draw_color(renderer, col.r, col.g, col.b, 255)
					render_fill_rect(renderer, &Rect{ x: px + c * scale, y: py + r * scale, w: scale, h: scale })
				}
			}
		}
		.boss {
			matrix := if frame == 0 { galaga_boss_f0 } else { galaga_boss_f1 }
			body_col := if e.hp == 2 { Color{ r: 35, g: 215, b: 70, a: 255 } } else { Color{ r: 185, g: 45, b: 215, a: 255 } }
			for r in 0 .. 16 {
				for c in 0 .. 16 {
					val := matrix[r][c]
					if val == 0 { continue }
					col := match val {
						1 { Color{ r: 25, g: 25, b: 35, a: 255 } }
						2 { body_col }
						3 { Color{ r: 245, g: 240, b: 220, a: 255 } }
						4 { Color{ r: 255, g: 215, b: 0, a: 255 } }
						5 { Color{ r: 255, g: 40, b: 50, a: 255 } }
						else { body_col }
					}
					set_render_draw_color(renderer, col.r, col.g, col.b, 255)
					render_fill_rect(renderer, &Rect{ x: px + c * scale, y: py + r * scale, w: scale, h: scale })
				}
			}
		}
	}
}
