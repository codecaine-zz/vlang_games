module main

import math

pub struct Vec3 {
pub mut:
	x f32
	y f32
	z f32
}

pub fn vec3(x f32, y f32, z f32) Vec3 {
	return Vec3{x: x, y: y, z: z}
}

pub fn (v Vec3) add(o Vec3) Vec3 {
	return Vec3{x: v.x + o.x, y: v.y + o.y, z: v.z + o.z}
}

pub fn (v Vec3) sub(o Vec3) Vec3 {
	return Vec3{x: v.x - o.x, y: v.y - o.y, z: v.z - o.z}
}

pub fn (v Vec3) scale(s f32) Vec3 {
	return Vec3{x: v.x * s, y: v.y * s, z: v.z * s}
}

pub fn (v Vec3) len_3d() f32 {
	return f32(math.sqrt(f64(v.x * v.x + v.y * v.y + v.z * v.z)))
}

pub struct ProjectedPoint {
pub mut:
	sx      f32
	sy      f32
	scale   f32
	visible bool
	depth_z f32
}

pub struct Camera {
pub mut:
	x           f32
	y           f32 = 115.0
	z           f32
	focal_len   f32 = 440.0
	horizon_y   f32 = 240.0
	tilt_angle  f32
}

// 3D Perspective Projection with Spline Hills and Curvature
pub fn project_3d(pos Vec3, cam Camera, track_curve f32, track_hill f32, win_w int, win_h int) ProjectedPoint {
	rel_z := pos.z - cam.z
	if rel_z < 15.0 {
		return ProjectedPoint{
			sx: 0
			sy: 0
			scale: 0
			visible: false
			depth_z: rel_z
		}
	}

	scale := cam.focal_len / rel_z
	cx := f32(win_w) * 0.5
	cy := f32(win_h) * 0.52

	// Smooth spline curvature offsets
	curve_offset := (rel_z * rel_z) * track_curve * 0.00003
	hill_offset := (rel_z * rel_z) * track_hill * 0.000015

	rel_x := pos.x - cam.x + curve_offset
	rel_y := pos.y - cam.y + hill_offset

	sx := cx + rel_x * scale
	sy := cy - rel_y * scale

	return ProjectedPoint{
		sx: sx
		sy: sy
		scale: scale
		visible: rel_z >= 15.0 && rel_z <= 2800.0 && sx >= -300.0 && sx <= f32(win_w + 300) && sy >= -300.0 && sy <= f32(win_h + 300)
		depth_z: rel_z
	}
}

// 3D Box Collision Check
pub fn check_box_collision_3d(p1 Vec3, sz1 Vec3, p2 Vec3, sz2 Vec3) bool {
	dx := math.abs(f64(p1.x - p2.x))
	dy := math.abs(f64(p1.y - p2.y))
	dz := math.abs(f64(p1.z - p2.z))

	max_dx := f64(sz1.x + sz2.x) * 0.5
	max_dy := f64(sz1.y + sz2.y) * 0.5
	max_dz := f64(sz1.z + sz2.z) * 0.5

	return dx <= max_dx && dy <= max_dy && dz <= max_dz
}

// 3D Sphere Collision Check
pub fn check_sphere_collision_3d(p1 Vec3, r1 f32, p2 Vec3, r2 f32) bool {
	dx := p1.x - p2.x
	dy := p1.y - p2.y
	dz := p1.z - p2.z
	dist_sq := dx * dx + dy * dy + dz * dz
	min_dist := r1 + r2
	return dist_sq <= min_dist * min_dist
}
