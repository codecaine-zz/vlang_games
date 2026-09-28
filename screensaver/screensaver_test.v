module main

fn test_screensaver_template_catalog() {
	templates := get_all_templates()
	// Validate that over 100 templates are included
	assert templates.len >= 100
	println('Validated ${templates.len} screensaver templates')

	// Validate IDs and non-empty metadata
	for idx, t in templates {
		assert t.id == idx + 1
		assert t.name.len > 0
		assert t.description.len > 0
		assert t.year.len > 0
	}
}

fn test_screensaver_categories() {
	templates := get_all_templates()
	
	mut win_count := 0
	mut mac_count := 0
	mut hacker_count := 0
	mut synth_count := 0
	mut fractal_count := 0
	mut ambient_count := 0
	mut novelty_count := 0
	mut physics_count := 0

	for t in templates {
		match t.category {
			.windows_classics { win_count++ }
			.after_dark { mac_count++ }
			.hacker_xscreen { hacker_count++ }
			.demoscene_synth { synth_count++ }
			.fractals_physics { fractal_count++ }
			.ambient_scifi { ambient_count++ }
			.novelty_arcade { novelty_count++ }
			.modern_physics { physics_count++ }
		}
	}

	assert win_count >= 10
	assert mac_count >= 10
	assert hacker_count >= 10
	assert synth_count >= 10
	assert fractal_count >= 10
	assert ambient_count >= 10
	assert novelty_count >= 10
	assert physics_count >= 15
}

fn test_screensaver_app_state() {
	mut app := new_app()
	assert app.templates.len >= 100
	assert app.gui.selected_index == 0

	app.next_screensaver()
	assert app.gui.selected_index == 1

	app.prev_screensaver()
	assert app.gui.selected_index == 0
}
