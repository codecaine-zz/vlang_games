module main

pub enum ObstacleType {
	pillar
	brick_wall
	crystal_spire
	pit
	energy_ring
	turret_pod
	item_pod
}

pub enum PowerUpType {
	speed_boost
	missile_pod
	invincible_shield
	health_pack
	score_gem
}

pub struct Obstacle {
pub mut:
	pos       Vec3
	size      Vec3
	obs_type  ObstacleType
	health    int  = 1
	active    bool = true
	item_type PowerUpType = .score_gem
	rot_y     f32
	timer     f32
}

pub struct WorldTheme {
pub:
	world_num     int
	name          string
	sky_top       Color
	sky_bot       Color
	nebula_col    Color
	floor_color_a Color
	floor_color_b Color
	grid_line_col Color
	sun_color     Color
	track_length  f32
	has_dragon    bool
}

pub fn get_world_theme(world_num int) WorldTheme {
	match world_num {
		1 {
			// World 1: Solar Plains (Emerald & Cyan Cyber Vista)
			return WorldTheme{
				world_num: 1
				name: 'WORLD 1: SOLAR PLAINS'
				sky_top: Color{r: 8, g: 20, b: 58}
				sky_bot: Color{r: 40, g: 100, b: 180}
				nebula_col: Color{r: 30, g: 80, b: 160}
				floor_color_a: Color{r: 25, g: 155, b: 105}
				floor_color_b: Color{r: 15, g: 100, b: 65}
				grid_line_col: Color{r: 80, g: 245, b: 190}
				sun_color: Color{r: 255, g: 220, b: 50}
				track_length: 12000.0
				has_dragon: true
			}
		}
		2 {
			// World 2: Crystal Caverns (Deep Violet & Prismatic Magenta)
			return WorldTheme{
				world_num: 2
				name: 'WORLD 2: CRYSTAL CAVERNS'
				sky_top: Color{r: 20, g: 6, b: 38}
				sky_bot: Color{r: 85, g: 25, b: 120}
				nebula_col: Color{r: 120, g: 30, b: 160}
				floor_color_a: Color{r: 140, g: 40, b: 165}
				floor_color_b: Color{r: 85, g: 20, b: 105}
				grid_line_col: Color{r: 245, g: 130, b: 255}
				sun_color: Color{r: 255, g: 110, b: 230}
				track_length: 14000.0
				has_dragon: true
			}
		}
		3 {
			// World 3: Magma Wasteland (Volcanic Inferno)
			return WorldTheme{
				world_num: 3
				name: 'WORLD 3: MAGMA WASTELAND'
				sky_top: Color{r: 40, g: 6, b: 6}
				sky_bot: Color{r: 140, g: 30, b: 12}
				nebula_col: Color{r: 180, g: 50, b: 20}
				floor_color_a: Color{r: 205, g: 65, b: 25}
				floor_color_b: Color{r: 120, g: 35, b: 12}
				grid_line_col: Color{r: 255, g: 190, b: 40}
				sun_color: Color{r: 255, g: 80, b: 30}
				track_length: 15000.0
				has_dragon: true
			}
		}
		4 {
			// World 4: Cyber Matrix (Neon Hacker Grid)
			return WorldTheme{
				world_num: 4
				name: 'WORLD 4: CYBER MATRIX'
				sky_top: Color{r: 3, g: 12, b: 6}
				sky_bot: Color{r: 10, g: 42, b: 22}
				nebula_col: Color{r: 20, g: 80, b: 45}
				floor_color_a: Color{r: 12, g: 90, b: 48}
				floor_color_b: Color{r: 6, g: 48, b: 24}
				grid_line_col: Color{r: 50, g: 255, b: 130}
				sun_color: Color{r: 110, g: 255, b: 170}
				track_length: 16000.0
				has_dragon: true
			}
		}
		else {
			// World 5: Cosmic Abyss (Deep Hyperspace Void)
			return WorldTheme{
				world_num: 5
				name: 'WORLD 5: COSMIC ABYSS'
				sky_top: Color{r: 4, g: 4, b: 15}
				sky_bot: Color{r: 22, g: 12, b: 58}
				nebula_col: Color{r: 60, g: 40, b: 140}
				floor_color_a: Color{r: 45, g: 70, b: 175}
				floor_color_b: Color{r: 22, g: 35, b: 98}
				grid_line_col: Color{r: 120, g: 215, b: 255}
				sun_color: Color{r: 245, g: 250, b: 255}
				track_length: 18000.0
				has_dragon: true
			}
		}
	}
}

pub fn generate_world_obstacles(world_num int) []Obstacle {
	mut obs := []Obstacle{}
	theme := get_world_theme(world_num)
	track_len := theme.track_length

	mut z := f32(500.0)
	for z < track_len - 1500.0 {
		step_z := f32(220.0 + f64(int(z * 17.0) % 180))
		z += step_z

		pattern := int(z / 380.0) % 6
		match pattern {
			0 {
				// Pair of monolithic pillars with center powerup
				obs << Obstacle{
					pos: vec3(-280, 70, z)
					size: vec3(75, 150, 75)
					obs_type: .pillar
					health: 2
				}
				obs << Obstacle{
					pos: vec3(280, 70, z)
					size: vec3(75, 150, 75)
					obs_type: .pillar
					health: 2
				}
				obs << Obstacle{
					pos: vec3(0, 35, z + 70)
					size: vec3(45, 45, 45)
					obs_type: .item_pod
					item_type: .speed_boost
				}
			}
			1 {
				// Destructible brick wall & high energy ring
				obs << Obstacle{
					pos: vec3(0, 50, z)
					size: vec3(180, 100, 45)
					obs_type: .brick_wall
					health: 3
				}
				obs << Obstacle{
					pos: vec3(0, 190, z)
					size: vec3(95, 95, 35)
					obs_type: .energy_ring
				}
			}
			2 {
				// Prismatic Crystal Spires
				obs << Obstacle{
					pos: vec3(-190, 75, z)
					size: vec3(65, 170, 65)
					obs_type: .crystal_spire
					health: 2
				}
				obs << Obstacle{
					pos: vec3(160, 75, z + 90)
					size: vec3(65, 170, 65)
					obs_type: .crystal_spire
					health: 2
				}
			}
			3 {
				// Chasm Pit requiring jump
				obs << Obstacle{
					pos: vec3(0, 0, z)
					size: vec3(480, 10, 150)
					obs_type: .pit
				}
				obs << Obstacle{
					pos: vec3(0, 140, z + 75)
					size: vec3(45, 45, 45)
					obs_type: .item_pod
					item_type: .invincible_shield
				}
			}
			4 {
				// Dual Turrets
				obs << Obstacle{
					pos: vec3(-210, 45, z)
					size: vec3(75, 85, 75)
					obs_type: .turret_pod
					health: 2
				}
				obs << Obstacle{
					pos: vec3(210, 45, z)
					size: vec3(75, 85, 75)
					obs_type: .turret_pod
					health: 2
				}
			}
			else {
				// Energy speed ring corridor & health container
				obs << Obstacle{
					pos: vec3(0, 125, z)
					size: vec3(105, 105, 35)
					obs_type: .energy_ring
				}
				obs << Obstacle{
					pos: vec3(0, 125, z + 130)
					size: vec3(105, 105, 35)
					obs_type: .energy_ring
				}
				obs << Obstacle{
					pos: vec3(0, 35, z + 65)
					size: vec3(45, 45, 45)
					obs_type: .item_pod
					item_type: .health_pack
				}
			}
		}
	}
	return obs
}
