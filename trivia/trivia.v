module main

import rand

pub struct Question {
pub:
	category    string
	question    string
	options     []string
	correct_idx int // 0 to 3
}

pub enum GameState {
	title
	question
	answer_reveal
	round_summary
	game_over
}

pub struct TriviaGame {
pub mut:
	questions            []Question
	active_indices       []int
	current_q_idx        int
	state                GameState = .title
	is_two_player        bool
	p1_score             int
	p2_score             int
	p1_streak            int
	p2_streak            int
	p1_selected          int = -1 // 0-3
	p2_selected          int = -1 // 0-3
	question_timer       f64
	question_duration    f64 = 15.0
	reveal_timer         f64
	total_rounds         int = 10
	current_round        int = 1
	sound_event          string
	double_wager_active  bool
}

pub fn new_trivia_game(is_2p bool) TriviaGame {
	mut g := TriviaGame{
		is_two_player: is_2p
	}
	g.init_questions()
	g.reset()
	return g
}

pub fn (mut g TriviaGame) init_questions() {
	g.questions.clear()

	// Category: Gaming & Retro Tech
	g.questions << Question{
		category: 'Gaming & Retro Tech'
		question: 'What was Mario\'s original name in 1981 Donkey Kong?'
		options: ['Jumpman', 'Plumber Boy', 'Luigi', 'Red Cap']
		correct_idx: 0
	}
	g.questions << Question{
		category: 'Gaming & Retro Tech'
		question: 'What piece in Tetris is composed of 4 square blocks in a line?'
		options: ['T-Tetromino', 'I-Tetromino (Line)', 'O-Tetromino', 'L-Tetromino']
		correct_idx: 1
	}
	g.questions << Question{
		category: 'Gaming & Retro Tech'
		question: 'Which legendary game creator designed Pac-Man in 1980?'
		options: ['Shigeru Miyamoto', 'Toru Iwatani', 'Gunpei Yokoi', 'Hideo Kojima']
		correct_idx: 1
	}
	g.questions << Question{
		category: 'Gaming & Retro Tech'
		question: 'What famous cheat input is known as the Konami Code?'
		options: ['Up Up Down Down Left Right Left Right B A', 'A B A B Up Down Left Right Select Start', 'Left Right Up Down B A B A', 'Down Down Up Up B A B A']
		correct_idx: 0
	}
	g.questions << Question{
		category: 'Gaming & Retro Tech'
		question: 'What programming language was V inspired by for extreme speed and simplicity?'
		options: ['C, Go, and Rust', 'COBOL and Fortran', 'PHP and Ruby', 'Perl and Haskell']
		correct_idx: 0
	}

	// Category: Science, Nature & Space
	g.questions << Question{
		category: 'Science, Nature & Space'
		question: 'What planet in our solar system has the most moons (146+)?'
		options: ['Jupiter', 'Saturn', 'Uranus', 'Neptune']
		correct_idx: 1
	}
	g.questions << Question{
		category: 'Science, Nature & Space'
		question: 'What is the powerhouse organelle of eukaryotic biological cells?'
		options: ['Ribosome', 'Mitochondria', 'Golgi Apparatus', 'Endoplasmic Reticulum']
		correct_idx: 1
	}
	g.questions << Question{
		category: 'Science, Nature & Space'
		question: 'Approximately how long does sunlight take to reach Earth?'
		options: ['8 minutes and 20 seconds', '1 minute', '1 hour', 'Instantaneous']
		correct_idx: 0
	}
	g.questions << Question{
		category: 'Science, Nature & Space'
		question: 'What is the chemical symbol for the element Gold?'
		options: ['Ag', 'Au', 'Fe', 'Gd']
		correct_idx: 1
	}
	g.questions << Question{
		category: 'Science, Nature & Space'
		question: 'What is the fastest land animal on Earth, reaching 70 mph?'
		options: ['Pronghorn Antelope', 'Cheetah', 'Peregrine Falcon', 'Lion']
		correct_idx: 1
	}

	// Category: Pop Culture & Cinema
	g.questions << Question{
		category: 'Pop Culture & Cinema'
		question: 'What color pill does Neo choose in the 1999 movie The Matrix?'
		options: ['Blue Pill', 'Red Pill', 'Green Pill', 'Gold Pill']
		correct_idx: 1
	}
	g.questions << Question{
		category: 'Pop Culture & Cinema'
		question: 'Which fictional secret agent holds the famous license to kill (007)?'
		options: ['Ethan Hunt', 'Jason Bourne', 'James Bond', 'Austin Powers']
		correct_idx: 2
	}
	g.questions << Question{
		category: 'Pop Culture & Cinema'
		question: 'In Back to the Future, what vehicle is converted into a Time Machine?'
		options: ['DeLorean DMC-12', 'Pontiac Firebird', 'Ford Mustang', 'Chevrolet Corvette']
		correct_idx: 0
	}
	g.questions << Question{
		category: 'Pop Culture & Cinema'
		question: 'Who composed the iconic music for Star Wars, Indiana Jones, and Jurassic Park?'
		options: ['Hans Zimmer', 'John Williams', 'Ennio Morricone', 'Danny Elfman']
		correct_idx: 1
	}

	// Category: World History & Geography
	g.questions << Question{
		category: 'World History & Geography'
		question: 'What is the longest river in the world?'
		options: ['Amazon River', 'Nile River', 'Yangtze River', 'Mississippi River']
		correct_idx: 1
	}
	g.questions << Question{
		category: 'World History & Geography'
		question: 'In what year did the Apollo 11 moon landing take place?'
		options: ['1965', '1969', '1972', '1975']
		correct_idx: 1
	}
	g.questions << Question{
		category: 'World History & Geography'
		question: 'Which country is home to the ancient Wonder of the World Petra?'
		options: ['Egypt', 'Jordan', 'Greece', 'Turkey']
		correct_idx: 1
	}
	g.questions << Question{
		category: 'World History & Geography'
		question: 'What is the capital city of Japan?'
		options: ['Kyoto', 'Tokyo', 'Osaka', 'Sapporo']
		correct_idx: 1
	}

	// Category: Logic & Brainteasers
	g.questions << Question{
		category: 'Logic & Brainteasers'
		question: 'If you have a 3-gallon jug and a 5-gallon jug, how many gallons can you measure?'
		options: ['Every integer 1 through 5', 'Only 3 and 5', 'Only 4', 'Only 8']
		correct_idx: 0
	}
	g.questions << Question{
		category: 'Logic & Brainteasers'
		question: 'What has keys but opens no locks, space but no room, and allows you to enter?'
		options: ['A Piano', 'A Keyboard', 'A Map', 'A Safe']
		correct_idx: 1
	}
}

pub fn (mut g TriviaGame) reset() {
	g.p1_score = 0
	g.p2_score = 0
	g.p1_streak = 0
	g.p2_streak = 0
	g.current_round = 1
	g.double_wager_active = false
	g.state = .title

	// Shuffle questions into active queue
	g.active_indices.clear()
	mut pool := []int{}
	for i in 0 .. g.questions.len {
		pool << i
	}
	for pool.len > 0 {
		idx := rand.int_in_range(0, pool.len) or { 0 }
		g.active_indices << pool[idx]
		pool.delete(idx)
	}
	g.current_q_idx = 0
}

pub fn (mut g TriviaGame) start_game() {
	g.reset()
	g.state = .question
	g.start_question()
}

pub fn (mut g TriviaGame) start_question() {
	g.p1_selected = -1
	g.p2_selected = -1
	g.question_timer = g.question_duration
	g.state = .question
	g.sound_event = 'lock'
}

pub fn (mut g TriviaGame) get_current_question() Question {
	if g.active_indices.len == 0 {
		return g.questions[0]
	}
	q_idx := g.active_indices[g.current_q_idx % g.active_indices.len]
	return g.questions[q_idx]
}

pub fn (mut g TriviaGame) submit_answer_p1(opt_idx int) {
	if g.state != .question || g.p1_selected != -1 || opt_idx < 0 || opt_idx > 3 {
		return
	}
	g.p1_selected = opt_idx
	g.sound_event = 'lock'

	if !g.is_two_player || g.p2_selected != -1 {
		g.resolve_question()
	}
}

pub fn (mut g TriviaGame) submit_answer_p2(opt_idx int) {
	if g.state != .question || !g.is_two_player || g.p2_selected != -1 || opt_idx < 0 || opt_idx > 3 {
		return
	}
	g.p2_selected = opt_idx
	g.sound_event = 'lock'

	if g.p1_selected != -1 {
		g.resolve_question()
	}
}

pub fn (mut g TriviaGame) resolve_question() {
	g.state = .answer_reveal
	g.reveal_timer = 2.8
	q := g.get_current_question()

	// Base points (scales with remaining time)
	time_bonus := int((g.question_timer / g.question_duration) * 500.0)
	base_pts := 500 + time_bonus
	multiplier := if g.double_wager_active { 2 } else { 1 }

	// Evaluate P1
	if g.p1_selected == q.correct_idx {
		g.p1_streak++
		streak_bonus := g.p1_streak * 100
		g.p1_score += (base_pts + streak_bonus) * multiplier
		g.sound_event = 'correct'
	} else {
		g.p1_streak = 0
		g.sound_event = 'wrong'
	}

	// Evaluate P2 (if 2P)
	if g.is_two_player {
		if g.p2_selected == q.correct_idx {
			g.p2_streak++
			streak_bonus := g.p2_streak * 100
			g.p2_score += (base_pts + streak_bonus) * multiplier
		} else {
			g.p2_streak = 0
		}
	}
}

pub fn (mut g TriviaGame) advance_to_next() {
	g.current_round++
	if g.current_round > g.total_rounds || g.current_q_idx + 1 >= g.active_indices.len {
		g.state = .game_over
		g.sound_event = 'victory'
	} else {
		g.current_q_idx++
		g.start_question()
	}
}

pub fn (mut g TriviaGame) update(dt f64) {
	if g.state == .question {
		g.question_timer -= dt
		if g.question_timer <= 0 {
			g.question_timer = 0
			g.resolve_question()
		}
	} else if g.state == .answer_reveal {
		g.reveal_timer -= dt
		if g.reveal_timer <= 0 {
			g.advance_to_next()
		}
	}
}
