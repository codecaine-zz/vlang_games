module main

import math

fn test_vec2_math() {
	v1 := Vec2{x: 3.0, y: 4.0}
	assert v1.length() == 5.0

	v2 := Vec2{x: 1.0, y: 2.0}
	added := v1.add(v2)
	assert added.x == 4.0
	assert added.y == 6.0

	subbed := v1.sub(v2)
	assert subbed.x == 2.0
	assert subbed.y == 2.0

	norm := v1.normalize()
	assert math.abs(norm.length() - 1.0) < 0.0001
}

fn test_closest_point_on_segment() {
	seg := LineSegment{
		p1: Vec2{x: 0.0, y: 0.0}
		p2: Vec2{x: 10.0, y: 0.0}
	}
	p := Vec2{x: 5.0, y: 5.0}
	closest := closest_point_on_segment(p, seg)
	assert closest.x == 5.0
	assert closest.y == 0.0
}

fn test_circle_bumper_collision() {
	mut ball := Ball{
		pos: Vec2{x: 100.0, y: 100.0}
		vel: Vec2{x: -100.0, y: 0.0}
		radius: 10.0
	}
	bumper_pos := Vec2{x: 130.0, y: 100.0}
	bumper_radius := 25.0

	collided := collide_circle_bumper(mut ball, bumper_pos, bumper_radius, 100.0)
	assert collided
	assert ball.vel.x < 0.0 // Repelled away from bumper
}

fn test_game_engine_init() {
	engine := new_game_engine()
	assert engine.state == .title
	assert engine.p1_balls == 3
	assert engine.multiplier == 1
	assert engine.card_targets.len == 5
	assert engine.bumpers.len == 3
}

fn test_start_game() {
	mut engine := new_game_engine()
	engine.start_game(.mode_1p)
	assert engine.state == .playing
	assert engine.current_player == 1
	assert engine.p1_score == 0
}

fn test_plunger_quick_tap_release() {
	mut engine := new_game_engine()
	engine.start_game(.mode_1p)
	assert engine.is_plunging

	// Tap plunger for 1 frame (tension < 5.0)
	engine.update(0.016, false, false, false, false, true)
	assert engine.plunger_tension < 5.0

	// Release plunger key
	engine.update(0.016, false, false, false, false, false)
	assert !engine.is_plunging // Must NOT be deadlocked!
	assert engine.ball.vel.y < -500.0 // Must launch ball!
}

fn test_zero_wall_tunneling() {
	mut engine := new_game_engine()
	engine.start_game(.mode_1p)
	engine.is_plunging = false

	// Fire ball towards left wall at high speed (1000 px/s) starting near wall
	engine.ball.pos = Vec2{x: 165.0, y: 300.0}
	engine.ball.vel = Vec2{x: -1000.0, y: 0.0}

	engine.update(0.016, false, false, false, false, false)

	// Ball must stay inside cabinet bounds (x >= 150 + radius) and bounce back
	assert engine.ball.pos.x >= (150.0 + engine.ball.radius)
	assert engine.ball.vel.x > 0.0 // Bounced off left boundary
}

fn test_stuck_ball_recovery() {
	mut engine := new_game_engine()
	engine.start_game(.mode_1p)
	engine.is_plunging = false

	// Place ball motionless in middle of field
	engine.ball.pos = Vec2{x: 350.0, y: 400.0}
	engine.ball.vel = Vec2{x: 0.0, y: 0.0}

	// Advance 95 frames (1.5 seconds)
	for _ in 0 .. 95 {
		engine.update(0.016, false, false, false, false, false)
	}

	// Auto-recovery should kick ball back into motion!
	assert engine.ball.vel.length() > 50.0
}

fn test_drop_targets_reset() {
	mut engine := new_game_engine()
	engine.start_game(.mode_1p)
	engine.is_plunging = false

	// Simulate hitting all 5 card targets
	for i in 0 .. engine.card_targets.len {
		engine.ball.pos = Vec2{
			x: engine.card_targets[i].pos.x + 12.0
			y: engine.card_targets[i].pos.y + 7.0
		}
		engine.update(0.016, false, false, false, false, false)
	}

	// Move ball away and tick one extra frame for all_dropped check
	engine.ball.pos = Vec2{x: 400.0, y: 400.0}
	engine.update(0.016, false, false, false, false, false)

	assert engine.p1_score >= 2500
	// All targets reset back to active
	for target in engine.card_targets {
		assert target.active
	}
}

fn test_rollovers_multiplier() {
	mut engine := new_game_engine()
	engine.start_game(.mode_1p)
	engine.is_plunging = false
	assert engine.multiplier == 1

	// Light up A, B, C
	for lane in engine.rollovers {
		engine.ball.pos = Vec2{
			x: lane.pos.x + 10.0
			y: lane.pos.y + 10.0
		}
		engine.update(0.016, false, false, false, false, false)
	}

	assert engine.multiplier == 2
}

fn test_ball_drain_and_game_over() {
	mut engine := new_game_engine()
	engine.start_game(.mode_1p)
	assert engine.p1_balls == 3

	// Drain ball 1
	engine.handle_ball_drain()
	assert engine.p1_balls == 2
	assert engine.state == .playing

	// Drain ball 2
	engine.handle_ball_drain()
	assert engine.p1_balls == 1
	assert engine.state == .playing

	// Drain ball 3
	engine.handle_ball_drain()
	assert engine.p1_balls == 0
	assert engine.state == .game_over
}
