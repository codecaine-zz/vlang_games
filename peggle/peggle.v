module main

import math

pub enum PegType {
	blue
	orange
	purple
	green
}

pub struct Peg {
pub mut:
	x          f64
	y          f64
	radius     f64 = 9.0
	ptype      PegType
	is_hit     bool
	hit_timer  f64
}

pub struct Ball {
pub mut:
	x       f64
	y       f64
	vx      f64
	vy      f64
	radius  f64 = 8.0
	active  bool
}

pub struct PeggleGame {
pub mut:
	width          int = 920
	height         int = 640

	cannon_angle   f64 = math.pi / 2.0 // Aim angle (radians)
	balls_left     int = 10
	score          int
	combo_hits     int
	orange_left    int

	active_balls   []Ball
	pegs           []Peg

	// Bottom Moving Bucket
	bucket_x       f64 = 460.0
	bucket_w       f64 = 90.0
	bucket_vx      f64 = 140.0

	is_fever       bool
	fever_slowmo   f64 = 1.0
	is_game_over   bool
	is_win         bool

	sound_event    string
	banner_text    string
	banner_timer   f64
}

pub fn new_peggle_game() PeggleGame {
	mut g := PeggleGame{}
	g.init_level()
	return g
}

pub fn (mut g PeggleGame) init_level() {
	g.balls_left = 10
	g.score = 0
	g.combo_hits = 0
	g.is_fever = false
	g.fever_slowmo = 1.0
	g.is_game_over = false
	g.is_win = false
	g.active_balls.clear()
	g.pegs.clear()

	// Generate 55 Pegs in elegant staggered arcs
	mut orange_count := 0
	for row in 0 .. 6 {
		count := 8 + (row % 2)
		y := 160.0 + f64(row * 48)
		offset_x := if row % 2 == 0 { 220.0 } else { 245.0 }

		for col in 0 .. count {
			x := offset_x + f64(col * 52)
			mut ptype := PegType.blue

			// Scatter Orange, Purple, and Green pegs
			if (row + col) % 3 == 0 && orange_count < 25 {
				ptype = .orange
				orange_count++
			} else if row == 2 && col == 4 {
				ptype = .purple
			} else if row == 4 && col == 2 {
				ptype = .green
			}

			g.pegs << Peg{
				x: x
				y: y
				ptype: ptype
			}
		}
	}

	g.orange_left = orange_count
	g.banner_text = 'CLEAR ALL ORANGE PEGS TO TRIGGER EXTREME FEVER!'
	g.banner_timer = 3.0
}

pub fn (mut g PeggleGame) shoot_ball() bool {
	if g.active_balls.len > 0 || g.balls_left <= 0 || g.is_game_over {
		return false
	}

	g.balls_left--
	g.combo_hits = 0

	spd := 620.0
	cannon_x := f64(g.width) / 2.0
	cannon_y := 45.0

	g.active_balls << Ball{
		x: cannon_x + math.cos(g.cannon_angle) * 35.0
		y: cannon_y + math.sin(g.cannon_angle) * 35.0
		vx: math.cos(g.cannon_angle) * spd
		vy: math.sin(g.cannon_angle) * spd
		active: true
	}

	g.sound_event = 'cannon'
	return true
}

pub fn (mut g PeggleGame) update(dt f64) {
	if g.banner_timer > 0.0 {
		g.banner_timer -= dt
	}

	real_dt := dt * g.fever_slowmo

	// 1. Move Bottom Catcher Bucket
	g.bucket_x += g.bucket_vx * real_dt
	if g.bucket_x - g.bucket_w / 2.0 <= 120.0 {
		g.bucket_x = 120.0 + g.bucket_w / 2.0
		g.bucket_vx = -g.bucket_vx
	} else if g.bucket_x + g.bucket_w / 2.0 >= f64(g.width - 120) {
		g.bucket_x = f64(g.width - 120) - g.bucket_w / 2.0
		g.bucket_vx = -g.bucket_vx
	}

	// 2. Update Ball Physics
	mut balls_in_play := false
	for b_i := 0; b_i < g.active_balls.len; b_i++ {
		mut b := g.active_balls[b_i]
		if !b.active {
			continue
		}
		balls_in_play = true

		// Gravity
		b.vy += 520.0 * real_dt

		b.x += b.vx * real_dt
		b.y += b.vy * real_dt

		// Left / Right Wall Bounces
		if b.x - b.radius <= 60.0 {
			b.x = 60.0 + b.radius
			b.vx = -b.vx * 0.85
		} else if b.x + b.radius >= f64(g.width - 60) {
			b.x = f64(g.width - 60) - b.radius
			b.vx = -b.vx * 0.85
		}

		// Collide with Pegs
		for p_i := 0; p_i < g.pegs.len; p_i++ {
			mut p := g.pegs[p_i]
			dx := b.x - p.x
			dy := b.y - p.y
			dist := math.sqrt(dx * dx + dy * dy)
			min_dist := b.radius + p.radius

			if dist < min_dist && dist > 0.001 {
				// Normal vector
				nx := dx / dist
				ny := dy / dist

				// Elastic bounce resolution
				dot := b.vx * nx + b.vy * ny
				if dot < 0.0 {
					b.vx -= 1.85 * dot * nx
					b.vy -= 1.85 * dot * ny
					b.x = p.x + nx * min_dist
					b.y = p.y + ny * min_dist

					if !p.is_hit {
						p.is_hit = true
						g.combo_hits++
						g.sound_event = 'ding'

						match p.ptype {
							.orange {
								g.score += 500 * g.combo_hits
								g.orange_left--
								if g.orange_left <= 0 && !g.is_fever {
									g.is_fever = true
									g.is_win = true
									g.sound_event = 'fever'
									g.banner_text = '★ EXTREME FEVER! 100,000 PTS! ★'
									g.banner_timer = 5.0
								}
							}
							.purple {
								g.score += 2000 * g.combo_hits
							}
							.green {
								g.score += 1000
								// Spawn second multi-ball
								g.active_balls << Ball{
									x: b.x
									y: b.y
									vx: -b.vx
									vy: b.vy - 100.0
									active: true
								}
							}
							.blue {
								g.score += 100 * g.combo_hits
							}
						}
					}
				}
			}
			g.pegs[p_i] = p
		}

		// Check Bottom Exit / Bucket Catch
		if b.y >= f64(g.height - 35) {
			// Check if caught in bucket
			if math.abs(b.x - g.bucket_x) <= g.bucket_w / 2.0 {
				g.balls_left++
				g.score += 5000
				g.sound_event = 'bucket'
				g.banner_text = 'FREE BALL CATCH! +1 BALL'
				g.banner_timer = 2.0
			}
			b.active = false
		}

		g.active_balls[b_i] = b
	}

	// Remove inactive balls
	for i := g.active_balls.len - 1; i >= 0; i-- {
		if !g.active_balls[i].active {
			g.active_balls.delete(i)
		}
	}

	// Clear hit pegs once turn ends
	if !balls_in_play && g.active_balls.len == 0 {
		for i := g.pegs.len - 1; i >= 0; i-- {
			if g.pegs[i].is_hit {
				g.pegs.delete(i)
			}
		}

		// Check Game Over
		if g.balls_left <= 0 && g.orange_left > 0 && !g.is_win {
			g.is_game_over = true
			g.banner_text = 'OUT OF BALLS! GAME OVER'
			g.banner_timer = 4.0
		}
	}
}
