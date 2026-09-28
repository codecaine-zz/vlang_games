module main

// Auto-generated 100 Cyberpunk Campaign Levels from web version
pub struct PointDef {
pub:
	x int
	y int
}

pub struct BlockDef {
pub:
	x   int
	y   int
	typ string
	dir string
}

pub struct EnemyDef {
pub:
	typ       string
	x         int
	y         int
	dir       string
	dirs      []string
	axis      string
	range_min int
	range_max int
}

pub struct LevelDef {
pub:
	id          int
	name        string
	grid_size   int
	grid        [][]int
	lolo        PointDef
	blocks      []BlockDef
	enemies     []EnemyDef
	solver_path []string
}

pub fn get_campaign_level_defs() []LevelDef {
	return [
		LevelDef{
			id: 1
			name: 'Stage 1: Training Protocol'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 0, 0, 8, 0, 0, 0, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 0, 7, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 7, y: 6, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 3, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'U', 'U', 'U', 'R', 'U', 'L', 'L', 'L', 'L', 'U', 'U', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 2
			name: 'Stage 2: Turret Crosshairs'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 0, 0, 8, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 6, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 4, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 6, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 2, y: 4, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 8, y: 7, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'U', 'U', 'L', 'L', 'L', 'U', 'L', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 3
			name: 'Stage 3: Crossfire Corridor'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 0, 0, 8, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 6, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 3, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 2, y: 4, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 8, y: 6, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 5, y: 7, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'U', 'R', 'R', 'U', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'R', 'R', 'U', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 4
			name: 'Stage 4: Diagonal Medusa-X'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 0, 0, 8, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 4, y: 6, typ: 'reflector', dir: 'up_right' }, BlockDef{ x: 7, y: 6, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'medusa_diag', x: 3, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 7, y: 7, dir: 'up', dirs: ['up'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 7, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'L', 'L', 'U', 'U', 'U', 'D', 'R', 'D', 'R', 'U', 'R', 'U', 'U', 'U', 'R', 'U', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 5
			name: 'Stage 5: Slumbering Skull'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 0, 0, 8, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 6, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 3, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 5, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'skull', x: 8, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 4, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'U', 'U', 'U', 'L', 'L', 'U', 'U', 'L', 'D', 'R', 'D', 'D', 'R', 'R', 'D', 'R', 'R', 'R', 'U', 'U', 'L', 'U', 'U', 'U', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 6
			name: 'Stage 6: Leeper Sleep Barrier'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 0, 0, 8, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 6, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 5, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 3, y: 6, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'leeper', x: 3, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 8, y: 4, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'U', 'U', 'U', 'L', 'L', 'L', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 7
			name: 'Stage 7: Gol Firestorm'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 6, 0, 8, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 4, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 5, typ: 'heavy', dir: '' }]
			enemies: [EnemyDef{ typ: 'gol', x: 3, y: 4, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 7, y: 4, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 5, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'U', 'R', 'U', 'U', 'U', 'U', 'R', 'U', 'D', 'L', 'L', 'L', 'U', 'L', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 8
			name: 'Stage 8: Don Medusa Highway'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 0, 0, 8, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 3, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'don_medusa', x: 3, y: 4, dir: 'down', dirs: [], axis: 'horizontal', range_min: 2, range_max: 4 }, EnemyDef{ typ: 'snake', x: 7, y: 7, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'L', 'S_D', 'D', 'D', 'D', 'D', 'R', 'D', 'L', 'L', 'L', 'R', 'U', 'L', 'D', 'L', 'L', 'D', 'L', 'U', 'U', 'U', 'U', 'L', 'U', 'U', 'R', 'L', 'D', 'D', 'R', 'D', 'D', 'D', 'R', 'R', 'U', 'U', 'U', 'R', 'U', 'U', 'U', 'U', 'U']
		},
		LevelDef{
			id: 9
			name: 'Stage 9: Cardinal Medusa Matrix'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 6, 0, 0, 8, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 3, y: 9 }
			blocks: [BlockDef{ x: 3, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'medusa', x: 5, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 3, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'L', 'R', 'R', 'U', 'U', 'L', 'U', 'U', 'L', 'U', 'U', 'R', 'D', 'D', 'D', 'L', 'D', 'R', 'R', 'D', 'R', 'R', 'R', 'R', 'D', 'L', 'L', 'L', 'L', 'L', 'S_U', 'U', 'U', 'U', 'L', 'U', 'R', 'R', 'U', 'R', 'R', 'U', 'R', 'R', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 10
			name: 'Stage 10: Sector 1 Apex Trial'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 6, 0, 0, 8, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 4, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 7, typ: 'reflector', dir: 'up_right' }, BlockDef{ x: 6, y: 6, typ: 'heavy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 2, y: 3, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_diag', x: 2, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 8, y: 5, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'U', 'U', 'S_U', 'U', 'U', 'R', 'U', 'L', 'U', 'D', 'L', 'L', 'L', 'L', 'U', 'L', 'L', 'L', 'D', 'D', 'R', 'R', 'R', 'R', 'D', 'D', 'D', 'R', 'D', 'L', 'L', 'D', 'L', 'L', 'U', 'D', 'R', 'R', 'U', 'U', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'U']
		},
		LevelDef{
			id: 11
			name: 'Stage 11: Mag-Lev Ice Slide'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 0, 0, 8, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 7, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 18, 18, 18, 18, 18, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 6, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 3, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 6, typ: 'ice', dir: '' }]
			enemies: [EnemyDef{ typ: 'medusa_diag', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 8, y: 4, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'U', 'L', 'L', 'U', 'U', 'R', 'R', 'U', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'R', 'U', 'R', 'U', 'U']
		},
		LevelDef{
			id: 12
			name: 'Stage 12: Dual Prism Deflections'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 0, 0, 8, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 4, y: 6, typ: 'reflector', dir: 'up_right' }, BlockDef{ x: 6, y: 6, typ: 'reflector', dir: 'up_left' }, BlockDef{ x: 5, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 5, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'D', 'D', 'D', 'D', 'U', 'U', 'U', 'U', 'R', 'U', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 13
			name: 'Stage 13: Dual Don Crossfire'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 0, 0, 8, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 7, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 6, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 3, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'don_medusa', x: 3, y: 4, dir: 'down', dirs: [], axis: 'horizontal', range_min: 2, range_max: 6 }, EnemyDef{ typ: 'snake', x: 4, y: 7, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'U', 'U', 'U', 'R', 'D', 'R', 'L', 'U', 'U', 'L', 'D', 'D', 'D', 'D', 'L', 'S_U', 'U', 'U', 'R', 'U', 'L', 'D', 'L', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'U']
		},
		LevelDef{
			id: 14
			name: 'Stage 14: Alma Buzzsaw Pursuit'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 0, 0, 8, 0, 0, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 7, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 7, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 4, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 7, typ: 'heavy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 5, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'L', 'L', 'D', 'L', 'L', 'D', 'D', 'D', 'R', 'R', 'U', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'L', 'U', 'U']
		},
		LevelDef{
			id: 15
			name: 'Stage 15: Quantum Portal Gateway'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 6, 0, 0, 8, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 3, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 6, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 2, y: 4, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa', x: 5, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 8, y: 7, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'R', 'U', 'L', 'U', 'L', 'U', 'U', 'U', 'R', 'D', 'L', 'D', 'D', 'R', 'D', 'R', 'R', 'D', 'D', 'R', 'R', 'U', 'U', 'D', 'R', 'U', 'U', 'R', 'U', 'U', 'U', 'D', 'D', 'L', 'L', 'U', 'U', 'L', 'U', 'U']
		},
		LevelDef{
			id: 16
			name: 'Stage 16: Neon Reflector Array'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 7, 0, 0, 8, 0, 0, 6, 0, 1], [1, 0, 0, 2, 0, 0, 0, 2, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 2, 0, 0, 0, 2, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 4, y: 5, typ: 'reflector', dir: 'up_right' }, BlockDef{ x: 6, y: 5, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 5, y: 7, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'D', 'D', 'L', 'D', 'D', 'L', 'L', 'L', 'L', 'L', 'D', 'D', 'U', 'U', 'L', 'U', 'U', 'U', 'U', 'R', 'D', 'D', 'L', 'D', 'D', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'U']
		},
		LevelDef{
			id: 17
			name: 'Stage 17: Gorgon Sentry Box'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 6, 0, 0, 8, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 2, 0, 2, 0, 2, 0, 2, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 3, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 6, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'medusa', x: 3, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa', x: 7, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 5, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'L', 'U', 'U', 'U', 'R', 'D', 'L', 'D', 'D', 'R', 'D', 'D', 'R', 'R', 'R', 'R', 'R', 'U', 'R', 'U', 'R', 'U', 'U', 'U', 'L', 'D', 'R', 'D', 'D', 'L', 'D', 'L', 'L', 'U', 'L', 'U', 'U', 'U', 'U', 'U']
		},
		LevelDef{
			id: 18
			name: 'Stage 18: Molten Magma Ferry'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 0, 0, 8, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 2, 20, 20, 0, 20, 20, 2, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 4, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 6, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 2, y: 3, dir: 'down', dirs: ['down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 8, y: 3, dir: 'down', dirs: ['down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 5, y: 7, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'L', 'U', 'U', 'U', 'U', 'R', 'R', 'D', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 19
			name: 'Stage 19: Sokoban Alloy Lock'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 6, 0, 0, 8, 0, 0, 7, 0, 1], [1, 0, 0, 0, 2, 0, 2, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 2, 0, 2, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 4, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 6, typ: 'heavy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 2, y: 4, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 8, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 5, y: 7, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'L', 'U', 'U', 'U', 'R', 'D', 'L', 'D', 'D', 'R', 'R', 'D', 'R', 'U', 'R', 'U', 'R', 'R', 'U', 'U', 'R', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 20
			name: 'Stage 20: Sector 2 Apex Fortress'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 6, 0, 8, 0, 7, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 4, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 5, typ: 'reflector', dir: 'up_right' }]
			enemies: [EnemyDef{ typ: 'don_medusa', x: 3, y: 4, dir: 'down', dirs: [], axis: 'horizontal', range_min: 2, range_max: 5 }, EnemyDef{ typ: 'don_medusa', x: 7, y: 6, dir: 'down', dirs: [], axis: 'horizontal', range_min: 5, range_max: 8 }, EnemyDef{ typ: 'medusa_diag', x: 2, y: 2, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 5, y: 7, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'L', 'L', 'R', 'U', 'D', 'R', 'S_U', 'U', 'L', 'U', 'R', 'D', 'R', 'D', 'R', 'L', 'U', 'L', 'U', 'U', 'R', 'U', 'U', 'U', 'R', 'L', 'D', 'D', 'D', 'L', 'D', 'L', 'U', 'R', 'U', 'R', 'U', 'L', 'L', 'U', 'L', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 21
			name: 'Stage 21: Vector Matrix Hub'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 6, 0, 0, 8, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 15, 0, 14, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 4, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 4, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 5, y: 3, dir: 'down', dirs: ['down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 8, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 5, y: 7, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'L', 'U', 'U', 'U', 'R', 'R', 'R', 'D', 'D', 'D', 'R', 'D', 'R', 'U', 'R', 'U', 'U', 'U', 'R', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 22
			name: 'Stage 22: Demolition Blast Nexus'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 6, 0, 8, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 19, 0, 0, 0, 19, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 3, y: 6, typ: 'bomb', dir: '' }, BlockDef{ x: 7, y: 6, typ: 'bomb', dir: '' }, BlockDef{ x: 5, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'gol', x: 2, y: 4, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 8, y: 4, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 5, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'S_U', 'U', 'U', 'U', 'R', 'R', 'D', 'R', 'R', 'U', 'R', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 23
			name: 'Stage 23: Moby Vortex Channel'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 0, 0, 8, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 3, 3, 3, 3, 3, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 4, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 4, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'moby', x: 2, y: 5, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 8, y: 3, dir: 'down', dirs: ['down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 5, y: 7, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'U', 'U', 'L', 'L', 'L', 'D', 'L', 'U', 'L', 'S_U', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 24
			name: 'Stage 24: Leeper Slumber Chokepoint'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 6, 0, 0, 8, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 2, 0, 0, 0, 2, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 2, 0, 2, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 5, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'medusa', x: 5, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 3, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 7, y: 6, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'D', 'D', 'D', 'D', 'D', 'D', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'D', 'D', 'D', 'D', 'D', 'R', 'D', 'R', 'R', 'U', 'R', 'R', 'D', 'R', 'U', 'U', 'U', 'U', 'R', 'U', 'L', 'L', 'L', 'U', 'L', 'U', 'U']
		},
		LevelDef{
			id: 25
			name: 'Stage 25: Sector 3 Citadel Gate'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 7, 0, 8, 0, 7, 0, 0, 1], [1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1], [1, 0, 0, 2, 0, 0, 0, 2, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 2, 0, 0, 0, 2, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 5, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 5, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'medusa', x: 5, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 4, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 8, y: 6, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 3, y: 7, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'L', 'U', 'U', 'U', 'R', 'R', 'D', 'L', 'L', 'D', 'D', 'R', 'D', 'D', 'D', 'R', 'R', 'U', 'R', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 26
			name: 'Stage 26: Slumbering Legion'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 0, 0, 8, 0, 0, 0, 0, 1], [1, 0, 6, 0, 2, 2, 2, 0, 6, 0, 1], [1, 0, 4, 0, 2, 0, 2, 0, 0, 0, 1], [1, 0, 0, 0, 2, 2, 2, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 5, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 3, y: 6, typ: 'decoy', dir: '' }, BlockDef{ x: 4, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'medusa_omni', x: 5, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 6, dir: 'down', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 7, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 3, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'D', 'L', 'D', 'D', 'L', 'L', 'L', 'D', 'D', 'L', 'L', 'U', 'L', 'U', 'U', 'U', 'U', 'R', 'U', 'R', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 27
			name: 'Stage 27: Dragon Fire Bastion'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 0, 0, 8, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 2, 2, 0, 0, 0, 2, 2, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 7, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 4, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 5, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 5, y: 5, dir: 'down', dirs: ['up', 'down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 3, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 8, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa', x: 4, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'U', 'U', 'L', 'U', 'U', 'U', 'R', 'L', 'D', 'D', 'D', 'R', 'R', 'S_D', 'D', 'R', 'D', 'L', 'L', 'L', 'L', 'D', 'L', 'U', 'U', 'L', 'U', 'L', 'L', 'U', 'U', 'R', 'R', 'U', 'S_L', 'U', 'L', 'D', 'L', 'D', 'R', 'R', 'U', 'R', 'R', 'U', 'U', 'U']
		},
		LevelDef{
			id: 28
			name: 'Stage 28: Heavy Freight Depot'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 6, 0, 0, 8, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 3, 3, 3, 0, 3, 3, 3, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 3, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 2, y: 3, dir: 'down', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 8, y: 3, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 8, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 8, y: 5, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'S_U', 'U', 'L', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'D', 'R', 'R', 'U', 'R', 'R', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 29
			name: 'Stage 29: Tri-Medusa Lock'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 0, 0, 8, 5, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 6, 0, 0, 1], [1, 0, 2, 2, 0, 0, 0, 2, 2, 0, 1], [1, 0, 0, 4, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 2, 0, 2, 4, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 4, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 3, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 5, y: 4, dir: 'down', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 7, dir: 'down', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 8, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 4, y: 5, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 30
			name: 'Stage 30: Sector 3 Grand Vault'
			grid_size: 11
			grid: [[1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1], [1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1], [1, 0, 0, 0, 4, 8, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 1], [1, 0, 3, 3, 3, 3, 3, 3, 3, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 5, y: 9 }
			blocks: [BlockDef{ x: 5, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 6, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 8, y: 6, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 5, y: 3, dir: 'down', dirs: ['down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 8, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 7, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'L', 'U', 'U', 'U', 'R', 'L', 'D', 'D', 'D', 'R', 'R', 'R', 'R', 'D', 'R', 'R', 'D', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'L', 'U', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 31
			name: 'Stage 31: Warp Resonance Alpha'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 1], [1, 0, 2, 2, 0, 0, 0, 0, 0, 2, 2, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 7, 0, 0, 1], [1, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 6, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 4, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 6, y: 6, dir: 'down', dirs: ['up', 'down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 3, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 10, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 3, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 2, y: 2, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'R', 'U', 'U', 'U', 'U', 'L', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 32
			name: 'Stage 32: Sub-Zero Flotilla'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 5, 0, 0, 0, 8, 0, 4, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 7, 0, 0, 1], [1, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 4, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 4, typ: 'heavy', dir: '' }, BlockDef{ x: 7, y: 4, typ: 'magnetic', dir: '' }, BlockDef{ x: 5, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 6, y: 5, dir: 'down', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 7, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 10, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 8, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 3, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 4, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'S_U', 'U', 'L', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 33
			name: 'Stage 33: Sticky Nanite Trench'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 5, 8, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 5, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 7, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 4, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 4, typ: 'heavy', dir: '' }, BlockDef{ x: 7, y: 4, typ: 'magnetic', dir: '' }, BlockDef{ x: 8, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 6, y: 5, dir: 'down', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 7, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 10, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 9, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 7, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 8, y: 3, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'R', 'U', 'L', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'U', 'R', 'R', 'D', 'U', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 34
			name: 'Stage 34: Omni-Star Ambush'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 6, 0, 4, 0, 8, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 5, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 4, y: 6, typ: 'reflector', dir: 'up_right' }, BlockDef{ x: 8, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 3, y: 8, typ: 'heavy', dir: '' }, BlockDef{ x: 6, y: 8, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 6, y: 5, dir: 'down', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 9, dir: 'down', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 10, y: 9, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 2, y: 8, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 5, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 4, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'R', 'R', 'R', 'S_D', 'R', 'R', 'R', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'R', 'L', 'L', 'L', 'D', 'L', 'L', 'U', 'L', 'L', 'L', 'R', 'R', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 35
			name: 'Stage 35: Hydraulic Colosseum'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 8, 0, 5, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 4, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 5, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 1], [1, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 5, y: 4, typ: 'reflector', dir: 'down_right' }, BlockDef{ x: 7, y: 4, typ: 'reflector', dir: 'down_left' }, BlockDef{ x: 6, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 4, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 2, y: 4, dir: 'down', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 10, y: 4, dir: 'down', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 10, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 8, y: 8, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 3, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 3, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'L', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'L', 'L', 'U', 'L', 'S_U', 'U', 'U', 'U', 'U', 'L', 'U', 'U', 'L', 'U', 'U', 'U']
		},
		LevelDef{
			id: 36
			name: 'Stage 36: Phasing Wisp Crypt'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 2, 2, 0, 6, 0, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 3, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 6, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 10, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 3, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 6, y: 3, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 7, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'L', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'D', 'R', 'R', 'R', 'U', 'R', 'U', 'U', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 37
			name: 'Stage 37: High-Grass Stealth Run'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 8, 4, 0, 0, 0, 0, 1], [1, 0, 0, 6, 5, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 15, 15, 0, 0, 0, 0, 0, 14, 14, 0, 1], [1, 0, 0, 5, 0, 4, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 5, 7, 0, 0, 0, 0, 0, 6, 4, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 6, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 6, y: 5, dir: 'down', dirs: ['up', 'down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 2, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 10, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 10, y: 8, dir: 'down', dirs: [], axis: 'horizontal', range_min: 8, range_max: 10 }, EnemyDef{ typ: 'gol', x: 9, y: 7, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 5, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'D', 'D', 'D', 'S_D', 'D', 'L', 'D', 'D', 'D', 'R', 'U', 'L', 'U', 'U', 'U', 'L', 'U', 'U', 'U', 'L', 'U', 'U', 'U']
		},
		LevelDef{
			id: 38
			name: 'Stage 38: Fragile Barrier Vault'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 8, 0, 0, 5, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 5, 0, 0, 0, 0, 0, 5, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 4, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 4, y: 5, typ: 'magnetic', dir: '' }, BlockDef{ x: 8, y: 5, typ: 'magnetic', dir: '' }, BlockDef{ x: 6, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 8, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 6, y: 3, dir: 'down', dirs: ['down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 2, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 10, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 8, y: 8, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 4, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 6, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'D', 'D', 'L', 'L', 'U', 'L', 'L', 'U', 'L', 'D', 'D', 'D', 'D', 'D', 'L', 'D', 'D', 'R', 'R', 'U', 'U', 'U', 'U', 'R', 'U', 'U', 'R', 'U', 'U', 'R', 'U', 'U']
		},
		LevelDef{
			id: 39
			name: 'Stage 39: Dual Vortex Canals'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 5, 5, 8, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 2, 0, 4, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 2, 5, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 7, 2, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 3, y: 4, typ: 'fragile', dir: '' }, BlockDef{ x: 3, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'gol', x: 2, y: 4, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 10, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 6, y: 8, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 3, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 4, y: 9, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['L', 'L', 'L', 'U', 'U', 'L', 'R', 'U', 'R', 'R', 'D', 'R', 'R', 'R', 'R', 'R', 'U', 'U', 'L', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 40
			name: 'Stage 40: Sector 4 Apex Core'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 1], [1, 0, 18, 18, 18, 18, 18, 0, 18, 18, 18, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 3, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 3, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 8, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'down', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 10, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 6, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 9, y: 4, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 6, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'L', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 41
			name: 'Stage 41: Concentric Ring Defense'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 8, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 18, 18, 18, 18, 0, 0, 0, 0, 3, 0, 1], [1, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 1], [1, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 4, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 3, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 8, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'down', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 10, y: 7, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 10, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 5, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 7, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 6, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'L', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'D', 'R', 'R', 'U', 'R', 'R', 'R', 'L', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 42
			name: 'Stage 42: Magma Stepping Stones'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 5, 0, 8, 0, 0, 0, 0, 0, 1], [1, 0, 6, 4, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 5, 0, 0, 0, 0, 5, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 4, y: 4, typ: 'decoy', dir: '' }, BlockDef{ x: 6, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 3, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'hopper', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 6, y: 3, dir: 'down', dirs: ['down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 10, y: 9, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 3, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 9, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'L', 'L', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'D', 'D', 'R', 'R', 'U', 'U', 'R', 'R', 'U', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 43
			name: 'Stage 43: Sawblade Alleyways'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 7, 5, 0, 2, 0, 6, 0, 0, 1], [1, 0, 19, 5, 0, 0, 0, 0, 0, 4, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 5, 0, 0, 0, 0, 0, 4, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 10, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 8, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'gol', x: 2, y: 3, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 10, y: 4, dir: 'down', dirs: ['down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 6, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 5, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 2, y: 2, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 7, y: 2, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'D', 'R', 'R', 'U', 'R', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'R', 'L', 'L', 'L', 'L', 'L', 'U', 'S_U', 'U', 'U', 'U', 'U', 'U', 'R', 'U', 'U', 'U', 'U']
		},
		LevelDef{
			id: 44
			name: 'Stage 44: Striker Sniper Roost'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 2, 4, 0, 0, 2, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 6, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 8, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'skull', x: 2, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 10, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 5, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 7, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 6, y: 3, dir: 'down', dirs: ['down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 5, y: 4, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 5, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 8, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'D', 'D', 'D', 'R', 'R', 'U', 'R', 'R', 'U', 'U', 'R', 'R', 'U', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 45
			name: 'Stage 45: Quadrant Reactor Beta'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 5, 0, 6, 0, 0, 1], [1, 0, 0, 2, 0, 0, 0, 0, 0, 0, 4, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 4, 0, 0, 5, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 4, y: 4, typ: 'decoy', dir: '' }, BlockDef{ x: 6, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 8, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 5, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'hopper', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 6, y: 3, dir: 'down', dirs: ['down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 10, y: 9, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 3, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 5, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 8, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'L', 'U', 'S_U', 'U', 'U', 'R', 'R', 'R', 'D', 'D', 'R', 'D', 'R', 'U', 'U', 'U', 'R', 'R', 'L', 'L', 'D', 'D', 'L', 'L', 'U', 'U', 'U', 'R', 'U', 'U']
		},
		LevelDef{
			id: 46
			name: 'Stage 46: Permafrost Gauntlet'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 5, 8, 0, 0, 0, 0, 0, 1], [1, 0, 16, 6, 5, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 2, 0, 0, 0, 0, 0, 17, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 4, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 3, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 5, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'down', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 10, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 7, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 6, y: 6, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 4, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'R', 'U', 'U', 'U', 'L', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 47
			name: 'Stage 47: Decoy Infiltration'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 8, 5, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 5, 0, 4, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 4, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 2, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 9, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 6, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'alma', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 10, y: 5, dir: 'down', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 4, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 5, y: 4, dir: 'down', dirs: [], axis: 'horizontal', range_min: 3, range_max: 7 }, EnemyDef{ typ: 'gol', x: 7, y: 4, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'R', 'U', 'U', 'U', 'L', 'D', 'R', 'D', 'D', 'L', 'L', 'L', 'L', 'D', 'L', 'L', 'D', 'D', 'D', 'L', 'L', 'U', 'U', 'R', 'U', 'L', 'L', 'U', 'U', 'L', 'U', 'R', 'S_U', 'U', 'R', 'L', 'D', 'D', 'D', 'D', 'R', 'R', 'R', 'R', 'U', 'R', 'U', 'R', 'U', 'S_L', 'L', 'U', 'U', 'L', 'U', 'U']
		},
		LevelDef{
			id: 48
			name: 'Stage 48: Magnetic Conduit Run'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 5, 0, 0, 8, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 2, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 15, 15, 0, 0, 0, 0, 0, 14, 14, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 6, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 8, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 6, y: 5, dir: 'down', dirs: ['up', 'down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 2, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 7, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 7, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 8, y: 8, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 8, y: 2, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'D', 'L', 'L', 'U', 'L', 'L', 'L', 'L', 'L', 'D', 'D', 'D', 'D', 'D', 'R', 'D', 'D', 'L', 'R', 'U', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 49
			name: 'Stage 49: Sentry Overload'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 5, 8, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1], [1, 0, 19, 0, 0, 0, 0, 0, 0, 0, 19, 0, 1], [1, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 3, y: 5, typ: 'bomb', dir: '' }, BlockDef{ x: 9, y: 5, typ: 'fragile', dir: '' }, BlockDef{ x: 5, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 5, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 6, y: 5, dir: 'down', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 10, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 10, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 4, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 6, y: 6, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 5, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'R', 'S_U', 'U', 'U', 'U', 'L', 'R', 'S_R', 'R', 'R', 'R', 'U', 'R', 'D', 'R', 'U', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 50
			name: 'Stage 50: Sector 5 Apex Citadel'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 8, 0, 0, 5, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 7, 0, 0, 1], [1, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 4, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 4, typ: 'heavy', dir: '' }, BlockDef{ x: 7, y: 4, typ: 'magnetic', dir: '' }, BlockDef{ x: 6, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 3, y: 2, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 6, y: 5, dir: 'down', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 7, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 10, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 4, y: 8, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 7, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 2, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 4, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'R', 'U', 'L', 'U', 'U', 'U', 'D', 'D', 'D', 'R', 'R', 'R', 'D', 'R', 'U', 'R', 'U', 'R', 'U', 'U', 'U', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 51
			name: 'Stage 51: Plasma Hydro-Locks'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 2, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 9, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 9, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 8, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'alma', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 10, y: 5, dir: 'down', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 9, y: 2, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 5, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 6, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 9, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'L', 'L', 'L', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'R', 'U', 'U', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'R', 'R', 'S_R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 52
			name: 'Stage 52: Chasm Bridge Crossings'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 8, 0, 0, 4, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 4, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 2, 2, 0, 0, 0, 0, 0, 2, 2, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 5, 0, 0, 0, 7, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 6, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 8, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 6, y: 6, dir: 'down', dirs: ['up', 'down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 3, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 10, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 2, y: 5, dir: 'down', dirs: [], axis: 'horizontal', range_min: 2, range_max: 4 }, EnemyDef{ typ: 'gol', x: 2, y: 7, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 3, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 4, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'R', 'R', 'U', 'U', 'U', 'U', 'L', 'U', 'L', 'U', 'U', 'R', 'R', 'D', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 53
			name: 'Stage 53: Leeper Minefield II'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 2, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 2, 2, 0, 0, 0, 0, 0, 2, 2, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 4, 7, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 6, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 6, y: 6, dir: 'down', dirs: ['up', 'down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 3, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 10, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 7, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 9, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 10, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 4, y: 2, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'R', 'U', 'U', 'U', 'L', 'U', 'D', 'R', 'R', 'R', 'R', 'R', 'U', 'R', 'U', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 54
			name: 'Stage 54: Heavy Push Logistics'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 5, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 3, y: 4, typ: 'fragile', dir: '' }, BlockDef{ x: 8, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 9, y: 8, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 6, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'gol', x: 2, y: 4, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 10, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 6, y: 8, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 10, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 10, y: 3, dir: 'down', dirs: [], axis: 'horizontal', range_min: 8, range_max: 10 }, EnemyDef{ typ: 'leeper', x: 10, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 8, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'L', 'L', 'L', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'L', 'U', 'L', 'L', 'U', 'U', 'U', 'U', 'L', 'U', 'U', 'D', 'R', 'U', 'L', 'U', 'U']
		},
		LevelDef{
			id: 55
			name: 'Stage 55: Prismatic Laser Net'
			grid_size: 13
			grid: [[1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 4, 5, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 5, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 6, y: 11 }
			blocks: [BlockDef{ x: 5, y: 4, typ: 'sticky', dir: '' }, BlockDef{ x: 7, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 9, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 9, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'leeper', x: 2, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 10, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 6, y: 4, dir: 'down', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 6, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 10, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 8, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 4, y: 7, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 10, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 56
			name: 'Stage 56: Lava Archipelago'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 18, 18, 18, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 4, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 4, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 3, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 10, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 8, typ: 'alloy', dir: '' }, BlockDef{ x: 3, y: 11, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'hopper', x: 12, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 7, y: 10, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 4, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 6, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 4, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 9, y: 4, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'U', 'R', 'D', 'R', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 57
			name: 'Stage 57: Sleep Walker Trench'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 5, 0, 0, 6, 0, 1], [1, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 5, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 6, y: 6, typ: 'holo', dir: '' }, BlockDef{ x: 8, y: 6, typ: 'decoy', dir: '' }, BlockDef{ x: 6, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 11, y: 8, typ: 'alloy', dir: '' }, BlockDef{ x: 11, y: 6, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 7, y: 6, dir: 'down', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 12, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 4, y: 9, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 12, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 12, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 10, y: 10, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 12, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'L', 'L', 'L', 'L', 'U', 'U', 'R', 'S_U', 'U', 'U', 'U', 'L', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 58
			name: 'Stage 58: Dual Don Highway II'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 2, 0, 0, 0, 0, 4, 0, 0, 5, 0, 1], [1, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 1], [1, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 3, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 11, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 4, typ: 'reflector', dir: 'up_right' }, BlockDef{ x: 6, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 11, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 8, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'striker', x: 2, y: 6, dir: 'right', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 12, y: 6, dir: 'left', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 7, y: 3, dir: 'down', dirs: ['down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 7, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 4, y: 8, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 12, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 3, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 11, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 4, y: 4, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'R', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'S_U', 'U', 'U', 'R', 'U', 'L', 'U', 'D', 'R', 'S_R', 'R', 'R', 'D', 'R', 'R', 'R', 'U', 'U', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 59
			name: 'Stage 59: Thermal Cascade'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 5, 0, 8, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 4, 0, 0, 0, 0, 5, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 5, y: 7, typ: 'reflector', dir: 'up_right' }, BlockDef{ x: 9, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 3, y: 10, typ: 'heavy', dir: '' }, BlockDef{ x: 9, y: 11, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 4, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 7, y: 6, dir: 'down', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 11, dir: 'down', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 12, y: 11, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 10, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 11, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 5, y: 3, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 12, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'R', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'S_U', 'U', 'U', 'U', 'U', 'U', 'R', 'U', 'U', 'S_U', 'U', 'U', 'U', 'R', 'L', 'L', 'L', 'L', 'D', 'L', 'L', 'U', 'L', 'L', 'L', 'L', 'R', 'R', 'R', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 60
			name: 'Stage 60: Sector 6 Apex Spire'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 8, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 1], [1, 0, 0, 0, 0, 5, 4, 0, 0, 0, 0, 4, 0, 0, 1], [1, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 5, y: 7, typ: 'reflector', dir: 'up_right' }, BlockDef{ x: 9, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 3, y: 10, typ: 'heavy', dir: '' }, BlockDef{ x: 5, y: 2, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 7, y: 6, dir: 'down', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 11, dir: 'down', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 12, y: 11, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 4, y: 2, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 8, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 8, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 10, y: 5, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 9, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'R', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'L', 'L', 'L', 'L', 'D', 'L', 'L', 'L', 'L', 'L', 'U', 'L', 'R', 'U', 'R', 'R', 'D', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 61
			name: 'Stage 61: Orbital Patrol Circuit'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 2, 0, 0, 0, 5, 4, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 2, 0, 2, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 4, 0, 5, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 6, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 3, y: 11, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 8, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 10, typ: 'alloy', dir: '' }, BlockDef{ x: 11, y: 9, typ: 'alloy', dir: '' }, BlockDef{ x: 3, y: 2, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 7, y: 6, dir: 'down', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 11, dir: 'down', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 12, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 3, y: 10, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 11, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 12, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 2, y: 2, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 5, y: 3, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'U', 'R', 'R', 'R', 'D', 'R', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 62
			name: 'Stage 62: Buzzsaw Labyrinth'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 4, 0, 2, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 3, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 2, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 3, y: 9, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 2, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 2, y: 6, dir: 'down', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 12, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 7, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 3, y: 2, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 9, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 11, y: 2, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 7, y: 9, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'D', 'L', 'L', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'D', 'D', 'L', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'R', 'U', 'U', 'R', 'U', 'U', 'R', 'U', 'U', 'U', 'U', 'R', 'R', 'U', 'R', 'U', 'U']
		},
		LevelDef{
			id: 63
			name: 'Stage 63: Magnetic Accelerator'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 4, y: 4, typ: 'decoy', dir: '' }, BlockDef{ x: 7, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 9, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'hopper', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 7, y: 3, dir: 'down', dirs: ['down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 12, y: 11, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 9, y: 2, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 9, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 8, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 11, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 6, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'D', 'D', 'R', 'R', 'U', 'U', 'R', 'R', 'R', 'L', 'L', 'S_U', 'U', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 64
			name: 'Stage 64: Frostbite Sockets'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 16, 6, 4, 5, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 2, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 3, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 9, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 8, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 2, y: 6, dir: 'down', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 12, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 4, y: 11, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 3, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 9, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 12, y: 9, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 8, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 65
			name: 'Stage 65: Dragon Siege Bastion'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 2, 2, 2, 0, 4, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 2, 0, 2, 0, 0, 0, 0, 0, 1], [1, 0, 5, 0, 0, 0, 2, 2, 2, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 3, y: 8, typ: 'decoy', dir: '' }, BlockDef{ x: 8, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 8, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 8, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'medusa_omni', x: 7, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 8, dir: 'down', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 11, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 6, y: 2, dir: 'down', dirs: [], axis: 'horizontal', range_min: 4, range_max: 8 }, EnemyDef{ typ: 'gol', x: 10, y: 6, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 11, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 11, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 9, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'L', 'S_D', 'D', 'D', 'D', 'D', 'D', 'L', 'L', 'L', 'D', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'D', 'D', 'D', 'D', 'R', 'D', 'D', 'D', 'D', 'D', 'L', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 66
			name: 'Stage 66: Quantum Crossroads'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 5, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1], [1, 0, 2, 2, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 7, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 11, y: 6, typ: 'magnetic', dir: '' }, BlockDef{ x: 8, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 2, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 11, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'don_medusa', x: 2, y: 5, dir: 'down', dirs: [], axis: 'horizontal', range_min: 2, range_max: 6 }, EnemyDef{ typ: 'turret', x: 12, y: 6, dir: 'down', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 5, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 6, y: 9, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 5, y: 2, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 6, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 8, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 12, y: 7, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'L', 'U', 'U', 'U', 'R', 'U', 'D', 'D', 'L', 'D', 'L', 'L', 'D', 'D', 'D', 'R', 'D', 'L', 'L', 'L', 'L', 'D', 'D', 'L', 'L', 'L', 'U', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'R', 'U', 'U', 'U', 'R', 'R', 'U', 'U', 'U']
		},
		LevelDef{
			id: 67
			name: 'Stage 67: Hopper Jumping Chasm'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 8, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 4, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 5, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 6, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 7, typ: 'decoy', dir: '' }, BlockDef{ x: 9, y: 9, typ: 'alloy', dir: '' }, BlockDef{ x: 11, y: 10, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 5, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'rocky', x: 2, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 12, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 7, y: 3, dir: 'down', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 11, y: 11, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 12, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 5, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 5, y: 3, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 10, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'D', 'D', 'D', 'D', 'R', 'R', 'R', 'U', 'R', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'L', 'L', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 68
			name: 'Stage 68: Bioweed Cover Grid'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 5, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 2, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 0, 4, 5, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 11, y: 6, typ: 'holo', dir: '' }, BlockDef{ x: 5, y: 11, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 2, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'medusa', x: 5, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 12, y: 6, dir: 'down', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 4, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 8, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 11, y: 2, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 2, y: 6, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 4, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'L', 'L', 'U', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 69
			name: 'Stage 69: Superheated Magma Core'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 1], [1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 15, 15, 0, 0, 0, 0, 0, 0, 0, 14, 14, 0, 1], [1, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 7, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 10, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 11, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 7, y: 6, dir: 'down', dirs: ['up', 'down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 7, y: 9, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 7, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 6, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 9, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 6, y: 4, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 70
			name: 'Stage 70: Sector 7 Apex Terminal'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 1], [1, 0, 0, 5, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1], [1, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 7, 5, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 7, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 10, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 9, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 8, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 12, y: 8, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 7, y: 3, dir: 'down', dirs: ['down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 12, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 3, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 6, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 4, y: 9, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 9, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 8, y: 8, dir: 'right', dirs: ['up', 'up_right', 'right', 'down_right', 'down', 'down_left', 'left', 'up_left'], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'L', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'D', 'D', 'R', 'R', 'U', 'U', 'R', 'R', 'R', 'D', 'D', 'D', 'R', 'R', 'D', 'D', 'D', 'D', 'D', 'S_L', 'L', 'D', 'L', 'R', 'U', 'U', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 71
			name: 'Stage 71: Quad-Quadrant Reactor'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 5, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 2, 0, 2, 0, 0, 0, 5, 0, 0, 0, 1], [1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 11, y: 6, typ: 'holo', dir: '' }, BlockDef{ x: 7, y: 11, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 9, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 8, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'medusa', x: 5, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 12, y: 6, dir: 'down', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 6, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 8, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 4, y: 3, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 6, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 5, y: 8, dir: 'right', dirs: ['up', 'up_right', 'right', 'down_right', 'down', 'down_left', 'left', 'up_left'], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'R', 'U', 'U', 'U', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'L', 'L', 'D', 'U', 'R', 'R', 'D', 'D', 'R', 'D', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'D', 'D', 'D', 'D', 'D', 'D', 'L', 'L', 'L', 'L', 'L', 'U', 'L', 'D', 'R', 'D', 'L', 'L', 'D', 'L', 'U', 'L', 'L', 'R', 'R', 'R', 'R', 'U', 'U', 'R', 'S_U', 'U', 'U', 'U', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'U']
		},
		LevelDef{
			id: 72
			name: 'Stage 72: Twin Island Chasm'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 5, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 4, 0, 0, 0, 2, 0, 2, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 4, 0, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 6, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 3, y: 11, typ: 'alloy', dir: '' }, BlockDef{ x: 11, y: 11, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 10, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 3, y: 4, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 7, y: 6, dir: 'down', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 11, dir: 'down', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 12, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 8, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 4, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 3, y: 10, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 73
			name: 'Stage 73: Overgrown Hedge Maze'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 5, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 5, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 1], [1, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 1], [1, 0, 0, 0, 0, 0, 2, 0, 2, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 6, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 3, y: 11, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 9, typ: 'alloy', dir: '' }, BlockDef{ x: 9, y: 11, typ: 'alloy', dir: '' }, BlockDef{ x: 9, y: 2, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 7, y: 6, dir: 'down', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 11, dir: 'down', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 6, y: 9, dir: 'down', dirs: [], axis: 'horizontal', range_min: 4, range_max: 8 }, EnemyDef{ typ: 'gol', x: 7, y: 9, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 4, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 10, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 10, y: 2, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'R', 'U', 'U', 'U', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'D', 'D', 'L', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'R', 'R', 'R', 'U', 'U', 'S_U', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'U', 'U', 'U', 'R', 'U', 'U']
		},
		LevelDef{
			id: 74
			name: 'Stage 74: Sticky Nanite Funnel'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 8, 0, 4, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 19, 0, 5, 5, 0, 0, 0, 0, 0, 0, 19, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 3, y: 6, typ: 'bomb', dir: '' }, BlockDef{ x: 11, y: 6, typ: 'fragile', dir: '' }, BlockDef{ x: 6, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 8, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 7, y: 6, dir: 'down', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 12, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 11, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 4, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 2, y: 10, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 6, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 11, y: 7, dir: 'right', dirs: ['up', 'up_right', 'right', 'down_right', 'down', 'down_left', 'left', 'up_left'], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 75
			name: 'Stage 75: Demolition Nexus'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 5, 0, 0, 0, 4, 0, 0, 5, 0, 1], [1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 6, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 2, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 7, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 7, y: 6, dir: 'down', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 12, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 6, y: 7, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 4, y: 2, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 3, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 3, y: 11, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 8, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'R', 'R', 'U', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 76
			name: 'Stage 76: Prism Laser Fortress'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 5, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 4, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 5, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 3, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 11, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 4, typ: 'reflector', dir: 'up_right' }, BlockDef{ x: 6, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 11, y: 8, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'striker', x: 2, y: 6, dir: 'right', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 12, y: 6, dir: 'left', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 7, y: 3, dir: 'down', dirs: ['down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 7, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 4, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 6, y: 2, dir: 'down', dirs: [], axis: 'horizontal', range_min: 4, range_max: 8 }, EnemyDef{ typ: 'gol', x: 3, y: 4, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 7, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 12, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'L', 'U', 'U', 'U', 'U', 'U', 'R', 'L', 'L', 'L', 'D', 'D', 'D', 'L', 'D', 'L', 'L', 'D', 'L', 'D', 'L', 'L', 'D', 'D', 'D', 'U', 'U', 'U', 'U', 'U', 'S_U', 'U', 'L', 'U', 'U', 'U', 'R', 'D', 'L', 'D', 'R', 'D', 'R', 'D', 'R', 'R', 'U', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'L', 'U', 'U']
		},
		LevelDef{
			id: 77
			name: 'Stage 77: Fluvial Bio-Delta'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 0, 2, 6, 0, 0, 1], [1, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 5, 0, 1], [1, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 4, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 1], [1, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 1], [1, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 7, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 8, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 2, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 7, y: 7, dir: 'down', dirs: ['up', 'down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 3, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 12, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 8, y: 2, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 4, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 3, y: 2, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 7, y: 5, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 10, y: 2, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'R', 'S_U', 'U', 'U', 'U', 'U', 'L', 'U', 'R', 'D', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'D', 'L', 'L', 'L', 'U', 'L', 'U', 'U', 'U']
		},
		LevelDef{
			id: 78
			name: 'Stage 78: Gorgon Colonnade II'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 3, y: 4, typ: 'fragile', dir: '' }, BlockDef{ x: 8, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 9, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 6, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 11, y: 4, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'gol', x: 2, y: 4, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 12, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 7, y: 10, dir: 'up', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 10, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 11, y: 3, dir: 'down', dirs: [], axis: 'horizontal', range_min: 9, range_max: 12 }, EnemyDef{ typ: 'leeper', x: 7, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 12, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 8, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'L', 'L', 'L', 'L', 'U', 'L', 'R', 'R', 'R', 'R', 'U', 'S_R', 'R', 'R', 'R', 'D', 'R', 'R', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 79
			name: 'Stage 79: Moby Whirlpool Apex'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 5, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 5, 0, 0, 0, 0, 4, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 3, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 11, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 7, y: 4, typ: 'reflector', dir: 'up_right' }, BlockDef{ x: 7, y: 7, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 9, typ: 'alloy', dir: '' }, BlockDef{ x: 3, y: 9, typ: 'alloy', dir: '' }, BlockDef{ x: 9, y: 10, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 4, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'striker', x: 2, y: 6, dir: 'right', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 12, y: 6, dir: 'left', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 7, y: 3, dir: 'down', dirs: ['down'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 7, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 9, y: 5, dir: 'down', dirs: [], axis: 'horizontal', range_min: 7, range_max: 11 }, EnemyDef{ typ: 'gol', x: 12, y: 11, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 10, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 3, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'L', 'L', 'L', 'L', 'R', 'R', 'R', 'U', 'S_R', 'R', 'D', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'R', 'S_U', 'U', 'U', 'R', 'U', 'L', 'U', 'L', 'D', 'R', 'D', 'D', 'L', 'D', 'D', 'D', 'D', 'D', 'L', 'L', 'D', 'L', 'U', 'L', 'U', 'U', 'U', 'U', 'U', 'L', 'U', 'L', 'L', 'L', 'L', 'U', 'U', 'R', 'U', 'R', 'R', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 80
			name: 'Stage 80: Sector 8 Apex Citadel'
			grid_size: 15
			grid: [[1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 2, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 5, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 7, y: 13 }
			blocks: [BlockDef{ x: 6, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 8, y: 6, typ: 'alloy', dir: '' }, BlockDef{ x: 4, y: 5, typ: 'alloy', dir: '' }, BlockDef{ x: 3, y: 2, typ: 'alloy', dir: '' }, BlockDef{ x: 5, y: 6, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'turret', x: 7, y: 6, dir: 'down', dirs: ['left', 'right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 12, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'gol', x: 2, y: 7, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 2, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 4, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 10, y: 4, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 4, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 81
			name: 'Stage 81: Omni-Medusa Crosshairs'
			grid_size: 17
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 8, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 7, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 0, 7, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 17, 0, 1], [1, 0, 0, 1, 0, 6, 0, 0, 0, 0, 15, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 8, y: 15 }
			blocks: [BlockDef{ x: 6, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 8, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa', x: 14, y: 12, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_diag', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 14, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 2, y: 12, dir: 'down', dirs: [], axis: 'vertical', range_min: 9, range_max: 12 }, EnemyDef{ typ: 'gol', x: 14, y: 5, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 14, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 5, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 14, y: 4, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 14, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 11, y: 10, dir: 'up', dirs: ['up'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'wisp', x: 2, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'orbiter', x: 14, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'U', 'U', 'L', 'L', 'U', 'U', 'L', 'L', 'U', 'U', 'L', 'L', 'D', 'D', 'D', 'R', 'D', 'L', 'D', 'D', 'L', 'L', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'U', 'U', 'U', 'U', 'R', 'U', 'R', 'U', 'R', 'R', 'L', 'L', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'S_R', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'R', 'U', 'L', 'L', 'L', 'U', 'L', 'L', 'D', 'U', 'R', 'R', 'D', 'R', 'R', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 82
			name: 'Stage 82: Magma Island Gauntlet'
			grid_size: 17
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 8, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 1, 0, 0, 1], [1, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 6, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 7, 0, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 15, 0, 7, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 2, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 8, y: 15 }
			blocks: [BlockDef{ x: 6, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 8, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa', x: 14, y: 12, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_diag', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 14, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 2, y: 12, dir: 'down', dirs: [], axis: 'vertical', range_min: 9, range_max: 12 }, EnemyDef{ typ: 'gol', x: 14, y: 5, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 14, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 5, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 14, y: 4, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 14, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 11, y: 10, dir: 'up', dirs: ['up'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'wisp', x: 2, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'orbiter', x: 14, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'R', 'R', 'D', 'D', 'L', 'R', 'R', 'R', 'U', 'U', 'U', 'R', 'R', 'U', 'L', 'U', 'R', 'U', 'R', 'R', 'L', 'L', 'L', 'D', 'L', 'L', 'L', 'L', 'D', 'L', 'U', 'R', 'U', 'L', 'U', 'L', 'L', 'D', 'U', 'R', 'R', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'L', 'D', 'L', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U']
		},
		LevelDef{
			id: 83
			name: 'Stage 83: Heavy Alloy Matrix'
			grid_size: 17
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 8, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 16, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 0, 7, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 7, 17, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 6, 0, 0, 0, 15, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 8, y: 15 }
			blocks: [BlockDef{ x: 6, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 8, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa', x: 14, y: 12, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_diag', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 14, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 2, y: 12, dir: 'down', dirs: [], axis: 'vertical', range_min: 9, range_max: 12 }, EnemyDef{ typ: 'gol', x: 14, y: 5, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 14, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 5, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 14, y: 4, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 14, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'wisp', x: 2, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'orbiter', x: 14, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'L', 'U', 'R', 'D', 'D', 'R', 'R', 'D', 'D', 'D', 'L', 'L', 'D', 'L', 'D', 'D', 'L', 'L', 'L', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'R', 'U', 'U', 'U', 'R', 'U', 'R', 'R', 'R', 'U', 'R', 'R', 'R', 'L', 'L', 'L', 'D', 'L', 'L', 'U', 'L', 'L', 'L', 'U', 'L', 'L', 'D', 'U', 'R', 'R', 'D', 'R', 'R', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 84
			name: 'Stage 84: Sub-Space Singularity'
			grid_size: 17
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 8, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 6, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 7, 0, 1, 0, 0, 1], [1, 0, 0, 7, 0, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 17, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 15, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 2, 0, 6, 0, 0, 0, 0, 0, 7, 0, 0, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 8, y: 15 }
			blocks: [BlockDef{ x: 6, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 8, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa', x: 14, y: 12, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_diag', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 14, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 2, y: 12, dir: 'down', dirs: [], axis: 'vertical', range_min: 9, range_max: 12 }, EnemyDef{ typ: 'gol', x: 14, y: 5, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 14, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 5, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 14, y: 4, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 14, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 11, y: 10, dir: 'up', dirs: ['up'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'wisp', x: 2, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'orbiter', x: 14, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'U', 'D', 'R', 'R', 'U', 'U', 'U', 'U', 'S_L', 'L', 'U', 'U', 'L', 'R', 'U', 'U', 'L', 'L', 'L', 'L', 'L', 'D', 'L', 'D', 'L', 'L', 'R', 'D', 'D', 'D', 'D', 'D', 'D', 'L', 'L', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'R', 'U', 'R', 'R', 'R', 'L', 'L', 'L', 'D', 'L', 'L', 'L', 'L', 'D', 'L', 'U', 'R', 'U', 'L', 'U', 'L', 'L', 'D', 'U', 'R', 'R', 'D', 'R', 'R', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 85
			name: 'Stage 85: High-Grass Stalker Den'
			grid_size: 17
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 8, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 0, 7, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 0, 0, 1], [1, 0, 6, 1, 0, 0, 0, 0, 0, 0, 15, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 7, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 8, y: 15 }
			blocks: [BlockDef{ x: 6, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 8, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 12, dir: 'down', dirs: [], axis: '', range_min: 9, range_max: 12 }, EnemyDef{ typ: 'snake', x: 14, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 14, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 5, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 14, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 14, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 11, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 14, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'U', 'L', 'S_U', 'U', 'U', 'L', 'R', 'D', 'D', 'R', 'R', 'L', 'L', 'L', 'S_L', 'L', 'D', 'D', 'D', 'L', 'D', 'D', 'D', 'R', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'R', 'U', 'R', 'R', 'R', 'R', 'R', 'D', 'R', 'R', 'U', 'R', 'R', 'R', 'D', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'U']
		},
		LevelDef{
			id: 86
			name: 'Stage 86: Permafrost Sentry Run'
			grid_size: 17
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 8, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 7, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 16, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 7, 0, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 17, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 15, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 2, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 8, y: 15 }
			blocks: [BlockDef{ x: 6, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 8, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa', x: 14, y: 12, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_diag', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 14, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 2, y: 12, dir: 'down', dirs: [], axis: 'vertical', range_min: 9, range_max: 12 }, EnemyDef{ typ: 'gol', x: 14, y: 5, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 14, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 5, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 14, y: 4, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 14, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 11, y: 10, dir: 'up', dirs: ['up'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'wisp', x: 2, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'orbiter', x: 14, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'D', 'L', 'L', 'L', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'L', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'R', 'U', 'R', 'U', 'R', 'R', 'L', 'L', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'S_R', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'L', 'L', 'L', 'L', 'L', 'L', 'U', 'R', 'U', 'L', 'L', 'L', 'U', 'L', 'L', 'D', 'U', 'R', 'R', 'D', 'R', 'R', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 87
			name: 'Stage 87: Striker Precision Net'
			grid_size: 17
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 8, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 6, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 0, 7, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 7, 1, 17, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 15, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 8, y: 15 }
			blocks: [BlockDef{ x: 6, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 8, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa', x: 14, y: 12, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_diag', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 14, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 2, y: 12, dir: 'down', dirs: [], axis: 'vertical', range_min: 9, range_max: 12 }, EnemyDef{ typ: 'gol', x: 14, y: 5, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 14, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 5, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 14, y: 4, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 14, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 11, y: 10, dir: 'up', dirs: ['up'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'wisp', x: 2, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'orbiter', x: 14, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'S_L', 'U', 'U', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'L', 'U', 'U', 'R', 'R', 'R', 'L', 'L', 'L', 'D', 'L', 'L', 'L', 'D', 'L', 'U', 'R', 'U', 'L', 'L', 'U', 'L', 'L', 'D', 'U', 'R', 'R', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'L', 'L', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U']
		},
		LevelDef{
			id: 88
			name: 'Stage 88: Slumbering Horde'
			grid_size: 17
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 8, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 7, 0, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 15, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 2, 0, 0, 0, 6, 0, 0, 0, 0, 7, 0, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 8, y: 15 }
			blocks: [BlockDef{ x: 6, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 8, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa', x: 14, y: 12, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_diag', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 14, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 2, y: 12, dir: 'down', dirs: [], axis: 'vertical', range_min: 9, range_max: 12 }, EnemyDef{ typ: 'gol', x: 14, y: 5, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 14, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 5, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 14, y: 4, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 14, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 11, y: 10, dir: 'up', dirs: ['up'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'wisp', x: 2, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'orbiter', x: 14, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'L', 'L', 'U', 'L', 'L', 'L', 'D', 'L', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'L', 'R', 'R', 'R', 'L', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'U', 'R', 'R', 'U', 'R', 'R', 'L', 'L', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'R', 'D', 'R', 'U', 'U', 'U', 'U', 'R', 'R', 'U', 'U', 'R', 'R', 'U', 'R', 'U', 'L', 'L', 'L', 'U', 'L', 'L', 'D', 'U', 'R', 'R', 'D', 'R', 'R', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 89
			name: 'Stage 89: Magnetic Vault Lock'
			grid_size: 17
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 8, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 16, 0, 6, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 7, 0, 1, 0, 0, 1], [1, 0, 0, 0, 7, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 17, 1, 0, 0, 1], [1, 0, 0, 1, 6, 0, 0, 0, 0, 0, 15, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 1, 0, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 8, y: 15 }
			blocks: [BlockDef{ x: 6, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 8, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa', x: 14, y: 12, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_diag', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 14, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 2, y: 12, dir: 'down', dirs: [], axis: 'vertical', range_min: 9, range_max: 12 }, EnemyDef{ typ: 'gol', x: 14, y: 5, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 14, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 5, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 14, y: 4, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 14, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 11, y: 10, dir: 'up', dirs: ['up'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'wisp', x: 2, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'orbiter', x: 14, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'U', 'U', 'L', 'L', 'U', 'U', 'U', 'L', 'L', 'U', 'L', 'L', 'D', 'D', 'D', 'D', 'D', 'D', 'L', 'L', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'R', 'R', 'U', 'U', 'L', 'L', 'S_L', 'U', 'U', 'U', 'L', 'U', 'U', 'U', 'L', 'L', 'U', 'U', 'R', 'R', 'R', 'L', 'L', 'L', 'D', 'L', 'L', 'L', 'L', 'D', 'L', 'U', 'R', 'U', 'L', 'U', 'L', 'L', 'D', 'U', 'R', 'R', 'D', 'R', 'R', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 90
			name: 'Stage 90: Sector 9 Apex Monolith'
			grid_size: 17
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 8, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 7, 0, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 17, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 15, 0, 0, 1, 7, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 8, y: 15 }
			blocks: [BlockDef{ x: 6, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 8, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 14, y: 12, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 12, dir: 'down', dirs: [], axis: '', range_min: 9, range_max: 12 }, EnemyDef{ typ: 'snake', x: 14, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 14, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 5, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 14, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 11, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 14, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'L', 'U', 'U', 'S_U', 'U', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'R', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'U', 'R', 'R', 'R', 'R', 'D', 'R', 'R', 'R', 'U', 'R', 'R', 'R', 'D', 'R', 'R', 'L', 'L', 'D', 'D', 'D', 'D', 'D', 'L', 'L', 'L', 'D', 'L', 'D', 'D', 'D', 'D', 'D', 'L', 'L', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U']
		},
		LevelDef{
			id: 91
			name: 'Stage 91: Citadel Infiltration'
			grid_size: 17
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 8, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 7, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 0, 7, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 0, 0, 1], [1, 0, 0, 1, 0, 6, 0, 0, 0, 0, 15, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 8, y: 15 }
			blocks: [BlockDef{ x: 6, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 8, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa', x: 14, y: 12, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_diag', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 14, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 2, y: 12, dir: 'down', dirs: [], axis: 'vertical', range_min: 9, range_max: 12 }, EnemyDef{ typ: 'gol', x: 14, y: 5, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 14, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 5, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 14, y: 4, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 14, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 11, y: 10, dir: 'up', dirs: ['up'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'wisp', x: 2, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'orbiter', x: 14, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'U', 'U', 'L', 'L', 'U', 'U', 'L', 'L', 'U', 'U', 'L', 'L', 'D', 'D', 'D', 'R', 'D', 'L', 'D', 'D', 'L', 'L', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'D', 'D', 'D', 'D', 'D', 'D', 'R', 'R', 'U', 'U', 'R', 'R', 'R', 'U', 'R', 'R', 'R', 'U', 'R', 'R', 'L', 'L', 'L', 'D', 'L', 'L', 'L', 'L', 'D', 'L', 'U', 'R', 'U', 'L', 'U', 'L', 'L', 'D', 'U', 'R', 'R', 'D', 'R', 'R', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 92
			name: 'Stage 92: Grand Prismatic Array'
			grid_size: 17
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 8, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 16, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 6, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 7, 0, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 17, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 15, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 2, 6, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 8, y: 15 }
			blocks: [BlockDef{ x: 6, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 8, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa', x: 14, y: 12, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_diag', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 14, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 2, y: 12, dir: 'down', dirs: [], axis: 'vertical', range_min: 9, range_max: 12 }, EnemyDef{ typ: 'gol', x: 14, y: 5, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 14, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 5, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 14, y: 4, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 14, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 11, y: 10, dir: 'up', dirs: ['up'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'wisp', x: 2, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'orbiter', x: 14, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'D', 'D', 'L', 'R', 'R', 'R', 'U', 'U', 'U', 'R', 'R', 'U', 'L', 'U', 'R', 'U', 'R', 'R', 'L', 'L', 'L', 'D', 'L', 'L', 'L', 'L', 'D', 'L', 'U', 'R', 'U', 'L', 'U', 'L', 'L', 'D', 'U', 'R', 'R', 'D', 'D', 'D', 'D', 'R', 'D', 'D', 'D', 'D', 'L', 'D', 'D', 'D', 'D', 'L', 'D', 'L', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U']
		},
		LevelDef{
			id: 93
			name: 'Stage 93: Boiling Magma Canal'
			grid_size: 17
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 8, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 0, 7, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 17, 0, 1], [1, 0, 0, 1, 0, 0, 6, 0, 0, 0, 15, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 7, 0, 1, 0, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 8, y: 15 }
			blocks: [BlockDef{ x: 6, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 8, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa', x: 14, y: 12, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_diag', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 14, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 2, y: 12, dir: 'down', dirs: [], axis: 'vertical', range_min: 9, range_max: 12 }, EnemyDef{ typ: 'gol', x: 14, y: 5, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 14, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 5, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 14, y: 4, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 14, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 11, y: 10, dir: 'up', dirs: ['up'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'wisp', x: 2, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'orbiter', x: 14, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'U', 'U', 'L', 'L', 'U', 'L', 'L', 'L', 'L', 'U', 'U', 'L', 'U', 'R', 'L', 'L', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'U', 'R', 'R', 'U', 'R', 'R', 'L', 'L', 'L', 'D', 'L', 'L', 'L', 'D', 'L', 'U', 'R', 'U', 'L', 'L', 'U', 'L', 'L', 'D', 'U', 'R', 'R', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'L', 'L', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U']
		},
		LevelDef{
			id: 94
			name: 'Stage 94: Decoy Phantasm Trench'
			grid_size: 17
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 8, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 16, 0, 0, 6, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 7, 0, 1, 0, 0, 1], [1, 0, 0, 7, 0, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 2, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 8, y: 15 }
			blocks: [BlockDef{ x: 6, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 10, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 8, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa', x: 14, y: 12, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_diag', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 14, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 2, y: 12, dir: 'down', dirs: [], axis: 'vertical', range_min: 9, range_max: 12 }, EnemyDef{ typ: 'gol', x: 14, y: 5, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 14, y: 8, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 5, y: 10, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 14, y: 4, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 14, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 11, y: 10, dir: 'up', dirs: ['up'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'wisp', x: 2, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'orbiter', x: 14, y: 6, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'U', 'U', 'L', 'U', 'L', 'U', 'U', 'L', 'L', 'U', 'L', 'L', 'L', 'R', 'U', 'U', 'R', 'R', 'D', 'D', 'D', 'D', 'D', 'D', 'L', 'L', 'D', 'L', 'L', 'R', 'U', 'R', 'U', 'U', 'R', 'R', 'U', 'R', 'S_R', 'U', 'U', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'L', 'L', 'U', 'U', 'R', 'R', 'R', 'L', 'L', 'L', 'D', 'L', 'L', 'L', 'L', 'D', 'L', 'U', 'R', 'U', 'L', 'U', 'L', 'L', 'D', 'U', 'R', 'R', 'D', 'R', 'R', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 95
			name: 'Stage 95: Quad Don Convergence'
			grid_size: 19
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 0, 7, 0, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 9, y: 17 }
			blocks: [BlockDef{ x: 11, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 9, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa', x: 16, y: 14, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_diag', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 16, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 2, y: 14, dir: 'down', dirs: [], axis: 'vertical', range_min: 10, range_max: 14 }, EnemyDef{ typ: 'gol', x: 16, y: 5, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 16, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 13, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 5, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 16, y: 4, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 16, y: 13, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 13, y: 11, dir: 'up', dirs: ['up'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'wisp', x: 2, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'orbiter', x: 16, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'L', 'L', 'L', 'U', 'U', 'L', 'L', 'U', 'L', 'L', 'L', 'D', 'D', 'D', 'D', 'R', 'D', 'D', 'D', 'L', 'L', 'L', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'L', 'D', 'D', 'D', 'D', 'S_L', 'D', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'U', 'U', 'R', 'R', 'L', 'L', 'L', 'D', 'R', 'D', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'D', 'L', 'U', 'U', 'R', 'U', 'L', 'U', 'L', 'L', 'D', 'U', 'R', 'R', 'D', 'R', 'R', 'R', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 96
			name: 'Stage 96: Quantum Wormhole Nexus'
			grid_size: 19
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 7, 0, 1], [1, 0, 6, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 17, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 15, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 9, y: 17 }
			blocks: [BlockDef{ x: 7, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 11, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 9, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 16, y: 14, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 16, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 14, dir: 'down', dirs: [], axis: '', range_min: 10, range_max: 14 }, EnemyDef{ typ: 'snake', x: 16, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 16, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 13, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 5, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 16, y: 13, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 13, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 16, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'R', 'U', 'U', 'L', 'L', 'L', 'L', 'U', 'U', 'L', 'U', 'U', 'U', 'L', 'L', 'L', 'L', 'S_L', 'L', 'U', 'L', 'U', 'U', 'U', 'R', 'L', 'U', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'D', 'R', 'R', 'U', 'R', 'R', 'R', 'R', 'D', 'R', 'S_R', 'R', 'D', 'U', 'L', 'L', 'D', 'D', 'D', 'D', 'D', 'D', 'L', 'L', 'L', 'L', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'L', 'L', 'L', 'L', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U']
		},
		LevelDef{
			id: 97
			name: 'Stage 97: The Dragon\'s Maw'
			grid_size: 19
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 0, 7, 0, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 15, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 9, y: 17 }
			blocks: [BlockDef{ x: 7, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 11, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 9, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa', x: 16, y: 14, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_diag', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 16, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 2, y: 14, dir: 'down', dirs: [], axis: 'vertical', range_min: 10, range_max: 14 }, EnemyDef{ typ: 'gol', x: 16, y: 5, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 16, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 13, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 5, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 16, y: 4, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 16, y: 13, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 13, y: 11, dir: 'up', dirs: ['up'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'wisp', x: 2, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'orbiter', x: 16, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'D', 'D', 'R', 'R', 'R', 'L', 'D', 'D', 'D', 'D', 'L', 'D', 'D', 'D', 'L', 'L', 'L', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'D', 'D', 'D', 'D', 'D', 'D', 'S_L', 'D', 'L', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'L', 'U', 'U', 'R', 'R', 'L', 'L', 'D', 'L', 'L', 'D', 'L', 'L', 'L', 'U', 'R', 'U', 'L', 'L', 'L', 'L', 'U', 'L', 'L', 'D', 'U', 'R', 'R', 'D', 'R', 'R', 'R', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 98
			name: 'Stage 98: Grandmaster Sokoban'
			grid_size: 19
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 15, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 9, y: 17 }
			blocks: [BlockDef{ x: 7, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 11, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 9, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa', x: 16, y: 14, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_diag', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 16, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 2, y: 14, dir: 'down', dirs: [], axis: 'vertical', range_min: 10, range_max: 14 }, EnemyDef{ typ: 'gol', x: 16, y: 5, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 16, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 13, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 5, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 16, y: 4, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 16, y: 13, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 13, y: 11, dir: 'up', dirs: ['up'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'wisp', x: 2, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'orbiter', x: 16, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'D', 'D', 'R', 'D', 'D', 'D', 'L', 'L', 'R', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'U', 'R', 'R', 'U', 'R', 'R', 'L', 'L', 'L', 'L', 'D', 'L', 'L', 'L', 'L', 'L', 'D', 'L', 'U', 'R', 'U', 'L', 'U', 'L', 'L', 'D', 'U', 'R', 'R', 'D', 'D', 'D', 'D', 'D', 'R', 'D', 'D', 'D', 'D', 'L', 'D', 'D', 'D', 'D', 'D', 'D', 'L', 'L', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U']
		},
		LevelDef{
			id: 99
			name: 'Stage 99: Apex Trial IX'
			grid_size: 19
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 7, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 0, 7, 0, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 17, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 15, 0, 7, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 9, y: 17 }
			blocks: [BlockDef{ x: 7, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 11, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 9, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'turret', x: 2, y: 5, dir: 'right', dirs: ['right'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa', x: 16, y: 14, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_diag', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'medusa_omni', x: 16, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'don_medusa', x: 2, y: 14, dir: 'down', dirs: [], axis: 'vertical', range_min: 10, range_max: 14 }, EnemyDef{ typ: 'gol', x: 16, y: 5, dir: 'left', dirs: ['left'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'leeper', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'skull', x: 16, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'alma', x: 2, y: 13, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'rocky', x: 5, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'moby', x: 16, y: 4, dir: 'left', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'hopper', x: 16, y: 13, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'striker', x: 13, y: 11, dir: 'up', dirs: ['up'], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'wisp', x: 2, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'L', 'L', 'U', 'U', 'U', 'L', 'L', 'L', 'L', 'U', 'U', 'U', 'R', 'D', 'D', 'D', 'D', 'L', 'D', 'D', 'D', 'R', 'D', 'D', 'D', 'L', 'L', 'L', 'R', 'U', 'R', 'U', 'U', 'U', 'R', 'S_U', 'U', 'S_R', 'R', 'U', 'U', 'R', 'R', 'R', 'R', 'R', 'S_R', 'R', 'U', 'U', 'D', 'D', 'L', 'L', 'U', 'U', 'U', 'U', 'U', 'L', 'L', 'L', 'L', 'U', 'U', 'R', 'R', 'R', 'R', 'L', 'L', 'L', 'L', 'D', 'L', 'L', 'L', 'L', 'L', 'D', 'L', 'U', 'R', 'U', 'L', 'U', 'L', 'L', 'D', 'U', 'R', 'R', 'D', 'R', 'R', 'R', 'R', 'R', 'U', 'U']
		},
		LevelDef{
			id: 100
			name: 'Stage 100: Grand Cyber Citadel Apex'
			grid_size: 19
			grid: [[1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 1, 1, 1, 1, 1, 1, 1, 1, 1], [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1], [1, 0, 7, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 6, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 7, 0, 0, 0, 18, 18, 6, 18, 18, 0, 0, 0, 0, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 15, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1], [1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 2, 0, 1], [1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 1], [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
			lolo: PointDef{ x: 9, y: 17 }
			blocks: [BlockDef{ x: 7, y: 3, typ: 'alloy', dir: '' }, BlockDef{ x: 11, y: 3, typ: 'alloy', dir: '' }]
			enemies: [EnemyDef{ typ: 'snake', x: 2, y: 9, dir: 'right', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 16, y: 14, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 16, y: 3, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 14, dir: 'down', dirs: [], axis: '', range_min: 10, range_max: 14 }, EnemyDef{ typ: 'snake', x: 16, y: 5, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 16, y: 9, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 13, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 5, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 16, y: 4, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 16, y: 13, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 13, y: 11, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 2, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }, EnemyDef{ typ: 'snake', x: 16, y: 7, dir: 'down', dirs: [], axis: '', range_min: 0, range_max: 0 }]
			solver_path: ['U', 'R', 'R', 'R', 'U', 'D', 'R', 'R', 'U', 'U', 'U', 'U', 'L', 'L', 'U', 'U', 'U', 'L', 'L', 'L', 'L', 'L', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'U', 'L', 'L', 'L', 'L', 'R', 'R', 'R', 'R', 'R', 'D', 'R', 'R', 'R', 'R', 'R', 'U', 'R', 'R', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'R', 'R', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'L', 'L', 'R', 'U', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'R', 'R', 'R', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U', 'U']
		},
	]
}