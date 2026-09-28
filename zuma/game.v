module main

import math
import rand

pub const zuma_colors = 5 // 1: Ruby, 2: Sapphire, 3: Emerald, 4: Topaz, 5: Amethyst
pub const ball_radius = 16.0
pub const ball_diameter = ball_radius * 2.0

pub enum PowerupType {
	none
	slow
	reverse
	bomb
}

pub struct TrackPoint {
pub:
	x f64
	y f64
}

pub struct Ball {
pub mut:
	color    int // 1..5
	dist     f64 // Distance along track (in pixels)
	powerup  PowerupType = .none
	is_dead  bool
}

pub struct Projectile {
pub mut:
	x       f64
	y       f64
	vx      f64
	vy      f64
	color   int
	powerup PowerupType
	active  bool
}

pub enum ZumaState {
	playing
	level_won
	game_over
}

pub struct ZumaGame {
pub mut:
	track           []TrackPoint
	total_track_len f64
	balls           []Ball
	shooter_x       f64 = 440.0
	shooter_y       f64 = 420.0
	turret_angle    f64
	current_ball    int = 1
	next_ball       int = 2
	projectile      Projectile
	state           ZumaState = .playing
	score           int
	high_score      int
	level           int = 1
	roll_speed      f64 = 30.0 // pixels per sec
	slow_timer      f64
	reverse_timer   f64
	combo_count     int
	balls_spawned   int
	max_balls_level int = 40
	pull_active     bool
}

pub fn new_zuma_game() ZumaGame {
	mut g := ZumaGame{}
	g.init_track()
	g.init_level(1)
	return g
}

// Generate smooth spiral track
pub fn (mut g ZumaGame) init_track() {
	g.track.clear()
	cx := 440.0
	cy := 420.0
	steps := 600
	mut pts := []TrackPoint{cap: steps}

	// Smooth spiral winding inwards toward skull pit at (cx + 100, cy + 80)
	for i in 0 .. steps {
		t := f64(i) / f64(steps) // 0.0 to 1.0
		theta := t * 4.2 * math.pi
		r := 340.0 * (1.0 - t * 0.72)
		x := cx + math.cos(theta) * (r * 1.15)
		y := cy + math.sin(theta) * (r * 0.95)
		pts << TrackPoint{x: x, y: y}
	}
	g.track = pts

	// Calculate total track arc length
	mut total := 0.0
	for i in 0 .. g.track.len - 1 {
		dx := g.track[i + 1].x - g.track[i].x
		dy := g.track[i + 1].y - g.track[i].y
		total += math.sqrt(dx * dx + dy * dy)
	}
	g.total_track_len = total
}

pub fn (g ZumaGame) get_track_pos(dist f64) (f64, f64) {
	if dist <= 0 || g.track.len == 0 {
		return g.track[0].x, g.track[0].y
	}
	mut current_dist := 0.0
	for i in 0 .. g.track.len - 1 {
		dx := g.track[i + 1].x - g.track[i].x
		dy := g.track[i + 1].y - g.track[i].y
		seg_len := math.sqrt(dx * dx + dy * dy)
		if current_dist + seg_len >= dist {
			ratio := (dist - current_dist) / seg_len
			x := g.track[i].x + dx * ratio
			y := g.track[i].y + dy * ratio
			return x, y
		}
		current_dist += seg_len
	}
	last := g.track[g.track.len - 1]
	return last.x, last.y
}

pub fn (mut g ZumaGame) init_level(lvl int) {
	g.level = lvl
	g.balls.clear()
	g.projectile.active = false
	g.state = .playing
	g.combo_count = 0
	g.slow_timer = 0
	g.reverse_timer = 0
	g.roll_speed = 32.0 + f64(lvl) * 4.0
	g.balls_spawned = 0
	g.max_balls_level = 35 + lvl * 10

	g.current_ball = rand.int_in_range(1, zuma_colors + 1) or { 1 }
	g.next_ball = rand.int_in_range(1, zuma_colors + 1) or { 2 }

	// Initial train of 15 balls
	for _ in 0 .. 15 {
		g.spawn_train_ball()
	}
}

pub fn (mut g ZumaGame) spawn_train_ball() {
	if g.balls_spawned >= g.max_balls_level {
		return
	}
	col := rand.int_in_range(1, zuma_colors + 1) or { 1 }

	// 6% chance of powerup
	mut p_type := PowerupType.none
	if rand.int_in_range(0, 16) or { 0 } == 0 {
		pick := rand.int_in_range(1, 4) or { 1 }
		p_type = match pick {
			1 { PowerupType.slow }
			2 { PowerupType.reverse }
			else { PowerupType.bomb }
		}
	}

	mut start_dist := 0.0
	if g.balls.len > 0 {
		start_dist = g.balls[g.balls.len - 1].dist - ball_diameter
	}

	g.balls << Ball{
		color:   col
		dist:    start_dist
		powerup: p_type
	}
	g.balls_spawned++
}

pub fn (mut g ZumaGame) swap_current_ball() {
	tmp := g.current_ball
	g.current_ball = g.next_ball
	g.next_ball = tmp
}

pub fn (mut g ZumaGame) shoot_ball() bool {
	if g.projectile.active || g.state != .playing {
		return false
	}
	spd := 750.0
	vx := math.cos(g.turret_angle) * spd
	vy := math.sin(g.turret_angle) * spd

	g.projectile = Projectile{
		x:       g.shooter_x + math.cos(g.turret_angle) * 35.0
		y:       g.shooter_y + math.sin(g.turret_angle) * 35.0
		vx:      vx
		vy:      vy
		color:   g.current_ball
		powerup: .none
		active:  true
	}

	g.current_ball = g.next_ball
	g.next_ball = rand.int_in_range(1, zuma_colors + 1) or { 1 }
	return true
}

// Check projectile collision with ball train & insert
pub fn (mut g ZumaGame) check_projectile_collision() (bool, int) {
	if !g.projectile.active {
		return false, 0
	}

	// Out of bounds check
	if g.projectile.x < 0 || g.projectile.x > 880 || g.projectile.y < 0 || g.projectile.y > 840 {
		g.projectile.active = false
		return false, 0
	}

	mut hit_idx := -1
	mut min_dist := 999999.0

	for i in 0 .. g.balls.len {
		bx, by := g.get_track_pos(g.balls[i].dist)
		dx := g.projectile.x - bx
		dy := g.projectile.y - by
		d := math.sqrt(dx * dx + dy * dy)
		if d < ball_diameter {
			if d < min_dist {
				min_dist = d
				hit_idx = i
			}
		}
	}

	if hit_idx != -1 {
		// Insert ball into train
		hit_ball_dist := g.balls[hit_idx].dist
		new_ball := Ball{
			color:   g.projectile.color
			dist:    hit_ball_dist
			powerup: g.projectile.powerup
		}
		g.projectile.active = false

		// Insert at hit_idx
		g.balls.insert(hit_idx, new_ball)

		// Push back subsequent balls so they don't overlap
		for j in hit_idx + 1 .. g.balls.len {
			if g.balls[j].dist > g.balls[j - 1].dist - ball_diameter {
				g.balls[j].dist = g.balls[j - 1].dist - ball_diameter
			}
		}

		// Check for Match-3+ starting at hit_idx
		cleared := g.check_matches_at(hit_idx)
		return true, cleared
	}
	return false, 0
}

// Find contiguous group of same color balls around index
pub fn (mut g ZumaGame) check_matches_at(idx int) int {
	if idx < 0 || idx >= g.balls.len {
		return 0
	}
	target_col := g.balls[idx].color

	// Find left/earlier contiguous
	mut start_i := idx
	for start_i > 0 && g.balls[start_i - 1].color == target_col && math.abs(g.balls[start_i].dist - g.balls[start_i - 1].dist) <= ball_diameter + 4.0 {
		start_i--
	}

	// Find right/later contiguous
	mut end_i := idx
	for end_i < g.balls.len - 1 && g.balls[end_i + 1].color == target_col && math.abs(g.balls[end_i + 1].dist - g.balls[end_i].dist) <= ball_diameter + 4.0 {
		end_i++
	}

	count := end_i - start_i + 1
	if count >= 3 {
		g.combo_count++
		mut pts := count * 100 * g.combo_count

		// Check powerups triggered
		for k in start_i .. end_i + 1 {
			match g.balls[k].powerup {
				.slow { g.slow_timer = 5.0 }
				.reverse { g.reverse_timer = 2.5 }
				.bomb {
					// Bomb explosion
					pts += 500
				}
				.none {}
			}
		}

		g.score += pts
		if g.score > g.high_score {
			g.high_score = g.score
		}

		// Remove balls
		g.balls.delete_many(start_i, count)
		g.pull_active = true

		// Check if entire level is cleared
		if g.balls.len == 0 && g.balls_spawned >= g.max_balls_level {
			g.state = .level_won
		}
		return count
	}
	g.combo_count = 0
	return 0
}

// Apply magnetic attraction to pull separated gaps together
pub fn (mut g ZumaGame) apply_magnetic_pull(dt f64) {
	if g.balls.len < 2 {
		return
	}
	for i in 0 .. g.balls.len - 1 {
		gap := (g.balls[i].dist - g.balls[i + 1].dist) - ball_diameter
		if gap > 2.0 {
			// If colors on either side of gap match, pull backward segment forward!
			if g.balls[i].color == g.balls[i + 1].color {
				pull_speed := 180.0 * dt
				for j in i + 1 .. g.balls.len {
					g.balls[j].dist += pull_speed
				}
				// If gap now closed, check for combo match
				if (g.balls[i].dist - g.balls[i + 1].dist) <= ball_diameter + 1.0 {
					g.check_matches_at(i)
				}
			}
		}
	}
}

pub fn (mut g ZumaGame) update(dt f64) {
	if g.state != .playing {
		return
	}

	// Update Timers
	if g.slow_timer > 0 {
		g.slow_timer -= dt
	}
	if g.reverse_timer > 0 {
		g.reverse_timer -= dt
	}

	// Compute effective rolling speed
	mut cur_speed := g.roll_speed
	if g.reverse_timer > 0 {
		cur_speed = -g.roll_speed * 1.5
	} else if g.slow_timer > 0 {
		cur_speed = g.roll_speed * 0.4
	}

	// Spawn more balls into train periodically
	if g.balls_spawned < g.max_balls_level {
		if g.balls.len == 0 || g.balls[g.balls.len - 1].dist > ball_diameter * 1.5 {
			g.spawn_train_ball()
		}
	}

	// Advance balls along track
	if g.balls.len > 0 {
		g.balls[0].dist += cur_speed * dt

		// Follower balls push/pull
		for i in 1 .. g.balls.len {
			target_dist := g.balls[i - 1].dist - ball_diameter
			if g.balls[i].dist > target_dist {
				g.balls[i].dist = target_dist
			} else {
				g.balls[i].dist += cur_speed * dt
				if g.balls[i].dist > target_dist {
					g.balls[i].dist = target_dist
				}
			}
		}
	}

	// Update projectile
	if g.projectile.active {
		g.projectile.x += g.projectile.vx * dt
		g.projectile.y += g.projectile.vy * dt
		g.check_projectile_collision()
	}

	// Magnetic pull on gaps
	g.apply_magnetic_pull(dt)

	// Check skull pit danger (end of track)
	if g.balls.len > 0 && g.balls[0].dist >= g.total_track_len - 10.0 {
		g.state = .game_over
	}
}
