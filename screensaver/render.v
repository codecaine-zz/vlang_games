module main

pub struct GuiState {
pub mut:
	show_menu       bool
	show_hud        bool = true
	is_fullscreen   bool
	selected_index  int
	filter_category int // -1: All, 0-6: Categories
	scroll_offset   int
	search_query    string
	auto_cycle      bool = true
	cycle_timer     f64
	cycle_interval  f64 = 15.0
	show_crt_filter bool = true
	speed_scale     f64 = 1.0
}

pub fn draw_screensaver_scene(renderer &Renderer, templates []ScreensaverTemplate, mut state ScreensaverState, mut gui GuiState, w int, h int) {
	if gui.selected_index < 0 || gui.selected_index >= templates.len {
		gui.selected_index = 0
	}
	current_tmpl := &templates[gui.selected_index]

	// 1. Render active engine using full screen resolution
	render_screensaver_engine(renderer, current_tmpl, mut state, w, h)

	// 2. CRT Scanline Filter overlay
	if gui.show_crt_filter {
		set_render_draw_color(renderer, 0, 0, 0, 40)
		for y := 0; y < h; y += 3 {
			render_draw_line(renderer, 0, y, w, y)
		}
	}

	// 3. Info Banner HUD (only shown when HUD is enabled and menu is closed)
	if gui.show_hud && !gui.show_menu {
		fill_rect_c(renderer, 15, 15, 420, 56, Color{ r: 10, g: 15, b: 20, a: 210 })
		draw_rect_c(renderer, 15, 15, 420, 56, Color{ r: 80, g: 120, b: 160, a: 255 })
		draw_text(renderer, 25, 22, '${gui.selected_index + 1}/${templates.len}: ${current_tmpl.name}', 1, Color{ r: 255, g: 255, b: 255 })
		draw_text(renderer, 25, 38, 'Era: ${current_tmpl.year} | Engine: ${current_tmpl.engine} | [TAB] Menu | [H] Hide UI', 1, Color{ r: 150, g: 200, b: 255 })
		draw_text(renderer, 25, 54, 'Next: [Right]/[N]  Prev: [Left]/[P]  Cycle: [C] (${int(gui.cycle_interval)}s)  Full: [F]', 1, Color{ r: 180, g: 180, b: 180 })
	}

	// 4. Windows 95 Display Properties Dialog
	if gui.show_menu {
		draw_display_properties_dialog(renderer, templates, mut gui, w, h)
	}
}

fn draw_display_properties_dialog(renderer &Renderer, templates []ScreensaverTemplate, mut gui GuiState, w int, h int) {
	dialog_w := 640
	dialog_h := 480
	dx := (w - dialog_w) / 2
	dy := (h - dialog_h) / 2

	// Win95 Dialog Background (#c0c0c0)
	win_gray := Color{ r: 192, g: 192, b: 192, a: 255 }
	win_dark := Color{ r: 128, g: 128, b: 128, a: 255 }
	win_blue := Color{ r: 0, g: 0, b: 128, a: 255 }

	fill_rect_c(renderer, dx, dy, dialog_w, dialog_h, win_gray)
	draw_rect_c(renderer, dx, dy, dialog_w, dialog_h, Color{ r: 255, g: 255, b: 255 })
	draw_rect_c(renderer, dx + 1, dy + 1, dialog_w - 2, dialog_h - 2, win_dark)

	// Title Bar
	fill_rect_c(renderer, dx + 3, dy + 3, dialog_w - 6, 22, win_blue)
	draw_text(renderer, dx + 10, dy + 7, 'Display Properties - Screen Saver Suite (102 Templates)', 1, Color{ r: 255, g: 255, b: 255 })

	// Close Button [X]
	fill_rect_c(renderer, dx + dialog_w - 22, dy + 5, 16, 14, win_gray)
	draw_rect_c(renderer, dx + dialog_w - 22, dy + 5, 16, 14, Color{ r: 0, g: 0, b: 0 })
	draw_text(renderer, dx + dialog_w - 18, dy + 8, 'X', 1, Color{ r: 0, g: 0, b: 0 })

	// Monitor Preview Screen
	mon_x := dx + 30
	mon_y := dy + 35
	fill_rect_c(renderer, mon_x, mon_y, 160, 110, Color{ r: 40, g: 40, b: 40 })
	draw_rect_c(renderer, mon_x - 4, mon_y - 4, 168, 118, win_dark)
	fill_rect_c(renderer, mon_x + 60, mon_y + 114, 40, 16, win_gray)
	fill_rect_c(renderer, mon_x + 40, mon_y + 130, 80, 8, win_dark)

	// Inner Monitor Preview text
	current_tmpl := &templates[gui.selected_index]
	draw_text_centered(renderer, mon_x + 80, mon_y + 40, 'PREVIEW', 1, Color{ r: 0, g: 255, b: 0 })
	draw_text_centered(renderer, mon_x + 80, mon_y + 60, '${current_tmpl.year}', 1, Color{ r: 255, g: 255, b: 255 })

	// Controls Panel
	draw_text(renderer, dx + 210, dy + 40, 'Screen Saver Selection:', 1, Color{ r: 0, g: 0, b: 0 })

	// Scrollable List Box
	list_x := dx + 210
	list_y := dy + 58
	list_w := 400
	list_h := 220

	fill_rect_c(renderer, list_x, list_y, list_w, list_h, Color{ r: 255, g: 255, b: 255 })
	draw_rect_c(renderer, list_x, list_y, list_w, list_h, win_dark)

	items_visible := 12
	start_idx := gui.scroll_offset
	for i := 0; i < items_visible && start_idx + i < templates.len; i++ {
		t_idx := start_idx + i
		t_item := &templates[t_idx]
		item_y := list_y + 4 + i * 17

		if t_idx == gui.selected_index {
			fill_rect_c(renderer, list_x + 2, item_y - 2, list_w - 4, 16, win_blue)
			draw_text(renderer, list_x + 6, item_y, '${t_idx + 1}. ${t_item.name} (${t_item.year})', 1, Color{ r: 255, g: 255, b: 255 })
		} else {
			draw_text(renderer, list_x + 6, item_y, '${t_idx + 1}. ${t_item.name} (${t_item.year})', 1, Color{ r: 0, g: 0, b: 0 })
		}
	}

	// Description Box
	desc_y := dy + 290
	fill_rect_c(renderer, dx + 30, desc_y, dialog_w - 60, 80, win_gray)
	draw_rect_c(renderer, dx + 30, desc_y, dialog_w - 60, 80, win_dark)
	draw_text(renderer, dx + 40, desc_y + 8, 'Description:', 1, Color{ r: 0, g: 0, b: 128 })
	draw_text(renderer, dx + 40, desc_y + 24, current_tmpl.description, 1, Color{ r: 0, g: 0, b: 0 })
	draw_text(renderer, dx + 40, desc_y + 42, 'Category: ${current_tmpl.category} | Engine: ${current_tmpl.engine}', 1, win_dark)
	draw_text(renderer, dx + 40, desc_y + 58, 'Auto-Cycle: ${if gui.auto_cycle { "ENABLED (${int(gui.cycle_interval)}s)" } else { "DISABLED" }} | CRT Filter: ${if gui.show_crt_filter { "ON" } else { "OFF" }}', 1, Color{ r: 0, g: 100, b: 0 })

	// Buttons (OK / Cancel / Settings)
	draw_button(renderer, dx + dialog_w - 280, dy + dialog_h - 40, 80, 24, 'OK', true)
	draw_button(renderer, dx + dialog_w - 190, dy + dialog_h - 40, 80, 24, 'Cancel', false)
	draw_button(renderer, dx + dialog_w - 100, dy + dialog_h - 40, 80, 24, 'Apply', false)

	// Quick key hints
	draw_text(renderer, dx + 30, dy + dialog_h - 35, '[UP]/[DOWN] Browse  |  [ENTER] Select  |  [TAB]/[ESC] Close', 1, Color{ r: 80, g: 80, b: 80 })
}

fn draw_button(renderer &Renderer, x int, y int, w int, h int, label string, is_default bool) {
	win_gray := Color{ r: 192, g: 192, b: 192, a: 255 }
	fill_rect_c(renderer, x, y, w, h, win_gray)
	draw_rect_c(renderer, x, y, w, h, if is_default { Color{ r: 0, g: 0, b: 0 } } else { Color{ r: 128, g: 128, b: 128 } })
	draw_line_c(renderer, x, y, x + w - 1, y, Color{ r: 255, g: 255, b: 255 })
	draw_line_c(renderer, x, y, x, y + h - 1, Color{ r: 255, g: 255, b: 255 })
	draw_text_centered(renderer, x + w / 2, y + 6, label, 1, Color{ r: 0, g: 0, b: 0 })
}
