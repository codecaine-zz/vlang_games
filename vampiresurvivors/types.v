module main

import math

pub const win_width = 1000
pub const win_height = 800
pub const world_width = 3200.0
pub const world_height = 3200.0

pub enum GameState {
	character_select
	power_up_shop
	stage_select
	playing
	level_up
	chest_opened
	paused
	game_over
	victory
}

pub enum StageType {
	mad_forest      // Classic dark forest
	inlaid_library   // Marble library corridor
	castle_grounds   // Volcanic obsidian castle
}

pub enum DifficultyLevel {
	normal  // 1.0x HP / Damage
	hard    // 1.8x HP / 1.5x Dmg / Faster Ranged Attacks
	inferno // 3.0x HP / 2.2x Dmg / Bullet-Hell Swarms & Champions
}

pub enum CharacterClass {
	antonio    // Whip master (+10% base damage, starts with Whip, Ultimate: Blood Tempest)
	imelda     // Magic Wand caster (+10% exp gain, starts with Magic Wand, Ultimate: Astral Nova)
	pasqualina // Runetracer (+10% projectile speed, starts with King Bible, Ultimate: Runic Judgement)
	gennaro    // Knife master (+1 extra projectile to all weapons, starts with Knife, Ultimate: Blade Hurricane)
	mortaccio  // Bone master (+1 projectile per 20 levels, starts with Axe, Ultimate: Bone Avalanche)
	eleanor    // Arcane sorceress (-15% cooldowns, starts with Prismatic Laser, Ultimate: Arcane Cataclysm)
}

pub enum WeaponType {
	whip
	magic_wand
	knife
	axe
	holy_bible
	garlic
	lightning_ring
	fire_wand
	cataclysm_nuke
	prismatic_laser
	// Evolved Super Weapons
	bloody_tear
	holy_wand
	thousand_edge
	death_spiral
	unholy_vespers
	soul_eater
	thunder_loop
	hellfire
	supernova
	gamma_ray
}

pub enum PassiveType {
	spinach    // +15% Damage per level
	armor      // -1 Damage taken per level
	empty_tome // -10% Cooldown per level
	wings      // +15% Move Speed per level
	crown      // +15% EXP Gain per level
	duplicator // +2 Extra Projectiles per level
	clover     // +10% Crit Chance per level
	hollow_heart // +20 Max HP per level
	pumarola   // +1.0 HP Regen/sec per level
}

pub enum EnemyType {
	bat
	skeleton
	zombie
	ghost
	mudman
	werewolf
	red_skull
	reaper_boss
}

pub enum GemType {
	blue   // 1 XP
	green  // 5 XP
	red    // 25 XP
	chest  // Boss treasure chest
}

pub enum FloorPickupType {
	vacuum_orb
	rosary_bomb
	freeze_watch
	floor_chicken
	coin_bag
}

pub struct FloorPickup {
pub mut:
	kind FloorPickupType
	x    f64
	y    f64
	life f64 = 60.0
}

pub struct BreakableProp {
pub mut:
	x       f64
	y       f64
	hp      f64 = 1.0
	is_urn  bool
}

pub struct BloodStain {
pub mut:
	x    f64
	y    f64
	rad  f64
	life f64 = 30.0
}

pub struct MistParticle {
pub mut:
	x    f64
	y    f64
	vx   f64
	vy   f64
	rad  f64
	life f64
	max_l f64
}

pub struct Firefly {
pub mut:
	x    f64
	y    f64
	base_x f64
	base_y f64
	phase  f64
	speed  f64
}

pub struct Weapon {
pub mut:
	kind         WeaponType
	level        int
	cooldown     f64
	timer        f64
	damage       f64
	speed        f64
	count        int
	duration     f64
	area         f64
	total_damage f64
	is_evolved   bool
}

pub struct Passive {
pub mut:
	kind  PassiveType
	level int
}

pub struct UpgradeChoice {
pub:
	is_weapon    bool
	w_kind       WeaponType
	p_kind       PassiveType
	name         string
	desc         string
	level        int
	is_evolution bool
}

pub struct Projectile {
pub mut:
	kind        WeaponType
	x           f64
	y           f64
	vx          f64
	vy          f64
	damage      f64
	life        f64
	max_life    f64
	radius      f64
	pierce      int
	angle       f64
	orbit_dist  f64
	owner_id    int
	is_ultimate bool
}

pub struct EnemyProjectile {
pub mut:
	x      f64
	y      f64
	vx     f64
	vy     f64
	damage f64
	life   f64
	radius f64
}

pub struct HazardZone {
pub mut:
	x        f64
	y        f64
	radius   f64
	timer    f64
	max_t    f64
	damage   f64
	fired    bool
	is_line  bool
	target_x f64
	target_y f64
}

pub struct Enemy {
pub mut:
	kind        EnemyType
	x           f64
	y           f64
	vx          f64
	vy          f64
	kb_vx       f64
	kb_vy       f64
	hp          f64
	max_hp      f64
	speed       f64
	damage      f64
	radius      f64
	exp_val     int
	flash_time  f64
	shoot_timer f64
	is_boss     bool
	is_champion bool
	dead        bool
}

pub struct ExpGem {
pub mut:
	kind       GemType
	x          f64
	y          f64
	value      int
	magnetized bool
	speed      f64
}

pub struct DamageNum {
pub mut:
	x       f64
	y       f64
	val     int
	life    f64
	is_crit bool
	is_heal bool
}

pub struct Particle {
pub mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	life  f64
	max_l f64
	r     u8
	g     u8
	b     u8
	size  f64
}

pub struct DashGhost {
pub mut:
	x    f64
	y    f64
	life f64
}

pub struct Player {
pub mut:
	id             int
	char_class     CharacterClass
	name           string
	x              f64
	y              f64
	vx             f64
	vy             f64
	facing_right   bool
	moving         bool
	walk_frame     f64
	hp             f64
	max_hp         f64
	speed          f64
	magnet_rad     f64
	level          int
	exp            int
	exp_next       int
	kills          int
	gold           int
	invuln_time    f64
	dash_cooldown  f64
	dash_timer     f64
	is_dashing     bool
	rerolls        int = 2
	skips          int = 2
	banishes       int = 2
	banished_items []string
	ultimate_meter f64 = 100.0
	ultimate_max   f64 = 100.0
	weapons        []Weapon
	passives       []Passive
}

pub struct Color {
pub:
	r u8
	g u8
	b u8
	a u8 = 255
}

// Distance helper
pub fn dist(x1 f64, y1 f64, x2 f64, y2 f64) f64 {
	dx := x2 - x1
	dy := y2 - y1
	return math.sqrt(dx * dx + dy * dy)
}

pub fn normalize(dx f64, dy f64) (f64, f64) {
	len := math.sqrt(dx * dx + dy * dy)
	if len <= 0.0001 {
		return 0.0, 0.0
	}
	return dx / len, dy / len
}
