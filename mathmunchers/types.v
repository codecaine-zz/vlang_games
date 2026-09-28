module main

pub enum RuleType {
	multiples
	factors
	primes
	equals
	greater_than
	less_than
	squares
}

pub enum Difficulty {
	easy
	medium
	hard
}

pub struct RuleInfo {
pub mut:
	rule_type   RuleType
	param       int
	title       string
	description string
}

pub enum PowerUpType {
	none
	freeze
	safe_zone
	bonus_star
}

pub struct Cell {
pub mut:
	value          int
	expr           string
	is_target      bool
	eaten          bool
	flash_timer    f64
	is_wrong_flash bool
	dissolve_timer f64
	power_up       PowerUpType
}

pub struct Player {
pub mut:
	grid_x              int
	grid_y              int
	real_x              f64
	real_y              f64
	score               int
	lives               int = 3
	combo               int
	munch_anim_timer    f64
	invincibility_timer f64
	blink_timer         f64
	step_timer          f64
	facing_right        bool = true
	extra_life_score    int = 10000
}

pub enum TroggleType {
	reggie
	smartie
	glutton
	bashful
	helper
}

pub struct Troggle {
pub mut:
	grid_x        int
	grid_y        int
	real_x        f64
	real_y        f64
	kind          TroggleType
	move_timer    f64
	move_interval f64 = 1.8
	anim_frame    int
	anim_timer    f64
	active        bool = true
}

pub struct TroggleWarning {
pub mut:
	grid_x     int
	grid_y     int
	timer      f64
	kind       TroggleType
	edge_side  int // 0: Top, 1: Right, 2: Bottom, 3: Left
}

pub struct Particle {
pub mut:
	x        f64
	y        f64
	vx       f64
	vy       f64
	color    Color
	life     f64
	max_life f64
	size     int = 4
}

pub struct FloatingText {
pub mut:
	x     f64
	y     f64
	text  string
	color Color
	life  f64
}

pub struct BonusStar {
pub mut:
	x     f64
	y     f64
	vy    f64
	value int = 200
}

pub enum GameState {
	start_menu
	playing
	paused
	bonus_round
	level_clear
	game_over
}

pub struct Color {
pub:
	r u8
	g u8
	b u8
	a u8 = 255
}

pub struct Button {
pub mut:
	x            int
	y            int
	w            int
	h            int
	text         string
	bg_color     Color
	hover_color  Color
	text_color   Color
	border_color Color
}

pub fn (b Button) contains(mx int, my int) bool {
	return mx >= b.x && mx <= b.x + b.w && my >= b.y && my <= b.y + b.h
}
