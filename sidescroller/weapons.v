module main

import math

enum WeaponType {
	pulse
	spread
	plasma
	missile
	flame
	grenade
	hyper_laser
	tesla
}

struct WeaponInfo {
	name        string
	symbol      string
	cooldown    f64 // seconds between shots
	damage      f64
	ammo_cost   int
	speed       f64
	description string
}

fn get_weapon_info(w WeaponType) WeaponInfo {
	return match w {
		.pulse {
			WeaponInfo{
				name:        'PULSE BLASTER'
				symbol:      'PLS'
				cooldown:    0.12
				damage:      18.0
				ammo_cost:   0
				speed:       750.0
				description: 'Standard rapid plasma bolt streams. Infinite ammo.'
			}
		}
		.spread {
			WeaponInfo{
				name:        'SPREAD VULCAN'
				symbol:      'SPD'
				cooldown:    0.22
				damage:      14.0
				ammo_cost:   1
				speed:       680.0
				description: 'Fires 5 heavy shotgun energy pellets in a wide cone.'
			}
		}
		.plasma {
			WeaponInfo{
				name:        'PLASMA RAILGUN'
				symbol:      'PLM'
				cooldown:    0.35
				damage:      45.0
				ammo_cost:   2
				speed:       950.0
				description: 'Piercing rail beam that passes through target armor.'
			}
		}
		.missile {
			WeaponInfo{
				name:        'HOMING MISSILES'
				symbol:      'MIS'
				cooldown:    0.28
				damage:      30.0
				ammo_cost:   1
				speed:       480.0
				description: 'Guided micro-rockets tracking nearest enemy targets.'
			}
		}
		.flame {
			WeaponInfo{
				name:        'FLAMETHROWER'
				symbol:      'FLM'
				cooldown:    0.06
				damage:      8.0
				ammo_cost:   1
				speed:       380.0
				description: 'Continuous intense fire stream causing burning over time.'
			}
		}
		.grenade {
			WeaponInfo{
				name:        'GRENADE MORTAR'
				symbol:      'GRN'
				cooldown:    0.40
				damage:      60.0
				ammo_cost:   2
				speed:       420.0
				description: 'Arcing explosive mortar shells splitting into cluster bomblets.'
			}
		}
		.hyper_laser {
			WeaponInfo{
				name:        'HYPER LASER'
				symbol:      'LSR'
				cooldown:    0.15
				damage:      32.0
				ammo_cost:   1
				speed:       1100.0
				description: 'High-energy linear beam stream vaporizing weak targets.'
			}
		}
		.tesla {
			WeaponInfo{
				name:        'TESLA SHOCKER'
				symbol:      'TSL'
				cooldown:    0.25
				damage:      38.0
				ammo_cost:   2
				speed:       850.0
				description: 'Chain lightning discharge arcing across hostiles.'
			}
		}
	}
}

struct Projectile {
pub mut:
	x           f64
	y           f64
	vx          f64
	vy          f64
	weapon_type WeaponType
	damage      f64
	radius      f64
	life        f64
	max_life    f64
	target_id   int = -1
	is_enemy    bool
	pierce      int = 1
	bounces     int
}

fn create_projectiles(w WeaponType, px f64, py f64, dir_x f64, dir_y f64, is_overdrive bool, is_enemy bool) []Projectile {
	info := get_weapon_info(w)
	mut mult := 1.0
	if is_overdrive {
		mult = 1.3
	}
	spd := info.speed * mult
	dmg := info.damage * mult

	mut list := []Projectile{}

	match w {
		.pulse {
			list << Projectile{
				x:           px
				y:           py - 4.0
				vx:          dir_x * spd
				vy:          dir_y * spd
				weapon_type: w
				damage:      dmg
				radius:      4.0
				life:        1.5
				max_life:    1.5
				is_enemy:    is_enemy
			}
			list << Projectile{
				x:           px
				y:           py + 4.0
				vx:          dir_x * spd
				vy:          dir_y * spd
				weapon_type: w
				damage:      dmg
				radius:      4.0
				life:        1.5
				max_life:    1.5
				is_enemy:    is_enemy
			}
		}
		.spread {
			angles := [-0.26, -0.13, 0.0, 0.13, 0.26]
			for a in angles {
				cos_a := math.cos(a)
				sin_a := math.sin(a)
				vx := (dir_x * cos_a - dir_y * sin_a) * spd
				vy := (dir_x * sin_a + dir_y * cos_a) * spd
				list << Projectile{
					x:           px
					y:           py
					vx:          vx
					vy:          vy
					weapon_type: w
					damage:      dmg
					radius:      5.0
					life:        1.2
					max_life:    1.2
					is_enemy:    is_enemy
				}
			}
		}
		.plasma {
			list << Projectile{
				x:           px
				y:           py
				vx:          dir_x * spd
				vy:          dir_y * spd
				weapon_type: w
				damage:      dmg
				radius:      8.0
				life:        2.0
				max_life:    2.0
				pierce:      4
				is_enemy:    is_enemy
			}
		}
		.missile {
			list << Projectile{
				x:           px
				y:           py - 10.0
				vx:          dir_x * (spd * 0.7)
				vy:          -120.0
				weapon_type: w
				damage:      dmg
				radius:      6.0
				life:        2.5
				max_life:    2.5
				is_enemy:    is_enemy
			}
			list << Projectile{
				x:           px
				y:           py + 10.0
				vx:          dir_x * (spd * 0.7)
				vy:          120.0
				weapon_type: w
				damage:      dmg
				radius:      6.0
				life:        2.5
				max_life:    2.5
				is_enemy:    is_enemy
			}
		}
		.flame {
			for i in 0 .. 3 {
				spread_y := (f64(i) - 1.0) * 80.0
				list << Projectile{
					x:           px
					y:           py
					vx:          dir_x * (spd + (f64(i) * 30.0))
					vy:          spread_y
					weapon_type: w
					damage:      dmg
					radius:      9.0
					life:        0.45
					max_life:    0.45
					is_enemy:    is_enemy
				}
			}
		}
		.grenade {
			list << Projectile{
				x:           px
				y:           py
				vx:          dir_x * spd
				vy:          -180.0
				weapon_type: w
				damage:      dmg
				radius:      8.0
				life:        1.8
				max_life:    1.8
				is_enemy:    is_enemy
			}
		}
		.hyper_laser {
			list << Projectile{
				x:           px
				y:           py
				vx:          dir_x * spd
				vy:          dir_y * spd
				weapon_type: w
				damage:      dmg
				radius:      6.0
				life:        1.0
				max_life:    1.0
				pierce:      2
				is_enemy:    is_enemy
			}
		}
		.tesla {
			list << Projectile{
				x:           px
				y:           py
				vx:          dir_x * spd
				vy:          dir_y * spd
				weapon_type: w
				damage:      dmg
				radius:      7.0
				life:        1.2
				max_life:    1.2
				pierce:      3
				is_enemy:    is_enemy
			}
		}
	}
	return list
}
