module main

import math

struct MotionState {
pub mut:
	x           f64
	y           f64
	vx          f64
	vy          f64
	is_grounded bool
}

const gravity = 460.0
const air_drag = 0.985
const ground_friction = 0.84
const max_fall_speed = 400.0

fn apply_flap(mut m MotionState, power f64) {
	m.vy -= power
	if m.vy < -340.0 {
		m.vy = -340.0
	}
	m.is_grounded = false
}

fn update_motion(mut m MotionState, dt f64, world_w f64) {
	if !m.is_grounded {
		m.vy += gravity * dt
		if m.vy > max_fall_speed {
			m.vy = max_fall_speed
		}
		m.vx *= air_drag
	} else {
		m.vy = 0
		m.vx *= ground_friction
	}

	m.x += m.vx * dt
	m.y += m.vy * dt

	// Screen edge wraparound
	if m.x < -20.0 {
		m.x += world_w + 40.0
	} else if m.x > world_w + 20.0 {
		m.x -= world_w + 40.0
	}
}

pub fn wrap_dx(from_x f64, to_x f64, world_w f64) f64 {
	mut dx := to_x - from_x
	if dx > world_w / 2.0 {
		dx -= world_w
	} else if dx < -world_w / 2.0 {
		dx += world_w
	}
	return dx
}

struct Platform {
pub mut:
	x f64
	y f64
	w f64
	h f64
}

fn update_platforms_collision(mut m MotionState, char_w f64, char_h f64, platforms []Platform) bool {
	char_left := m.x - (char_w / 2.0)
	char_right := m.x + (char_w / 2.0)
	char_bottom := m.y + (char_h / 2.0)
	char_top := m.y - (char_h / 2.0)

	// Check if still resting on any platform ledge
	if m.is_grounded {
		mut on_ground := false
		for plat in platforms {
			if char_right >= plat.x && char_left <= plat.x + plat.w {
				if math.abs(char_bottom - plat.y) <= 4.0 {
					on_ground = true
					m.y = plat.y - (char_h / 2.0)
					m.vy = 0
					break
				}
			}
		}
		if !on_ground {
			// Walked off the edge of the platform! Immediately resume falling
			m.is_grounded = false
		} else {
			return true
		}
	}

	// Landing on top of platforms from the air
	if m.vy >= 0 {
		for plat in platforms {
			if char_right >= plat.x && char_left <= plat.x + plat.w {
				if char_bottom >= plat.y && char_bottom <= plat.y + 14.0 {
					m.y = plat.y - (char_h / 2.0)
					m.vy = 0
					m.is_grounded = true
					return true
				}
			}
		}
	} else if m.vy < 0 {
		// Bumping head into underside of platform
		for plat in platforms {
			if char_right >= plat.x && char_left <= plat.x + plat.w {
				plat_bottom := plat.y + plat.h
				if char_top <= plat_bottom && char_top >= plat_bottom - 10.0 {
					m.y = plat_bottom + (char_h / 2.0)
					m.vy = math.abs(m.vy) * 0.3
					break
				}
			}
		}
	}

	return m.is_grounded
}
