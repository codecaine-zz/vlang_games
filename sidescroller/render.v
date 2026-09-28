module main

import math
import os

pub struct SidescrollerTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm SidescrollerTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/sidescroller.png',
		'./assets/sprites/sidescroller.png',
		'../assets/sprites/sidescroller.png',
		'sidescroller/assets/sprites/sidescroller.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('sidescroller Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

fn draw_game(renderer &Renderer, ge &GameEngine, tex &Texture) {
	// Background Clear
	set_render_draw_color(renderer, 15, 23, 42, 255)
	render_clear(renderer)

	mut shake_x := 0
	mut shake_y := 0
	if ge.camera_shake > 0 {
		shake_x = int((math.sin(ge.elapsed_time * 50.0) * ge.camera_shake))
		shake_y = int((math.cos(ge.elapsed_time * 45.0) * ge.camera_shake))
	}

	// 1. Parallax Layer 1: Distant City Skyline
	draw_city_skyline(renderer, ge.camera_x * 0.1, shake_x, shake_y)

	// 2. Parallax Layer 2: Industrial Grids & Megastructures
	draw_industrial_grid(renderer, ge.camera_x * 0.3, shake_x, shake_y)

	// 3. Ground Platforms & Terrain
	draw_ground_platforms(renderer, ge.camera_x, shake_x, shake_y)

	// 4. Power-ups
	for pu in ge.powerups {
		draw_powerup(renderer, pu, ge.camera_x, shake_x, shake_y, tex)
	}

	// 5. Enemies & Bosses
	for enemy in ge.enemies {
		if enemy.active {
			draw_enemy(renderer, enemy, ge.camera_x, shake_x, shake_y, tex)
		}
	}

	// 6. Player
	if ge.state == .playing || ge.state == .stage_clear || ge.state == .paused {
		draw_player(renderer, ge.player, ge.camera_x, shake_x, shake_y, ge.elapsed_time, tex)
	}

	// 7. Projectiles
	for pr in ge.projectiles {
		draw_projectile(renderer, pr, ge.camera_x, shake_x, shake_y)
	}

	// 8. Particle System & Floating Text
	for pt in ge.particles {
		draw_particle(renderer, pt, ge.camera_x, shake_x, shake_y)
	}

	// 9. HUD Overlay
	if ge.state == .playing || ge.state == .paused || ge.state == .stage_clear {
		draw_hud(renderer, ge)
	}

	// 10. Screen Overlays (Title, Paused, Stage Clear, Game Over, Victory)
	match ge.state {
		.title { draw_title_screen(renderer, ge) }
		.paused { draw_paused_screen(renderer) }
		.stage_clear { draw_stage_clear_screen(renderer, ge) }
		.game_over { draw_game_over_screen(renderer, ge) }
		.victory { draw_victory_screen(renderer, ge) }
		else {}
	}
}

fn draw_city_skyline(renderer &Renderer, scroll_x f64, sx int, sy int) {
	set_render_draw_color(renderer, 30, 41, 59, 255)
	for i in 0 .. 15 {
		x := int(f64(i * 90) - math.mod(scroll_x, 90.0)) + sx
		h := 150 + (i * 37) % 180
		w := 75
		y := 480 - h + sy

		rect := Rect{
			x: x
			y: y
			w: w
			h: h
		}
		render_fill_rect(renderer, &rect)

		// Glowing windows
		set_render_draw_color(renderer, 51, 65, 85, 255)
		for wy := y + 20; wy < 460; wy += 25 {
			for wx := x + 10; wx < x + w - 10; wx += 20 {
				wrect := Rect{
					x: wx
					y: wy
					w: 8
					h: 12
				}
				render_fill_rect(renderer, &wrect)
			}
		}
		set_render_draw_color(renderer, 30, 41, 59, 255)
	}
}

fn draw_industrial_grid(renderer &Renderer, scroll_x f64, sx int, sy int) {
	set_render_draw_color(renderer, 71, 85, 105, 180)
	for i in 0 .. 12 {
		x := int(f64(i * 120) - math.mod(scroll_x, 120.0)) + sx
		rect := Rect{
			x: x
			y: 350 + sy
			w: 40
			h: 130
		}
		render_draw_rect(renderer, &rect)
		render_draw_line(renderer, x, 350 + sy, x + 40, 480 + sy)
		render_draw_line(renderer, x + 40, 350 + sy, x, 480 + sy)
	}
}

fn draw_ground_platforms(renderer &Renderer, camera_x f64, sx int, sy int) {
	// Main ground bar
	set_render_draw_color(renderer, 14, 116, 144, 255)
	ground_rect := Rect{
		x: 0
		y: 480 + sy
		w: 960
		h: 60
	}
	render_fill_rect(renderer, &ground_rect)

	// Cyber Neon top line
	set_render_draw_color(renderer, 34, 211, 238, 255)
	top_line := Rect{
		x: 0
		y: 478 + sy
		w: 960
		h: 4
	}
	render_fill_rect(renderer, &top_line)

	// Grid pattern
	set_render_draw_color(renderer, 8, 145, 178, 255)
	for x := 0; x < 960; x += 40 {
		grid_x := int(f64(x) - math.mod(camera_x, 40.0)) + sx
		render_draw_line(renderer, grid_x, 482 + sy, grid_x, 540 + sy)
	}
}

fn draw_player(renderer &Renderer, p Player, camera_x f64, sx int, sy int, t f64, tex &Texture) {
	screen_x := int(p.x - camera_x) + sx
	screen_y := int(p.y) + sy

	// Invincibility flicker
	if p.invincible_timer > 0 && int(p.invincible_timer * 20.0) % 2 == 0 {
		return
	}

	if tex != unsafe { nil } {
		mut pose := 0
		if p.dash_timer > 0 {
			pose = 5
		} else if !p.is_grounded {
			pose = 4
		} else if p.vx != 0.0 {
			pose = 1 + int(math.abs(p.vx * t * 10.0)) % 3
		}

		src := Rect{x: pose * 48, y: 0, w: 48, h: 64}
		dst := Rect{x: screen_x - 24, y: screen_y - 48, w: 48, h: 48}
		center := Point{x: 24, y: 24}
		flip := if !p.facing_right { RendererFlip.horizontal } else { RendererFlip.none }
		render_copy_ex(renderer, tex, &src, &dst, 0.0, &center, flip)

		if p.shield > 0 {
			set_render_draw_color(renderer, 34, 211, 238, 200)
			s_rect := Rect{
				x: screen_x - 24
				y: screen_y - 54
				w: 48
				h: 58
			}
			render_draw_rect(renderer, &s_rect)
		}
		return
	}

	// Dash Trail effect
	if p.dash_timer > 0 {
		set_render_draw_color(renderer, 6, 182, 212, 100)
		trail_rect := Rect{
			x: screen_x - 15
			y: screen_y - 48
			w: 30
			h: 48
		}
		render_fill_rect(renderer, &trail_rect)
	}

	// Overdrive Aura
	if p.overdrive_timer > 0 {
		set_render_draw_color(renderer, 250, 204, 21, 150)
		aura := Rect{
			x: screen_x - 22
			y: screen_y - 52
			w: 44
			h: 56
		}
		render_draw_rect(renderer, &aura)
	}

	// Shield Bubble
	if p.shield > 0 {
		set_render_draw_color(renderer, 34, 211, 238, 200)
		s_rect := Rect{
			x: screen_x - 24
			y: screen_y - 54
			w: 48
			h: 58
		}
		render_draw_rect(renderer, &s_rect)
	}

	// Cyber Mech Body
	set_render_draw_color(renderer, 30, 41, 59, 255) // Base dark armor
	body_rect := Rect{
		x: screen_x - 14
		y: screen_y - 42
		w: 28
		h: 36
	}
	render_fill_rect(renderer, &body_rect)

	// Armor Chest Plate
	set_render_draw_color(renderer, 14, 165, 233, 255)
	chest_rect := Rect{
		x: screen_x - 10
		y: screen_y - 38
		w: 20
		h: 18
	}
	render_fill_rect(renderer, &chest_rect)

	// Visor / Helmet Eye
	set_render_draw_color(renderer, 239, 68, 68, 255)
	mut eye_x := screen_x + 2
	if !p.facing_right {
		eye_x = screen_x - 10
	}
	visor := Rect{
		x: eye_x
		y: screen_y - 40
		w: 8
		h: 5
	}
	render_fill_rect(renderer, &visor)

	// Legs / Running animation
	set_render_draw_color(renderer, 51, 65, 85, 255)
	leg_offset := int(math.sin(t * 15.0) * 8.0)
	if !p.is_grounded {
		// Bent legs in air
		render_draw_line(renderer, screen_x - 6, screen_y - 6, screen_x - 12, screen_y)
		render_draw_line(renderer, screen_x + 6, screen_y - 6, screen_x + 12, screen_y)
	} else {
		render_draw_line(renderer, screen_x - 6, screen_y - 6, screen_x - 6 + leg_offset, screen_y)
		render_draw_line(renderer, screen_x + 6, screen_y - 6, screen_x + 6 - leg_offset, screen_y)
	}

	// Weapon Barrel
	set_render_draw_color(renderer, 203, 213, 225, 255)
	mut barrel_x := screen_x + 14
	if !p.facing_right {
		barrel_x = screen_x - 24
	}
	barrel := Rect{
		x: barrel_x
		y: screen_y - 28
		w: 10
		h: 6
	}
	render_fill_rect(renderer, &barrel)

	// Orbiting Combat Drone
	if p.drone_active {
		drone_screen_x := int(p.x + math.cos(p.drone_angle) * 45.0 - camera_x) + sx
		drone_screen_y := int(p.y - 20.0 + math.sin(p.drone_angle) * 20.0) + sy

		set_render_draw_color(renderer, 168, 85, 247, 255)
		d_rect := Rect{
			x: drone_screen_x - 6
			y: drone_screen_y - 6
			w: 12
			h: 12
		}
		render_fill_rect(renderer, &d_rect)
		set_render_draw_color(renderer, 234, 179, 8, 255)
		d_eye := Rect{
			x: drone_screen_x - 2
			y: drone_screen_y - 2
			w: 4
			h: 4
		}
		render_fill_rect(renderer, &d_eye)
	}
}

fn draw_projectile(renderer &Renderer, pr Projectile, camera_x f64, sx int, sy int) {
	px := int(pr.x - camera_x) + sx
	py := int(pr.y) + sy

	color := match pr.weapon_type {
		.pulse { Color{r: 34, g: 211, b: 238} }
		.spread { Color{r: 250, g: 204, b: 21} }
		.plasma { Color{r: 168, g: 85, b: 247} }
		.missile { Color{r: 249, g: 115, b: 22} }
		.flame { Color{r: 239, g: 68, b: 68} }
		.grenade { Color{r: 132, g: 204, b: 22} }
		.hyper_laser { Color{r: 236, g: 72, b: 153} }
		.tesla { Color{r: 59, g: 130, b: 246} }
	}

	set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	rad := int(pr.radius)

	if pr.weapon_type == .hyper_laser {
		// Draw laser beam line
		beam := Rect{
			x: px - 20
			y: py - 3
			w: 40
			h: 6
		}
		render_fill_rect(renderer, &beam)
	} else {
		rect := Rect{
			x: px - rad
			y: py - rad
			w: rad * 2
			h: rad * 2
		}
		render_fill_rect(renderer, &rect)
	}
}

fn draw_enemy(renderer &Renderer, enemy Enemy, camera_x f64, sx int, sy int, tex &Texture) {
	ex := int(enemy.x - camera_x) + sx
	ey := int(enemy.y) + sy
	rad := int(enemy.radius)

	if tex != unsafe { nil } {
		match enemy.etype {
			.scout {
				src := Rect{x: 0, y: 64, w: 48, h: 48}
				dst := Rect{x: ex - 24, y: ey - 24, w: 48, h: 48}
				render_copy(renderer, tex, &src, &dst)
			}
			.mech {
				src := Rect{x: 56, y: 64, w: 56, h: 56}
				dst := Rect{x: ex - 28, y: ey - 32, w: 56, h: 56}
				render_copy(renderer, tex, &src, &dst)
			}
			.turret {
				src := Rect{x: 144, y: 64, w: 48, h: 48}
				dst := Rect{x: ex - 24, y: ey - 24, w: 48, h: 48}
				render_copy(renderer, tex, &src, &dst)
			}
			.kamikaze {
				src := Rect{x: 192, y: 64, w: 48, h: 48}
				dst := Rect{x: ex - 24, y: ey - 24, w: 48, h: 48}
				render_copy(renderer, tex, &src, &dst)
			}
			.sniper {
				src := Rect{x: 0, y: 64, w: 48, h: 48}
				dst := Rect{x: ex - 24, y: ey - 24, w: 48, h: 48}
				render_copy(renderer, tex, &src, &dst)
			}
			.boss_behemoth, .boss_dreadnought, .boss_omega {
				src := Rect{x: 0, y: 128, w: 96, h: 96}
				dst := Rect{x: ex - 48, y: ey - 48, w: 96, h: 96}
				render_copy(renderer, tex, &src, &dst)

				// Boss HP bar above head
				hp_ratio := enemy.hp / enemy.max_hp
				set_render_draw_color(renderer, 51, 65, 85, 255)
				bg_bar := Rect{
					x: ex - rad
					y: ey - rad - 18
					w: rad * 2
					h: 8
				}
				render_fill_rect(renderer, &bg_bar)

				set_render_draw_color(renderer, 239, 68, 68, 255)
				fg_bar := Rect{
					x: ex - rad
					y: ey - rad - 18
					w: int(f64(rad * 2) * hp_ratio)
					h: 8
				}
				render_fill_rect(renderer, &fg_bar)
			}
		}
		return
	}

	match enemy.etype {
		.scout {
			set_render_draw_color(renderer, 244, 63, 94, 255)
			body := Rect{
				x: ex - rad
				y: ey - 8
				w: rad * 2
				h: 16
			}
			render_fill_rect(renderer, &body)
		}
		.mech {
			set_render_draw_color(renderer, 100, 116, 139, 255)
			body := Rect{
				x: ex - rad
				y: ey - rad
				w: rad * 2
				h: rad * 2
			}
			render_fill_rect(renderer, &body)
			// Cannon
			set_render_draw_color(renderer, 239, 68, 68, 255)
			cannon := Rect{
				x: ex - rad - 8
				y: ey - 5
				w: 12
				h: 8
			}
			render_fill_rect(renderer, &cannon)
		}
		.turret {
			set_render_draw_color(renderer, 148, 163, 184, 255)
			base := Rect{
				x: ex - rad
				y: ey - 10
				w: rad * 2
				h: 20
			}
			render_fill_rect(renderer, &base)
			set_render_draw_color(renderer, 239, 68, 68, 255)
			eye := Rect{
				x: ex - 4
				y: ey - 4
				w: 8
				h: 8
			}
			render_fill_rect(renderer, &eye)
		}
		.kamikaze {
			set_render_draw_color(renderer, 239, 68, 68, 255)
			body := Rect{
				x: ex - rad
				y: ey - rad
				w: rad * 2
				h: rad * 2
			}
			render_fill_rect(renderer, &body)
		}
		.sniper {
			set_render_draw_color(renderer, 217, 70, 239, 255)
			body := Rect{
				x: ex - rad
				y: ey - 10
				w: rad * 2
				h: 20
			}
			render_fill_rect(renderer, &body)
		}
		.boss_behemoth, .boss_dreadnought, .boss_omega {
			// Boss Heavy Rendering
			set_render_draw_color(renderer, 127, 29, 29, 255)
			body := Rect{
				x: ex - rad
				y: ey - rad
				w: rad * 2
				h: rad * 2
			}
			render_fill_rect(renderer, &body)
			set_render_draw_color(renderer, 239, 68, 68, 255)
			core := Rect{
				x: ex - 15
				y: ey - 15
				w: 30
				h: 30
			}
			render_fill_rect(renderer, &core)

			// Boss HP bar above head
			hp_ratio := enemy.hp / enemy.max_hp
			set_render_draw_color(renderer, 51, 65, 85, 255)
			bg_bar := Rect{
				x: ex - rad
				y: ey - rad - 18
				w: rad * 2
				h: 8
			}
			render_fill_rect(renderer, &bg_bar)

			set_render_draw_color(renderer, 239, 68, 68, 255)
			fg_bar := Rect{
				x: ex - rad
				y: ey - rad - 18
				w: int(f64(rad * 2) * hp_ratio)
				h: 8
			}
			render_fill_rect(renderer, &fg_bar)
		}
	}
}

fn draw_powerup(renderer &Renderer, pu PowerUp, camera_x f64, sx int, sy int, tex &Texture) {
	px := int(pu.x - camera_x) + sx
	py := int(pu.y) + sy

	if tex != unsafe { nil } {
		idx := match pu.ptype {
			.weapon_drop { 0 }
			.shield_core { 1 }
			.overdrive { 2 }
			.combat_drone { 3 }
			.repair_kit { 4 }
			.emp_bomb { 5 }
			.multiplier_orb { 6 }
		}
		src := Rect{x: idx * 40, y: 240, w: 40, h: 40}
		dst := Rect{x: px - 16, y: py - 16, w: 32, h: 32}
		render_copy(renderer, tex, &src, &dst)
		return
	}

	color := match pu.ptype {
		.weapon_drop { Color{r: 250, g: 204, b: 21} }
		.shield_core { Color{r: 34, g: 211, b: 238} }
		.overdrive { Color{r: 249, g: 115, b: 22} }
		.combat_drone { Color{r: 168, g: 85, b: 247} }
		.repair_kit { Color{r: 52, g: 211, b: 153} }
		.emp_bomb { Color{r: 239, g: 68, b: 68} }
		.multiplier_orb { Color{r: 236, g: 72, b: 153} }
	}

	set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	rect := Rect{
		x: px - 12
		y: py - 12
		w: 24
		h: 24
	}
	render_fill_rect(renderer, &rect)

	symbol := match pu.ptype {
		.weapon_drop { get_weapon_info(pu.wtype).symbol }
		.shield_core { 'SHD' }
		.overdrive { 'OVR' }
		.combat_drone { 'DRN' }
		.repair_kit { 'REP' }
		.emp_bomb { 'EMP' }
		.multiplier_orb { '2X' }
	}

	draw_text_centered(renderer, px, py - 4, symbol, 1, Color{
		r: 15
		g: 23
		b: 42
	})
}

fn draw_particle(renderer &Renderer, pt Particle, camera_x f64, sx int, sy int) {
	px := int(pt.x - camera_x) + sx
	py := int(pt.y) + sy

	if pt.is_text {
		draw_text(renderer, px, py, pt.text, 1, pt.color)
	} else {
		set_render_draw_color(renderer, pt.color.r, pt.color.g, pt.color.b, pt.color.a)
		s := int(pt.size)
		rect := Rect{
			x: px - (s / 2)
			y: py - (s / 2)
			w: s
			h: s
		}
		render_fill_rect(renderer, &rect)
	}
}

fn draw_hud(renderer &Renderer, ge &GameEngine) {
	// Top Header Bar
	set_render_draw_color(renderer, 15, 23, 42, 230)
	bar := Rect{
		x: 0
		y: 0
		w: 960
		h: 60
	}
	render_fill_rect(renderer, &bar)
	set_render_draw_color(renderer, 30, 41, 59, 255)
	render_draw_line(renderer, 0, 60, 960, 60)

	p := ge.player

	// Health Bar
	draw_text(renderer, 20, 12, 'HP', 1, Color{
		r: 52
		g: 211
		b: 153
	})
	set_render_draw_color(renderer, 51, 65, 85, 255)
	hp_bg := Rect{
		x: 45
		y: 12
		w: 150
		h: 12
	}
	render_fill_rect(renderer, &hp_bg)

	set_render_draw_color(renderer, 52, 211, 153, 255)
	hp_fg := Rect{
		x: 45
		y: 12
		w: int(150.0 * (p.hp / p.max_hp))
		h: 12
	}
	render_fill_rect(renderer, &hp_fg)

	// Shield Bar
	draw_text(renderer, 20, 30, 'SH', 1, Color{
		r: 34
		g: 211
		b: 238
	})
	set_render_draw_color(renderer, 51, 65, 85, 255)
	sh_bg := Rect{
		x: 45
		y: 30
		w: 150
		h: 10
	}
	render_fill_rect(renderer, &sh_bg)

	set_render_draw_color(renderer, 34, 211, 238, 255)
	sh_fg := Rect{
		x: 45
		y: 30
		w: int(150.0 * (p.shield / p.max_shield))
		h: 10
	}
	render_fill_rect(renderer, &sh_fg)

	// Energy Jetpack Gauge
	draw_text(renderer, 210, 12, 'NRG', 1, Color{
		r: 250
		g: 204
		b: 21
	})
	set_render_draw_color(renderer, 51, 65, 85, 255)
	nrg_bg := Rect{
		x: 245
		y: 12
		w: 100
		h: 12
	}
	render_fill_rect(renderer, &nrg_bg)

	set_render_draw_color(renderer, 250, 204, 21, 255)
	nrg_fg := Rect{
		x: 245
		y: 12
		w: int(100.0 * (p.energy / p.max_energy))
		h: 12
	}
	render_fill_rect(renderer, &nrg_fg)

	// Active Weapon & Ammo
	info := get_weapon_info(p.active_weapon)
	ammo_val := p.ammo[info.symbol] or { 0 }
	mut ammo_str := '${ammo_val}'
	if info.ammo_cost == 0 {
		ammo_str = 'INF'
	}

	draw_text(renderer, 370, 12, 'WEAPON: ${info.name}', 1, Color{
		r: 248
		g: 250
		b: 252
	})
	draw_text(renderer, 370, 30, 'AMMO: ${ammo_str}  [Q/E or 1-8]', 1, Color{
		r: 148
		g: 163
		b: 184
	})

	// Score & Multiplier & Stage
	draw_text(renderer, 680, 12, 'SCORE: ${ge.score}', 1, Color{
		r: 250
		g: 204
		b: 21
	})
	draw_text(renderer, 680, 30, 'STAGE: ${ge.stage}/3  BOMBS: ${p.bombs}', 1, Color{
		r: 168
		g: 85
		b: 247
	})

	// Stage Progress Bar
	draw_text(renderer, 210, 30, 'PROG', 1, Color{
		r: 148
		g: 163
		b: 184
	})
	set_render_draw_color(renderer, 51, 65, 85, 255)
	prog_bg := Rect{
		x: 245
		y: 30
		w: 100
		h: 10
	}
	render_fill_rect(renderer, &prog_bg)

	set_render_draw_color(renderer, 168, 85, 247, 255)
	prog_ratio := math.min(1.0, ge.stage_distance / ge.max_stage_distance)
	prog_fg := Rect{
		x: 245
		y: 30
		w: int(100.0 * prog_ratio)
		h: 10
	}
	render_fill_rect(renderer, &prog_fg)

	// Boss Warning Alert
	if ge.boss_warning_timer > 0 && int(ge.boss_warning_timer * 10.0) % 2 == 0 {
		draw_text_centered(renderer, 480, 80, 'WARNING: STAGE BOSS APPROACHING!', 2, Color{
			r: 239
			g: 68
			b: 68
		})
	}
}

fn draw_title_screen(renderer &Renderer, ge &GameEngine) {
	set_render_draw_color(renderer, 15, 23, 42, 235)
	overlay := Rect{
		x: 0
		y: 0
		w: 960
		h: 540
	}
	render_fill_rect(renderer, &overlay)

	draw_text_centered(renderer, 480, 100, 'CYBERPUNK VANGUARD', 4, Color{
		r: 34
		g: 211
		b: 238
	})
	draw_text_centered(renderer, 480, 150, 'ADVANCED 2D ACTION SIDE-SCROLLER', 2, Color{
		r: 250
		g: 204
		b: 21
	})

	draw_text_centered(renderer, 480, 220, '--- CONTROLS ---', 2, Color{
		r: 168
		g: 85
		b: 247
	})
	draw_text_centered(renderer, 480, 250, 'A / D / Left / Right : Move & Aim', 1, Color{
		r: 226
		g: 232
		b: 240
	})
	draw_text_centered(renderer, 480, 270, 'W / Up / Space : Double Jump / Jetpack Boost', 1, Color{
		r: 226
		g: 232
		b: 240
	})
	draw_text_centered(renderer, 480, 290, 'J / Z / Left Click : Fire Active Weapon', 1, Color{
		r: 226
		g: 232
		b: 240
	})
	draw_text_centered(renderer, 480, 310, 'K / Shift : Cyber Dash / Dodge Roll', 1, Color{
		r: 226
		g: 232
		b: 240
	})
	draw_text_centered(renderer, 480, 330, 'Space / B : Trigger EMP Bomb Blast Wave', 1, Color{
		r: 226
		g: 232
		b: 240
	})
	draw_text_centered(renderer, 480, 350, 'Q / E  or  1 - 8 : Switch Weapons (8 Weapons Suite!)', 1, Color{
		r: 226
		g: 232
		b: 240
	})
	draw_text_centered(renderer, 480, 370, 'P: Pause  |  R: Reset  |  S: Mute Sound', 1, Color{
		r: 226
		g: 232
		b: 240
	})

	if int(ge.elapsed_time * 4.0) % 2 == 0 {
		draw_text_centered(renderer, 480, 440, 'PRESS [SPACE] OR [ENTER] TO ENGAGE MISSION', 2, Color{
			r: 52
			g: 211
			b: 153
		})
	}
}

fn draw_paused_screen(renderer &Renderer) {
	set_render_draw_color(renderer, 15, 23, 42, 180)
	overlay := Rect{
		x: 0
		y: 0
		w: 960
		h: 540
	}
	render_fill_rect(renderer, &overlay)
	draw_text_centered(renderer, 480, 240, 'GAME PAUSED', 3, Color{
		r: 250
		g: 204
		b: 21
	})
	draw_text_centered(renderer, 480, 290, 'Press [P] to Resume', 1, Color{
		r: 226
		g: 232
		b: 240
	})
}

fn draw_stage_clear_screen(renderer &Renderer, ge &GameEngine) {
	set_render_draw_color(renderer, 15, 23, 42, 200)
	overlay := Rect{
		x: 0
		y: 0
		w: 960
		h: 540
	}
	render_fill_rect(renderer, &overlay)

	draw_text_centered(renderer, 480, 200, 'STAGE CLEAR!', 4, Color{
		r: 52
		g: 211
		b: 153
	})
	draw_text_centered(renderer, 480, 270, 'PROCEEDING TO STAGE ${ge.stage}...', 2, Color{
		r: 34
		g: 211
		b: 238
	})
	draw_text_centered(renderer, 480, 340, 'Press [Space] to Continue', 1, Color{
		r: 226
		g: 232
		b: 240
	})
}

fn draw_game_over_screen(renderer &Renderer, ge &GameEngine) {
	set_render_draw_color(renderer, 15, 23, 42, 220)
	overlay := Rect{
		x: 0
		y: 0
		w: 960
		h: 540
	}
	render_fill_rect(renderer, &overlay)

	draw_text_centered(renderer, 480, 180, 'MISSION FAILED', 4, Color{
		r: 239
		g: 68
		b: 68
	})
	draw_text_centered(renderer, 480, 250, 'FINAL SCORE: ${ge.score}', 2, Color{
		r: 250
		g: 204
		b: 21
	})
	draw_text_centered(renderer, 480, 280, 'HIGH SCORE: ${ge.high_score}', 1, Color{
		r: 148
		g: 163
		b: 184
	})

	draw_text_centered(renderer, 480, 360, 'Press [R] or [Space] to Retry', 2, Color{
		r: 226
		g: 232
		b: 240
	})
}

fn draw_victory_screen(renderer &Renderer, ge &GameEngine) {
	set_render_draw_color(renderer, 15, 23, 42, 230)
	overlay := Rect{
		x: 0
		y: 0
		w: 960
		h: 540
	}
	render_fill_rect(renderer, &overlay)

	draw_text_centered(renderer, 480, 160, 'VICTORY ACHIEVED!', 4, Color{
		r: 250
		g: 204
		b: 21
	})
	draw_text_centered(renderer, 480, 220, 'CYBER CITY LIBERATED FROM OMEGA THREAT', 2, Color{
		r: 34
		g: 211
		b: 238
	})

	draw_text_centered(renderer, 480, 290, 'TOTAL SCORE: ${ge.score}', 2, Color{
		r: 52
		g: 211
		b: 153
	})
	draw_text_centered(renderer, 480, 380, 'Press [R] or [Space] to Replay', 2, Color{
		r: 226
		g: 232
		b: 240
	})
}
