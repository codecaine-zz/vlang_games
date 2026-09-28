module main

import math
import rand

const world_w = 800
const world_h = 600
pub const max_level = 5
const max_lives = 5

enum BrickType {
	normal
	armored
	steel
	tnt
	mystery
}

struct Brick {
pub mut:
	x      int
	y      int
	w      int
	h      int
	hp     int
	max_hp int
	kind   BrickType
	color  Color
	alive  bool
}

enum PowerUpType {
	multiball
	expand_paddle
	laser_paddle
	sticky_paddle
	fireball
	slow_ball
	bottom_shield
	extra_life
}

struct Capsule {
pub mut:
	x     f64
	y     f64
	dy    f64 = 140.0
	kind  PowerUpType
	w     int = 26
	h     int = 14
	timer f64 = 12.0
}

struct Ball {
pub mut:
	x        f64
	y        f64
	dx       f64
	dy       f64
	radius   f64 = 6.0
	attached bool
	offset_x f64
}

struct Paddle {
pub mut:
	x              f64 = world_w / 2.0 - 50.0
	y              f64 = 540.0
	w              f64 = 100.0
	h              f64 = 14.0
	base_w         f64 = 100.0
	laser_timer    f64
	has_lasers     bool
	sticky_catches int
	has_sticky     bool
	expand_timer   f64
	fireball_timer f64
	slowball_timer f64
	laser_cooldown f64
}

struct LaserBeam {
pub mut:
	x  f64
	y  f64
	dy f64 = -650.0
}

struct BreakoutGame {
pub mut:
	paddle               Paddle
	balls                []Ball
	bricks               []Brick
	capsules             []Capsule
	lasers               []LaserBeam
	score                int
	lives                int  = 3
	level                int  = 1
	bottom_shield_active bool
	game_over            bool
	level_cleared        bool
	combo_multiplier     int  = 1
	last_sound_event     string
	last_sound_param     f64
	shake_trauma         f64
}

fn new_breakout_game() BreakoutGame {
	mut game := BreakoutGame{}
	game.reset()
	return game
}

fn (mut g BreakoutGame) reset() {
	g.score = 0
	g.lives = 3
	g.level = 1
	g.game_over = false
	g.level_cleared = false
	g.bottom_shield_active = false
	g.reset_round()
	g.load_level(g.level)
}

fn (mut g BreakoutGame) reset_round() {
	g.paddle = Paddle{
		x:      world_w / 2.0 - 50.0
		y:      540.0
		w:      100.0
		h:      14.0
		base_w: 100.0
	}
	g.balls = [
		Ball{
			x:        world_w / 2.0
			y:        525.0
			dx:       220.0
			dy:       -320.0
			attached: true
			offset_x: 50.0
		},
	]
	g.capsules.clear()
	g.lasers.clear()
	g.combo_multiplier = 1
}

fn (mut g BreakoutGame) load_level(lvl int) {
	g.bricks.clear()
	g.level_cleared = false
	g.reset_round()

	cols := 10
	brick_w := 70
	brick_h := 20
	padding_x := 5
	padding_y := 6
	start_x := (world_w - (cols * (brick_w + padding_x))) / 2

	match lvl {
		1 {
			// Classic Rainbow Grid
			rows := 5
			colors := [
				Color{r: 255, g: 60, b: 60},
				Color{r: 255, g: 160, b: 0},
				Color{r: 255, g: 220, b: 0},
				Color{r: 0, g: 220, b: 100},
				Color{r: 0, g: 180, b: 255},
			]

			for r in 0 .. rows {
				for c in 0 .. cols {
					x := start_x + c * (brick_w + padding_x)
					y := 80 + r * (brick_h + padding_y)
					kind := if (r + c) % 7 == 0 { BrickType.mystery } else { BrickType.normal }
					g.bricks << Brick{
						x:      x
						y:      y
						w:      brick_w
						h:      brick_h
						hp:     1
						max_hp: 1
						kind:   kind
						color:  colors[r % colors.len]
						alive:  true
					}
				}
			}
		}
		2 {
			// Diamond Pyramid
			colors := [
				Color{r: 255, g: 80, b: 180},
				Color{r: 0, g: 230, b: 255},
				Color{r: 255, g: 200, b: 0},
			]
			for r in 0 .. 7 {
				c_start := math.abs(3 - r)
				c_end := cols - c_start
				for c in c_start .. c_end {
					x := start_x + c * (brick_w + padding_x)
					y := 60 + r * (brick_h + padding_y)
					kind := if r == 3 && (c == 4 || c == 5) {
						BrickType.mystery
					} else if r % 2 == 0 {
						BrickType.armored
					} else {
						BrickType.normal
					}
					hp := if kind == .armored { 2 } else { 1 }
					g.bricks << Brick{
						x:      x
						y:      y
						w:      brick_w
						h:      brick_h
						hp:     hp
						max_hp: hp
						kind:   kind
						color:  colors[r % colors.len]
						alive:  true
					}
				}
			}
		}
		3 {
			// Space Invader Pattern with Steel Pillars
			for r in 0 .. 6 {
				for c in 0 .. cols {
					x := start_x + c * (brick_w + padding_x)
					y := 70 + r * (brick_h + padding_y)

					if (c == 0 || c == cols - 1) && r > 1 {
						// Steel sides
						g.bricks << Brick{
							x:      x
							y:      y
							w:      brick_w
							h:      brick_h
							hp:     99
							max_hp: 99
							kind:   .steel
							color:  Color{r: 160, g: 160, b: 180}
							alive:  true
						}
					} else if (r + c) % 5 == 0 {
						g.bricks << Brick{
							x:      x
							y:      y
							w:      brick_w
							h:      brick_h
							hp:     1
							max_hp: 1
							kind:   .mystery
							color:  Color{r: 255, g: 220, b: 0}
							alive:  true
						}
					} else {
						g.bricks << Brick{
							x:      x
							y:      y
							w:      brick_w
							h:      brick_h
							hp:     1
							max_hp: 1
							kind:   .normal
							color:  Color{r: 0, g: 255, b: 180}
							alive:  true
						}
					}
				}
			}
		}
		4 {
			// Castle Fort with TNT Explosives
			for r in 0 .. 6 {
				for c in 0 .. cols {
					x := start_x + c * (brick_w + padding_x)
					y := 70 + r * (brick_h + padding_y)

					if (r == 2 && c == 4) || (r == 2 && c == 5) {
						g.bricks << Brick{
							x:      x
							y:      y
							w:      brick_w
							h:      brick_h
							hp:     1
							max_hp: 1
							kind:   .tnt
							color:  Color{r: 255, g: 50, b: 50}
							alive:  true
						}
					} else if r == 0 || r == 5 {
						g.bricks << Brick{
							x:      x
							y:      y
							w:      brick_w
							h:      brick_h
							hp:     2
							max_hp: 2
							kind:   .armored
							color:  Color{r: 200, g: 100, b: 255}
							alive:  true
						}
					} else {
						g.bricks << Brick{
							x:      x
							y:      y
							w:      brick_w
							h:      brick_h
							hp:     1
							max_hp: 1
							kind:   .normal
							color:  Color{r: 100, g: 200, b: 255}
							alive:  true
						}
					}
				}
			}
		}
		else {
			// Boss Grid with Armored & Mystery Walls
			for r in 0 .. 7 {
				for c in 0 .. cols {
					x := start_x + c * (brick_w + padding_x)
					y := 60 + r * (brick_h + padding_y)
					kind := if r % 3 == 0 {
						BrickType.armored
					} else if (r + c) % 4 == 0 {
						BrickType.mystery
					} else {
						BrickType.normal
					}
					hp := if kind == .armored { 3 } else { 1 }
					color := if kind == .armored {
						Color{r: 255, g: 100, b: 0}
					} else {
						Color{r: 0, g: 255, b: 220}
					}
					g.bricks << Brick{
						x:      x
						y:      y
						w:      brick_w
						h:      brick_h
						hp:     hp
						max_hp: hp
						kind:   kind
						color:  color
						alive:  true
					}
				}
			}
		}
	}
}

fn (mut g BreakoutGame) launch_balls() {
	for i in 0 .. g.balls.len {
		if g.balls[i].attached {
			g.balls[i].attached = false
			angle := -math.pi / 2.0 + (rand.f64() - 0.5) * 0.6
			speed := 380.0
			g.balls[i].dx = math.cos(angle) * speed
			g.balls[i].dy = math.sin(angle) * speed
		}
	}
}

fn (mut g BreakoutGame) fire_lasers() {
	if !g.paddle.has_lasers || g.paddle.laser_cooldown > 0.0 {
		return
	}
	g.paddle.laser_cooldown = 0.25
	g.last_sound_event = 'laser'
	g.lasers << LaserBeam{
		x: g.paddle.x + 8.0
		y: g.paddle.y
	}
	g.lasers << LaserBeam{
		x: g.paddle.x + g.paddle.w - 8.0
		y: g.paddle.y
	}
}

fn (mut g BreakoutGame) step(dt f64, move_x f64, launch_trigger bool, fire_trigger bool) {
	if g.game_over || g.level_cleared {
		return
	}
	g.last_sound_event = ''

	if g.shake_trauma > 0 {
		g.shake_trauma = math.max(0.0, g.shake_trauma - dt * 2.5)
	}

	// Handle Power-Up Timers
	if g.paddle.expand_timer > 0.0 {
		g.paddle.expand_timer -= dt
		if g.paddle.expand_timer <= 0.0 {
			g.paddle.w = g.paddle.base_w
		}
	}
	if g.paddle.laser_timer > 0.0 {
		g.paddle.laser_timer -= dt
		if g.paddle.laser_timer <= 0.0 {
			g.paddle.has_lasers = false
		}
	}
	if g.paddle.fireball_timer > 0.0 {
		g.paddle.fireball_timer -= dt
	}
	if g.paddle.slowball_timer > 0.0 {
		g.paddle.slowball_timer -= dt
	}
	if g.paddle.laser_cooldown > 0.0 {
		g.paddle.laser_cooldown -= dt
	}

	// Move Paddle
	g.paddle.x = move_x - g.paddle.w / 2.0
	if g.paddle.x < 10 {
		g.paddle.x = 10
	} else if g.paddle.x > world_w - g.paddle.w - 10 {
		g.paddle.x = world_w - g.paddle.w - 10
	}

	// Triggers
	if launch_trigger {
		g.launch_balls()
	}
	if fire_trigger {
		g.fire_lasers()
	}

	// Update Lasers
	for i := g.lasers.len - 1; i >= 0; i-- {
		mut laser := g.lasers[i]
		laser.y += laser.dy * dt

		// Hit Bricks check
		for j in 0 .. g.bricks.len {
			if !g.bricks[j].alive {
				continue
			}
			b := g.bricks[j]
			if laser.x >= b.x && laser.x <= b.x + b.w && laser.y >= b.y && laser.y <= b.y + b.h {
				g.damage_brick(j, 1)
				g.lasers.delete(i)
				break
			}
		}

		if i < g.lasers.len && laser.y < 0 {
			g.lasers.delete(i)
		}
	}

	// Update Capsules
	for i := g.capsules.len - 1; i >= 0; i-- {
		mut cap := g.capsules[i]
		cap.y += cap.dy * dt

		// Catch check (Magnetic generous hitbox)
		if cap.y + f64(cap.h) >= g.paddle.y - 2.0 && cap.y <= g.paddle.y + g.paddle.h + 4.0 {
			if cap.x + f64(cap.w) >= g.paddle.x - 6.0 && cap.x <= g.paddle.x + g.paddle.w + 6.0 {
				g.apply_powerup(cap.kind)
				g.capsules.delete(i)
				g.last_sound_event = 'powerup'
				continue
			}
		}

		if cap.y > world_h {
			g.capsules.delete(i)
		} else {
			g.capsules[i] = cap
		}
	}

	// Update Balls
	speed_mod := if g.paddle.slowball_timer > 0.0 { 0.65 } else { 1.0 }

	for i := g.balls.len - 1; i >= 0; i-- {
		mut ball := g.balls[i]

		if ball.attached {
			ball.x = g.paddle.x + ball.offset_x
			ball.y = g.paddle.y - ball.radius
			g.balls[i] = ball
			continue
		}

		// Move Ball
		ball.x += ball.dx * speed_mod * dt
		ball.y += ball.dy * speed_mod * dt

		// Wall Bounces
		if ball.x - ball.radius <= 0 {
			ball.x = ball.radius
			ball.dx = math.abs(ball.dx)
			g.last_sound_event = 'paddle'
		} else if ball.x + ball.radius >= world_w {
			ball.x = world_w - ball.radius
			ball.dx = -math.abs(ball.dx)
			g.last_sound_event = 'paddle'
		}

		if ball.y - ball.radius <= 40 {
			ball.y = 40 + ball.radius
			ball.dy = math.abs(ball.dy)
			g.last_sound_event = 'paddle'
		}

		// Precise Paddle Hitbox Bounce & Anti-Tunneling
		paddle_left := g.paddle.x - ball.radius * 0.8
		paddle_right := g.paddle.x + g.paddle.w + ball.radius * 0.8
		if ball.dy > 0.0 && ball.y + ball.radius >= g.paddle.y && ball.y - ball.radius <= g.paddle.y + g.paddle.h {
			if ball.x >= paddle_left && ball.x <= paddle_right {
				g.last_sound_event = 'paddle'
				g.combo_multiplier = 1

				// Ball touches the top surface of the paddle exactly
				ball.y = g.paddle.y - ball.radius

				if g.paddle.has_sticky && g.paddle.sticky_catches > 0 {
					g.paddle.sticky_catches--
					ball.attached = true
					ball.offset_x = math.clamp(ball.x - g.paddle.x, 8.0, g.paddle.w - 8.0)
				} else {
					// Hit angle calculation relative to paddle center (-1.0 to +1.0)
					raw_hit := (ball.x - (g.paddle.x + g.paddle.w * 0.5)) / (g.paddle.w * 0.5)
					hit_pos := math.clamp(raw_hit, -1.0, 1.0)
					angle := hit_pos * (math.pi / 2.7) // Up to 66 deg angle
					speed := math.max(340.0, math.sqrt(ball.dx * ball.dx + ball.dy * ball.dy))
					ball.dx = math.sin(angle) * speed
					ball.dy = -math.max(120.0, math.abs(math.cos(angle) * speed))
				}
			}
		}

		// Bottom Shield Bounce
		if g.bottom_shield_active && ball.y + ball.radius >= world_h - 10 {
			g.bottom_shield_active = false
			ball.dy = -math.abs(ball.dy)
			g.last_sound_event = 'paddle'
		}

		// Brick Collisions
		is_fireball := g.paddle.fireball_timer > 0.0

		for j in 0 .. g.bricks.len {
			if !g.bricks[j].alive {
				continue
			}
			b := g.bricks[j]

			// Rect-Circle overlap check
			closest_x := math.max(f64(b.x), math.min(ball.x, f64(b.x + b.w)))
			closest_y := math.max(f64(b.y), math.min(ball.y, f64(b.y + b.h)))

			dist_x := ball.x - closest_x
			dist_y := ball.y - closest_y
			dist_sq := dist_x * dist_x + dist_y * dist_y

			if dist_sq < ball.radius * ball.radius {
				g.damage_brick(j, 1)

				if !is_fireball {
					// Determine bounce direction
					if math.abs(dist_x) > math.abs(dist_y) {
						ball.dx = -ball.dx
					} else {
						ball.dy = -ball.dy
					}
					break
				}
			}
		}

		// Check if Ball Lost
		if ball.y > world_h + 20 {
			g.balls.delete(i)
		} else {
			g.balls[i] = ball
		}
	}

	// Check if all balls lost
	if g.balls.len == 0 {
		g.lives--
		g.last_sound_event = 'lose'

		if g.lives <= 0 {
			g.game_over = true
		} else {
			g.reset_round()
		}
	}

	// Check level clear condition (all non-steel bricks destroyed)
	mut remaining := 0
	for b in g.bricks {
		if b.alive && b.kind != .steel {
			remaining++
		}
	}
	if remaining == 0 {
		g.level_cleared = true
		g.last_sound_event = 'win'
	}
}

fn (mut g BreakoutGame) damage_brick(idx int, damage int) {
	if idx < 0 || idx >= g.bricks.len || !g.bricks[idx].alive {
		return
	}
	mut b := g.bricks[idx]

	if b.kind == .steel {
		g.last_sound_event = 'metal'
		return
	}

	b.hp -= damage
	if b.hp <= 0 {
		b.alive = false
		g.score += 10 * g.combo_multiplier
		g.combo_multiplier++
		g.shake_trauma = math.min(1.0, g.shake_trauma + 0.12)

		if b.kind == .tnt {
			g.last_sound_event = 'explosion'
			g.explode_tnt(b.x, b.y)
		} else if b.kind == .mystery || rand.f64() < 0.25 {
			g.last_sound_event = 'brick'
			g.spawn_capsule(f64(b.x + b.w / 2), f64(b.y + b.h / 2))
		} else {
			g.last_sound_event = 'brick'
		}
	} else {
		g.last_sound_event = 'brick'
	}

	g.bricks[idx] = b
}

fn (mut g BreakoutGame) explode_tnt(cx int, cy int) {
	g.shake_trauma = math.min(1.0, g.shake_trauma + 0.45)
	for i in 0 .. g.bricks.len {
		if !g.bricks[i].alive {
			continue
		}
		bx := g.bricks[i].x
		by := g.bricks[i].y
		if math.abs(f64(bx - cx)) <= 90.0 && math.abs(f64(by - cy)) <= 35.0 {
			g.bricks[i].alive = false
			g.score += 20
		}
	}
}

fn (mut g BreakoutGame) spawn_capsule(x f64, y f64) {
	kinds := [
		PowerUpType.multiball,
		PowerUpType.expand_paddle,
		PowerUpType.laser_paddle,
		PowerUpType.sticky_paddle,
		PowerUpType.fireball,
		PowerUpType.slow_ball,
		PowerUpType.bottom_shield,
		PowerUpType.extra_life,
	]
	idx := rand.intn(kinds.len) or { 0 }
	g.capsules << Capsule{
		x:    x
		y:    y
		kind: kinds[idx]
	}
}

fn (mut g BreakoutGame) apply_powerup(kind PowerUpType) {
	match kind {
		.multiball {
			if g.balls.len > 0 {
				base_x := g.balls[0].x
				base_y := g.balls[0].y
				g.balls << Ball{
					x:  base_x
					y:  base_y
					dx: -240.0
					dy: -300.0
				}
				g.balls << Ball{
					x:  base_x
					y:  base_y
					dx: 240.0
					dy: -300.0
				}
			}
		}
		.expand_paddle {
			g.paddle.w = g.paddle.base_w * 1.5
			g.paddle.expand_timer = 12.0
		}
		.laser_paddle {
			g.paddle.has_lasers = true
			g.paddle.laser_timer = 10.0
		}
		.sticky_paddle {
			g.paddle.has_sticky = true
			g.paddle.sticky_catches = 3
		}
		.fireball {
			g.paddle.fireball_timer = 8.0
		}
		.slow_ball {
			g.paddle.slowball_timer = 10.0
		}
		.bottom_shield {
			g.bottom_shield_active = true
		}
		.extra_life {
			if g.lives < max_lives {
				g.lives++
			}
		}
	}
}
