module main

import time

import math
import os
import rand

pub struct TextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
	loaded         bool
}

pub fn (mut tm TextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/towerfall.png',
		'./assets/sprites/towerfall.png',
		'../assets/sprites/towerfall.png',
		'towerfall/assets/sprites/towerfall.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('towerfall Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

pub fn render_towerfall_game(renderer &Renderer, mut g TowerFallGame, tex &Texture) {
	// Screen shake offsets
	mut shake_x := 0
	mut shake_y := 0
	if g.shake_timer > 0.0 {
		shake_x = int((rand.f64() - 0.5) * g.shake_intensity)
		shake_y = int((rand.f64() - 0.5) * g.shake_intensity)
	}

	// 1. Background Fill (Rich Arena Theme)
	bg_col := match g.current_arena {
		0 { Color{24, 20, 36, 255} } // Sacred Ground
		1 { Color{16, 28, 42, 255} } // Sunken City
		2 { Color{40, 18, 26, 255} } // King's Court
		else { Color{28, 24, 20, 255} } // Tower of Dusk
	}
	set_render_draw_color(renderer, bg_col.r, bg_col.g, bg_col.b, 255)
	render_clear(renderer)

	// 2. Render Arena Level Tiles
	render_arena_tiles(renderer, g, tex, shake_x, shake_y)

	// 3. Render Chests
	for c in g.chests {
		render_chest(renderer, c, tex, shake_x, shake_y)
	}

	// 4. Render Arrows
	for a in g.arrows {
		render_arrow(renderer, a, tex, shake_x, shake_y)
	}

	// 5. Render Monsters (Quest Mode)
	if g.mode == .quest {
		for m in g.monsters {
			if m.hp > 0 {
				render_monster(renderer, m, tex, shake_x, shake_y)
			}
		}
	}

	// 6. Render Archers with HD Animations & Shadows
	for p in g.players {
		if p.lives > 0 {
			render_archer(renderer, p, tex, shake_x, shake_y)
		}
	}

	// 7. Render Particles
	render_particles(renderer, g.particles)

	// 8. Render UI & HUD Overlays
	render_hud(renderer, g)

	// 9. Render Toast Overlay
	if g.toast_timer > 0.0 {
		draw_text_centered_shadow(renderer, g.toast_msg, arena_w / 2, 80, 2, Color{255, 255, 255, 255}, Color{0, 0, 0, 255})
	}
}

fn render_arena_tiles(renderer &Renderer, g &TowerFallGame, tex &Texture, sx int, sy int) {
	tile_offset_x := match g.current_arena {
		0 { 0 }
		1 { 128 }
		2 { 192 }
		else { 0 }
	}

	stone_main := match g.current_arena {
		0 { Color{70, 75, 100, 255} }
		1 { Color{45, 80, 95, 255} }
		2 { Color{95, 50, 60, 255} }
		else { Color{85, 75, 60, 255} }
	}
	stone_top := match g.current_arena {
		0 { Color{110, 115, 150, 255} }
		1 { Color{75, 125, 140, 255} }
		2 { Color{145, 85, 95, 255} }
		else { Color{130, 115, 90, 255} }
	}

	for r in 0 .. map_rows {
		for c in 0 .. map_cols {
			tx := c * tile_size + sx
			ty := r * tile_size + sy

			if g.map_tiles[r][c] {
				if tex != unsafe { nil } {
					src := Rect{ x: tile_offset_x, y: 384, w: 64, h: 64 }
					dst := Rect{ x: tx, y: ty, w: tile_size, h: tile_size }
					render_copy(renderer, tex, &src, &dst)
				} else {
					rect := Rect{ x: tx, y: ty, w: tile_size, h: tile_size }
					set_render_draw_color(renderer, stone_main.r, stone_main.g, stone_main.b, 255)
					render_fill_rect(renderer, &rect)

					top_rect := Rect{ x: tx, y: ty, w: tile_size, h: 4 }
					set_render_draw_color(renderer, stone_top.r, stone_top.g, stone_top.b, 255)
					render_fill_rect(renderer, &top_rect)
				}
			} else if g.bramble_tiles[r][c] {
				if tex != unsafe { nil } {
					src := Rect{ x: 64, y: 384, w: 64, h: 64 }
					dst := Rect{ x: tx, y: ty, w: tile_size, h: tile_size }
					render_copy(renderer, tex, &src, &dst)
				} else {
					rect := Rect{ x: tx, y: ty, w: tile_size, h: tile_size }
					set_render_draw_color(renderer, 40, 140, 50, 255)
					render_fill_rect(renderer, &rect)
				}
			}
		}
	}
}

fn render_archer(renderer &Renderer, p Archer, tex &Texture, sx int, sy int) {
	px := int(p.x) + sx
	py := int(p.y) + sy

	// Flashing effect during invulnerability
	if p.invuln_timer > 0.0 && int(p.invuln_timer * 15.0) % 2 == 0 {
		return
	}

	// Modern Drop Shadow under Archer
	shd_rect := Rect{ x: px - 14, y: py - 2, w: 28, h: 6 }
	set_render_draw_color(renderer, 10, 8, 16, 140)
	render_fill_rect(renderer, &shd_rect)

	// Archer Color Row Index (0 = Green, 1 = Blue, 2 = Pink, 3 = Yellow)
	row := int(p.color)

	// Determine Animation Frame (0: Idle, 1..4: Run, 5: Aim Up, 6: Aim Down, 7: Dash)
	mut frame := 0
	if p.is_dashing {
		frame = 7
	} else if p.aim_y < -0.3 {
		frame = 5
	} else if p.aim_y > 0.3 {
		frame = 6
	} else if math.abs(p.vx) > 20.0 {
		frame = 1 + int(u32(time.ticks()) / 100) % 4
	}

	if tex != unsafe { nil } {
		src := Rect{ x: frame * 64, y: row * 64, w: 64, h: 64 }
		dst := Rect{ x: px - 20, y: py - 40, w: 40, h: 40 }
		flip := if p.facing < 0 { RendererFlip.horizontal } else { RendererFlip.none }
		render_copy_ex(renderer, tex, &src, &dst, 0.0, unsafe { nil }, flip)
	} else {
		// Fallback geometry renderer
		arch_col := match p.color {
			.green { Color{60, 200, 90, 255} }
			.blue { Color{70, 140, 240, 255} }
			.pink { Color{240, 90, 160, 255} }
			.yellow { Color{240, 200, 50, 255} }
		}

		body_rect := Rect{
			x: px - int(p.w / 2.0)
			y: py - int(p.h)
			w: int(p.w)
			h: int(p.h)
		}
		set_render_draw_color(renderer, arch_col.r, arch_col.g, arch_col.b, 255)
		render_fill_rect(renderer, &body_rect)

		head_rect := Rect{ x: px - 8, y: py - int(p.h) - 10, w: 16, h: 12 }
		set_render_draw_color(renderer, 240, 230, 210, 255)
		render_fill_rect(renderer, &head_rect)
	}

	// Quiver Indicator above head
	for i in 0 .. p.arrows {
		arr_x := px - 12 + i * 6
		arr_y := py - int(p.h) - 18
		set_render_draw_color(renderer, 255, 220, 100, 255)
		render_draw_line(renderer, arr_x, arr_y, arr_x, arr_y - 8)
	}
}

fn render_arrow(renderer &Renderer, a Arrow, tex &Texture, sx int, sy int) {
	ax := int(a.x) + sx
	ay := int(a.y) + sy

	col := match a.arrow_type {
		.normal { Color{255, 230, 120, 255} }
		.brambly { Color{80, 220, 90, 255} }
		.bomb { Color{255, 80, 40, 255} }
		.laser { Color{80, 220, 255, 255} }
	}

	if tex != unsafe { nil } {
		item_idx := match a.arrow_type {
			.normal { 0 }
			.brambly { 1 }
			.bomb { 2 }
			.laser { 3 }
		}
		src := Rect{ x: item_idx * 64, y: 256, w: 64, h: 64 }
		dst := Rect{ x: ax - 16, y: ay - 16, w: 32, h: 32 }
		angle := a.rot_angle * 180.0 / math.pi
		render_copy_ex(renderer, tex, &src, &dst, angle, unsafe { nil }, RendererFlip.none)
	} else {
		dx := int(math.cos(a.rot_angle) * 12.0)
		dy := int(math.sin(a.rot_angle) * 12.0)
		set_render_draw_color(renderer, col.r, col.g, col.b, 255)
		render_draw_line(renderer, ax - dx, ay - dy, ax + dx, ay + dy)
	}
}

fn render_monster(renderer &Renderer, m Monster, tex &Texture, sx int, sy int) {
	mx := int(m.x) + sx
	my := int(m.y) + sy

	// Drop Shadow under monster
	shd_rect := Rect{ x: mx - 12, y: my + 10, w: 24, h: 5 }
	set_render_draw_color(renderer, 10, 8, 16, 140)
	render_fill_rect(renderer, &shd_rect)

	if tex != unsafe { nil } {
		// Animated Monster Frame (2 frames per monster)
		anim_frame := int(u32(time.ticks()) / 180) % 2
		m_offset := match m.m_type {
			.skeleton { 0 + anim_frame }
			.slime { 2 + anim_frame }
			.bat { 4 + anim_frame }
			.reaper { 6 + anim_frame }
			.boss { 8 }
		}
		src := Rect{ x: m_offset * 64, y: 320, w: 64, h: 64 }
		dst := Rect{ x: mx - 20, y: my - 20, w: 40, h: 40 }
		render_copy(renderer, tex, &src, &dst)
	} else {
		m_col := match m.m_type {
			.skeleton { Color{220, 220, 220, 255} }
			.slime { Color{50, 220, 100, 255} }
			.bat { Color{160, 60, 220, 255} }
			.reaper { Color{40, 40, 40, 255} }
			.boss { Color{240, 40, 40, 255} }
		}

		rect := Rect{ x: mx - 12, y: my - 12, w: 24, h: 24 }
		set_render_draw_color(renderer, m_col.r, m_col.g, m_col.b, 255)
		render_fill_rect(renderer, &rect)
	}
}

fn render_chest(renderer &Renderer, c Chest, tex &Texture, sx int, sy int) {
	cx := int(c.x) + sx
	cy := int(c.y) + sy

	if tex != unsafe { nil } {
		c_idx := if c.opened { 5 } else { 4 }
		src := Rect{ x: c_idx * 64, y: 256, w: 64, h: 64 }
		dst := Rect{ x: cx - 16, y: cy - 16, w: 32, h: 32 }
		render_copy(renderer, tex, &src, &dst)
	} else {
		if c.opened {
			rect := Rect{ x: cx - 10, y: cy - 6, w: 20, h: 12 }
			set_render_draw_color(renderer, 120, 80, 40, 255)
			render_fill_rect(renderer, &rect)
		} else {
			rect := Rect{ x: cx - 12, y: cy - 10, w: 24, h: 20 }
			set_render_draw_color(renderer, 220, 160, 40, 255)
			render_fill_rect(renderer, &rect)
		}
	}
}

fn render_hud(renderer &Renderer, g &TowerFallGame) {
	if g.mode == .menu {
		draw_text_centered_shadow(renderer, 'TOWERFALL ASCENSION', arena_w / 2, 100, 4, Color{255, 215, 0, 255}, Color{0, 0, 0, 255})
		draw_text_centered_shadow(renderer, 'ARCHERY COMBAT PLATFORMER', arena_w / 2, 150, 2, Color{80, 220, 255, 255}, Color{0, 0, 0, 255})

		// Menu Selection Highlight
		opt1_col := if g.menu_selected == 0 { Color{255, 255, 0, 255} } else { Color{220, 220, 220, 255} }
		opt2_col := if g.menu_selected == 1 { Color{255, 255, 0, 255} } else { Color{220, 220, 220, 255} }

		draw_text_centered_shadow(renderer, '[1] QUEST MODE (SOLO / CO-OP VS MONSTERS)', arena_w / 2, 260, 2, opt1_col, Color{0, 0, 0, 255})
		draw_text_centered_shadow(renderer, '[2] VERSUS MODE (1V1 ARCHER BATTLE VS AI)', arena_w / 2, 310, 2, opt2_col, Color{0, 0, 0, 255})
		draw_text_centered_shadow(renderer, '[ESC] QUIT GAME', arena_w / 2, 360, 2, Color{180, 180, 180, 255}, Color{0, 0, 0, 255})

		draw_text_centered(renderer, 'CONTROLS: WASD/ARROWS=MOVE/AIM  SPACE/K=JUMP  SHIFT/J=DODGE DASH', arena_w / 2, 470, 1, Color{200, 220, 240, 255})
		draw_text_centered(renderer, 'F5: QUICK SAVE STATE | F9: QUICK LOAD STATE', arena_w / 2, 500, 1, Color{255, 220, 80, 255})
		draw_text_centered(renderer, 'HIGH SCORE: ${g.high_score}  MAX QUEST WAVE: ${g.max_quest_wave}', arena_w / 2, 530, 1, Color{150, 250, 150, 255})
	} else {
		// Top HUD Bar
		hud_text := if g.mode == .quest {
			'QUEST WAVE ${g.quest_wave} | SCORE: ${g.score} | HIGH: ${g.high_score}'
		} else {
			'VERSUS ARENA BATTLE | P1 LIVES: ${if g.players.len > 0 { g.players[0].lives } else { 0 }} | BOT LIVES: ${if g.players.len > 1 { g.players[1].lives } else { 0 }}'
		}
		draw_text_shadow(renderer, hud_text, 20, 16, 2, Color{255, 255, 255, 255}, Color{0, 0, 0, 255})
		draw_text(renderer, '[F5] SAVE  [F9] LOAD', arena_w - 220, 16, 2, Color{255, 220, 80, 255})
	}
}
