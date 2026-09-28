module main

pub enum CharacterType {
	fish
	crystal
	robot
}

pub enum WeaponType {
	revolver
	shotgun
	laser_rifle
	grenade_launcher
	machinegun
	crossbow
}

pub enum EnemyKind {
	maggot
	bandit
	scorpion
	assassin
	big_bandit
}

pub enum MutationType {
	bloodlust
	rhino_skin
	scavenger
	laser_brain
	extra_feet
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
	x            f64
	y            f64
	dx           f64
	dy           f64
	w            f64
	h            f64
	damage       int
	lifetime     f64
	from_player  bool
	is_explosive bool
	is_laser     bool
	color        Color
}

pub enum PickupKind {
	rad
	ammo
	health
	weapon_chest
}

pub struct Pickup {
pub mut:
	x           f64
	y           f64
	kind        PickupKind
	amount      int
	weapon_kind WeaponType
	active      bool
}

pub struct Enemy {
pub mut:
	x           f64
	y           f64
	vx          f64
	vy          f64
	w           f64
	h           f64
	hp          int
	max_hp      int
	kind        EnemyKind
	shoot_timer f64
	angle       f64
	active      bool
}

pub struct Player {
pub mut:
	x                f64
	y                f64
	vx               f64
	vy               f64
	w                f64
	h                f64
	hp               int
	max_hp           int
	rads             int
	level            int
	weapon           WeaponType
	secondary_weapon WeaponType
	ammo             int
	max_ammo         int
	character        CharacterType
	roll_timer       f64
	shield_timer     f64
	invuln_timer     f64
	shoot_cooldown   f64
	aim_angle        f64
	kills            int
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

pub struct WallBlock {
pub mut:
	solid bool
	hp    int
}

pub struct NuclearThroneGame {
pub mut:
	stage               int = 1
	substage            int = 1
	arena_w             int = 1200
	arena_h             int = 1200
	tile_size           int = 40
	cols                int = 30
	rows                int = 30
	grid                [][]WallBlock
	player              Player
	enemies             []Enemy
	bullets             []Bullet
	pickups             []Pickup
	particles           []Particle
	camera_x            f64
	camera_y            f64
	game_over           bool
	victory             bool
	high_score          int
	screen_shake        f64
	score               int
	rads_to_next_level  int = 30
	mutation_screen     bool
	available_mutations []MutationType
	active_mutations    []MutationType
	boss_spawned        bool
	last_sound_event    string
}
