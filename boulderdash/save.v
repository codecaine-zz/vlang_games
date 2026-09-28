module main

import os

pub struct BoulderSaveData {
pub mut:
	high_score         int
	max_cave_unlocked  int
	current_cave       int
	save_state_valid   bool
	state_cave         int
	state_score        int
	state_lives        int
	state_diamonds_got int
	state_time_left    f64
	state_player_r     int
	state_player_c     int
	state_grid_lines   []string
}

pub fn get_boulder_save_path() string {
	home := os.home_dir()
	mut dir := '.'
	$if macos {
		dir = os.join_path(home, 'Library', 'Application Support', 'boulderdash')
	} $else $if linux {
		xdg_config := os.getenv('XDG_CONFIG_HOME')
		config_base := if xdg_config != '' { xdg_config } else { os.join_path(home, '.config') }
		dir = os.join_path(config_base, 'boulderdash')
	} $else $if windows {
		appdata := os.getenv('APPDATA')
		base := if appdata != '' { appdata } else { os.join_path(home, 'AppData', 'Roaming') }
		dir = os.join_path(base, 'boulderdash')
	}
	os.mkdir_all(dir) or {}
	return os.join_path(dir, 'save.txt')
}

pub fn load_boulder_save() BoulderSaveData {
	path := get_boulder_save_path()
	if !os.exists(path) {
		return BoulderSaveData{}
	}
	lines := os.read_lines(path) or { return BoulderSaveData{} }
	mut data := BoulderSaveData{}

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
			'high_score' { data.high_score = val.int() }
			'max_cave_unlocked' { data.max_cave_unlocked = val.int() }
			'current_cave' { data.current_cave = val.int() }
			'save_state_valid' { data.save_state_valid = val.bool() }
			'state_cave' { data.state_cave = val.int() }
			'state_score' { data.state_score = val.int() }
			'state_lives' { data.state_lives = val.int() }
			'state_diamonds_got' { data.state_diamonds_got = val.int() }
			'state_time_left' { data.state_time_left = val.f64() }
			'state_player_r' { data.state_player_r = val.int() }
			'state_player_c' { data.state_player_c = val.int() }
			else {}
		}
	}
	return data
}

pub fn save_boulder_data(data &BoulderSaveData) {
	path := get_boulder_save_path()
	mut content := 'high_score=${data.high_score}\n'
	content += 'max_cave_unlocked=${data.max_cave_unlocked}\n'
	content += 'current_cave=${data.current_cave}\n'
	content += 'save_state_valid=${data.save_state_valid}\n'
	content += 'state_cave=${data.state_cave}\n'
	content += 'state_score=${data.state_score}\n'
	content += 'state_lives=${data.state_lives}\n'
	content += 'state_diamonds_got=${data.state_diamonds_got}\n'
	content += 'state_time_left=${data.state_time_left}\n'
	content += 'state_player_r=${data.state_player_r}\n'
	content += 'state_player_c=${data.state_player_c}\n'
	for line in data.state_grid_lines {
		content += 'grid_line=${line}\n'
	}
	os.write_file(path, content) or {}
}
