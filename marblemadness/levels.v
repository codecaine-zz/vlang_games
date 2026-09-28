module main

pub struct LevelDef {
pub:
	name         string
	level_num    int
	start_time   int // Initial time in seconds
	start_x      f32
	start_y      f32
	start_z      f32
	goal_x       f32
	goal_y       f32
	goal_z       f32
	width        int
	height       int
	has_rival    bool
	rival_start_x f32
	rival_start_y f32
	rival_start_z f32
	theme_color  int // Color scheme index (0: classic blue/grey, 1: green, 2: purple/red, 3: golden, etc.)
}

pub struct LevelData {
pub mut:
	def        LevelDef
	tiles      [][]Tile
	munchers   []Vec3
	sweepers   []SweeperDef
	birds      []BirdDef
	bumpers    []Vec3
}

pub struct SweeperDef {
pub:
	start_x f32
	start_y f32
	end_x   f32
	end_y   f32
	z       f32
	speed   f32
}

pub struct BirdDef {
pub:
	spawn_x f32
	spawn_y f32
	spawn_z f32
	patrol_dir_x f32
	patrol_dir_y f32
}

// Helper to create empty grid of tiles
fn make_empty_grid(w int, h int) [][]Tile {
	mut grid := [][]Tile{len: h}
	for y in 0 .. h {
		grid[y] = []Tile{len: w}
		for x in 0 .. w {
			grid[y][x] = Tile{tile_type: .empty, base_z: 0.0}
		}
	}
	return grid
}

// Helper to fill rectangular region of tiles
fn fill_rect(mut grid [][]Tile, x0 int, y0 int, w int, h int, t_type TileType, base_z f32, color_idx int) {
	for y in y0 .. y0 + h {
		if y < 0 || y >= grid.len { continue }
		for x in x0 .. x0 + w {
			if x < 0 || x >= grid[y].len { continue }
			grid[y][x] = Tile{
				tile_type: t_type
				base_z: base_z
				color_idx: color_idx
			}
		}
	}
}

// -------------------------------------------------------------
// LEVEL 1: PRACTICE RACE
// -------------------------------------------------------------
pub fn load_level_1() LevelData {
	def := LevelDef{
		name: 'PRACTICE RACE'
		level_num: 1
		start_time: 65
		start_x: 2.5
		start_y: 2.5
		start_z: 6.0
		goal_x: 10.5
		goal_y: 28.5
		goal_z: 0.0
		width: 16
		height: 32
		has_rival: false
		theme_color: 0
	}

	mut grid := make_empty_grid(def.width, def.height)

	// Section 1: Starting summit (z = 6)
	fill_rect(mut grid, 1, 1, 4, 4, .flat, 6.0, 0)
	
	// Gentle slope down to z = 5 (in +Y direction)
	fill_rect(mut grid, 1, 5, 4, 3, .slope_y_down, 5.0, 1)

	// Landing 1 (z = 5)
	fill_rect(mut grid, 1, 8, 5, 3, .flat, 5.0, 0)

	// Turn East: slope down to z = 4 (in +X direction)
	fill_rect(mut grid, 6, 8, 4, 3, .slope_x_down, 4.0, 1)

	// Landing 2 (z = 4)
	fill_rect(mut grid, 10, 8, 4, 4, .flat, 4.0, 0)

	// Turn South: slope down to z = 2 (in +Y direction)
	fill_rect(mut grid, 10, 12, 4, 4, .slope_y_down, 2.0, 1)
	grid[12][10].height = 2.0
	grid[13][10].height = 2.0
	grid[14][10].height = 2.0
	grid[15][10].height = 2.0
	for y in 12 .. 16 {
		for x in 10 .. 14 {
			grid[y][x].height = 2.0
		}
	}

	// Landing 3 (z = 2)
	fill_rect(mut grid, 9, 16, 5, 4, .flat, 2.0, 0)

	// Final funnel slope down to z = 0
	fill_rect(mut grid, 8, 20, 6, 4, .slope_y_down, 0.0, 1)
	for y in 20 .. 24 {
		for x in 8 .. 14 {
			grid[y][x].height = 2.0
		}
	}

	// Final sprint straightaway (z = 0)
	fill_rect(mut grid, 7, 24, 7, 5, .flat, 0.0, 0)

	// Goal line (z = 0)
	fill_rect(mut grid, 7, 29, 7, 2, .goal, 0.0, 2)

	return LevelData{
		def: def
		tiles: grid
	}
}

// -------------------------------------------------------------
// LEVEL 2: BEGINNER RACE
// -------------------------------------------------------------
pub fn load_level_2() LevelData {
	def := LevelDef{
		name: 'BEGINNER RACE'
		level_num: 2
		start_time: 75
		start_x: 3.5
		start_y: 2.5
		start_z: 8.0
		goal_x: 12.5
		goal_y: 34.5
		goal_z: 0.0
		width: 18
		height: 38
		has_rival: false
		theme_color: 1
	}

	mut grid := make_empty_grid(def.width, def.height)

	// Summit start (z = 8)
	fill_rect(mut grid, 2, 1, 4, 3, .flat, 8.0, 0)

	// Steep chute down to z = 6
	fill_rect(mut grid, 2, 4, 4, 4, .slope_y_down, 6.0, 1)
	for y in 4 .. 8 {
		for x in 2 .. 6 {
			grid[y][x].height = 2.0
		}
	}

	// Mid basin (z = 6) with funnel
	fill_rect(mut grid, 1, 8, 7, 4, .flat, 6.0, 0)

	// Split Path:
	// Path A (East bridge, high and narrow, z = 6 -> 4)
	fill_rect(mut grid, 8, 8, 6, 2, .flat, 6.0, 0)
	fill_rect(mut grid, 12, 10, 3, 5, .slope_y_down, 4.0, 1)
	for y in 10 .. 15 {
		for x in 12 .. 15 {
			grid[y][x].height = 2.0
		}
	}

	// Path B (South steep drop with acid munchers, z = 6 -> 3)
	fill_rect(mut grid, 2, 12, 4, 4, .slope_y_down, 3.0, 1)
	for y in 12 .. 16 {
		for x in 2 .. 6 {
			grid[y][x].height = 3.0
		}
	}
	fill_rect(mut grid, 1, 16, 6, 4, .flat, 3.0, 0)
	// Green acid hazards in Path B
	grid[17][2] = Tile{tile_type: .hazard_acid, base_z: 3.0}
	grid[18][4] = Tile{tile_type: .hazard_acid, base_z: 3.0}

	// Convergence terrace (z = 3)
	fill_rect(mut grid, 5, 20, 9, 5, .flat, 3.0, 0)
	grid[22][8] = Tile{tile_type: .hazard_acid, base_z: 3.0}

	// Vacuum tube shortcut: in at (12, 21), out at (7, 29)
	grid[21][12] = Tile{tile_type: .tube_in, base_z: 3.0, target_x: 7, target_y: 29}

	// Final slopes down to z = 0
	fill_rect(mut grid, 6, 25, 7, 4, .slope_y_down, 0.0, 1)
	for y in 25 .. 29 {
		for x in 6 .. 13 {
			grid[y][x].height = 3.0
		}
	}

	// Exit basin & Goal (z = 0)
	fill_rect(mut grid, 5, 29, 9, 6, .flat, 0.0, 0)
	grid[29][7] = Tile{tile_type: .tube_out, base_z: 0.0}
	grid[31][6] = Tile{tile_type: .hazard_acid, base_z: 0.0}
	grid[31][11] = Tile{tile_type: .hazard_acid, base_z: 0.0}

	// Goal
	fill_rect(mut grid, 8, 35, 6, 2, .goal, 0.0, 2)

	mut munchers := [
		vec3(2.5, 17.5, 3.0),
		vec3(4.5, 18.5, 3.0),
		vec3(8.5, 22.5, 3.0),
		vec3(6.5, 31.5, 0.0),
		vec3(11.5, 31.5, 0.0)
	]

	return LevelData{
		def: def
		tiles: grid
		munchers: munchers
	}
}

// -------------------------------------------------------------
// LEVEL 3: INTERMEDIATE RACE (WAVE TERRAIN & STEEL MARBLE)
// -------------------------------------------------------------
pub fn load_level_3() LevelData {
	def := LevelDef{
		name: 'INTERMEDIATE RACE'
		level_num: 3
		start_time: 80
		start_x: 2.5
		start_y: 2.5
		start_z: 10.0
		goal_x: 10.5
		goal_y: 38.5
		goal_z: 0.0
		width: 18
		height: 42
		has_rival: true
		rival_start_x: 4.5
		rival_start_y: 2.5
		rival_start_z: 10.0
		theme_color: 2
	}

	mut grid := make_empty_grid(def.width, def.height)

	// Summit Start (z = 10)
	fill_rect(mut grid, 1, 1, 6, 3, .flat, 10.0, 0)

	// Upper slope down to z = 8
	fill_rect(mut grid, 1, 4, 5, 4, .slope_y_down, 8.0, 1)
	for y in 4 .. 8 {
		for x in 1 .. 6 {
			grid[y][x].height = 2.0
		}
	}

	// Wave Terrain section 1 (z = 8)
	fill_rect(mut grid, 1, 8, 7, 6, .wave, 8.0, 3)

	// Narrow Ridge East (z = 7)
	fill_rect(mut grid, 8, 10, 6, 3, .flat, 7.0, 0)

	// Downhill S-curve slope to z = 4
	fill_rect(mut grid, 11, 13, 4, 6, .slope_y_down, 4.0, 1)
	for y in 13 .. 19 {
		for x in 11 .. 15 {
			grid[y][x].height = 3.0
		}
	}

	// Wave Terrain section 2 (z = 4)
	fill_rect(mut grid, 6, 19, 9, 6, .wave, 4.0, 3)

	// Narrow switchback ramp to z = 2
	fill_rect(mut grid, 2, 22, 4, 5, .flat, 4.0, 0)
	fill_rect(mut grid, 2, 27, 4, 5, .slope_y_down, 2.0, 1)
	for y in 27 .. 32 {
		for x in 2 .. 6 {
			grid[y][x].height = 2.0
		}
	}

	// Final straight slope to goal (z = 2 -> 0)
	fill_rect(mut grid, 5, 32, 8, 4, .slope_y_down, 0.0, 1)
	for y in 32 .. 36 {
		for x in 5 .. 13 {
			grid[y][x].height = 2.0
		}
	}

	// Goal region (z = 0)
	fill_rect(mut grid, 6, 36, 8, 4, .flat, 0.0, 0)
	fill_rect(mut grid, 6, 39, 8, 2, .goal, 0.0, 2)

	// Bumpers
	mut bumpers := [
		vec3(7.5, 9.5, 7.0),
		vec3(10.5, 14.5, 6.0),
		vec3(3.5, 24.5, 4.0)
	]

	return LevelData{
		def: def
		tiles: grid
		bumpers: bumpers
	}
}

// -------------------------------------------------------------
// LEVEL 4: AERIAL RACE (SKY CATWALKS, TUBES & PTERODACTYLS)
// -------------------------------------------------------------
pub fn load_level_4() LevelData {
	def := LevelDef{
		name: 'AERIAL RACE'
		level_num: 4
		start_time: 80
		start_x: 2.5
		start_y: 2.5
		start_z: 12.0
		goal_x: 10.5
		goal_y: 42.5
		goal_z: 0.0
		width: 20
		height: 46
		has_rival: true
		rival_start_x: 4.5
		rival_start_y: 2.5
		rival_start_z: 12.0
		theme_color: 3
	}

	mut grid := make_empty_grid(def.width, def.height)

	// Summit Start (z = 12)
	fill_rect(mut grid, 1, 1, 5, 3, .flat, 12.0, 0)

	// Sky Catwalk 1 (narrow 2-tile bridge at z = 12)
	fill_rect(mut grid, 2, 4, 3, 5, .flat, 12.0, 0)

	// Catapult spring pad launching across chasm!
	grid[9][3] = Tile{tile_type: .catapult, base_z: 12.0}

	// Landing platform across chasm (z = 9)
	fill_rect(mut grid, 8, 10, 6, 4, .flat, 9.0, 0)

	// Slippery Ice Slope (z = 9 -> 6)
	fill_rect(mut grid, 9, 14, 5, 6, .ice, 6.0, 1)
	for y in 14 .. 20 {
		for x in 9 .. 14 {
			grid[y][x].tile_type = .slope_y_down
			grid[y][x].height = 3.0
		}
	}

	// Mid Terrace (z = 6)
	fill_rect(mut grid, 7, 20, 8, 4, .flat, 6.0, 0)

	// Vacuum Tube Chute across gap: In at (13, 21), Out at (3, 30)
	grid[21][13] = Tile{tile_type: .tube_in, base_z: 6.0, target_x: 3, target_y: 30}

	// Alternate tricky bridge (z = 6 -> 4)
	fill_rect(mut grid, 2, 23, 3, 6, .slope_y_down, 4.0, 1)
	for y in 23 .. 29 {
		for x in 2 .. 5 {
			grid[y][x].height = 2.0
		}
	}

	// Lower terrace (z = 4)
	fill_rect(mut grid, 1, 29, 6, 4, .flat, 4.0, 0)
	grid[30][3] = Tile{tile_type: .tube_out, base_z: 4.0}

	// Slope down to final floor (z = 4 -> 0)
	fill_rect(mut grid, 4, 33, 8, 6, .slope_y_down, 0.0, 1)
	for y in 33 .. 39 {
		for x in 4 .. 12 {
			grid[y][x].height = 4.0
		}
	}

	// Goal region (z = 0)
	fill_rect(mut grid, 6, 39, 9, 5, .flat, 0.0, 0)
	fill_rect(mut grid, 7, 43, 7, 2, .goal, 0.0, 2)

	// Flying Bird Hazards
	birds := [
		BirdDef{spawn_x: 3.0, spawn_y: 8.0, spawn_z: 13.0, patrol_dir_x: 1.0, patrol_dir_y: 0.0},
		BirdDef{spawn_x: 10.0, spawn_y: 22.0, spawn_z: 8.0, patrol_dir_x: -1.0, patrol_dir_y: 0.5}
	]

	return LevelData{
		def: def
		tiles: grid
		birds: birds
	}
}

// -------------------------------------------------------------
// LEVEL 5: SILLY RACE (BROOM SWEEPERS & REVERSE TRICKS)
// -------------------------------------------------------------
pub fn load_level_5() LevelData {
	def := LevelDef{
		name: 'SILLY RACE'
		level_num: 5
		start_time: 80
		start_x: 3.5
		start_y: 2.5
		start_z: 14.0
		goal_x: 12.5
		goal_y: 44.5
		goal_z: 0.0
		width: 20
		height: 48
		has_rival: true
		rival_start_x: 5.5
		rival_start_y: 2.5
		rival_start_z: 14.0
		theme_color: 4
	}

	mut grid := make_empty_grid(def.width, def.height)

	// Start Summit (z = 14)
	fill_rect(mut grid, 2, 1, 5, 3, .flat, 14.0, 0)

	// Ramp (z = 14 -> 11)
	fill_rect(mut grid, 2, 4, 5, 4, .slope_y_down, 11.0, 1)
	for y in 4 .. 8 {
		for x in 2 .. 7 {
			grid[y][x].height = 3.0
		}
	}

	// Sweeper Platform 1 (z = 11)
	fill_rect(mut grid, 1, 8, 8, 4, .flat, 11.0, 0)

	// Tricky diagonal ramp
	fill_rect(mut grid, 8, 10, 6, 4, .slope_x_down, 8.0, 1)
	for y in 10 .. 14 {
		for x in 8 .. 14 {
			grid[y][x].height = 3.0
		}
	}

	// Sweeper Platform 2 (z = 8)
	fill_rect(mut grid, 10, 14, 8, 5, .flat, 8.0, 0)

	// Wacky bouncy bumpers and ice
	fill_rect(mut grid, 6, 19, 7, 6, .ice, 6.0, 1)
	for y in 19 .. 25 {
		for x in 6 .. 13 {
			grid[y][x].tile_type = .slope_y_down
			grid[y][x].height = 2.0
		}
	}

	// Platform 3 (z = 4)
	fill_rect(mut grid, 4, 25, 10, 5, .flat, 4.0, 0)

	// Sweeper Platform 3 & Slopes to z = 0
	fill_rect(mut grid, 6, 30, 8, 8, .slope_y_down, 0.0, 1)
	for y in 30 .. 38 {
		for x in 6 .. 14 {
			grid[y][x].height = 4.0
		}
	}

	// Finish basin (z = 0)
	fill_rect(mut grid, 7, 38, 10, 7, .flat, 0.0, 0)
	fill_rect(mut grid, 9, 44, 7, 2, .goal, 0.0, 2)

	// Floor Sweepers
	sweepers := [
		SweeperDef{start_x: 1.5, start_y: 9.5, end_x: 7.5, end_y: 9.5, z: 11.0, speed: 2.2},
		SweeperDef{start_x: 10.5, start_y: 16.5, end_x: 16.5, end_y: 16.5, z: 8.0, speed: 2.8},
		SweeperDef{start_x: 4.5, start_y: 27.5, end_x: 12.5, end_y: 27.5, z: 4.0, speed: 3.2}
	]

	bumpers := [
		vec3(6.5, 20.5, 6.0),
		vec3(12.5, 22.5, 5.0)
	]

	return LevelData{
		def: def
		tiles: grid
		sweepers: sweepers
		bumpers: bumpers
	}
}

// -------------------------------------------------------------
// LEVEL 6: ULTIMATE RACE (THE FINAL GAUNTLET)
// -------------------------------------------------------------
pub fn load_level_6() LevelData {
	def := LevelDef{
		name: 'ULTIMATE RACE'
		level_num: 6
		start_time: 85
		start_x: 3.5
		start_y: 2.5
		start_z: 16.0
		goal_x: 11.5
		goal_y: 48.5
		goal_z: 0.0
		width: 22
		height: 52
		has_rival: true
		rival_start_x: 5.5
		rival_start_y: 2.5
		rival_start_z: 16.0
		theme_color: 5
	}

	mut grid := make_empty_grid(def.width, def.height)

	// Summit (z = 16)
	fill_rect(mut grid, 2, 1, 6, 3, .flat, 16.0, 0)

	// Disappearing tile bridge (z = 16)
	fill_rect(mut grid, 3, 4, 4, 4, .disappearing, 16.0, 1)

	// Steep drop 1 (z = 16 -> 12)
	fill_rect(mut grid, 2, 8, 6, 4, .slope_y_down, 12.0, 1)
	for y in 8 .. 12 {
		for x in 2 .. 8 {
			grid[y][x].height = 4.0
		}
	}

	// Mid Terrace 1 with Acid Munchers (z = 12)
	fill_rect(mut grid, 1, 12, 10, 4, .flat, 12.0, 0)
	grid[13][4] = Tile{tile_type: .hazard_acid, base_z: 12.0}
	grid[14][7] = Tile{tile_type: .hazard_acid, base_z: 12.0}

	// East catwalk & Tube in: In at (13, 14), Out at (4, 25)
	fill_rect(mut grid, 10, 13, 5, 3, .flat, 12.0, 0)
	grid[14][13] = Tile{tile_type: .tube_in, base_z: 12.0, target_x: 4, target_y: 25}

	// Wave Zone (z = 12 -> 8)
	fill_rect(mut grid, 2, 16, 7, 5, .slope_y_down, 8.0, 1)
	for y in 16 .. 21 {
		for x in 2 .. 9 {
			grid[y][x].height = 4.0
		}
	}
	fill_rect(mut grid, 2, 21, 8, 5, .wave, 8.0, 3)

	// Tube exit & Platform (z = 6)
	fill_rect(mut grid, 2, 26, 8, 4, .flat, 6.0, 0)
	grid[25][4] = Tile{tile_type: .tube_out, base_z: 6.0}

	// Disappearing Bridge (z = 6)
	fill_rect(mut grid, 9, 27, 6, 3, .disappearing, 6.0, 1)

	// Catapult to final run (z = 6)
	grid[28][14] = Tile{tile_type: .catapult, base_z: 6.0}

	// Final downhill gauntlet (z = 6 -> 0)
	fill_rect(mut grid, 5, 32, 11, 8, .slope_y_down, 0.0, 1)
	for y in 32 .. 40 {
		for x in 5 .. 16 {
			grid[y][x].height = 6.0
		}
	}

	// Final trophy basin (z = 0)
	fill_rect(mut grid, 6, 40, 12, 9, .flat, 0.0, 0)
	grid[42][8] = Tile{tile_type: .hazard_acid, base_z: 0.0}
	grid[43][14] = Tile{tile_type: .hazard_acid, base_z: 0.0}

	// Grand Finish Goal
	fill_rect(mut grid, 8, 48, 8, 2, .goal, 0.0, 2)

	munchers := [
		vec3(4.5, 13.5, 12.0),
		vec3(7.5, 14.5, 12.0),
		vec3(8.5, 42.5, 0.0),
		vec3(14.5, 43.5, 0.0)
	]

	sweepers := [
		SweeperDef{start_x: 2.5, start_y: 28.5, end_x: 8.5, end_y: 28.5, z: 6.0, speed: 3.5},
		SweeperDef{start_x: 6.5, start_y: 44.5, end_x: 16.5, end_y: 44.5, z: 0.0, speed: 4.0}
	]

	birds := [
		BirdDef{spawn_x: 5.0, spawn_y: 18.0, spawn_z: 14.0, patrol_dir_x: 1.0, patrol_dir_y: 0.2}
	]

	bumpers := [
		vec3(4.5, 34.5, 4.0),
		vec3(13.5, 36.5, 2.0)
	]

	return LevelData{
		def: def
		tiles: grid
		munchers: munchers
		sweepers: sweepers
		birds: birds
		bumpers: bumpers
	}
}

pub fn get_level_by_number(level_num int) LevelData {
	match level_num {
		1 { return load_level_1() }
		2 { return load_level_2() }
		3 { return load_level_3() }
		4 { return load_level_4() }
		5 { return load_level_5() }
		6 { return load_level_6() }
		else { return load_level_1() }
	}
}
