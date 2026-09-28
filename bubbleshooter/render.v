import math
import os
import rand



pub struct BubbleShooterTextureManager {
pub mut:
	sprite_texture &Texture = unsafe { nil }
}

pub fn (mut tm BubbleShooterTextureManager) init(renderer &Renderer) {
	candidates := [
		'assets/sprites/bubbleshooter.png',
		'./assets/sprites/bubbleshooter.png',
		'../assets/sprites/bubbleshooter.png',
		'bubbleshooter/assets/sprites/bubbleshooter.png',
	]
	for p in candidates {
		if os.exists(p) {
			tm.sprite_texture = load_texture(renderer.ctx, p)
			if tm.sprite_texture != unsafe { nil } && tm.sprite_texture.valid {
				println('bubbleshooter Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

pub struct PopParticle {
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

pub fn create_pop_particles(cx f64, cy f64, col Color) []PopParticle {
	mut parts := []PopParticle{cap: 24}
	for _ in 0 .. 18 {
		angle := (f64(rand.intn(360) or { 0 }) * math.pi) / 180.0
		speed := 40.0 + f64(rand.intn(160) or { 80 })
		life := 0.35 + f64(rand.intn(30) or { 15 }) / 100.0
		parts << PopParticle{
			x:        cx
			y:        cy
			vx:       math.cos(angle) * speed
			vy:       math.sin(angle) * speed
			life:     life
			max_life: life
			color:    col
			size:     2.0 + f64(rand.intn(4) or { 2 })
		}
	}
	return parts
}

pub fn update_pop_particles(mut particles []PopParticle, dt f64) {
	for mut p in particles {
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.vy += 250.0 * dt // gravity
		p.life -= dt
	}
	mut alive := []PopParticle{cap: particles.len}
	for p in particles {
		if p.life > 0 {
			alive << p
		}
	}
	particles = alive.clone()
}

pub fn render_pop_particles(renderer &Renderer, particles []PopParticle) {
	for p in particles {
		alpha := u8(math.clamp(p.life / p.max_life * 255.0, 0, 255))
		set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, alpha)
		sz := int(p.size)
		rect := Rect{x: int(p.x) - sz / 2, y: int(p.y) - sz / 2, w: sz, h: sz}
		render_fill_rect(renderer, &rect)
	}
}

pub fn get_bubble_theme_colors(color_id int) (Color, Color, Color) {
	// Returns (main_color, highlight_color, shadow_color)
	match color_id {
		1 { // Red
			return Color{r: 235, g: 45, b: 55}, Color{r: 255, g: 160, b: 170}, Color{r: 150, g: 20, b: 30}
		}
		2 { // Blue
			return Color{r: 40, g: 140, b: 245}, Color{r: 160, g: 210, b: 255}, Color{r: 20, g: 70, b: 160}
		}
		3 { // Green
			return Color{r: 45, g: 200, b: 65}, Color{r: 160, g: 245, b: 170}, Color{r: 20, g: 120, b: 35}
		}
		4 { // Yellow
			return Color{r: 245, g: 210, b: 35}, Color{r: 255, g: 245, b: 160}, Color{r: 160, g: 130, b: 15}
		}
		5 { // Purple
			return Color{r: 180, g: 60, b: 235}, Color{r: 230, g: 170, b: 255}, Color{r: 100, g: 25, b: 145}
		}
		6 { // Orange
			return Color{r: 245, g: 130, b: 35}, Color{r: 255, g: 195, b: 145}, Color{r: 160, g: 75, b: 15}
		}
		else {
			return Color{r: 180, g: 180, b: 180}, Color{r: 240, g: 240, b: 240}, Color{r: 100, g: 100, b: 100}
		}
	}
}

pub fn draw_glossy_bubble(renderer &Renderer, cx f64, cy f64, rad f64, color_id int, tex &Texture) {
	if tex != unsafe { nil } && color_id >= 1 && color_id <= 8 {
		col_x := (color_id - 1) * 64
		src := Rect{ x: col_x, y: 0, w: 64, h: 64 }
		eff_r := int(rad)
		dst := Rect{ x: int(cx) - eff_r, y: int(cy) - eff_r, w: eff_r * 2, h: eff_r * 2 }
		render_copy(renderer, tex, &src, &dst)
		return
	}

	main_c, high_c, shad_c := get_bubble_theme_colors(color_id)
	int_rad := int(rad)

	// Main body filled circle
	set_render_draw_color(renderer, main_c.r, main_c.g, main_c.b, main_c.a)
	for dy := -int_rad; dy <= int_rad; dy++ {
		dx_max := int(math.sqrt(f64(int_rad * int_rad - dy * dy)))
		render_draw_line(renderer, int(cx) - dx_max, int(cy) + dy, int(cx) + dx_max, int(cy) + dy)
	}

	// Bottom-Right Shadow Crescent
	set_render_draw_color(renderer, shad_c.r, shad_c.g, shad_c.b, 200)
	for dy := 0; dy <= int_rad; dy++ {
		dx_max := int(math.sqrt(f64(int_rad * int_rad - dy * dy)))
		if dx_max > 4 {
			render_draw_line(renderer, int(cx) + dx_max - 4, int(cy) + dy, int(cx) + dx_max, int(cy) + dy)
		}
	}

	// Top-Left Gloss Specular Highlight
	set_render_draw_color(renderer, high_c.r, high_c.g, high_c.b, 230)
	hl_rad := int(rad * 0.4)
	hl_cx := cx - rad * 0.35
	hl_cy := cy - rad * 0.35
	for dy := -hl_rad; dy <= hl_rad; dy++ {
		dx_max := int(math.sqrt(f64(hl_rad * hl_rad - dy * dy)))
		render_draw_line(renderer, int(hl_cx) - dx_max, int(hl_cy) + dy, int(hl_cx) + dx_max, int(hl_cy) + dy)
	}
}

pub fn render_bubbleshooter_game(renderer &Renderer, game &BubbleShooterGame, win_w int, win_h int, particles []PopParticle, tex &Texture) {
	shake_mag := game.shake_trauma * game.shake_trauma * 16.0
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

	// Arcade Dark Gradient Background
	set_render_draw_color(renderer, 14, 16, 28, 255)
	render_clear(renderer)

	// Arena Playfield Box
	ax := int(game.arena_x)
	ay := int(game.arena_y)
	aw := int(game.arena_w)
	ah := int(game.arena_h)

	// Playfield Backdrop
	set_render_draw_color(renderer, 22, 26, 44, 255)
	render_fill_rect(renderer, &Rect{x: ax, y: ay, w: aw, h: ah})

	// Arena Side Neon Walls
	set_render_draw_color(renderer, 70, 90, 150, 255)
	render_draw_rect(renderer, &Rect{x: ax, y: ay, w: aw, h: ah})

	// Danger Threshold Line
	set_render_draw_color(renderer, 220, 40, 50, 180)
	for lx := ax + 4; lx < ax + aw - 4; lx += 8 {
		render_draw_line(renderer, lx, int(game.danger_y), lx + 4, int(game.danger_y))
	}

	// Draw Grid Bubbles
	for r in 0 .. grid_rows {
		max_c := if r % 2 == 0 { grid_cols } else { grid_cols - 1 }
		for c in 0 .. max_c {
			col := game.grid[r][c]
			if col > 0 {
				bx, by := game.get_bubble_pos(r, c)
				draw_glossy_bubble(renderer, bx, by, bubble_radius, col, tex)
			}
		}
	}

	// Draw Falling Bubbles
	for fb in game.falling {
		draw_glossy_bubble(renderer, fb.x, fb.y, bubble_radius, fb.color, tex)
	}

	// Draw Trajectory Guideline if Aiming
	if game.state == .aiming {
		launcher_x := game.arena_x + game.arena_w / 2.0
		launcher_y := game.arena_y + game.arena_h - 30.0

		mut curr_x := launcher_x
		mut curr_y := launcher_y
		mut ray_dx := math.cos(game.aim_angle)
		mut ray_dy := -math.sin(game.aim_angle)

		set_render_draw_color(renderer, 255, 255, 255, 140)
		for step_i in 0 .. 50 {
			mut next_x := curr_x + ray_dx * 12.0
			next_y := curr_y + ray_dy * 12.0

			// Bounce off side walls
			if next_x - bubble_radius <= game.arena_x {
				next_x = game.arena_x + bubble_radius
				ray_dx = -ray_dx
			} else if next_x + bubble_radius >= game.arena_x + game.arena_w {
				next_x = game.arena_x + game.arena_w - bubble_radius
				ray_dx = -ray_dx
			}

			if step_i % 2 == 0 {
				dot_rect := Rect{x: int(curr_x) - 2, y: int(curr_y) - 2, w: 4, h: 4}
				render_fill_rect(renderer, &dot_rect)
			}

			curr_x = next_x
			curr_y = next_y
			if curr_y <= game.arena_y + bubble_radius {
				break
			}
		}
	}

	// Draw Projectile
	if game.projectile.active {
		draw_glossy_bubble(renderer, game.projectile.x, game.projectile.y, bubble_radius, game.projectile.color, tex)
	}

	// Draw Launcher Cannon & Current Bubble
	launcher_cx := game.arena_x + game.arena_w / 2.0
	launcher_cy := game.arena_y + game.arena_h - 30.0

	// Rotating Arrow Pointer
	arrow_len := 45.0
	tip_x := launcher_cx + math.cos(game.aim_angle) * arrow_len
	tip_y := launcher_cy - math.sin(game.aim_angle) * arrow_len
	set_render_draw_color(renderer, 255, 215, 0, 255)
	render_draw_line(renderer, int(launcher_cx), int(launcher_cy), int(tip_x), int(tip_y))

	// Current Bubble at Launcher
	if game.state == .aiming {
		draw_glossy_bubble(renderer, launcher_cx, launcher_cy, bubble_radius, game.current_color, tex)
	}

	// Draw Next Bubble in Reserve Queue (Left Panel)
	draw_text(renderer, ax - 130, ay + 380, 'NEXT', 2, Color{r: 160, g: 180, b: 220})
	draw_glossy_bubble(renderer, f64(ax - 90), f64(ay + 430), bubble_radius * 0.9, game.next_color, tex)

	// Ceiling Warning / Drops left counter
	drops_left := game.miss_limit - game.missed_shots
	draw_text(renderer, ax - 150, ay + 200, 'DROPS IN', 1, Color{r: 255, g: 100, b: 100})
	draw_text(renderer, ax - 110, ay + 220, '${drops_left}', 3, Color{r: 255, g: 60, b: 60})

	// Particles
	render_pop_particles(renderer, particles)

	// Right HUD: Title, Scores, Controls
	draw_text(renderer, ax + aw + 40, ay + 20, 'BUBBLE', 3, Color{r: 40, g: 180, b: 255})
	draw_text(renderer, ax + aw + 40, ay + 50, 'SHOOTER', 3, Color{r: 255, g: 215, b: 0})

	draw_text(renderer, ax + aw + 40, ay + 110, 'SCORE', 2, Color{r: 180, g: 190, b: 210})
	draw_text(renderer, ax + aw + 40, ay + 135, '${game.score}', 3, Color{r: 255, g: 255, b: 255})

	draw_text(renderer, ax + aw + 40, ay + 180, 'HI-SCORE', 2, Color{r: 180, g: 190, b: 210})
	draw_text(renderer, ax + aw + 40, ay + 205, '${game.high_score}', 3, Color{r: 255, g: 215, b: 0})

	draw_text(renderer, ax + aw + 40, ay + 260, 'SHOTS: ${game.shots_fired}', 2, Color{r: 140, g: 160, b: 200})

	draw_text(renderer, ax + aw + 40, ay + 340, 'CONTROLS:', 1, Color{r: 255, g: 255, b: 255})
	draw_text(renderer, ax + aw + 40, ay + 360, '[MOUSE] AIM', 1, Color{r: 160, g: 180, b: 220})
	draw_text(renderer, ax + aw + 40, ay + 380, '[CLICK/SPACE] SHOOT', 1, Color{r: 160, g: 180, b: 220})
	draw_text(renderer, ax + aw + 40, ay + 400, '[A/D] ARROW AIM', 1, Color{r: 160, g: 180, b: 220})
	draw_text(renderer, ax + aw + 40, ay + 420, '[R] RESTART  [F11] Fullscreen', 1, Color{r: 160, g: 180, b: 220})
	draw_text(renderer, ax + aw + 40, ay + 440, '[S] SOUND TOGGLE', 1, Color{r: 160, g: 180, b: 220})

	// Game Over / Victory Modal Overlay
	if game.state == .won || game.state == .game_over {
		set_render_draw_color(renderer, 0, 0, 0, 190)
		render_fill_rect(renderer, &Rect{x: 0, y: 0, w: win_w, h: win_h})

		mx := (win_w - 440) / 2
		my := (win_h - 220) / 2
		modal_rect := Rect{x: mx, y: my, w: 440, h: 220}
		set_render_draw_color(renderer, 20, 26, 44, 255)
		render_fill_rect(renderer, &modal_rect)
		set_render_draw_color(renderer, 70, 90, 160, 255)
		render_draw_rect(renderer, &modal_rect)

		if game.state == .won {
			draw_text_centered(renderer, win_w / 2, my + 30, 'STAGE CLEARED!', 3, Color{r: 255, g: 215, b: 0})
			draw_text_centered(renderer, win_w / 2, my + 75, 'AMAZING ACCURACY!', 2, Color{r: 80, g: 255, b: 120})
		} else {
			draw_text_centered(renderer, win_w / 2, my + 30, 'GAME OVER', 3, Color{r: 255, g: 60, b: 60})
			draw_text_centered(renderer, win_w / 2, my + 75, 'BUBBLES OVERFLOWED!', 2, Color{r: 220, g: 120, b: 120})
		}

		draw_text_centered(renderer, win_w / 2, my + 120, 'FINAL SCORE: ${game.score}', 2, Color{r: 255, g: 255, b: 255})
		draw_text_centered(renderer, win_w / 2, my + 165, 'PRESS [SPACE] OR [R] TO PLAY AGAIN', 1, Color{r: 140, g: 180, b: 240})
	}

	if renderer.ctx != unsafe { nil } { prod_fx_render(renderer.ctx) }
	render_present(renderer)
}
