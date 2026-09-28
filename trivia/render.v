module main

import math

const col_studio_bg = Color{ r: 18, g: 15, b: 38, a: 255 }
const col_studio_panel = Color{ r: 32, g: 26, b: 64, a: 255 }
const col_gold = Color{ r: 255, g: 215, b: 0, a: 255 }
const col_opt_a = Color{ r: 230, g: 60, b: 50, a: 255 }   // Red
const col_opt_b = Color{ r: 50, g: 130, b: 240, a: 255 }  // Blue
const col_opt_c = Color{ r: 240, g: 180, b: 30, a: 255 }  // Yellow
const col_opt_d = Color{ r: 40, g: 200, b: 90, a: 255 }   // Green
const col_correct_green = Color{ r: 50, g: 230, b: 100, a: 255 }

pub fn render_trivia_game(renderer &Renderer, mut g TriviaGame, w int, h int, mx int, my int) {
	// TV Studio backdrop
	draw_beveled_box(renderer, 0, 0, w, h, col_studio_bg, Color{r:70,g:50,b:110}, Color{r:10,g:8,b:20})

	// Top Show Header & Score Podiums
	draw_beveled_box(renderer, 24, 16, w - 48, 65, col_studio_panel, col_gold, Color{r:15,g:10,b:30})

	// P1 Podium
	draw_text(renderer, 45, 26, 'PLAYER 1', 1, Color{r:200,g:230,b:255})
	draw_text(renderer, 45, 42, '${g.p1_score} PTS', 3, col_gold)
	if g.p1_streak > 1 {
		draw_text(renderer, 200, 48, '🔥 ${g.p1_streak}x STREAK', 1, Color{r:255,g:120,b:60})
	}

	// Center Show Logo & Round Counter
	draw_text_centered(renderer, w / 2, 24, 'PARTY TRIVIA SHOW', 2, col_gold)
	draw_text_centered(renderer, w / 2, 50, 'ROUND ${g.current_round} / ${g.total_rounds}', 1, Color{r:180,g:220,b:255})

	// P2 Podium (if 2P)
	if g.is_two_player {
		draw_text(renderer, w - 180, 26, 'PLAYER 2', 1, Color{r:255,g:200,b:220})
		draw_text(renderer, w - 180, 42, '${g.p2_score} PTS', 3, col_gold)
	}

	// Title Screen Phase
	if g.state == .title {
		draw_beveled_box(renderer, w / 2 - 280, h / 2 - 130, 560, 260, col_studio_panel, col_gold, Color{r:15,g:10,b:30})
		draw_text_centered(renderer, w / 2, h / 2 - 90, 'PARTY TRIVIA SHOW', 4, col_gold)
		draw_text_centered(renderer, w / 2, h / 2 - 30, 'TV QUIZ ARENA • MULTI-CATEGORY QUESTIONS', 1, Color{r:200,g:230,b:255})
		draw_text_centered(renderer, w / 2, h / 2 + 10, '1P SOLO MARATHON & 2P LOCAL BUZZER DUEL', 1, Color{r:255,g:180,b:220})
		draw_beveled_box(renderer, w / 2 - 180, h / 2 + 50, 360, 48, Color{r:40,g:140,b:70}, col_gold, Color{r:15,g:50,b:25})
		draw_text_centered(renderer, w / 2, h / 2 + 66, 'PRESS SPACE TO START QUIZ!', 1, Color{r:255,g:255,b:255})
		return
	}

	// Game Over / Podium Phase
	if g.state == .game_over {
		draw_beveled_box(renderer, w / 2 - 260, h / 2 - 120, 520, 240, col_studio_panel, col_gold, Color{r:15,g:10,b:30})
		draw_text_centered(renderer, w / 2, h / 2 - 80, '🏆 FINAL PODIUM 🏆', 3, col_gold)
		if g.is_two_player {
			winner_name := if g.p1_score > g.p2_score { 'PLAYER 1 WINS!' } else if g.p2_score > g.p1_score { 'PLAYER 2 WINS!' } else { 'TIE GAME!' }
			draw_text_centered(renderer, w / 2, h / 2 - 25, winner_name, 3, Color{r:255,g:255,b:255})
			draw_text_centered(renderer, w / 2, h / 2 + 25, 'P1: ${g.p1_score} PTS  vs  P2: ${g.p2_score} PTS', 2, Color{r:200,g:230,b:255})
		} else {
			draw_text_centered(renderer, w / 2, h / 2 - 25, 'CONGRATULATIONS!', 3, Color{r:255,g:255,b:255})
			draw_text_centered(renderer, w / 2, h / 2 + 25, 'FINAL SCORE: ${g.p1_score} POINTS', 2, col_gold)
		}
		draw_text_centered(renderer, w / 2, h / 2 + 75, 'PRESS SPACE OR R TO PLAY AGAIN', 1, Color{r:180,g:220,b:255})
		return
	}

	// Current Question Box
	q := g.get_current_question()
	draw_beveled_box(renderer, 24, 95, w - 48, 140, Color{r:22,g:18,b:48}, col_gold, Color{r:10,g:6,b:20})

	// Category Badge
	draw_beveled_box(renderer, 45, 105, 260, 26, Color{r:50,g:35,b:90}, Color{r:160,g:140,b:220}, Color{r:20,g:10,b:40})
	draw_text(renderer, 55, 114, 'CATEGORY: ${q.category}', 1, col_gold)

	// Question text (Word wrapped / centered)
	draw_text_centered(renderer, w / 2, 160, q.question, 2, Color{r:255,g:255,b:255})

	// Timer Bar below question
	time_ratio := math.clamp(g.question_timer / g.question_duration, 0.0, 1.0)
	bar_w := w - 96
	draw_beveled_box(renderer, 48, 245, bar_w, 18, Color{r:20,g:10,b:30}, col_gold, Color{r:10,g:5,b:15})
	timer_col := if time_ratio < 0.25 { Color{r:255,g:60,b:60} } else { col_gold }
	draw_beveled_box(renderer, 48, 245, int(f64(bar_w) * time_ratio), 18, timer_col, Color{r:255,g:255,b:255}, timer_col)

	// 4 Multiple Choice Answer Options (2x2 Grid)
	opt_cols := [col_opt_a, col_opt_b, col_opt_c, col_opt_d]
	opt_keys_p1 := ['1 / A', '2 / B', '3 / C', '4 / D']

	btn_w := (w - 72) / 2
	btn_h := 85

	for i in 0 .. 4 {
		gx := i % 2
		gy := i / 2
		bx := 24 + gx * (btn_w + 24)
		by := 280 + gy * (btn_h + 20)

		is_correct := (i == q.correct_idx)
		is_selected_p1 := (g.p1_selected == i)

		mut bg_col := Color{r:30,g:25,b:55}
		mut border_col := opt_cols[i]

		if g.state == .answer_reveal {
			if is_correct {
				bg_col = Color{r:30,g:140,b:60}
				border_col = col_correct_green
			} else if is_selected_p1 && !is_correct {
				bg_col = Color{r:150,g:30,b:30}
				border_col = Color{r:255,g:80,b:80}
			}
		} else if is_selected_p1 {
			bg_col = Color{r:60,g:50,b:100}
			border_col = col_gold
		}

		draw_beveled_box(renderer, bx, by, btn_w, btn_h, bg_col, border_col, Color{r:10,g:8,b:20})

		// Option Letter / Key shortcut badge
		badge_str := '${u8(`A` + i).ascii_str()} [${opt_keys_p1[i]}]'
		draw_text(renderer, bx + 16, by + 16, badge_str, 1, opt_cols[i])

		// Option Text
		draw_text(renderer, bx + 16, by + 42, q.options[i], 2, Color{r:255,g:255,b:255})
	}

	// Result Feedback Banner during answer reveal
	if g.state == .answer_reveal {
		banner_y := h - 140
		if g.p1_selected == q.correct_idx {
			draw_beveled_box(renderer, w / 2 - 200, banner_y, 400, 60, Color{r:25,g:120,b:50}, col_gold, Color{r:10,g:40,b:15})
			draw_text_centered(renderer, w / 2, banner_y + 18, '★ CORRECT ANSWER! ★', 2, Color{r:255,g:255,b:255})
		} else {
			draw_beveled_box(renderer, w / 2 - 200, banner_y, 400, 60, Color{r:140,g:25,b:25}, Color{r:255,g:100,b:100}, Color{r:50,g:10,b:10})
			draw_text_centered(renderer, w / 2, banner_y + 18, 'INCORRECT!', 2, Color{r:255,g:255,b:255})
		}
	}

	// Bottom Controls Bar
	draw_text_centered(renderer, w / 2, h - 22, 'Select Answer: 1-4 / Q-R / Mouse Click | Space: Continue | M: 1P/2P Mode | S: Sound', 1, Color{r:160,g:180,b:220})
}
