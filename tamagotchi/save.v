module main

import os

pub struct TamaSaveData {
pub mut:
	save_state_valid bool
	stage_idx        int = 1
	name             string = 'Mametchi'
	age_days         int = 1
	weight_oz        int = 5
	hunger           int = 3
	happiness        int = 3
	discipline       int = 50
	energy           int = 100
	is_sleeping      bool
	is_sick          bool
	poop_count       int
}

pub fn get_tama_save_path() string {
	home := os.home_dir()
	mut dir := '.'
	$if macos {
		dir = os.join_path(home, 'Library', 'Application Support', 'tamagotchi')
	} $else $if linux {
		xdg_config := os.getenv('XDG_CONFIG_HOME')
		config_base := if xdg_config != '' { xdg_config } else { os.join_path(home, '.config') }
		dir = os.join_path(config_base, 'tamagotchi')
	} $else $if windows {
		appdata := os.getenv('APPDATA')
		base := if appdata != '' { appdata } else { os.join_path(home, 'AppData', 'Roaming') }
		dir = os.join_path(base, 'tamagotchi')
	}
	os.mkdir_all(dir) or {}
	return os.join_path(dir, 'save.txt')
}

pub fn load_tama_save() TamaSaveData {
	path := get_tama_save_path()
	if !os.exists(path) {
		return TamaSaveData{}
	}
	lines := os.read_lines(path) or { return TamaSaveData{} }
	mut data := TamaSaveData{}

	for line in lines {
		parts := line.split('=')
		if parts.len != 2 {
			continue
		}
		key := parts[0].trim_space()
		val := parts[1].trim_space()
		match key {
			'save_state_valid' { data.save_state_valid = val.bool() }
			'stage_idx' { data.stage_idx = val.int() }
			'name' { data.name = val }
			'age_days' { data.age_days = val.int() }
			'weight_oz' { data.weight_oz = val.int() }
			'hunger' { data.hunger = val.int() }
			'happiness' { data.happiness = val.int() }
			'discipline' { data.discipline = val.int() }
			'energy' { data.energy = val.int() }
			'is_sleeping' { data.is_sleeping = val.bool() }
			'is_sick' { data.is_sick = val.bool() }
			'poop_count' { data.poop_count = val.int() }
			else {}
		}
	}
	return data
}

pub fn save_tama_data(data &TamaSaveData) {
	path := get_tama_save_path()
	mut content := 'save_state_valid=${data.save_state_valid}\n'
	content += 'stage_idx=${data.stage_idx}\n'
	content += 'name=${data.name}\n'
	content += 'age_days=${data.age_days}\n'
	content += 'weight_oz=${data.weight_oz}\n'
	content += 'hunger=${data.hunger}\n'
	content += 'happiness=${data.happiness}\n'
	content += 'discipline=${data.discipline}\n'
	content += 'energy=${data.energy}\n'
	content += 'is_sleeping=${data.is_sleeping}\n'
	content += 'is_sick=${data.is_sick}\n'
	content += 'poop_count=${data.poop_count}\n'
	os.write_file(path, content) or {}
}
