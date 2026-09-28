module main

import math
import os
import rand

pub struct NuclearThroneTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn new_nuclear_throne_texture_manager() NuclearThroneTextureManager {
	return NuclearThroneTextureManager{}
}

pub fn (mut tm NuclearThroneTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/nuclearthrone.png',
		'./assets/sprites/nuclearthrone.png',
		'../assets/sprites/nuclearthrone.png',
		'nuclearthrone/assets/sprites/nuclearthrone.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('nuclearthrone Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

pub fn render_nuclear_throne_game(renderer &Renderer, game &NuclearThroneGame, tex &Texture) {
	// Deep post-apocalyptic wasteland terrain color
	set_render_draw_color(renderer, 24, 18, 14, 255)
	render_clear(renderer)

	// Apply screen shake offset
	mut shake_x := 0
	mut shake_y := 0
	if game.screen_shake > 0 {
		shake_x = int((rand.f64() - 0.5) * game.screen_shake * 30.0)
		shake_y = int((rand.f64() - 0.5) * game.screen_shake * 30.0)
	}

	cam_x := int(game.camera_x) - shake_x
	cam_y := int(game.camera_y) - shake_y
	screen_w := 800
	screen_h := 600

	// Render Wasteland Floor Grid
	min_c := math.max(0, cam_x / game.tile_size)
	max_c := math.min(game.cols - 1, (cam_x + screen_w) / game.tile_size + 1)
	min_r := math.max(0, cam_y / game.tile_size)
	max_r := math.min(game.rows - 1, (cam_y + screen_h) / game.tile_size + 1)

	for r in min_r .. max_r + 1 {
		for c in min_c .. max_c + 1 {
			px := c * game.tile_size - cam_x
			py := r * game.tile_size - cam_y
			wall := game.grid[r][c]

			if wall.solid {
				// Solid Wall tile with drop shadow
				set_render_draw_color(renderer, 10, 6, 4, 255)
				shadow := Rect{x: px + 3, y: py + 4, w: game.tile_size, h: game.tile_size}
				render_fill_rect(renderer, &shadow)

				set_render_draw_color(renderer, 100, 75, 55, 255)
				rect := Rect{x: px, y: py, w: game.tile_size, h: game.tile_size}
				render_fill_rect(renderer, &rect)

				set_render_draw_color(renderer, 140, 110, 80, 255)
				render_draw_line(renderer, px, py, px + game.tile_size, py)
				render_draw_line(renderer, px, py, px, py + game.tile_size)

				set_render_draw_color(renderer, 50, 35, 25, 255)
				render_draw_rect(renderer, &rect)
			} else {
				// Floor tile
				set_render_draw_color(renderer, 38, 28, 20, 255)
				rect := Rect{x: px, y: py, w: game.tile_size, h: game.tile_size}
				render_draw_rect(renderer, &rect)
			}
		}
	}

	// Render Pickups (Rads, Ammo, Chests) with Additive Glow
	for pk in game.pickups {
		if !pk.active {
			continue
		}
		px := int(pk.x) - cam_x
		py := int(pk.y) - cam_y

		match pk.kind {
			.rad {
				set_render_draw_blend_mode(renderer, .add)
				set_render_draw_color(renderer, 60, 255, 100, 80)
				glow := Rect{x: px - 8, y: py - 8, w: 16, h: 16}
				render_fill_rect(renderer, &glow)

				set_render_draw_blend_mode(renderer, .blend)
				set_render_draw_color(renderer, 80, 255, 120, 255)
				rect := Rect{x: px - 4, y: py - 4, w: 8, h: 8}
				render_fill_rect(renderer, &rect)
				set_render_draw_color(renderer, 255, 255, 255, 255)
				core := Rect{x: px - 2, y: py - 2, w: 4, h: 4}
				render_fill_rect(renderer, &core)
			}
			.ammo {
				set_render_draw_color(renderer, 255, 220, 40, 255)
				rect := Rect{x: px - 5, y: py - 5, w: 10, h: 10}
				render_fill_rect(renderer, &rect)
			}
			.health {
				set_render_draw_color(renderer, 255, 60, 80, 255)
				rect := Rect{x: px - 5, y: py - 5, w: 10, h: 10}
				render_fill_rect(renderer, &rect)
			}
			.weapon_chest {
				set_render_draw_color(renderer, 220, 150, 40, 255)
				rect := Rect{x: px - 12, y: py - 9, w: 24, h: 18}
				render_fill_rect(renderer, &rect)
				set_render_draw_color(renderer, 255, 255, 255, 255)
				draw_text(renderer, px - 10, py - 4, 'CHEST', 1, Color{r: 255, g: 255, b: 255})
			}
		}
	}

	// Render Enemies with Drop Shadows
	for e in game.enemies {
		if !e.active {
			continue
		}
		px := int(e.x) - cam_x
		py := int(e.y) - cam_y
		w := int(e.w)
		h := int(e.h)

		// Enemy Drop Shadow
		set_render_draw_color(renderer, 0, 0, 0, 140)
		shadow := Rect{x: px + 3, y: py + 4, w: w, h: h}
		render_fill_rect(renderer, &shadow)

		match e.kind {
			.maggot {
				set_render_draw_color(renderer, 190, 170, 110, 255)
			}
			.bandit {
				set_render_draw_color(renderer, 230, 100, 40, 255)
			}
			.scorpion {
				set_render_draw_color(renderer, 60, 200, 90, 255)
			}
			.assassin {
				set_render_draw_color(renderer, 220, 40, 80, 255)
			}
			.big_bandit {
				set_render_draw_color(renderer, 255, 40, 40, 255)
			}
		}
		rect := Rect{x: px, y: py, w: w, h: h}
		render_fill_rect(renderer, &rect)

		// Border outline
		set_render_draw_color(renderer, 20, 10, 10, 255)
		render_draw_rect(renderer, &rect)

		// Boss health bar above head
		if e.kind == .big_bandit {
			hp_w := int(f64(w) * (f64(e.hp) / f64(e.max_hp)))
			bar_bg := Rect{x: px, y: py - 14, w: w, h: 8}
			bar_fg := Rect{x: px, y: py - 14, w: hp_w, h: 8}
			set_render_draw_color(renderer, 60, 20, 20, 255)
			render_fill_rect(renderer, &bar_bg)
			set_render_draw_color(renderer, 255, 40, 40, 255)
			render_fill_rect(renderer, &bar_fg)
			set_render_draw_color(renderer, 255, 215, 0, 255)
			render_draw_rect(renderer, &bar_bg)
		}
	}

	// Render Bullets with Additive Glow Trails
	for b in game.bullets {
		px := int(b.x) - cam_x
		py := int(b.y) - cam_y

		// Bullet glow
		set_render_draw_blend_mode(renderer, .add)
		set_render_draw_color(renderer, b.color.r, b.color.g, b.color.b, 100)
		glow := Rect{x: px - int(b.w), y: py - int(b.h), w: int(b.w) * 2, h: int(b.h) * 2}
		render_fill_rect(renderer, &glow)

		// Core
		set_render_draw_blend_mode(renderer, .blend)
		set_render_draw_color(renderer, 255, 255, 255, 255)
		rect := Rect{x: px - int(b.w) / 2, y: py - int(b.h) / 2, w: int(b.w), h: int(b.h)}
		render_fill_rect(renderer, &rect)
	}

	// Render Particles
	set_render_draw_blend_mode(renderer, .add)
	for pt in game.particles {
		px := int(pt.x) - cam_x
		py := int(pt.y) - cam_y
		alpha := u8(255.0 * (pt.life / pt.max_life))
		set_render_draw_color(renderer, pt.color.r, pt.color.g, pt.color.b, alpha)
		rect := Rect{x: px - pt.size / 2, y: py - pt.size / 2, w: pt.size, h: pt.size}
		render_fill_rect(renderer, &rect)
	}
	set_render_draw_blend_mode(renderer, .blend)

	// Render Player & Crystal Shield / Roll trail
	p := game.player
	if p.invuln_timer == 0 || int(p.invuln_timer * 15.0) % 2 == 0 {
		px := int(p.x) - cam_x
		py := int(p.y) - cam_y

		// Crystal Shield aura
		if p.shield_timer > 0 {
			set_render_draw_blend_mode(renderer, .add)
			set_render_draw_color(renderer, 80, 240, 255, 180)
			aura := Rect{x: px - 8, y: py - 8, w: int(p.w) + 16, h: int(p.h) + 16}
			render_fill_rect(renderer, &aura)
			set_render_draw_blend_mode(renderer, .blend)
		}

		// Player Body
		if !isnil(tex) {
			src_rect := Rect{x: 0, y: 0, w: 32, h: 32}
			dest_rect := Rect{x: px, y: py, w: int(p.w), h: int(p.h)}
			render_copy(renderer, tex, &src_rect, &dest_rect)
		} else {
			match p.character {
				.fish { set_render_draw_color(renderer, 40, 210, 110, 255) }
				.crystal { set_render_draw_color(renderer, 80, 190, 255, 255) }
				.robot { set_render_draw_color(renderer, 190, 190, 210, 255) }
			}
			rect := Rect{x: px, y: py, w: int(p.w), h: int(p.h)}
			render_fill_rect(renderer, &rect)

			set_render_draw_color(renderer, 20, 20, 20, 255)
			render_draw_rect(renderer, &rect)
		}

		// Gun barrel aiming line & reticle
		gun_x := px + int(p.w) / 2
		gun_y := py + int(p.h) / 2
		barrel_x := gun_x + int(math.cos(p.aim_angle) * 18.0)
		barrel_y := gun_y + int(math.sin(p.aim_angle) * 18.0)
		set_render_draw_color(renderer, 255, 255, 255, 255)
		render_draw_line(renderer, gun_x, gun_y, barrel_x, barrel_y)
	}

	// Render Glassmorphism Modern HUD & Status
	render_modern_hud(renderer, game)

	// Render CRT Scanlines
	render_crt_overlay(renderer, screen_w, screen_h)

	// Render Mutation Screen Overlay
	if game.mutation_screen {
		render_mutation_screen(renderer, game)
	}

	// Render Game Over or Victory screens
	if game.game_over {
		render_overlay_box(renderer, 'WASTELAND DIED', 'PRESS RESTART OR [R]', Color{r: 255, g: 40, b: 40}, game.score, game.high_score)
	} else if game.victory {
		render_overlay_box(renderer, 'NUCLEAR THRONE REACHED!', 'VICTORY OF THE WASTELAND!', Color{r: 60, g: 255, b: 100}, game.score, game.high_score)
	}
}

fn render_modern_hud(renderer &Renderer, game &NuclearThroneGame) {
	p := game.player

	// Glassmorphism HUD Card
	set_render_draw_blend_mode(renderer, .blend)
	set_render_draw_color(renderer, 24, 18, 14, 210)
	hud_bg := Rect{x: 10, y: 10, w: 780, h: 80}
	render_fill_rect(renderer, &hud_bg)
	set_render_draw_color(renderer, 255, 140, 40, 150)
	render_draw_rect(renderer, &hud_bg)

	// Health Bar
	draw_text(renderer, 25, 25, 'HP:', 2, Color{r: 255, g: 60, b: 80})
	for i in 0 .. p.max_hp {
		color := if i < p.hp { Color{r: 255, g: 60, b: 80} } else { Color{r: 70, g: 30, b: 40} }
		rect := Rect{x: 70 + i * 16, y: 25, w: 12, h: 16}
		set_render_draw_color(renderer, color.r, color.g, color.b, 255)
		render_fill_rect(renderer, &rect)
	}

	// RADS (Radiation Experience) Bar
	draw_text(renderer, 25, 50, 'RADS:', 1, Color{r: 60, g: 255, b: 100})
	rad_pct := f64(p.rads) / f64(game.rads_to_next_level)
	bar_w := int(150.0 * rad_pct)
	bg_bar := Rect{x: 70, y: 50, w: 150, h: 10}
	fg_bar := Rect{x: 70, y: 50, w: bar_w, h: 10}
	set_render_draw_color(renderer, 30, 60, 30, 255)
	render_fill_rect(renderer, &bg_bar)
	set_render_draw_color(renderer, 60, 255, 100, 255)
	render_fill_rect(renderer, &fg_bar)

	// Level & Stage
	draw_text(renderer, 245, 25, 'LVL ${p.level}', 2, Color{r: 60, g: 255, b: 100})
	draw_text(renderer, 335, 25, 'AREA ${game.stage}-${game.substage}', 2, Color{r: 255, g: 220, b: 80})

	// Weapon & Ammo
	mut w_str := 'REVOLVER'
	match p.weapon {
		.shotgun { w_str = 'SHOTGUN' }
		.laser_rifle { w_str = 'LASER RIFLE' }
		.grenade_launcher { w_str = 'GRENADE LAUNCHER' }
		.machinegun { w_str = 'MACHINEGUN' }
		.crossbow { w_str = 'CROSSBOW' }
		else {}
	}
	draw_text(renderer, 245, 50, 'WEAPON: ${w_str} (${p.ammo}/${p.max_ammo})', 1, Color{r: 255, g: 255, b: 255})

	// Score & Kills
	draw_text(renderer, 630, 22, 'SCORE: ${game.score}', 1, Color{r: 255, g: 255, b: 255})
	draw_text(renderer, 630, 42, 'KILLS: ${p.kills}', 1, Color{r: 255, g: 140, b: 40})
	draw_text(renderer, 630, 62, 'HIGH: ${game.high_score}', 1, Color{r: 255, g: 215, b: 0})
}

fn render_crt_overlay(renderer &Renderer, w int, h int) {
	set_render_draw_blend_mode(renderer, .blend)
	set_render_draw_color(renderer, 0, 0, 0, 12)
	for y := 0; y < h; y += 4 {
		line := Rect{x: 0, y: y, w: w, h: 2}
		render_fill_rect(renderer, &line)
	}
}

fn render_mutation_screen(renderer &Renderer, game &NuclearThroneGame) {
	set_render_draw_blend_mode(renderer, .blend)
	set_render_draw_color(renderer, 14, 10, 8, 235)
	bg := Rect{x: 120, y: 100, w: 560, h: 400}
	render_fill_rect(renderer, &bg)

	set_render_draw_color(renderer, 60, 255, 100, 255)
	render_draw_rect(renderer, &bg)

	draw_text_centered(renderer, 400, 125, 'SELECT MUTATION!', 3, Color{r: 60, g: 255, b: 100})

	for i, m in game.available_mutations {
		iy := 185 + i * 55
		mut m_name := 'BLOODLUST (HEAL ON KILL)'
		match m {
			.rhino_skin { m_name = 'RHINO SKIN (+2 MAX HP)' }
			.scavenger { m_name = 'SCAVENGER (DOUBLE AMMO DROPS)' }
			.laser_brain { m_name = 'LASER BRAIN (DOUBLE LASER DMG)' }
			.extra_feet { m_name = 'EXTRA FEET (+25% MOVEMENT SPEED)' }
			else {}
		}

		// Mutation card container frame
		card := Rect{x: 140, y: iy - 5, w: 520, h: 45}
		set_render_draw_color(renderer, 28, 22, 18, 220)
		render_fill_rect(renderer, &card)
		set_render_draw_color(renderer, 60, 180, 80, 255)
		render_draw_rect(renderer, &card)

		draw_text(renderer, 155, iy + 8, '[${i + 1}] ${m_name}', 2, Color{r: 255, g: 255, b: 255})
	}

	draw_text_centered(renderer, 400, 460, 'PRESS [1-5] OR CLICK TO SELECT MUTATION', 1, Color{r: 180, g: 180, b: 180})
}

fn render_overlay_box(renderer &Renderer, title string, subtitle string, color Color, score int, high int) {
	set_render_draw_blend_mode(renderer, .blend)
	set_render_draw_color(renderer, 14, 10, 8, 235)
	box := Rect{x: 160, y: 180, w: 480, h: 240}
	render_fill_rect(renderer, &box)

	set_render_draw_color(renderer, color.r, color.g, color.b, 255)
	render_draw_rect(renderer, &box)

	draw_text_centered(renderer, 400, 210, title, 3, color)
	draw_text_centered(renderer, 400, 260, subtitle, 2, Color{r: 255, g: 255, b: 255})
	draw_text_centered(renderer, 400, 300, 'FINAL SCORE: ${score}', 2, Color{r: 255, g: 215, b: 0})
	draw_text_centered(renderer, 400, 330, 'HIGH SCORE: ${high}', 2, Color{r: 200, g: 200, b: 200})
}
