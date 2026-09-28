module main

import os

pub struct ChipsSaveData {
pub mut:
	max_level_unlocked int
	current_level      int
	save_state_valid   bool
	state_level        int
	state_player_x     int
	state_player_y     int
	state_chips_left   int
	state_time_left    f64
	state_keys         []int
	state_boots        []bool
	state_grid_lines   []string
}

pub fn get_chips_save_path() string {
	home := os.home_dir()
	mut dir := '.'
	$if macos {
		dir = os.join_path(home, 'Library', 'Application Support', 'chipschallenge')
	} $else $if linux {
		xdg_config := os.getenv('XDG_CONFIG_HOME')
		config_base := if xdg_config != '' { xdg_config } else { os.join_path(home, '.config') }
		dir = os.join_path(config_base, 'chipschallenge')
	} $else $if windows {
		appdata := os.getenv('APPDATA')
		base := if appdata != '' { appdata } else { os.join_path(home, 'AppData', 'Roaming') }
		dir = os.join_path(base, 'chipschallenge')
	}
	os.mkdir_all(dir) or {}
	return os.join_path(dir, 'save.txt')
}

pub fn load_chips_save() ChipsSaveData {
	path := get_chips_save_path()
	if !os.exists(path) {
		return ChipsSaveData{}
	}
	lines := os.read_lines(path) or { return ChipsSaveData{} }
	mut data := ChipsSaveData{
		state_keys: [0, 0, 0, 0]
		state_boots: [false, false, false, false]
	}

	for line in lines {
		if line.starts_with('grid_line=') {
			data.state_grid_lines << line.all_after('grid_line=')
			continue
		}
		parts := line.split('=')
		if parts.len != 2 {
			continue
		}
		key := parts[0].trim_space()
		val := parts[1].trim_space()
		match key {
			'max_level_unlocked' { data.max_level_unlocked = val.int() }
			'current_level' { data.current_level = val.int() }
			'save_state_valid' { data.save_state_valid = val.bool() }
			'state_level' { data.state_level = val.int() }
			'state_player_x' { data.state_player_x = val.int() }
			'state_player_y' { data.state_player_y = val.int() }
			'state_chips_left' { data.state_chips_left = val.int() }
			'state_time_left' { data.state_time_left = val.f64() }
			'keys' {
				k_parts := val.split(',')
				if k_parts.len == 4 {
					data.state_keys = [k_parts[0].int(), k_parts[1].int(), k_parts[2].int(), k_parts[3].int()]
				}
			}
			'boots' {
				b_parts := val.split(',')
				if b_parts.len == 4 {
					data.state_boots = [b_parts[0].bool(), b_parts[1].bool(), b_parts[2].bool(), b_parts[3].bool()]
				}
			}
			else {}
		}
	}
	return data
}

pub fn save_chips_data(data &ChipsSaveData) {
	path := get_chips_save_path()
	mut content := 'max_level_unlocked=${data.max_level_unlocked}\n'
	content += 'current_level=${data.current_level}\n'
	content += 'save_state_valid=${data.save_state_valid}\n'
	content += 'state_level=${data.state_level}\n'
	content += 'state_player_x=${data.state_player_x}\n'
	content += 'state_player_y=${data.state_player_y}\n'
	content += 'state_chips_left=${data.state_chips_left}\n'
	content += 'state_time_left=${data.state_time_left}\n'
	content += 'keys=${data.state_keys[0]},${data.state_keys[1]},${data.state_keys[2]},${data.state_keys[3]}\n'
	content += 'boots=${data.state_boots[0]},${data.state_boots[1]},${data.state_boots[2]},${data.state_boots[3]}\n'
	for line in data.state_grid_lines {
		content += 'grid_line=${line}\n'
	}
	os.write_file(path, content) or {}
}
