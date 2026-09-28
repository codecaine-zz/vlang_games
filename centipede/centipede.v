module main

import os
import math
import rand



const grid_cols = 30
const grid_rows = 30
const tile_size = 20.0
const playfield_offset_x = 100.0
const playfield_offset_y = 40.0
const playfield_width = f64(grid_cols) * tile_size // 600.0
const playfield_height = f64(grid_rows) * tile_size // 600.0

enum PowerUpType {
	none
	rapid_fire
	triple_spread
	plasma_beam
	emp_nuke
	shield
	speed_dash
}

struct Mushroom {
pub mut:
	exists       bool
	hp           int = 4
	is_poison    bool
	has_powerup  bool
	powerup_type PowerUpType = .none
}

struct CentipedeSegment {
pub mut:
	col         int
	row         int
	sub_x       f64 // progress within current tile [0.0 .. 1.0]
	sub_y       f64
	dir_x       int = 1  // +1 right, -1 left
	dir_y       int = 1  // +1 down, -1 up
	is_head     bool
	is_poisoned bool // vertical dive mode
	hp          int = 1
	speed       f64 = 4.0 // tiles per second
}

struct CentipedeChain {
pub mut:
	segments []CentipedeSegment
}

struct Player {
pub mut:
	x         f64 = 400.0
	y         f64 = 580.0
	radius    f64 = 10.0
	speed     f64 = 240.0
	fire_cooldown f64
	is_alive  bool = true
	respawn_timer f64
}

struct Laser {
pub mut:
	x         f64
	y         f64
	dx        f64
	dy        f64
	is_plasma bool
	active    bool = true
}

struct Flea {
pub mut:
	col     int
	y       f64
	speed   f64 = 180.0
	hp      int = 2
	active  bool
}

struct Spider {
pub mut:
	x          f64
	y          f64
	dir_x      f64
	dir_y      f64
	speed      f64 = 140.0
	timer      f64
	active     bool
}

struct Scorpion {
pub mut:
	row     int
	x       f64
	dir_x   f64 = 1.0
	speed   f64 = 160.0
	active  bool
}

struct DroppedPowerUp {
pub mut:
	x      f64
	y      f64
	ptype  PowerUpType
	active bool = true
}

struct Particle {
pub mut:
	x        f64
	y        f64
	dx       f64
	dy       f64
	life     f64
	max_life f64
	color    Color
}

struct ScorePopup {
pub mut:
	x     f64
	y     f64
	text  string
	life  f64 = 1.0
	color Color
}

struct CentipedeGame {
pub mut:
	grid             [30][30]Mushroom
	player           Player
	chains           []CentipedeChain
	lasers           []Laser
	fleas            []Flea
	spiders          []Spider
	scorpions        []Scorpion
	powerups         []DroppedPowerUp
	particles        []Particle
	popups           []ScorePopup
	score            int
	high_score       int = 10000
	lives            int = 3
	wave             int = 1
	game_over        bool
	paused           bool
	wave_cleared     bool
	wave_clear_timer f64

	// Active Power-up Timers (seconds remaining)
	timer_rapid_fire  f64
	timer_triple_shot f64
	timer_plasma_beam f64
	timer_shield      f64
	timer_speed_dash  f64

	// Enemy Spawn Timers
	flea_spawn_timer     f64
	spider_spawn_timer   f64
	scorpion_spawn_timer f64

	// Boss wave flag
	is_boss_wave bool
	boss_hp      int
	boss_max_hp  int
	shake_trauma f64

	sprite_texture     &Texture = unsafe { nil }
	has_sprite_texture bool
}

pub fn (mut game CentipedeGame) init_textures(renderer &Renderer) {
	paths := [
		'assets/sprites/centipede.png',
		'./assets/sprites/centipede.png',
		'../assets/sprites/centipede.png',
		'centipede/assets/sprites/centipede.png',
	]
	for p in paths {
		if os.exists(p) {
			game.sprite_texture = load_texture(renderer.ctx, p)
			if game.sprite_texture != unsafe { nil } && game.sprite_texture.valid {
				println('centipede Texture Loaded Successfully: ' + p)
				return
			}
		}
	}
}

fn new_centipede_game() CentipedeGame {
	mut game := CentipedeGame{}
	game.init_new_game()
	return game
}

fn (mut g CentipedeGame) init_new_game() {
	g.score = 0
	g.lives = 3
	g.wave = 1
	g.game_over = false
	g.paused = false
	g.shake_trauma = 0.0
	g.player = Player{
		x: playfield_offset_x + playfield_width / 2.0
		y: playfield_offset_y + playfield_height - 30.0
	}
	g.clear_entities()
	g.generate_initial_mushrooms()
	g.start_wave(1)
}

fn (mut g CentipedeGame) reset() {
	g.init_new_game()
}

fn (mut g CentipedeGame) clear_entities() {
	g.chains.clear()
	g.lasers.clear()
	g.fleas.clear()
	g.spiders.clear()
	g.scorpions.clear()
	g.powerups.clear()
	g.particles.clear()
	g.popups.clear()
	g.timer_rapid_fire = 0.0
	g.timer_triple_shot = 0.0
	g.timer_plasma_beam = 0.0
	g.timer_shield = 0.0
	g.timer_speed_dash = 0.0
}

fn (mut g CentipedeGame) generate_initial_mushrooms() {
	// Clear grid
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			g.grid[r][c] = Mushroom{exists: false}
		}
	}

	// Spawn ~50-60 random mushrooms in upper & middle grid (rows 2..24)
	mush_count := 50 + rand.intn(15) or { 10 }
	for _ in 0 .. mush_count {
		r := 2 + rand.intn(22) or { 0 }
		c := rand.intn(grid_cols) or { 0 }
		if !g.grid[r][c].exists {
			has_pow := (rand.intn(12) or { 0 }) == 0
			mut ptype := PowerUpType.none
			if has_pow {
				p_rand := rand.intn(6) or { 0 }
				ptype = match p_rand {
					0 { PowerUpType.rapid_fire }
					1 { PowerUpType.triple_spread }
					2 { PowerUpType.plasma_beam }
					3 { PowerUpType.emp_nuke }
					4 { PowerUpType.shield }
					else { PowerUpType.speed_dash }
				}
			}
			g.grid[r][c] = Mushroom{
				exists: true
				hp: 4
				is_poison: false
				has_powerup: has_pow
				powerup_type: ptype
			}
		}
	}
}

fn (mut g CentipedeGame) start_wave(wave_num int) {
	g.wave = wave_num
	g.chains.clear()
	g.fleas.clear()
	g.spiders.clear()
	g.scorpions.clear()
	g.wave_cleared = false

	g.is_boss_wave = (wave_num % 5 == 0)

	base_speed := 4.0 + f64(wave_num) * 0.5
	if g.is_boss_wave {
		// Spawn Armored Mega-Centipede
		seg_count := 12
		g.boss_hp = 50
		g.boss_max_hp = 50
		mut segments := []CentipedeSegment{cap: seg_count}
		for i in 0 .. seg_count {
			segments << CentipedeSegment{
				col: (grid_cols / 2) - i
				row: 0
				sub_x: 0.5
				sub_y: 0.5
				dir_x: 1
				dir_y: 1
				is_head: (i == 0)
				hp: if i == 0 { 5 } else { 2 }
				speed: base_speed * 1.25
			}
		}
		g.chains << CentipedeChain{segments: segments}
	} else {
		// Normal wave: 1 main centipede (length 10 to 14 depending on wave)
		length := math.min(10 + wave_num / 2, 16)
		mut segments := []CentipedeSegment{cap: length}
		start_col := rand.intn(grid_cols - length) or { 5 }
		for i in 0 .. length {
			segments << CentipedeSegment{
				col: start_col + length - 1 - i
				row: 0
				sub_x: 0.5
				sub_y: 0.5
				dir_x: 1
				dir_y: 1
				is_head: (i == 0)
				hp: 1
				speed: base_speed
			}
		}
		g.chains << CentipedeChain{segments: segments}
	}

	g.flea_spawn_timer = 4.0
	g.spider_spawn_timer = 3.0
	g.scorpion_spawn_timer = 8.0
}

fn (mut g CentipedeGame) add_popup(x f64, y f64, text string, color Color) {
	g.popups << ScorePopup{
		x: x
		y: y
		text: text
		life: 1.0
		color: color
	}
}

fn (mut g CentipedeGame) add_score(pts int, x f64, y f64) {
	g.score += pts
	if g.score > g.high_score {
		g.high_score = g.score
	}
	g.add_popup(x, y, '+${pts}', Color{r: 255, g: 230, b: 80})
}

fn (mut g CentipedeGame) update(dt f64, sound_mgr &SoundManager) {
	if g.game_over || g.paused {
		return
	}

	if g.shake_trauma > 0.0 {
		g.shake_trauma = math.max(0.0, g.shake_trauma - dt * 2.2)
	}

	// Update Powerup Timers
	if g.timer_rapid_fire > 0.0 { g.timer_rapid_fire -= dt }
	if g.timer_triple_shot > 0.0 { g.timer_triple_shot -= dt }
	if g.timer_plasma_beam > 0.0 { g.timer_plasma_beam -= dt }
	if g.timer_shield > 0.0 { g.timer_shield -= dt }
	if g.timer_speed_dash > 0.0 { g.timer_speed_dash -= dt }

	// Handle Player Respawn
	if !g.player.is_alive {
		g.player.respawn_timer -= dt
		if g.player.respawn_timer <= 0.0 {
			if g.lives > 0 {
				g.player.is_alive = true
				g.player.x = playfield_offset_x + playfield_width / 2.0
				g.player.y = playfield_offset_y + playfield_height - 30.0
				g.timer_shield = 2.5 // temporary invulnerability post-respawn
			} else {
				g.game_over = true
			}
		}
		return
	}

	// Update Player Fire Cooldown
	if g.player.fire_cooldown > 0.0 {
		g.player.fire_cooldown -= dt
	}

	// Update Particles
	for i := g.particles.len - 1; i >= 0; i-- {
		g.particles[i].x += g.particles[i].dx * dt
		g.particles[i].y += g.particles[i].dy * dt
		g.particles[i].life -= dt
		if g.particles[i].life <= 0.0 {
			g.particles.delete(i)
		}
	}

	// Update Score Popups
	for i := g.popups.len - 1; i >= 0; i-- {
		g.popups[i].y -= 25.0 * dt
		g.popups[i].life -= dt
		if g.popups[i].life <= 0.0 {
			g.popups.delete(i)
		}
	}

	// Update Dropped Powerups
	for i := g.powerups.len - 1; i >= 0; i-- {
		g.powerups[i].y += 80.0 * dt
		// Check pickup by player
		if g.player.is_alive {
			dx := g.powerups[i].x - g.player.x
			dy := g.powerups[i].y - g.player.y
			if math.sqrt(dx * dx + dy * dy) < (g.player.radius + 12.0) {
				// Picked up!
				g.apply_powerup(g.powerups[i].ptype, sound_mgr)
				g.powerups.delete(i)
				continue
			}
		}
		if g.powerups[i].y > playfield_offset_y + playfield_height + 20.0 {
			g.powerups.delete(i)
		}
	}

	// Update Lasers
	for i := g.lasers.len - 1; i >= 0; i-- {
		g.lasers[i].x += g.lasers[i].dx * dt
		g.lasers[i].y += g.lasers[i].dy * dt
		if g.lasers[i].y < playfield_offset_y - 10.0 || g.lasers[i].x < playfield_offset_x - 10.0 || g.lasers[i].x > playfield_offset_x + playfield_width + 10.0 {
			g.lasers.delete(i)
		}
	}

	// Update Centipedes
	g.update_centipedes(dt, sound_mgr)

	// Update Fleas
	g.update_fleas(dt, sound_mgr)

	// Update Spiders
	g.update_spiders(dt, sound_mgr)

	// Update Scorpions
	g.update_scorpions(dt, sound_mgr)

	// Check Laser Collisions
	g.check_collisions(sound_mgr)

	// Spawn Enemy Logic
	g.handle_enemy_spawns(dt, sound_mgr)

	// Check Wave Clear Condition
	if g.chains.len == 0 && !g.wave_cleared {
		g.wave_cleared = true
		g.wave_clear_timer = 2.0
		sound_mgr.play_powerup_sound()
	}

	if g.wave_cleared {
		g.wave_clear_timer -= dt
		if g.wave_clear_timer <= 0.0 {
			// Regenerate damaged mushrooms for bonus points!
			g.regenerate_mushrooms()
			g.start_wave(g.wave + 1)
		}
	}
}

fn (mut g CentipedeGame) apply_powerup(ptype PowerUpType, sound_mgr &SoundManager) {
	sound_mgr.play_powerup_sound()
	match ptype {
		.rapid_fire {
			g.timer_rapid_fire = 6.0
			g.add_popup(g.player.x, g.player.y - 20.0, 'RAPID FIRE!', Color{r: 80, g: 255, b: 120})
		}
		.triple_spread {
			g.timer_triple_shot = 6.0
			g.add_popup(g.player.x, g.player.y - 20.0, 'TRIPLE SHOT!', Color{r: 255, g: 150, b: 50})
		}
		.plasma_beam {
			g.timer_plasma_beam = 5.0
			g.add_popup(g.player.x, g.player.y - 20.0, 'PLASMA BEAM!', Color{r: 200, g: 80, b: 255})
		}
		.emp_nuke {
			sound_mgr.play_nuke_sound()
			g.trigger_emp_nuke()
			g.add_popup(g.player.x, g.player.y - 20.0, 'EMP NUKE!', Color{r: 255, g: 50, b: 80})
		}
		.shield {
			g.timer_shield = 6.0
			g.add_popup(g.player.x, g.player.y - 20.0, 'SHIELD ACTIVE!', Color{r: 50, g: 200, b: 255})
		}
		.speed_dash {
			g.timer_speed_dash = 6.0
			g.add_popup(g.player.x, g.player.y - 20.0, 'SPEED BOOST!', Color{r: 255, g: 255, b: 100})
		}
		else {}
	}
}

fn (mut g CentipedeGame) trigger_emp_nuke() {
	g.shake_trauma = math.min(1.0, g.shake_trauma + 0.60)
	// Destroy all fleas, spiders, scorpions
	for spider in g.spiders {
		g.add_score(300, spider.x, spider.y)
		g.spawn_particles(spider.x, spider.y, 15, Color{r: 255, g: 200, b: 50})
	}
	g.spiders.clear()

	for flea in g.fleas {
		fx := playfield_offset_x + f64(flea.col) * tile_size + 10.0
		g.add_score(200, fx, flea.y)
		g.spawn_particles(fx, flea.y, 15, Color{r: 100, g: 255, b: 100})
	}
	g.fleas.clear()

	for scorp in g.scorpions {
		sy := playfield_offset_y + f64(scorp.row) * tile_size + 10.0
		g.add_score(1000, scorp.x, sy)
		g.spawn_particles(scorp.x, sy, 20, Color{r: 255, g: 80, b: 255})
	}
	g.scorpions.clear()

	// Clear poison mushrooms
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			if g.grid[r][c].exists && g.grid[r][c].is_poison {
				g.grid[r][c].is_poison = false
				mx := playfield_offset_x + f64(c) * tile_size + 10.0
				my := playfield_offset_y + f64(r) * tile_size + 10.0
				g.spawn_particles(mx, my, 5, Color{r: 180, g: 80, b: 255})
			}
		}
	}
}

fn (mut g CentipedeGame) player_fire(sound_mgr &SoundManager) {
	if !g.player.is_alive || g.player.fire_cooldown > 0.0 {
		return
	}

	cooldown := if g.timer_rapid_fire > 0.0 { 0.08 } else { 0.18 }
	g.player.fire_cooldown = cooldown

	is_plasma := g.timer_plasma_beam > 0.0
	if is_plasma {
		sound_mgr.play_plasma_sound()
	} else {
		sound_mgr.play_laser_sound()
	}

	if g.timer_triple_shot > 0.0 {
		g.lasers << Laser{
			x: g.player.x
			y: g.player.y - 12.0
			dx: 0.0
			dy: -550.0
			is_plasma: is_plasma
		}
		g.lasers << Laser{
			x: g.player.x - 6.0
			y: g.player.y - 12.0
			dx: -120.0
			dy: -520.0
			is_plasma: is_plasma
		}
		g.lasers << Laser{
			x: g.player.x + 6.0
			y: g.player.y - 12.0
			dx: 120.0
			dy: -520.0
			is_plasma: is_plasma
		}
	} else {
		g.lasers << Laser{
			x: g.player.x
			y: g.player.y - 12.0
			dx: 0.0
			dy: -550.0
			is_plasma: is_plasma
		}
	}
}

fn (mut g CentipedeGame) move_player(dx f64, dy f64, dt f64) {
	if !g.player.is_alive {
		return
	}

	speed_mult := if g.timer_speed_dash > 0.0 { 1.6 } else { 1.0 }
	move_dist := g.player.speed * speed_mult * dt

	g.player.x += dx * move_dist
	g.player.y += dy * move_dist

	// Clamp within playfield boundaries & Player Zone (rows 24..29)
	min_x := playfield_offset_x + g.player.radius
	max_x := playfield_offset_x + playfield_width - g.player.radius
	min_y := playfield_offset_y + (24.0 * tile_size) + g.player.radius
	max_y := playfield_offset_y + playfield_height - g.player.radius

	if g.player.x < min_x { g.player.x = min_x }
	if g.player.x > max_x { g.player.x = max_x }
	if g.player.y < min_y { g.player.y = min_y }
	if g.player.y > max_y { g.player.y = max_y }

	if g.timer_speed_dash > 0.0 && (dx != 0.0 || dy != 0.0) {
		g.spawn_particles(g.player.x, g.player.y, 1, Color{r: 255, g: 255, b: 120})
	}
}

fn (mut g CentipedeGame) update_centipedes(dt f64, sound_mgr &SoundManager) {
	for chain_idx := g.chains.len - 1; chain_idx >= 0; chain_idx-- {
		mut chain := &g.chains[chain_idx]
		if chain.segments.len == 0 {
			g.chains.delete(chain_idx)
			continue
		}

		for seg_idx in 0 .. chain.segments.len {
			mut seg := &chain.segments[seg_idx]

			// Move sub_x / sub_y
			move_step := seg.speed * dt
			if seg.is_poisoned {
				// Dive straight down
				seg.sub_y += move_step * 1.5
				if seg.sub_y >= 1.0 {
					seg.sub_y -= 1.0
					seg.row++
					if seg.row >= grid_rows - 1 {
						seg.row = grid_rows - 1
						seg.is_poisoned = false // reached bottom, resume normal movement
						seg.dir_y = -1 // bounce up
					}
				}
			} else {
				// Horizontal movement
				seg.sub_x += f64(seg.dir_x) * move_step
				if seg.sub_x >= 1.0 || seg.sub_x <= 0.0 {
					next_col := seg.col + seg.dir_x
					must_turn := next_col < 0 || next_col >= grid_cols || (next_col >= 0 && next_col < grid_cols && seg.row >= 0 && seg.row < grid_rows && g.grid[seg.row][next_col].exists)

					if must_turn {
						// Check if hit poison mushroom
						if next_col >= 0 && next_col < grid_cols && seg.row >= 0 && seg.row < grid_rows && g.grid[seg.row][next_col].exists && g.grid[seg.row][next_col].is_poison {
							seg.is_poisoned = true
						} else {
							// Move vertically 1 row
							next_row := seg.row + seg.dir_y
							if next_row >= grid_rows {
								seg.row = grid_rows - 1
								seg.dir_y = -1 // bounce back up into player zone
							} else if next_row < 24 && seg.dir_y == -1 {
								seg.row = 24
								seg.dir_y = 1 // bounce back down
							} else if next_row >= 0 && next_row < grid_rows {
								seg.row = next_row
							}
							seg.dir_x = -seg.dir_x
						}

						if seg.dir_x > 0 { seg.sub_x = 0.0 } else { seg.sub_x = 1.0 }
					} else {
						seg.col = next_col
						if seg.dir_x > 0 { seg.sub_x = 0.0 } else { seg.sub_x = 1.0 }
					}
				}
			}

			// Check player collision
			if g.player.is_alive && g.timer_shield <= 0.0 {
				seg_world_x := playfield_offset_x + (f64(seg.col) + seg.sub_x) * tile_size
				seg_world_y := playfield_offset_y + (f64(seg.row) + seg.sub_y) * tile_size
				dx := seg_world_x - g.player.x
				dy := seg_world_y - g.player.y
				if math.sqrt(dx * dx + dy * dy) < (g.player.radius + 8.0) {
					g.kill_player(sound_mgr)
				}
			}
		}
	}
}

fn (mut g CentipedeGame) update_fleas(dt f64, sound_mgr &SoundManager) {
	for i := g.fleas.len - 1; i >= 0; i-- {
		g.fleas[i].y += g.fleas[i].speed * dt
		r := int((g.fleas[i].y - playfield_offset_y) / tile_size)
		c := g.fleas[i].col

		if r >= 0 && r < grid_rows && c >= 0 && c < grid_cols {
			if !g.grid[r][c].exists {
				if (rand.intn(100) or { 0 }) < 15 {
					g.grid[r][c] = Mushroom{exists: true, hp: 4}
				}
			}
		}

		// Check player collision
		if g.player.is_alive && g.timer_shield <= 0.0 {
			fx := playfield_offset_x + f64(c) * tile_size + 10.0
			dx := fx - g.player.x
			dy := g.fleas[i].y - g.player.y
			if math.sqrt(dx * dx + dy * dy) < (g.player.radius + 10.0) {
				g.kill_player(sound_mgr)
			}
		}

		if g.fleas[i].y > playfield_offset_y + playfield_height + 20.0 {
			g.fleas.delete(i)
		}
	}
}

fn (mut g CentipedeGame) update_spiders(dt f64, sound_mgr &SoundManager) {
	for i := g.spiders.len - 1; i >= 0; i-- {
		g.spiders[i].timer += dt
		if g.spiders[i].timer > 0.4 {
			g.spiders[i].timer = 0.0
			g.spiders[i].dir_y = if (rand.intn(2) or { 0 }) == 0 { 1.0 } else { -1.0 }
		}

		g.spiders[i].x += g.spiders[i].dir_x * g.spiders[i].speed * dt
		g.spiders[i].y += g.spiders[i].dir_y * g.spiders[i].speed * dt

		// Clamp Y within player zone
		min_y := playfield_offset_y + 24.0 * tile_size
		max_y := playfield_offset_y + playfield_height - 10.0
		if g.spiders[i].y < min_y {
			g.spiders[i].y = min_y
			g.spiders[i].dir_y = 1.0
		}
		if g.spiders[i].y > max_y {
			g.spiders[i].y = max_y
			g.spiders[i].dir_y = -1.0
		}

		// Devour mushrooms
		sr := int((g.spiders[i].y - playfield_offset_y) / tile_size)
		sc := int((g.spiders[i].x - playfield_offset_x) / tile_size)
		if sr >= 0 && sr < grid_rows && sc >= 0 && sc < grid_cols {
			if g.grid[sr][sc].exists {
				g.grid[sr][sc].exists = false
			}
		}

		// Check player collision
		if g.player.is_alive && g.timer_shield <= 0.0 {
			dx := g.spiders[i].x - g.player.x
			dy := g.spiders[i].y - g.player.y
			if math.sqrt(dx * dx + dy * dy) < (g.player.radius + 12.0) {
				g.kill_player(sound_mgr)
			}
		}

		// Despawn off sides
		if g.spiders[i].x < playfield_offset_x - 40.0 || g.spiders[i].x > playfield_offset_x + playfield_width + 40.0 {
			g.spiders.delete(i)
		}
	}
}

fn (mut g CentipedeGame) update_scorpions(dt f64, sound_mgr &SoundManager) {
	for i := g.scorpions.len - 1; i >= 0; i-- {
		g.scorpions[i].x += g.scorpions[i].dir_x * g.scorpions[i].speed * dt
		sy := playfield_offset_y + f64(g.scorpions[i].row) * tile_size + 10.0

		// Poison mushrooms in path
		sc := int((g.scorpions[i].x - playfield_offset_x) / tile_size)
		sr := g.scorpions[i].row
		if sr >= 0 && sr < grid_rows && sc >= 0 && sc < grid_cols {
			if g.grid[sr][sc].exists && !g.grid[sr][sc].is_poison {
				g.grid[sr][sc].is_poison = true
			}
		}

		// Check player collision
		if g.player.is_alive && g.timer_shield <= 0.0 {
			dx := g.scorpions[i].x - g.player.x
			dy := sy - g.player.y
			if math.sqrt(dx * dx + dy * dy) < (g.player.radius + 12.0) {
				g.kill_player(sound_mgr)
			}
		}

		if g.scorpions[i].x < playfield_offset_x - 40.0 || g.scorpions[i].x > playfield_offset_x + playfield_width + 40.0 {
			g.scorpions.delete(i)
		}
	}
}

fn (mut g CentipedeGame) kill_player(sound_mgr &SoundManager) {
	if !g.player.is_alive || g.timer_shield > 0.0 {
		return
	}
	g.player.is_alive = false
	g.lives--
	g.player.respawn_timer = 1.5
	g.shake_trauma = math.min(1.0, g.shake_trauma + 0.65)
	sound_mgr.play_explosion_sound()
	g.spawn_particles(g.player.x, g.player.y, 30, Color{r: 255, g: 80, b: 80})

	if g.lives <= 0 {
		g.game_over = true
	}
}

fn (mut g CentipedeGame) check_collisions(sound_mgr &SoundManager) {
	for l_idx := g.lasers.len - 1; l_idx >= 0; l_idx-- {
		mut laser := &g.lasers[l_idx]
		if !laser.active {
			continue
		}

		// 1. Grid Mushroom Collision
		grid_c := int((laser.x - playfield_offset_x) / tile_size)
		grid_r := int((laser.y - playfield_offset_y) / tile_size)

		if grid_r >= 0 && grid_r < grid_rows && grid_c >= 0 && grid_c < grid_cols {
			if g.grid[grid_r][grid_c].exists {
				sound_mgr.play_hit_sound()
				if laser.is_plasma {
					g.grid[grid_r][grid_c].hp = 0
				} else {
					g.grid[grid_r][grid_c].hp--
					laser.active = false
				}

				if g.grid[grid_r][grid_c].hp <= 0 {
					// Mushroom destroyed!
					if g.grid[grid_r][grid_c].has_powerup {
						mx := playfield_offset_x + f64(grid_c) * tile_size + 10.0
						my := playfield_offset_y + f64(grid_r) * tile_size + 10.0
						g.powerups << DroppedPowerUp{
							x: mx
							y: my
							ptype: g.grid[grid_r][grid_c].powerup_type
						}
					}
					g.grid[grid_r][grid_c].exists = false
					g.add_score(1, laser.x, laser.y)
					g.spawn_particles(laser.x, laser.y, 6, Color{r: 100, g: 255, b: 150})
				}
				if !laser.active {
					g.lasers.delete(l_idx)
					continue
				}
			}
		}

		// 2. Centipede Segment Collision
		mut hit_seg := false
		for chain_idx := g.chains.len - 1; chain_idx >= 0; chain_idx-- {
			mut chain := &g.chains[chain_idx]
			for seg_idx := chain.segments.len - 1; seg_idx >= 0; seg_idx-- {
				seg := chain.segments[seg_idx]
				seg_x := playfield_offset_x + (f64(seg.col) + seg.sub_x) * tile_size
				seg_y := playfield_offset_y + (f64(seg.row) + seg.sub_y) * tile_size

				dx := laser.x - seg_x
				dy := laser.y - seg_y
				if math.sqrt(dx * dx + dy * dy) < 12.0 {
					sound_mgr.play_hit_sound()
					if !laser.is_plasma {
						laser.active = false
					}

					// Shot segment!
					hit_seg = true
					if seg.is_head {
						g.shake_trauma = math.min(1.0, g.shake_trauma + 0.15)
						g.add_score(100, seg_x, seg_y)
					} else {
						g.shake_trauma = math.min(1.0, g.shake_trauma + 0.08)
						g.add_score(10, seg_x, seg_y)
					}

					g.spawn_particles(seg_x, seg_y, 12, Color{r: 255, g: 100, b: 50})

					// Convert segment to Mushroom
					if seg.row >= 0 && seg.row < grid_rows && seg.col >= 0 && seg.col < grid_cols {
						g.grid[seg.row][seg.col] = Mushroom{exists: true, hp: 4}
					}

					// Split centipede chain into two if middle segment!
					// Segments before seg_idx remain in original chain.
					// Segments after seg_idx form a new chain, with the element right after seg_idx becoming a HEAD!
					mut has_new_tail := false
					mut new_tail := []CentipedeSegment{}
					if seg_idx + 1 < chain.segments.len {
						new_tail = chain.segments[seg_idx + 1..chain.segments.len].clone()
						if new_tail.len > 0 {
							new_tail[0].is_head = true
							has_new_tail = true
						}
					}

					chain.segments.trim(seg_idx)
					if chain.segments.len == 0 {
						g.chains.delete(chain_idx)
					}
					if has_new_tail {
						g.chains << CentipedeChain{segments: new_tail}
					}

					break
				}
			}
			if hit_seg {
				break
			}
		}

		if hit_seg && !laser.active {
			g.lasers.delete(l_idx)
			continue
		}

		// 3. Fleas Collision
		for f_idx := g.fleas.len - 1; f_idx >= 0; f_idx-- {
			fx := playfield_offset_x + f64(g.fleas[f_idx].col) * tile_size + 10.0
			dx := laser.x - fx
			dy := laser.y - g.fleas[f_idx].y
			if math.sqrt(dx * dx + dy * dy) < 14.0 {
				sound_mgr.play_hit_sound()
				if !laser.is_plasma { laser.active = false }
				g.fleas[f_idx].hp--
				if g.fleas[f_idx].hp <= 0 {
					g.shake_trauma = math.min(1.0, g.shake_trauma + 0.16)
					g.add_score(200, fx, g.fleas[f_idx].y)
					g.spawn_particles(fx, g.fleas[f_idx].y, 15, Color{r: 80, g: 255, b: 120})
					g.fleas.delete(f_idx)
				}
				break
			}
		}
		if !laser.active {
			g.lasers.delete(l_idx)
			continue
		}

		// 4. Spiders Collision
		for s_idx := g.spiders.len - 1; s_idx >= 0; s_idx-- {
			dx := laser.x - g.spiders[s_idx].x
			dy := laser.y - g.spiders[s_idx].y
			if math.sqrt(dx * dx + dy * dy) < 16.0 {
				sound_mgr.play_explosion_sound()
				if !laser.is_plasma { laser.active = false }

				// Score based on distance to player
				p_dist := math.sqrt((g.spiders[s_idx].x - g.player.x) * (g.spiders[s_idx].x - g.player.x) + (g.spiders[s_idx].y - g.player.y) * (g.spiders[s_idx].y - g.player.y))
				pts := if p_dist < 60.0 { 900 } else if p_dist < 120.0 { 600 } else { 300 }

				g.shake_trauma = math.min(1.0, g.shake_trauma + 0.22)
				g.add_score(pts, g.spiders[s_idx].x, g.spiders[s_idx].y)
				g.spawn_particles(g.spiders[s_idx].x, g.spiders[s_idx].y, 20, Color{r: 255, g: 220, b: 50})
				g.spiders.delete(s_idx)
				break
			}
		}
		if !laser.active {
			g.lasers.delete(l_idx)
			continue
		}

		// 5. Scorpions Collision
		for sc_idx := g.scorpions.len - 1; sc_idx >= 0; sc_idx-- {
			sy := playfield_offset_y + f64(g.scorpions[sc_idx].row) * tile_size + 10.0
			dx := laser.x - g.scorpions[sc_idx].x
			dy := laser.y - sy
			if math.sqrt(dx * dx + dy * dy) < 16.0 {
				sound_mgr.play_explosion_sound()
				if !laser.is_plasma { laser.active = false }
				g.shake_trauma = math.min(1.0, g.shake_trauma + 0.25)
				g.add_score(1000, g.scorpions[sc_idx].x, sy)
				g.spawn_particles(g.scorpions[sc_idx].x, sy, 20, Color{r: 255, g: 80, b: 255})
				g.scorpions.delete(sc_idx)
				break
			}
		}

		if !laser.active {
			g.lasers.delete(l_idx)
		}
	}
}

fn (mut g CentipedeGame) handle_enemy_spawns(dt f64, sound_mgr &SoundManager) {
	// Flea Spawn: check player zone mushroom density
	g.flea_spawn_timer -= dt
	if g.flea_spawn_timer <= 0.0 {
		g.flea_spawn_timer = 5.0 + rand.f64() * 4.0
		mut player_mushrooms := 0
		for r in 24 .. grid_rows {
			for c in 0 .. grid_cols {
				if g.grid[r][c].exists {
					player_mushrooms++
				}
			}
		}
		if player_mushrooms < 6 && g.fleas.len < 2 {
			f_col := rand.intn(grid_cols) or { 0 }
			g.fleas << Flea{
				col: f_col
				y: playfield_offset_y
				hp: 2
				active: true
			}
			sound_mgr.play_flea_drop_sound()
		}
	}

	// Spider Spawn
	g.spider_spawn_timer -= dt
	if g.spider_spawn_timer <= 0.0 {
		g.spider_spawn_timer = 4.0 + rand.f64() * 5.0
		if g.spiders.len < 2 {
			from_left := (rand.intn(2) or { 0 }) == 0
			sx := if from_left { playfield_offset_x - 10.0 } else { playfield_offset_x + playfield_width + 10.0 }
			sy := playfield_offset_y + (24.0 + rand.f64() * 5.0) * tile_size
			s_dir := if from_left { 1.0 } else { -1.0 }
			g.spiders << Spider{
				x: sx
				y: sy
				dir_x: s_dir
				dir_y: 1.0
				timer: 0.0
				active: true
			}
			sound_mgr.play_spider_hop_sound()
		}
	}

	// Scorpion Spawn (Wave 2+)
	if g.wave >= 2 {
		g.scorpion_spawn_timer -= dt
		if g.scorpion_spawn_timer <= 0.0 {
			g.scorpion_spawn_timer = 7.0 + rand.f64() * 6.0
			if g.scorpions.len < 1 {
				from_left := (rand.intn(2) or { 0 }) == 0
				sx := if from_left { playfield_offset_x - 10.0 } else { playfield_offset_x + playfield_width + 10.0 }
				s_row := 3 + (rand.intn(18) or { 0 })
				s_dir := if from_left { 1.0 } else { -1.0 }
				g.scorpions << Scorpion{
					row: s_row
					x: sx
					dir_x: s_dir
					active: true
				}
				sound_mgr.play_scorpion_sound()
			}
		}
	}
}

fn (mut g CentipedeGame) regenerate_mushrooms() {
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			if g.grid[r][c].exists {
				if g.grid[r][c].hp < 4 || g.grid[r][c].is_poison {
					g.grid[r][c].hp = 4
					g.grid[r][c].is_poison = false
					g.score += 5
					mx := playfield_offset_x + f64(c) * tile_size + 10.0
					my := playfield_offset_y + f64(r) * tile_size + 10.0
					g.spawn_particles(mx, my, 3, Color{r: 255, g: 255, b: 255})
				}
			}
		}
	}
}

fn (mut g CentipedeGame) spawn_particles(x f64, y f64, count int, color Color) {
	for _ in 0 .. count {
		angle := rand.f64() * 2.0 * math.pi
		speed := 30.0 + rand.f64() * 120.0
		life := 0.2 + rand.f64() * 0.4
		g.particles << Particle{
			x: x
			y: y
			dx: math.cos(angle) * speed
			dy: math.sin(angle) * speed
			life: life
			max_life: life
			color: color
		}
	}
}
