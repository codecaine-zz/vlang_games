module main

import math
import rand

pub struct Particle {
pub mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	life  f64
	max_l f64
	color Color
	size  int
}

pub fn spawn_burst(mut particles []Particle, x f64, y f64, count int, color Color) {
	for _ in 0 .. count {
		angle := rand.f64() * 2.0 * math.pi
		speed := 40.0 + rand.f64() * 220.0
		life := 0.25 + rand.f64() * 0.45
		particles << Particle{
			x: x
			y: y
			vx: math.cos(angle) * speed
			vy: math.sin(angle) * speed
			life: life
			max_l: life
			color: color
			size: 2 + rand.intn(3) or { 1 }
		}
	}
}

pub fn spawn_arrow_spark(mut particles []Particle, x f64, y f64, dir_x f64, dir_y f64) {
	for _ in 0 .. 5 {
		angle := math.atan2(dir_y, dir_x) + (rand.f64() - 0.5) * 0.8
		speed := 80.0 + rand.f64() * 120.0
		life := 0.15 + rand.f64() * 0.2
		particles << Particle{
			x: x
			y: y
			vx: math.cos(angle) * speed
			vy: math.sin(angle) * speed
			life: life
			max_l: life
			color: Color{r: 255, g: 220, b: 80, a: 255}
			size: 2
		}
	}
}

pub fn update_particles(mut particles []Particle, dt f64) {
	for i := particles.len - 1; i >= 0; i-- {
		particles[i].x += particles[i].vx * dt
		particles[i].y += particles[i].vy * dt
		particles[i].life -= dt
		if particles[i].life <= 0 {
			particles.delete(i)
		}
	}
}

pub fn render_particles(renderer &Renderer, particles []Particle) {
	for p in particles {
		alpha := u8(math.max(0.0, math.min(255.0, (p.life / p.max_l) * 255.0)))
		set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, alpha)
		rect := Rect{
			x: int(p.x) - p.size / 2
			y: int(p.y) - p.size / 2
			w: p.size
			h: p.size
		}
		render_fill_rect(renderer, &rect)
	}
}
