module main

fn test_rain_game_init() {
	mut game := new_rain_game()
	assert game.max_drops == 5000
	assert game.themes.len == 5
	assert game.drops.len == 5000
	assert game.mode == .atmospheric
}

fn test_particle_resizing() {
	mut game := new_rain_game()
	game.set_particle_count(15000)
	assert game.max_drops == 15000
	assert game.drops.len == 15000

	game.set_particle_count(2000)
	assert game.max_drops == 2000
	assert game.drops.len == 2000
}

fn test_ram_allocation() {
	mut game := new_rain_game()
	game.allocate_ram_benchmark(512)
	assert game.ram_allocated_mb == 512
	assert game.ram_buffers.len == 32 // 512 / 16 = 32 chunks

	game.allocate_ram_benchmark(64)
	assert game.ram_allocated_mb == 64
	assert game.ram_buffers.len == 4
}

fn test_game_update_and_splashes() {
	mut game := new_rain_game()
	game.spawn_splash(100.0, 100.0, 5)
	
	mut active_splashes := 0
	for s in game.splashes {
		if s.active { active_splashes++ }
	}
	assert active_splashes == 5

	game.update(0.016)
	assert game.fps > 0.0
}

fn test_intensity_presets() {
	mut game := new_rain_game()
	game.set_intensity_preset(1) // Drizzle
	assert game.rain_intensity == 0.4

	game.set_intensity_preset(5) // M4 Armageddon
	assert game.rain_intensity == 3.2
	assert game.max_drops == 500000
	assert game.ram_allocated_mb == 8192
}
