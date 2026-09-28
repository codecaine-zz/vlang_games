module main

import math
import rand

pub enum GameMode {
	atmospheric
	defense
	benchmark
}

pub struct Drop {
pub mut:
	x         f64
	y         f64
	vx        f64
	vy        f64
	length    f64
	thickness f64
	alpha     u8
	drop_type int // 0 = standard, 1 = drizzle, 2 = heavy torrent, 3 = lightning fragment
	active    bool = true
}

pub struct Splash {
pub mut:
	x        f64
	y        f64
	vx       f64
	vy       f64
	life     f64
	max_life f64
	active   bool = true
}

pub struct Ripple {
pub mut:
	x          f64
	y          f64
	radius     f64
	max_radius f64
	alpha      u8
	active     bool = true
}

pub struct WeatherTheme {
pub:
	name            string
	bg_color        Color
	drop_color      Color
	splash_color    Color
	lightning_color Color
	puddle_color    Color
}

pub struct Umbrella {
pub mut:
	x          f64
	y          f64
	width      f64 = 140.0
	height     f64 = 40.0
	angle      f64 = 0.0 // in radians
	elasticity f64 = 0.85
	deflections int
}

pub struct TargetZone {
pub mut:
	x       f64
	y       f64
	w       f64
	h       f64
	wetness f64 = 0.0 // 0.0 to 100.0%
	label   string
}

pub struct FluidCell {
pub mut:
	height  f64
	v_height f64
}

pub struct RainGame {
pub mut:
	mode                GameMode = .atmospheric
	screen_w            int = 960
	screen_h            int = 640
	drops               []Drop
	splashes            []Splash
	ripples             []Ripple
	max_drops           int = 5000
	max_splashes        int = 1000
	max_ripples         int = 500
	wind_force          f64 = 1.5
	wind_angle          f64 = 0.2 // angle off vertical in radians
	rain_intensity      f64 = 1.0 // 0.2 drizzle to 3.0 typhoon
	gravity             f64 = 980.0
	ground_y            f64 = 520.0
	lightning_flash     f64
	lightning_x         f64
	theme_idx           int
	themes              []WeatherTheme
	umbrella            Umbrella
	target_zone         TargetZone
	score               int
	energy              f64 = 100.0
	
	// Fluid heightfield grid for ground puddles
	grid_cols           int = 96
	grid_rows           int = 1
	puddle_heights      []f64
	
	// Hardware & RAM Benchmark Stress Tester
	ram_allocated_mb    int = 128 // Allocates real dynamic RAM buffers (up to 32,768 MB)
	ram_buffers         [][]u8
	active_particle_cnt int = 5000
	fps                 f64 = 60.0
	frame_time_ms       f64 = 16.6
	total_processed     u64
	benchmark_timer     f64
}

fn new_rain_game() RainGame {
	themes := [
		WeatherTheme{
			name: 'Midnight Tempest',
			bg_color: Color{r: 8, g: 12, b: 24},
			drop_color: Color{r: 160, g: 210, b: 255, a: 220},
			splash_color: Color{r: 200, g: 230, b: 255, a: 200},
			lightning_color: Color{r: 255, g: 255, b: 240},
			puddle_color: Color{r: 30, g: 60, b: 110, a: 150},
		},
		WeatherTheme{
			name: 'Cyberpunk Neon',
			bg_color: Color{r: 15, g: 5, b: 25},
			drop_color: Color{r: 0, g: 240, b: 255, a: 230},
			splash_color: Color{r: 255, g: 0, b: 180, a: 220},
			lightning_color: Color{r: 255, g: 240, b: 0},
			puddle_color: Color{r: 80, g: 0, b: 120, a: 180},
		},
		WeatherTheme{
			name: 'Acid Green Storm',
			bg_color: Color{r: 5, g: 18, b: 10},
			drop_color: Color{r: 100, g: 255, b: 120, a: 220},
			splash_color: Color{r: 180, g: 255, b: 160, a: 200},
			lightning_color: Color{r: 200, g: 255, b: 100},
			puddle_color: Color{r: 20, g: 80, b: 40, a: 160},
		},
		WeatherTheme{
			name: 'Golden Sunset Rain',
			bg_color: Color{r: 28, g: 14, b: 10},
			drop_color: Color{r: 255, g: 180, b: 100, a: 220},
			splash_color: Color{r: 255, g: 220, b: 150, a: 200},
			lightning_color: Color{r: 255, g: 255, b: 200},
			puddle_color: Color{r: 110, g: 50, b: 20, a: 150},
		},
		WeatherTheme{
			name: 'Blizzard Ice Storm',
			bg_color: Color{r: 18, g: 25, b: 35},
			drop_color: Color{r: 220, g: 240, b: 255, a: 240},
			splash_color: Color{r: 255, g: 255, b: 255, a: 230},
			lightning_color: Color{r: 180, g: 220, b: 255},
			puddle_color: Color{r: 60, g: 90, b: 140, a: 160},
		},
	]

	mut game := RainGame{
		themes: themes,
		umbrella: Umbrella{
			x: 480.0,
			y: 380.0,
		},
		target_zone: TargetZone{
			x: 430.0,
			y: 470.0,
			w: 100.0,
			h: 50.0,
			label: 'DRY SHELTER',
		},
		puddle_heights: []f64{len: 96, init: 0.0},
	}

	game.init_particle_pools()
	game.allocate_ram_benchmark(128)
	return game
}

fn (mut game RainGame) init_particle_pools() {
	game.drops = []Drop{len: game.max_drops}
	for i in 0 .. game.max_drops {
		game.respawn_drop(i)
	}

	game.splashes = []Splash{len: game.max_splashes}
	for i in 0 .. game.max_splashes {
		game.splashes[i].active = false
	}

	game.ripples = []Ripple{len: game.max_ripples}
	for i in 0 .. game.max_ripples {
		game.ripples[i].active = false
	}
}

fn (mut game RainGame) set_particle_count(count int) {
	new_cnt := if count < 1000 { 1000 } else if count > 1000000 { 1000000 } else { count }
	game.max_drops = new_cnt
	game.active_particle_cnt = new_cnt
	
	// Efficient pool resizing
	if game.drops.len < new_cnt {
		old_len := game.drops.len
		game.drops.grow_cap(new_cnt - game.drops.len)
		for i in old_len .. new_cnt {
			mut d := Drop{active: true}
			game.drops << d
			game.respawn_drop(i)
		}
	} else {
		game.drops.trim(new_cnt)
	}
}

fn (mut game RainGame) allocate_ram_benchmark(target_mb int) {
	clamped_mb := if target_mb < 64 { 64 } else if target_mb > 32768 { 32768 } else { target_mb }
	game.ram_allocated_mb = clamped_mb
	
	// Re-allocate byte chunks (each chunk = 16 MB to prevent huge single allocation overhead)
	num_chunks := clamped_mb / 16
	game.ram_buffers = [][]u8{len: num_chunks}
	chunk_bytes := 16 * 1024 * 1024
	
	for i in 0 .. num_chunks {
		mut buf := []u8{len: chunk_bytes}
		// Populate memory to force physical page allocation on macOS VM
		for j := 0; j < chunk_bytes; j += 4096 {
			buf[j] = u8((i + j) % 256)
		}
		game.ram_buffers[i] = buf
	}
}

fn (mut game RainGame) touch_ram_buffers() {
	// Continuously churn allocated RAM buffers during benchmark to stress Apple M4 memory bandwidth!
	if game.ram_buffers.len == 0 { return }
	for i in 0 .. game.ram_buffers.len {
		mut buf := unsafe { game.ram_buffers[i] }
		if buf.len > 1024 {
			div := u64(buf.len - 16)
			if div > 0 {
				idx := int((game.total_processed * 64) % div)
				if idx >= 0 && idx < buf.len {
					buf[idx] = u8((buf[idx] + 1) % 256)
				}
			}
		}
	}
}

fn (mut game RainGame) respawn_drop(idx int) {
	if idx < 0 || idx >= game.drops.len { return }
	mut d := unsafe { &game.drops[idx] }
	
	// Spawn above top edge or far left depending on wind
	w := f64(game.screen_w)
	spawn_margin := 200.0
	d.x = rand.f64() * (w + spawn_margin * 2.0) - spawn_margin
	d.y = -rand.f64() * f64(game.screen_h) - 20.0
	
	base_speed := 450.0 + rand.f64() * 350.0
	speed_mod := game.rain_intensity
	d.vy = base_speed * speed_mod
	d.vx = math.sin(game.wind_angle) * d.vy + game.wind_force * 40.0
	
	d.length = 10.0 + rand.f64() * 18.0 * game.rain_intensity
	d.thickness = 1.0 + rand.f64() * 1.5
	d.alpha = u8(160 + (rand.intn(95) or { 0 }))
	d.drop_type = if rand.f64() < 0.15 { 1 } else if game.rain_intensity > 2.0 { 2 } else { 0 }
	d.active = true
}

fn (mut game RainGame) spawn_splash(x f64, y f64, count int) {
	mut created := 0
	for i in 0 .. game.splashes.len {
		if !game.splashes[i].active {
			mut s := unsafe { &game.splashes[i] }
			s.x = x
			s.y = y
			ang := -math.pi * 0.15 - rand.f64() * math.pi * 0.7
			spd := 60.0 + rand.f64() * 140.0
			s.vx = math.cos(ang) * spd + game.wind_force * 15.0
			s.vy = math.sin(ang) * spd
			s.life = 0.0
			s.max_life = 0.15 + rand.f64() * 0.2
			s.active = true
			created++
			if created >= count { break }
		}
	}
}

fn (mut game RainGame) spawn_ripple(x f64, y f64) {
	for i in 0 .. game.ripples.len {
		if !game.ripples[i].active {
			mut r := unsafe { &game.ripples[i] }
			r.x = x
			r.y = y
			r.radius = 2.0
			r.max_radius = 12.0 + rand.f64() * 16.0
			r.alpha = 220
			r.active = true
			break
		}
	}
}

fn (mut game RainGame) trigger_lightning() {
	game.lightning_flash = 1.0
	game.lightning_x = 50.0 + rand.f64() * f64(game.screen_w - 100)
}

fn (mut game RainGame) update(dt f64) {
	game.total_processed += u64(game.drops.len)
	game.frame_time_ms = dt * 1000.0
	game.fps = if dt > 0.0001 { 1.0 / dt } else { 60.0 }
	game.benchmark_timer += dt

	// Lightning decay
	if game.lightning_flash > 0.0 {
		game.lightning_flash -= dt * 4.0
		if game.lightning_flash < 0.0 { game.lightning_flash = 0.0 }
	} else if rand.f64() < 0.003 * game.rain_intensity {
		game.trigger_lightning()
	}

	// Dynamic RAM benchmark churn
	game.touch_ram_buffers()

	// Update Umbrella collision bounds based on mouse position
	umb_x := game.umbrella.x
	umb_y := game.umbrella.y
	umb_w := game.umbrella.width
	umb_h := game.umbrella.height
	half_w := umb_w * 0.5

	// Ground puddle accumulation update
	mut col_step := f64(game.screen_w) / f64(game.puddle_heights.len)

	// Particle loop
	for i in 0 .. game.drops.len {
		mut d := unsafe { &game.drops[i] }
		if !d.active { continue }

		d.x += (d.vx + game.wind_force * 30.0) * dt
		d.y += (d.vy + game.gravity * 0.15) * dt

		// Umbrella collision check
		if d.y >= umb_y - 10.0 && d.y <= umb_y + umb_h && d.x >= umb_x - half_w && d.x <= umb_x + half_w {
			game.spawn_splash(d.x, umb_y, 2)
			game.umbrella.deflections++
			if game.mode == .defense {
				game.energy += 0.2
				if game.energy > 100.0 { game.energy = 100.0 }
			}
			game.respawn_drop(i)
			continue
		}

		// Target Zone wetness check (Defense Mode)
		if game.mode == .defense {
			if d.x >= game.target_zone.x && d.x <= game.target_zone.x + game.target_zone.w &&
			   d.y >= game.target_zone.y && d.y <= game.target_zone.y + game.target_zone.h {
				game.target_zone.wetness += 0.05
				if game.target_zone.wetness > 100.0 { game.target_zone.wetness = 100.0 }
				game.respawn_drop(i)
				continue
			}
		}

		// Ground impact check
		if d.y >= game.ground_y {
			col_idx := int(d.x / col_step)
			if col_idx >= 0 && col_idx < game.puddle_heights.len {
				game.puddle_heights[col_idx] += 0.02 * game.rain_intensity
				if game.puddle_heights[col_idx] > 18.0 { game.puddle_heights[col_idx] = 18.0 }
			}

			if rand.f64() < 0.3 {
				game.spawn_splash(d.x, game.ground_y, 1)
			}
			if rand.f64() < 0.15 {
				game.spawn_ripple(d.x, game.ground_y + rand.f64() * 30.0)
			}

			game.respawn_drop(i)
		}

		// Out of bounds check
		if d.x < -250.0 || d.x > f64(game.screen_w) + 250.0 || d.y > f64(game.screen_h) + 50.0 {
			game.respawn_drop(i)
		}
	}

	// Update Splashes
	for i in 0 .. game.splashes.len {
		mut s := unsafe { &game.splashes[i] }
		if !s.active { continue }

		s.x += s.vx * dt
		s.y += s.vy * dt
		s.vy += 300.0 * dt // splash gravity
		s.life += dt

		if s.life >= s.max_life || s.y >= game.ground_y + 10.0 {
			s.active = false
		}
	}

	// Update Ripples
	for i in 0 .. game.ripples.len {
		mut r := unsafe { &game.ripples[i] }
		if !r.active { continue }

		r.radius += 25.0 * dt
		fade_ratio := 1.0 - (r.radius / r.max_radius)
		r.alpha = u8(220.0 * fade_ratio)

		if r.radius >= r.max_radius {
			r.active = false
		}
	}

	// Evaporate puddles gradually
	for col := 0; col < game.puddle_heights.len; col++ {
		if game.puddle_heights[col] > 0.0 {
			game.puddle_heights[col] -= 0.15 * dt
			if game.puddle_heights[col] < 0.0 { game.puddle_heights[col] = 0.0 }
		}
	}

	// Defense mode target zone drying
	if game.mode == .defense {
		if game.target_zone.wetness > 0.0 {
			game.target_zone.wetness -= 1.0 * dt
			if game.target_zone.wetness < 0.0 { game.target_zone.wetness = 0.0 }
		}
		game.score += int(dt * 10.0)
	}
}

fn (mut game RainGame) cycle_theme() {
	game.theme_idx = (game.theme_idx + 1) % game.themes.len
}

fn (mut game RainGame) set_intensity_preset(preset int) {
	match preset {
		1 { // Drizzle
			game.rain_intensity = 0.4
			game.wind_force = 0.5
			game.set_particle_count(3000)
		}
		2 { // Heavy Rain
			game.rain_intensity = 1.0
			game.wind_force = 1.5
			game.set_particle_count(8000)
		}
		3 { // Monsoon
			game.rain_intensity = 1.8
			game.wind_force = 3.0
			game.set_particle_count(25000)
		}
		4 { // Typhoon
			game.rain_intensity = 2.5
			game.wind_force = 5.0
			game.set_particle_count(80000)
		}
		5 { // M4 Armageddon Benchmark
			game.rain_intensity = 3.2
			game.wind_force = 7.0
			game.set_particle_count(500000)
			game.allocate_ram_benchmark(8192) // 8GB RAM
		}
		else {}
	}
}
