module main

import math
import rand

enum GameMode {
	mode_1p
	mode_2p
}

enum GameState {
	title
	playing
	game_over
	paused
}

enum PlayfieldZone {
	upper
	lower
	mario_bonus
}

struct Bumper {
mut:
	pos       Vec2
	radius    f64 = 28.0
	hit_timer int
	score_val int = 100
}

struct DropTarget {
mut:
	pos       Vec2
	width     f64 = 24.0
	height    f64 = 14.0
	active    bool = true
	label     string
	score_val int = 500
}

struct RolloverLane {
mut:
	pos       Vec2
	width     f64 = 28.0
	height    f64 = 40.0
	active    bool
	label     string
}

struct Brick {
mut:
	x         f64
	y         f64
	width     f64 = 36.0
	height    f64 = 16.0
	active    bool = true
	color_idx int
	score_val int = 200
}

struct MarioStage {
mut:
	mario_x             f64 = 390.0
	mario_speed         f64 = 320.0
	shield_width        f64 = 85.0
	damsel_x            f64 = 390.0
	damsel_y            f64 = 1135.0
	damsel_dir          f64 = 1.0
	bricks              []Brick
	damsel_falling      bool
	rescued             bool
	damsel_rescue_timer int
}

struct ScorePopup {
mut:
	pos   Vec2
	text  string
	timer int
	color Color
}

struct GameEngine {
mut:
	mode                GameMode = .mode_1p
	state               GameState = .title
	zone                PlayfieldZone = .upper
	current_player      int = 1
	p1_score            int
	p2_score            int
	high_score          int = 10000
	p1_balls            int = 3
	p2_balls            int = 3
	multiplier          int = 1
	bonus_points        int
	ball                Ball
	camera_y            f64
	target_camera_y     f64
	plunger_tension     f64
	is_plunging         bool
	left_flipper_lower  Flipper
	right_flipper_lower Flipper
	left_flipper_upper  Flipper
	right_flipper_upper Flipper
	bumpers             []Bumper
	card_targets        []DropTarget
	rollovers           []RolloverLane
	slingshot_left      []LineSegment
	slingshot_right     []LineSegment
	table_walls         []LineSegment
	spinner_pos         Vec2
	spinner_angle       f64
	spinner_speed       f64
	spinner_hit_timer   int
	kickback_active     bool = true
	mario_stage         MarioStage
	popups              []ScorePopup
	tilt_count          int
	is_tilted           bool
	tilt_timer          int
	stuck_timer         int
	sound_queue         []string
}

fn new_game_engine() GameEngine {
	mut engine := GameEngine{
		left_flipper_lower:  new_flipper(Vec2{x: 310, y: 810}, 0.55, -0.50, true)
		right_flipper_lower: new_flipper(Vec2{x: 470, y: 810}, math.pi - 0.55, math.pi + 0.50, false)
		left_flipper_upper:  new_flipper(Vec2{x: 240, y: 380}, 0.45, -0.45, true)
		right_flipper_upper: new_flipper(Vec2{x: 540, y: 380}, math.pi - 0.45, math.pi + 0.45, false)
		spinner_pos:         Vec2{x: 580, y: 240}
	}
	engine.init_table_geometry()
	engine.reset_ball_to_plunger()
	return engine
}

fn (ge &GameEngine) init_table_geometry() {
	mut mutable_ge := unsafe { &GameEngine(ge) }

	// 1. Table Outer Walls
	// Top Arch
	mutable_ge.table_walls << LineSegment{p1: Vec2{x: 150, y: 220}, p2: Vec2{x: 220, y: 120}}
	mutable_ge.table_walls << LineSegment{p1: Vec2{x: 220, y: 120}, p2: Vec2{x: 390, y: 80}}
	mutable_ge.table_walls << LineSegment{p1: Vec2{x: 390, y: 80}, p2: Vec2{x: 560, y: 120}}
	mutable_ge.table_walls << LineSegment{p1: Vec2{x: 560, y: 120}, p2: Vec2{x: 650, y: 220}}

	// Main Side Boundaries
	mutable_ge.table_walls << LineSegment{p1: Vec2{x: 150, y: 220}, p2: Vec2{x: 150, y: 740}}
	mutable_ge.table_walls << LineSegment{p1: Vec2{x: 650, y: 220}, p2: Vec2{x: 650, y: 880}} // Plunger wall
	mutable_ge.table_walls << LineSegment{p1: Vec2{x: 620, y: 220}, p2: Vec2{x: 620, y: 880}} // Plunger inner wall

	// Bottom Slanted Guides to Lower Flippers
	mutable_ge.table_walls << LineSegment{p1: Vec2{x: 150, y: 740}, p2: Vec2{x: 310, y: 810}}
	mutable_ge.table_walls << LineSegment{p1: Vec2{x: 620, y: 740}, p2: Vec2{x: 470, y: 810}}

	// Outlane Guides
	mutable_ge.table_walls << LineSegment{p1: Vec2{x: 200, y: 680}, p2: Vec2{x: 200, y: 760}}
	mutable_ge.table_walls << LineSegment{p1: Vec2{x: 570, y: 680}, p2: Vec2{x: 570, y: 760}}

	// 2. Slingshots
	mutable_ge.slingshot_left << LineSegment{p1: Vec2{x: 240, y: 710}, p2: Vec2{x: 280, y: 775}}
	mutable_ge.slingshot_left << LineSegment{p1: Vec2{x: 280, y: 775}, p2: Vec2{x: 240, y: 775}}
	mutable_ge.slingshot_left << LineSegment{p1: Vec2{x: 240, y: 775}, p2: Vec2{x: 240, y: 710}}

	mutable_ge.slingshot_right << LineSegment{p1: Vec2{x: 540, y: 710}, p2: Vec2{x: 500, y: 775}}
	mutable_ge.slingshot_right << LineSegment{p1: Vec2{x: 500, y: 775}, p2: Vec2{x: 540, y: 775}}
	mutable_ge.slingshot_right << LineSegment{p1: Vec2{x: 540, y: 775}, p2: Vec2{x: 540, y: 710}}

	// 3. Bumpers
	mutable_ge.bumpers << Bumper{pos: Vec2{x: 310, y: 240}, radius: 28.0, score_val: 100}
	mutable_ge.bumpers << Bumper{pos: Vec2{x: 470, y: 240}, radius: 28.0, score_val: 100}
	mutable_ge.bumpers << Bumper{pos: Vec2{x: 390, y: 310}, radius: 28.0, score_val: 200}

	// 4. Drop Targets (Playing Cards 10, J, Q, K, A)
	cards := ['10', 'J', 'Q', 'K', 'A']
	for i, card in cards {
		mutable_ge.card_targets << DropTarget{
			pos:       Vec2{x: 180.0 + f64(i) * 36.0, y: 560.0}
			width:     26.0
			height:    16.0
			active:    true
			label:     card
			score_val: 500
		}
	}

	// 5. Rollover Lanes A, B, C
	lanes := ['A', 'B', 'C']
	for i, lane in lanes {
		mutable_ge.rollovers << RolloverLane{
			pos:    Vec2{x: 330.0 + f64(i) * 45.0, y: 100.0}
			width:  32.0
			height: 45.0
			active: false
			label:  lane
		}
	}

	// 6. Mario Bonus Sub-Stage Bricks
	colors := [0, 1, 2] // Red, Yellow, Blue
	for r in 0 .. 3 {
		for c in 0 .. 8 {
			mutable_ge.mario_stage.bricks << Brick{
				x:         200.0 + f64(c) * 48.0
				y:         1180.0 + f64(r) * 22.0
				width:     44.0
				height:    18.0
				active:    true
				color_idx: colors[r]
				score_val: 200 + r * 100
			}
		}
	}
}

fn (ge &GameEngine) reset_ball_to_plunger() {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	mutable_ge.ball = Ball{
		pos:    Vec2{x: 635.0, y: 840.0}
		vel:    Vec2{x: 0.0, y: 0.0}
		radius: 10.0
		active: true
	}
	mutable_ge.is_plunging = true
	mutable_ge.plunger_tension = 0.0
	mutable_ge.target_camera_y = 0.0
	mutable_ge.zone = .upper
	mutable_ge.stuck_timer = 0
}

fn (ge &GameEngine) start_game(mode GameMode) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	mutable_ge.mode = mode
	mutable_ge.state = .playing
	mutable_ge.current_player = 1
	mutable_ge.p1_score = 0
	mutable_ge.p2_score = 0
	mutable_ge.p1_balls = 3
	mutable_ge.p2_balls = 3
	mutable_ge.multiplier = 1
	mutable_ge.bonus_points = 0
	mutable_ge.tilt_count = 0
	mutable_ge.is_tilted = false
	mutable_ge.reset_ball_to_plunger()
}

fn (ge &GameEngine) add_score(pts int) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	total := pts * mutable_ge.multiplier
	if mutable_ge.current_player == 1 {
		mutable_ge.p1_score += total
		if mutable_ge.p1_score > mutable_ge.high_score {
			mutable_ge.high_score = mutable_ge.p1_score
		}
	} else {
		mutable_ge.p2_score += total
		if mutable_ge.p2_score > mutable_ge.high_score {
			mutable_ge.high_score = mutable_ge.p2_score
		}
	}
	mutable_ge.bonus_points += total / 5
}

fn (ge &GameEngine) add_popup(pos Vec2, text string, color Color) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	mutable_ge.popups << ScorePopup{
		pos:   pos
		text:  text
		timer: 45
		color: color
	}
}

fn (ge &GameEngine) nudge_table() {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	if mutable_ge.is_tilted || mutable_ge.state != .playing {
		return
	}
	mutable_ge.tilt_count++
	mutable_ge.ball.vel.x += (rand.f64() * 2.0 - 1.0) * 180.0
	mutable_ge.ball.vel.y -= 150.0
	mutable_ge.sound_queue << 'tilt'

	if mutable_ge.tilt_count >= 4 {
		mutable_ge.is_tilted = true
		mutable_ge.add_popup(Vec2{x: 350, y: 400}, 'TILT!', Color{255, 50, 50, 255})
	}
}

fn (ge &GameEngine) update(dt f64, p1_left bool, p1_right bool, mario_left bool, mario_right bool, plunge_hold bool) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	if mutable_ge.state != .playing {
		return
	}

	// Update Popups
	for i := mutable_ge.popups.len - 1; i >= 0; i-- {
		mutable_ge.popups[i].timer--
		mutable_ge.popups[i].pos.y -= 0.6
		if mutable_ge.popups[i].timer <= 0 {
			mutable_ge.popups.delete(i)
		}
	}

	// Update Bumpers hit timers
	for i in 0 .. mutable_ge.bumpers.len {
		if mutable_ge.bumpers[i].hit_timer > 0 {
			mutable_ge.bumpers[i].hit_timer--
		}
	}

	// Update Flippers if not tilted
	if !mutable_ge.is_tilted {
		mutable_ge.left_flipper_lower.update(dt, p1_left)
		mutable_ge.right_flipper_lower.update(dt, p1_right)
		mutable_ge.left_flipper_upper.update(dt, p1_left)
		mutable_ge.right_flipper_upper.update(dt, p1_right)
	}

	// Plunger Spring logic - Fix deadlock bug on quick tap/release
	if mutable_ge.is_plunging {
		if plunge_hold {
			mutable_ge.plunger_tension = math.min(100.0, mutable_ge.plunger_tension + 140.0 * dt)
		} else {
			// Released plunger key - launch ball with current or default minimum power
			launch_power := math.max(620.0, 620.0 + (mutable_ge.plunger_tension * 7.5))
			mutable_ge.ball.vel = Vec2{
				x: (rand.f64() * 2.0 - 1.0) * 30.0
				y: -launch_power
			}
			mutable_ge.is_plunging = false
			mutable_ge.plunger_tension = 0.0
			mutable_ge.sound_queue << 'plunger_release'
		}
		return
	}

	// Auto re-engage plunger if ball rolls back down into plunger chute (x >= 620, y >= 780)
	if mutable_ge.ball.pos.x >= 620.0 && mutable_ge.ball.pos.y >= 780.0 && mutable_ge.ball.vel.y >= 0.0 {
		mutable_ge.reset_ball_to_plunger()
		return
	}

	// Anti-Stuck Safeguard: Check if ball is trapped or motionless
	if mutable_ge.ball.vel.length() < 25.0 && mutable_ge.zone != .mario_bonus {
		mutable_ge.stuck_timer++
		if mutable_ge.stuck_timer > 90 { // 1.5 seconds motionless
			mutable_ge.ball.vel = Vec2{
				x: (rand.f64() * 2.0 - 1.0) * 200.0
				y: -300.0
			}
			mutable_ge.add_popup(mutable_ge.ball.pos, 'UNSTUCK!', Color{255, 255, 100, 255})
			mutable_ge.sound_queue << 'bumper'
			mutable_ge.stuck_timer = 0
		}
	} else {
		mutable_ge.stuck_timer = 0
	}

	// SUB-STEPPING PHYSICS ENGINE (8 sub-steps per frame for 100% collision accuracy & zero wall tunneling)
	sub_steps := 8
	sub_dt := dt / f64(sub_steps)

	for step in 0 .. sub_steps {
		// Ball Movement & Gravity per sub-step
		gravity := 480.0
		mutable_ge.ball.vel.y += gravity * sub_dt
		mutable_ge.ball.vel.x *= 0.9995
		mutable_ge.ball.vel.y *= 0.9995

		// Cap maximum ball speed to prevent tunneling
		max_speed := 1100.0
		speed := mutable_ge.ball.vel.length()
		if speed > max_speed {
			mutable_ge.ball.vel = mutable_ge.ball.vel.normalize().mul(max_speed)
		}

		mutable_ge.ball.pos.x += mutable_ge.ball.vel.x * sub_dt
		mutable_ge.ball.pos.y += mutable_ge.ball.vel.y * sub_dt

		// HARD CABINET BOUNDARY CLAMPING & REFLECTIONS
		// Left Cabinet Boundary
		if mutable_ge.ball.pos.x < 150.0 + mutable_ge.ball.radius {
			mutable_ge.ball.pos.x = 150.0 + mutable_ge.ball.radius
			if mutable_ge.ball.vel.x < 0.0 {
				mutable_ge.ball.vel.x = -mutable_ge.ball.vel.x * 0.8
			}
		}

		// Right Outer Cabinet Boundary (Plunger Lane outer wall)
		if mutable_ge.ball.pos.x > 650.0 - mutable_ge.ball.radius {
			mutable_ge.ball.pos.x = 650.0 - mutable_ge.ball.radius
			if mutable_ge.ball.vel.x > 0.0 {
				mutable_ge.ball.vel.x = -mutable_ge.ball.vel.x * 0.8
			}
		}

		// Main Table / Plunger Lane Divider Wall (x = 620)
		if mutable_ge.ball.pos.x > (620.0 - mutable_ge.ball.radius) && mutable_ge.ball.pos.x < 620.0
			&& mutable_ge.ball.pos.y > 220.0 && mutable_ge.ball.pos.y < 800.0 {
			mutable_ge.ball.pos.x = 620.0 - mutable_ge.ball.radius
			if mutable_ge.ball.vel.x > 0.0 {
				mutable_ge.ball.vel.x = -mutable_ge.ball.vel.x * 0.8
			}
		}

		// Top Ceiling Arch Boundary
		if mutable_ge.ball.pos.y < 80.0 + mutable_ge.ball.radius {
			mutable_ge.ball.pos.y = 80.0 + mutable_ge.ball.radius
			if mutable_ge.ball.vel.y < 0.0 {
				mutable_ge.ball.vel.y = -mutable_ge.ball.vel.y * 0.8
			}
		}

		// 1. Table Line Walls Collision
		for seg in mutable_ge.table_walls {
			if collide_circle_segment(mut mutable_ge.ball, seg, 0.75) {
				if step == 0 {
					mutable_ge.sound_queue << 'flick'
				}
			}
		}

		// 2. Flipper Collisions (if not tilted)
		if !mutable_ge.is_tilted {
			if collide_circle_flipper(mut mutable_ge.ball, mutable_ge.left_flipper_lower)
				|| collide_circle_flipper(mut mutable_ge.ball, mutable_ge.right_flipper_lower)
				|| collide_circle_flipper(mut mutable_ge.ball, mutable_ge.left_flipper_upper)
				|| collide_circle_flipper(mut mutable_ge.ball, mutable_ge.right_flipper_upper) {
				if step == 0 {
					mutable_ge.sound_queue << 'flick'
				}
			}
		}

		// 3. Slingshots
		for seg in mutable_ge.slingshot_left {
			if collide_circle_segment(mut mutable_ge.ball, seg, 1.35) {
				mutable_ge.add_score(150)
				if step == 0 {
					mutable_ge.sound_queue << 'slingshot'
				}
			}
		}
		for seg in mutable_ge.slingshot_right {
			if collide_circle_segment(mut mutable_ge.ball, seg, 1.35) {
				mutable_ge.add_score(150)
				if step == 0 {
					mutable_ge.sound_queue << 'slingshot'
				}
			}
		}

		// 4. Bumpers
		for i in 0 .. mutable_ge.bumpers.len {
			if collide_circle_bumper(mut mutable_ge.ball, mutable_ge.bumpers[i].pos,
				mutable_ge.bumpers[i].radius, 150.0) {
				mutable_ge.bumpers[i].hit_timer = 12
				mutable_ge.add_score(mutable_ge.bumpers[i].score_val)
				mutable_ge.add_popup(mutable_ge.bumpers[i].pos, '+${mutable_ge.bumpers[i].score_val * mutable_ge.multiplier}',
					Color{255, 230, 80, 255})
				if step == 0 {
					mutable_ge.sound_queue << 'bumper'
				}
			}
		}
	}

	// Update Camera Viewport position
	if mutable_ge.ball.pos.y > 1050.0 {
		mutable_ge.zone = .mario_bonus
		mutable_ge.target_camera_y = 1000.0
	} else if mutable_ge.ball.pos.y > 450.0 {
		mutable_ge.zone = .lower
		mutable_ge.target_camera_y = 400.0
	} else {
		mutable_ge.zone = .upper
		mutable_ge.target_camera_y = 0.0
	}
	mutable_ge.camera_y += (mutable_ge.target_camera_y - mutable_ge.camera_y) * 0.1

	// Update Spinner
	if mutable_ge.spinner_hit_timer > 0 {
		mutable_ge.spinner_hit_timer--
		mutable_ge.spinner_angle += mutable_ge.spinner_speed * dt
		mutable_ge.spinner_speed *= 0.95
	}

	// 5. Drop Targets
	mut all_dropped := true
	for i in 0 .. mutable_ge.card_targets.len {
		if mutable_ge.card_targets[i].active {
			all_dropped = false
			c_rect_center := Vec2{
				x: mutable_ge.card_targets[i].pos.x + mutable_ge.card_targets[i].width / 2.0
				y: mutable_ge.card_targets[i].pos.y + mutable_ge.card_targets[i].height / 2.0
			}
			if mutable_ge.ball.pos.distance(c_rect_center) < (mutable_ge.ball.radius + 14.0) {
				mutable_ge.card_targets[i].active = false
				mutable_ge.add_score(mutable_ge.card_targets[i].score_val)
				mutable_ge.add_popup(mutable_ge.card_targets[i].pos, '+${mutable_ge.card_targets[i].score_val}',
					Color{100, 255, 100, 255})
				mutable_ge.sound_queue << 'target'
			}
		}
	}
	if all_dropped {
		mutable_ge.add_score(3000)
		mutable_ge.add_popup(Vec2{x: 320, y: 550}, 'CARD BONUS +3000!', Color{255, 120, 255, 255})
		for i in 0 .. mutable_ge.card_targets.len {
			mutable_ge.card_targets[i].active = true
		}
	}

	// 6. Rollover Lanes
	for i in 0 .. mutable_ge.rollovers.len {
		r_pos := mutable_ge.rollovers[i].pos
		if mutable_ge.ball.pos.x >= r_pos.x && mutable_ge.ball.pos.x <= r_pos.x + mutable_ge.rollovers[i].width
			&& mutable_ge.ball.pos.y >= r_pos.y
			&& mutable_ge.ball.pos.y <= r_pos.y + mutable_ge.rollovers[i].height {
			if !mutable_ge.rollovers[i].active {
				mutable_ge.rollovers[i].active = true
				mutable_ge.add_score(500)
				mutable_ge.sound_queue << 'target'
			}
		}
	}
	if mutable_ge.rollovers[0].active && mutable_ge.rollovers[1].active
		&& mutable_ge.rollovers[2].active {
		if mutable_ge.multiplier < 5 {
			mutable_ge.multiplier++
			mutable_ge.add_popup(Vec2{x: 350, y: 120}, '${mutable_ge.multiplier}X MULTIPLIER!',
				Color{255, 255, 0, 255})
		}
		for i in 0 .. mutable_ge.rollovers.len {
			mutable_ge.rollovers[i].active = false
		}
	}

	// 7. Spinner Lane
	if mutable_ge.ball.pos.distance(mutable_ge.spinner_pos) < 25.0 {
		mutable_ge.spinner_hit_timer = 20
		mutable_ge.spinner_speed = 35.0
		mutable_ge.add_score(50)
		mutable_ge.sound_queue << 'spinner'
	}

	// 8. Mario Sub-Stage Hole Target (Hole at x: 390, y: 160)
	hole_pos := Vec2{x: 390, y: 160}
	if mutable_ge.ball.pos.distance(hole_pos) < 18.0 {
		mutable_ge.ball.pos = Vec2{x: 390, y: 1280}
		mutable_ge.ball.vel = Vec2{x: (rand.f64() * 2.0 - 1.0) * 80.0, y: -200.0}
		mutable_ge.zone = .mario_bonus
		mutable_ge.add_popup(Vec2{x: 320, y: 1200}, 'MARIO STAGE!', Color{255, 100, 100, 255})
		mutable_ge.sound_queue << 'mario_bounce'
	}

	// 9. Mario Bonus Stage Logic
	if mutable_ge.zone == .mario_bonus {
		// Mario controls
		if mario_left {
			mutable_ge.mario_stage.mario_x = math.max(190.0, mutable_ge.mario_stage.mario_x - mutable_ge.mario_stage.mario_speed * dt)
		}
		if mario_right {
			mutable_ge.mario_stage.mario_x = math.min(570.0, mutable_ge.mario_stage.mario_x + mutable_ge.mario_stage.mario_speed * dt)
		}

		// Damsel walking
		mutable_ge.mario_stage.damsel_x += mutable_ge.mario_stage.damsel_dir * 40.0 * dt
		if mutable_ge.mario_stage.damsel_x < 220.0 || mutable_ge.mario_stage.damsel_x > 540.0 {
			mutable_ge.mario_stage.damsel_dir *= -1.0
		}

		// Bounce off Mario's Shield Paddle (y = 1430)
		m_x := mutable_ge.mario_stage.mario_x
		m_w := mutable_ge.mario_stage.shield_width
		if mutable_ge.ball.pos.y >= 1420.0 && mutable_ge.ball.pos.y <= 1445.0
			&& mutable_ge.ball.pos.x >= (m_x - m_w / 2.0)
			&& mutable_ge.ball.pos.x <= (m_x + m_w / 2.0) {
			hit_offset := (mutable_ge.ball.pos.x - m_x) / (m_w / 2.0)
			mutable_ge.ball.vel = Vec2{x: hit_offset * 240.0, y: -480.0}
			mutable_ge.sound_queue << 'mario_bounce'
		}

		// Breakable Bricks Collisions
		mut active_bricks := 0
		for i in 0 .. mutable_ge.mario_stage.bricks.len {
			if mutable_ge.mario_stage.bricks[i].active {
				active_bricks++
				brk := mutable_ge.mario_stage.bricks[i]
				b_rect_center := Vec2{x: brk.x + brk.width / 2.0, y: brk.y + brk.height / 2.0}
				if mutable_ge.ball.pos.distance(b_rect_center) < 22.0 {
					mutable_ge.mario_stage.bricks[i].active = false
					mutable_ge.ball.vel.y *= -1.0
					mutable_ge.add_score(brk.score_val)
					mutable_ge.add_popup(Vec2{x: brk.x, y: brk.y}, '+${brk.score_val}', Color{
						r: 255
						g: 220
						b: 100
						a: 255
					})
					mutable_ge.sound_queue << 'target'
				}
			}
		}

		// Damsel Rescue Trigger when all bricks cleared
		if active_bricks == 0 && !mutable_ge.mario_stage.damsel_falling
			&& !mutable_ge.mario_stage.rescued {
			mutable_ge.mario_stage.damsel_falling = true
		}

		if mutable_ge.mario_stage.damsel_falling {
			mutable_ge.mario_stage.damsel_y += 180.0 * dt
			// Damsel caught on Mario's paddle
			if mutable_ge.mario_stage.damsel_y >= 1420.0 {
				if math.abs(mutable_ge.mario_stage.damsel_x - mutable_ge.mario_stage.mario_x) < 55.0 {
					mutable_ge.mario_stage.rescued = true
					mutable_ge.mario_stage.damsel_falling = false
					mutable_ge.add_score(10000)
					mutable_ge.add_popup(Vec2{x: 320, y: 1250}, 'DAMSEL RESCUED! +10000',
						Color{255, 50, 255, 255})
					mutable_ge.sound_queue << 'damsel_rescue'
				} else {
					// Missed damsel - reset bricks
					mutable_ge.mario_stage.damsel_falling = false
					mutable_ge.mario_stage.damsel_y = 1135.0
					for i in 0 .. mutable_ge.mario_stage.bricks.len {
						mutable_ge.mario_stage.bricks[i].active = true
					}
				}
			}
		}

		// Mario stage bottom pit exit
		if mutable_ge.ball.pos.y > 1490.0 {
			// Ball returns to lower playfield
			mutable_ge.ball.pos = Vec2{x: 390.0, y: 700.0}
			mutable_ge.ball.vel = Vec2{x: 0.0, y: 150.0}
			mutable_ge.zone = .lower
		}
	}

	// 10. Center Main Playfield Drain Pit (y > 880 on lower table)
	if mutable_ge.ball.pos.y > 880.0 && mutable_ge.zone != .mario_bonus {
		if mutable_ge.kickback_active && mutable_ge.ball.pos.x >= 360.0
			&& mutable_ge.ball.pos.x <= 420.0 {
			// Kickback saves ball!
			mutable_ge.ball.vel = Vec2{x: 0.0, y: -650.0}
			mutable_ge.kickback_active = false
			mutable_ge.add_popup(Vec2{x: 340, y: 830}, 'KICKBACK SAVE!', Color{100, 255, 100, 255})
			mutable_ge.sound_queue << 'slingshot'
		} else {
			// Ball Drain!
			mutable_ge.sound_queue << 'drain'
			mutable_ge.handle_ball_drain()
		}
	}
}

fn (ge &GameEngine) handle_ball_drain() {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	if mutable_ge.current_player == 1 {
		mutable_ge.p1_balls--
		if mutable_ge.mode == .mode_2p && mutable_ge.p2_balls > 0 {
			mutable_ge.current_player = 2
		}
	} else {
		mutable_ge.p2_balls--
		if mutable_ge.p1_balls > 0 {
			mutable_ge.current_player = 1
		}
	}

	if mutable_ge.p1_balls <= 0 && (mutable_ge.mode == .mode_1p || mutable_ge.p2_balls <= 0) {
		mutable_ge.state = .game_over
	} else {
		mutable_ge.reset_ball_to_plunger()
	}
}
