# 🎮 V Game Arcade Collection — 89 Complete Games in V

[![V Language](https://img.shields.io/badge/Language-V%200.4.x-5D87A8?style=for-the-badge&logo=v&logoColor=white)](https://vlang.io/)
[![Games](https://img.shields.io/badge/Total%20Games-89%20Fully%20Playable-4EC9B0?style=for-the-badge)](screenshots/)
[![Fullscreen](https://img.shields.io/badge/Display-Fullscreen%20Dynamic%20Widescreen-FF8800?style=for-the-badge)](#-universal-controls--widescreen-display)
[![Audio](https://img.shields.io/badge/Audio-Real--Time%20Chiptune%20Synthesis-9933FF?style=for-the-badge)](#-real-time-chiptune-synthesizer)
[![Tests](https://img.shields.io/badge/Tests-89%2F89%20Passing%20(100%25)-brightgreen?style=for-the-badge)](#-running-automated-tests)

Welcome to the **V Game Arcade Collection**! A monumental collection of **89 complete, standalone games and simulations** implemented in the **[V Programming Language](https://vlang.io/)** utilizing hardware-accelerated Sokol graphics (`gg`), real-time procedural chiptune audio synthesis, and dynamic aspect-ratio widescreen scaling with arcade pillarbox wings.

## ✨ Collection Highlights

- **89 Complete Games**: From 1970s coin-op legends and 1990s desktop classics to modern roguelites and virtual pets.
- **100% Native V**: Fast compilation, clean codebases, zero heavy external runtime engines.
- **Universal Widescreen Fullscreen**: Press `` ` `` / `~` (Grave Accent / Tilde) on **any game** to enter full screen. Intelligent letterboxing/pillarboxing with stylized retro arcade wings ensures no monitor space is wasted.
- **Built-in Procedural Audio**: Every game features real-time square, saw, triangle, and noise wave audio synthesis for authentic retro BGM and SFX.
- **Verified Visual Fidelity**: All 89 games have been verified with crisp, full-color fullscreen screenshots showcasing real-time rendering.
- **Full Automated Test Coverage**: Every game has an automated test suite verifying game logic, physics, and state transitions.

## ⌨️ Universal Controls & Widescreen Display

| Key | Action | Description |
| :--- | :--- | :--- |
| **`` ` `` / `~`** *(Grave / Tilde)* | **Toggle Fullscreen** | Seamlessly expands game into fullscreen with zero distorted stretching. |
| **`F10`** | **Cycle Graphics Filter** | Cycle between 4 post-processing profiles: **CRT Pro**, **Cyber Bloom**, **Clean HD**, and **Vintage Amber**. |
| **`M`** | **Toggle Music (BGM)** | Instantly mute or un-mute background procedural chiptune music. |
| **`N`** | **Toggle Sound FX (SFX)** | Instantly mute or un-mute sound effects. |
| **`Esc`** | **Exit Game** | Cleanly exits the game back to terminal. |

> 💡 **Master-Level Audio-Visual Integration & Display Profiles**: Press **`F10`** or click the sleek **`[F10] FX`** badge in the upper-right corner at any time to switch visual modes with an animated glassmorphic HUD notification banner.

### 🎨 Master Graphics Profiles & Visual Suite
- 🕹️ **Arcade CRT Pro** *(Default)*: Authentic **Sony Trinitron / PVM RGB Aperture Grille** vertical phosphor micro-triads, 3px scanline grille, cathode beam electron sweep, curved Trinitron glass bezels, upper specular reflection sheen, floating phosphor dust motes, and real-time audio-reactive wing equalizer visualizer bars.
- ⚡ **Cyber Bloom**: Vibrant pulsing neon boundary rails, dynamic chromatic edge fringing (cyan left, magenta right), and glowing cosmic dust motes.
- 💎 **Clean Modern HD**: Razor-sharp, unfiltered pixel art with minimalist slate pillars for high-DPI modern displays with zero scanlines.
- 📺 **Vintage Amber Phosphor**: 1980s monochrome P31 amber composite monitor warmth overlay with cathode sweep and glass bezels.
- 🌌 **Atmospheric 3D Parallax Starfield**: Three independent depth layers of drifting, twinkling cosmic stars and nebula motes.
- 💥 **Non-Linear Camera Trauma & Shake Engine**: Visceral arcade screen shake decaying quadratically (`trauma * trauma * 20.0f`) with high-impact screen edge flashes on intense events (`prod_fx_trigger_shake`).
- ✨ **Directional Kinetic Spark Debris**: Randomized angular particle ejection with gravity, aerodynamic drag, and cross glare bursts (`prod_fx_trigger_sparks`).
- 🔢 **Floating Combo & Score Popups**: Dynamic ascending score text with drop shadows and fading alpha (`prod_fx_trigger_floating_score`).
- 🌊 **Dynamic Shockwave Rings**: High-energy explosive and impact ripple waves that radiate across the playfield (`prod_fx_trigger_shockwave`).

### 🎵 Master Audio Engine & Acoustic Processing
- 🎚️ **Analog Soft-Saturator Limiter (Zero Digital Audio Clipping)**: Replaced traditional hard clipping (`fclamp(sum, -1.0, 1.0)`) with a rational soft-saturator curve `x / (1.0 + 0.45 * |x|)`. Eliminates harsh digital buzzing artifacts when multiple SFX or BGM chords overlap, producing warm analog console tape/tube saturation.
- 🎛️ **Real-Time Audio-Visual Energy Coupling**: Real-time buffer tracking of acoustic RMS power, peak amplitude attacks, and bass harmonics (`C.set_audio_levels_c`). The cabinet wing equalizer bars physically dance and bounce in sync with the real acoustic waveforms of the game rather than synthetic timer math.
- 🌫️ **Dreamlike Lowpass Filter on Pause**: Single-pole recursive IIR lowpass filter (`g_lpf_state += 0.14f * (sample - g_lpf_state)`) that softens and muffles high frequencies when paused, creating an immersive, high-end console ambiance where music continues to groove gently in the background.
- 🎼 **Procedural Polyphonic Chiptune Synthesis**: High-speed waveform synthesis across all games featuring square, saw, triangle, and white noise voices with dynamic pitch scaling.

## 📑 Category Directory

- [🚀 **Arcade Classics & Space Combat** (15 Games)](#arcade-classics--space-combat) — *Iconic quarter-eating arcade hits, vector shooters, and classic multi-screen adventures.*
- [⚔️ **Action, Platformers & Roguelikes** (14 Games)](#action-platformers--roguelikes) — *Fast-paced platformers, vertical descent combat, bullet heavens, and stealth ninjutsu.*
- [🧩 **Puzzles & Tile Matchers** (16 Games)](#puzzles--tile-matchers) — *Brain-twisting logic puzzles, competitive falling blocks, match-3 cascades, and spatial mazes.*
- [🎱 **Sports, Physics & Precision** (14 Games)](#sports-physics--precision) — *Ballistics, table sports, flippers, billiard elastic collisions, and downhill slope physics.*
- [♟️ **Strategy, Board & Card Games** (13 Games)](#strategy-board--card-games) — *Casino card tables, naval grid deduction, tower defense, and Lemmings puzzle strategy.*
- [🕹️ **Simulation, Arcade Novelties & Brain Games** (17 Games)](#simulation-arcade-novelties--brain-games) — *Virtual pets, audio memory synths, procedural flame engines, and nostalgic simulations.*

## 🚀 Arcade Classics & Space Combat
*Iconic quarter-eating arcade hits, vector shooters, and classic multi-screen adventures.*

### Asteroids

![Asteroids Fullscreen Screenshot](screenshots/asteroids.png)

**Description**: Vector arcade space shooter with true 360-degree Newtonian inertia, rotational thrusters, hyper-space emergency jump, floating space debris, and flying saucers.

- **🎮 Controls**: `Left/Right or A/D to rotate, Up/W to thrust, Space to shoot, Down/S for hyperspace, ~ for Fullscreen`
- **🚀 Run Game**: `v run asteroids`

### Centipede

![Centipede Fullscreen Screenshot](screenshots/centipede.png)

**Description**: Frenetic trackball arcade shooter blasting venomous segmenting centipedes, erratically jumping spiders, poison scorpions, and diving fleas through a mushroom forest.

- **🎮 Controls**: `Arrow keys or Mouse to move bug blaster, Space or Left Click to fire, ~ for Fullscreen`
- **🚀 Run Game**: `v run centipede`

### Codecaine Bros.

![Codecaine Bros. Fullscreen Screenshot](screenshots/codecainebros.png)

**Description**: Classic sewer platformer punching platforms from beneath to flip shellcreepers, sidesteppers, and fighter flies on their backs before kicking them away.

- **🎮 Controls**: `Left/Right or A/D to run, Space to jump, ~ for Fullscreen, M for Music, N for SFX`
- **🚀 Run Game**: `v run codecainebros`

### Codecaine Kong

![Codecaine Kong Fullscreen Screenshot](screenshots/codecainekong.png)

**Description**: Pioneering 1981 platformer climbing sloped construction girders, leaping rolling oil barrels, swinging destruction hammers, and scaling elevators to rescue Pauline.

- **🎮 Controls**: `Left/Right or A/D to walk, Up/Down to climb ladders, Space to jump, ~ for Fullscreen`
- **🚀 Run Game**: `v run codecainekong`

### Codecaine Man

![Codecaine Man Fullscreen Screenshot](screenshots/codecaineman.png)

**Description**: The iconic maze runner with Blinky, Pinky, Inky, and Clyde featuring authentic ghost scatter/chase AI modes, power pellets, corner-cutting, and bonus fruit.

- **🎮 Controls**: `Arrow keys or W/A/S/D to navigate maze turns, ~ for Fullscreen, M for Music, N for SFX`
- **🚀 Run Game**: `v run codecaineman`

### Dig Dug

![Dig Dug Fullscreen Screenshot](screenshots/digdug.png)

**Description**: Subterranean excavation arcade favorite digging underground dirt tunnels, inflating Pookas and fire-breathing Fygars with your air pump, or crushing them under rocks.

- **🎮 Controls**: `Arrow keys or W/A/S/D to dig, Space to pump enemies, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run digdug`

### Frogger

![Frogger Fullscreen Screenshot](screenshots/frogger.png)

**Description**: Classic arcade road-crossing challenge dodging speeding sports cars, freight trucks, and leaping across river logs, alligators, and diving turtles.

- **🎮 Controls**: `Arrow keys or W/A/S/D to hop, ~ for Fullscreen, M for Music, N for SFX`
- **🚀 Run Game**: `v run frogger`

### Galaga

![Galaga Fullscreen Screenshot](screenshots/galaga.png)

**Description**: Classic space fighter with swirling dive-bombing insect alien formations, boss tractor beam ship capture, and dual-fighter firepower mode.

- **🎮 Controls**: `Left/Right or A/D to move, Space to fire missiles, ~ for Fullscreen, M for Music, N for SFX`
- **🚀 Run Game**: `v run galaga`

### Light Cycles (Tron)

![Light Cycles (Tron) Fullscreen Screenshot](screenshots/lightcycles.png)

**Description**: Tron neon virtual grid light cycle duels leaving solid light ribbon trails, trapping rival cyber racers into wall collisions at blazing speeds.

- **🎮 Controls**: `Arrow keys or W/A/S/D to steer 90-degree turns, Space for turbo boost, ~ for Fullscreen`
- **🚀 Run Game**: `v run lightcycles`

### Lunar Lander

![Lunar Lander Fullscreen Screenshot](screenshots/lunarlander.png)

**Description**: Authentic physics-driven lunar descent simulator with fine rotational attitude jets, main throttle thrust, landing gear physics, and jagged lunar terrain pads.

- **🎮 Controls**: `Left/Right or A/D to rotate, Up/W or Space for thrust, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run lunarlander`

### Mappy

![Mappy Fullscreen Screenshot](screenshots/mappy.png)

**Description**: Micro-police mouse bouncing on trampoline floors, opening sonic microwave doors, and retrieving stolen treasures while evading Nyamco and the Mewkies.

- **🎮 Controls**: `Left/Right or A/D to move, Space to open/slam doors, ~ for Fullscreen, M for Music, N for SFX`
- **🚀 Run Game**: `v run mappy`

### Missile Command

![Missile Command Fullscreen Screenshot](screenshots/missilecommand.png)

**Description**: Cold War air-defense classic defending six metropolitan cities and three anti-ballistic missile silos against descending MIRV nuclear warheads and bombers.

- **🎮 Controls**: `Mouse to target reticle, Left Click/1-3 to fire from left/center/right battery, ~ for Fullscreen`
- **🚀 Run Game**: `v run missilecommand`

### Q*Bert

![Q*Bert Fullscreen Screenshot](screenshots/qbert.png)

**Description**: Isometric pyramid hopping arcade masterpiece hopping across isometric cubes to cycle their colors while outsmarting Coily the snake, Ugg, and flying disks.

- **🎮 Controls**: `Diagonal keypad or Q/E/Z/C / Arrows to hop diagonally, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run qbert`

### Sink Sub

![Sink Sub Fullscreen Screenshot](screenshots/sinksub.png)

**Description**: Naval destroyer depth charge challenge dropping timed explosive barrels from surface warships to intercept navigating enemy attack submarines and dodge rising torpedoes.

- **🎮 Controls**: `Left/Right or A/D to steer warship, Z / Left Arrow to drop left depth charge, X / Right Arrow to drop right depth charge, ~ for Fullscreen`
- **🚀 Run Game**: `v run sinksub`

### Space Invaders

![Space Invaders Fullscreen Screenshot](screenshots/spaceinvaders.png)

**Description**: Authentic 1978 arcade recreation with marching alien matrix, UFO mystery ships, destructible protective shields, and accelerating four-note tempo audio.

- **🎮 Controls**: `Left/Right or A/D to move, Space/Up to fire, ~ for Fullscreen, M for Music, N for SFX`
- **🚀 Run Game**: `v run spaceinvaders`

## ⚔️ Action, Platformers & Roguelikes
*Fast-paced platformers, vertical descent combat, bullet heavens, and stealth ninjutsu.*

### Balloon Fight

![Balloon Fight Fullscreen Screenshot](screenshots/balloonfight.png)

**Description**: Balloon buoyancy flight duels with dual-balloon flapping physics, popping enemy balloon parachutes, flipper bumpers, lightning bolts, and giant hungry fish.

- **🎮 Controls**: `Left/Right to steer, Space or Up to flap wings, ~ for Fullscreen, M for Music, N for SFX`
- **🚀 Run Game**: `v run balloonfight`

### Bomberman

![Bomberman Fullscreen Screenshot](screenshots/bomberman.png)

**Description**: Grid-based arena explosive action dropping timed bombs, blasting soft brick blocks, collecting blast radius and bomb count powerups, and trapping enemy wandering creeps.

- **🎮 Controls**: `Arrow keys or W/A/S/D to move, Space to place bomb, ~ for Fullscreen, M for Music, N for SFX`
- **🚀 Run Game**: `v run bomberman`

### Cyber Runner

![Cyber Runner Fullscreen Screenshot](screenshots/cyberrunner.png)

**Description**: High-speed synthwave infinite runner with wall-sliding, low slide dashes, energy pickups, laser barrier dodging, and reactive beat pulses.

- **🎮 Controls**: `Space/Up to jump/double jump, Down/S to slide, ~ for Fullscreen, M for Music, N for SFX`
- **🚀 Run Game**: `v run cyberrunner`

### Downwell

![Downwell Fullscreen Screenshot](screenshots/downwell.png)

**Description**: High-velocity vertical well descent roguelite with explosive gunboots, gem combo streaks, weapon modules (Shotgun, Laser, Machinegun), and procedural depths.

- **🎮 Controls**: `Left/Right or A/D to move, Space/Z to jump and fire gunboots downwards, ~ for Fullscreen`
- **🚀 Run Game**: `v run downwell`

### Duke

![Duke Fullscreen Screenshot](screenshots/duke.png)

**Description**: Nostalgic 90s side-scrolling action platformer packed with heavy artillery, high-tech camera security systems, soda health cans, and cybernetic foes.

- **🎮 Controls**: `Left/Right or A/D to walk, Space to jump, Ctrl/Z to shoot, Up/Down for elevators, ~ for Fullscreen`
- **🚀 Run Game**: `v run duke`

### Flappy Bird

![Flappy Bird Fullscreen Screenshot](screenshots/flappy.png)

**Description**: One-button tap-to-flap airborne endurance arcade phenomenon guiding the flapping yellow bird through jagged green pipe gaps with responsive gravity.

- **🎮 Controls**: `Space or Left Click to flap wings, ~ for Fullscreen, M for Music, N for SFX`
- **🚀 Run Game**: `v run flappy`

### GnuJump

![GnuJump Fullscreen Screenshot](screenshots/gnujump.png)

**Description**: Addictive vertical tower jumping challenge with collapsing ice platforms, trampoline springboards, air combo multipliers, and rising lava.

- **🎮 Controls**: `Left/Right or A/D to steer, Space or Up to jump high, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run gnujump`

### Micro Mayhem

![Micro Mayhem Fullscreen Screenshot](screenshots/micromayhem.png)

**Description**: Chaotic micro-action arena shooter with randomized rapid-fire mini-arenas, weapon powerups, and intensifying enemy waves.

- **🎮 Controls**: `W/A/S/D to move, Mouse/Arrows to aim and shoot, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run micromayhem`

### Nuclear Throne

![Nuclear Throne Fullscreen Screenshot](screenshots/nuclearthrone.png)

**Description**: Post-apocalyptic top-down wasteland roguelike with mutant abilities, radioactive canister pickups, destructive weaponry, and screen-shaking combat.

- **🎮 Controls**: `W/A/S/D to move, Mouse to aim reticle, Left Click to fire, Right Click for mutant active ability, ~ for Fullscreen`
- **🚀 Run Game**: `v run nuclearthrone`

### Shinobi

![Shinobi Fullscreen Screenshot](screenshots/shinobi.png)

**Description**: Sega ninja arcade action throwing razor-sharp shurikens, close-range sword katas, double jumping to high scaffolding, rescuing hostages, and unleashing screen-clearing Ninjutsu.

- **🎮 Controls**: `Arrow keys to move, Z to throw shuriken/slash, X to jump, C for Ninjutsu magic, ~ for Fullscreen`
- **🚀 Run Game**: `v run shinobi`

### Side Scroller

![Side Scroller Fullscreen Screenshot](screenshots/sidescroller.png)

**Description**: Classic horizontal space shmup featuring multi-tier weapon upgrades, shield drones, multi-layered parallax starfields, and colossal mechanical flagship bosses.

- **🎮 Controls**: `W/A/S/D or Arrows to fly starship, Space to fire plasma lasers, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run sidescroller`

### TowerFall

![TowerFall Fullscreen Screenshot](screenshots/towerfall.png)

**Description**: Intense archery platform arena featuring lethal one-hit arrow shots, wall jumping, dodge-roll arrow catching, and tactical quiver management.

- **🎮 Controls**: `A/D to run, W to aim up, S to duck/drop through platforms, Space to jump, J/K to shoot/dodge roll, ~ for Fullscreen`
- **🚀 Run Game**: `v run towerfall`

### Vampire Survivors

![Vampire Survivors Fullscreen Screenshot](screenshots/vampiresurvivors.png)

**Description**: Gothic horror auto-firing bullet heaven surviving endless tides of bats, zombies, skeletons, and bosses with weapon evolutions, gem magnets, and chests.

- **🎮 Controls**: `Arrow keys or W/A/S/D to move, Space to dash, ~ for Fullscreen, M for Music, N for SFX`
- **🚀 Run Game**: `v run vampiresurvivors`

### World Runner

![World Runner Fullscreen Screenshot](screenshots/worldrunner.png)

**Description**: Pseudo-3D forward-scrolling cosmic runner jumping over planetary chasms, collecting invincible power stars, and blasting alien monuments.

- **🎮 Controls**: `Left/Right or A/D to steer, Space to jump over chasms, Up to accelerate, ~ for Fullscreen`
- **🚀 Run Game**: `v run worldrunner`

## 🧩 Puzzles & Tile Matchers
*Brain-twisting logic puzzles, competitive falling blocks, match-3 cascades, and spatial mazes.*

### Bejeweled

![Bejeweled Fullscreen Screenshot](screenshots/bejeweled.png)

**Description**: Classic match-3 gem swapping puzzle with sparkling cascades, explosive Flame Gems, screen-clearing Star Gems, and multi-color Hypercubes.

- **🎮 Controls**: `Mouse click/drag to swap adjacent gems, ~ for Fullscreen, M for Music, N for SFX`
- **🚀 Run Game**: `v run bejeweled`

### Block Dude

![Block Dude Fullscreen Screenshot](screenshots/blockdude.png)

**Description**: Beloved TI-83 graphing calculator puzzle carrying, lifting, and stacking heavy bricks across vertical chasms to reach the exit doorway.

- **🎮 Controls**: `Left/Right to move, Up/Down to climb/pick up block, Space to drop block, ~ for Fullscreen`
- **🚀 Run Game**: `v run blockdude`

### Bubble Shooter

![Bubble Shooter Fullscreen Screenshot](screenshots/bubbleshooter.png)

**Description**: Angle-aiming bubble cannon bouncing spheres off walls to match 3+ bubbles, severing hanging clusters, and clearing descending ceilings.

- **🎮 Controls**: `Mouse to aim cannon trajectory, Left Click or Space to launch bubble, ~ for Fullscreen`
- **🚀 Run Game**: `v run bubbleshooter`

### Chip's Challenge

![Chip's Challenge Fullscreen Screenshot](screenshots/chipschallenge.png)

**Description**: Top-down tile puzzle gathering computer microchips, collecting fire boots, water flippers, ice skates, pushing blocks, and unlocking colored socket doors.

- **🎮 Controls**: `Arrow keys or W/A/S/D to move Chip, R to retry level, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run chipschallenge`

### Columns

![Columns Fullscreen Screenshot](screenshots/columns.png)

**Description**: Sega arcade gem matching puzzle dropping 3-gem vertical pillars, cycling jewelry colors in mid-air, and triggering diagonal, horizontal, and vertical sparkles.

- **🎮 Controls**: `Left/Right to steer column, Up/Space to cycle gem colors, Down to drop faster, ~ for Fullscreen`
- **🚀 Run Game**: `v run columns`

### Dr. Codecaine

![Dr. Codecaine Fullscreen Screenshot](screenshots/drcodecaine.png)

**Description**: Medical pill-sorting puzzle eradicating red, blue, and yellow viruses by aligning matching vitamin capsules with cascading chain reactions.

- **🎮 Controls**: `Left/Right to position pill, Up/Z/X to rotate capsule orientation, Down for fast drop, ~ for Fullscreen`
- **🚀 Run Game**: `v run drcodecaine`

### Klax

![Klax Fullscreen Screenshot](screenshots/klax.png)

**Description**: 1989 Atari isometric puzzle catching tumbling colored tiles on a paddle conveyor belt and flipping them into a 5x5 bin to form lines (Klaxes) in 3 dimensions.

- **🎮 Controls**: `Left/Right or A/D to steer paddle, Space/Down to flip tile into bin, Up to push back, ~ for Fullscreen`
- **🚀 Run Game**: `v run klax`

### Adventures of Lolo

![Adventures of Lolo Fullscreen Screenshot](screenshots/lolo.png)

**Description**: Classic HAL Laboratory puzzle adventure pushing Emerald Frames, collecting Heart Framers to power your Magic Shot, and sealing Medusa gaze beams.

- **🎮 Controls**: `Arrow keys or W/A/S/D to move, Space to shoot egg shot, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run lolo`

### Panel de Pon

![Panel de Pon Fullscreen Screenshot](screenshots/paneldepon.png)

**Description**: Furious horizontal tile-swapping puzzle (Puzzle League / Tetris Attack) with rising stacks, freeze timers, skill chains, and cascading clears.

- **🎮 Controls**: `Arrow keys or W/A/S/D to move cursor, Space/Z to swap tiles, Up to raise stack manually, ~ for Fullscreen`
- **🚀 Run Game**: `v run paneldepon`

### Picross

![Picross Fullscreen Screenshot](screenshots/picross.png)

**Description**: Nonogram picture logic grid deducing filled and empty cells from row/column numerical clues to reveal beautiful retro pixel art drawings.

- **🎮 Controls**: `Arrow keys or Mouse to select cell, Left Click/Z to fill, Right Click/X to place cross mark, ~ for Fullscreen`
- **🚀 Run Game**: `v run picross`

### Puyo Puyo

![Puyo Puyo Fullscreen Screenshot](screenshots/puyopuyo.png)

**Description**: Iconic Japanese competitive blob puzzle featuring squash-and-stretch jelly slime physics, gravity drops, giant chain reaction combos, and garbage puyo avalanches.

- **🎮 Controls**: `Left/Right to move pair, Up/X to rotate, Down to soft drop, Space to drop instant, ~ for Fullscreen`
- **🚀 Run Game**: `v run puyopuyo`

### Puzzle Fighter

![Puzzle Fighter Fullscreen Screenshot](screenshots/puzzlefighter.png)

**Description**: Arcade fighting puzzle fusion dropping regular and crash gems, building colossal power gems, and triggering devastating counter-gem avalanches.

- **🎮 Controls**: `Left/Right to steer gem pair, Up/Z/X to rotate, Down to drop fast, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run puzzlefighter`

### SameGame

![SameGame Fullscreen Screenshot](screenshots/samegame.png)

**Description**: Strategic tile elimination puzzle selecting large contiguous clusters of matching colored blocks, causing columns to collapse inward toward an empty board.

- **🎮 Controls**: `Mouse click on color group to select and pop, R to reset, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run samegame`

### Sokoban

![Sokoban Fullscreen Screenshot](screenshots/sokoban.png)

**Description**: Pure spatial logic warehouse puzzle navigating narrow brick labyrinths to push wooden crates onto designated storage target diamonds without getting stuck.

- **🎮 Controls**: `Arrow keys or W/A/S/D to push crates, U to undo move, R to restart level, ~ for Fullscreen`
- **🚀 Run Game**: `v run sokoban`

### Tetris

![Tetris Fullscreen Screenshot](screenshots/tetris.png)

**Description**: World-class competitive tetromino puzzle with Guideline 7-bag randomizer, Super Rotation System (SRS) wall kicks, ghost piece guide, hold box, and line fanfare.

- **🎮 Controls**: `Left/Right to move, Up/X to rotate clockwise, Z to rotate CCW, Down for soft drop, Space for hard drop, C to hold, ~ for Fullscreen`
- **🚀 Run Game**: `v run tetris`

### Zuma

![Zuma Fullscreen Screenshot](screenshots/zuma.png)

**Description**: Ancient stone frog idol rotating 360 degrees to fire colored spheres into an advancing spiral chain, triggering reverse chains and accuracy multipliers.

- **🎮 Controls**: `Mouse to rotate frog aiming, Left Click to fire ball, Right Click/Space to swap next ball color, ~ for Fullscreen`
- **🚀 Run Game**: `v run zuma`

## 🎱 Sports, Physics & Precision
*Ballistics, table sports, flippers, billiard elastic collisions, and downhill slope physics.*

### Air Hockey

![Air Hockey Fullscreen Screenshot](screenshots/airhockey.png)

**Description**: Arcade air hockey table simulation with zero-friction cushioned puck physics, high-velocity mallet strikes, bank shots, and responsive goal detectors.

- **🎮 Controls**: `Mouse to control paddle mallet, ~ for Fullscreen, M for Music, N for SFX`
- **🚀 Run Game**: `v run airhockey`

### Bowling

![Bowling Fullscreen Screenshot](screenshots/bowling.png)

**Description**: 10-pin bowling alley simulation with positioning line, release timing, hook spin curves, full pin-to-pin kinetic collisions, spares, and strikes.

- **🎮 Controls**: `Left/Right to position bowler, Space to lock power and spin meters, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run bowling`

### Breakout

![Breakout Fullscreen Screenshot](screenshots/breakout.png)

**Description**: Brick-busting arcade action with multi-tier rainbow brick layers, ball speed tiers, angle deflection physics, and multi-ball bonus capsules.

- **🎮 Controls**: `Left/Right or Mouse to position paddle, Space to launch ball, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run breakout`

### Darts

![Darts Fullscreen Screenshot](screenshots/darts.png)

**Description**: Championship pub dartboard simulation with natural wind sway drift, 501 countdown rules, triple rings, bullseye targeting, and double-out checkout.

- **🎮 Controls**: `Mouse to steady dart reticle, Hold Left Click for power gauge, Release to throw, ~ for Fullscreen`
- **🚀 Run Game**: `v run darts`

### JezzBall

![JezzBall Fullscreen Screenshot](screenshots/jezzball.png)

**Description**: Windows 95 classic containing bouncing atoms by constructing horizontal and vertical forcefield partition walls to seal off 75% of the arena.

- **🎮 Controls**: `Mouse to position line cursor, Left Click to build wall, Right Click/Space to toggle horizontal/vertical wall orientation, ~ for Fullscreen`
- **🚀 Run Game**: `v run jezzball`

### Marble Madness

![Marble Madness Fullscreen Screenshot](screenshots/marblemadness.png)

**Description**: 1984 Atari isometric arcade masterpiece rolling through dizzying 3D geometric courses with momentum physics, cliffs, tubes, catapults, and marble enemies.

- **🎮 Controls**: `Arrow keys or W/A/S/D to guide marble roll, Space for speed boost jump, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run marblemadness`

### Peggle

![Peggle Fullscreen Screenshot](screenshots/peggle.png)

**Description**: Pachinko physics ball launcher aiming for orange target pegs, dynamic guide trajectory line, free-ball moving catcher bucket, and Extreme Fever euphoria.

- **🎮 Controls**: `Mouse to aim ball launcher, Left Click or Space to shoot, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run peggle`

### Pinball

![Pinball Fullscreen Screenshot](screenshots/pinball.png)

**Description**: Full-table physics pinball machine featuring spring plunger, dual flippers, high-score bumpers, drop targets, ramps, slingshots, and multi-ball frenzy.

- **🎮 Controls**: `Z / Left Shift for Left Flipper, / / Right Shift for Right Flipper, Down/Space to pull plunger, ~ for Fullscreen`
- **🚀 Run Game**: `v run pinball`

### Pong

![Pong Fullscreen Screenshot](screenshots/pong.png)

**Description**: The 1972 video game pioneer with analog paddle deflection physics, CRT phosphorus scanlines, variable rally acceleration, and responsive AI.

- **🎮 Controls**: `W/S for Player 1, Up/Down for Player 2 / vs AI, ~ for Fullscreen, M for Music, N for SFX`
- **🚀 Run Game**: `v run pong`

### 8-Ball Pool

![8-Ball Pool Fullscreen Screenshot](screenshots/pool.png)

**Description**: Overhead billiards simulation with fine cue stick aiming line, variable stroke power, ball-to-ball elastic momentum transfer, and 6-pocket collision physics.

- **🎮 Controls**: `Mouse to aim cue, Click and pull back to gauge shot power, Release to strike, ~ for Fullscreen`
- **🚀 Run Game**: `v run pool`

### Racer

![Racer Fullscreen Screenshot](screenshots/racer.png)

**Description**: Pseudo-3D sprite scaler retro road racing with winding asphalt curves, rolling hills, rival car traffic, roadside billboards, and turbo boost.

- **🎮 Controls**: `Left/Right or A/D to steer, Up/W to accelerate, Down/S to brake, Space for turbo nitro, ~ for Fullscreen`
- **🚀 Run Game**: `v run racer`

### Ragdoll

![Ragdoll Fullscreen Screenshot](screenshots/ragdoll.png)

**Description**: Verlet physics sandbox simulator with interactive skeletal joint constraints, gravity toggles, interactive mouse dragging, obstacle bouncing, and momentum transfer.

- **🎮 Controls**: `Left Click and drag joints with mouse, G to toggle gravity, R to reset ragdoll, ~ for Fullscreen`
- **🚀 Run Game**: `v run ragdoll`

### Scorched Earth

![Scorched Earth Fullscreen Screenshot](screenshots/scorchedearth.png)

**Description**: The mother of all artillery tank games calculating elevation angles, turret velocity, variable wind drift, and destructive ballistic weapon payloads across jagged hills.

- **🎮 Controls**: `Left/Right to aim turret angle, Up/Down to adjust muzzle velocity, Space to fire cannon, Tab to cycle weapons, ~ for Fullscreen`
- **🚀 Run Game**: `v run scorchedearth`

### SkiFree

![SkiFree Fullscreen Screenshot](screenshots/skifree.png)

**Description**: Retro downhill skiing slalom weaving past pine trees, mogul jumps, dog walkers, and accelerating into warp speed to outrun the terrifying Abominable Snow Monster.

- **🎮 Controls**: `Left/Right or A/D to steer skis, Down/W to tuck for speed, Space to jump over obstacles, ~ for Fullscreen`
- **🚀 Run Game**: `v run skifree`

## ♟️ Strategy, Board & Card Games
*Casino card tables, naval grid deduction, tower defense, and Lemmings puzzle strategy.*

### Battleship

![Battleship Fullscreen Screenshot](screenshots/battleship.png)

**Description**: Naval grid warfare hunting hidden aircraft carriers, battleships, cruisers, submarines, and destroyers with radar pinging and hit detection.

- **🎮 Controls**: `Mouse Click on grid to target naval missile salvo, R to rotate ships during placement, ~ for Fullscreen`
- **🚀 Run Game**: `v run battleship`

### Blackjack 21

![Blackjack 21 Fullscreen Screenshot](screenshots/blackjack.png)

**Description**: Casino table blackjack with dealer stand on soft 17, double down, split pairs, insurance, chips betting, and realistic shoe shuffle.

- **🎮 Controls**: `H to Hit, S to Stand, D to Double, P to Split, 1-4 to choose bet chips, ~ for Fullscreen`
- **🚀 Run Game**: `v run blackjack`

### Connect 4

![Connect 4 Fullscreen Screenshot](screenshots/connect4.png)

**Description**: Classic vertical four-in-a-row chip drop game with gravitational column drops, win animations, and challenging minimax AI opponent.

- **🎮 Controls**: `Keys 1-7 or Mouse Click on columns to drop chip, ~ for Fullscreen, M for Music, N for SFX`
- **🚀 Run Game**: `v run connect4`

### Dope Wars

![Dope Wars Fullscreen Screenshot](screenshots/dopewars.png)

**Description**: Cult 1984 financial commodity simulation traveling through city boroughs, buying low and selling high, evading loan shark interest, and upgrading coat capacity.

- **🎮 Controls**: `Number keys and Arrow keys to navigate menu options, buy, sell, and travel, ~ for Fullscreen`
- **🚀 Run Game**: `v run dopewars`

### Lemmings

![Lemmings Fullscreen Screenshot](screenshots/lemmings.png)

**Description**: Psygnosis 1991 puzzle strategy assigning climbers, floaters, bombers, blockers, builders, bashers, miners, and diggers to guide green-haired lemmings to safety.

- **🎮 Controls**: `1-8 to select skill, Mouse to hover and click lemming to assign, Space to pause, N to nuke, ~ for Fullscreen`
- **🚀 Run Game**: `v run lemmings`

### Liar's Dice

![Liar's Dice Fullscreen Screenshot](screenshots/liarsdice.png)

**Description**: High-stakes pirate bluffing and probability deduction game bidding on total dice faces under cups and calling bluffs (Dudo).

- **🎮 Controls**: `Up/Down to change bid quantity, Left/Right for die face, Enter to make bid, L to call Liar, ~ for Fullscreen`
- **🚀 Run Game**: `v run liarsdice`

### Minesweeper

![Minesweeper Fullscreen Screenshot](screenshots/minesweeper.png)

**Description**: Authentic Windows minefield deduction with recursive zero-flood uncovering, flag placements, question marks, mine counter, and timer.

- **🎮 Controls**: `Left Click to uncover cell, Right Click to toggle flag marker, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run minesweeper`

### Reversi / Othello

![Reversi / Othello Fullscreen Screenshot](screenshots/reversi.png)

**Description**: Timeless 8x8 territorial board game flanking and flipping opponent discs between your stones, featuring valid move highlights and intelligent AI.

- **🎮 Controls**: `Mouse Click on valid highlighted square to place disc, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run reversi`

### Retro Slot Machine

![Retro Slot Machine Fullscreen Screenshot](screenshots/slots.png)

**Description**: Vintage 3-reel mechanical casino slot machine with lucky sevens, bars, cherries, bells, variable paylines, and animated arm pull.

- **🎮 Controls**: `Space or Enter to pull lever/spin reels, 1-3 to set bet paylines, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run slots`

### Texas Hold'em Poker

![Texas Hold'em Poker Fullscreen Screenshot](screenshots/texas.png)

**Description**: No-limit Texas Hold'em table with blind structures, Flop/Turn/River community cards, pot calculation, hand ranker, and varied AI betting personalities.

- **🎮 Controls**: `C to Check/Call, B to Bet/Raise, F to Fold, Up/Down to adjust bet amount, ~ for Fullscreen`
- **🚀 Run Game**: `v run texas`

### Tower Defense

![Tower Defense Fullscreen Screenshot](screenshots/towerdefense.png)

**Description**: Strategic path defense placing upgradeable Gatling, Cannon, Laser, and Cryo turrets to repel escalating waves of enemy creeps and armored bosses.

- **🎮 Controls**: `1-4 to select turret type, Mouse Click on map to build/upgrade tower, Space to start next wave, ~ for Fullscreen`
- **🚀 Run Game**: `v run towerdefense`

### War

![War Fullscreen Screenshot](screenshots/war.png)

**Description**: Traditional high-stakes card battle game with rapid card flips, simultaneous rank ties, and multi-card War resolution face-downs.

- **🎮 Controls**: `Space or Left Click to draw and flip cards, ~ for Fullscreen, M for Music, N for SFX`
- **🚀 Run Game**: `v run war`

### Yahtzee

![Yahtzee Fullscreen Screenshot](screenshots/yahtzee.png)

**Description**: Classic 5-dice scoring game with 3 rolls per turn, holding favorable dice, and strategic upper/lower section scoring (Full House, Straights, Yahtzee).

- **🎮 Controls**: `Space to roll dice, 1-5 to hold/unhold dice, Mouse Click to select scorecard category, ~ for Fullscreen`
- **🚀 Run Game**: `v run yahtzee`

## 🕹️ Simulation, Arcade Novelties & Brain Games
*Virtual pets, audio memory synths, procedural flame engines, and nostalgic simulations.*

### Boulder Dash

![Boulder Dash Fullscreen Screenshot](screenshots/boulderdash.png)

**Description**: Subterranean cavern spelunker digging dirt, collecting sparkling diamonds, dodging heavy rolling boulders, and trapping exploding fireflies.

- **🎮 Controls**: `Arrow keys or W/A/S/D to dig and move Rockford, Space + Direction to dig without moving, ~ for Fullscreen`
- **🚀 Run Game**: `v run boulderdash`

### Chimp Test

![Chimp Test Fullscreen Screenshot](screenshots/chimptest.png)

**Description**: Primate working-memory benchmark testing immediate photographic recall of numbered square tile locations before they are hidden.

- **🎮 Controls**: `Mouse Click on numbered tiles in ascending numerical order, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run chimptest`

### Click Arcade

![Click Arcade Fullscreen Screenshot](screenshots/clickarcade.png)

**Description**: High-intensity reaction speed clicker challenging rapid-fire reflex targets, vanishing gold coins, bomb traps, and combo multiplier streaks.

- **🎮 Controls**: `Mouse Click on targets before they expire, ~ for Fullscreen, M for Music, N for SFX`
- **🚀 Run Game**: `v run clickarcade`

### Etch-A-Sketch

![Etch-A-Sketch Fullscreen Screenshot](screenshots/etchasketch.png)

**Description**: Dual-knob mechanical drawing toy simulator with continuous line stylus, color pen options, and shake-to-erase screen clearing.

- **🎮 Controls**: `Arrow keys or W/A/S/D or Mouse drag to turn knobs, Space/R to shake and erase drawing, ~ for Fullscreen`
- **🚀 Run Game**: `v run etchasketch`

### DOOM Fire Simulation

![DOOM Fire Simulation Fullscreen Screenshot](screenshots/fire.png)

**Description**: The legendary 1993 DOOM PSX procedural flame rasterizer with rising thermal convection, random decay dispersal, and glowing 256-color heat palette.

- **🎮 Controls**: `Up/Down to increase/decrease fire intensity, Space to toggle wind, ~ for Fullscreen`
- **🚀 Run Game**: `v run fire`

### 2048

![2048 Fullscreen Screenshot](screenshots/game2048.png)

**Description**: Addictive sliding numeric tile puzzle merging identical powers of two to reach the legendary 2048 golden tile with smooth slide animations.

- **🎮 Controls**: `Arrow keys or W/A/S/D to slide and merge tiles, U to undo move, R to restart, ~ for Fullscreen`
- **🚀 Run Game**: `v run game2048`

### Gold Miner

![Gold Miner Fullscreen Screenshot](screenshots/goldminer.png)

**Description**: Swinging pendulum reel claw winch aiming for glittering gold nuggets, secret cash bags, and avoiding heavy time-wasting rocks before time expires.

- **🎮 Controls**: `Down or Space to fire winch claw downward, Up for dynamite stick, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run goldminer`

### Math Munchers

![Math Munchers Fullscreen Screenshot](screenshots/mathmunchers.png)

**Description**: 90s educational arcade classic guiding the green Muncher to chomp multiples, factors, and primes while evading the wandering Troggles.

- **🎮 Controls**: `Arrow keys or W/A/S/D to move across grid, Space to chomp number tile, ~ for Fullscreen`
- **🚀 Run Game**: `v run mathmunchers`

### Memory Match

![Memory Match Fullscreen Screenshot](screenshots/memorymatch.png)

**Description**: Concentration card-flipping brain game matching identical icon pairs across grid layouts under time constraints with combo scoring.

- **🎮 Controls**: `Mouse Click on cards to flip and match pairs, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run memorymatch`

### Rain Simulation

![Rain Simulation Fullscreen Screenshot](screenshots/rain.png)

**Description**: Ambient ripple water simulation with tranquil falling raindrops, refractive puddles, fluid physics, and soothing nature ambiance.

- **🎮 Controls**: `Mouse click/drag to stir water surface ripples, Space to toggle storm intensity, ~ for Fullscreen`
- **🚀 Run Game**: `v run rain`

### Rodent's Revenge

![Rodent's Revenge Fullscreen Screenshot](screenshots/rodentsrevenge.png)

**Description**: Windows Entertainment Pack classic maneuvering a mouse to push cheese blocks to completely surround and transform predatory cats into cheese wedges.

- **🎮 Controls**: `Arrow keys or W/A/S/D to push blocks, ~ for Fullscreen, M for Music, N for SFX`
- **🚀 Run Game**: `v run rodentsrevenge`

### Mystify Screensaver

![Mystify Screensaver Fullscreen Screenshot](screenshots/screensaver.png)

**Description**: Hypnotic 90s vector polyline screensaver bouncing color-shifting lines and geometric ribbons across the cosmic void with trail physics.

- **🎮 Controls**: `Space to randomize polyline physics, C to cycle color palette, ~ for Fullscreen`
- **🚀 Run Game**: `v run screensaver`

### Cyber Simon

![Cyber Simon Fullscreen Screenshot](screenshots/simon.png)

**Description**: Electronic four-tone memory sequence synthesizer with escalating speeds, reactive neon quadrant pads, 7-segment LED display, and audio VU strobe rim.

- **🎮 Controls**: `Q/W/A/S or 1/2/3/4 or Mouse Click on pads, Space to start sequence, M for Mode, ~ for Fullscreen`
- **🚀 Run Game**: `v run simon`

### Snake

![Snake Fullscreen Screenshot](screenshots/snake.png)

**Description**: Nokia 3310 arcade snake growing longer with every apple consumed without crashing into perimeter walls or your own slithering tail.

- **🎮 Controls**: `Arrow keys or W/A/S/D to change direction, ~ for Fullscreen, M for Music, N for SFX`
- **🚀 Run Game**: `v run snake`

### Tamagotchi 1996

![Tamagotchi 1996 Fullscreen Screenshot](screenshots/tamagotchi.png)

**Description**: Authentic egg-shaped virtual pet keychain simulation with LCD dot matrix screen, feeding meals/snacks, playing guessing mini-games, cleaning messes, and evolutionary stages.

- **🎮 Controls**: `A / Left to navigate icon bar, B / Space to select, C / Esc to cancel, 1-3 to click rubber buttons, ~ for Fullscreen`
- **🚀 Run Game**: `v run tamagotchi`

### Arcade Trivia

![Arcade Trivia Fullscreen Screenshot](screenshots/trivia.png)

**Description**: Fast-paced trivia game show testing your knowledge across gaming history, science, pop culture, geography, and cinema under a ticking clock.

- **🎮 Controls**: `1-4 or A-D to select answer, Space for next question, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run trivia`

### Typing Attack

![Typing Attack Fullscreen Screenshot](screenshots/typing.png)

**Description**: Word-defense arcade typing shooter vaporizing descending alien spacecraft by typing their inscribed words quickly and accurately.

- **🎮 Controls**: `Type words on your keyboard to target and fire laser cannons, ~ for Fullscreen, M for Music`
- **🚀 Run Game**: `v run typing`

## 🛠️ How to Build and Run

### Prerequisites
Install the V programming language from [vlang.io](https://vlang.io/) or via package manager:

**macOS (Homebrew):**
```bash
brew install v
# Verify V is installed:
v version
```

**Ubuntu / Debian (APT):**
Install the necessary C compiler, audio (`libasound2-dev`, `pipewire-alsa`), OpenGL, and X11 development headers:
```bash
sudo apt update
sudo apt install -y build-essential libasound2-dev libasound2-plugins pipewire-alsa libgl1-mesa-dev libx11-dev libxi-dev libxcursor-dev

# If using Homebrew on Linux (Linuxbrew), ensure ALSA finds the system PipeWire audio plugin:
mkdir -p /home/linuxbrew/.linuxbrew/lib/alsa-lib
ln -sf /usr/lib/*-linux-gnu/alsa-lib/* /home/linuxbrew/.linuxbrew/lib/alsa-lib/

# Verify V is installed:
v version
```

> **Tip for Linux**: Run with `v -cc cc run <game>` to directly use the system GCC compiler and bypass TCC warnings.

### Running Any Game Directly
To launch any game immediately, run `v run` followed by the game folder:
```bash
# Examples:
v run balloonfight
v run simon
v run lemmings
v run marblemadness
v run tamagotchi
```

### Compiling Optimized Release Binaries
To compile an optimized, standalone binary for maximum performance:
```bash
v -prod -o bin/balloonfight balloonfight
./bin/balloonfight
```

## 🧪 Running Automated Tests

Every game includes dedicated automated test suites verifying gameplay logic, collision physics, state management, and score tracking:
```bash
# Run a single game's tests:
v test balloonfight/balloonfight_test.v

# Run all test suites across all 89 games:
python3 -c "
import os, subprocess
for d in sorted(os.listdir('.')):
    t = os.path.join(d, f'{d}_test.v')
    if os.path.exists(t):
        subprocess.run(['v', 'test', t], check=True)
"
```

---
### 🏆 Made with ❤️ in V
Built with speed, simplicity, and pure gaming fun.