module main

import time

import math
import rand

pub struct SparkParticle {
pub mut:
	x        f64
	y        f64
	vx       f64
	vy       f64
	life     f64
	max_life f64
	color    Color
	size     f64
}

pub fn create_explosion_fx(cx f64, cy f64, count int) []SparkParticle {
	mut parts := []SparkParticle{cap: count}
	for _ in 0 .. count {
		angle := (f64(rand.intn(360) or { 0 }) * math.pi) / 180.0
		speed := 40.0 + f64(rand.intn(160) or { 80 })
		life := 0.35 + f64(rand.intn(35) or { 15 }) / 100.0
		cols := [
			Color{r: 255, g: 220, b: 50},
			Color{r: 255, g: 120, b: 30},
			Color{r: 240, g: 40, b: 40},
			Color{r: 200, g: 200, b: 220},
		]
		c := cols[rand.intn(cols.len) or { 0 }]
		parts << SparkParticle{
			x:        cx
			y:        cy
			vx:       math.cos(angle) * speed
			vy:       math.sin(angle) * speed
			life:     life
			max_life: life
			color:    c
			size:     2.0 + f64(rand.intn(4) or { 2 })
		}
	}
	return parts
}

pub fn update_sparks(mut sparks []SparkParticle, dt f64) {
	for mut p in sparks {
		p.x += p.vx * dt
		p.y += p.vy * dt + 60.0 * dt
		p.life -= dt
	}
	mut alive := []SparkParticle{cap: sparks.len}
	for p in sparks {
		if p.life > 0 { alive << p }
	}
	sparks = alive.clone()
}

pub fn render_sparks(renderer &Renderer, sparks []SparkParticle, cam_x f64, cam_y f64) {
	for p in sparks {
		sx := int(p.x - cam_x)
		sy := int(p.y - cam_y)
		alpha := u8(math.clamp(p.life / p.max_life * 255.0, 0.0, 255.0))
		set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, alpha)
		sz := int(p.size)
		render_fill_rect(renderer, &Rect{x: sx - sz / 2, y: sy - sz / 2, w: sz, h: sz})
	}
}

pub fn draw_duke_player(renderer &Renderer, p &DukePlayer, cx f64, cy f64, tex &Texture) {
	ix := int(cx)
	iy := int(cy)
	d := p.dir
	ticks := time.ticks()

	if tex != unsafe { nil } {
		mut src_x := 0
		mut src_y := 0
		mut src_w := 32
		mut src_h := 40
		mut dst_y := iy - 10

		if !p.on_ground && !p.is_climbing && !p.is_hanging {
			// Somersault tumbling in air
			anim := (int(ticks / 90)) % 2
			src_x = if anim == 0 { 144 } else { 192 }
			src_y = 0
			src_w = 32
			src_h = 32
			dst_y = iy - 2
		} else if p.is_climbing {
			anim := (int(ticks / 140)) % 2
			src_x = if anim == 0 { 336 } else { 384 }
			src_y = 0
		} else if p.is_hanging {
			anim := (int(ticks / 140)) % 2
			src_x = if anim == 0 { 432 } else { 480 }
			src_y = 0
		} else if p.is_crouching {
			src_x = 240
			src_y = 0
			src_w = 32
			src_h = 32
			dst_y = iy - 2
		} else if p.is_aiming_up {
			src_x = 288
			src_y = 0
		} else if p.vx != 0.0 {
			anim := (int(ticks / 120)) % 2
			src_x = if anim == 0 { 48 } else { 96 }
			src_y = 0
		} else {
			src_x = 0
			src_y = 0
		}

		src := Rect{x: src_x, y: src_y, w: src_w, h: src_h}
		dst := Rect{x: ix - 6, y: dst_y, w: src_w, h: src_h}
		flip := if d < 0 { RendererFlip.horizontal } else { RendererFlip.none }
		render_copy_ex(renderer, tex, &src, &dst, 0.0, unsafe { nil }, flip)
		return
	}

	// Procedural Fallback
	if !p.on_ground && !p.is_climbing && !p.is_hanging {
		set_render_draw_color(renderer, 220, 40, 40, 255)
		render_fill_rect(renderer, &Rect{x: ix, y: iy + 4, w: 20, h: 20})
		set_render_draw_color(renderer, 40, 80, 180, 255)
		render_fill_rect(renderer, &Rect{x: ix + 3, y: iy + 14, w: 14, h: 12})
		set_render_draw_color(renderer, 245, 215, 60, 255)
		render_fill_rect(renderer, &Rect{x: ix + 4, y: iy, w: 12, h: 6})
		return
	}

	set_render_draw_color(renderer, 250, 220, 60, 255)
	render_fill_rect(renderer, &Rect{x: ix + 2, y: iy, w: 16, h: 6})
	set_render_draw_color(renderer, 245, 185, 140, 255)
	render_fill_rect(renderer, &Rect{x: ix + 3, y: iy + 6, w: 14, h: 7})
	set_render_draw_color(renderer, 15, 15, 20, 255)
	if d > 0 {
		render_fill_rect(renderer, &Rect{x: ix + 8, y: iy + 7, w: 8, h: 3})
		set_render_draw_color(renderer, 180, 240, 255, 255)
		render_fill_rect(renderer, &Rect{x: ix + 10, y: iy + 7, w: 2, h: 2})
	} else {
		render_fill_rect(renderer, &Rect{x: ix + 4, y: iy + 7, w: 8, h: 3})
		set_render_draw_color(renderer, 180, 240, 255, 255)
		render_fill_rect(renderer, &Rect{x: ix + 6, y: iy + 7, w: 2, h: 2})
	}

	body_h := if p.is_crouching { 8 } else { 12 }
	set_render_draw_color(renderer, 220, 35, 40, 255)
	render_fill_rect(renderer, &Rect{x: ix + 2, y: iy + 13, w: 16, h: body_h})
	set_render_draw_color(renderer, 245, 185, 140, 255)
	render_fill_rect(renderer, &Rect{x: ix, y: iy + 14, w: 3, h: 8})
	render_fill_rect(renderer, &Rect{x: ix + 17, y: iy + 14, w: 3, h: 8})

	if !p.is_crouching {
		leg_swing := if p.vx != 0 { int(math.sin(p.walk_anim_t) * 3.0) } else { 0 }
		set_render_draw_color(renderer, 35, 80, 190, 255)
		render_fill_rect(renderer, &Rect{x: ix + 3 + leg_swing, y: iy + 25, w: 6, h: 7})
		render_fill_rect(renderer, &Rect{x: ix + 11 - leg_swing, y: iy + 25, w: 6, h: 7})
		set_render_draw_color(renderer, 100, 60, 25, 255)
		render_fill_rect(renderer, &Rect{x: ix + 2 + leg_swing, y: iy + 29, w: 7, h: 4})
		render_fill_rect(renderer, &Rect{x: ix + 11 - leg_swing, y: iy + 29, w: 7, h: 4})
	}

	set_render_draw_color(renderer, 180, 185, 195, 255)
	if p.is_aiming_up {
		render_fill_rect(renderer, &Rect{x: ix + 8, y: iy - 8, w: 4, h: 14})
		set_render_draw_color(renderer, 255, 60, 60, 255)
		render_fill_rect(renderer, &Rect{x: ix + 8, y: iy - 9, w: 4, h: 2})
	} else {
		gun_x := if d > 0 { ix + 14 } else { ix - 8 }
		gun_y := iy + if p.is_crouching { 16 } else { 14 }
		render_fill_rect(renderer, &Rect{x: gun_x, y: gun_y, w: 12, h: 5})
		set_render_draw_color(renderer, 255, 60, 60, 255)
		muzzle_x := if d > 0 { gun_x + 10 } else { gun_x }
		render_fill_rect(renderer, &Rect{x: muzzle_x, y: gun_y + 1, w: 2, h: 3})
	}
}

pub fn draw_tile(renderer &Renderer, tx int, ty int, tile int, sx int, sy int, level int, tex &Texture) {
	rect := Rect{x: sx, y: sy, w: int(tile_sz), h: int(tile_sz)}

	if tex != unsafe { nil } {
		mut src_x := 0
		mut src_y := 64
		match tile {
			1 {
				src_x = match level {
					2 { 40 }
					3 { 80 }
					else { 0 }
				}
			}
			3 { src_x = 120 }
			4 { src_x = 160 }
			5 { src_x = 200 }
			6 { src_x = 240 }
			7 { src_x = 280 }
			8 { src_x = 320 }
			9 { src_x = 360 }
			else { return }
		}
		src := Rect{x: src_x, y: src_y, w: 32, h: 32}
		render_copy(renderer, tex, &src, &rect)
		return
	}

	match tile {
		1 {
			match level {
				2 {
					set_render_draw_color(renderer, 90, 55, 40, 255)
					render_fill_rect(renderer, &rect)
					set_render_draw_color(renderer, 140, 90, 65, 255)
					render_draw_line(renderer, sx, sy, sx + int(tile_sz), sy)
					render_draw_line(renderer, sx, sy, sx, sy + int(tile_sz))
					set_render_draw_color(renderer, 50, 30, 20, 255)
					render_draw_line(renderer, sx, sy + int(tile_sz) - 1, sx + int(tile_sz), sy + int(tile_sz) - 1)
				}
				3 {
					set_render_draw_color(renderer, 45, 30, 70, 255)
					render_fill_rect(renderer, &rect)
					set_render_draw_color(renderer, 70, 180, 240, 255)
					render_draw_line(renderer, sx, sy, sx + int(tile_sz), sy)
					set_render_draw_color(renderer, 25, 15, 45, 255)
					render_draw_line(renderer, sx, sy + int(tile_sz) - 1, sx + int(tile_sz), sy + int(tile_sz) - 1)
				}
				else {
					set_render_draw_color(renderer, 70, 75, 90, 255)
					render_fill_rect(renderer, &rect)
					set_render_draw_color(renderer, 110, 120, 140, 255)
					render_draw_line(renderer, sx, sy, sx + int(tile_sz), sy)
					render_draw_line(renderer, sx, sy, sx, sy + int(tile_sz))
					set_render_draw_color(renderer, 40, 45, 55, 255)
					render_draw_line(renderer, sx, sy + int(tile_sz) - 1, sx + int(tile_sz), sy + int(tile_sz) - 1)
				}
			}
			set_render_draw_color(renderer, 180, 190, 210, 255)
			render_fill_rect(renderer, &Rect{x: sx + 3, y: sy + 3, w: 2, h: 2})
			render_fill_rect(renderer, &Rect{x: sx + 27, y: sy + 3, w: 2, h: 2})
			render_fill_rect(renderer, &Rect{x: sx + 3, y: sy + 27, w: 2, h: 2})
			render_fill_rect(renderer, &Rect{x: sx + 27, y: sy + 27, w: 2, h: 2})
		}
		3 {
			set_render_draw_color(renderer, 220, 170, 40, 255)
			render_draw_line(renderer, sx + 6, sy, sx + 6, sy + int(tile_sz))
			render_draw_line(renderer, sx + 26, sy, sx + 26, sy + int(tile_sz))
			render_draw_line(renderer, sx + 6, sy + 8, sx + 26, sy + 8)
			render_draw_line(renderer, sx + 6, sy + 16, sx + 26, sy + 16)
			render_draw_line(renderer, sx + 6, sy + 24, sx + 26, sy + 24)
		}
		4 {
			set_render_draw_color(renderer, 140, 150, 165, 255)
			render_fill_rect(renderer, &Rect{x: sx, y: sy + 6, w: int(tile_sz), h: 10})
			set_render_draw_color(renderer, 210, 220, 235, 255)
			render_draw_line(renderer, sx, sy + 7, sx + int(tile_sz), sy + 7)
		}
		5 {
			set_render_draw_color(renderer, 210, 40, 40, 255)
			render_fill_rect(renderer, &rect)
			draw_text_centered(renderer, sx + 16, sy + 10, 'KEY', 1, Color{r: 255, g: 255, b: 255})
		}
		6 {
			set_render_draw_color(renderer, 40, 90, 220, 255)
			render_fill_rect(renderer, &rect)
			draw_text_centered(renderer, sx + 16, sy + 10, 'KEY', 1, Color{r: 255, g: 255, b: 255})
		}
		7 {
			set_render_draw_color(renderer, 40, 190, 70, 255)
			render_fill_rect(renderer, &rect)
			draw_text_centered(renderer, sx + 16, sy + 10, 'KEY', 1, Color{r: 255, g: 255, b: 255})
		}
		8 {
			set_render_draw_color(renderer, 50, 240, 60, 255)
			render_fill_rect(renderer, &rect)
			set_render_draw_color(renderer, 180, 255, 120, 255)
			for i in 0 .. 4 {
				render_fill_rect(renderer, &Rect{x: sx + i * 8 + 2, y: sy + 4, w: 4, h: 3})
			}
		}
		9 {
			set_render_draw_color(renderer, 40, 180, 240, 255)
			render_fill_rect(renderer, &rect)
			draw_text_centered(renderer, sx + 16, sy + 10, 'EXIT', 1, Color{r: 255, g: 255, b: 255})
		}
		else {}
	}
}

pub fn draw_boss_mech(renderer &Renderer, boss &BossMech, cam_x f64, cam_y f64, tex &Texture) {
	if !boss.active { return }
	bx := int(boss.x - cam_x)
	by := int(boss.y - cam_y)

	if tex != unsafe { nil } {
		src := Rect{x: 0, y: 336, w: 80, h: 80}
		dst := Rect{x: bx - 8, y: by - 5, w: 80, h: 80}
		flip := if boss.dir > 0 { RendererFlip.horizontal } else { RendererFlip.none }
		render_copy_ex(renderer, tex, &src, &dst, 0.0, unsafe { nil }, flip)
	} else {
		set_render_draw_color(renderer, 120, 30, 160, 255)
		render_fill_rect(renderer, &Rect{x: bx, y: by, w: int(boss.w), h: int(boss.h)})
		set_render_draw_color(renderer, 180, 70, 220, 255)
		render_draw_rect(renderer, &Rect{x: bx, y: by, w: int(boss.w), h: int(boss.h)})
		set_render_draw_color(renderer, 255, 30, 40, 255)
		render_fill_rect(renderer, &Rect{x: bx + 15, y: by + 12, w: 40, h: 10})
		set_render_draw_color(renderer, 255, 200, 200, 255)
		render_fill_rect(renderer, &Rect{x: bx + 30, y: by + 14, w: 10, h: 6})
		set_render_draw_color(renderer, 200, 200, 220, 255)
		render_fill_rect(renderer, &Rect{x: bx - 14, y: by + 20, w: 18, h: 8})
		render_fill_rect(renderer, &Rect{x: bx - 14, y: by + 40, w: 18, h: 8})
	}

	// Boss Health Bar
	bar_w := 80
	bar_h := 8
	bar_x := bx - 5
	bar_y := by - 16
	set_render_draw_color(renderer, 20, 20, 30, 255)
	render_fill_rect(renderer, &Rect{x: bar_x, y: bar_y, w: bar_w, h: bar_h})

	hp_w := int(f64(boss.hp) / f64(boss.max_hp) * f64(bar_w - 2))
	set_render_draw_color(renderer, 240, 40, 40, 255)
	render_fill_rect(renderer, &Rect{x: bar_x + 1, y: bar_y + 1, w: hp_w, h: bar_h - 2})
	set_render_draw_color(renderer, 255, 255, 255, 255)
	draw_text_centered(renderer, bx + int(boss.w) / 2, bar_y - 12, 'MEGA MECH GOLIATH', 1, Color{r: 255, g: 60, b: 60})
}

pub fn render_duke_game(renderer &Renderer, game &DukeGame, screen_w int, screen_h int, sparks []SparkParticle) {
	ticks := time.ticks()
	tex := game.sprite_texture

	// Sector Background Colors
	match game.level_num {
		2 { set_render_draw_color(renderer, 24, 14, 12, 255) }
		3 { set_render_draw_color(renderer, 18, 12, 32, 255) }
		else { set_render_draw_color(renderer, 15, 18, 28, 255) }
	}
	render_clear(renderer)

	// Camera Scroll Offset
	mut cam_x := game.player.x - f64(screen_w) / 2.0
	mut cam_y := game.player.y - f64(screen_h) / 2.0
	cam_x = math.clamp(cam_x, 0.0, world_w - f64(screen_w))
	cam_y = math.clamp(cam_y, 0.0, world_h - f64(screen_h))

	// Parallax Backdrop
	if game.level_num == 1 {
		set_render_draw_color(renderer, 25, 30, 48, 255)
		for i in 0 .. 15 {
			bx := int(f64(i * 140) - cam_x * 0.25)
			render_fill_rect(renderer, &Rect{x: bx, y: 180, w: 90, h: 400})
			set_render_draw_color(renderer, 220, 200, 70, 180)
			for wy := 200; wy < 400; wy += 30 {
				render_fill_rect(renderer, &Rect{x: bx + 15, y: wy, w: 10, h: 12})
				render_fill_rect(renderer, &Rect{x: bx + 55, y: wy, w: 10, h: 12})
			}
			set_render_draw_color(renderer, 25, 30, 48, 255)
		}
	} else if game.level_num == 2 {
		set_render_draw_color(renderer, 45, 25, 20, 255)
		for i in 0 .. 12 {
			bx := int(f64(i * 160) - cam_x * 0.2)
			render_fill_rect(renderer, &Rect{x: bx, y: 100, w: 30, h: 500})
		}
	} else {
		set_render_draw_color(renderer, 220, 230, 255, 200)
		for i in 0 .. 50 {
			sx := (i * 137) % screen_w
			sy := (i * 97) % screen_h
			render_fill_rect(renderer, &Rect{x: sx, y: sy, w: 2, h: 2})
		}
	}

	// Draw Visible Map Tiles
	start_col := int(cam_x / tile_sz)
	end_col := int((cam_x + f64(screen_w)) / tile_sz) + 1
	start_row := int(cam_y / tile_sz)
	end_row := int((cam_y + f64(screen_h)) / tile_sz) + 1

	for r in start_row .. end_row {
		for c in start_col .. end_col {
			tile := game.get_tile(c, r)
			if tile > 0 {
				sx := int(f64(c) * tile_sz - cam_x)
				sy := int(f64(r) * tile_sz - cam_y)
				draw_tile(renderer, c, r, tile, sx, sy, game.level_num, tex)
			}
		}
	}

	// Draw Elevators
	for elev in game.elevators {
		ex := int(elev.x - cam_x)
		ey := int(elev.y - cam_y)
		if tex != unsafe { nil } {
			src := Rect{x: 400, y: 72, w: 48, h: 16}
			dst := Rect{x: ex, y: ey, w: int(elev.w), h: int(elev.h)}
			render_copy(renderer, tex, &src, &dst)
		} else {
			set_render_draw_color(renderer, 240, 190, 30, 255)
			render_fill_rect(renderer, &Rect{x: ex, y: ey, w: int(elev.w), h: int(elev.h)})
			set_render_draw_color(renderer, 20, 20, 20, 255)
			for dx := 0; dx < int(elev.w); dx += 12 {
				render_draw_line(renderer, ex + dx, ey, ex + dx + 6, ey + int(elev.h))
			}
		}
	}

	// Draw Destructibles (Cameras, Crates, Barrels)
	for d in game.destructs {
		if d.active {
			dx := int(d.x - cam_x)
			dy := int(d.y - cam_y)

			if tex != unsafe { nil } {
				src_x := if d.is_camera { 0 } else if d.is_barrel { 40 } else { 80 }
				src := Rect{x: src_x, y: 128, w: 32, h: 32}
				dst := Rect{x: dx - 2, y: dy - 2, w: 32, h: 32}
				render_copy(renderer, tex, &src, &dst)
			} else {
				if d.is_camera {
					set_render_draw_color(renderer, 160, 165, 175, 255)
					render_fill_rect(renderer, &Rect{x: dx, y: dy, w: 20, h: 14})
					set_render_draw_color(renderer, 255, 30, 30, 255)
					render_fill_rect(renderer, &Rect{x: dx + 12, y: dy + 4, w: 6, h: 6})
				} else if d.is_barrel {
					set_render_draw_color(renderer, 40, 190, 50, 255)
					render_fill_rect(renderer, &Rect{x: dx, y: dy, w: 24, h: 26})
					set_render_draw_color(renderer, 240, 220, 30, 255)
					draw_text_centered(renderer, dx + 12, dy + 8, 'RAD', 1, Color{r: 20, g: 20, b: 20})
				} else {
					set_render_draw_color(renderer, 150, 100, 50, 255)
					render_fill_rect(renderer, &Rect{x: dx, y: dy, w: 26, h: 26})
					set_render_draw_color(renderer, 80, 50, 20, 255)
					render_draw_rect(renderer, &Rect{x: dx, y: dy, w: 26, h: 26})
					render_draw_line(renderer, dx, dy, dx + 26, dy + 26)
				}
			}
		}
	}

	// Draw Pickups
	for item in game.items {
		if item.active {
			ix := int(item.x - cam_x)
			iy := int(item.y - cam_y)

			if tex != unsafe { nil } {
				src_x := match item.kind {
					.soda_can { 0 }
					.turkey { 40 }
					.red_key { 80 }
					.blue_key { 120 }
					.green_key { 160 }
					.floppy_disk { 200 }
					.circuit_board { 240 }
					.weapon_dual { 280 }
					.weapon_flame { 320 }
					.weapon_missile { 360 }
				}
				src := Rect{x: src_x, y: 192, w: 32, h: 32}
				dst := Rect{x: ix - 16, y: iy - 16, w: 32, h: 32}
				render_copy(renderer, tex, &src, &dst)
			} else {
				match item.kind {
					.soda_can {
						set_render_draw_color(renderer, 220, 30, 40, 255)
						render_fill_rect(renderer, &Rect{x: ix - 6, y: iy - 8, w: 12, h: 16})
						set_render_draw_color(renderer, 255, 255, 255, 255)
						render_draw_line(renderer, ix - 6, iy, ix + 6, iy)
					}
					.turkey {
						set_render_draw_color(renderer, 200, 130, 60, 255)
						render_fill_rect(renderer, &Rect{x: ix - 8, y: iy - 6, w: 16, h: 12})
					}
					.red_key {
						set_render_draw_color(renderer, 240, 40, 40, 255)
						render_fill_rect(renderer, &Rect{x: ix - 6, y: iy - 4, w: 12, h: 8})
					}
					.blue_key {
						set_render_draw_color(renderer, 40, 100, 250, 255)
						render_fill_rect(renderer, &Rect{x: ix - 6, y: iy - 4, w: 12, h: 8})
					}
					.green_key {
						set_render_draw_color(renderer, 40, 220, 60, 255)
						render_fill_rect(renderer, &Rect{x: ix - 6, y: iy - 4, w: 12, h: 8})
					}
					.weapon_dual, .weapon_flame, .weapon_missile {
						set_render_draw_color(renderer, 255, 215, 0, 255)
						render_fill_rect(renderer, &Rect{x: ix - 8, y: iy - 6, w: 16, h: 12})
						set_render_draw_color(renderer, 20, 20, 20, 255)
						draw_text_centered(renderer, ix, iy - 4, 'GUN', 1, Color{r: 20, g: 20, b: 20})
					}
					else {
						set_render_draw_color(renderer, 200, 200, 220, 255)
						render_fill_rect(renderer, &Rect{x: ix - 6, y: iy - 6, w: 12, h: 12})
					}
				}
			}
		}
	}

	// Draw Enemies
	for e in game.enemies {
		if e.active {
			ex := int(e.x - cam_x)
			ey := int(e.y - cam_y)

			if tex != unsafe { nil } {
				anim := (int(ticks / 180)) % 2
				mut src_x := 0
				match e.kind {
					.robodroid {
						src_x = if anim == 0 { 0 } else { 48 }
					}
					.turret {
						src_x = if e.dir > 0 { 144 } else { 96 }
					}
					.mutant_slime {
						src_x = if anim == 0 { 192 } else { 240 }
					}
				}
				src := Rect{x: src_x, y: 256, w: 32, h: 32}
				dst := Rect{x: ex - 4, y: ey - 4, w: 32, h: 32}
				render_copy(renderer, tex, &src, &dst)
			} else {
				match e.kind {
					.robodroid {
						set_render_draw_color(renderer, 140, 50, 180, 255)
						render_fill_rect(renderer, &Rect{x: ex, y: ey, w: int(e.w), h: int(e.h)})
						set_render_draw_color(renderer, 255, 50, 60, 255)
						render_fill_rect(renderer, &Rect{x: ex + 4, y: ey + 6, w: int(e.w) - 8, h: 4})
					}
					.turret {
						set_render_draw_color(renderer, 80, 85, 100, 255)
						render_fill_rect(renderer, &Rect{x: ex, y: ey, w: int(e.w), h: int(e.h)})
						set_render_draw_color(renderer, 240, 200, 40, 255)
						render_draw_line(renderer, ex + 12, ey + 12, ex + if e.dir > 0 { 24 } else { 0 }, ey + 12)
					}
					.mutant_slime {
						set_render_draw_color(renderer, 60, 240, 80, 255)
						render_fill_rect(renderer, &Rect{x: ex, y: ey + 8, w: int(e.w), h: int(e.h) - 8})
					}
				}
			}
		}
	}

	// Draw Mega Mech Boss
	draw_boss_mech(renderer, &game.boss, cam_x, cam_y, tex)

	// Draw Bullets & Lasers
	for b in game.bullets {
		if b.active {
			bx := int(b.x - cam_x)
			by := int(b.y - cam_y)
			r := int(b.rad)

			if tex != unsafe { nil } {
				mut src_x := 0
				match b.@type {
					.blaster { src_x = if b.is_enemy { 160 } else { 0 } }
					.dual_laser { src_x = 40 }
					.flamethrower { src_x = 80 }
					.missile { src_x = 120 }
				}
				src := Rect{x: src_x, y: 440, w: 32, h: 32}
				dst := Rect{x: bx - 16, y: by - 16, w: 32, h: 32}
				flip := if b.vx < 0 { RendererFlip.horizontal } else { RendererFlip.none }
				render_copy_ex(renderer, tex, &src, &dst, 0.0, unsafe { nil }, flip)
			} else {
				match b.@type {
					.blaster {
						col := if b.is_enemy { Color{r: 255, g: 60, b: 60} } else { Color{r: 255, g: 220, b: 50} }
						set_render_draw_color(renderer, col.r, col.g, col.b, 255)
						render_fill_rect(renderer, &Rect{x: bx - r, y: by - r, w: r * 2, h: r * 2})
					}
					.dual_laser {
						set_render_draw_color(renderer, 40, 220, 255, 255)
						render_fill_rect(renderer, &Rect{x: bx - r, y: by - r, w: r * 2 + 4, h: r * 2})
					}
					.flamethrower {
						set_render_draw_color(renderer, 255, 120, 30, 220)
						render_fill_rect(renderer, &Rect{x: bx - r, y: by - r, w: r * 2, h: r * 2})
					}
					.missile {
						set_render_draw_color(renderer, 220, 225, 235, 255)
						render_fill_rect(renderer, &Rect{x: bx - r, y: by - r / 2, w: r * 2, h: r})
						set_render_draw_color(renderer, 255, 100, 30, 255)
						render_fill_rect(renderer, &Rect{x: bx - r - 4, y: by - r / 2, w: 4, h: r})
					}
				}
			}
		}
	}

	// Draw Particle Explosions & Shrapnel
	render_sparks(renderer, sparks, cam_x, cam_y)

	// Draw Duke Player
	draw_duke_player(renderer, &game.player, game.player.x - cam_x, game.player.y - cam_y, tex)

	// Top Retro HUD (Two-Tier EGA Bezel)
	hud_h := 52
	set_render_draw_color(renderer, 14, 20, 42, 255)
	render_fill_rect(renderer, &Rect{x: 0, y: 0, w: screen_w, h: hud_h})
	set_render_draw_color(renderer, 60, 100, 200, 255)
	render_draw_line(renderer, 0, hud_h, screen_w, hud_h)

	// Top Tier (y: 8)
	draw_text(renderer, 15, 8, 'DUKE NUKEM', 2, Color{r: 255, g: 215, b: 0})

	// Health Bar Cells
	draw_text(renderer, 190, 8, 'HEALTH:', 2, Color{r: 180, g: 190, b: 220})
	for i in 0 .. game.player.max_hp {
		hx := 305 + i * 12
		cell_col := if i < game.player.hp { Color{r: 240, g: 40, b: 50} } else { Color{r: 45, g: 50, b: 65} }
		set_render_draw_color(renderer, cell_col.r, cell_col.g, cell_col.b, 255)
		render_fill_rect(renderer, &Rect{x: hx, y: 8, w: 9, h: 14})
		set_render_draw_color(renderer, 15, 15, 25, 255)
		render_draw_rect(renderer, &Rect{x: hx, y: 8, w: 9, h: 14})
	}

	draw_text(renderer, 460, 8, 'CAMERAS: ${game.cameras_left}', 2, Color{r: 255, g: 180, b: 40})
	draw_text(renderer, screen_w - 240, 8, 'SCORE: ${game.player.score}', 2, Color{r: 255, g: 255, b: 255})

	// Bottom Tier (y: 30)
	draw_text(renderer, 15, 30, 'KEYS:', 1, Color{r: 180, g: 190, b: 220})

	if tex != unsafe { nil } {
		if game.player.has_red_key {
			src := Rect{x: 80, y: 192, w: 32, h: 32}
			dst := Rect{x: 60, y: 28, w: 16, h: 16}
			render_copy(renderer, tex, &src, &dst)
		}
		if game.player.has_blue_key {
			src := Rect{x: 120, y: 192, w: 32, h: 32}
			dst := Rect{x: 80, y: 28, w: 16, h: 16}
			render_copy(renderer, tex, &src, &dst)
		}
		if game.player.has_green_key {
			src := Rect{x: 160, y: 192, w: 32, h: 32}
			dst := Rect{x: 100, y: 28, w: 16, h: 16}
			render_copy(renderer, tex, &src, &dst)
		}
	} else {
		r_col := if game.player.has_red_key { Color{r: 240, g: 40, b: 40} } else { Color{r: 50, g: 50, b: 60} }
		b_col := if game.player.has_blue_key { Color{r: 40, g: 120, b: 240} } else { Color{r: 50, g: 50, b: 60} }
		g_col := if game.player.has_green_key { Color{r: 40, g: 220, b: 60} } else { Color{r: 50, g: 50, b: 60} }

		set_render_draw_color(renderer, r_col.r, r_col.g, r_col.b, 255)
		render_fill_rect(renderer, &Rect{x: 60, y: 29, w: 10, h: 12})
		set_render_draw_color(renderer, b_col.r, b_col.g, b_col.b, 255)
		render_fill_rect(renderer, &Rect{x: 74, y: 29, w: 10, h: 12})
		set_render_draw_color(renderer, g_col.r, g_col.g, g_col.b, 255)
		render_fill_rect(renderer, &Rect{x: 88, y: 29, w: 10, h: 12})
	}

	wep_name := match game.player.weapon {
		.blaster { 'BLASTER' }
		.dual_laser { 'DUAL LASER' }
		.flamethrower { 'FLAME THROWER' }
		.missile { 'MICRO MISSILE' }
	}
	draw_text(renderer, 190, 30, 'WEAPON: ${wep_name}', 1, Color{r: 255, g: 255, b: 255})
	draw_text(renderer, 460, 30, 'AMMO: ${game.player.ammo}', 1, Color{r: 255, g: 215, b: 0})
	draw_text(renderer, screen_w - 240, 30, 'LIVES: ${game.player.lives} | SECTOR ${game.level_num}', 1, Color{r: 140, g: 200, b: 255})

	// Controls Footer Hint
	draw_text_centered(renderer, screen_w / 2, screen_h - 18, '[A/D/ARROWS] MOVE  [W/UP] CLIMB/AIM  [S/DOWN] CROUCH  [SPACE] JUMP  [CTRL/J/F] FIRE  [R] RESTART  [F11] Fullscreen', 1, Color{r: 160, g: 180, b: 220})

	// Mission Debrief / Victory / Game Over Overlays
	if game.state == .sector_debrief || game.state == .game_won || game.state == .game_over {
		set_render_draw_color(renderer, 0, 0, 0, 195)
		render_fill_rect(renderer, &Rect{x: 0, y: 0, w: screen_w, h: screen_h})

		mx := (screen_w - 520) / 2
		my := (screen_h - 260) / 2
		modal_rect := Rect{x: mx, y: my, w: 520, h: 260}
		set_render_draw_color(renderer, 18, 26, 56, 255)
		render_fill_rect(renderer, &modal_rect)
		set_render_draw_color(renderer, 60, 110, 220, 255)
		render_draw_rect(renderer, &modal_rect)

		if game.state == .sector_debrief {
			draw_text_centered(renderer, screen_w / 2, my + 24, 'MISSION DEBRIEF', 3, Color{r: 255, g: 215, b: 0})
			draw_text_centered(renderer, screen_w / 2, my + 65, '${game.sector_name} CLEARED!', 2, Color{r: 80, g: 255, b: 120})

			cam_bonus_str := if game.cameras_killed == game.cameras_total { 'ALL DESTROYED (+10,000 BONUS!)' } else { '${game.cameras_killed}/${game.cameras_total}' }
			draw_text_centered(renderer, screen_w / 2, my + 105, 'CAMERAS: ${cam_bonus_str}', 1, Color{r: 255, g: 220, b: 100})
			draw_text_centered(renderer, screen_w / 2, my + 130, 'SECTOR TIME: ${int(game.sector_time)} SECONDS', 1, Color{r: 180, g: 200, b: 240})
			draw_text_centered(renderer, screen_w / 2, my + 155, 'SECTOR BONUS: +${game.bonus_earned} PTS', 2, Color{r: 255, g: 255, b: 255})
			draw_text_centered(renderer, screen_w / 2, my + 185, 'TOTAL SCORE: ${game.player.score}', 2, Color{r: 255, g: 215, b: 0})
			draw_text_centered(renderer, screen_w / 2, my + 225, 'PRESS [SPACE] TO ENTER NEXT SECTOR', 1, Color{r: 140, g: 200, b: 255})
		} else if game.state == .game_won {
			draw_text_centered(renderer, screen_w / 2, my + 24, 'CYBER OUTPOST LIBERATED!', 3, Color{r: 255, g: 215, b: 0})
			draw_text_centered(renderer, screen_w / 2, my + 65, 'DR. PROTON DEFEATED & ESCAPED!', 2, Color{r: 80, g: 255, b: 120})
			draw_text_centered(renderer, screen_w / 2, my + 115, 'DUKE IS READY FOR THE NEXT MISSION', 2, Color{r: 200, g: 220, b: 255})
			draw_text_centered(renderer, screen_w / 2, my + 155, 'FINAL SCORE: ${game.player.score}', 3, Color{r: 255, g: 255, b: 255})
			draw_text_centered(renderer, screen_w / 2, my + 225, 'PRESS [SPACE] OR [R] TO PLAY AGAIN', 1, Color{r: 140, g: 200, b: 255})
		} else {
			draw_text_centered(renderer, screen_w / 2, my + 24, 'MISSION FAILED', 3, Color{r: 240, g: 50, b: 60})
			draw_text_centered(renderer, screen_w / 2, my + 75, 'DUKE WAS OVERWHELMED!', 2, Color{r: 220, g: 140, b: 140})
			draw_text_centered(renderer, screen_w / 2, my + 130, 'SCORE: ${game.player.score}', 2, Color{r: 255, g: 255, b: 255})
			draw_text_centered(renderer, screen_w / 2, my + 205, 'PRESS [SPACE] OR [R] TO RETRY', 1, Color{r: 140, g: 200, b: 255})
		}
	}

	if renderer.ctx != unsafe { nil } { prod_fx_render(renderer.ctx) }
	render_present(renderer)
}
