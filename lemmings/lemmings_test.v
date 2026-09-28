module main

fn test_lemmings_initialization() {
	mut g := new_lemmings_game()
	assert g.levels.len >= 2
	assert g.level_idx == 0
	assert g.terrain.len == map_w
	assert g.spawned_count == 0
	assert g.saved_count == 0
}

fn test_lemmings_spawning_and_skills() {
	mut g := new_lemmings_game()
	// Advance time to spawn lemmings
	for _ in 0 .. 50 {
		g.update(0.1)
	}
	assert g.lemmings.len > 0
	assert g.spawned_count > 0

	// Test Skill assignment
	g.selected_skill = .digger
	init_diggers := g.levels[0].skills[Skill.digger.str()]
	assert g.assign_skill(0)
	assert g.lemmings[0].state == .digging
	assert g.levels[0].skills[Skill.digger.str()] == init_diggers - 1
}

fn test_lemmings_nuke_and_explosion() {
	mut g := new_lemmings_game()
	g.update(2.0)
	assert g.lemmings.len > 0

	g.trigger_nuke()
	assert g.is_nuking
	assert g.lemmings[0].countdown > 0.0

	// Advance past countdown
	for _ in 0 .. 60 {
		g.update(0.1)
	}
	assert g.dead_count > 0
}
