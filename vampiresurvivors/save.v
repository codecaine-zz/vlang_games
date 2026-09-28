module main

import os

pub struct SaveData {
pub mut:
	total_gold      int
	might_lvl       int
	health_lvl      int
	speed_lvl       int
	greed_lvl       int
	growth_lvl      int
	rerolls_lvl     int
	banish_lvl      int
	unlocked_stages []string
	unlocked_chars  []string
	achievements    []string
}

pub fn get_save_dir() string {
	home := os.home_dir()
	$if macos {
		return os.join_path(home, 'Library', 'Application Support', 'vampiresurvivors')
	} $else $if linux {
		xdg_config := os.getenv('XDG_CONFIG_HOME')
		config_base := if xdg_config != '' { xdg_config } else { os.join_path(home, '.config') }
		return os.join_path(config_base, 'vampiresurvivors')
	} $else $if windows {
		appdata := os.getenv('APPDATA')
		base := if appdata != '' { appdata } else { os.join_path(home, 'AppData', 'Roaming') }
		return os.join_path(base, 'vampiresurvivors')
	} $else {
		return '.'
	}
}

pub fn get_save_path() string {
	dir := get_save_dir()
	os.mkdir_all(dir) or {}
	target := os.join_path(dir, 'save.json')

	// Auto-Migrate legacy local ./save.json to user platform folder if needed
	if os.exists('save.json') && !os.exists(target) && target != 'save.json' {
		os.cp('save.json', target) or {}
	}

	return target
}

pub fn load_save_data() SaveData {
	mut path := get_save_path()
	if !os.exists(path) && os.exists('save.json') {
		path = 'save.json'
	}
	if !os.exists(path) {
		return SaveData{
			total_gold:      0
			might_lvl:       0
			health_lvl:      0
			speed_lvl:       0
			greed_lvl:       0
			growth_lvl:      0
			rerolls_lvl:     0
			banish_lvl:      0
			unlocked_stages: ['mad_forest']
			unlocked_chars:  ['antonio', 'imelda', 'pasqualina', 'gennaro']
			achievements:    []
		}
	}

	lines := os.read_lines(path) or { return SaveData{} }
	mut sd := SaveData{
		unlocked_stages: ['mad_forest']
		unlocked_chars:  ['antonio', 'imelda', 'pasqualina', 'gennaro']
	}

	for line in lines {
		parts := line.split('=')
		if parts.len != 2 {
			continue
		}
		key := parts[0].trim_space()
		val := parts[1].trim_space()
		match key {
			'total_gold' { sd.total_gold = val.int() }
			'might_lvl' { sd.might_lvl = val.int() }
			'health_lvl' { sd.health_lvl = val.int() }
			'speed_lvl' { sd.speed_lvl = val.int() }
			'greed_lvl' { sd.greed_lvl = val.int() }
			'growth_lvl' { sd.growth_lvl = val.int() }
			'rerolls_lvl' { sd.rerolls_lvl = val.int() }
			'banish_lvl' { sd.banish_lvl = val.int() }
			'unlocked_stages' {
				sd.unlocked_stages = val.split(',')
			}
			'unlocked_chars' {
				sd.unlocked_chars = val.split(',')
			}
			'achievements' {
				if val.len > 0 {
					sd.achievements = val.split(',')
				}
			}
			else {}
		}
	}
	return sd
}

pub fn save_data_to_file(sd &SaveData) {
	path := get_save_path()
	mut content := 'total_gold=${sd.total_gold}\n'
	content += 'might_lvl=${sd.might_lvl}\n'
	content += 'health_lvl=${sd.health_lvl}\n'
	content += 'speed_lvl=${sd.speed_lvl}\n'
	content += 'greed_lvl=${sd.greed_lvl}\n'
	content += 'growth_lvl=${sd.growth_lvl}\n'
	content += 'rerolls_lvl=${sd.rerolls_lvl}\n'
	content += 'banish_lvl=${sd.banish_lvl}\n'
	content += 'unlocked_stages=${sd.unlocked_stages.join(",")}\n'
	content += 'unlocked_chars=${sd.unlocked_chars.join(",")}\n'
	content += 'achievements=${sd.achievements.join(",")}\n'
	os.write_file(path, content) or {}
}
