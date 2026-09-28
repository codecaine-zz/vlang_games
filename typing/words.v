module main

import rand

const short_words = [
	'ace', 'act', 'aim', 'air', 'arc', 'arm', 'ash', 'axe',
	'bad', 'bar', 'bat', 'bay', 'bed', 'bin', 'bit', 'bot', 'box', 'bug', 'bus',
	'cab', 'can', 'cap', 'cat', 'cog', 'cup', 'cut',
	'dam', 'day', 'dig', 'dim', 'dog', 'dot', 'dry', 'due',
	'ear', 'eat', 'egg', 'ego', 'end', 'era', 'eye',
	'fan', 'far', 'fit', 'fix', 'fly', 'fog', 'fox', 'fun',
	'gap', 'gas', 'gem', 'gig', 'glow', 'gnu', 'grid', 'gun', 'gut',
	'hat', 'hex', 'hit', 'hop', 'hot', 'hub', 'hut',
	'ice', 'ink', 'ion', 'ivy',
	'jam', 'jar', 'jaw', 'jet', 'job', 'jog', 'joy',
	'key', 'kid', 'kit',
	'lab', 'lap', 'law', 'led', 'leg', 'lid', 'lip', 'log', 'lot',
	'map', 'mat', 'mix', 'mud', 'mug',
	'net', 'new', 'nod', 'now', 'nut',
	'oak', 'oar', 'odd', 'oil', 'old', 'one', 'opt', 'orb', 'owl',
	'pad', 'pan', 'pat', 'paw', 'peg', 'pen', 'pet', 'pie', 'pin', 'pit', 'pod', 'pop', 'pot',
	'rag', 'ram', 'ran', 'raw', 'ray', 'red', 'rib', 'rim', 'rip', 'rod', 'row', 'rug', 'run',
	'sad', 'sap', 'sea', 'set', 'sin', 'sip', 'sir', 'sit', 'six', 'sky', 'sun',
	'tab', 'tag', 'tap', 'tar', 'tea', 'ten', 'tie', 'tin', 'tip', 'toe', 'top', 'toy', 'two',
	'urn', 'use',
	'van', 'vat', 'vet', 'via',
	'war', 'wax', 'web', 'wet', 'wig', 'win', 'wire',
	'yak', 'yes', 'yet',
	'zap', 'zen', 'zip', 'zoo',
	'acid', 'atom', 'base', 'beam', 'beta', 'bolt', 'byte', 'chip', 'core', 'cyan',
	'data', 'disk', 'dock', 'echo', 'flux', 'gate', 'gear', 'grid', 'halo', 'hash',
	'idle', 'iron', 'jump', 'laser', 'link', 'lock', 'loop', 'mask', 'mesh', 'mega',
	'nano', 'neon', 'node', 'nova', 'orbit', 'pack', 'path', 'ping', 'plot', 'port',
	'pulse', 'quad', 'race', 'raid', 'ramp', 'rank', 'ray', 'ring', 'risk', 'root',
	'scan', 'ship', 'slot', 'spark', 'star', 'sync', 'task', 'tech', 'warp', 'zero',
]

const medium_words = [
	'action', 'active', 'adapter', 'advance', 'algebra', 'altitude', 'analyst',
	'antenna', 'arcade', 'archive', 'array', 'artifact', 'asteroid', 'battery',
	'beacon', 'binary', 'booster', 'buffer', 'capsule', 'carrier', 'channel',
	'chassis', 'circuit', 'cluster', 'cockpit', 'command', 'complex', 'compute',
	'console', 'control', 'counter', 'cruiser', 'crystal', 'current', 'decoder',
	'defense', 'density', 'diagram', 'digital', 'display', 'divider', 'dynamic',
	'eclipse', 'element', 'emitter', 'encoder', 'engine', 'entropy', 'execute',
	'factory', 'filter', 'firewall', 'fission', 'flight', 'fractal', 'frequency',
	'furnace', 'galaxy', 'gateway', 'generator', 'glitch', 'gravity', 'guidance',
	'hardware', 'horizon', 'hybrid', 'impulse', 'infinity', 'ingress', 'injector',
	'integer', 'intercom', 'junction', 'keyboard', 'kinetic', 'launcher', 'loading',
	'logic', 'magnetic', 'matrix', 'measure', 'mechanism', 'mission', 'module',
	'monitor', 'mutation', 'network', 'neutron', 'nuclear', 'nucleus', 'numeric',
	'optical', 'orbit', 'output', 'package', 'particle', 'payload', 'percept',
	'phantom', 'physics', 'pioneer', 'pipeline', 'plasma', 'platform', 'polygon',
	'process', 'program', 'propel', 'protocol', 'pulsar', 'quantum', 'quasar',
	'radiant', 'reactor', 'reflector', 'repeater', 'resource', 'rocket', 'rotation',
	'satellite', 'scanner', 'science', 'segment', 'sensor', 'sequence', 'shield',
	'signal', 'silicon', 'software', 'spectrum', 'station', 'stellar', 'subspace',
	'surface', 'terminal', 'thermal', 'thruster', 'titanium', 'torpedo', 'tracker',
	'transit', 'traverse', 'trigger', 'turbine', 'universe', 'upgrade', 'vacuum',
	'vector', 'velocity', 'venture', 'virtual', 'voltage', 'vortex', 'voyager',
]

const long_boss_words = [
	'acceleration', 'aerodynamics', 'annihilation', 'antimatter', 'architecture',
	'astronautical', 'astrophysics', 'biodiversity', 'calculations', 'capacitance',
	'chromatography', 'classification', 'communication', 'computational', 'configuration',
	'constellation', 'cryptography', 'cybernetics', 'deceleration', 'deconstruction',
	'destabilizer', 'disintegration', 'electromagnet', 'environmental', 'extrapolate',
	'gravitational', 'hypervelocity', 'illumination', 'infrastructure', 'interstellar',
	'jurisdiction', 'luminescence', 'magnetometer', 'microprocessor', 'nanotechnology',
	'neutralization', 'photosynthesis', 'predetermined', 'quantization', 'recalibration',
	'reconnaissance', 'refrigeration', 'semiconductor', 'serialization', 'singularity',
	'stratosphere', 'supercomputer', 'superconductor', 'teleportation', 'thermodynamic',
	'transformation', 'transmutation', 'triangulation', 'turbopump', 'visualization',
]

const code_words = [
	'allocate', 'argument', 'assert', 'async', 'atomic', 'benchmark', 'binary',
	'boolean', 'bracket', 'buffer', 'callback', 'channel', 'closure', 'compiler',
	'constant', 'coroutine', 'debugger', 'delegate', 'destructor', 'dynamic',
	'endpoint', 'enum', 'evaluate', 'exception', 'executor', 'expression',
	'function', 'generic', 'handler', 'hashmap', 'heap', 'immutable', 'implements',
	'import', 'inheritance', 'initialize', 'inline', 'interface', 'iterator',
	'lambda', 'library', 'lifetime', 'literal', 'macro', 'memory', 'method',
	'module', 'mutable', 'namespace', 'network', 'null', 'operand', 'operator',
	'override', 'package', 'pointer', 'polymorph', 'primitive', 'protocol',
	'prototype', 'queue', 'recursion', 'reference', 'register', 'return',
	'runtime', 'sandbox', 'scope', 'semaphore', 'sequence', 'singleton',
	'stack', 'statement', 'static', 'string', 'struct', 'switch', 'syntax',
	'template', 'thread', 'token', 'trait', 'tuple', 'typedef', 'unsafe',
	'variable', 'vector', 'virtual', 'volatile', 'while', 'wrapper', 'yield',
]

const emp_words = [
	'nuke', 'blast', 'shock', 'pulse', 'flash', 'surge', 'spark', 'flare',
	'detonate', 'overload', 'discharge', 'supernova', 'hyperwave',
]

const freeze_words = [
	'freeze', 'frost', 'chill', 'pause', 'stasis', 'cryo', 'glacier',
	'absolute', 'timewarp', 'slowdown', 'chronos', 'subzero',
]

const heal_words = [
	'heal', 'cure', 'mend', 'life', 'vital', 'shield', 'repair', 'restore',
	'regenerate', 'nanobots', 'overcharge', 'reinforced',
]

fn get_random_word(length_tier int, is_code_mode bool) string {
	if is_code_mode {
		idx := rand.intn(code_words.len) or { 0 }
		return code_words[idx]
	}

	match length_tier {
		0 {
			idx := rand.intn(short_words.len) or { 0 }
			return short_words[idx]
		}
		1 {
			idx := rand.intn(medium_words.len) or { 0 }
			return medium_words[idx]
		}
		else {
			idx := rand.intn(long_boss_words.len) or { 0 }
			return long_boss_words[idx]
		}
	}
}

fn get_random_emp_word() string {
	idx := rand.intn(emp_words.len) or { 0 }
	return emp_words[idx]
}

fn get_random_freeze_word() string {
	idx := rand.intn(freeze_words.len) or { 0 }
	return freeze_words[idx]
}

fn get_random_heal_word() string {
	idx := rand.intn(heal_words.len) or { 0 }
	return heal_words[idx]
}
