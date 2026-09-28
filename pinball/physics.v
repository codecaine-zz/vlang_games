module main

import math

struct Vec2 {
mut:
	x f64
	y f64
}

fn (v Vec2) add(o Vec2) Vec2 {
	return Vec2{
		x: v.x + o.x
		y: v.y + o.y
	}
}

fn (v Vec2) sub(o Vec2) Vec2 {
	return Vec2{
		x: v.x - o.x
		y: v.y - o.y
	}
}

fn (v Vec2) mul(s f64) Vec2 {
	return Vec2{
		x: v.x * s
		y: v.y * s
	}
}

fn (v Vec2) length() f64 {
	return math.sqrt(v.x * v.x + v.y * v.y)
}

fn (v Vec2) normalize() Vec2 {
	len := v.length()
	if len < 0.00001 {
		return Vec2{
			x: 0.0
			y: 0.0
		}
	}
	return Vec2{
		x: v.x / len
		y: v.y / len
	}
}

fn (v Vec2) dot(o Vec2) f64 {
	return v.x * o.x + v.y * o.y
}

fn (v Vec2) distance(o Vec2) f64 {
	dx := v.x - o.x
	dy := v.y - o.y
	return math.sqrt(dx * dx + dy * dy)
}

struct Ball {
mut:
	pos    Vec2
	vel    Vec2
	radius f64 = 10.0
	active bool = true
	spin   f64
}

struct LineSegment {
	p1 Vec2
	p2 Vec2
}

struct Flipper {
mut:
	pivot         Vec2
	length        f64 = 85.0
	base_angle    f64
	max_angle     f64
	current_angle f64
	angular_vel   f64
	is_left       bool
}

fn new_flipper(pivot Vec2, base_angle f64, max_angle f64, is_left bool) Flipper {
	return Flipper{
		pivot:         pivot
		length:        85.0
		base_angle:    base_angle
		max_angle:     max_angle
		current_angle: base_angle
		angular_vel:   0.0
		is_left:       is_left
	}
}

fn (f &Flipper) update(dt f64, is_pressed bool) {
	mut mutable_f := unsafe { &Flipper(f) }
	target := if is_pressed { mutable_f.max_angle } else { mutable_f.base_angle }
	speed := 28.0 // rad/s rotation speed

	old_angle := mutable_f.current_angle
	if mutable_f.current_angle < target {
		mutable_f.current_angle = math.min(target, mutable_f.current_angle + speed * dt)
	} else if mutable_f.current_angle > target {
		mutable_f.current_angle = math.max(target, mutable_f.current_angle - speed * dt)
	}

	mutable_f.angular_vel = (mutable_f.current_angle - old_angle) / dt
}

fn (f &Flipper) get_tip() Vec2 {
	return Vec2{
		x: f.pivot.x + f.length * math.cos(f.current_angle)
		y: f.pivot.y + f.length * math.sin(f.current_angle)
	}
}

fn (f &Flipper) get_segment() LineSegment {
	return LineSegment{
		p1: f.pivot
		p2: f.get_tip()
	}
}

fn closest_point_on_segment(p Vec2, seg LineSegment) Vec2 {
	seg_vec := seg.p2.sub(seg.p1)
	seg_len_sq := seg_vec.dot(seg_vec)
	if seg_len_sq < 0.00001 {
		return seg.p1
	}
	t := math.max(0.0, math.min(1.0, p.sub(seg.p1).dot(seg_vec) / seg_len_sq))
	return seg.p1.add(seg_vec.mul(t))
}

fn collide_circle_segment(mut ball Ball, seg LineSegment, restitution f64) bool {
	closest := closest_point_on_segment(ball.pos, seg)
	dist := ball.pos.distance(closest)
	if dist < ball.radius {
		mut normal := ball.pos.sub(closest)
		if dist > 0.0001 {
			normal = normal.normalize()
		} else {
			normal = Vec2{
				x: 0.0
				y: -1.0
			}
		}
		overlap := ball.radius - dist
		ball.pos = ball.pos.add(normal.mul(overlap))

		v_dot_n := ball.vel.dot(normal)
		if v_dot_n < 0.0 {
			ball.vel = ball.vel.sub(normal.mul((1.0 + restitution) * v_dot_n))
		}
		return true
	}
	return false
}

fn collide_circle_bumper(mut ball Ball, bumper_pos Vec2, bumper_radius f64, bounce_boost f64) bool {
	dist := ball.pos.distance(bumper_pos)
	min_dist := ball.radius + bumper_radius
	if dist < min_dist {
		mut normal := ball.pos.sub(bumper_pos)
		if dist > 0.0001 {
			normal = normal.normalize()
		} else {
			normal = Vec2{
				x: 0.0
				y: -1.0
			}
		}
		overlap := min_dist - dist
		ball.pos = ball.pos.add(normal.mul(overlap))

		// Repel forcefully
		outward_speed := math.max(350.0, ball.vel.length() * 1.3) + bounce_boost
		ball.vel = normal.mul(outward_speed)
		return true
	}
	return false
}

fn collide_circle_flipper(mut ball Ball, flipper &Flipper) bool {
	seg := flipper.get_segment()
	closest := closest_point_on_segment(ball.pos, seg)
	dist := ball.pos.distance(closest)
	if dist < ball.radius {
		mut normal := ball.pos.sub(closest)
		if dist > 0.0001 {
			normal = normal.normalize()
		} else {
			normal = Vec2{
				x: 0.0
				y: -1.0
			}
		}
		overlap := ball.radius - dist
		ball.pos = ball.pos.add(normal.mul(overlap))

		arm_dist := closest.distance(flipper.pivot)
		// Tangent direction of flipper motion
		flipper_tangent := Vec2{
			x: -math.sin(flipper.current_angle)
			y: math.cos(flipper.current_angle)
		}
		flipper_vel := flipper_tangent.mul(flipper.angular_vel * arm_dist)

		rel_vel := ball.vel.sub(flipper_vel)
		v_dot_n := rel_vel.dot(normal)
		if v_dot_n < 0.0 {
			restitution := 0.85
			rel_vel_reflected := rel_vel.sub(normal.mul((1.0 + restitution) * v_dot_n))
			ball.vel = rel_vel_reflected.add(flipper_vel)
		}

		// When flipper is moving upward, impart crisp arcade vertical launch impulse
		if math.abs(flipper.angular_vel) > 2.0 {
			up_boost := math.min(680.0, math.abs(flipper.angular_vel) * 24.0)
			ball.vel.y = -up_boost
			if flipper.is_left {
				ball.vel.x = math.max(60.0, ball.vel.x + 140.0)
			} else {
				ball.vel.x = math.min(-60.0, ball.vel.x - 140.0)
			}
		}
		return true
	}
	return false
}
