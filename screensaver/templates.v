module main

pub fn get_all_templates() []ScreensaverTemplate {
	mut t := []ScreensaverTemplate{cap: 110}

	// ----------------------------------------------------
	// Category 1: Windows 95 / 98 / Plus! / XP Classics (1-15)
	// ----------------------------------------------------
	t << ScreensaverTemplate{
		id: 1, name: '3D Pipes (Classic Brass)', category: .windows_classics, engine: .engine_pipes,
		description: 'Iconic Windows 95 OpenGL 3D branching pipes with brass joints.', year: '1995',
		primary_color: Color{ r: 218, g: 165, b: 32 }, secondary_color: Color{ r: 180, g: 80, b: 30 }, accent_color: Color{ r: 255, g: 215, b: 0 },
		speed: 1.0, density: 4, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 2, name: '3D Pipes (Cyber Neon)', category: .windows_classics, engine: .engine_pipes,
		description: 'High-speed glowing cyberpunk pipe network.', year: '1998',
		primary_color: Color{ r: 0, g: 255, b: 255 }, secondary_color: Color{ r: 255, g: 0, b: 255 }, accent_color: Color{ r: 50, g: 255, b: 50 },
		speed: 1.5, density: 6, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 3, name: '3D Flying Objects (Windows Logo)', category: .windows_classics, engine: .engine_flying_objects,
		description: 'Floating, rotating 4-color Windows emblem in outer space.', year: '1995',
		primary_color: Color{ r: 242, g: 80, b: 34 }, secondary_color: Color{ r: 0, g: 164, b: 239 }, accent_color: Color{ r: 255, g: 185, b: 0 },
		speed: 1.0, density: 3, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 4, name: '3D Flying Objects (Exploding Stars)', category: .windows_classics, engine: .engine_flying_objects,
		description: 'Faceted multi-colored 3D stars orbiting in perspective.', year: '1996',
		primary_color: Color{ r: 255, g: 220, b: 50 }, secondary_color: Color{ r: 255, g: 100, b: 50 }, accent_color: Color{ r: 100, g: 200, b: 255 },
		speed: 1.2, density: 5, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 5, name: '3D Maze (Classic Brick)', category: .windows_classics, engine: .engine_maze,
		description: '1st-person 3D raycasted labyrinth with smiley faces & brick walls.', year: '1995',
		primary_color: Color{ r: 180, g: 50, b: 40 }, secondary_color: Color{ r: 80, g: 80, b: 90 }, accent_color: Color{ r: 255, g: 220, b: 0 },
		speed: 1.0, density: 8, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 6, name: '3D Text ("Windows 95")', category: .windows_classics, engine: .engine_3d_text,
		description: 'Spinning, wobbling 3D chrome rendered typography.', year: '1995',
		primary_color: Color{ r: 190, g: 210, b: 240 }, secondary_color: Color{ r: 90, g: 130, b: 190 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.0, density: 1, custom_text: 'Windows 95', sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 7, name: '3D Text (Live Digital Clock)', category: .windows_classics, engine: .engine_3d_text,
		description: '3D rotating timekeeper reflecting OpenGL lighting.', year: '1998',
		primary_color: Color{ r: 0, g: 255, b: 180 }, secondary_color: Color{ r: 0, g: 120, b: 100 }, accent_color: Color{ r: 150, g: 255, b: 220 },
		speed: 1.0, density: 1, custom_text: 'TIME', sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 8, name: 'Mystify (Rainbow Polygon)', category: .windows_classics, engine: .engine_mystify,
		description: 'Multi-vertex bouncing neon polygons with shifting hues.', year: '1990',
		primary_color: Color{ r: 255, g: 50, b: 150 }, secondary_color: Color{ r: 50, g: 200, b: 255 }, accent_color: Color{ r: 255, g: 255, b: 50 },
		speed: 1.2, density: 4, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 9, name: 'Mystify (Dual Lissajous)', category: .windows_classics, engine: .engine_mystify,
		description: 'Intertwined complex orbital ribbon curves.', year: '1992',
		primary_color: Color{ r: 0, g: 255, b: 128 }, secondary_color: Color{ r: 128, g: 0, b: 255 }, accent_color: Color{ r: 255, g: 200, b: 0 },
		speed: 0.9, density: 6, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 10, name: 'Starfield (Warp Speed)', category: .windows_classics, engine: .engine_starfield,
		description: 'Iconic 3D starfield hyperjump acceleration.', year: '1991',
		primary_color: Color{ r: 255, g: 255, b: 255 }, secondary_color: Color{ r: 180, g: 200, b: 255 }, accent_color: Color{ r: 255, g: 255, b: 180 },
		speed: 1.6, density: 400, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 11, name: 'Starfield (Deep Space Nebula)', category: .windows_classics, engine: .engine_starfield,
		description: 'Calm drift through multicolored stellar nebulae.', year: '1998',
		primary_color: Color{ r: 200, g: 150, b: 255 }, secondary_color: Color{ r: 100, g: 180, b: 255 }, accent_color: Color{ r: 255, g: 120, b: 180 },
		speed: 0.6, density: 300, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 12, name: 'Bezier Curves (Silk Ribbons)', category: .windows_classics, engine: .engine_bezier,
		description: 'Flowing cubic bezier spline waves drifting across the screen.', year: '1993',
		primary_color: Color{ r: 255, g: 100, b: 80 }, secondary_color: Color{ r: 80, g: 200, b: 255 }, accent_color: Color{ r: 220, g: 80, b: 220 },
		speed: 1.0, density: 5, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 13, name: 'Scrolling Marquee (Retro Banner)', category: .windows_classics, engine: .engine_3d_text,
		description: 'Classic Windows 3.1 & 95 customizable marquee banner.', year: '1992',
		primary_color: Color{ r: 255, g: 255, b: 0 }, secondary_color: Color{ r: 0, g: 0, b: 0 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.0, density: 1, custom_text: 'WELCOME TO V ARCADE', sub_mode: 2
	}
	t << ScreensaverTemplate{
		id: 14, name: 'Underwater Aquarium (Plus! 98)', category: .windows_classics, engine: .engine_aquarium,
		description: 'Serene coral reef with rising air bubbles & swimming fish.', year: '1998',
		primary_color: Color{ r: 0, g: 140, b: 200 }, secondary_color: Color{ r: 255, g: 120, b: 0 }, accent_color: Color{ r: 50, g: 220, b: 120 },
		speed: 0.8, density: 12, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 15, name: 'Dangerous Creatures (Jungle)', category: .windows_classics, engine: .engine_aquarium,
		description: 'Dark tropical foliage with glowing predator eyes.', year: '1994',
		primary_color: Color{ r: 20, g: 80, b: 30 }, secondary_color: Color{ r: 255, g: 200, b: 0 }, accent_color: Color{ r: 255, g: 50, b: 50 },
		speed: 0.5, density: 8, sub_mode: 1
	}

	// ----------------------------------------------------
	// Category 2: After Dark & 90s Mac Nostalgia (16-30)
	// ----------------------------------------------------
	t << ScreensaverTemplate{
		id: 16, name: 'Flying Toasters (Original 1989)', category: .after_dark, engine: .engine_toasters,
		description: 'The legendary Berkeley Systems flying chrome toasters with wings.', year: '1989',
		primary_color: Color{ r: 220, g: 220, b: 230 }, secondary_color: Color{ r: 190, g: 140, b: 90 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.0, density: 6, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 17, name: 'Flying Toasters (Night Flight)', category: .after_dark, engine: .engine_toasters,
		description: 'Toasters soaring across a deep starry midnight sky.', year: '1991',
		primary_color: Color{ r: 180, g: 190, b: 220 }, secondary_color: Color{ r: 210, g: 160, b: 100 }, accent_color: Color{ r: 255, g: 240, b: 150 },
		speed: 1.2, density: 8, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 18, name: 'Fish City (After Dark Aquarium)', category: .after_dark, engine: .engine_aquarium,
		description: 'Retro Mac pixel art tropical fish and ascending bubble columns.', year: '1990',
		primary_color: Color{ r: 10, g: 40, b: 80 }, secondary_color: Color{ r: 255, g: 150, b: 0 }, accent_color: Color{ r: 100, g: 255, b: 200 },
		speed: 0.9, density: 15, sub_mode: 2
	}
	t << ScreensaverTemplate{
		id: 19, name: 'Boris the Cat', category: .after_dark, engine: .engine_toasters,
		description: 'Playful pixel cat exploring and napping across the screen.', year: '1992',
		primary_color: Color{ r: 220, g: 130, b: 60 }, secondary_color: Color{ r: 255, g: 255, b: 255 }, accent_color: Color{ r: 255, g: 100, b: 150 },
		speed: 0.7, density: 1, sub_mode: 2
	}
	t << ScreensaverTemplate{
		id: 20, name: 'Bad Dog (Carpet Digger)', category: .after_dark, engine: .engine_toasters,
		description: 'Mischievous terrier tearing holes in the screen.', year: '1993',
		primary_color: Color{ r: 160, g: 110, b: 70 }, secondary_color: Color{ r: 220, g: 180, b: 130 }, accent_color: Color{ r: 255, g: 50, b: 50 },
		speed: 0.8, density: 1, sub_mode: 3
	}
	t << ScreensaverTemplate{
		id: 21, name: 'Maelstrom (Cosmic Vortex)', category: .after_dark, engine: .engine_tunnel,
		description: 'Swirling gravitational cosmic sinkhole pulling stellar matter.', year: '1992',
		primary_color: Color{ r: 120, g: 0, b: 200 }, secondary_color: Color{ r: 0, g: 180, b: 255 }, accent_color: Color{ r: 255, g: 220, b: 100 },
		speed: 1.4, density: 20, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 22, name: 'Lunatic Fringe (Space Patrol)', category: .after_dark, engine: .engine_starfield,
		description: 'Automated arcade starfighter defending against alien fleets.', year: '1993',
		primary_color: Color{ r: 255, g: 80, b: 80 }, secondary_color: Color{ r: 80, g: 255, b: 120 }, accent_color: Color{ r: 255, g: 255, b: 0 },
		speed: 1.3, density: 250, sub_mode: 2
	}
	t << ScreensaverTemplate{
		id: 23, name: 'Squirts (Raindrops on Glass)', category: .after_dark, engine: .engine_rain_ripples,
		description: 'Atmospheric water condensation running down a window pane.', year: '1991',
		primary_color: Color{ r: 160, g: 200, b: 240 }, secondary_color: Color{ r: 90, g: 130, b: 180 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 0.8, density: 40, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 24, name: 'Neon Spirograph', category: .after_dark, engine: .engine_mystify,
		description: 'Multi-gear mathematical geometric line drawings in vibrant neon.', year: '1990',
		primary_color: Color{ r: 0, g: 255, b: 200 }, secondary_color: Color{ r: 255, g: 0, b: 150 }, accent_color: Color{ r: 255, g: 255, b: 0 },
		speed: 1.0, density: 8, sub_mode: 2
	}
	t << ScreensaverTemplate{
		id: 25, name: 'Hall of Mirrors', category: .after_dark, engine: .engine_tunnel,
		description: 'Infinite receding tunnel of ornate picture frames.', year: '1993',
		primary_color: Color{ r: 200, g: 160, b: 80 }, secondary_color: Color{ r: 60, g: 40, b: 20 }, accent_color: Color{ r: 255, g: 230, b: 150 },
		speed: 1.1, density: 16, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 26, name: 'Laser Show', category: .after_dark, engine: .engine_bezier,
		description: 'Concert venue laser beams slicing through atmospheric haze.', year: '1992',
		primary_color: Color{ r: 50, g: 255, b: 50 }, secondary_color: Color{ r: 255, g: 50, b: 50 }, accent_color: Color{ r: 50, g: 100, b: 255 },
		speed: 1.4, density: 7, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 27, name: 'Globe 3D (Wireframe Earth)', category: .after_dark, engine: .engine_hypercube,
		description: 'Rotating vector wireframe globe with latitude and longitude lines.', year: '1991',
		primary_color: Color{ r: 80, g: 180, b: 255 }, secondary_color: Color{ r: 30, g: 80, b: 160 }, accent_color: Color{ r: 150, g: 240, b: 255 },
		speed: 0.9, density: 24, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 28, name: 'Flying Windows (GUI Storm)', category: .after_dark, engine: .engine_flying_objects,
		description: 'Cascading retro system dialog boxes floating across space.', year: '1994',
		primary_color: Color{ r: 200, g: 200, b: 200 }, secondary_color: Color{ r: 0, g: 0, b: 128 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.1, density: 4, sub_mode: 2
	}
	t << ScreensaverTemplate{
		id: 29, name: 'Night Sky & Constellations', category: .after_dark, engine: .engine_starfield,
		description: 'Astronomical celestial map with glowing constellation lines.', year: '1992',
		primary_color: Color{ r: 100, g: 150, b: 255 }, secondary_color: Color{ r: 50, g: 80, b: 160 }, accent_color: Color{ r: 255, g: 255, b: 200 },
		speed: 0.4, density: 180, sub_mode: 3
	}
	t << ScreensaverTemplate{
		id: 30, name: 'Autonomous Lawn Mower', category: .after_dark, engine: .engine_snake_ai,
		description: 'Grid-based lawnmower cutting grass in optimal lawn strips.', year: '1993',
		primary_color: Color{ r: 40, g: 180, b: 40 }, secondary_color: Color{ r: 20, g: 100, b: 20 }, accent_color: Color{ r: 220, g: 30, b: 30 },
		speed: 1.0, density: 20, sub_mode: 1
	}

	// ----------------------------------------------------
	// Category 3: XScreenSaver & Hacker Terminals (31-48)
	// ----------------------------------------------------
	t << ScreensaverTemplate{
		id: 31, name: 'The Matrix (Classic Phosphor Green)', category: .hacker_xscreen, engine: .engine_matrix,
		description: 'Cascading green digital rain with glowing white lead glyphs.', year: '1999',
		primary_color: Color{ r: 0, g: 255, b: 70 }, secondary_color: Color{ r: 0, g: 120, b: 30 }, accent_color: Color{ r: 210, g: 255, b: 220 },
		speed: 1.0, density: 35, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 32, name: 'The Matrix (Cyberpunk Cyan)', category: .hacker_xscreen, engine: .engine_matrix,
		description: 'Electric cyan data code stream from the mainframe.', year: '2003',
		primary_color: Color{ r: 0, g: 230, b: 255 }, secondary_color: Color{ r: 0, g: 80, b: 150 }, accent_color: Color{ r: 220, g: 255, b: 255 },
		speed: 1.2, density: 40, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 33, name: 'The Matrix (Red Alert Binary)', category: .hacker_xscreen, engine: .engine_matrix,
		description: 'High-security crimson binary 0/1 data cascade.', year: '2000',
		primary_color: Color{ r: 255, g: 40, b: 40 }, secondary_color: Color{ r: 130, g: 0, b: 0 }, accent_color: Color{ r: 255, g: 200, b: 200 },
		speed: 1.3, density: 45, sub_mode: 2
	}
	t << ScreensaverTemplate{
		id: 34, name: 'BSOD (Windows 95 Fatal Exception)', category: .hacker_xscreen, engine: .engine_bsod,
		description: 'Authentic fatal exception 0E has occurred at 0028:C0011E36.', year: '1995',
		primary_color: Color{ r: 0, g: 0, b: 170 }, secondary_color: Color{ r: 255, g: 255, b: 255 }, accent_color: Color{ r: 0, g: 0, b: 170 },
		speed: 1.0, density: 1, custom_text: 'Windows 95', sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 35, name: 'BSOD (Windows XP Kernel Trap)', category: .hacker_xscreen, engine: .engine_bsod,
		description: 'STOP: 0x000000D1 DRIVER_IRQL_NOT_LESS_OR_EQUAL dump.', year: '2001',
		primary_color: Color{ r: 0, g: 0, b: 130 }, secondary_color: Color{ r: 255, g: 255, b: 255 }, accent_color: Color{ r: 0, g: 0, b: 130 },
		speed: 1.0, density: 1, custom_text: 'Windows XP', sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 36, name: 'BSOD (Amiga Guru Meditation)', category: .hacker_xscreen, engine: .engine_bsod,
		description: 'Software Failure. Press left mouse button. #00000004.#00004845', year: '1985',
		primary_color: Color{ r: 0, g: 0, b: 0 }, secondary_color: Color{ r: 255, g: 0, b: 0 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.0, density: 1, custom_text: 'AMIGA GURU', sub_mode: 2
	}
	t << ScreensaverTemplate{
		id: 37, name: 'BSOD (Classic Mac Bomb System 7)', category: .hacker_xscreen, engine: .engine_bsod,
		description: 'Sorry, a system error occurred. "Finder" address error.', year: '1991',
		primary_color: Color{ r: 240, g: 240, b: 240 }, secondary_color: Color{ r: 0, g: 0, b: 0 }, accent_color: Color{ r: 180, g: 180, b: 180 },
		speed: 1.0, density: 1, custom_text: 'Macintosh', sub_mode: 3
	}
	t << ScreensaverTemplate{
		id: 38, name: 'BSOD (Linux Kernel Panic Oops)', category: .hacker_xscreen, engine: .engine_bsod,
		description: 'Kernel panic - not syncing: Fatal exception in interrupt.', year: '1994',
		primary_color: Color{ r: 0, g: 0, b: 0 }, secondary_color: Color{ r: 200, g: 200, b: 200 }, accent_color: Color{ r: 255, g: 100, b: 100 },
		speed: 1.0, density: 1, custom_text: 'Linux Panic', sub_mode: 4
	}
	t << ScreensaverTemplate{
		id: 39, name: 'Phosphor CRT Terminal (Green Mainframe)', category: .hacker_xscreen, engine: .engine_terminal,
		description: 'High-speed diagnostic scrolling buffer on P1 green phosphor CRT.', year: '1982',
		primary_color: Color{ r: 50, g: 255, b: 50 }, secondary_color: Color{ r: 0, g: 80, b: 0 }, accent_color: Color{ r: 180, g: 255, b: 180 },
		speed: 1.0, density: 24, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 40, name: 'Phosphor CRT Terminal (Amber VT220)', category: .hacker_xscreen, engine: .engine_terminal,
		description: 'DEC VT220 glowing amber terminal output stream.', year: '1983',
		primary_color: Color{ r: 255, g: 170, b: 0 }, secondary_color: Color{ r: 100, g: 60, b: 0 }, accent_color: Color{ r: 255, g: 230, b: 150 },
		speed: 1.0, density: 24, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 41, name: "Conway's Game of Life (Gosper Gun)", category: .hacker_xscreen, engine: .engine_life,
		description: 'Continuous glider generator shooting cellular streams.', year: '1970',
		primary_color: Color{ r: 0, g: 255, b: 200 }, secondary_color: Color{ r: 0, g: 80, b: 60 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.0, density: 50, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 42, name: "Conway's Game of Life (Primordial Soup)", category: .hacker_xscreen, engine: .engine_life,
		description: 'Organic evolving cellular colonies, oscillators, and still-lifes.', year: '1975',
		primary_color: Color{ r: 255, g: 80, b: 180 }, secondary_color: Color{ r: 80, g: 20, b: 60 }, accent_color: Color{ r: 255, g: 220, b: 50 },
		speed: 1.2, density: 60, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 43, name: "Langton's Ant", category: .hacker_xscreen, engine: .engine_life,
		description: 'Cellular automaton ant building complex recursive highways.', year: '1986',
		primary_color: Color{ r: 255, g: 220, b: 0 }, secondary_color: Color{ r: 50, g: 50, b: 200 }, accent_color: Color{ r: 255, g: 50, b: 50 },
		speed: 2.0, density: 80, sub_mode: 2
	}
	t << ScreensaverTemplate{
		id: 44, name: 'Boids Flocking (Starling Murmuration)', category: .hacker_xscreen, engine: .engine_boids,
		description: 'Craig Reynolds flocking simulation: Separation, Alignment, Cohesion.', year: '1986',
		primary_color: Color{ r: 220, g: 230, b: 255 }, secondary_color: Color{ r: 80, g: 100, b: 150 }, accent_color: Color{ r: 255, g: 200, b: 50 },
		speed: 1.0, density: 120, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 45, name: 'Boids Flocking (Neon Bioluminescent Swarm)', category: .hacker_xscreen, engine: .engine_boids,
		description: 'Glowing aquatic swarm steering around gravity wells.', year: '1995',
		primary_color: Color{ r: 0, g: 255, b: 255 }, secondary_color: Color{ r: 255, g: 0, b: 128 }, accent_color: Color{ r: 255, g: 255, b: 0 },
		speed: 1.3, density: 150, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 46, name: 'Lorenz Attractor (Butterfly Chaos)', category: .hacker_xscreen, engine: .engine_attractor,
		description: 'Chaotic 3D differential trajectory with dual orbital lobes.', year: '1963',
		primary_color: Color{ r: 0, g: 240, b: 255 }, secondary_color: Color{ r: 255, g: 50, b: 100 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.0, density: 800, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 47, name: 'Rossler Attractor (Cosmic Ribbon)', category: .hacker_xscreen, engine: .engine_attractor,
		description: 'Continuous spiral band unfolding into deterministic chaos.', year: '1976',
		primary_color: Color{ r: 255, g: 140, b: 0 }, secondary_color: Color{ r: 180, g: 0, b: 255 }, accent_color: Color{ r: 255, g: 255, b: 100 },
		speed: 1.1, density: 900, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 48, name: 'Aizawa Attractor (Spherical Vortex)', category: .hacker_xscreen, engine: .engine_attractor,
		description: '3D spherical flow with central core jet stream.', year: '1984',
		primary_color: Color{ r: 50, g: 255, b: 150 }, secondary_color: Color{ r: 0, g: 120, b: 255 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.0, density: 1000, sub_mode: 2
	}

	// ----------------------------------------------------
	// Category 4: Demoscene & Synthwave Retro (49-66)
	// ----------------------------------------------------
	t << ScreensaverTemplate{
		id: 49, name: 'Synthwave Outrun Grid (Sunset 1984)', category: .demoscene_synth, engine: .engine_synthwave,
		description: 'Neon vector horizon, glowing segmented sun, and mountain ranges.', year: '1984',
		primary_color: Color{ r: 255, g: 0, b: 128 }, secondary_color: Color{ r: 0, g: 240, b: 255 }, accent_color: Color{ r: 255, g: 220, b: 0 },
		speed: 1.0, density: 20, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 50, name: 'Synthwave Cyber Highway (Purple Moon)', category: .demoscene_synth, engine: .engine_synthwave,
		description: 'High-speed receding perspective highway under a neon moon.', year: '1986',
		primary_color: Color{ r: 160, g: 0, b: 255 }, secondary_color: Color{ r: 0, g: 255, b: 200 }, accent_color: Color{ r: 255, g: 100, b: 200 },
		speed: 1.5, density: 24, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 51, name: 'Amiga Copper Bars (Rainbow Raster)', category: .demoscene_synth, engine: .engine_plasma,
		description: 'Classic Amiga OCS hardware Copper raster color bars.', year: '1985',
		primary_color: Color{ r: 255, g: 0, b: 0 }, secondary_color: Color{ r: 0, g: 255, b: 0 }, accent_color: Color{ r: 0, g: 0, b: 255 },
		speed: 1.2, density: 16, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 52, name: 'Doom Fire (Classic PSX / PC Engine)', category: .demoscene_synth, engine: .engine_doom_fire,
		description: 'The authentic Fabien Sanglard Doom 1993 fire palette algorithm.', year: '1993',
		primary_color: Color{ r: 255, g: 80, b: 0 }, secondary_color: Color{ r: 255, g: 220, b: 0 }, accent_color: Color{ r: 120, g: 0, b: 0 },
		speed: 1.0, density: 80, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 53, name: 'Blue Mystic Plasma Fire', category: .demoscene_synth, engine: .engine_doom_fire,
		description: 'Eerie blue/cyan arcane inferno rising from the screen base.', year: '1995',
		primary_color: Color{ r: 0, g: 160, b: 255 }, secondary_color: Color{ r: 180, g: 240, b: 255 }, accent_color: Color{ r: 0, g: 30, b: 120 },
		speed: 1.1, density: 80, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 54, name: 'Oldschool Demo Plasma', category: .demoscene_synth, engine: .engine_plasma,
		description: 'Multi-frequency sine/cosine wave interference color palette cycling.', year: '1991',
		primary_color: Color{ r: 255, g: 0, b: 255 }, secondary_color: Color{ r: 0, g: 255, b: 255 }, accent_color: Color{ r: 255, g: 255, b: 0 },
		speed: 1.0, density: 60, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 55, name: 'Voxel Landscape 3D (Comanche Alps)', category: .demoscene_synth, engine: .engine_voxel,
		description: 'Real-time raycast heightmap voxel terrain flight over mountain peaks.', year: '1992',
		primary_color: Color{ r: 50, g: 150, b: 50 }, secondary_color: Color{ r: 140, g: 110, b: 80 }, accent_color: Color{ r: 240, g: 240, b: 255 },
		speed: 1.0, density: 100, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 56, name: 'Voxel Mars Canyon Flight', category: .demoscene_synth, engine: .engine_voxel,
		description: 'Subterranean flight through red planetary canyons and dunes.', year: '1994',
		primary_color: Color{ r: 210, g: 60, b: 30 }, secondary_color: Color{ r: 120, g: 30, b: 10 }, accent_color: Color{ r: 255, g: 180, b: 100 },
		speed: 1.2, density: 100, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 57, name: 'Tunnel Zoomer (Checkerboard 3D)', category: .demoscene_synth, engine: .engine_tunnel,
		description: 'Twisting infinite 3D checkerboard cylinder flight.', year: '1994',
		primary_color: Color{ r: 255, g: 255, b: 255 }, secondary_color: Color{ r: 20, g: 20, b: 20 }, accent_color: Color{ r: 255, g: 50, b: 50 },
		speed: 1.2, density: 16, sub_mode: 2
	}
	t << ScreensaverTemplate{
		id: 58, name: 'Tunnel Zoomer (Hypnotic Psychedelic)', category: .demoscene_synth, engine: .engine_tunnel,
		description: 'Concentric color cycling tunnel warping through hyperspace.', year: '1996',
		primary_color: Color{ r: 255, g: 0, b: 128 }, secondary_color: Color{ r: 0, g: 255, b: 128 }, accent_color: Color{ r: 255, g: 255, b: 0 },
		speed: 1.4, density: 20, sub_mode: 3
	}
	t << ScreensaverTemplate{
		id: 59, name: 'Star Wars Opening Crawl', category: .demoscene_synth, engine: .engine_3d_text,
		description: 'Receding 3D angled narrative text crawl disappearing into starfield.', year: '1977',
		primary_color: Color{ r: 255, g: 220, b: 0 }, secondary_color: Color{ r: 180, g: 150, b: 0 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 0.8, density: 1, custom_text: 'EPISODE VII: THE V ADVENTURE', sub_mode: 3
	}
	t << ScreensaverTemplate{
		id: 60, name: 'Qix Vector Ribbon Trails', category: .demoscene_synth, engine: .engine_mystify,
		description: 'Spinning geometric wireframe line ribbons with fading trails.', year: '1981',
		primary_color: Color{ r: 0, g: 255, b: 255 }, secondary_color: Color{ r: 255, g: 0, b: 255 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.2, density: 12, sub_mode: 3
	}
	t << ScreensaverTemplate{
		id: 61, name: 'Chiptune Spectrum (32-Band VU Bars)', category: .demoscene_synth, engine: .engine_chiptune,
		description: 'Pulsating 32-band audio spectrum analyzer with peak meters.', year: '1988',
		primary_color: Color{ r: 0, g: 255, b: 100 }, secondary_color: Color{ r: 255, g: 200, b: 0 }, accent_color: Color{ r: 255, g: 40, b: 40 },
		speed: 1.0, density: 32, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 62, name: 'Chiptune Oscilloscope (Phosphor Beam)', category: .demoscene_synth, engine: .engine_chiptune,
		description: 'Real-time Lissajous and waveform sound oscilloscope.', year: '1984',
		primary_color: Color{ r: 50, g: 255, b: 80 }, secondary_color: Color{ r: 0, g: 100, b: 20 }, accent_color: Color{ r: 200, g: 255, b: 200 },
		speed: 1.0, density: 64, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 63, name: 'Chiptune Radial Starburst Visualizer', category: .demoscene_synth, engine: .engine_chiptune,
		description: '360-degree pulsating circular frequency spectrum burst.', year: '1995',
		primary_color: Color{ r: 0, g: 200, b: 255 }, secondary_color: Color{ r: 255, g: 0, b: 200 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.2, density: 48, sub_mode: 2
	}
	t << ScreensaverTemplate{
		id: 64, name: 'DNA Double Helix 3D', category: .demoscene_synth, engine: .engine_hypercube,
		description: 'Rotating molecular double helix with adenine-thymine rungs.', year: '1990',
		primary_color: Color{ r: 0, g: 220, b: 255 }, secondary_color: Color{ r: 255, g: 50, b: 100 }, accent_color: Color{ r: 255, g: 220, b: 50 },
		speed: 1.0, density: 24, sub_mode: 2
	}
	t << ScreensaverTemplate{
		id: 65, name: 'Hypercube 4D (Tesseract Projection)', category: .demoscene_synth, engine: .engine_hypercube,
		description: '4-dimensional hypercube rotating in 4D space and projected into 3D.', year: '1988',
		primary_color: Color{ r: 0, g: 255, b: 200 }, secondary_color: Color{ r: 200, g: 0, b: 255 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.0, density: 16, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 66, name: 'Liquid Metaballs 2D', category: .demoscene_synth, engine: .engine_plasma,
		description: 'Merging, stretching organic fluid mercury drops.', year: '1993',
		primary_color: Color{ r: 0, g: 150, b: 255 }, secondary_color: Color{ r: 255, g: 100, b: 50 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.1, density: 8, sub_mode: 2
	}

	// ----------------------------------------------------
	// Category 5: Mathematical Fractals & Physics Labs (67-80)
	// ----------------------------------------------------
	t << ScreensaverTemplate{
		id: 67, name: 'Mandelbrot Infinite Explorer', category: .fractals_physics, engine: .engine_fractal,
		description: 'Continuous smooth zoom into the Seahorse Valley of Mandelbrot.', year: '1980',
		primary_color: Color{ r: 0, g: 100, b: 255 }, secondary_color: Color{ r: 255, g: 150, b: 0 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 0.8, density: 40, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 68, name: 'Julia Set Morph (Complex Dynamics)', category: .fractals_physics, engine: .engine_fractal,
		description: 'Parametric orbit morph of quadratic Julia sets.', year: '1982',
		primary_color: Color{ r: 255, g: 0, b: 150 }, secondary_color: Color{ r: 0, g: 255, b: 200 }, accent_color: Color{ r: 255, g: 255, b: 0 },
		speed: 1.0, density: 40, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 69, name: 'Sierpinski Gasket (Chaos Game)', category: .fractals_physics, engine: .engine_fractal,
		description: 'Point probability distribution forming infinite recursive triangles.', year: '1915',
		primary_color: Color{ r: 0, g: 255, b: 180 }, secondary_color: Color{ r: 50, g: 100, b: 255 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.5, density: 1000, sub_mode: 2
	}
	t << ScreensaverTemplate{
		id: 70, name: 'Barnsley Fern IFS', category: .fractals_physics, engine: .engine_fractal,
		description: 'Iterated Function System growing biological fractal ferns.', year: '1988',
		primary_color: Color{ r: 40, g: 220, b: 60 }, secondary_color: Color{ r: 20, g: 120, b: 30 }, accent_color: Color{ r: 180, g: 255, b: 180 },
		speed: 1.4, density: 1200, sub_mode: 3
	}
	t << ScreensaverTemplate{
		id: 71, name: 'N-Body Gravity (Solar Planetary)', category: .fractals_physics, engine: .engine_gravity,
		description: 'Newtonian orbital gravity with trailing particle wakes.', year: '1968',
		primary_color: Color{ r: 255, g: 220, b: 0 }, secondary_color: Color{ r: 0, g: 180, b: 255 }, accent_color: Color{ r: 255, g: 80, b: 80 },
		speed: 1.0, density: 16, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 72, name: 'N-Body Galaxy Collision', category: .fractals_physics, engine: .engine_gravity,
		description: 'Two rotating spiral galaxies colliding and warping tidal tails.', year: '1972',
		primary_color: Color{ r: 100, g: 200, b: 255 }, secondary_color: Color{ r: 255, g: 100, b: 180 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.2, density: 250, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 73, name: 'Double Pendulum Chaos', category: .fractals_physics, engine: .engine_gravity,
		description: 'Lagrangian physics simulation demonstrating extreme sensitive dependence.', year: '1978',
		primary_color: Color{ r: 0, g: 255, b: 255 }, secondary_color: Color{ r: 255, g: 0, b: 100 }, accent_color: Color{ r: 255, g: 255, b: 0 },
		speed: 1.0, density: 400, sub_mode: 2
	}
	t << ScreensaverTemplate{
		id: 74, name: 'Verlet Cloth Grid (Wind Physics)', category: .fractals_physics, engine: .engine_gravity,
		description: 'Point-mass spring cloth mesh billowing under wind forces.', year: '1995',
		primary_color: Color{ r: 200, g: 220, b: 255 }, secondary_color: Color{ r: 100, g: 120, b: 180 }, accent_color: Color{ r: 255, g: 200, b: 100 },
		speed: 1.0, density: 400, sub_mode: 3
	}
	t << ScreensaverTemplate{
		id: 75, name: 'Fluid Vector Field Vortex', category: .fractals_physics, engine: .engine_gravity,
		description: 'Streamline particle advection through curling force fields.', year: '1992',
		primary_color: Color{ r: 0, g: 220, b: 255 }, secondary_color: Color{ r: 0, g: 80, b: 200 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.3, density: 300, sub_mode: 4
	}
	t << ScreensaverTemplate{
		id: 76, name: 'Sand & Powder Physics', category: .fractals_physics, engine: .engine_life,
		description: 'Falling colorful sand grains forming dunes and avalanches.', year: '1994',
		primary_color: Color{ r: 230, g: 190, b: 100 }, secondary_color: Color{ r: 180, g: 80, b: 200 }, accent_color: Color{ r: 80, g: 180, b: 220 },
		speed: 1.5, density: 60, sub_mode: 3
	}
	t << ScreensaverTemplate{
		id: 77, name: 'Hypnotic Moire Patterns', category: .fractals_physics, engine: .engine_mystify,
		description: 'Overlapping rotating line gratings generating optical wave illusions.', year: '1970',
		primary_color: Color{ r: 255, g: 255, b: 255 }, secondary_color: Color{ r: 0, g: 0, b: 0 }, accent_color: Color{ r: 128, g: 128, b: 128 },
		speed: 0.8, density: 36, sub_mode: 4
	}
	t << ScreensaverTemplate{
		id: 78, name: 'Harmonograph (4-Pendulum Curve)', category: .fractals_physics, engine: .engine_mystify,
		description: 'Acoustic decay curves drawn by four coupled pendulums.', year: '1890',
		primary_color: Color{ r: 255, g: 180, b: 50 }, secondary_color: Color{ r: 50, g: 200, b: 255 }, accent_color: Color{ r: 255, g: 50, b: 150 },
		speed: 1.0, density: 1000, sub_mode: 5
	}
	t << ScreensaverTemplate{
		id: 79, name: 'Voronoi Cellular Growth', category: .fractals_physics, engine: .engine_plasma,
		description: 'Dynamic Euclidean Voronoi partition centers expanding.', year: '1908',
		primary_color: Color{ r: 0, g: 200, b: 150 }, secondary_color: Color{ r: 150, g: 0, b: 200 }, accent_color: Color{ r: 255, g: 220, b: 0 },
		speed: 0.9, density: 16, sub_mode: 3
	}
	t << ScreensaverTemplate{
		id: 80, name: 'L-System Fractal Tree', category: .fractals_physics, engine: .engine_fractal,
		description: 'Grammar-based botanical tree swaying in procedural breeze.', year: '1968',
		primary_color: Color{ r: 140, g: 220, b: 100 }, secondary_color: Color{ r: 100, g: 70, b: 40 }, accent_color: Color{ r: 255, g: 150, b: 180 },
		speed: 0.7, density: 8, sub_mode: 4
	}

	// ----------------------------------------------------
	// Category 6: Ambient, Sci-Fi & Natural Phenomena (81-92)
	// ----------------------------------------------------
	t << ScreensaverTemplate{
		id: 81, name: 'Aurora Borealis (Northern Lights)', category: .ambient_scifi, engine: .engine_bezier,
		description: 'Luminous green and violet curtains waving in polar skies.', year: '1995',
		primary_color: Color{ r: 40, g: 255, b: 140 }, secondary_color: Color{ r: 160, g: 40, b: 255 }, accent_color: Color{ r: 80, g: 180, b: 255 },
		speed: 0.6, density: 12, sub_mode: 2
	}
	t << ScreensaverTemplate{
		id: 82, name: 'Fireworks Spectacular', category: .ambient_scifi, engine: .engine_fireworks,
		description: 'Grand finale aerial mortar shells bursting into sparkling waterfalls.', year: '1993',
		primary_color: Color{ r: 255, g: 50, b: 50 }, secondary_color: Color{ r: 50, g: 200, b: 255 }, accent_color: Color{ r: 255, g: 255, b: 100 },
		speed: 1.0, density: 200, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 83, name: 'Electric Tesla Storm (High Voltage)', category: .ambient_scifi, engine: .engine_lightning,
		description: 'Branching electrical lightning discharges and plasma arcs.', year: '1994',
		primary_color: Color{ r: 150, g: 200, b: 255 }, secondary_color: Color{ r: 200, g: 100, b: 255 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.3, density: 8, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 84, name: 'Blizzard & Drifting Snow', category: .ambient_scifi, engine: .engine_starfield,
		description: 'Quiet nighttime snowfall drifting under gusting wind currents.', year: '1990',
		primary_color: Color{ r: 255, g: 255, b: 255 }, secondary_color: Color{ r: 180, g: 200, b: 220 }, accent_color: Color{ r: 220, g: 240, b: 255 },
		speed: 0.7, density: 200, sub_mode: 4
	}
	t << ScreensaverTemplate{
		id: 85, name: 'Monsoon Rain & Pond Ripples', category: .ambient_scifi, engine: .engine_rain_ripples,
		description: 'Gentle raindrops falling onto a dark water surface creating concentric waves.', year: '1992',
		primary_color: Color{ r: 80, g: 180, b: 240 }, secondary_color: Color{ r: 30, g: 90, b: 160 }, accent_color: Color{ r: 200, g: 240, b: 255 },
		speed: 0.9, density: 30, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 86, name: 'Submarine Sonar Radar', category: .ambient_scifi, engine: .engine_radar,
		description: '360-degree rotating phosphor beam detecting underwater contacts.', year: '1984',
		primary_color: Color{ r: 0, g: 255, b: 100 }, secondary_color: Color{ r: 0, g: 80, b: 30 }, accent_color: Color{ r: 255, g: 50, b: 50 },
		speed: 1.0, density: 8, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 87, name: 'Sci-Fi Tactical HUD Diagnostics', category: .ambient_scifi, engine: .engine_radar,
		description: 'Targeting reticles, rotating orbital trackers, and telemetry readouts.', year: '1998',
		primary_color: Color{ r: 0, g: 220, b: 255 }, secondary_color: Color{ r: 0, g: 100, b: 150 }, accent_color: Color{ r: 255, g: 200, b: 0 },
		speed: 1.1, density: 12, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 88, name: 'Deep Ocean Bioluminescence', category: .ambient_scifi, engine: .engine_boids,
		description: 'Glowing jellyfish and abyssal plankton floating in the dark ocean.', year: '1996',
		primary_color: Color{ r: 0, g: 255, b: 220 }, secondary_color: Color{ r: 120, g: 40, b: 200 }, accent_color: Color{ r: 255, g: 255, b: 150 },
		speed: 0.5, density: 60, sub_mode: 2
	}
	t << ScreensaverTemplate{
		id: 89, name: 'Campfire Night Embers', category: .ambient_scifi, engine: .engine_doom_fire,
		description: 'Glowing orange embers floating upward into the midnight sky.', year: '1991',
		primary_color: Color{ r: 255, g: 120, b: 20 }, secondary_color: Color{ r: 255, g: 200, b: 50 }, accent_color: Color{ r: 150, g: 30, b: 0 },
		speed: 0.8, density: 60, sub_mode: 2
	}
	t << ScreensaverTemplate{
		id: 90, name: 'Starship Warp Drive Conduit', category: .ambient_scifi, engine: .engine_tunnel,
		description: 'Sub-space warp plasma conduit pulsing with energy.', year: '1993',
		primary_color: Color{ r: 0, g: 160, b: 255 }, secondary_color: Color{ r: 200, g: 50, b: 255 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.5, density: 24, sub_mode: 4
	}
	t << ScreensaverTemplate{
		id: 91, name: 'Solar Flare & Coronal Loops', category: .ambient_scifi, engine: .engine_plasma,
		description: 'Boiling stellar surface with magnetic plasma prominences.', year: '1995',
		primary_color: Color{ r: 255, g: 100, b: 0 }, secondary_color: Color{ r: 255, g: 220, b: 0 }, accent_color: Color{ r: 255, g: 40, b: 0 },
		speed: 0.9, density: 30, sub_mode: 4
	}
	t << ScreensaverTemplate{
		id: 92, name: 'Cosmic Nebula Cloud Generation', category: .ambient_scifi, engine: .engine_plasma,
		description: 'Multi-layered gaseous stellar nursery glowing in ultraviolet.', year: '1997',
		primary_color: Color{ r: 180, g: 50, b: 220 }, secondary_color: Color{ r: 50, g: 120, b: 220 }, accent_color: Color{ r: 255, g: 200, b: 100 },
		speed: 0.7, density: 40, sub_mode: 5
	}

	// ----------------------------------------------------
	// Category 7: Novelty, Arcade & Meme Favorites (93-102)
	// ----------------------------------------------------
	t << ScreensaverTemplate{
		id: 93, name: 'DVD Logo Bouncer (Corner Tracker)', category: .novelty_arcade, engine: .engine_dvd_logo,
		description: 'Will it hit the exact corner?! Keeps track of bounces & corner hits.', year: '2000',
		primary_color: Color{ r: 255, g: 80, b: 80 }, secondary_color: Color{ r: 80, g: 255, b: 80 }, accent_color: Color{ r: 80, g: 150, b: 255 },
		speed: 1.0, density: 1, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 94, name: 'Arcade Pong AI (Eternal Rally)', category: .novelty_arcade, engine: .engine_pong_ai,
		description: 'Two vintage arcade CPU paddles locked in an infinite rally duel.', year: '1972',
		primary_color: Color{ r: 255, g: 255, b: 255 }, secondary_color: Color{ r: 120, g: 120, b: 120 }, accent_color: Color{ r: 255, g: 255, b: 0 },
		speed: 1.0, density: 1, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 95, name: 'Autonomous Snake AI (Hamiltonian)', category: .novelty_arcade, engine: .engine_snake_ai,
		description: 'AI snake traversing optimal pathfinding cycles to fill the board.', year: '1997',
		primary_color: Color{ r: 0, g: 255, b: 120 }, secondary_color: Color{ r: 0, g: 100, b: 40 }, accent_color: Color{ r: 255, g: 50, b: 50 },
		speed: 1.2, density: 24, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 96, name: 'Autonomous Pac-Man Arcade', category: .novelty_arcade, engine: .engine_snake_ai,
		description: 'Retro yellow hero gobbling power pellets while dodging ghosts.', year: '1980',
		primary_color: Color{ r: 255, g: 255, b: 0 }, secondary_color: Color{ r: 0, g: 0, b: 255 }, accent_color: Color{ r: 255, g: 0, b: 0 },
		speed: 1.0, density: 16, sub_mode: 2
	}
	t << ScreensaverTemplate{
		id: 97, name: 'Clockwork Chronometer (Gears & Pendulum)', category: .novelty_arcade, engine: .engine_clockwork,
		description: 'Meshing brass gears, escapement wheels, and live ticking clock.', year: '1850',
		primary_color: Color{ r: 218, g: 165, b: 32 }, secondary_color: Color{ r: 140, g: 90, b: 40 }, accent_color: Color{ r: 255, g: 235, b: 150 },
		speed: 1.0, density: 6, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 98, name: 'Binary Digital Matrix Clock', category: .novelty_arcade, engine: .engine_clockwork,
		description: 'Real-time column binary matrix timekeeper with glowing LEDs.', year: '1999',
		primary_color: Color{ r: 0, g: 255, b: 200 }, secondary_color: Color{ r: 0, g: 60, b: 50 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.0, density: 6, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 99, name: 'Circuit Board Autonomous Tracer', category: .novelty_arcade, engine: .engine_pipes,
		description: 'Green PCB substrate with glowing copper signal traces routing.', year: '1987',
		primary_color: Color{ r: 0, g: 180, b: 80 }, secondary_color: Color{ r: 200, g: 160, b: 0 }, accent_color: Color{ r: 0, g: 255, b: 150 },
		speed: 1.1, density: 8, sub_mode: 2
	}
	t << ScreensaverTemplate{
		id: 100, name: 'Kaleidoscope Mirror (Symmetry 8-Way)', category: .novelty_arcade, engine: .engine_kaleidoscope,
		description: 'Rotating multi-faceted stained glass symmetry reflections.', year: '1989',
		primary_color: Color{ r: 255, g: 50, b: 180 }, secondary_color: Color{ r: 50, g: 200, b: 255 }, accent_color: Color{ r: 255, g: 220, b: 0 },
		speed: 0.9, density: 8, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 101, name: 'Night Highway Traffic Light Streaks', category: .novelty_arcade, engine: .engine_starfield,
		description: 'Long-exposure red tail-lights and white headlights streaming on highway.', year: '1995',
		primary_color: Color{ r: 255, g: 40, b: 40 }, secondary_color: Color{ r: 255, g: 255, b: 220 }, accent_color: Color{ r: 255, g: 180, b: 0 },
		speed: 1.4, density: 150, sub_mode: 5
	}
	t << ScreensaverTemplate{
		id: 102, name: 'Retro 1984 Macintosh Desktop Tour', category: .novelty_arcade, engine: .engine_flying_objects,
		description: 'Original MacPaint, floppy disks, trashcan, and smiling Mac icons.', year: '1984',
		primary_color: Color{ r: 220, g: 220, b: 220 }, secondary_color: Color{ r: 0, g: 0, b: 0 }, accent_color: Color{ r: 100, g: 100, b: 100 },
		speed: 1.0, density: 5, sub_mode: 3
	}

	// ----------------------------------------------------
	// Category 8: Modern Physics & Interactive Simulations (103-118)
	// ----------------------------------------------------
	t << ScreensaverTemplate{
		id: 103, name: 'Gargantua Black Hole (Relativistic Lensing)', category: .modern_physics, engine: .engine_black_hole,
		description: 'General relativity photon sphere, Doppler-beamed accretion disk, and Hawking radiation.', year: '2026',
		primary_color: Color{ r: 255, g: 170, b: 50 }, secondary_color: Color{ r: 255, g: 80, b: 20 }, accent_color: Color{ r: 255, g: 240, b: 200 },
		speed: 1.0, density: 500, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 104, name: 'SPH Fluid Hydrodynamics (Liquid Splash)', category: .modern_physics, engine: .engine_fluid_sph,
		description: 'Smoothed Particle Hydrodynamics liquid with viscosity, surface tension & sloshing.', year: '2026',
		primary_color: Color{ r: 0, g: 180, b: 255 }, secondary_color: Color{ r: 0, g: 80, b: 200 }, accent_color: Color{ r: 180, g: 240, b: 255 },
		speed: 1.0, density: 350, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 105, name: 'Elastic Soft-Body Jelly Lattice', category: .modern_physics, engine: .engine_softbody_jelly,
		description: 'Pressurized spring-mass jelly blob squishing and bouncing off physics obstacles.', year: '2026',
		primary_color: Color{ r: 0, g: 255, b: 160 }, secondary_color: Color{ r: 0, g: 150, b: 100 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.0, density: 36, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 106, name: 'N-Body Galactic Collision (Milky Way & Andromeda)', category: .modern_physics, engine: .engine_galaxy_nbody,
		description: 'Direct gravitational interaction of dual galactic cores forming tidal arms & bridges.', year: '2026',
		primary_color: Color{ r: 120, g: 200, b: 255 }, secondary_color: Color{ r: 255, g: 120, b: 180 }, accent_color: Color{ r: 255, g: 255, b: 220 },
		speed: 1.2, density: 600, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 107, name: 'Double Pendulum Chaos (Phase-Space Glow)', category: .modern_physics, engine: .engine_double_pendulum,
		description: 'Coupled chaotic Lagrangian pendulums trailing glowing phosphorescent ribbons.', year: '2026',
		primary_color: Color{ r: 0, g: 255, b: 240 }, secondary_color: Color{ r: 255, g: 0, b: 128 }, accent_color: Color{ r: 255, g: 240, b: 0 },
		speed: 1.0, density: 10, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 108, name: 'Magnetic Ferrofluid Spikes & Field Lines', category: .modern_physics, engine: .engine_ferrofluid,
		description: 'Surface tension spike formation over moving magnetic dipole attraction fields.', year: '2026',
		primary_color: Color{ r: 30, g: 35, b: 40 }, secondary_color: Color{ r: 80, g: 90, b: 110 }, accent_color: Color{ r: 0, g: 255, b: 200 },
		speed: 1.0, density: 180, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 109, name: 'Granular Sand Avalanche (Chutes & Dunes)', category: .modern_physics, engine: .engine_granules_sand,
		description: 'Angle-of-repose granular avalanche flowing through funnels, pins, and chutes.', year: '2026',
		primary_color: Color{ r: 240, g: 200, b: 110 }, secondary_color: Color{ r: 200, g: 100, b: 60 }, accent_color: Color{ r: 100, g: 220, b: 240 },
		speed: 1.2, density: 400, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 110, name: 'Neon Kinetic Marble Run (Rube Goldberg)', category: .modern_physics, engine: .engine_marble_run,
		description: 'Steel marbles rolling down loops, gravity rails, kinetic bumpers, and elevators.', year: '2026',
		primary_color: Color{ r: 0, g: 255, b: 255 }, secondary_color: Color{ r: 255, g: 0, b: 200 }, accent_color: Color{ r: 255, g: 255, b: 0 },
		speed: 1.0, density: 25, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 111, name: 'Optics Dispersion & Prism Refraction', category: .modern_physics, engine: .engine_optics_prism,
		description: 'White light ray breaking into Snell’s law rainbow caustics through crystal prisms.', year: '2026',
		primary_color: Color{ r: 255, g: 255, b: 255 }, secondary_color: Color{ r: 100, g: 150, b: 255 }, accent_color: Color{ r: 255, g: 50, b: 50 },
		speed: 0.9, density: 30, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 112, name: '2D Wave Tank (Double-Slit Interference)', category: .modern_physics, engine: .engine_wave_interference,
		description: 'Real-time wave propagation with constructive & destructive interference fringes.', year: '2026',
		primary_color: Color{ r: 0, g: 180, b: 255 }, secondary_color: Color{ r: 0, g: 40, b: 120 }, accent_color: Color{ r: 220, g: 255, b: 255 },
		speed: 1.0, density: 80, sub_mode: 0
	}
	t << ScreensaverTemplate{
		id: 113, name: 'Verlet Cloth Banner in Hurricane Wind', category: .modern_physics, engine: .engine_softbody_jelly,
		description: 'Point-mass spring lattice tearing and flapping in high Reynolds turbulence.', year: '2026',
		primary_color: Color{ r: 255, g: 80, b: 80 }, secondary_color: Color{ r: 180, g: 40, b: 40 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.2, density: 40, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 114, name: 'Predator-Prey Swarm (Bait-Ball Evasion)', category: .modern_physics, engine: .engine_boids,
		description: '1,000 prey fish forming a vortex bait-ball to evade sweeping predator sharks.', year: '2026',
		primary_color: Color{ r: 0, g: 240, b: 255 }, secondary_color: Color{ r: 0, g: 100, b: 160 }, accent_color: Color{ r: 255, g: 50, b: 50 },
		speed: 1.2, density: 250, sub_mode: 3
	}
	t << ScreensaverTemplate{
		id: 115, name: 'Tesla Plasma Globe (Filament Discharge)', category: .modern_physics, engine: .engine_lightning,
		description: 'Interactive high-frequency plasma streamers reaching for user touch points.', year: '2026',
		primary_color: Color{ r: 180, g: 80, b: 255 }, secondary_color: Color{ r: 80, g: 160, b: 255 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.3, density: 16, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 116, name: 'Supernova Shockwave & Interstellar Filament', category: .modern_physics, engine: .engine_fireworks,
		description: 'Magnetohydrodynamic blast wave ionizing interstellar hydrogen clouds.', year: '2026',
		primary_color: Color{ r: 255, g: 100, b: 40 }, secondary_color: Color{ r: 140, g: 0, b: 255 }, accent_color: Color{ r: 255, g: 240, b: 180 },
		speed: 1.0, density: 300, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 117, name: 'Quantum Wavepacket Tunneling (Schrödinger)', category: .modern_physics, engine: .engine_wave_interference,
		description: 'Gaussian probability wavepacket barrier tunneling and reflected wave packets.', year: '2026',
		primary_color: Color{ r: 0, g: 255, b: 180 }, secondary_color: Color{ r: 0, g: 80, b: 120 }, accent_color: Color{ r: 255, g: 255, b: 255 },
		speed: 1.1, density: 80, sub_mode: 1
	}
	t << ScreensaverTemplate{
		id: 118, name: 'Magnetic Pendulum Fractal Basins (3-Pole)', category: .modern_physics, engine: .engine_double_pendulum,
		description: 'Chaotic iron pendulum swinging above three magnetic attractor poles.', year: '2026',
		primary_color: Color{ r: 255, g: 50, b: 50 }, secondary_color: Color{ r: 50, g: 255, b: 50 }, accent_color: Color{ r: 50, g: 100, b: 255 },
		speed: 1.0, density: 8, sub_mode: 1
	}

	return t
}

