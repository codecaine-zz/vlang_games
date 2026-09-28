module main

pub enum ZoneType {
	cavern
	catacombs
	flooded
}

pub enum WeaponType {
	standard
	machinegun
	shotgun
	laser
	burst
}

pub enum EnemyType {
	bat
	turtle
	crawler
	eye
}

pub enum BlockType {
	empty
	solid
	destructible
	shop_door
	gem_block
}

pub struct Particle {
pub mut:
	x        f64
	y        f64
	dx       f64
	dy       f64
	life     f64
	max_life f64
	color    Color
	size     int
}

pub struct Bullet {
pub mut:
	x           f64
	y           f64
	dx          f64
	dy          f64
	w           f64
	h           f64
	damage      int
	lifetime    f64
	from_player bool
}

pub struct Enemy {
pub mut:
	x            f64
	y            f64
	vx           f64
	vy           f64
	w            f64
	h            f64
	hp           int
	max_hp       int
	kind         EnemyType
	is_red       bool
	frame_timer  f64
	facing_right bool
	active       bool
}

pub enum PickupType {
	gem
	health
	max_health
	ammo
}

pub struct Pickup {
pub mut:
	x      f64
	y      f64
	kind   PickupType
	amount int
	active bool
}

pub struct ShopItem {
pub mut:
	name   string
	cost   int
	kind   PickupType
	bought bool
}

pub struct Player {
pub mut:
	x            f64
	y            f64
	vx           f64
	vy           f64
	w            f64
	h            f64
	hp           int
	max_hp       int
	gems         int
	ammo         int
	max_ammo     int
	weapon       WeaponType
	facing_right bool
	is_grounded  bool
	can_shoot    bool
	shoot_cooldown f64
	combo        int
	invuln_timer f64
}

pub struct Block {
pub mut:
	kind BlockType
	hp   int
}

pub struct DownwellGame {
pub mut:
	stage          int = 1
	depth          f64
	well_width     int = 14
	well_height    int = 160
	block_size     int = 32
	grid           [][]Block
	player         Player
	enemies        []Enemy
	bullets        []Bullet
	pickups        []Pickup
	particles      []Particle
	camera_y       f64
	game_over      bool
	victory        bool
	high_score     int
	shop_active    bool
	shop_items     []ShopItem
	screen_shake   f64
	score          int
	zone           ZoneType = .cavern
	last_sound_event string
}

pub struct Color {
pub mut:
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

pub fn (b Button) contains(px int, py int) bool {
	return px >= b.x && px <= b.x + b.w && py >= b.y && py <= b.y + b.h
}
