module main

fn test_trivia_init() {
	mut g := new_trivia_game(false)
	assert g.questions.len >= 20
	assert g.p1_score == 0
	assert g.state == .title
}

fn test_trivia_question_flow() {
	mut g := new_trivia_game(false)
	g.start_game()
	assert g.state == .question
	assert g.question_timer == 15.0

	q := g.get_current_question()
	assert q.options.len == 4
	assert q.correct_idx >= 0 && q.correct_idx <= 3

	// Submit correct answer
	g.submit_answer_p1(q.correct_idx)
	assert g.state == .answer_reveal
	assert g.p1_streak == 1
	assert g.p1_score > 0
}

fn test_trivia_wrong_answer() {
	mut g := new_trivia_game(false)
	g.start_game()
	q := g.get_current_question()

	wrong_idx := (q.correct_idx + 1) % 4
	g.submit_answer_p1(wrong_idx)
	assert g.state == .answer_reveal
	assert g.p1_streak == 0
	assert g.p1_score == 0
}
