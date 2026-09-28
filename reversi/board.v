module main

const board_size = 8

const piece_empty = 0
const piece_black = 1
const piece_white = 2

struct Point {
pub:
	r int
	c int
}

struct BoardState {
	cells          [8][8]int
	current_player int
	black_count    int
	white_count    int
}

struct Board {
pub mut:
	cells          [8][8]int
	current_player int
	black_count    int
	white_count    int
	game_over      bool
	winner         int
	last_move      Point
	history        []BoardState
}

fn new_board() Board {
	mut b := Board{
		current_player: piece_black
		black_count:    2
		white_count:    2
		game_over:      false
		winner:         0
		last_move:      Point{r: -1, c: -1}
	}
	// Initial 4 discs in center
	b.cells[3][3] = piece_white
	b.cells[3][4] = piece_black
	b.cells[4][3] = piece_black
	b.cells[4][4] = piece_white
	return b
}

fn is_valid_coord(r int, c int) bool {
	return r >= 0 && r < board_size && c >= 0 && c < board_size
}

fn opponent_of(player int) int {
	return if player == piece_black { piece_white } else { piece_black }
}

fn (b &Board) get_flips_in_dir(r int, c int, dr int, dc int, player int) []Point {
	mut flips := []Point{}
	opp := opponent_of(player)
	mut curr_r := r + dr
	mut curr_c := c + dc

	for is_valid_coord(curr_r, curr_c) && b.cells[curr_r][curr_c] == opp {
		flips << Point{r: curr_r, c: curr_c}
		curr_r += dr
		curr_c += dc
	}

	if is_valid_coord(curr_r, curr_c) && b.cells[curr_r][curr_c] == player && flips.len > 0 {
		return flips
	}
	return []Point{}
}

fn (b &Board) get_all_flips(r int, c int, player int) []Point {
	if !is_valid_coord(r, c) || b.cells[r][c] != piece_empty {
		return []Point{}
	}

	mut all_flips := []Point{}
	directions := [
		Point{r: -1, c: -1}, Point{r: -1, c: 0}, Point{r: -1, c: 1},
		Point{r: 0, c: -1},                     Point{r: 0, c: 1},
		Point{r: 1, c: -1},  Point{r: 1, c: 0},  Point{r: 1, c: 1},
	]

	for dir in directions {
		flips := b.get_flips_in_dir(r, c, dir.r, dir.c, player)
		for pt in flips {
			all_flips << pt
		}
	}
	return all_flips
}

fn (b &Board) is_valid_move(r int, c int, player int) bool {
	return b.get_all_flips(r, c, player).len > 0
}

fn (b &Board) get_valid_moves(player int) []Point {
	mut moves := []Point{}
	for r in 0 .. board_size {
		for c in 0 .. board_size {
			if b.is_valid_move(r, c, player) {
				moves << Point{r: r, c: c}
			}
		}
	}
	return moves
}

fn (mut b Board) update_counts() {
	mut blacks := 0
	mut whites := 0
	for r in 0 .. board_size {
		for c in 0 .. board_size {
			if b.cells[r][c] == piece_black {
				blacks++
			} else if b.cells[r][c] == piece_white {
				whites++
			}
		}
	}
	b.black_count = blacks
	b.white_count = whites
}

fn (mut b Board) make_move(r int, c int) ([]Point, bool) {
	if b.game_over {
		return []Point{}, false
	}
	flips := b.get_all_flips(r, c, b.current_player)
	if flips.len == 0 {
		return []Point{}, false
	}

	// Save history for undo
	b.history << BoardState{
		cells:          b.cells
		current_player: b.current_player
		black_count:    b.black_count
		white_count:    b.white_count
	}

	// Place disc
	b.cells[r][c] = b.current_player
	for pt in flips {
		b.cells[pt.r][pt.c] = b.current_player
	}
	b.last_move = Point{r: r, c: c}
	b.update_counts()

	// Switch player or pass
	next_player := opponent_of(b.current_player)
	next_moves := b.get_valid_moves(next_player)

	if next_moves.len > 0 {
		b.current_player = next_player
	} else {
		// Next player has no moves (Pass!)
		curr_moves := b.get_valid_moves(b.current_player)
		if curr_moves.len == 0 {
			// Both players have no moves -> Game over!
			b.game_over = true
			if b.black_count > b.white_count {
				b.winner = piece_black
			} else if b.white_count > b.black_count {
				b.winner = piece_white
			} else {
				b.winner = 0 // Draw
			}
		}
	}

	return flips, true
}

fn (mut b Board) undo() bool {
	if b.history.len == 0 {
		return false
	}
	state := b.history.pop()
	b.cells = state.cells
	b.current_player = state.current_player
	b.black_count = state.black_count
	b.white_count = state.white_count
	b.game_over = false
	b.winner = 0
	b.last_move = Point{r: -1, c: -1}
	return true
}
