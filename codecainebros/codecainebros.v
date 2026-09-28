module main

import math
import rand

pub const gravity = 640.0
pub const max_run_speed = 260.0
pub const run_accel = 750.0
pub const friction = 680.0

pub enum GameState {
	title
	playing
	bonus_phase
	phase_clear
	game_over
	paused
}

pub enum GameMode {
	single_player
	two_players
}

pub enum EnemyType {
	shellcreeper // Turtle
	sidestepper  // Crab (takes 2 hits)
	fighterfly   // Jumping fly
	slipice      // Ice monster
	fireball     // Green/Red fireball
}

pub enum EnemyState {
	spawning
	walking
	angry      // Crab enraged (speed x1.8)
	stunned    // Flipped on back
	recovering // Flashing/wiggling about to right itself
	kicked     // Hit by player, flying away
	in_pipe    // Traveling inside pipe
}

pub enum PowerUpType {
	star
	fire_flower
}

pub struct Platform {
pub:
	x      f32
	y      f32
	w      f32
	h      f32
	is_ice bool
}

pub struct BumpWave {
pub mut:
	x        f32
	y        f32
	radius   f32 = 40.0
	timer    f32 = 0.22
	duration f32 = 0.22
	active   bool = true
}

pub struct Shockwave {
pub mut:
	x        f32
	y        f32
	radius   f32   = 10.0
	max_r    f32   = 450.0
	timer    f32   = 0.45
	duration f32   = 0.45
	color    Color = Color{ r: 80, g: 190, b: 255, a: 255 }
	active   bool  = true
}

pub enum DripType {
	water
	toxic_waste
	sludge
}

pub struct WaterDrip {
pub mut:
	x         f32
	y         f32
	vy        f32 = 140.0
	drip_type DripType = .water
	target_y  f32 = 540.0
	color     Color = Color{ r: 90, g: 200, b: 255, a: 220 }
	active    bool = true
}

pub struct Player {
pub mut:
	id           int // 1 = Mario, 2 = Luigi
	x            f32
	y            f32
	vx           f32
	vy           f32
	width        f32 = 28.0
	height       f32 = 36.0
	facing_right bool = true
	is_grounded  bool
	is_jumping   bool
	is_skidding  bool
	is_dead      bool
	dead_timer   f32
	invuln_timer f32
	score        int
	lives        int = 3
	anim_timer   f32
	walk_frame   int
	combo_count  int
	combo_timer  f32
	// Enhancements
	star_timer   f32 // Super Star Invincibility (seconds)
	has_fire     bool // Fire Flower Power
	charge_timer f32 // Down charge for super spring jump
	is_charged   bool
}

pub struct Enemy {
pub mut:
	id           int
	enemy_type   EnemyType
	state        EnemyState
	x            f32
	y            f32
	vx           f32
	vy           f32
	width        f32 = 28.0
	height       f32 = 28.0
	facing_right bool = true
	is_grounded  bool
	stun_timer   f32
	angry_level  int // 0 = normal, 1 = angry for crab
	hop_timer    f32 // For Fighter Fly
	anim_timer   f32
	pipe_timer   f32
	pipe_target  int // 0 = top left, 1 = top right
	active       bool = true
}

pub struct SlidingShell {
pub mut:
	x           f32
	y           f32
	vx          f32
	vy          f32
	width       f32 = 28.0
	height      f32 = 22.0
	is_grounded bool
	anim_timer  f32
	life_timer  f32 = 12.0
	combo       int = 1
	active      bool = true
}

pub struct PlayerFireball {
pub mut:
	player_id   int
	x           f32
	y           f32
	vx          f32
	vy          f32
	width       f32 = 14.0
	height      f32 = 14.0
	bounces     int
	life_timer  f32 = 3.5
	anim_timer  f32
	active      bool = true
}

pub struct PowerUp {
pub mut:
	power_type  PowerUpType
	x           f32
	y           f32
	vx          f32
	vy          f32
	width       f32 = 24.0
	height      f32 = 24.0
	is_grounded bool
	anim_timer  f32
	active      bool = true
}

pub struct Coin {
pub mut:
	x           f32
	y           f32
	vx          f32
	vy          f32
	width       f32 = 20.0
	height      f32 = 20.0
	is_grounded bool
	anim_timer  f32
	life_timer  f32 = 14.0
	active      bool = true
}

pub struct ScorePopup {
pub mut:
	x      f32
	y      f32
	text   string
	color  Color
	timer  f32 = 0.9
	active bool = true
}

pub struct Particle {
pub mut:
	x      f32
	y      f32
	vx     f32
	vy     f32
	color  Color
	life   f32
	max_l  f32
	size   f32
	active bool = true
}

pub struct PowBlock {
pub mut:
	x           f32 = 376.0
	y           f32 = 384.0
	w           f32 = 48.0
	h           f32 = 32.0
	hits_left   int = 3
	active      bool = true
	shake_timer f32
}

pub struct MarioBrosGame {
pub mut:
	state              GameState = .title
	mode               GameMode  = .single_player
	phase              int       = 1
	high_score         int       = 20000
	players            []Player
	enemies            []Enemy
	sliding_shells     []SlidingShell
	player_fireballs   []PlayerFireball
	powerups           []PowerUp
	coins              []Coin
	platforms          []Platform
	bump_waves         []BumpWave
	shockwaves         []Shockwave
	water_drips        []WaterDrip
	score_popups       []ScorePopup
	particles          []Particle
	pow_block          PowBlock
	sound_mgr          SoundManager
	spawn_timer        f32
	enemies_left       int
	total_in_phase     int
	screen_shake       f32
	shake_offset_x     f32
	shake_offset_y     f32
	phase_timer        f32
	bonus_timer        f32
	fireball_timer     f32
	drip_spawn_timer   f32
	phase_banner_timer f32
	combo_banner       string
	combo_banner_timer f32
	crt_filter         bool = true
	// Controls
	p1_left            bool
	p1_right           bool
	p1_up              bool
	p1_down            bool
	p1_jump            bool
	p1_fire            bool
	p1_fire_cooldown   f32
	p2_left            bool
	p2_right           bool
	p2_up              bool
	p2_down            bool
	p2_jump            bool
	p2_fire            bool
	p2_fire_cooldown   f32
}

pub fn new_mario_bros_game() MarioBrosGame {
	mut g := MarioBrosGame{
		sound_mgr: new_sound_manager()
	}
	g.init_platforms()
	g.reset_to_title()
	return g
}

pub fn (mut g MarioBrosGame) init_platforms() {
	g.platforms.clear()
	// Ground floor
	g.platforms << Platform{ x: 0.0, y: 540.0, w: 800.0, h: 60.0, is_ice: false }

	// Tier 1 (Top)
	g.platforms << Platform{ x: 0.0, y: 160.0, w: 340.0, h: 22.0, is_ice: false }
	g.platforms << Platform{ x: 460.0, y: 160.0, w: 340.0, h: 22.0, is_ice: false }

	// Tier 2 (Middle)
	g.platforms << Platform{ x: 170.0, y: 290.0, w: 460.0, h: 22.0, is_ice: false }

	// Tier 3 (Lower)
	g.platforms << Platform{ x: 0.0, y: 416.0, w: 320.0, h: 22.0, is_ice: false }
	g.platforms << Platform{ x: 480.0, y: 416.0, w: 320.0, h: 22.0, is_ice: false }
}

pub fn (mut g MarioBrosGame) reset_to_title() {
	g.state = .title
	g.players.clear()
	g.enemies.clear()
	g.sliding_shells.clear()
	g.player_fireballs.clear()
	g.powerups.clear()
	g.coins.clear()
	g.bump_waves.clear()
	g.shockwaves.clear()
	g.water_drips.clear()
	g.score_popups.clear()
	g.particles.clear()
}

pub fn (mut g MarioBrosGame) start_game(mode GameMode) {
	g.mode = mode
	g.phase = 1
	g.players.clear()
	g.enemies.clear()
	g.sliding_shells.clear()
	g.player_fireballs.clear()
	g.powerups.clear()
	g.coins.clear()
	g.bump_waves.clear()
	g.shockwaves.clear()
	g.particles.clear()

	// Player 1: Mario (Starts bottom-left)
	g.players << Player{
		id:           1
		x:            180.0
		y:            504.0
		vx:           0.0
		vy:           0.0
		facing_right: true
		is_grounded:  true
		lives:        3
	}

	// Player 2: Luigi (Starts bottom-right)
	if mode == .two_players {
		g.players << Player{
			id:           2
			x:            590.0
			y:            504.0
			vx:           0.0
			vy:           0.0
			facing_right: false
			is_grounded:  true
			lives:        3
		}
	}

	g.pow_block = PowBlock{
		hits_left: 3
		active:    true
	}

	g.setup_phase(1)
}

pub fn (mut g MarioBrosGame) setup_phase(phase int) {
	g.phase = phase
	g.enemies.clear()
	g.sliding_shells.clear()
	g.player_fireballs.clear()
	g.powerups.clear()
	g.coins.clear()
	g.bump_waves.clear()
	g.shockwaves.clear()
	g.particles.clear()

	// Recharge POW block slightly on new phase
	if !g.pow_block.active || g.pow_block.hits_left < 3 {
		g.pow_block.active = true
		g.pow_block.hits_left = math.min(3, g.pow_block.hits_left + 1)
	}

	// Reset player positions on phase start
	if g.players.len > 0 {
		g.players[0].x = 180.0
		g.players[0].y = 504.0
		g.players[0].vx = 0.0
		g.players[0].vy = 0.0
		g.players[0].is_grounded = true
		g.players[0].invuln_timer = 2.5
	}
	if g.players.len > 1 {
		g.players[1].x = 590.0
		g.players[1].y = 504.0
		g.players[1].vx = 0.0
		g.players[1].vy = 0.0
		g.players[1].is_grounded = true
		g.players[1].invuln_timer = 2.5
	}

	// Phase 3, 8, 13 etc are Bonus Coin Phases
	if phase % 5 == 3 {
		g.state = .bonus_phase
		g.bonus_timer = 20.0
		g.spawn_bonus_coins()
		g.sound_mgr.play_phase_clear()
		return
	}

	g.state = .playing
	g.phase_banner_timer = 2.2
	g.spawn_timer = 1.0

	// Calculate enemy counts based on phase difficulty
	count := 4 + phase * 2
	g.total_in_phase = count
	g.enemies_left = count

	g.sound_mgr.play_phase_clear()

	// Chance to spawn a Star or Fire Flower power-up
	if phase >= 2 {
		g.spawn_powerup(if phase % 2 == 0 { PowerUpType.star } else { PowerUpType.fire_flower })
	}
}

pub fn (mut g MarioBrosGame) spawn_bonus_coins() {
	g.coins.clear()
	// 10 coins positioned across all platforms
	spots := [
		[100.0, 128.0],
		[220.0, 128.0],
		[540.0, 128.0],
		[660.0, 128.0],
		[270.0, 258.0],
		[390.0, 258.0],
		[510.0, 258.0],
		[140.0, 384.0],
		[640.0, 384.0],
		[390.0, 508.0],
	]
	for sp in spots {
		g.coins << Coin{
			x:           f32(sp[0])
			y:           f32(sp[1])
			vx:          0.0
			vy:          0.0
			is_grounded: true
			anim_timer:  f32(rand.intn(100) or { 0 }) / 100.0
			active:      true
		}
	}
}

pub fn (mut g MarioBrosGame) spawn_powerup(p_type PowerUpType) {
	pipe_side := rand.intn(2) or { 0 }
	spawn_x := if pipe_side == 0 { f32(60.0) } else { f32(740.0) }
	dir := if pipe_side == 0 { f32(110.0) } else { f32(-110.0) }
	g.powerups << PowerUp{
		power_type:  p_type
		x:           spawn_x
		y:           86.0
		vx:          dir
		vy:          -60.0
		is_grounded: false
		active:      true
	}
	g.sound_mgr.play_powerup()
}

pub fn (mut g MarioBrosGame) spawn_enemy() {
	if g.enemies_left <= 0 {
		return
	}
	g.enemies_left--

	// Determine enemy type based on phase
	mut e_type := EnemyType.shellcreeper
	r := rand.intn(100) or { 0 }

	if g.phase == 1 {
		e_type = .shellcreeper
	} else if g.phase == 2 {
		e_type = if r < 50 { EnemyType.shellcreeper } else { EnemyType.sidestepper }
	} else if g.phase == 3 {
		e_type = if r < 35 { EnemyType.shellcreeper } else if r < 70 { EnemyType.sidestepper } else { EnemyType.fighterfly }
	} else {
		if r < 30 {
			e_type = .shellcreeper
		} else if r < 60 {
			e_type = .sidestepper
		} else if r < 85 {
			e_type = .fighterfly
		} else {
			e_type = .slipice
		}
	}

	pipe_side := rand.intn(2) or { 0 }
	spawn_x := if pipe_side == 0 { f32(20.0) } else { f32(750.0) }
	target_dir := pipe_side == 0

	mut enemy := Enemy{
		id:           g.total_in_phase - g.enemies_left
		enemy_type:   e_type
		state:        .walking
		x:            spawn_x
		y:            86.0
		vx:           if target_dir { f32(100.0) } else { f32(-100.0) }
		vy:           0.0
		facing_right: target_dir
		is_grounded:  false
		active:       true
	}

	if e_type == .sidestepper {
		enemy.vx *= 1.15
	} else if e_type == .fighterfly {
		enemy.hop_timer = 0.8
	}

	g.enemies << enemy
	g.sound_mgr.play_pipe()
}

pub fn (mut g MarioBrosGame) spawn_fireball() {
	pipe_side := rand.intn(2) or { 0 }
	spawn_x := if pipe_side == 0 { f32(-20.0) } else { f32(820.0) }
	vy_level := f32(180 + (rand.intn(3) or { 0 }) * 125)

	g.enemies << Enemy{
		id:           999
		enemy_type:   .fireball
		state:        .walking
		x:            spawn_x
		y:            vy_level
		vx:           if pipe_side == 0 { f32(160.0) } else { f32(-160.0) }
		vy:           0.0
		facing_right: pipe_side == 0
		active:       true
	}
}

pub fn (mut g MarioBrosGame) trigger_bump_wave(bx f32, by f32) {
	g.bump_waves << BumpWave{
		x: bx
		y: by
	}
	g.sound_mgr.play_bump()

	// Check grounded enemies above this bump wave
	for mut e in g.enemies {
		if !e.active || e.state == .kicked || e.state == .in_pipe {
			continue
		}
		if e.is_grounded && math.abs(e.y + e.height - by) < 18.0 && math.abs(e.x + e.width * 0.5 - bx) < 55.0 {
			g.hit_enemy_from_below(mut e)
		}
	}
}

pub fn (mut g MarioBrosGame) hit_pow_block() {
	if !g.pow_block.active || g.pow_block.hits_left <= 0 {
		return
	}
	g.pow_block.hits_left--
	g.pow_block.shake_timer = 0.35
	g.screen_shake = 0.4
	g.sound_mgr.play_pow()

	g.shockwaves << Shockwave{
		x: g.pow_block.x + g.pow_block.w * 0.5
		y: g.pow_block.y + g.pow_block.h * 0.5
	}

	for mut e in g.enemies {
		if !e.active || e.state == .kicked || e.state == .in_pipe {
			continue
		}
		if e.is_grounded {
			g.hit_enemy_from_below(mut e)
		}
	}

	if g.pow_block.hits_left <= 0 {
		g.pow_block.active = false
	}
}

pub fn (mut g MarioBrosGame) hit_enemy_from_below(mut e Enemy) {
	// If the enemy is already turned over (stunned or recovering), hitting it from below flips it back upright and dangerous!
	if e.state == .stunned || e.state == .recovering {
		e.stun_timer = 0.0
		e.is_grounded = false
		e.vy = -240.0
		rec_dir := if e.facing_right { f32(1.0) } else { f32(-1.0) }
		if e.enemy_type == .sidestepper {
			e.state = .angry
			e.angry_level = 1
			e.vx = rec_dir * (150.0 + f32(g.phase * 8))
		} else {
			e.state = .walking
			e.vx = rec_dir * (120.0 + f32(g.phase * 8))
			if e.enemy_type == .fighterfly {
				e.hop_timer = 0.5
			}
		}
		g.sound_mgr.play_bump()
		g.add_particles(e.x + e.width * 0.5, e.y + e.height * 0.5, 8, Color{ r: 255, g: 120, b: 60, a: 220 })
		return
	}

	if e.enemy_type == .sidestepper {
		if e.state == .walking {
			e.state = .angry
			e.angry_level = 1
			// Bound up with forward momentum in an enraged arc!
			dir_mult := if e.facing_right { f32(1.25) } else { f32(-1.25) }
			e.vx = math.abs(e.vx) * dir_mult
			e.vy = -260.0
			e.is_grounded = false
			g.sound_mgr.play_bump()
			g.add_score_popup(e.x, e.y - 10.0, 'ANGRY!', Color{ r: 255, g: 80, b: 80, a: 255 })
			g.add_particles(e.x + e.width * 0.5, e.y + e.height * 0.5, 8, Color{ r: 255, g: 100, b: 100, a: 220 })
			return
		}
	}

	e.state = .stunned
	e.stun_timer = 6.0
	// Bound up preserving horizontal momentum onto back in a forward arc!
	if math.abs(e.vx) > 10.0 {
		e.vx = e.vx * 1.2
	} else {
		e.vx = if e.facing_right { f32(50.0) } else { f32(-50.0) }
	}
	e.vy = -275.0
	e.is_grounded = false
	g.sound_mgr.play_flip()
	g.add_particles(e.x + e.width * 0.5, e.y + e.height * 0.5, 8, Color{ r: 255, g: 220, b: 60, a: 200 })
}

pub fn (mut g MarioBrosGame) fire_player_fireball(p_id int, px f32, py f32, facing_right bool) {
	dir := if facing_right { f32(360.0) } else { f32(-360.0) }
	g.player_fireballs << PlayerFireball{
		player_id:  p_id
		x:          if facing_right { px + 28.0 } else { px - 14.0 }
		y:          py + 10.0
		vx:         dir
		vy:         -40.0
		active:     true
	}
	g.sound_mgr.play_fireball()
}

pub fn (mut g MarioBrosGame) add_score_popup(x f32, y f32, text string, color Color) {
	g.score_popups << ScorePopup{
		x:     x
		y:     y
		text:  text
		color: color
	}
}

pub fn (mut g MarioBrosGame) add_particles(x f32, y f32, count int, color Color) {
	for _ in 0 .. count {
		angle := f32(rand.intn(360) or { 0 }) * f32(math.pi) / 180.0
		speed := f32(rand.intn(160) or { 60 }) + 30.0
		g.particles << Particle{
			x:      x
			y:      y
			vx:     f32(math.cos(angle)) * speed
			vy:     f32(math.sin(angle)) * speed
			color:  color
			life:   0.3 + f32(rand.intn(30) or { 0 }) / 100.0
			max_l:  0.6
			size:   f32((rand.intn(3) or { 0 }) + 2)
			active: true
		}
	}
}

pub fn (g &MarioBrosGame) find_ground_below(x f32, start_y f32) f32 {
	mut lowest_y := f32(540.0)
	for plat in g.platforms {
		if plat.y > start_y + 4.0 && plat.y < lowest_y {
			if x >= plat.x && x <= plat.x + plat.w {
				lowest_y = plat.y
			}
		}
	}
	return lowest_y
}

pub fn (mut g MarioBrosGame) spawn_ambient_drip() {
	roll := rand.intn(100) or { 0 }
	if roll < 45 {
		// Pipe drip: oozing waste / toxic green from one of the 4 pipes
		pipe_idx := rand.intn(4) or { 0 }
		mut px := f32(82.0)
		mut py := f32(130.0)
		match pipe_idx {
			0 { px = 82.0; py = 130.0 }
			1 { px = 718.0; py = 130.0 }
			2 { px = 82.0; py = 536.0 }
			else { px = 718.0; py = 536.0 }
		}
		target := g.find_ground_below(px, py)
		is_toxic := (rand.intn(2) or { 0 }) == 0
		d_type := if is_toxic { DripType.toxic_waste } else { DripType.sludge }
		d_color := if is_toxic {
			Color{ r: 70, g: 255, b: 50, a: 240 }
		} else {
			Color{ r: 190, g: 150, b: 35, a: 230 }
		}
		g.water_drips << WaterDrip{
			x:         px
			y:         py
			vy:        90.0
			drip_type: d_type
			target_y:  target
			color:     d_color
			active:    true
		}
	} else if roll < 80 {
		// Platform underside water drip
		mut spawned := false
		if g.platforms.len > 0 {
			plat_idx := rand.intn(g.platforms.len) or { 0 }
			plat := g.platforms[plat_idx]
			if plat.h < 30.0 { // Upper platform
				px := plat.x + 10.0 + f32(rand.intn(int(math.max(1.0, plat.w - 20.0))) or { 0 })
				py := plat.y + plat.h
				target := g.find_ground_below(px, py)
				g.water_drips << WaterDrip{
					x:         px
					y:         py
					vy:        70.0
					drip_type: .water
					target_y:  target
					color:     Color{ r: 90, g: 200, b: 255, a: 220 }
					active:    true
				}
				spawned = true
			}
		}
		if !spawned {
			px := f32(40.0) + f32(rand.intn(720) or { 0 })
			py := f32(6.0)
			target := g.find_ground_below(px, py)
			g.water_drips << WaterDrip{
				x:         px
				y:         py
				vy:        110.0
				drip_type: .water
				target_y:  target
				color:     Color{ r: 90, g: 200, b: 255, a: 220 }
				active:    true
			}
		}
	} else {
		// Ceiling sewer drop
		px := f32(40.0) + f32(rand.intn(720) or { 0 })
		py := f32(6.0)
		target := g.find_ground_below(px, py)
		g.water_drips << WaterDrip{
			x:         px
			y:         py
			vy:        110.0
			drip_type: .water
			target_y:  target
			color:     Color{ r: 100, g: 210, b: 255, a: 220 }
			active:    true
		}
	}
}

pub fn (mut g MarioBrosGame) add_splash(x f32, y f32, d_type DripType) {
	count := (rand.intn(3) or { 0 }) + 3
	for _ in 0 .. count {
		vx := f32(rand.intn(140) or { 70 }) - 70.0
		vy := -f32(rand.intn(90) or { 45 }) - 50.0
		c := match d_type {
			.toxic_waste {
				if (rand.intn(2) or { 0 }) == 0 {
					Color{ r: 80, g: 255, b: 60, a: 230 }
				} else {
					Color{ r: 190, g: 255, b: 90, a: 255 }
				}
			}
			.sludge {
				if (rand.intn(2) or { 0 }) == 0 {
					Color{ r: 190, g: 150, b: 35, a: 230 }
				} else {
					Color{ r: 240, g: 200, b: 70, a: 240 }
				}
			}
			else {
				if (rand.intn(2) or { 0 }) == 0 {
					Color{ r: 110, g: 210, b: 255, a: 220 }
				} else {
					Color{ r: 210, g: 245, b: 255, a: 255 }
				}
			}
		}
		g.particles << Particle{
			x:      x
			y:      y - 2.0
			vx:     vx
			vy:     vy
			color:  c
			life:   0.22 + f32(rand.intn(18) or { 0 }) / 100.0
			max_l:  0.4
			size:   f32((rand.intn(2) or { 0 }) + 2)
			active: true
		}
	}
}

pub fn (mut g MarioBrosGame) update(dt f32) {
	// 1. Screen Shake Decay
	if g.screen_shake > 0.0 {
		g.screen_shake -= dt
		mag := g.screen_shake * 14.0
		g.shake_offset_x = (f32(rand.intn(200) or { 100 }) / 100.0 - 1.0) * mag
		g.shake_offset_y = (f32(rand.intn(200) or { 100 }) / 100.0 - 1.0) * mag
	} else {
		g.shake_offset_x = 0.0
		g.shake_offset_y = 0.0
	}

	// 2. Cooldowns
	if g.p1_fire_cooldown > 0.0 {
		g.p1_fire_cooldown -= dt
	}
	if g.p2_fire_cooldown > 0.0 {
		g.p2_fire_cooldown -= dt
	}

	if g.state != .playing && g.state != .bonus_phase {
		return
	}

	// 3. Spawners
	if g.state == .playing {
		g.phase_timer += dt
		g.spawn_timer -= dt
		if g.spawn_timer <= 0.0 && g.enemies_left > 0 {
			g.spawn_enemy()
			g.spawn_timer = f32(math.max(1.8, 3.8 - f64(g.phase) * 0.25))
		}

		g.fireball_timer -= dt
		if g.fireball_timer <= 0.0 && g.phase >= 2 {
			g.spawn_fireball()
			g.fireball_timer = f32(math.max(5.0, 14.0 - f64(g.phase) * 0.6))
		}
	} else if g.state == .bonus_phase {
		g.bonus_timer -= dt
		if g.bonus_timer <= 0.0 || g.coins.len == 0 {
			g.next_phase()
			return
		}
	}

	// 4. Update Players
	for mut p in g.players {
		if p.is_dead {
			p.dead_timer -= dt
			p.vy += gravity * dt
			p.y += p.vy * dt
			if p.dead_timer <= 0.0 {
				if p.lives > 0 {
					p.is_dead = false
					p.x = if p.id == 1 { f32(180.0) } else { f32(590.0) }
					p.y = 504.0
					p.vx = 0.0
					p.vy = 0.0
					p.is_grounded = true
					p.invuln_timer = 3.0
				} else {
					g.check_game_over()
				}
			}
			continue
		}

		if p.invuln_timer > 0.0 {
			p.invuln_timer -= dt
		}

		if p.star_timer > 0.0 {
			p.star_timer -= dt
			// Star sparkles
			if (rand.intn(2) or { 0 }) == 0 {
				g.add_particles(p.x + p.width * 0.5, p.y + p.height * 0.5, 1, Color{
					r: u8(rand.intn(255) or { 255 })
					g: u8(rand.intn(255) or { 255 })
					b: u8(rand.intn(255) or { 255 })
					a: 220
				})
			}
		}

		if p.combo_timer > 0.0 {
			p.combo_timer -= dt
			if p.combo_timer <= 0.0 {
				p.combo_count = 0
			}
		}

		// Input handling
		left_pressed := if p.id == 1 { g.p1_left } else { g.p2_left }
		right_pressed := if p.id == 1 { g.p1_right } else { g.p2_right }
		down_pressed := if p.id == 1 { g.p1_down } else { g.p2_down }
		jump_pressed := if p.id == 1 { g.p1_jump } else { g.p2_jump }
		fire_pressed := if p.id == 1 { g.p1_fire } else { g.p2_fire }

		// Super Spring Jump Charge
		if down_pressed && p.is_grounded {
			p.charge_timer += dt
			if p.charge_timer > 0.3 {
				p.is_charged = true
				// Charging sparks
				if (rand.intn(3) or { 0 }) == 0 {
					g.add_particles(p.x + p.width * 0.5, p.y + p.height, 1, Color{ r: 255, g: 255, b: 60, a: 220 })
				}
			}
		} else {
			p.charge_timer = 0.0
			p.is_charged = false
		}

		// Fireball Shooting
		if fire_pressed && p.has_fire {
			if p.id == 1 && g.p1_fire_cooldown <= 0.0 {
				g.fire_player_fireball(1, p.x, p.y, p.facing_right)
				g.p1_fire_cooldown = 0.28
			} else if p.id == 2 && g.p2_fire_cooldown <= 0.0 {
				g.fire_player_fireball(2, p.x, p.y, p.facing_right)
				g.p2_fire_cooldown = 0.28
			}
		}

		// Horizontal Movement & Accel
		speed_mult := if p.star_timer > 0.0 { f32(1.5) } else { f32(1.0) }
		target_max := max_run_speed * speed_mult

		if left_pressed && !right_pressed {
			p.vx -= run_accel * dt
			if p.vx < -target_max {
				p.vx = -target_max
			}
			p.facing_right = false
			p.is_skidding = p.vx > 30.0
		} else if right_pressed && !left_pressed {
			p.vx += run_accel * dt
			if p.vx > target_max {
				p.vx = target_max
			}
			p.facing_right = true
			p.is_skidding = p.vx < -30.0
		} else {
			p.is_skidding = false
			if p.vx > 0.0 {
				p.vx -= friction * dt
				if p.vx < 0.0 {
					p.vx = 0.0
				}
			} else if p.vx < 0.0 {
				p.vx += friction * dt
				if p.vx > 0.0 {
					p.vx = 0.0
				}
			}
		}

		// Jump (Normal or Super Spring Jump!)
		if jump_pressed && p.is_grounded && !p.is_jumping {
			if p.is_charged {
				p.vy = -680.0 // Massive Super Spring Jump!
				g.sound_mgr.play_super_jump()
				g.add_particles(p.x + p.width * 0.5, p.y + p.height, 8, Color{ r: 255, g: 255, b: 100, a: 220 })
				g.add_score_popup(p.x, p.y - 12.0, 'SPRING JUMP!', Color{ r: 255, g: 240, b: 80, a: 255 })
			} else {
				p.vy = -480.0
				g.sound_mgr.play_jump()
				g.add_particles(p.x + p.width * 0.5, p.y + p.height, 4, Color{ r: 180, g: 180, b: 200, a: 180 })
			}
			p.is_grounded = false
			p.is_jumping = true
			p.is_charged = false
			p.charge_timer = 0.0
		}

		// Gravity
		p.vy += gravity * dt
		if p.vy > 480.0 {
			p.vy = 480.0
		}

		// Apply velocity
		old_y := p.y
		p.x += p.vx * dt
		p.y += p.vy * dt

		// Screen Wrap-Around
		if p.x < -p.width {
			p.x = 800.0
		} else if p.x > 800.0 {
			p.x = -p.width
		}

		// Platform Collision
		p.is_grounded = false
		for plat in g.platforms {
			// Land on top
			if old_y + p.height <= plat.y + 4.0 && p.y + p.height >= plat.y {
				if p.x + p.width > plat.x && p.x < plat.x + plat.w {
					p.y = plat.y - p.height
					p.vy = 0.0
					p.is_grounded = true
					p.is_jumping = false
				}
			}
			// Head bump underneath platform!
			else if p.vy < 0.0 && old_y >= plat.y + plat.h - 6.0 && p.y <= plat.y + plat.h {
				if p.x + p.width + 4.0 > plat.x && p.x - 4.0 < plat.x + plat.w {
					p.y = plat.y + plat.h
					p.vy = 40.0
					g.trigger_bump_wave(p.x + p.width * 0.5, plat.y)
				}
			}
		}

		// POW Block top landing / bottom bumping
		if g.pow_block.active && g.pow_block.hits_left > 0 {
			pb := g.pow_block
			if old_y + p.height <= pb.y + 4.0 && p.y + p.height >= pb.y {
				if p.x + p.width > pb.x && p.x < pb.x + pb.w {
					p.y = pb.y - p.height
					p.vy = 0.0
					p.is_grounded = true
					p.is_jumping = false
				}
			} else if p.vy < 0.0 && old_y >= pb.y + pb.h - 4.0 && p.y <= pb.y + pb.h {
				if p.x + p.width > pb.x && p.x < pb.x + pb.w {
					p.y = pb.y + pb.h
					p.vy = 40.0
					g.hit_pow_block()
				}
			}
		}

		// Animation frame stepping
		if math.abs(p.vx) > 10.0 {
			p.anim_timer += dt * 10.0
			p.walk_frame = int(p.anim_timer) % 4
		} else {
			p.walk_frame = 0
		}

		// High score sync
		if p.score > g.high_score {
			g.high_score = p.score
		}
	}

	// 5. Update Sliding Shells (Bowling Attacks!)
	for mut sh in g.sliding_shells {
		if !sh.active {
			continue
		}
		sh.anim_timer += dt * 18.0
		sh.life_timer -= dt
		if sh.life_timer <= 0.0 {
			sh.active = false
			continue
		}

		sh.vy += gravity * dt
		old_shy := sh.y
		sh.x += sh.vx * dt
		sh.y += sh.vy * dt

		// Trail particles
		if (rand.intn(2) or { 0 }) == 0 {
			g.add_particles(sh.x + sh.width * 0.5, sh.y + sh.height - 2.0, 1, Color{ r: 80, g: 230, b: 90, a: 180 })
		}

		// Screen Wrap-Around
		if sh.x < -sh.width {
			sh.x = 800.0
		} else if sh.x > 800.0 {
			sh.x = -sh.width
		}

		// Platform landing
		sh.is_grounded = false
		for plat in g.platforms {
			if old_shy + sh.height <= plat.y + 6.0 && sh.y + sh.height >= plat.y {
				if sh.x + sh.width > plat.x && sh.x < plat.x + plat.w {
					sh.y = plat.y - sh.height
					sh.vy = 0.0
					sh.is_grounded = true
				}
			}
		}

		// Check Sliding Shell hitting Enemies (Bowling them down!)
		for mut e in g.enemies {
			if !e.active || e.state == .kicked || e.state == .in_pipe {
				continue
			}
			if sh.x + sh.width > e.x && sh.x < e.x + e.width && sh.y + sh.height > e.y && sh.y < e.y + e.height {
				e.state = .kicked
				e.vx = sh.vx * 0.7
				e.vy = -340.0
				g.sound_mgr.play_shell_kick()
				g.screen_shake = 0.2

				pts := 800 * sh.combo
				sh.combo++
				if g.players.len > 0 {
					g.players[0].score += pts
				}
				g.add_score_popup(e.x, e.y, '+${pts}', Color{ r: 255, g: 240, b: 60, a: 255 })
				g.add_particles(e.x + e.width * 0.5, e.y + e.height * 0.5, 12, Color{ r: 255, g: 215, b: 0, a: 220 })
			}
		}
	}

	// 6. Update Player Fireballs
	for mut fb in g.player_fireballs {
		if !fb.active {
			continue
		}
		fb.anim_timer += dt * 14.0
		fb.life_timer -= dt
		if fb.life_timer <= 0.0 {
			fb.active = false
			continue
		}

		fb.vy += gravity * dt
		old_fby := fb.y
		fb.x += fb.vx * dt
		fb.y += fb.vy * dt

		// Fire spark trail
		g.add_particles(fb.x + fb.width * 0.5, fb.y + fb.height * 0.5, 1, Color{ r: 255, g: 120, b: 20, a: 200 })

		if fb.x < -fb.width || fb.x > 800.0 {
			fb.active = false
			continue
		}

		// Platform Bouncing
		for plat in g.platforms {
			if old_fby + fb.height <= plat.y + 6.0 && fb.y + fb.height >= plat.y {
				if fb.x + fb.width > plat.x && fb.x < plat.x + plat.w {
					fb.y = plat.y - fb.height
					fb.vy = -220.0 // Bounce upward!
					fb.bounces++
					if fb.bounces > 5 {
						fb.active = false
					}
				}
			}
		}

		// Check Fireball hitting Enemies -> Flips them on their back!
		for mut e in g.enemies {
			if !e.active || e.state == .kicked || e.state == .in_pipe || e.enemy_type == .fireball {
				continue
			}
			if fb.x + fb.width > e.x && fb.x < e.x + e.width && fb.y + fb.height > e.y && fb.y < e.y + e.height {
				fb.active = false
				g.hit_enemy_from_below(mut e)
				g.add_particles(e.x + e.width * 0.5, e.y + e.height * 0.5, 8, Color{ r: 255, g: 140, b: 30, a: 220 })
				break
			}
		}
	}

	// 7. Update Power-Ups (Starman & Fire Flower)
	for mut pu in g.powerups {
		if !pu.active {
			continue
		}
		pu.anim_timer += dt * 6.0
		pu.vy += gravity * dt
		old_puy := pu.y
		pu.x += pu.vx * dt
		pu.y += pu.vy * dt

		// Screen Wrap-Around
		if pu.x < -pu.width {
			pu.x = 800.0
		} else if pu.x > 800.0 {
			pu.x = -pu.width
		}

		// Platform Bouncing for Starman & Flower
		pu.is_grounded = false
		for plat in g.platforms {
			if old_puy + pu.height <= plat.y + 6.0 && pu.y + pu.height >= plat.y {
				if pu.x + pu.width > plat.x && pu.x < plat.x + plat.w {
					pu.y = plat.y - pu.height
					pu.vy = if pu.power_type == .star { f32(-280.0) } else { f32(0.0) }
					pu.is_grounded = true
				}
			}
		}

		// Check Player collecting Power-Up!
		for mut p in g.players {
			if p.is_dead {
				continue
			}
			if p.x + p.width > pu.x && p.x < pu.x + pu.width && p.y + p.height > pu.y && p.y < pu.y + pu.height {
				pu.active = false
				if pu.power_type == .star {
					p.star_timer = 10.0
					g.sound_mgr.play_star_power()
					g.add_score_popup(p.x, p.y - 12.0, 'STAR POWER!', Color{ r: 255, g: 215, b: 0, a: 255 })
				} else {
					p.has_fire = true
					g.sound_mgr.play_powerup()
					g.add_score_popup(p.x, p.y - 12.0, 'FIRE FLOWER!', Color{ r: 255, g: 120, b: 40, a: 255 })
				}
				p.score += 1000
				g.add_particles(p.x + p.width * 0.5, p.y + p.height * 0.5, 16, Color{ r: 255, g: 255, b: 120, a: 255 })
			}
		}
	}

	// 8. Update Enemies
	for mut e in g.enemies {
		if !e.active {
			continue
		}

		// Kicked enemy flying out of stage
		if e.state == .kicked {
			e.vy += gravity * dt
			e.x += e.vx * dt
			e.y += e.vy * dt
			if e.y > 620.0 {
				e.active = false
			}
			continue
		}

		// In pipe transit
		if e.state == .in_pipe {
			e.pipe_timer -= dt
			if e.pipe_timer <= 0.0 {
				e.state = .walking
				e.x = if e.pipe_target == 0 { f32(40.0) } else { f32(760.0) }
				e.y = 86.0
				e.facing_right = e.pipe_target == 0
				e_dir := if e.facing_right { f32(1.0) } else { f32(-1.0) }
				e.vx = e_dir * (100.0 + f32(g.phase * 8))
				e.vy = 0.0
				g.sound_mgr.play_pipe()
			}
			continue
		}

		// Stun timer & recovery
		if e.state == .stunned || e.state == .recovering {
			e.stun_timer -= dt
			if e.stun_timer < 2.2 && e.state == .stunned {
				e.state = .recovering
			}
			if e.stun_timer <= 0.0 {
				e.state = if e.enemy_type == .sidestepper { .angry } else { .walking }
				rec_dir := if e.facing_right { f32(1.0) } else { f32(-1.0) }
				e.vx = rec_dir * (130.0 + f32(g.phase * 8))
				e.vy = -140.0
				e.is_grounded = false
			}

			// Friction damping while lying on back
			if e.is_grounded {
				if math.abs(e.vx) > 3.0 {
					e.vx -= (e.vx * 4.5) * dt
				} else {
					e.vx = 0.0
				}
			}
		}

		// Fighter Fly hopping mechanics
		if e.enemy_type == .fighterfly && (e.state == .walking || e.state == .angry) {
			if e.is_grounded {
				e.hop_timer -= dt
				if e.hop_timer <= 0.0 {
					e.vy = -280.0
					e.is_grounded = false
					e.hop_timer = 0.9
					g.add_particles(e.x + e.width * 0.5, e.y + e.height, 3, Color{ r: 170, g: 150, b: 220, a: 160 })
				}
			}
		}

		// Fireball sinusoidal motion
		if e.enemy_type == .fireball {
			e.anim_timer += dt * 8.0
			e.y += f32(math.sin(f64(e.anim_timer)) * 3.0)
			e.x += e.vx * dt
			if (rand.intn(2) or { 0 }) == 0 {
				g.add_particles(e.x + 14.0, e.y + 14.0, 1, Color{ r: 255, g: 140, b: 20, a: 180 })
			}
			if e.x < -40.0 || e.x > 840.0 {
				e.active = false
			}
			continue
		}

		// Gravity
		e.vy += gravity * dt
		if e.vy > 550.0 {
			e.vy = 550.0
		}

		old_ey := e.y
		// Preserve horizontal motion in air or while sliding onto back
		if !e.is_grounded || (e.state != .stunned && e.state != .recovering) || math.abs(e.vx) > 2.0 {
			e.x += e.vx * dt
		}
		e.y += e.vy * dt

		// Screen Wrap-Around for enemies
		if e.x < -e.width {
			e.x = 800.0
		} else if e.x > 800.0 {
			e.x = -e.width
		}

		// Bottom pipe entry
		if e.is_grounded && e.y >= 500.0 && (e.state == .walking || e.state == .angry) {
			if e.x < 50.0 && !e.facing_right {
				e.state = .in_pipe
				e.pipe_timer = 2.0
				e.pipe_target = 1
				g.sound_mgr.play_pipe()
				continue
			} else if e.x > 720.0 && e.facing_right {
				e.state = .in_pipe
				e.pipe_timer = 2.0
				e.pipe_target = 0
				g.sound_mgr.play_pipe()
				continue
			}
		}

		// Platform collision for enemies
		e.is_grounded = false
		for plat in g.platforms {
			if old_ey + e.height <= plat.y + 6.0 && e.y + e.height >= plat.y {
				if e.x + e.width > plat.x && e.x < plat.x + plat.w {
					e.y = plat.y - e.height
					// Bounce if landing fast on its back!
					if (e.state == .stunned || e.state == .recovering) && e.vy > 180.0 {
						e.vy = -e.vy * 0.35
						g.add_particles(e.x + e.width * 0.5, plat.y, 4, Color{ r: 210, g: 210, b: 210, a: 160 })
					} else {
						e.vy = 0.0
						e.is_grounded = true
					}
				}
			}
		}
	}

	// 9. Enemy-to-Enemy Collisions (Bouncing off upside-down & head-on)
	for i := 0; i < g.enemies.len; i++ {
		if !g.enemies[i].active || g.enemies[i].state == .kicked || g.enemies[i].state == .in_pipe || g.enemies[i].enemy_type == .fireball {
			continue
		}
		for j := i + 1; j < g.enemies.len; j++ {
			if !g.enemies[j].active || g.enemies[j].state == .kicked || g.enemies[j].state == .in_pipe || g.enemies[j].enemy_type == .fireball {
				continue
			}

			e1_left := g.enemies[i].x
			e1_right := g.enemies[i].x + g.enemies[i].width
			e1_bottom := g.enemies[i].y + g.enemies[i].height

			e2_left := g.enemies[j].x
			e2_right := g.enemies[j].x + g.enemies[j].width
			e2_bottom := g.enemies[j].y + g.enemies[j].height

			if math.abs(f64(e1_bottom - e2_bottom)) < 18.0 && e1_right > e2_left && e1_left < e2_right {
				e1_flipped := g.enemies[i].state == .stunned || g.enemies[i].state == .recovering
				e2_flipped := g.enemies[j].state == .stunned || g.enemies[j].state == .recovering

				e1_moving := g.enemies[i].state == .walking || g.enemies[i].state == .angry
				e2_moving := g.enemies[j].state == .walking || g.enemies[j].state == .angry

				if e1_flipped && e2_moving {
					if e2_left < e1_left {
						g.enemies[j].facing_right = false
						g.enemies[j].vx = -math.abs(g.enemies[j].vx)
						g.enemies[j].x = e1_left - g.enemies[j].width - 1.0
					} else {
						g.enemies[j].facing_right = true
						g.enemies[j].vx = math.abs(g.enemies[j].vx)
						g.enemies[j].x = e1_right + 1.0
					}
					g.sound_mgr.play_bump()
				} else if e2_flipped && e1_moving {
					if e1_left < e2_left {
						g.enemies[i].facing_right = false
						g.enemies[i].vx = -math.abs(g.enemies[i].vx)
						g.enemies[i].x = e2_left - g.enemies[i].width - 1.0
					} else {
						g.enemies[i].facing_right = true
						g.enemies[i].vx = math.abs(g.enemies[i].vx)
						g.enemies[i].x = e2_right + 1.0
					}
					g.sound_mgr.play_bump()
				} else if e1_moving && e2_moving {
					if (e1_left < e2_left && g.enemies[i].vx > 0 && g.enemies[j].vx < 0) ||
					   (e2_left < e1_left && g.enemies[j].vx > 0 && g.enemies[i].vx < 0) {
						g.enemies[i].facing_right = !g.enemies[i].facing_right
						g.enemies[i].vx = -g.enemies[i].vx
						g.enemies[j].facing_right = !g.enemies[j].facing_right
						g.enemies[j].vx = -g.enemies[j].vx

						if e1_left < e2_left {
							g.enemies[i].x = e2_left - g.enemies[i].width - 1.0
							g.enemies[j].x = e2_left + 1.0
						} else {
							g.enemies[j].x = e1_left - g.enemies[j].width - 1.0
							g.enemies[i].x = e1_left + 1.0
						}
						g.sound_mgr.play_bump()
					}
				}
			}
		}
	}

	// 10. Update Coins
	for mut c in g.coins {
		if !c.active {
			continue
		}
		c.life_timer -= dt
		if c.life_timer <= 0.0 {
			c.active = false
			continue
		}
		c.anim_timer += dt * 8.0

		c.vy += gravity * dt
		if c.vy > 500.0 {
			c.vy = 500.0
		}

		old_cy := c.y
		c.x += c.vx * dt
		c.y += c.vy * dt

		if c.x < -c.width {
			c.x = 800.0
		} else if c.x > 800.0 {
			c.x = -c.width
		}

		c.is_grounded = false
		for plat in g.platforms {
			if old_cy + c.height <= plat.y + 6.0 && c.y + c.height >= plat.y {
				if c.x + c.width > plat.x && c.x < plat.x + plat.w {
					c.y = plat.y - c.height
					c.vy = 0.0
					c.is_grounded = true
				}
			}
		}
	}

	// 11. Player-Enemy & Player-Coin Collisions
	for mut p in g.players {
		if p.is_dead {
			continue
		}

		// Check Coin Collection (Magnetic responsive hitbox)
		for mut c in g.coins {
			if !c.active {
				continue
			}
			if p.x + p.width + 4.0 > c.x && p.x - 4.0 < c.x + c.width && p.y + p.height + 4.0 > c.y && p.y - 4.0 < c.y + c.height {
				c.active = false
				p.score += 800
				g.sound_mgr.play_coin()
				g.add_score_popup(c.x, c.y, '800', Color{ r: 255, g: 240, b: 60, a: 255 })
				g.add_particles(c.x + c.width * 0.5, c.y + c.height * 0.5, 8, Color{ r: 255, g: 215, b: 0, a: 255 })
			}
		}

		// Check Enemy Interaction
		for mut e in g.enemies {
			if !e.active || e.state == .kicked || e.state == .in_pipe {
				continue
			}

			// Generous hitbox for kicking stunned/recovering enemies or star invincible rush
			is_stunned := e.state == .stunned || e.state == .recovering
			if is_stunned || p.star_timer > 0.0 {
				if p.x + p.width > e.x && p.x < e.x + e.width && p.y + p.height > e.y && p.y < e.y + e.height {
					// STAR POWER INVINCIBLE RUSH!
					if p.star_timer > 0.0 {
						e.state = .kicked
						e.vx = if p.facing_right { f32(350.0) } else { f32(-350.0) }
						e.vy = -380.0
						g.sound_mgr.play_kick()
						p.score += 1000
						g.add_score_popup(e.x, e.y, 'STAR 1000!', Color{ r: 255, g: 255, b: 80, a: 255 })
						g.add_particles(e.x + e.width * 0.5, e.y + e.height * 0.5, 14, Color{ r: 255, g: 200, b: 40, a: 255 })
						continue
					}

					// Kicking a turtle shell launches a Sliding Shell!
					if e.enemy_type == .shellcreeper {
						e.active = false
						sh_vx := if p.facing_right { f32(400.0) } else { f32(-400.0) }
						g.sliding_shells << SlidingShell{
							x:           e.x
							y:           e.y + 6.0
							vx:          sh_vx
							vy:          0.0
							is_grounded: true
							active:      true
						}
						g.sound_mgr.play_shell_kick()
					} else {
						e.state = .kicked
						kick_dir := if p.facing_right { f32(300.0) } else { f32(-300.0) }
						e.vx = kick_dir
						e.vy = -320.0
						g.sound_mgr.play_kick()
					}

					// Combo multiplier
					p.combo_count++
					p.combo_timer = 2.0
					pts := match p.combo_count {
						1 { 800 }
						2 { 1600 }
						3 { 2400 }
						else { 3200 }
					}
					p.score += pts
					g.add_score_popup(e.x, e.y, '${pts}', Color{ r: 255, g: 255, b: 255, a: 255 })

					if p.combo_count >= 2 {
						g.combo_banner = '${p.combo_count}x COMBO!'
						g.combo_banner_timer = 1.2
					}

					// Spawn Gold Coin from kicked enemy
					g.coins << Coin{
						x:           e.x
						y:           e.y
						vx:          if p.facing_right { f32(120.0) } else { f32(-120.0) }
						vy:          -300.0
						is_grounded: false
						anim_timer:  0.0
						active:      true
					}
				}
				continue
			}

			// Active dangerous enemies: precision inset hurtbox (avoids unfair clipping)
			p_hurt_l := p.x + 5.0
			p_hurt_r := p.x + p.width - 5.0
			p_hurt_t := p.y + 4.0
			p_hurt_b := p.y + p.height - 2.0

			e_hurt_l := e.x + 3.0
			e_hurt_r := e.x + e.width - 3.0
			e_hurt_t := e.y + 3.0
			e_hurt_b := e.y + e.height

			if p_hurt_r > e_hurt_l && p_hurt_l < e_hurt_r && p_hurt_b > e_hurt_t && p_hurt_t < e_hurt_b {
				if (e.state == .walking || e.state == .angry || e.enemy_type == .fireball || e.enemy_type == .slipice) && p.invuln_timer <= 0.0 {
					p.is_dead = true
					p.dead_timer = 2.5
					p.vy = -450.0
					p.lives--
					p.has_fire = false
					p.star_timer = 0.0
					g.sound_mgr.play_die()
					g.screen_shake = 0.3
					g.add_particles(p.x + p.width * 0.5, p.y + p.height * 0.5, 16, Color{ r: 255, g: 60, b: 60, a: 255 })
				}
			}
		}
	}

	// 12. Update Particles, Water Drips, Shockwaves
	for mut pt in g.particles {
		if !pt.active {
			continue
		}
		pt.life -= dt
		if pt.life <= 0.0 {
			pt.active = false
			continue
		}
		pt.vy += 380.0 * dt
		pt.x += pt.vx * dt
		pt.y += pt.vy * dt
	}

	// Ambient Sewer Drips & Waste Drops
	g.drip_spawn_timer -= dt
	if g.drip_spawn_timer <= 0.0 {
		g.drip_spawn_timer = 0.16 + f32(rand.intn(22) or { 10 }) / 100.0
		if g.water_drips.len < 32 {
			g.spawn_ambient_drip()
		}
	}

	for mut wd in g.water_drips {
		if !wd.active {
			continue
		}
		wd.vy += 320.0 * dt
		wd.y += wd.vy * dt
		if wd.y >= wd.target_y {
			wd.active = false
			g.add_splash(wd.x, wd.target_y, wd.drip_type)
		}
	}

	for mut sw in g.shockwaves {
		if !sw.active {
			continue
		}
		sw.timer -= dt
		if sw.timer <= 0.0 {
			sw.active = false
			continue
		}
		progress := 1.0 - sw.timer / sw.duration
		sw.radius = sw.max_r * progress
	}

	for mut bw in g.bump_waves {
		if !bw.active {
			continue
		}
		bw.timer -= dt
		if bw.timer <= 0.0 {
			bw.active = false
		}
	}

	for mut sp in g.score_popups {
		if !sp.active {
			continue
		}
		sp.timer -= dt
		sp.y -= 45.0 * dt
		if sp.timer <= 0.0 {
			sp.active = false
		}
	}

	// Filter inactive items
	g.particles = g.particles.filter(it.active)
	g.water_drips = g.water_drips.filter(it.active)
	g.shockwaves = g.shockwaves.filter(it.active)
	g.bump_waves = g.bump_waves.filter(it.active)
	g.score_popups = g.score_popups.filter(it.active)
	g.coins = g.coins.filter(it.active)
	g.sliding_shells = g.sliding_shells.filter(it.active)
	g.player_fireballs = g.player_fireballs.filter(it.active)
	g.powerups = g.powerups.filter(it.active)

	// Check Phase Victory (all enemies cleared)
	if g.state == .playing {
		mut active_enemies := 0
		for e in g.enemies {
			if e.active {
				active_enemies++
			}
		}
		if g.enemies_left <= 0 && active_enemies == 0 {
			g.state = .phase_clear
			g.sound_mgr.play_phase_clear()
		}
	}
}

pub fn (mut g MarioBrosGame) next_phase() {
	g.setup_phase(g.phase + 1)
}

pub fn (mut g MarioBrosGame) check_game_over() {
	mut all_dead := true
	for p in g.players {
		if p.lives > 0 || !p.is_dead {
			all_dead = false
			break
		}
	}
	if all_dead {
		g.state = .game_over
	}
}
