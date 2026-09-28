import os
import subprocess
import sys

MASTER_GFX = '''module main

import gg

pub struct Rect {
pub mut:
	x int
	y int
	w int
	h int
}

pub struct Point {
pub mut:
	x int
	y int
}

pub struct Texture {
pub mut:
	img   gg.Image
	valid bool
}

pub enum BlendMode {
	none
	blend
	add
	mod
	mul
}

pub enum RendererFlip {
	none       = 0
	horizontal = 1
	vertical   = 2
}

pub struct Renderer {
pub mut:
	ctx        &gg.Context = unsafe { nil }
	draw_color gg.Color
	width      int
	height     int
	logical_w  int
	logical_h  int
	scale      f32 = 1.0
	offset_x   f32 = 0.0
	offset_y   f32 = 0.0
	last_win_w int
	last_win_h int
}

pub fn (mut r Renderer) set_draw_color(red u8, green u8, blue u8, alpha u8) {
	r.draw_color = gg.Color{r: red, g: green, b: blue, a: alpha}
}

pub fn set_render_draw_color(renderer &Renderer, r u8, g u8, b u8, a u8) {
	unsafe {
		mut ren := &Renderer(renderer)
		ren.draw_color = gg.Color{r: r, g: g, b: b, a: a}
	}
}

@[inline]
pub fn (mut r Renderer) update_viewport() {
	if r.ctx == unsafe { nil } {
		return
	}
	ws := r.ctx.window_size()
	if ws.width <= 0 || ws.height <= 0 {
		return
	}
	if ws.width == r.last_win_w && ws.height == r.last_win_h && r.scale > 0.001 {
		return
	}
	r.last_win_w = ws.width
	r.last_win_h = ws.height

	if r.logical_w <= 0 || r.logical_h <= 0 {
		if r.width > 0 && r.height > 0 {
			r.logical_w = r.width
			r.logical_h = r.height
		} else if r.ctx.config.width > 0 && r.ctx.config.height > 0 {
			r.logical_w = r.ctx.config.width
			r.logical_h = r.ctx.config.height
		} else {
			r.logical_w = ws.width
			r.logical_h = ws.height
		}
	}
	sx := f32(ws.width) / f32(r.logical_w)
	sy := f32(ws.height) / f32(r.logical_h)
	s := if sx < sy { sx } else { sy }
	r.scale = s
	r.offset_x = (f32(ws.width) - f32(r.logical_w) * s) / 2.0
	r.offset_y = (f32(ws.height) - f32(r.logical_h) * s) / 2.0
}

pub fn (r &Renderer) screen_to_logical(sx f32, sy f32) (int, int) {
	if r.scale <= 0.001 {
		return int(sx), int(sy)
	}
	lx := int((sx - r.offset_x) / r.scale)
	ly := int((sy - r.offset_y) / r.scale)
	return lx, ly
}

pub fn (r &Renderer) draw_rect_filled(x f32, y f32, w f32, h f32, c gg.Color) {
	if r.ctx == unsafe { nil } { return }
	mut ren := unsafe { &Renderer(r) }
	ren.update_viewport()
	ren.ctx.draw_rect_filled(ren.offset_x + x * ren.scale, ren.offset_y + y * ren.scale, w * ren.scale, h * ren.scale, c)
}

pub fn (r &Renderer) draw_rect_empty(x f32, y f32, w f32, h f32, c gg.Color) {
	if r.ctx == unsafe { nil } { return }
	mut ren := unsafe { &Renderer(r) }
	ren.update_viewport()
	ren.ctx.draw_rect_empty(ren.offset_x + x * ren.scale, ren.offset_y + y * ren.scale, w * ren.scale, h * ren.scale, c)
}

pub fn (r &Renderer) draw_rounded_rect_filled(x f32, y f32, w f32, h f32, radius f32, c gg.Color) {
	if r.ctx == unsafe { nil } { return }
	mut ren := unsafe { &Renderer(r) }
	ren.update_viewport()
	ren.ctx.draw_rounded_rect_filled(ren.offset_x + x * ren.scale, ren.offset_y + y * ren.scale, w * ren.scale, h * ren.scale, radius * ren.scale, c)
}

pub fn (r &Renderer) draw_rounded_rect_empty(x f32, y f32, w f32, h f32, radius f32, c gg.Color) {
	if r.ctx == unsafe { nil } { return }
	mut ren := unsafe { &Renderer(r) }
	ren.update_viewport()
	ren.ctx.draw_rounded_rect_empty(ren.offset_x + x * ren.scale, ren.offset_y + y * ren.scale, w * ren.scale, h * ren.scale, radius * ren.scale, c)
}

pub fn (r &Renderer) draw_circle_filled(cx f32, cy f32, radius f32, c gg.Color) {
	if r.ctx == unsafe { nil } { return }
	mut ren := unsafe { &Renderer(r) }
	ren.update_viewport()
	ren.ctx.draw_circle_filled(ren.offset_x + cx * ren.scale, ren.offset_y + cy * ren.scale, radius * ren.scale, c)
}

pub fn (r &Renderer) draw_circle_empty(cx f32, cy f32, radius f32, c gg.Color) {
	if r.ctx == unsafe { nil } { return }
	mut ren := unsafe { &Renderer(r) }
	ren.update_viewport()
	ren.ctx.draw_circle_empty(ren.offset_x + cx * ren.scale, ren.offset_y + cy * ren.scale, radius * ren.scale, c)
}

pub fn (r &Renderer) draw_line(x1 f32, y1 f32, x2 f32, y2 f32, c gg.Color) {
	if r.ctx == unsafe { nil } { return }
	mut ren := unsafe { &Renderer(r) }
	ren.update_viewport()
	ren.ctx.draw_line(ren.offset_x + x1 * ren.scale, ren.offset_y + y1 * ren.scale, ren.offset_x + x2 * ren.scale, ren.offset_y + y2 * ren.scale, c)
}

pub fn (r &Renderer) draw_text(x int, y int, text string, cfg gg.TextCfg) {
	if r.ctx == unsafe { nil } { return }
	mut ren := unsafe { &Renderer(r) }
	ren.update_viewport()
	sx := int(ren.offset_x + f32(x) * ren.scale)
	sy := int(ren.offset_y + f32(y) * ren.scale)
	scaled_cfg := gg.TextCfg{
		...cfg
		size: int(f32(cfg.size) * ren.scale)
	}
	ren.ctx.draw_text(sx, sy, text, scaled_cfg)
}

pub fn (r &Renderer) draw_image_with_config(cfg gg.DrawImageConfig) {
	if r.ctx == unsafe { nil } { return }
	mut ren := unsafe { &Renderer(r) }
	ren.update_viewport()
	mut scaled_cfg := cfg
	scaled_cfg.img_rect = gg.Rect{
		x: ren.offset_x + cfg.img_rect.x * ren.scale
		y: ren.offset_y + cfg.img_rect.y * ren.scale
		width: cfg.img_rect.width * ren.scale
		height: cfg.img_rect.height * ren.scale
	}
	ren.ctx.draw_image_with_config(scaled_cfg)
}

pub fn render_clear(renderer &Renderer) {
	if renderer.ctx != unsafe { nil } {
		mut ren := unsafe { &Renderer(renderer) }
		ren.update_viewport()
		ws := renderer.ctx.window_size()
		w := if ws.width > 0 { f32(ws.width) } else { f32(renderer.width) }
		h := if ws.height > 0 { f32(ws.height) } else { f32(renderer.height) }
		renderer.ctx.draw_rect_filled(0, 0, w, h, renderer.draw_color)
	}
}

pub fn render_present(renderer &Renderer) {}

pub fn render_fill_rect(renderer &Renderer, rect &Rect) {
	if renderer.ctx != unsafe { nil } && rect != unsafe { nil } {
		mut ren := unsafe { &Renderer(renderer) }
		ren.update_viewport()
		x := ren.offset_x + f32(rect.x) * ren.scale
		y := ren.offset_y + f32(rect.y) * ren.scale
		w := f32(rect.w) * ren.scale
		h := f32(rect.h) * ren.scale
		renderer.ctx.draw_rect_filled(x, y, w, h, renderer.draw_color)
	}
}

pub fn render_draw_rect(renderer &Renderer, rect &Rect) {
	if renderer.ctx != unsafe { nil } && rect != unsafe { nil } {
		mut ren := unsafe { &Renderer(renderer) }
		ren.update_viewport()
		x := ren.offset_x + f32(rect.x) * ren.scale
		y := ren.offset_y + f32(rect.y) * ren.scale
		w := f32(rect.w) * ren.scale
		h := f32(rect.h) * ren.scale
		renderer.ctx.draw_rect_empty(x, y, w, h, renderer.draw_color)
	}
}

pub fn render_draw_line(renderer &Renderer, x1 int, y1 int, x2 int, y2 int) {
	if renderer.ctx != unsafe { nil } {
		mut ren := unsafe { &Renderer(renderer) }
		ren.update_viewport()
		sx1 := ren.offset_x + f32(x1) * ren.scale
		sy1 := ren.offset_y + f32(y1) * ren.scale
		sx2 := ren.offset_x + f32(x2) * ren.scale
		sy2 := ren.offset_y + f32(y2) * ren.scale
		renderer.ctx.draw_line(sx1, sy1, sx2, sy2, renderer.draw_color)
	}
}

pub fn render_draw_point(renderer &Renderer, x int, y int) {
	if renderer.ctx != unsafe { nil } {
		mut ren := unsafe { &Renderer(renderer) }
		ren.update_viewport()
		sx := ren.offset_x + f32(x) * ren.scale
		sy := ren.offset_y + f32(y) * ren.scale
		s := if ren.scale > 1.0 { ren.scale } else { 1.0 }
		renderer.ctx.draw_rect_filled(sx, sy, s, s, renderer.draw_color)
	}
}

pub fn render_copy(renderer &Renderer, tex &Texture, src &Rect, dst &Rect) {
	if renderer.ctx == unsafe { nil } || tex == unsafe { nil } || !tex.valid || dst == unsafe { nil } {
		return
	}
	mut ren := unsafe { &Renderer(renderer) }
	ren.update_viewport()
	mut cfg := gg.DrawImageConfig{
		img:      &tex.img
		img_rect: gg.Rect{
			x:      ren.offset_x + f32(dst.x) * ren.scale
			y:      ren.offset_y + f32(dst.y) * ren.scale
			width:  f32(dst.w) * ren.scale
			height: f32(dst.h) * ren.scale
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

pub fn render_copy_ex(renderer &Renderer, tex &Texture, src &Rect, dst &Rect, angle f64, center voidptr, flip RendererFlip) {
	if renderer.ctx == unsafe { nil } || tex == unsafe { nil } || !tex.valid || dst == unsafe { nil } {
		return
	}
	mut ren := unsafe { &Renderer(renderer) }
	ren.update_viewport()
	mut cfg := gg.DrawImageConfig{
		img:      &tex.img
		img_rect: gg.Rect{
			x:      ren.offset_x + f32(dst.x) * ren.scale
			y:      ren.offset_y + f32(dst.y) * ren.scale
			width:  f32(dst.w) * ren.scale
			height: f32(dst.h) * ren.scale
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

pub fn render_fill_circle(renderer &Renderer, cx f32, cy f32, radius f32) {
	if renderer.ctx != unsafe { nil } {
		mut ren := unsafe { &Renderer(renderer) }
		ren.update_viewport()
		renderer.ctx.draw_circle_filled(ren.offset_x + cx * ren.scale, ren.offset_y + cy * ren.scale, radius * ren.scale, renderer.draw_color)
	}
}

pub fn render_draw_circle(renderer &Renderer, cx f32, cy f32, radius f32) {
	if renderer.ctx != unsafe { nil } {
		mut ren := unsafe { &Renderer(renderer) }
		ren.update_viewport()
		renderer.ctx.draw_circle_empty(ren.offset_x + cx * ren.scale, ren.offset_y + cy * ren.scale, radius * ren.scale, renderer.draw_color)
	}
}

pub fn render_fill_ellipse(renderer &Renderer, cx f32, cy f32, rx f32, ry f32) {
	if renderer.ctx != unsafe { nil } {
		mut ren := unsafe { &Renderer(renderer) }
		ren.update_viewport()
		renderer.ctx.draw_ellipse_filled(ren.offset_x + cx * ren.scale, ren.offset_y + cy * ren.scale, rx * ren.scale, ry * ren.scale, renderer.draw_color)
	}
}

pub fn render_draw_ellipse(renderer &Renderer, cx f32, cy f32, rx f32, ry f32) {
	if renderer.ctx != unsafe { nil } {
		mut ren := unsafe { &Renderer(renderer) }
		ren.update_viewport()
		renderer.ctx.draw_ellipse_empty(ren.offset_x + cx * ren.scale, ren.offset_y + cy * ren.scale, rx * ren.scale, ry * ren.scale, renderer.draw_color)
	}
}

pub fn render_fill_rounded_rect(renderer &Renderer, x f32, y f32, w f32, h f32, radius f32) {
	if renderer.ctx != unsafe { nil } {
		mut ren := unsafe { &Renderer(renderer) }
		ren.update_viewport()
		renderer.ctx.draw_rounded_rect_filled(ren.offset_x + x * ren.scale, ren.offset_y + y * ren.scale, w * ren.scale, h * ren.scale, radius * ren.scale, renderer.draw_color)
	}
}

pub fn render_draw_rounded_rect(renderer &Renderer, x f32, y f32, w f32, h f32, radius f32) {
	if renderer.ctx != unsafe { nil } {
		mut ren := unsafe { &Renderer(renderer) }
		ren.update_viewport()
		renderer.ctx.draw_rounded_rect_empty(ren.offset_x + x * ren.scale, ren.offset_y + y * ren.scale, w * ren.scale, h * ren.scale, radius * ren.scale, renderer.draw_color)
	}
}

pub fn render_fill_triangle(renderer &Renderer, x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32) {
	if renderer.ctx != unsafe { nil } {
		mut ren := unsafe { &Renderer(renderer) }
		ren.update_viewport()
		renderer.ctx.draw_triangle_filled(
			ren.offset_x + x1 * ren.scale, ren.offset_y + y1 * ren.scale,
			ren.offset_x + x2 * ren.scale, ren.offset_y + y2 * ren.scale,
			ren.offset_x + x3 * ren.scale, ren.offset_y + y3 * ren.scale,
			renderer.draw_color
		)
	}
}

pub fn render_fill_polygon(renderer &Renderer, cx f32, cy f32, radius f32, edges int, rotation f32) {
	if renderer.ctx != unsafe { nil } {
		mut ren := unsafe { &Renderer(renderer) }
		ren.update_viewport()
		renderer.ctx.draw_polygon_filled(ren.offset_x + cx * ren.scale, ren.offset_y + cy * ren.scale, radius * ren.scale, edges, rotation, renderer.draw_color)
	}
}

pub fn set_texture_blend_mode(tex &Texture, mode BlendMode) {}

pub fn set_render_draw_blend_mode(renderer &Renderer, mode BlendMode) {}

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
'''

def update_game(g):
    if g in ('air_hockey', 'engine', 'cyberrunner', 'pong', 'snake'):
        return True
    
    # 1. Update gfx.v
    gfx_path = os.path.join(g, 'gfx.v')
    with open(gfx_path, 'w') as fp:
        fp.write(MASTER_GFX)
    
    # 2. Update main.v
    main_path = os.path.join(g, 'main.v')
    if not os.path.exists(main_path):
        return False
    with open(main_path) as fp:
        mtxt = fp.read()
    
    # Mouse scaling in on_event
    old_ev = 'fn on_event(e &gg.Event, data voidptr) {\n\tmut app := unsafe { &App(data) }'
    new_ev = '''fn on_event(e &gg.Event, data voidptr) {
\tmut app := unsafe { &App(data) }
\tif e.typ in [.mouse_move, .mouse_down, .mouse_up, .mouse_scroll] && app.renderer.scale > 0.001 {
\t\tmut me := unsafe { &gg.Event(e) }
\t\tme.mouse_x = (e.mouse_x - app.renderer.offset_x) / app.renderer.scale
\t\tme.mouse_y = (e.mouse_y - app.renderer.offset_y) / app.renderer.scale
\t}'''
    if old_ev in mtxt and 'app.renderer.scale > 0.001' not in mtxt:
        mtxt = mtxt.replace(old_ev, new_ev)
    
    # Add .f11, .grave_accent to match e.key_code
    if '.f11' not in mtxt and '.grave_accent' not in mtxt:
        old_kd = '\t\t.key_down {\n\t\t\tmatch e.key_code {'
        new_kd = '\t\t.key_down {\n\t\t\tmatch e.key_code {\n\t\t\t\t.f11, .grave_accent {\n\t\t\t\t\tgg.toggle_fullscreen()\n\t\t\t\t}'
        if old_kd in mtxt:
            mtxt = mtxt.replace(old_kd, new_kd)
        else:
            # Try alternate indentation or spacing
            for cand in ['\t\t\tmatch e.key_code {', 'match e.key_code {']:
                if cand in mtxt:
                    mtxt = mtxt.replace(cand, cand + '\n\t\t\t\t.f11, .grave_accent {\n\t\t\t\t\tgg.toggle_fullscreen()\n\t\t\t\t}', 1)
                    break
    
    # Ensure resizable: true
    if 'resizable:     false' in mtxt:
        mtxt = mtxt.replace('resizable:     false', 'resizable:     true')
    elif 'resizable: false' in mtxt:
        mtxt = mtxt.replace('resizable: false', 'resizable: true')
    elif 'resizable:' not in mtxt and 'window_title:' in mtxt:
        mtxt = mtxt.replace('window_title:', 'resizable:     true\n\t\twindow_title:', 1)
    
    with open(main_path, 'w') as fp:
        fp.write(mtxt)
    
    return True

def main():
    games = sorted([d for d in os.listdir('.') if os.path.isdir(d) and not d.startswith('.') and d not in ('scripts', 'assets', 'shared', 'air_hockey', 'engine')])
    print(f'Processing {len(games)} games...')
    failed = []
    for i, g in enumerate(games):
        update_game(g)
        res = subprocess.run(['v', '-check', g], capture_output=True, text=True)
        if res.returncode == 0:
            print(f'[{i+1}/{len(games)}] {g}: PASS')
        else:
            print(f'[{i+1}/{len(games)}] {g}: FAIL!')
            print(res.stderr[:300])
            failed.append(g)
    
    print(f'Finished! Passed: {len(games) - len(failed)}/{len(games)}')
    if failed:
        print(f'Failed games ({len(failed)}): {failed}')
        sys.exit(1)

if __name__ == '__main__':
    main()
