module main

fn test_flappy_initialization() {
	mut g := new_flappy_game()
	assert g.state == .ready
	assert g.score == 0
	assert g.bird.alive == true
	assert g.pipes.len > 0
}

fn test_flap_impulse() {
	mut g := new_flappy_game()
	g.state = .playing
	g.bird.vy = 100.0

	flapped := g.flap()
	assert flapped == true
	assert g.bird.vy < 0.0 // moving upward
	assert g.bird.angle < 0.0
}

fn test_pipe_passing_score() {
	mut g := new_flappy_game()
	g.state = .playing
	g.bird.x = 150.0

	// Set a pipe that is just about to be passed
	g.pipes.clear()
	g.bird.y = 215.0 // exactly in middle of gap (150..285)
	g.bird.vy = 0.0
	g.pipes << Pipe{
		x:      155.0
		top_h:  150.0
		passed: false
	}

	assert g.score == 0

	// Step forward until pipe.x + pipe_width < bird.x
	for _ in 0 .. 30 {
		g.bird.y = 215.0 // keep in gap
		g.bird.vy = 0.0
		g.update(0.02)
	}

	assert g.pipes[0].passed == true
	assert g.score == 1
}

fn test_medal_tiers() {
	mut g := new_flappy_game()
	g.score = 5
	assert g.get_medal() == .none

	g.score = 12
	assert g.get_medal() == .bronze

	g.score = 25
	assert g.get_medal() == .silver

	g.score = 35
	assert g.get_medal() == .gold

	g.score = 55
	assert g.get_medal() == .platinum
}
