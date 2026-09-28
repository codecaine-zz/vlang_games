module main

import gg

pub struct Rect {
pub mut:
	x int
	y int
	w int
	h int
}

// Point definition is conditional or voidptr

pub struct Texture {
pub mut:
	img   gg.Image
	valid bool
}

pub struct Renderer {
pub mut:
	ctx        &gg.Context = unsafe { nil }
	draw_color gg.Color
	width      int
	height     int
}

pub fn (mut r Renderer) set_draw_color(red u8, green u8, blue u8, alpha u8) {
	r.draw_color = gg.Color{r: red, g: green, b: blue, a: alpha}
}

pub fn set_render_draw_color(renderer &Renderer, r u8, g u8, b u8, a u8) {
	unsafe {
		mut ren := &Renderer(voidptr(renderer))
		ren.draw_color = gg.Color{r: r, g: g, b: b, a: a}
	}
}

pub fn render_clear(renderer &Renderer) {
	if renderer.ctx != unsafe { nil } {
		renderer.ctx.draw_rect_filled(0, 0, f32(renderer.width), f32(renderer.height), renderer.draw_color)
	}
}

pub fn render_present(renderer &Renderer) {}

pub fn render_fill_rect(renderer &Renderer, rect &Rect) {
	if renderer.ctx != unsafe { nil } && rect != unsafe { nil } {
		renderer.ctx.draw_rect_filled(f32(rect.x), f32(rect.y), f32(rect.w), f32(rect.h), renderer.draw_color)
	}
}

pub fn render_draw_rect(renderer &Renderer, rect &Rect) {
	if renderer.ctx != unsafe { nil } && rect != unsafe { nil } {
		renderer.ctx.draw_rect_empty(f32(rect.x), f32(rect.y), f32(rect.w), f32(rect.h), renderer.draw_color)
	}
}

pub fn render_draw_line(renderer &Renderer, x1 int, y1 int, x2 int, y2 int) {
	if renderer.ctx != unsafe { nil } {
		renderer.ctx.draw_line(f32(x1), f32(y1), f32(x2), f32(y2), renderer.draw_color)
	}
}

pub fn render_draw_point(renderer &Renderer, x int, y int) {
	if renderer.ctx != unsafe { nil } {
		renderer.ctx.draw_rect_filled(f32(x), f32(y), 1, 1, renderer.draw_color)
	}
}

pub fn render_copy(renderer &Renderer, tex &Texture, src &Rect, dst &Rect) {
	if renderer.ctx == unsafe { nil } || tex == unsafe { nil } || !tex.valid || dst == unsafe { nil } {
		return
	}
	mut cfg := gg.DrawImageConfig{
		img:      &tex.img
		img_rect: gg.Rect{
			x:      f32(dst.x)
			y:      f32(dst.y)
			width:  f32(dst.w)
			height: f32(dst.h)
		}
	}
	if src != unsafe { nil } {
		cfg.part_rect = gg.Rect{
			x:      f32(src.x)
			y:      f32(src.y)
			width:  f32(src.w)
			height: f32(src.h)
		}
	}
	renderer.ctx.draw_image_with_config(cfg)
}

pub enum RendererFlip {
	none       = 0
	horizontal = 1
	vertical   = 2
}

pub fn render_copy_ex(renderer &Renderer, tex &Texture, src &Rect, dst &Rect, angle f64, center voidptr, flip RendererFlip) {
	if renderer.ctx == unsafe { nil } || tex == unsafe { nil } || !tex.valid || dst == unsafe { nil } {
		return
	}
	mut cfg := gg.DrawImageConfig{
		img:      &tex.img
		img_rect: gg.Rect{
			x:      f32(dst.x)
			y:      f32(dst.y)
			width:  f32(dst.w)
			height: f32(dst.h)
		}
		rotation: f32(angle)
	}
	if src != unsafe { nil } {
		cfg.part_rect = gg.Rect{
			x:      f32(src.x)
			y:      f32(src.y)
			width:  f32(src.w)
			height: f32(src.h)
		}
	}
	renderer.ctx.draw_image_with_config(cfg)
}

pub fn set_texture_blend_mode(tex &Texture, mode int) {}

pub fn set_render_draw_blend_mode(renderer &Renderer, mode int) {}

pub fn render_set_clip_rect(renderer &Renderer, rect &Rect) {}

pub fn load_texture(ctx &gg.Context, path string) &Texture {
	img := ctx.create_image(path) or { return &Texture{} }
	return &Texture{
		img:   img
		valid: true
	}
}

pub fn load_bmp(path string) &Texture {
	return &Texture{}
}
