module main

import math
import rand

pub enum ToolType {
	grab
	grav_gun
	impulse_blaster
	tether
	spawn_ragdoll
	spawn_barrel
	spawn_ball
	slice
	bomb
}

pub enum ArenaType {
	funhouse
	staircase
	zero_g
}

pub enum BodyPart {
	head
	neck
	pelvis
	l_elbow
	r_elbow
	l_hand
	r_hand
	l_knee
	r_knee
	l_foot
	r_foot
}

pub enum ObstacleType {
	platform
	trampoline
	spinner
	fan
	gravity_well
	portal
	bumper
}

pub struct PointMass {
pub mut:
	x           f64
	y           f64
	old_x       f64
	old_y       f64
	mass        f64
	radius      f64
	pinned      bool
	color       Color
	part_type   BodyPart
	dismembered bool
	id          int
}

pub struct DistanceConstraint {
pub mut:
	p1_idx      int
	p2_idx      int
	rest_length f64
	stiffness   f64
	breakable   bool
	max_stress  f64
	color       Color
	active      bool = true
}

pub struct Ragdoll {
pub mut:
	id               int
	points           []PointMass
	constraints      []DistanceConstraint
	expression       string = 'normal' // normal, shock, dizzy
	expression_timer f64
	color            Color
}

pub struct Obstacle {
pub mut:
	obs_type      ObstacleType
	x             f64
	y             f64
	w             f64
	h             f64
	r             f64
	angle         f64
	angular_vel   f64
	bounciness    f64 = 0.8
	portal_dest_x f64
	portal_dest_y f64
	color         Color
	label         string
}

pub struct Prop {
pub mut:
	x         f64
	y         f64
	old_x     f64
	old_y     f64
	radius    f64
	mass      f64
	prop_type string // barrel, ball
	color     Color
}

pub struct Tether {
pub mut:
	p1_ragdoll_idx int = -1
	p1_point_idx   int = -1
	p1_prop_idx    int = -1
	p1_obs_x       f64
	p1_obs_y       f64

	p2_ragdoll_idx int = -1
	p2_point_idx   int = -1
	p2_prop_idx    int = -1
	p2_obs_x       f64
	p2_obs_y       f64

	rest_length    f64
	stiffness      f64 = 0.5
	color          Color
	active         bool = true
}

pub struct Particle {
pub mut:
	x             f64
	y             f64
	vx            f64
	vy            f64
	life          f64
	max_life      f64
	size          f64
	color         Color
	particle_type string // spark, blood, smoke, shockwave
}

pub struct RagdollGame {
pub mut:
	ragdolls               []Ragdoll
	obstacles              []Obstacle
	props                  []Prop
	tethers                []Tether
	particles              []Particle
	active_tool            ToolType  = .grab
	active_arena           ArenaType = .funhouse
	gravity                f64 = 980.0
	bounciness             f64 = 0.65
	timescale              f64 = 1.0
	dragged_ragdoll_idx    int = -1
	dragged_point_idx      int = -1
	dragged_prop_idx       int = -1
	grav_held_ragdoll_idx  int = -1
	grav_held_point_idx    int = -1
	grav_held_prop_idx     int = -1
	tether_start_ragdoll   int = -1
	tether_start_point     int = -1
	tether_start_prop      int = -1
	tether_start_x         f64
	tether_start_y         f64
	tether_active_setting  bool
	prev_mouse_x           f64
	prev_mouse_y           f64
	sound_event_thud       bool
	thud_intensity         f64
	sound_event_crunch     bool
	sound_event_explosion  bool
	sound_event_zap        bool
	sound_event_boing      bool
	sound_event_bumper     bool
	sound_event_tether     bool
	next_ragdoll_id        int
	fps_display            int = 60
	frame_counter          int
	fps_timer              f64
}

pub fn new_ragdoll_game() RagdollGame {
	mut game := RagdollGame{}
	game.load_arena(.funhouse)
	return game
}

pub fn (mut g RagdollGame) load_arena(arena ArenaType) {
	g.active_arena = arena
	g.ragdolls.clear()
	g.obstacles.clear()
	g.props.clear()
	g.tethers.clear()
	g.particles.clear()
	g.dragged_ragdoll_idx = -1
	g.dragged_point_idx = -1
	g.dragged_prop_idx = -1
	g.grav_held_ragdoll_idx = -1
	g.grav_held_point_idx = -1
	g.grav_held_prop_idx = -1
	g.tether_active_setting = false

	match arena {
		.funhouse {
			g.gravity = 980.0
			// Floor
			g.obstacles << Obstacle{
				obs_type: .platform
				x: 40, y: 540, w: 720, h: 20
				color: Color{r: 60, g: 80, b: 120}
				label: 'FLOOR PLATFORM'
			}
			// Ramps
			g.obstacles << Obstacle{
				obs_type: .platform
				x: 40, y: 220, w: 220, h: 16
				angle: 0.2
				color: Color{r: 80, g: 100, b: 150}
				label: 'SLIDE RAMP 1'
			}
			g.obstacles << Obstacle{
				obs_type: .platform
				x: 540, y: 320, w: 220, h: 16
				angle: -0.2
				color: Color{r: 80, g: 100, b: 150}
				label: 'SLIDE RAMP 2'
			}
			// Trampoline
			g.obstacles << Obstacle{
				obs_type: .trampoline
				x: 270, y: 520, w: 260, h: 20
				bounciness: 1.6
				color: Color{r: 255, g: 80, b: 160}
				label: 'BOUNCY TRAMPOLINE'
			}
			// Rotating spinner
			g.obstacles << Obstacle{
				obs_type: .spinner
				x: 400, y: 200, r: 85
				angular_vel: 2.0
				color: Color{r: 255, g: 200, b: 50}
				label: 'SPINNER'
			}
			// Pinball Bumpers
			g.obstacles << Obstacle{
				obs_type: .bumper
				x: 180, y: 380, r: 28
				bounciness: 2.0
				color: Color{r: 0, g: 240, b: 255}
				label: 'BUMPER'
			}
			g.obstacles << Obstacle{
				obs_type: .bumper
				x: 620, y: 420, r: 28
				bounciness: 2.0
				color: Color{r: 0, g: 240, b: 255}
				label: 'BUMPER'
			}

			// Spawn initial Ragdoll & Props
			g.spawn_ragdoll_at(400, 80, Color{r: 255, g: 120, b: 80})
			g.spawn_prop_at(350, 60, 'barrel')
			g.spawn_prop_at(450, 60, 'ball')
		}
		.staircase {
			g.gravity = 1100.0
			g.obstacles << Obstacle{
				obs_type: .platform
				x: 40, y: 550, w: 720, h: 20
				color: Color{r: 70, g: 70, b: 90}
				label: 'BOTTOM GROUND'
			}
			for i in 0 .. 7 {
				g.obstacles << Obstacle{
					obs_type: .platform
					x: 80 + f64(i * 85), y: 170 + f64(i * 48), w: 85, h: 18
					color: Color{r: 120 + u8(i * 15), g: 90, b: 140}
					label: 'STEP'
				}
			}
			for i in 0 .. 3 {
				g.spawn_prop_at(620 + f64(i * 38), 510, 'barrel')
			}
			g.spawn_ragdoll_at(100, 100, Color{r: 80, g: 220, b: 120})
			g.spawn_ragdoll_at(180, 110, Color{r: 240, g: 90, b: 200})
		}
		.zero_g {
			g.gravity = 120.0 // Low gravity
			g.obstacles << Obstacle{
				obs_type: .platform
				x: 40, y: 550, w: 720, h: 16
				color: Color{r: 40, g: 180, b: 220}
				label: 'LAB FLOOR'
			}
			g.obstacles << Obstacle{
				obs_type: .fan
				x: 90, y: 440, w: 150, h: 110
				color: Color{r: 100, g: 255, b: 200}
				label: 'FAN UPDRAFT'
			}
			g.obstacles << Obstacle{
				obs_type: .gravity_well
				x: 400, y: 280, r: 80
				color: Color{r: 200, g: 80, b: 255}
				label: 'GRAVITY WELL'
			}
			g.obstacles << Obstacle{
				obs_type: .portal
				x: 650, y: 470, r: 35
				portal_dest_x: 650, portal_dest_y: 130
				color: Color{r: 255, g: 140, b: 0}
				label: 'PORTAL IN'
			}
			g.obstacles << Obstacle{
				obs_type: .portal
				x: 650, y: 130, r: 35
				portal_dest_x: 650, portal_dest_y: 470
				color: Color{r: 0, g: 160, b: 255}
				label: 'PORTAL OUT'
			}

			g.spawn_ragdoll_at(160, 240, Color{r: 0, g: 220, b: 255})
			g.spawn_ragdoll_at(600, 280, Color{r: 255, g: 220, b: 50})
			g.spawn_prop_at(400, 160, 'ball')
			g.spawn_prop_at(400, 400, 'ball')
		}
	}
}

pub fn (mut g RagdollGame) spawn_ragdoll_at(cx f64, cy f64, col Color) int {
	g.next_ragdoll_id++
	mut r := Ragdoll{
		id: g.next_ragdoll_id
		color: col
	}

	pts := [
		PointMass{x: cx, y: cy - 45, old_x: cx, old_y: cy - 45, mass: 1.2, radius: 14, color: col, part_type: .head, id: 0},
		PointMass{x: cx, y: cy - 25, old_x: cx, old_y: cy - 25, mass: 1.5, radius: 10, color: col, part_type: .neck, id: 1},
		PointMass{x: cx, y: cy + 15, old_x: cx, old_y: cy + 15, mass: 1.8, radius: 12, color: col, part_type: .pelvis, id: 2},
		PointMass{x: cx - 22, y: cy - 15, old_x: cx - 22, old_y: cy - 15, mass: 0.8, radius: 7, color: col, part_type: .l_elbow, id: 3},
		PointMass{x: cx + 22, y: cy - 15, old_x: cx + 22, old_y: cy - 15, mass: 0.8, radius: 7, color: col, part_type: .r_elbow, id: 4},
		PointMass{x: cx - 38, y: cy - 5, old_x: cx - 38, old_y: cy - 5, mass: 0.6, radius: 6, color: col, part_type: .l_hand, id: 5},
		PointMass{x: cx + 38, y: cy - 5, old_x: cx + 38, old_y: cy - 5, mass: 0.6, radius: 6, color: col, part_type: .r_hand, id: 6},
		PointMass{x: cx - 14, y: cy + 45, old_x: cx - 14, old_y: cy + 45, mass: 1.0, radius: 8, color: col, part_type: .l_knee, id: 7},
		PointMass{x: cx + 14, y: cy + 45, old_x: cx + 14, old_y: cy + 45, mass: 1.0, radius: 8, color: col, part_type: .r_knee, id: 8},
		PointMass{x: cx - 16, y: cy + 75, old_x: cx - 16, old_y: cy + 75, mass: 0.8, radius: 7, color: col, part_type: .l_foot, id: 9},
		PointMass{x: cx + 16, y: cy + 75, old_x: cx + 16, old_y: cy + 75, mass: 0.8, radius: 7, color: col, part_type: .r_foot, id: 10},
	]
	r.points = pts

	mut create_c := fn (p1 int, p2 int, pts []PointMass, stiffness f64, breakable bool, max_stress f64, col Color) DistanceConstraint {
		dx := pts[p1].x - pts[p2].x
		dy := pts[p1].y - pts[p2].y
		len := math.sqrt(dx * dx + dy * dy)
		return DistanceConstraint{
			p1_idx: p1
			p2_idx: p2
			rest_length: len
			stiffness: stiffness
			breakable: breakable
			max_stress: max_stress
			color: col
			active: true
		}
	}

	// Anatomical skeleton sticks
	r.constraints << create_c(0, 1, r.points, 0.95, false, 0, col) // Head-Neck
	r.constraints << create_c(1, 2, r.points, 0.95, false, 0, col) // Neck-Pelvis

	r.constraints << create_c(1, 3, r.points, 0.9, true, 260.0, col) // Neck-L_Elbow
	r.constraints << create_c(1, 4, r.points, 0.9, true, 260.0, col) // Neck-R_Elbow
	r.constraints << create_c(3, 5, r.points, 0.9, true, 200.0, col) // L_Elbow-L_Hand
	r.constraints << create_c(4, 6, r.points, 0.9, true, 200.0, col) // R_Elbow-R_Hand

	r.constraints << create_c(2, 7, r.points, 0.9, true, 280.0, col) // Pelvis-L_Knee
	r.constraints << create_c(2, 8, r.points, 0.9, true, 280.0, col) // Pelvis-R_Knee
	r.constraints << create_c(7, 9, r.points, 0.9, true, 220.0, col) // L_Knee-L_Foot
	r.constraints << create_c(8, 10, r.points, 0.9, true, 220.0, col) // R_Knee-R_Foot

	// Flexible spine posture support
	r.constraints << create_c(0, 2, r.points, 0.35, false, 0, col) // Head-Pelvis soft spine

	idx := g.ragdolls.len
	g.ragdolls << r
	return idx
}

pub fn (mut g RagdollGame) spawn_prop_at(cx f64, cy f64, prop_type string) {
	mut p := Prop{
		x: cx, y: cy
		old_x: cx, old_y: cy
		prop_type: prop_type
	}
	if prop_type == 'barrel' {
		p.radius = 16.0
		p.mass = 2.5
		p.color = Color{r: 220, g: 60, b: 40}
	} else {
		p.radius = 14.0
		p.mass = 1.2
		p.color = Color{r: 40, g: 220, b: 240}
	}
	g.props << p
}

pub fn (mut g RagdollGame) update(dt_raw f64, mx int, my int, mouse_down bool, mouse_clicked bool) {
	dt := math.min(dt_raw, 0.033) * g.timescale
	fmx := f64(mx)
	fmy := f64(my)

	mouse_vx := (fmx - g.prev_mouse_x) / math.max(0.001, dt_raw)
	mouse_vy := (fmy - g.prev_mouse_y) / math.max(0.001, dt_raw)
	g.prev_mouse_x = fmx
	g.prev_mouse_y = fmy

	g.sound_event_thud = false
	g.sound_event_crunch = false
	g.sound_event_explosion = false
	g.sound_event_zap = false
	g.sound_event_boing = false
	g.sound_event_bumper = false
	g.sound_event_tether = false

	g.frame_counter++
	g.fps_timer += dt_raw
	if g.fps_timer >= 1.0 {
		g.fps_display = g.frame_counter
		g.frame_counter = 0
		g.fps_timer = 0
	}

	for mut obs in g.obstacles {
		if obs.obs_type == .spinner {
			obs.angle += obs.angular_vel * dt
		}
	}

	// Process tool inputs
	g.handle_tool_inputs(mx, my, mouse_down, mouse_clicked, mouse_vx, mouse_vy)

	// Physics sub-stepping (8 sub-steps per frame)
	sub_steps := 8
	sub_dt := dt / f64(sub_steps)

	for _ in 0 .. sub_steps {
		g.physics_sub_step(sub_dt, fmx, fmy, mouse_vx, mouse_vy)
	}

	// Particles lifetime
	for i := g.particles.len - 1; i >= 0; i-- {
		mut part := g.particles[i]
		part.x += part.vx * dt
		part.y += part.vy * dt
		part.life -= dt
		if part.particle_type == 'smoke' || part.particle_type == 'shockwave' {
			part.size += dt * 25.0
		}
		if part.life <= 0 {
			g.particles.delete(i)
		} else {
			g.particles[i] = part
		}
	}

	// Expressions timer
	for mut r in g.ragdolls {
		if r.expression != 'normal' {
			r.expression_timer -= dt
			if r.expression_timer <= 0 {
				r.expression = 'normal'
			}
		}
	}
}

fn (mut g RagdollGame) handle_tool_inputs(mx int, my int, mouse_down bool, mouse_clicked bool, _ f64, _ f64) {
	fmx := f64(mx)
	fmy := f64(my)

	// Playfield bounds check
	if my < 50 || my > 550 {
		return
	}

	if mouse_clicked {
		match g.active_tool {
			.spawn_ragdoll {
				col := Color{r: u8((rand.intn(180) or { 0 }) + 70), g: u8((rand.intn(180) or { 0 }) + 70), b: u8((rand.intn(180) or { 0 }) + 70)}
				g.spawn_ragdoll_at(fmx, fmy, col)
			}
			.spawn_barrel {
				g.spawn_prop_at(fmx, fmy, 'barrel')
			}
			.spawn_ball {
				g.spawn_prop_at(fmx, fmy, 'ball')
			}
			.impulse_blaster {
				g.trigger_shockwave(fmx, fmy, 160.0, 1600.0)
				g.sound_event_zap = true
			}
			.bomb {
				g.trigger_explosion(fmx, fmy)
			}
			.slice {
				g.slice_constraints_at(fmx, fmy, 28.0)
			}
			.tether {
				if !g.tether_active_setting {
					g.tether_start_x = fmx
					g.tether_start_y = fmy
					g.tether_start_ragdoll, g.tether_start_point = g.find_closest_ragdoll_point(fmx, fmy, 30.0)
					g.tether_start_prop = g.find_closest_prop(fmx, fmy, 30.0)
					g.tether_active_setting = true
				} else {
					end_ragdoll, end_point := g.find_closest_ragdoll_point(fmx, fmy, 30.0)
					end_prop := g.find_closest_prop(fmx, fmy, 30.0)

					dx := fmx - g.tether_start_x
					dy := fmy - g.tether_start_y
					dist := math.sqrt(dx * dx + dy * dy)

					if dist > 10.0 {
						t := Tether{
							p1_ragdoll_idx: g.tether_start_ragdoll
							p1_point_idx: g.tether_start_point
							p1_prop_idx: g.tether_start_prop
							p1_obs_x: g.tether_start_x
							p1_obs_y: g.tether_start_y
							p2_ragdoll_idx: end_ragdoll
							p2_point_idx: end_point
							p2_prop_idx: end_prop
							p2_obs_x: fmx
							p2_obs_y: fmy
							rest_length: dist
							stiffness: 0.5
							color: Color{r: 255, g: 220, b: 0}
						}
						g.tethers << t
						g.sound_event_tether = true
					}
					g.tether_active_setting = false
				}
			}
			else {}
		}
	}

	if mouse_down {
		if g.active_tool == .grab {
			if g.dragged_point_idx == -1 && g.dragged_prop_idx == -1 {
				r_idx, p_idx := g.find_closest_ragdoll_point(fmx, fmy, 40.0)
				if r_idx != -1 {
					g.dragged_ragdoll_idx = r_idx
					g.dragged_point_idx = p_idx
				} else {
					pr_idx := g.find_closest_prop(fmx, fmy, 40.0)
					if pr_idx != -1 {
						g.dragged_prop_idx = pr_idx
					}
				}
			}
		} else if g.active_tool == .grav_gun {
			if g.grav_held_point_idx == -1 && g.grav_held_prop_idx == -1 {
				r_idx, p_idx := g.find_closest_ragdoll_point(fmx, fmy, 160.0)
				if r_idx != -1 {
					g.grav_held_ragdoll_idx = r_idx
					g.grav_held_point_idx = p_idx
					g.sound_event_zap = true
				} else {
					pr_idx := g.find_closest_prop(fmx, fmy, 160.0)
					if pr_idx != -1 {
						g.grav_held_prop_idx = pr_idx
						g.sound_event_zap = true
					}
				}
			}
		}
	} else {
		g.dragged_ragdoll_idx = -1
		g.dragged_point_idx = -1
		g.dragged_prop_idx = -1
		g.grav_held_ragdoll_idx = -1
		g.grav_held_point_idx = -1
		g.grav_held_prop_idx = -1
	}
}

fn (mut g RagdollGame) physics_sub_step(sub_dt f64, fmx f64, fmy f64, mouse_vx f64, mouse_vy f64) {
	sub_damping := 0.999

	// 1. Point mass Verlet integration
	for mut r in g.ragdolls {
		for mut p in r.points {
			if p.pinned { continue }
			cur_vx := (p.x - p.old_x) * sub_damping
			cur_vy := (p.y - p.old_y) * sub_damping
			p.old_x = p.x
			p.old_y = p.y
			p.x += cur_vx
			p.y += cur_vy + g.gravity * sub_dt * sub_dt
		}
	}

	// 2. Props Verlet integration
	for mut pr in g.props {
		cur_vx := (pr.x - pr.old_x) * sub_damping
		cur_vy := (pr.y - pr.old_y) * sub_damping
		pr.old_x = pr.x
		pr.old_y = pr.y
		pr.x += cur_vx
		pr.y += cur_vy + g.gravity * sub_dt * sub_dt
	}

	// Smooth mouse drag application & throw velocity
	if g.dragged_ragdoll_idx >= 0 && g.dragged_ragdoll_idx < g.ragdolls.len {
		mut r := &g.ragdolls[g.dragged_ragdoll_idx]
		if g.dragged_point_idx >= 0 && g.dragged_point_idx < r.points.len {
			mut p := &r.points[g.dragged_point_idx]
			p.x = fmx
			p.y = fmy
			p.old_x = fmx - mouse_vx * sub_dt
			p.old_y = fmy - mouse_vy * sub_dt
		}
	}
	if g.dragged_prop_idx >= 0 && g.dragged_prop_idx < g.props.len {
		mut pr := &g.props[g.dragged_prop_idx]
		pr.x = fmx
		pr.y = fmy
		pr.old_x = fmx - mouse_vx * sub_dt
		pr.old_y = fmy - mouse_vy * sub_dt
	}

	// Gravity Gun Tractor Beam
	if g.grav_held_ragdoll_idx >= 0 && g.grav_held_ragdoll_idx < g.ragdolls.len {
		mut r := &g.ragdolls[g.grav_held_ragdoll_idx]
		if g.grav_held_point_idx >= 0 && g.grav_held_point_idx < r.points.len {
			mut p := &r.points[g.grav_held_point_idx]
			dx := fmx - p.x
			dy := fmy - p.y
			dist := math.sqrt(dx * dx + dy * dy)
			if dist > 4.0 {
				p.x += dx * 0.12
				p.y += dy * 0.12
				p.old_x = p.x - mouse_vx * sub_dt * 0.8
				p.old_y = p.y - mouse_vy * sub_dt * 0.8
			}
			if (rand.intn(4) or { 0 }) == 0 {
				g.particles << Particle{
					x: p.x, y: p.y
					vx: (rand.f64() * 2.0 - 1.0) * 40.0
					vy: (rand.f64() * 2.0 - 1.0) * 40.0
					life: 0.3, max_life: 0.3, size: 4.0
					color: Color{r: 0, g: 255, b: 220}
					particle_type: 'spark'
				}
			}
		}
	}
	if g.grav_held_prop_idx >= 0 && g.grav_held_prop_idx < g.props.len {
		mut pr := &g.props[g.grav_held_prop_idx]
		dx := fmx - pr.x
		dy := fmy - pr.y
		dist := math.sqrt(dx * dx + dy * dy)
		if dist > 4.0 {
			pr.x += dx * 0.12
			pr.y += dy * 0.12
			pr.old_x = pr.x - mouse_vx * sub_dt * 0.8
			pr.old_y = pr.y - mouse_vy * sub_dt * 0.8
		}
	}

	// 3. Solve distance constraints (3 iterations per substep for rigid stability)
	for _ in 0 .. 3 {
		for mut r in g.ragdolls {
			for mut c in r.constraints {
				if !c.active { continue }
				mut p1 := &r.points[c.p1_idx]
				mut p2 := &r.points[c.p2_idx]

				dx := p2.x - p1.x
				dy := p2.y - p1.y
				dist := math.sqrt(dx * dx + dy * dy)
				if dist < 0.0001 { continue }

				delta := (dist - c.rest_length) / dist

				stress := math.abs(dist - c.rest_length)
				if c.breakable && stress > c.max_stress {
					c.active = false
					p1.dismembered = true
					p2.dismembered = true
					g.sound_event_crunch = true
					r.expression = 'dizzy'
					r.expression_timer = 2.0
					for _ in 0 .. 5 {
						g.particles << Particle{
							x: (p1.x + p2.x) * 0.5
							y: (p1.y + p2.y) * 0.5
							vx: (rand.f64() * 2.0 - 1.0) * 100.0
							vy: (rand.f64() * 2.0 - 1.0) * 100.0 - 40.0
							life: 0.5, max_life: 0.5, size: 5.0
							color: Color{r: 240, g: 20, b: 20}
							particle_type: 'blood'
						}
					}
					continue
				}

				w1 := if p1.pinned { 0.0 } else { 0.5 }
				w2 := if p2.pinned { 0.0 } else { 0.5 }

				p1.x += dx * delta * c.stiffness * w1
				p1.y += dy * delta * c.stiffness * w1
				p2.x -= dx * delta * c.stiffness * w2
				p2.y -= dy * delta * c.stiffness * w2
			}
		}
	}

	// 4. Solve active tethers
	for t in g.tethers {
		if !t.active { continue }
		mut p1x := t.p1_obs_x
		mut p1y := t.p1_obs_y
		if t.p1_ragdoll_idx >= 0 && t.p1_ragdoll_idx < g.ragdolls.len {
			p1x = g.ragdolls[t.p1_ragdoll_idx].points[t.p1_point_idx].x
			p1y = g.ragdolls[t.p1_ragdoll_idx].points[t.p1_point_idx].y
		} else if t.p1_prop_idx >= 0 && t.p1_prop_idx < g.props.len {
			p1x = g.props[t.p1_prop_idx].x
			p1y = g.props[t.p1_prop_idx].y
		}

		mut p2x := t.p2_obs_x
		mut p2y := t.p2_obs_y
		if t.p2_ragdoll_idx >= 0 && t.p2_ragdoll_idx < g.ragdolls.len {
			p2x = g.ragdolls[t.p2_ragdoll_idx].points[t.p2_point_idx].x
			p2y = g.ragdolls[t.p2_ragdoll_idx].points[t.p2_point_idx].y
		} else if t.p2_prop_idx >= 0 && t.p2_prop_idx < g.props.len {
			p2x = g.props[t.p2_prop_idx].x
			p2y = g.props[t.p2_prop_idx].y
		}

		dx := p2x - p1x
		dy := p2y - p1y
		dist := math.sqrt(dx * dx + dy * dy)
		if dist > t.rest_length {
			delta := (dist - t.rest_length) / dist
			fx := dx * delta * t.stiffness * 0.4
			fy := dy * delta * t.stiffness * 0.4

			if t.p1_ragdoll_idx >= 0 && t.p1_ragdoll_idx < g.ragdolls.len {
				g.ragdolls[t.p1_ragdoll_idx].points[t.p1_point_idx].x += fx
				g.ragdolls[t.p1_ragdoll_idx].points[t.p1_point_idx].y += fy
			} else if t.p1_prop_idx >= 0 && t.p1_prop_idx < g.props.len {
				g.props[t.p1_prop_idx].x += fx
				g.props[t.p1_prop_idx].y += fy
			}

			if t.p2_ragdoll_idx >= 0 && t.p2_ragdoll_idx < g.ragdolls.len {
				g.ragdolls[t.p2_ragdoll_idx].points[t.p2_point_idx].x -= fx
				g.ragdolls[t.p2_ragdoll_idx].points[t.p2_point_idx].y -= fy
			} else if t.p2_prop_idx >= 0 && t.p2_prop_idx < g.props.len {
				g.props[t.p2_prop_idx].x -= fx
				g.props[t.p2_prop_idx].y -= fy
			}
		}
	}

	// 5. Bounds & Obstacle Collisions
	min_x := 30.0
	max_x := 770.0
	min_y := 50.0
	max_y := 540.0

	for mut r in g.ragdolls {
		for mut p in r.points {
			// Screen boundaries (using correct sub-step displacement)
			cur_vy := p.y - p.old_y
			cur_vx := p.x - p.old_x

			if p.y > max_y - p.radius {
				if cur_vy > 0 {
					p.y = max_y - p.radius
					p.old_y = p.y + cur_vy * g.bounciness
					p.old_x = p.x - cur_vx * 0.85
					if cur_vy > 2.5 {
						g.sound_event_thud = true
						g.thud_intensity = cur_vy / 10.0
						if cur_vy > 6.0 {
							r.expression = 'shock'
							r.expression_timer = 1.2
						}
					}
				}
			}
			if p.x < min_x + p.radius {
				if cur_vx < 0 {
					p.x = min_x + p.radius
					p.old_x = p.x + cur_vx * g.bounciness
				}
			}
			if p.x > max_x - p.radius {
				if cur_vx > 0 {
					p.x = max_x - p.radius
					p.old_x = p.x + cur_vx * g.bounciness
				}
			}
			if p.y < min_y + p.radius {
				if cur_vy < 0 {
					p.y = min_y + p.radius
					p.old_y = p.y + cur_vy * g.bounciness
				}
			}

			// Obstacles
			for obs in g.obstacles {
				match obs.obs_type {
					.platform, .trampoline {
						g.collide_point_rect(mut p, obs, mut r)
					}
					.spinner {
						g.collide_point_spinner(mut p, obs, mut r)
					}
					.fan {
						if p.x >= obs.x && p.x <= obs.x + obs.w && p.y >= obs.y && p.y <= obs.y + obs.h {
							p.old_y += 3.5 // Push upward smoothly
							if (rand.intn(10) or { 0 }) == 0 {
								g.particles << Particle{
									x: p.x, y: p.y
									vx: (rand.f64() * 2.0 - 1.0) * 20.0
									vy: -150.0
									life: 0.3, max_life: 0.3, size: 3.0
									color: Color{r: 200, g: 255, b: 240}
									particle_type: 'smoke'
								}
							}
						}
					}
					.gravity_well {
						dx := obs.x - p.x
						dy := obs.y - p.y
						dist := math.sqrt(dx * dx + dy * dy)
						if dist < obs.r * 2.2 && dist > 5.0 {
							force := (obs.r * 2.2 - dist) * 1.2
							p.old_x -= (dx / dist) * force * sub_dt
							p.old_y -= (dy / dist) * force * sub_dt
						}
					}
					.portal {
						dx := obs.x - p.x
						dy := obs.y - p.y
						dist := math.sqrt(dx * dx + dy * dy)
						if dist < obs.r {
							disp_x := p.x - p.old_x
							disp_y := p.y - p.old_y
							p.x = obs.portal_dest_x
							p.y = obs.portal_dest_y
							p.old_x = p.x - disp_x
							p.old_y = p.y - disp_y
							g.sound_event_zap = true
						}
					}
					.bumper {
						dx := p.x - obs.x
						dy := p.y - obs.y
						dist := math.sqrt(dx * dx + dy * dy)
						if dist < obs.r + p.radius && dist > 0.001 {
							nx := dx / dist
							ny := dy / dist
							p.x = obs.x + nx * (obs.r + p.radius)
							p.old_x = p.x - nx * 12.0
							p.old_y = p.y - ny * 12.0
							g.sound_event_bumper = true
							r.expression = 'shock'
							r.expression_timer = 1.0
						}
					}
				}
			}
		}
	}

	// Props boundary & obstacle collisions
	for mut pr in g.props {
		cur_vy := pr.y - pr.old_y
		cur_vx := pr.x - pr.old_x

		if pr.y > max_y - pr.radius {
			if cur_vy > 0 {
				pr.y = max_y - pr.radius
				pr.old_y = pr.y + cur_vy * g.bounciness
				pr.old_x = pr.x - cur_vx * 0.85
			}
		}
		if pr.x < min_x + pr.radius {
			if cur_vx < 0 {
				pr.x = min_x + pr.radius
				pr.old_x = pr.x + cur_vx * g.bounciness
			}
		}
		if pr.x > max_x - pr.radius {
			if cur_vx > 0 {
				pr.x = max_x - pr.radius
				pr.old_x = pr.x + cur_vx * g.bounciness
			}
		}

		for obs in g.obstacles {
			if obs.obs_type == .platform || obs.obs_type == .trampoline {
				if pr.x >= obs.x && pr.x <= obs.x + obs.w && pr.y + pr.radius >= obs.y && pr.y - pr.radius <= obs.y + obs.h {
					if cur_vy > 0 {
						pr.y = obs.y - pr.radius
						bounce := if obs.obs_type == .trampoline { obs.bounciness } else { g.bounciness }
						pr.old_y = pr.y + cur_vy * bounce
						pr.old_x = pr.x - cur_vx * 0.85
					}
				}
			}
		}
	}
}

fn (g &RagdollGame) collide_point_rect(mut p PointMass, obs Obstacle, mut r Ragdoll) {
	rx := p.x - (obs.x + obs.w * 0.5)
	ry := p.y - (obs.y + obs.h * 0.5)

	cos_a := math.cos(-obs.angle)
	sin_a := math.sin(-obs.angle)
	rot_x := rx * cos_a - ry * sin_a
	rot_y := rx * sin_a + ry * cos_a

	half_w := obs.w * 0.5
	half_h := obs.h * 0.5

	if rot_x >= -half_w - p.radius && rot_x <= half_w + p.radius && rot_y >= -half_h - p.radius && rot_y <= half_h + p.radius {
		cur_vy := p.y - p.old_y
		cur_vx := p.x - p.old_x

		if rot_y < 0 && cur_vy > 0 {
			rot_y_new := -half_h - p.radius
			p.x = (obs.x + obs.w * 0.5) + (rot_x * math.cos(obs.angle) - rot_y_new * math.sin(obs.angle))
			p.y = (obs.y + obs.h * 0.5) + (rot_x * math.sin(obs.angle) + rot_y_new * math.cos(obs.angle))

			bounce := if obs.obs_type == .trampoline { obs.bounciness } else { g.bounciness }
			if obs.obs_type == .trampoline {
				mut mutable_g := unsafe { &RagdollGame(g) }
				mutable_g.sound_event_boing = true
				r.expression = 'shock'
				r.expression_timer = 1.0
			}
			p.old_y = p.y + cur_vy * bounce
			p.old_x = p.x - cur_vx * 0.85
		}
	}
}

fn (g &RagdollGame) collide_point_spinner(mut p PointMass, obs Obstacle, mut r Ragdoll) {
	dx := p.x - obs.x
	dy := p.y - obs.y
	dist := math.sqrt(dx * dx + dy * dy)
	if dist < obs.r + p.radius && dist > 0.001 {
		nx := dx / dist
		ny := dy / dist

		p.x = obs.x + nx * (obs.r + p.radius)
		p.y = obs.y + ny * (obs.r + p.radius)

		tx := -ny * obs.angular_vel * 8.0
		ty := nx * obs.angular_vel * 8.0

		p.old_x = p.x - tx
		p.old_y = p.y - ty

		mut mutable_g := unsafe { &RagdollGame(g) }
		mutable_g.sound_event_thud = true
		mutable_g.thud_intensity = 0.8
		r.expression = 'shock'
		r.expression_timer = 1.2
	}
}

pub fn (mut g RagdollGame) trigger_shockwave(cx f64, cy f64, radius f64, force f64) {
	g.particles << Particle{
		x: cx, y: cy, vx: 0, vy: 0, life: 0.35, max_life: 0.35, size: 8.0, color: Color{r: 0, g: 240, b: 255}, particle_type: 'shockwave'
	}
	for _ in 0 .. 16 {
		ang := rand.f64() * math.pi * 2.0
		spd := rand.f64() * 180.0 + 80.0
		g.particles << Particle{
			x: cx, y: cy, vx: math.cos(ang) * spd, vy: math.sin(ang) * spd, life: 0.35, max_life: 0.35, size: 4.0, color: Color{r: 0, g: 255, b: 255}, particle_type: 'spark'
		}
	}

	for mut r in g.ragdolls {
		for mut p in r.points {
			dx := p.x - cx
			dy := p.y - cy
			dist := math.sqrt(dx * dx + dy * dy)
			if dist < radius && dist > 0.001 {
				factor := (radius - dist) / radius
				p.old_x -= (dx / dist) * force * factor * 0.008
				p.old_y -= (dy / dist) * force * factor * 0.008
				r.expression = 'shock'
				r.expression_timer = 1.5
			}
		}
	}

	for mut pr in g.props {
		dx := pr.x - cx
		dy := pr.y - cy
		dist := math.sqrt(dx * dx + dy * dy)
		if dist < radius && dist > 0.001 {
			factor := (radius - dist) / radius
			pr.old_x -= (dx / dist) * force * factor * 0.008
			pr.old_y -= (dy / dist) * force * factor * 0.008
		}
	}
}

pub fn (mut g RagdollGame) trigger_explosion(cx f64, cy f64) {
	g.sound_event_explosion = true
	g.trigger_shockwave(cx, cy, 220.0, 3200.0)

	for _ in 0 .. 25 {
		ang := rand.f64() * math.pi * 2.0
		spd := rand.f64() * 300.0 + 40.0
		g.particles << Particle{
			x: cx, y: cy, vx: math.cos(ang) * spd, vy: math.sin(ang) * spd, life: 0.5, max_life: 0.5, size: 6.0, color: Color{r: 255, g: 120, b: 20}, particle_type: 'spark'
		}
		g.particles << Particle{
			x: cx, y: cy, vx: math.cos(ang) * spd * 0.3, vy: math.sin(ang) * spd * 0.3, life: 0.7, max_life: 0.7, size: 10.0, color: Color{r: 100, g: 100, b: 100}, particle_type: 'smoke'
		}
	}
}

pub fn (mut g RagdollGame) slice_constraints_at(cx f64, cy f64, radius f64) {
	mut sliced := false
	for mut r in g.ragdolls {
		for mut c in r.constraints {
			if !c.active { continue }
			p1 := r.points[c.p1_idx]
			p2 := r.points[c.p2_idx]
			mid_x := (p1.x + p2.x) * 0.5
			mid_y := (p1.y + p2.y) * 0.5
			dx := mid_x - cx
			dy := mid_y - cy
			if math.sqrt(dx * dx + dy * dy) < radius {
				c.active = false
				sliced = true
				r.expression = 'dizzy'
				r.expression_timer = 2.0
			}
		}
	}
	if sliced {
		g.sound_event_crunch = true
	}
}

fn (g &RagdollGame) find_closest_ragdoll_point(mx f64, my f64, max_dist f64) (int, int) {
	mut min_d := max_dist
	mut best_r := -1
	mut best_p := -1
	for r_idx in 0 .. g.ragdolls.len {
		r := g.ragdolls[r_idx]
		for p_idx in 0 .. r.points.len {
			p := r.points[p_idx]
			dx := p.x - mx
			dy := p.y - my
			dist := math.sqrt(dx * dx + dy * dy)
			if dist < min_d {
				min_d = dist
				best_r = r_idx
				best_p = p_idx
			}
		}
	}
	return best_r, best_p
}

fn (g &RagdollGame) find_closest_prop(mx f64, my f64, max_dist f64) int {
	mut min_d := max_dist
	mut best_pr := -1
	for pr_idx in 0 .. g.props.len {
		pr := g.props[pr_idx]
		dx := pr.x - mx
		dy := pr.y - my
		dist := math.sqrt(dx * dx + dy * dy)
		if dist < min_d {
			min_d = dist
			best_pr = pr_idx
		}
	}
	return best_pr
}
