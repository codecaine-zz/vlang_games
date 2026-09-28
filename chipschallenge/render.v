module main

import math
import os



const cell_sz = 32

pub struct TextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn new_texture_manager() TextureManager {
	return TextureManager{}
}

pub fn (mut tm TextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/chipschallenge.png',
		'./assets/sprites/chipschallenge.png',
		'../assets/sprites/chipschallenge.png',
		'chipschallenge/assets/sprites/chipschallenge.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('chipschallenge Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

pub fn render_chips_game(renderer &Renderer, mut g ChipsGame, win_w int, win_h int, sound_enabled bool, tex &Texture) {
	// 1. Dark Grey Windows 95 Canvas Background
	set_render_draw_color(renderer, 192, 192, 192, 255)
	clear_rect := Rect{0, 0, win_w, win_h}
	render_fill_rect(renderer, &clear_rect)

	tile_size := 36
	board_x := 30
	board_y := 30
	board_w := grid_size * tile_size
	board_h := grid_size * tile_size

	// 2. Sunken Grid Bevel
	set_render_draw_color(renderer, 128, 128, 128, 255)
	frame := Rect{board_x - 3, board_y - 3, board_w + 6, board_h + 6}
	render_draw_rect(renderer, &frame)
	set_render_draw_color(renderer, 255, 255, 255, 255)
	frame_outer := Rect{board_x - 4, board_y - 4, board_w + 8, board_h + 8}
	render_draw_rect(renderer, &frame_outer)

	// 3. Render 16x16 Grid Tiles
	for x in 0 .. grid_size {
		for y in 0 .. grid_size {
			px := board_x + x * tile_size
			py := board_y + y * tile_size
			render_tile(renderer, g.grid[x][y], px, py, tile_size, tex, g.anim_frame)
		}
	}

	// 4. Render Chip (Player)
	chip_px := board_x + g.player_x * tile_size
	chip_py := board_y + g.player_y * tile_size
	render_chip_player(renderer, chip_px, chip_py, tile_size, g, tex)

	// 5. Right Side Windows Status HUD
	hud_x := board_x + board_w + 25
	hud_y := board_y
	hud_w := win_w - hud_x - 30
	hud_h := board_h
	render_hud_panel(renderer, g, hud_x, hud_y, hud_w, hud_h, sound_enabled, tex)

	// 6. Announcement Banner
	if g.banner_timer > 0.0 && g.banner_text != '' {
		bw := g.banner_text.len * 8 * 2 + 40
		bx := win_w / 2 - bw / 2
		by := 260

		set_render_draw_color(renderer, 20, 30, 45, 240)
		bg := Rect{bx, by, bw, 44}
		render_fill_rect(renderer, &bg)
		set_render_draw_color(renderer, 255, 215, 0, 255)
		render_draw_rect(renderer, &bg)

		draw_text_centered(renderer, win_w / 2, by + 14, g.banner_text, 2, Color{255, 230, 80, 255})
	}
}

fn draw_sprite_tile(renderer &Renderer, tex &Texture, src_x int, src_y int, dst_x int, dst_y int, s int) {
	src := Rect{src_x, src_y, cell_sz, cell_sz}
	dst := Rect{dst_x, dst_y, s, s}
	render_copy(renderer, tex, &src, &dst)
}

fn render_tile(renderer &Renderer, t Tile, x int, y int, s int, tex &Texture, anim_frame int) {
	if tex != unsafe { nil } {
		// Draw base floor under transparent/overlay items
		draw_sprite_tile(renderer, tex, 0, 2 * cell_sz, x, y, s)

		match t {
			.floor {
				return
			}
			.wall {
				draw_sprite_tile(renderer, tex, 1 * cell_sz, 2 * cell_sz, x, y, s)
			}
			.dirt_block {
				draw_sprite_tile(renderer, tex, 2 * cell_sz, 2 * cell_sz, x, y, s)
			}
			.dirt_floor {
				draw_sprite_tile(renderer, tex, 3 * cell_sz, 2 * cell_sz, x, y, s)
			}
			.ice {
				draw_sprite_tile(renderer, tex, 4 * cell_sz, 2 * cell_sz, x, y, s)
			}
			.water {
				f := anim_frame % 4
				draw_sprite_tile(renderer, tex, f * cell_sz, 3 * cell_sz, x, y, s)
			}
			.fire {
				f := anim_frame % 4
				draw_sprite_tile(renderer, tex, (4 + f) * cell_sz, 3 * cell_sz, x, y, s)
			}
			.red_key {
				draw_sprite_tile(renderer, tex, 0 * cell_sz, 4 * cell_sz, x, y, s)
			}
			.blue_key {
				draw_sprite_tile(renderer, tex, 1 * cell_sz, 4 * cell_sz, x, y, s)
			}
			.yellow_key {
				draw_sprite_tile(renderer, tex, 2 * cell_sz, 4 * cell_sz, x, y, s)
			}
			.green_key {
				draw_sprite_tile(renderer, tex, 3 * cell_sz, 4 * cell_sz, x, y, s)
			}
			.red_door {
				draw_sprite_tile(renderer, tex, 4 * cell_sz, 4 * cell_sz, x, y, s)
			}
			.blue_door {
				draw_sprite_tile(renderer, tex, 5 * cell_sz, 4 * cell_sz, x, y, s)
			}
			.yellow_door {
				draw_sprite_tile(renderer, tex, 6 * cell_sz, 4 * cell_sz, x, y, s)
			}
			.green_door {
				draw_sprite_tile(renderer, tex, 7 * cell_sz, 4 * cell_sz, x, y, s)
			}
			.chip {
				f := anim_frame % 4
				draw_sprite_tile(renderer, tex, f * cell_sz, 5 * cell_sz, x, y, s)
			}
			.chip_socket {
				draw_sprite_tile(renderer, tex, 4 * cell_sz, 5 * cell_sz, x, y, s)
			}
			.exit_portal {
				f := anim_frame % 4
				draw_sprite_tile(renderer, tex, (5 + f) * cell_sz, 5 * cell_sz, x, y, s)
			}
			.hint_tile {
				draw_sprite_tile(renderer, tex, 9 * cell_sz, 5 * cell_sz, x, y, s)
			}
			.flippers {
				draw_sprite_tile(renderer, tex, 0 * cell_sz, 6 * cell_sz, x, y, s)
			}
			.fire_boots {
				draw_sprite_tile(renderer, tex, 1 * cell_sz, 6 * cell_sz, x, y, s)
			}
			.ice_skates {
				draw_sprite_tile(renderer, tex, 2 * cell_sz, 6 * cell_sz, x, y, s)
			}
			.suction_boots {
				draw_sprite_tile(renderer, tex, 3 * cell_sz, 6 * cell_sz, x, y, s)
			}
		}
		return
	}

	// Procedural Fallback
	set_render_draw_color(renderer, 220, 220, 220, 255)
	base := Rect{x, y, s, s}
	render_fill_rect(renderer, &base)

	match t {
		.wall {
			set_render_draw_color(renderer, 40, 70, 150, 255)
			render_fill_rect(renderer, &base)
			set_render_draw_color(renderer, 70, 110, 200, 255)
			render_draw_rect(renderer, &base)
		}
		.chip {
			set_render_draw_color(renderer, 30, 30, 30, 255)
			ic := Rect{x + 8, y + 8, s - 16, s - 16}
			render_fill_rect(renderer, &ic)
			set_render_draw_color(renderer, 220, 180, 40, 255)
			render_draw_line(renderer, x + 4, y + 12, x + 8, y + 12)
			render_draw_line(renderer, x + 4, y + 24, x + 8, y + 24)
			render_draw_line(renderer, x + s - 8, y + 12, x + s - 4, y + 12)
			render_draw_line(renderer, x + s - 8, y + 24, x + s - 4, y + 24)
		}
		.chip_socket {
			set_render_draw_color(renderer, 200, 40, 40, 255)
			render_fill_rect(renderer, &base)
			set_render_draw_color(renderer, 255, 255, 255, 255)
			render_draw_line(renderer, x, y, x + s, y + s)
			render_draw_line(renderer, x, y + s, x + s, y)
		}
		.exit_portal {
			set_render_draw_color(renderer, 40, 220, 240, 255)
			render_fill_rect(renderer, &base)
			set_render_draw_color(renderer, 255, 255, 255, 255)
			draw_filled_circle(renderer, x + s / 2, y + s / 2, 8, Color{255, 255, 255, 255})
		}
		.red_key {
			draw_key_icon(renderer, x, y, s, Color{220, 40, 40, 255})
		}
		.blue_key {
			draw_key_icon(renderer, x, y, s, Color{40, 80, 220, 255})
		}
		.yellow_key {
			draw_key_icon(renderer, x, y, s, Color{230, 200, 30, 255})
		}
		.green_key {
			draw_key_icon(renderer, x, y, s, Color{40, 200, 60, 255})
		}
		.red_door {
			draw_door_tile(renderer, x, y, s, Color{200, 40, 40, 255})
		}
		.blue_door {
			draw_door_tile(renderer, x, y, s, Color{40, 80, 200, 255})
		}
		.yellow_door {
			draw_door_tile(renderer, x, y, s, Color{220, 190, 30, 255})
		}
		.green_door {
			draw_door_tile(renderer, x, y, s, Color{40, 180, 60, 255})
		}
		.water {
			set_render_draw_color(renderer, 30, 110, 220, 255)
			render_fill_rect(renderer, &base)
		}
		.fire {
			set_render_draw_color(renderer, 240, 60, 20, 255)
			render_fill_rect(renderer, &base)
		}
		.dirt_block {
			set_render_draw_color(renderer, 140, 80, 40, 255)
			b := Rect{x + 2, y + 2, s - 4, s - 4}
			render_fill_rect(renderer, &b)
		}
		.dirt_floor {
			set_render_draw_color(renderer, 160, 110, 60, 255)
			render_fill_rect(renderer, &base)
		}
		.flippers {
			set_render_draw_color(renderer, 40, 200, 220, 255)
			draw_text_centered(renderer, x + s / 2, y + s / 2 - 4, 'FLIP', 1, Color{20, 40, 80, 255})
		}
		.fire_boots {
			set_render_draw_color(renderer, 240, 80, 40, 255)
			draw_text_centered(renderer, x + s / 2, y + s / 2 - 4, 'BOOT', 1, Color{80, 20, 10, 255})
		}
		.hint_tile {
			set_render_draw_color(renderer, 240, 240, 100, 255)
			draw_text_centered(renderer, x + s / 2, y + s / 2 - 4, '?', 2, Color{40, 40, 40, 255})
		}
		else {}
	}

	set_render_draw_color(renderer, 180, 180, 180, 255)
	render_draw_rect(renderer, &base)
}

fn draw_key_icon(renderer &Renderer, x int, y int, s int, col Color) {
	set_render_draw_color(renderer, col.r, col.g, col.b, 255)
	draw_filled_circle(renderer, x + s / 2 - 4, y + s / 2, 5, col)
	shaft := Rect{x + s / 2 - 4, y + s / 2 - 2, 12, 4}
	render_fill_rect(renderer, &shaft)
	tooth := Rect{x + s / 2 + 5, y + s / 2 + 2, 3, 4}
	render_fill_rect(renderer, &tooth)
}

fn draw_door_tile(renderer &Renderer, x int, y int, s int, col Color) {
	set_render_draw_color(renderer, col.r, col.g, col.b, 255)
	d_rect := Rect{x + 2, y + 2, s - 4, s - 4}
	render_fill_rect(renderer, &d_rect)
	set_render_draw_color(renderer, 255, 255, 255, 255)
	keyhole := Rect{x + s / 2 - 2, y + s / 2 - 3, 4, 6}
	render_fill_rect(renderer, &keyhole)
}

fn render_chip_player(renderer &Renderer, x int, y int, s int, g ChipsGame, tex &Texture) {
	if tex != unsafe { nil } {
		if g.is_dead {
			draw_sprite_tile(renderer, tex, 6 * cell_sz, 1 * cell_sz, x, y, s)
			return
		}

		mut col_idx := 0
		if g.facing_dx == 0 && g.facing_dy == 1 {
			col_idx = 0 + g.walk_step
		} else if g.facing_dx == 0 && g.facing_dy == -1 {
			col_idx = 2 + g.walk_step
		} else if g.facing_dx == -1 {
			col_idx = 4 + g.walk_step
		} else if g.facing_dx == 1 {
			col_idx = 6 + g.walk_step
		}

		// Equipment variant row 1
		mut row_idx := 0
		if g.has_flippers && g.grid[g.player_x][g.player_y] == .water {
			row_idx = 1
			col_idx = 0 + g.walk_step
		} else if g.has_fire_boots && g.grid[g.player_x][g.player_y] == .fire {
			row_idx = 1
			col_idx = 2 + g.walk_step
		} else if g.has_ice_skates && g.grid[g.player_x][g.player_y] == .ice {
			row_idx = 1
			col_idx = 4 + g.walk_step
		}

		draw_sprite_tile(renderer, tex, col_idx * cell_sz, row_idx * cell_sz, x, y, s)
		return
	}

	// Procedural Chip
	set_render_draw_color(renderer, 240, 210, 30, 255)
	body := Rect{x + 8, y + 10, s - 16, s - 16}
	render_fill_rect(renderer, &body)

	set_render_draw_color(renderer, 220, 40, 40, 255)
	cap := Rect{x + 8, y + 6, s - 16, 6}
	render_fill_rect(renderer, &cap)

	set_render_draw_color(renderer, 30, 60, 180, 255)
	legs := Rect{x + 10, y + s - 8, s - 20, 6}
	render_fill_rect(renderer, &legs)

	set_render_draw_color(renderer, 255, 255, 255, 255)
	eye1 := Rect{x + 12 + g.facing_dx * 2, y + 14 + g.facing_dy * 2, 3, 3}
	eye2 := Rect{x + 18 + g.facing_dx * 2, y + 14 + g.facing_dy * 2, 3, 3}
	render_fill_rect(renderer, &eye1)
	render_fill_rect(renderer, &eye2)
}

fn render_hud_panel(renderer &Renderer, g ChipsGame, x int, y int, w int, h int, sound_enabled bool, tex &Texture) {
	// Windows 95 Style Panel
	set_render_draw_color(renderer, 210, 210, 210, 255)
	panel := Rect{x, y, w, h}
	render_fill_rect(renderer, &panel)

	// 3D Bevel Border
	set_render_draw_color(renderer, 255, 255, 255, 255)
	render_draw_line(renderer, x, y, x + w, y)
	render_draw_line(renderer, x, y, x, y + h)
	set_render_draw_color(renderer, 100, 100, 100, 255)
	render_draw_line(renderer, x, y + h, x + w, y + h)
	render_draw_line(renderer, x + w, y, x + w, y + h)

	lvl := g.levels[g.level_idx]

	// Title
	draw_text_centered(renderer, x + w / 2, y + 14, "CHIP'S CHALLENGE", 1, Color{20, 20, 40, 255})
	draw_text_centered(renderer, x + w / 2, y + 32, lvl.name.to_upper(), 1, Color{80, 40, 20, 255})

	// Chips Left 7-Segment Box
	set_render_draw_color(renderer, 20, 20, 20, 255)
	chip_box := Rect{x + 20, y + 60, w - 40, 45}
	render_fill_rect(renderer, &chip_box)
	if tex != unsafe { nil } {
		draw_sprite_tile(renderer, tex, 0, 5 * cell_sz, x + 24, y + 66, 32)
	}
	draw_text_centered(renderer, x + w / 2 + 10, y + 68, 'CHIPS LEFT', 1, Color{180, 180, 180, 255})
	draw_text_centered(renderer, x + w / 2 + 10, y + 84, '${g.chips_left}', 2, Color{255, 50, 50, 255})

	// Time Left 7-Segment Box
	time_box := Rect{x + 20, y + 120, w - 40, 45}
	render_fill_rect(renderer, &time_box)
	draw_text_centered(renderer, x + w / 2, y + 128, 'TIME REMAINING', 1, Color{180, 180, 180, 255})
	draw_text_centered(renderer, x + w / 2, y + 144, '${int(math.max(0.0, g.time_left))}', 2, Color{50, 255, 50, 255})

	// Keys Inventory with icons
	draw_text(renderer, x + 20, y + 185, 'KEYS INVENTORY:', 1, Color{40, 40, 40, 255})
	if tex != unsafe { nil } {
		draw_sprite_tile(renderer, tex, 0 * cell_sz, 4 * cell_sz, x + 20, y + 205, 24)
		draw_text(renderer, x + 50, y + 212, 'x${g.red_keys}', 1, Color{200, 30, 30, 255})

		draw_sprite_tile(renderer, tex, 1 * cell_sz, 4 * cell_sz, x + 110, y + 205, 24)
		draw_text(renderer, x + 140, y + 212, 'x${g.blue_keys}', 1, Color{30, 60, 200, 255})

		draw_sprite_tile(renderer, tex, 2 * cell_sz, 4 * cell_sz, x + 20, y + 235, 24)
		draw_text(renderer, x + 50, y + 242, 'x${g.yellow_keys}', 1, Color{180, 150, 0, 255})

		draw_sprite_tile(renderer, tex, 3 * cell_sz, 4 * cell_sz, x + 110, y + 235, 24)
		draw_text(renderer, x + 140, y + 242, 'x${g.green_keys}', 1, Color{30, 160, 40, 255})
	} else {
		draw_text(renderer, x + 24, y + 205, 'RED: ${g.red_keys}', 1, Color{200, 30, 30, 255})
		draw_text(renderer, x + 120, y + 205, 'BLUE: ${g.blue_keys}', 1, Color{30, 60, 200, 255})
		draw_text(renderer, x + 24, y + 230, 'YEL: ${g.yellow_keys}', 1, Color{180, 150, 0, 255})
		draw_text(renderer, x + 120, y + 230, 'GRN: ${g.green_keys}', 1, Color{30, 160, 40, 255})
	}

	// Boots Equipment Panel with icons
	draw_text(renderer, x + 20, y + 275, 'EQUIPMENT:', 1, Color{40, 40, 40, 255})
	if tex != unsafe { nil } {
		draw_sprite_tile(renderer, tex, 0 * cell_sz, 6 * cell_sz, x + 20, y + 295, 28)
		flip_str := if g.has_flippers { 'FLIPPERS [ON]' } else { 'FLIPPERS' }
		flip_col := if g.has_flippers { Color{30, 140, 200, 255} } else { Color{130, 130, 130, 255} }
		draw_text(renderer, x + 52, y + 302, flip_str, 1, flip_col)

		draw_sprite_tile(renderer, tex, 1 * cell_sz, 6 * cell_sz, x + 20, y + 330, 28)
		fire_str := if g.has_fire_boots { 'FIRE BOOTS [ON]' } else { 'FIRE BOOTS' }
		fire_col := if g.has_fire_boots { Color{220, 60, 30, 255} } else { Color{130, 130, 130, 255} }
		draw_text(renderer, x + 52, y + 337, fire_str, 1, fire_col)
	} else {
		flip_str := if g.has_flippers { '[X] FLIPPERS' } else { '[ ] FLIPPERS' }
		fire_str := if g.has_fire_boots { '[X] FIRE BOOTS' } else { '[ ] FIRE BOOTS' }
		draw_text(renderer, x + 24, y + 295, flip_str, 1, Color{30, 80, 180, 255})
		draw_text(renderer, x + 24, y + 315, fire_str, 1, Color{180, 50, 20, 255})
	}

	// Hint window
	if g.showing_hint {
		draw_text(renderer, x + 20, y + 380, 'HINT: ${lvl.hint_text}', 1, Color{80, 60, 0, 255})
	}

	// Sound toggle badge
	sound_x := x + 20
	sound_y := y + h - 50
	if sound_enabled {
		set_render_draw_color(renderer, 40, 120, 60, 255)
		btn := Rect{sound_x, sound_y, w - 40, 28}
		render_fill_rect(renderer, &btn)
		draw_text_centered(renderer, sound_x + (w - 40) / 2, sound_y + 8, 'MUSIC & SFX: ON [M]', 1, Color{255, 255, 255, 255})
	} else {
		set_render_draw_color(renderer, 120, 35, 40, 255)
		btn := Rect{sound_x, sound_y, w - 40, 28}
		render_fill_rect(renderer, &btn)
		draw_text_centered(renderer, sound_x + (w - 40) / 2, sound_y + 8, 'MUTED [M]', 1, Color{255, 180, 180, 255})
	}
}
