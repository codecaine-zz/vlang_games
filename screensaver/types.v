module main

pub enum Category {
	windows_classics
	after_dark
	hacker_xscreen
	demoscene_synth
	fractals_physics
	ambient_scifi
	novelty_arcade
	modern_physics
}

pub enum EngineType {
	engine_matrix
	engine_pipes
	engine_starfield
	engine_mystify
	engine_maze
	engine_3d_text
	engine_flying_objects
	engine_bezier
	engine_aquarium
	engine_toasters
	engine_bsod
	engine_terminal
	engine_life
	engine_boids
	engine_attractor
	engine_synthwave
	engine_plasma
	engine_doom_fire
	engine_voxel
	engine_tunnel
	engine_chiptune
	engine_hypercube
	engine_fractal
	engine_gravity
	engine_fireworks
	engine_lightning
	engine_rain_ripples
	engine_radar
	engine_dvd_logo
	engine_pong_ai
	engine_snake_ai
	engine_clockwork
	engine_kaleidoscope
	engine_black_hole
	engine_fluid_sph
	engine_softbody_jelly
	engine_ragdoll_physics
	engine_galaxy_nbody
	engine_ferrofluid
	engine_granules_sand
	engine_marble_run
	engine_double_pendulum
	engine_optics_prism
	engine_wave_interference
}

pub struct ScreensaverTemplate {
pub:
	id              int
	name            string
	category        Category
	engine          EngineType
	description     string
	year            string
	primary_color   Color
	secondary_color Color
	accent_color    Color
	speed           f64
	density         int
	custom_text     string
	sub_mode        int
}

pub struct Particle {
pub mut:
	x        f64
	y        f64
	z        f64
	vx       f64
	vy       f64
	vz       f64
	mass     f64 = 1.0
	life     f64
	max_life f64
	color    Color
	size     int
	ch       u8
	active   bool
}

pub struct PipeJoint {
pub mut:
	x     int
	y     int
	z     int
	dir   int // 0:+x, 1:-x, 2:+y, 3:-y, 4:+z, 5:-z
	color Color
}

pub struct PolyVertex {
pub mut:
	x  f64
	y  f64
	vx f64
	vy f64
}

pub struct TrailPoint {
pub:
	p1 PolyVertex
	p2 PolyVertex
	p3 PolyVertex
	p4 PolyVertex
	c  Color
}

pub struct Boid {
pub mut:
	x  f64
	y  f64
	vx f64
	vy f64
	c  Color
}

pub struct SpringPoint {
pub mut:
	x     f64
	y     f64
	prev_x f64
	prev_y f64
	fixed bool
}

pub struct SpringLink {
pub:
	p1     int
	p2     int
	length f64
}

pub struct ScreensaverState {
pub mut:
	time_elapsed    f64
	frame_count     u64
	particles       []Particle
	pipes           []PipeJoint
	poly_verts      []PolyVertex
	trails          []TrailPoint
	boids           []Boid
	spring_pts      []SpringPoint
	spring_links    []SpringLink
	grid_state      [][]u8
	next_grid       [][]u8
	wave_grid1      [][]f64
	wave_grid2      [][]f64
	dvd_x           f64 = 200
	dvd_y           f64 = 150
	dvd_vx          f64 = 3.2
	dvd_vy          f64 = 2.4
	dvd_color       Color = Color{ r: 255, g: 80, b: 80 }
	dvd_corner_hits int
	mouse_x         int
	mouse_y         int
	mouse_down      bool
	mouse_right_down bool
	custom_int1     int
	custom_int2     int
	custom_f1       f64
	custom_f2       f64
	custom_f3       f64
	custom_f4       f64
}
