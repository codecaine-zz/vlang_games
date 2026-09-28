module main

pub struct LevelDef {
pub:
	name       string
	par_pushes int
	par_steps  int
	map_data   []string
}

pub const sokoban_levels = [
	// Level 1: Warehouse Entrance (Introductory)
	LevelDef{
		name:       'Level 1: Warehouse Entrance'
		par_pushes: 6
		par_steps:  18
		map_data:   [
			'  #####',
			'###   #',
			'#   $ #',
			'# #  .#',
			'# $  .#',
			'#  @  #',
			'#######',
		]
	},
	// Level 2: Loading Dock
	LevelDef{
		name:       'Level 2: Loading Dock'
		par_pushes: 12
		par_steps:  28
		map_data:   [
			'######',
			'#    #',
			'# $$ #',
			'# .. #',
			'#  @ #',
			'######',
		]
	},
	// Level 3: Dual Corridors
	LevelDef{
		name:       'Level 3: Dual Corridors'
		par_pushes: 15
		par_steps:  35
		map_data:   [
			'  ####  ',
			'###  ###',
			'#  $ $ #',
			'# .##. #',
			'#  @   #',
			'########',
		]
	},
	// Level 4: Central Cross
	LevelDef{
		name:       'Level 4: Central Cross'
		par_pushes: 22
		par_steps:  45
		map_data:   [
			'########',
			'#   .  #',
			'# $#$# #',
			'#  . . #',
			'# #$#$ #',
			'#   @  #',
			'########',
		]
	},
	// Level 5: Cloverleaf Chamber
	LevelDef{
		name:       'Level 5: Cloverleaf'
		par_pushes: 26
		par_steps:  54
		map_data:   [
			'  ##### ',
			'###   ##',
			'#  $ $ #',
			'# #.#. #',
			'# $ @ $#',
			'# .#.# #',
			'##   ###',
			' #####  ',
		]
	},
	// Level 6: Warehouse Storage B
	LevelDef{
		name:       'Level 6: Storage Wing B'
		par_pushes: 32
		par_steps:  68
		map_data:   [
			'#######',
			'# . . #',
			'# $ $ #',
			'#  #  #',
			'# $ $ #',
			'# . . #',
			'#  @  #',
			'#######',
		]
	},
	// Level 7: The Square Maze
	LevelDef{
		name:       'Level 7: The Square'
		par_pushes: 38
		par_steps:  80
		map_data:   [
			'########',
			'#  ..  #',
			'# $$#  #',
			'#  #$$ #',
			'#  ..  #',
			'#  @   #',
			'########',
		]
	},
	// Level 8: Four Corners
	LevelDef{
		name:       'Level 8: Four Corners'
		par_pushes: 45
		par_steps:  95
		map_data:   [
			'#########',
			'#.  #  .#',
			'# $   $ #',
			'## # # ##',
			'#   @   #',
			'## # # ##',
			'# $   $ #',
			'#.  #  .#',
			'#########',
		]
	},
	// Level 9: The Spiral
	LevelDef{
		name:       'Level 9: The Spiral'
		par_pushes: 52
		par_steps:  110
		map_data:   [
			'#########',
			'#       #',
			'# ##### #',
			'# #...# #',
			'# #$$$# #',
			'# # @ # #',
			'# ##### #',
			'#       #',
			'#########',
		]
	},
	// Level 10: Master Vault
	LevelDef{
		name:       'Level 10: Master Vault'
		par_pushes: 60
		par_steps:  130
		map_data:   [
			'##########',
			'#  ....  #',
			'#  $$$$  #',
			'# ##  ## #',
			'#   @    #',
			'##########',
		]
	},
	// Level 11: Narrow Corridors
	LevelDef{
		name:       'Level 11: Narrow Path'
		par_pushes: 40
		par_steps:  85
		map_data:   [
			'######',
			'#..  #',
			'# #$##',
			'# $  #',
			'# #$##',
			'# @..#',
			'######',
		]
	},
	// Level 12: Diagonal Shift
	LevelDef{
		name:       'Level 12: Diagonal Shift'
		par_pushes: 48
		par_steps:  98
		map_data:   [
			'########',
			'#...   #',
			'#  $$$ #',
			'# ###  #',
			'#  @   #',
			'########',
		]
	},
	// Level 13: Twin Compartments
	LevelDef{
		name:       'Level 13: Twin Compartments'
		par_pushes: 50
		par_steps:  105
		map_data:   [
			'#########',
			'#..#    #',
			'#..# $$ #',
			'#  # $$ #',
			'#  #  @ #',
			'#########',
		]
	},
	// Level 14: Crossfire
	LevelDef{
		name:       'Level 14: Crossfire'
		par_pushes: 55
		par_steps:  115
		map_data:   [
			' ####### ',
			'##  .  ##',
			'#  $$$  #',
			'# ..@.. #',
			'#  $$$  #',
			'##  .  ##',
			' ####### ',
		]
	},
	// Level 15: Grand Master Finale
	LevelDef{
		name:       'Level 15: Grand Master'
		par_pushes: 75
		par_steps:  160
		map_data:   [
			' ######### ',
			'##   #   ##',
			'#  $ . $  #',
			'# $ ... $ #',
			'#  $ . $  #',
			'##   @   ##',
			' ######### ',
		]
	},
]
