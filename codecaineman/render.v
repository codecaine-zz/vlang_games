module main

import math
import os
import rand

const pacman_sprite_sz = 32

pub struct PacmanTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn new_pacman_texture_manager() PacmanTextureManager {
	return PacmanTextureManager{}
}

pub fn (mut tm PacmanTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/pacman.png',
		'./assets/sprites/pacman.png',
		'../assets/sprites/pacman.png',
		'pacman/assets/sprites/pacman.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('pacman Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

const win_w = 960
const win_h = 790

const cell_px = 24
const margin_x = 35
const margin_y = 100

struct Button {
pub mut:
	x            int
	y            int
	w            int
	h            int
	text         string
	bg_color     Color
	hover_color  Color
	text_color   Color
	border_color Color
}

fn (b &Button) contains(px int, py int) bool {
	return px >= b.x && px <= b.x + b.w && py >= b.y && py <= b.y + b.h
}

fn (b &Button) draw(renderer &Renderer, mouse_x int, mouse_y int) {
	is_hover := b.contains(mouse_x, mouse_y)
	bg := if is_hover { b.hover_color } else { b.bg_color }

	rect := Rect{
		x: b.x
		y: b.y
		w: b.w
		h: b.h
	}

	set_render_draw_color(renderer, bg.r, bg.g, bg.b, bg.a)
	render_fill_rect(renderer, &rect)

	set_render_draw_color(renderer, b.border_color.r, b.border_color.g, b.border_color.b, b.border_color.a)
	render_draw_rect(renderer, &rect)

	text_y := b.y + (b.h - 16) / 2
	draw_text_centered(renderer, b.x + b.w / 2, text_y, b.text, 2, b.text_color)
}

fn draw_pacman_sprite(renderer &Renderer, px f64, py f64, dir Direction, mouth_ang f64, tex &Texture) {
	cx := margin_x + int(px)
	cy := margin_y + int(py)

	if tex != unsafe { nil } {
		row_y := match dir {
			.right { 0 }
			.down { 1 }
			.left { 2 }
			.up { 3 }
			else { 0 }
		}
		col_x := if mouth_ang < 0.22 {
			0
		} else if mouth_ang < 0.55 {
			1
		} else {
			2
		}
		src := Rect{x: col_x * pacman_sprite_sz, y: row_y * pacman_sprite_sz, w: pacman_sprite_sz, h: pacman_sprite_sz}
		dst := Rect{x: cx - 13, y: cy - 13, w: 26, h: 26}
		render_copy(renderer, tex, &src, &dst)
		return
	}

	r := 11
	base_ang := match dir {
		.right { 0.0 }
		.left { math.pi }
		.up { -0.5 * math.pi }
		.down { 0.5 * math.pi }
		else { 0.0 }
	}

	// 16-Bit Shaded Pac-Man Body with Highlight Contour
	for ry in -r .. r + 1 {
		for rx in -r .. r + 1 {
			d2 := rx * rx + ry * ry
			if d2 <= r * r {
				ang := math.atan2(f64(ry), f64(rx))
				mut diff := math.abs(ang - base_ang)
				if diff > math.pi {
					diff = 2.0 * math.pi - diff
				}

				if diff >= mouth_ang {
					col := if ry < -3 && rx < 0 {
						Color{ r: 255, g: 255, b: 140 }
					} else if d2 > (r - 2) * (r - 2) && (ry > 2 || rx > 2) {
						Color{ r: 215, g: 175, b: 0 }
					} else {
						Color{ r: 255, g: 220, b: 0 }
					}
					set_render_draw_color(renderer, col.r, col.g, col.b, 255)
					render_draw_point(renderer, cx + rx, cy + ry)
				}
			}
		}
	}
}

fn draw_ghost_sprite(renderer &Renderer, ghost &Ghost, global_t f64, frightened_t f64, tex &Texture) {
	cx := margin_x + int(ghost.x)
	cy := margin_y + int(ghost.y)

	if tex != unsafe { nil } {
		if ghost.mode == .frightened {
			is_flashing := frightened_t <= 2.0 && math.fmod(global_t, 0.4) >= 0.2
			col_x := if is_flashing { 1 } else { 0 }
			src := Rect{x: col_x * pacman_sprite_sz, y: 6 * pacman_sprite_sz, w: pacman_sprite_sz, h: pacman_sprite_sz}
			dst := Rect{x: cx - 13, y: cy - 13, w: 26, h: 26}
			render_copy(renderer, tex, &src, &dst)
			return
		} else if ghost.mode != .eaten {
			row_y := match ghost.name {
				.blinky, .pinky { 4 }
				.inky, .clyde { 5 }
			}
			base_col := match ghost.name {
				.blinky, .inky { 0 }
				.pinky, .clyde { 4 }
			}
			dir_col := match ghost.dir {
				.right { 0 }
				.left { 1 }
				.up { 2 }
				.down { 3 }
				else { 0 }
			}
			col_x := base_col + dir_col
			src := Rect{x: col_x * pacman_sprite_sz, y: row_y * pacman_sprite_sz, w: pacman_sprite_sz, h: pacman_sprite_sz}
			dst := Rect{x: cx - 13, y: cy - 13, w: 26, h: 26}
			render_copy(renderer, tex, &src, &dst)
			return
		}
	}

	r := 11
	body_color := match ghost.mode {
		.frightened {
			if frightened_t <= 2.0 && math.fmod(global_t, 0.4) >= 0.2 {
				Color{
					r: 220
					g: 220
					b: 255
				}
			} else {
				Color{
					r: 30
					g: 60
					b: 220
				}
			}
		}
		.eaten {
			Color{
				r: 0
				g: 0
				b: 0
				a: 0
			}
		}
		else {
			match ghost.name {
				.blinky {
					Color{
						r: 240
						g: 40
						b: 40
					}
				}
				.pinky {
					Color{
						r: 255
						g: 160
						b: 200
					}
				}
				.inky {
					Color{
						r: 40
						g: 220
						b: 240
					}
				}
				.clyde {
					Color{
						r: 255
						g: 160
						b: 40
					}
				}
			}
		}
	}

	if ghost.mode != .eaten {
		// 16-Bit Ghost Body Dome with Highlight & Shaded Contour
		set_render_draw_color(renderer, body_color.r, body_color.g, body_color.b, 255)
		for ry in -r .. r - 2 {
			rx_max := int(math.sqrt(f64(r * r - ry * ry)))
			rect := Rect{
				x: cx - rx_max
				y: cy + ry
				w: rx_max * 2
				h: 1
			}
			render_fill_rect(renderer, &rect)
		}

		// Top Left Highlight
		set_render_draw_color(renderer, 255, 255, 255, 140)
		render_draw_line(renderer, cx - 6, cy - 7, cx - 2, cy - 9)

		// 16-Bit Scalloped Wavy Tentacle Skirt (3 animated ruffles)
		wave_phase := int(global_t * 8.0) % 2
		for s := 0; s < 3; s++ {
			sx := cx - r + s * 7 + 1
			sy := cy + r - 2
			sh := if (s + wave_phase) % 2 == 0 { 5 } else { 3 }
			skirt_r := Rect{ x: sx, y: sy, w: 6, h: sh }
			set_render_draw_color(renderer, body_color.r, body_color.g, body_color.b, 255)
			render_fill_rect(renderer, &skirt_r)
		}
	}

	// Eyes / Face Rendering
	if ghost.mode == .frightened {
		eye1_x := cx - 4
		eye2_x := cx + 4
		eye_y := cy - 3

		face_color := if frightened_t <= 2.0 && math.fmod(global_t, 0.4) >= 0.2 {
			Color{ r: 220, g: 40, b: 40 }
		} else {
			Color{ r: 255, g: 180, b: 200 }
		}

		set_render_draw_color(renderer, face_color.r, face_color.g, face_color.b, 255)
		e1 := Rect{ x: eye1_x - 1, y: eye_y - 1, w: 3, h: 3 }
		e2 := Rect{ x: eye2_x - 1, y: eye_y - 1, w: 3, h: 3 }
		render_fill_rect(renderer, &e1)
		render_fill_rect(renderer, &e2)

		// Wavy zigzag mouth
		mouth_rect := Rect{ x: cx - 5, y: cy + 3, w: 10, h: 2 }
		render_fill_rect(renderer, &mouth_rect)
	} else {
		eye1_x := cx - 4
		eye2_x := cx + 4
		eye_y := cy - 3

		// White Sclera with drop shadow
		set_render_draw_color(renderer, 255, 255, 255, 255)
		e1 := Rect{ x: eye1_x - 3, y: eye_y - 4, w: 6, h: 8 }
		e2 := Rect{ x: eye2_x - 3, y: eye_y - 4, w: 6, h: 8 }
		render_fill_rect(renderer, &e1)
		render_fill_rect(renderer, &e2)

		// Directional Cobalt Blue Pupil with Glint
		dc, dr := dir_to_offset(ghost.dir)
		pupil_x1 := eye1_x + dc * 2
		pupil_y1 := eye_y + dr * 2
		pupil_x2 := eye2_x + dc * 2
		pupil_y2 := eye_y + dr * 2

		set_render_draw_color(renderer, 20, 40, 180, 255)
		p1 := Rect{ x: pupil_x1 - 1, y: pupil_y1 - 2, w: 3, h: 4 }
		p2 := Rect{ x: pupil_x2 - 1, y: pupil_y2 - 2, w: 3, h: 4 }
		render_fill_rect(renderer, &p1)
		render_fill_rect(renderer, &p2)

		set_render_draw_color(renderer, 255, 255, 255, 200)
		render_draw_point(renderer, pupil_x1, pupil_y1 - 1)
		render_draw_point(renderer, pupil_x2, pupil_y1 - 1)
	}
}

fn draw_game(renderer &Renderer, game &Game, mouse_x int, mouse_y int, btn_reset &Button, btn_sound &Button, btn_pause &Button, tex &Texture) {
	shake_mag := game.shake_trauma * game.shake_trauma * 14.0
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

	// Deep arcade black background
	set_render_draw_color(renderer, 10, 10, 15, 255)
	render_clear(renderer)

	// Top Title & Header Status
	header_rect := Rect{
		x: 20
		y: 15
		w: win_w - 40
		h: 70
	}
	set_render_draw_color(renderer, 18, 24, 42, 255)
	render_fill_rect(renderer, &header_rect)
	set_render_draw_color(renderer, 30, 80, 240, 255)
	render_draw_rect(renderer, &header_rect)

	draw_text(renderer, 24, 34, 'CODECAINE MAN', 2, Color{
		r: 255
		g: 235
		b: 0
	})

	draw_text(renderer, 250, 25, '1UP', 2, Color{
		r: 255
		g: 255
		b: 255
	})
	draw_text(renderer, 250, 48, '${game.score}', 2, Color{
		r: 255
		g: 255
		b: 255
	})

	draw_text(renderer, 420, 25, 'HIGH SCORE', 2, Color{
		r: 255
		g: 255
		b: 255
	})
	draw_text(renderer, 420, 48, '${game.high_score}', 2, Color{
		r: 255
		g: 220
		b: 40
	})

	draw_text(renderer, 640, 25, 'LEVEL', 2, Color{
		r: 255
		g: 255
		b: 255
	})
	draw_text(renderer, 640, 48, '${game.level}', 2, Color{
		r: 50
		g: 220
		b: 255
	})

	// Lives Icons
	draw_text(renderer, 760, 25, 'LIVES', 2, Color{
		r: 255
		g: 255
		b: 255
	})
	for l in 0 .. game.lives {
		draw_pacman_sprite(renderer, f64(750 + l * 26), -50.0, .right, 0.3, tex)
	}

	// Render Maze Playfield
	maze_border := Rect{
		x: margin_x - 2
		y: margin_y - 2
		w: map_cols * cell_px + 4
		h: map_rows * cell_px + 4
	}
	set_render_draw_color(renderer, 30, 80, 240, 255)
	render_draw_rect(renderer, &maze_border)

	for r in 0 .. map_rows {
		for c in 0 .. map_cols {
			cell_x := margin_x + c * cell_px
			cell_y := margin_y + r * cell_px
			tile := game.grid[c][r]

			match tile {
				.wall {
					rect := Rect{
						x: cell_x
						y: cell_y
						w: cell_px
						h: cell_px
					}
					set_render_draw_color(renderer, 25, 45, 140, 255)
					render_fill_rect(renderer, &rect)

					set_render_draw_color(renderer, 45, 110, 255, 255)
					render_draw_rect(renderer, &rect)
				}
				.door {
					door_rect := Rect{
						x: cell_x
						y: cell_y + 8
						w: cell_px
						h: 8
					}
					set_render_draw_color(renderer, 255, 180, 200, 255)
					render_fill_rect(renderer, &door_rect)
				}
				.dot {
					dot_rect := Rect{
						x: cell_x + 10
						y: cell_y + 10
						w: 4
						h: 4
					}
					set_render_draw_color(renderer, 255, 215, 175, 255)
					render_fill_rect(renderer, &dot_rect)
				}
				.power_pellet {
					if math.fmod(game.global_timer, 0.4) < 0.2 {
						pellet_rect := Rect{
							x: cell_x + 6
							y: cell_y + 6
							w: 12
							h: 12
						}
						set_render_draw_color(renderer, 255, 235, 190, 255)
						render_fill_rect(renderer, &pellet_rect)
					}
				}
				else {}
			}
		}
	}

	// Render Bonus Fruit
	if game.fruit_active {
		fx := margin_x + game.fruit_col * cell_px + 2
		fy := margin_y + game.fruit_row * cell_px + 2
		if tex != unsafe { nil } {
			src := Rect{x: 0, y: 7 * pacman_sprite_sz, w: pacman_sprite_sz, h: pacman_sprite_sz}
			dst := Rect{x: fx - 2, y: fy - 2, w: 24, h: 24}
			render_copy(renderer, tex, &src, &dst)
		} else {
			f_rect := Rect{x: fx + 4, y: fy + 4, w: 12, h: 12}
			set_render_draw_color(renderer, 255, 40, 60, 255)
			render_fill_rect(renderer, &f_rect)
		}
	}

	// Render Ghosts
	for g in game.ghosts {
		draw_ghost_sprite(renderer, &g, game.global_timer, game.frightened_timer, tex)
	}

	// Render Pac-Man
	draw_pacman_sprite(renderer, game.pacman.x, game.pacman.y, game.pacman.dir, game.pacman.mouth_angle, tex)

	// Render Floating Score Popups
	for pop in game.popups {
		draw_text_centered(renderer, margin_x + int(pop.x), margin_y + int(pop.y), pop.text, 2, pop.color)
	}

	// UI Control Buttons (Right side panel)
	btn_reset.draw(renderer, mouse_x, mouse_y)
	btn_sound.draw(renderer, mouse_x, mouse_y)
	btn_pause.draw(renderer, mouse_x, mouse_y)

	// Footer instructions
	draw_text_centered(renderer, win_w / 2, 755, 'CONTROLS: [ARROWS/WASD] MOVE  |  [R] RESET  |  [P] PAUSE  |  [S] SOUND | F11: Fullscreen',
		1, Color{
		r: 140
		g: 160
		b: 200
	})

	// Overlays for Ready! / Level Clear / Game Over / Paused
	if game.status == .ready {
		draw_text_centered(renderer, margin_x + 14 * cell_px, margin_y + 17 * cell_px + 4,
			'READY!', 2, Color{
			r: 255
			g: 235
			b: 0
		})
	} else if game.status == .level_clear {
		overlay_rect := Rect{
			x: 180
			y: 280
			w: 580
			h: 180
		}
		set_render_draw_color(renderer, 10, 40, 20, 240)
		render_fill_rect(renderer, &overlay_rect)
		set_render_draw_color(renderer, 50, 255, 120, 255)
		render_draw_rect(renderer, &overlay_rect)

		draw_text_centered(renderer, win_w / 2, 320, 'STAGE CLEARED!', 4, Color{
			r: 50
			g: 255
			b: 120
		})
		draw_text_centered(renderer, win_w / 2, 390, 'PREPARING NEXT LEVEL...', 2, Color{
			r: 255
			g: 255
			b: 255
		})
	} else if game.status == .game_over {
		overlay_rect := Rect{
			x: 180
			y: 280
			w: 580
			h: 180
		}
		set_render_draw_color(renderer, 50, 10, 15, 240)
		render_fill_rect(renderer, &overlay_rect)
		set_render_draw_color(renderer, 255, 50, 60, 255)
		render_draw_rect(renderer, &overlay_rect)

		draw_text_centered(renderer, win_w / 2, 320, 'GAME OVER', 4, Color{
			r: 255
			g: 50
			b: 60
		})
		draw_text_centered(renderer, win_w / 2, 390, 'PRESS [R] TO REPLAY', 2, Color{
			r: 255
			g: 220
			b: 50
		})
	} else if game.status == .paused {
		overlay_rect := Rect{
			x: 220
			y: 290
			w: 500
			h: 160
		}
		set_render_draw_color(renderer, 15, 25, 45, 240)
		render_fill_rect(renderer, &overlay_rect)
		set_render_draw_color(renderer, 50, 180, 255, 255)
		render_draw_rect(renderer, &overlay_rect)

		draw_text_centered(renderer, win_w / 2, 330, 'PAUSED', 4, Color{
			r: 50
			g: 200
			b: 255
		})
		draw_text_centered(renderer, win_w / 2, 395, 'PRESS [P] TO RESUME', 2, Color{
			r: 255
			g: 255
			b: 255
		})
	}
}
