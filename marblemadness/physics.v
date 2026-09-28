module main

import math

pub const tile_w = 40.0
pub const tile_h = 20.0
pub const tile_z = 26.0

pub const gravity = 22.0
pub const marble_radius = 0.34
pub const shatter_impact_speed = 16.0
pub const terminal_fall_velocity = -24.0

pub enum TileType {
	empty
	flat
	slope_x_up      // slopes UP in +x direction (from x to x+1)
	slope_x_down    // slopes DOWN in +x direction
	slope_y_up      // slopes UP in +y direction (from y to y+1)
	slope_y_down    // slopes DOWN in +y direction
	slope_xy_down   // slopes down in both +x and +y
	slope_xy_up     // slopes up in both +x and +y
	ice             // ultra low friction
	wave            // undulating liquid/organic terrain
	catapult        // super jump spring pad
	tube_in         // vacuum chute entrance
	tube_out        // vacuum chute exit
	goal            // level finish flag
	hazard_acid     // green acid puddle / muncher pit
	disappearing    // periodically solid / hollow
	bumper          // bounces marble away with high force
}

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

pub fn (v Vec3) len_2d() f32 {
	return f32(math.sqrt(f64(v.x * v.x + v.y * v.y)))
}

pub fn (v Vec3) len_3d() f32 {
	return f32(math.sqrt(f64(v.x * v.x + v.y * v.y + v.z * v.z)))
}

pub fn (v Vec3) normalized_2d() Vec3 {
	l := v.len_2d()
	if l > 0.001 {
		return Vec3{x: v.x / l, y: v.y / l, z: 0.0}
	}
	return Vec3{x: 0, y: 0, z: 0}
}

// Convert 3D world coordinates (x, y, z) into 2D isometric screen space
pub fn world_to_screen(x f32, y f32, z f32, cam_x f32, cam_y f32) (f32, f32) {
	sx := (x - y) * (tile_w * 0.5) + cam_x
	sy := (x + y) * (tile_h * 0.5) - z * tile_z + cam_y
	return sx, sy
}

// Convert screen coordinates back into ground plane (z=0) world coordinates
pub fn screen_to_world_z0(sx f32, sy f32, cam_x f32, cam_y f32) (f32, f32) {
	rx := sx - cam_x
	ry := sy - cam_y
	u := rx / (tile_w * 0.5)
	v := ry / (tile_h * 0.5)
	x := (u + v) * 0.5
	y := (v - u) * 0.5
	return x, y
}

// Tile structure
pub struct Tile {
pub mut:
	tile_type TileType = .flat
	base_z    f32      // Base elevation
	height    f32 = 1.0 // Height delta if slope
	color_idx int      // Palette index for visual theme
	target_x  int      // For tubes: target destination X
	target_y  int      // For tubes: target destination Y
	timer     f32      // Dynamic cycle animation timer
	is_active bool = true
}

// Query raw height for a specific tile at local (u, v) in [0, 1]
fn get_tile_raw_height(t Tile, u f32, v f32, px f32, py f32, global_time f32) (f32, f32, f32) {
	mut h := t.base_z
	mut dz_dx := f32(0.0)
	mut dz_dy := f32(0.0)

	match t.tile_type {
		.flat, .ice, .catapult, .tube_in, .tube_out, .goal, .hazard_acid, .bumper, .disappearing {
			h = t.base_z
			dz_dx = 0.0
			dz_dy = 0.0
		}
		.slope_x_up {
			h = t.base_z + u * t.height
			dz_dx = t.height
			dz_dy = 0.0
		}
		.slope_x_down {
			h = t.base_z + (1.0 - u) * t.height
			dz_dx = -t.height
			dz_dy = 0.0
		}
		.slope_y_up {
			h = t.base_z + v * t.height
			dz_dx = 0.0
			dz_dy = t.height
		}
		.slope_y_down {
			h = t.base_z + (1.0 - v) * t.height
			dz_dx = 0.0
			dz_dy = -t.height
		}
		.slope_xy_down {
			h = t.base_z + (2.0 - u - v) * (t.height * 0.5)
			dz_dx = -t.height * 0.5
			dz_dy = -t.height * 0.5
		}
		.slope_xy_up {
			h = t.base_z + (u + v) * (t.height * 0.5)
			dz_dx = t.height * 0.5
			dz_dy = t.height * 0.5
		}
		.wave {
			freq := f32(2.5)
			amp := f32(0.4)
			phase := f64(global_time * 4.0 + (px + py) * freq)
			h = t.base_z + f32(math.sin(phase)) * amp
			dz_dx = f32(math.cos(phase)) * amp * freq
			dz_dy = f32(math.cos(phase)) * amp * freq
		}
		.empty {
			return -100.0, 0.0, 0.0
		}
	}
	return h, dz_dx, dz_dy
}

// Query continuous surface height H(x, y) and normal slope gradients with smooth edge filtering
pub fn get_surface_info(tiles [][]Tile, px f32, py f32, global_time f32) (bool, f32, f32, f32, TileType) {
	gx := int(math.floor(f64(px)))
	gy := int(math.floor(f64(py)))

	if gx < 0 || gy < 0 || gy >= tiles.len || gx >= tiles[gy].len {
		return false, -100.0, 0.0, 0.0, TileType.empty
	}

	t := tiles[gy][gx]
	if t.tile_type == .empty {
		return false, -100.0, 0.0, 0.0, TileType.empty
	}
	if t.tile_type == .disappearing && !t.is_active {
		return false, -100.0, 0.0, 0.0, TileType.empty
	}

	u := px - f32(gx) // [0.0, 1.0)
	v := py - f32(gy) // [0.0, 1.0)

	h, dz_dx, dz_dy := get_tile_raw_height(t, u, v, px, py, global_time)
	return true, h, dz_dx, dz_dy, t.tile_type
}
