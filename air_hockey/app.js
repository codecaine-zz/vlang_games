const State = {
    MENU: 0,
    PLAYING: 1,
    PAUSED: 2,
    GOAL: 3,
    GAME_OVER: 4
};

let gameState = State.MENU;

// Audio Engine
const AudioContext = window.AudioContext || window.webkitAudioContext;
let audioCtx;
let isMuted = false;

function initAudio() {
    if (!audioCtx) {
        audioCtx = new AudioContext();
    }
    if (audioCtx.state === 'suspended') {
        audioCtx.resume();
    }
}

function playTone(freq, type, duration, vol=0.5, slideFreq=null) {
    if (isMuted || !audioCtx) return;
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    
    osc.type = type;
    osc.frequency.setValueAtTime(freq, audioCtx.currentTime);
    if (slideFreq) {
        osc.frequency.exponentialRampToValueAtTime(slideFreq, audioCtx.currentTime + duration);
    }
    
    gain.gain.setValueAtTime(vol, audioCtx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + duration);
    
    osc.connect(gain);
    gain.connect(audioCtx.destination);
    
    osc.start();
    osc.stop(audioCtx.currentTime + duration);
}

function playHitSound() {
    playTone(300, 'triangle', 0.1, 0.5, 100);
}

function playWallSound() {
    playTone(150, 'square', 0.1, 0.3);
}

function playScoreSound() {
    if (isMuted || !audioCtx) return;
    const notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
    notes.forEach((freq, i) => {
        setTimeout(() => playTone(freq, 'sine', 0.2, 0.3), i * 100);
    });
}

function playGameOverSound(win) {
    if (isMuted || !audioCtx) return;
    if (win) {
        playScoreSound();
    } else {
        playTone(300, 'sawtooth', 0.5, 0.4, 100);
        setTimeout(() => playTone(250, 'sawtooth', 0.5, 0.4, 80), 300);
    }
}

// Canvas Setup
const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');

let cw, ch;
// Standard virtual table size: 600x1000
const TABLE_W = 600;
const TABLE_H = 1000;
let scale = 1;

function resize() {
    const winW = window.innerWidth * 0.9;
    const winH = window.innerHeight * 0.9;
    
    const aspect = TABLE_W / TABLE_H;
    if (winW / winH < aspect) {
        cw = winW;
        ch = winW / aspect;
    } else {
        ch = winH;
        cw = winH * aspect;
    }
    
    canvas.width = cw;
    canvas.height = ch;
    scale = cw / TABLE_W;
}
window.addEventListener('resize', resize);
resize();

// Physics & Entities
const PUCK_RADIUS = 20;
const MALLET_RADIUS = 35;
const GOAL_WIDTH = 200;
const MAX_SCORE = 7;

let player = { x: TABLE_W/2, y: TABLE_H - 100, r: MALLET_RADIUS, vx: 0, vy: 0, score: 0 };
let ai = { x: TABLE_W/2, y: 100, r: MALLET_RADIUS, vx: 0, vy: 0, score: 0, targetX: TABLE_W/2, targetY: 100 };
let puck = { x: TABLE_W/2, y: TABLE_H/2, r: PUCK_RADIUS, vx: 0, vy: 0 };

let difficulty = 'medium'; // easy, medium, hard
let aiSpeed = 0.05; 
let maxAiSpeed = 500; // px/s
let aiReactionDelay = 200; // ms
let lastAiUpdate = 0;

function resetPositions(server) {
    player.x = TABLE_W/2;
    player.y = TABLE_H - 100;
    player.vx = 0; player.vy = 0;
    
    ai.x = TABLE_W/2;
    ai.y = 100;
    ai.vx = 0; ai.vy = 0;
    
    puck.x = TABLE_W/2;
    puck.y = server === 'player' ? TABLE_H - 200 : 200;
    puck.vx = 0;
    puck.vy = 0;
}

// Particles
let particles = [];
function spawnParticles(x, y, color) {
    for (let i = 0; i < 30; i++) {
        const angle = Math.random() * Math.PI * 2;
        const speed = Math.random() * 300 + 100;
        particles.push({
            x: x, y: y,
            vx: Math.cos(angle) * speed,
            vy: Math.sin(angle) * speed,
            life: 1.0,
            color: color
        });
    }
}

// Screen Shake
let shakeTime = 0;
function shakeScreen() {
    shakeTime = 0.2; // 200ms
}

// Input / Pointer Lock
canvas.addEventListener('click', () => {
    if (gameState === State.PLAYING) {
        initAudio();
        canvas.requestPointerLock();
    }
});

document.addEventListener('pointerlockchange', () => {
    if (document.pointerLockElement !== canvas && gameState === State.PLAYING) {
        gameState = State.PAUSED;
        document.getElementById('start-btn').innerText = 'Resume';
        showScreen('main-menu');
    }
});

document.addEventListener('mousemove', (e) => {
    if (gameState === State.PLAYING && document.pointerLockElement === canvas) {
        // Convert movement to table coordinates
        const dx = e.movementX / scale;
        const dy = e.movementY / scale;
        
        // Update velocity for collision impulse
        player.vx = dx / 0.016; // approx 60fps
        player.vy = dy / 0.016;

        player.x += dx;
        player.y += dy;

        // Clamp to player's half
        player.x = Math.max(player.r, Math.min(TABLE_W - player.r, player.x));
        player.y = Math.max(TABLE_H/2 + player.r, Math.min(TABLE_H - player.r, player.y));
    }
});

// UI Logic
function showScreen(id) {
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
    document.getElementById(id).classList.add('active');
    
    if (id === 'hud') {
        document.getElementById('hud').classList.add('active');
    }
}

document.querySelectorAll('.diff-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
        document.querySelectorAll('.diff-btn').forEach(b => b.classList.remove('active'));
        e.target.classList.add('active');
        difficulty = e.target.dataset.diff;
    });
});

document.getElementById('start-btn').addEventListener('click', () => {
    initAudio();
    if (gameState === State.MENU || gameState === State.GAME_OVER) {
        player.score = 0;
        ai.score = 0;
        updateScoreboard();
        resetPositions('player');
        
        if (difficulty === 'easy') { aiSpeed = 3; maxAiSpeed = 300; aiReactionDelay = 400; }
        else if (difficulty === 'medium') { aiSpeed = 6; maxAiSpeed = 600; aiReactionDelay = 200; }
        else if (difficulty === 'hard') { aiSpeed = 10; maxAiSpeed = 1200; aiReactionDelay = 50; }
    }
    
    gameState = State.PLAYING;
    showScreen('hud');
    canvas.requestPointerLock();
});

document.getElementById('play-again-btn').addEventListener('click', () => {
    gameState = State.MENU;
    document.getElementById('start-btn').innerText = 'Play';
    showScreen('main-menu');
});

document.getElementById('mute-btn').addEventListener('click', (e) => {
    isMuted = !isMuted;
    e.target.innerText = isMuted ? '🔇' : '🔊';
});

document.getElementById('fullscreen-btn').addEventListener('click', () => {
    if (!document.fullscreenElement) {
        document.documentElement.requestFullscreen().catch(err => {
            console.log(`Error attempting to enable fullscreen: ${err.message}`);
        });
    } else {
        document.exitFullscreen();
    }
});

function updateScoreboard() {
    document.getElementById('player-score').innerText = player.score;
    document.getElementById('ai-score').innerText = ai.score;
}

// Physics Step
function circleCollision(c1, c2) {
    const dx = c2.x - c1.x;
    const dy = c2.y - c1.y;
    const dist = Math.sqrt(dx*dx + dy*dy);
    if (dist < c1.r + c2.r) {
        // Resolve overlap
        const overlap = (c1.r + c2.r) - dist;
        const nx = dx / dist;
        const ny = dy / dist;
        
        c2.x += nx * overlap * 0.5;
        c2.y += ny * overlap * 0.5;
        c1.x -= nx * overlap * 0.5;
        c1.y -= ny * overlap * 0.5;

        // Dynamic collision impulse
        const kx = c1.vx - c2.vx;
        const ky = c1.vy - c2.vy;
        
        // Dot product
        const p = 2.0 * (nx * kx + ny * ky) / 2; // Assuming equal mass for simplicity, though mallet is practically infinite mass in user control
        
        // For mallet, we want to impart energy to puck
        // Assuming c1 is mallet (infinite mass in control), c2 is puck
        if (c1 === player || c1 === ai) {
            c2.vx = c2.vx + p * nx * 1.5 + c1.vx * 0.5;
            c2.vy = c2.vy + p * ny * 1.5 + c1.vy * 0.5;
        } else {
            c1.vx -= p * nx;
            c1.vy -= p * ny;
            c2.vx += p * nx;
            c2.vy += p * ny;
        }
        
        // Max puck speed
        const speed = Math.hypot(c2.vx, c2.vy);
        const MAX_SPEED = 2000;
        if (speed > MAX_SPEED) {
            c2.vx = (c2.vx / speed) * MAX_SPEED;
            c2.vy = (c2.vy / speed) * MAX_SPEED;
        }
        
        playHitSound();
        shakeScreen();
    }
}

function updatePhysics(dt) {
    if (gameState !== State.PLAYING) return;

    // AI Logic
    const now = Date.now();
    if (now - lastAiUpdate > aiReactionDelay) {
        if (puck.y < TABLE_H/2 + 100) {
            // Defend or attack
            ai.targetX = puck.x;
            ai.targetY = Math.max(ai.r, Math.min(TABLE_H/2 - ai.r, puck.y - 30));
        } else {
            // Return to center
            ai.targetX = TABLE_W/2;
            ai.targetY = 100;
        }
        lastAiUpdate = now;
    }

    // Move AI
    const adx = ai.targetX - ai.x;
    const ady = ai.targetY - ai.y;
    const adist = Math.sqrt(adx*adx + ady*ady);
    if (adist > 5) {
        const moveSpeed = Math.min(maxAiSpeed, adist * aiSpeed);
        ai.vx = (adx / adist) * moveSpeed;
        ai.vy = (ady / adist) * moveSpeed;
    } else {
        ai.vx = 0; ai.vy = 0;
    }

    ai.x += ai.vx * dt;
    ai.y += ai.vy * dt;
    
    // Clamp AI
    ai.x = Math.max(ai.r, Math.min(TABLE_W - ai.r, ai.x));
    ai.y = Math.max(ai.r, Math.min(TABLE_H/2 - ai.r, ai.y));

    // Move Puck
    puck.x += puck.vx * dt;
    puck.y += puck.vy * dt;

    // Friction
    puck.vx *= 0.99;
    puck.vy *= 0.99;

    // Wall Collisions
    const goalLeft = TABLE_W/2 - GOAL_WIDTH/2;
    const goalRight = TABLE_W/2 + GOAL_WIDTH/2;

    if (puck.x <= puck.r) {
        puck.x = puck.r;
        puck.vx *= -0.8;
        playWallSound();
    } else if (puck.x >= TABLE_W - puck.r) {
        puck.x = TABLE_W - puck.r;
        puck.vx *= -0.8;
        playWallSound();
    }

    if (puck.y <= puck.r) {
        if (puck.x > goalLeft && puck.x < goalRight) {
            scoreGoal('player');
        } else {
            puck.y = puck.r;
            puck.vy *= -0.8;
            playWallSound();
        }
    } else if (puck.y >= TABLE_H - puck.r) {
        if (puck.x > goalLeft && puck.x < goalRight) {
            scoreGoal('ai');
        } else {
            puck.y = TABLE_H - puck.r;
            puck.vy *= -0.8;
            playWallSound();
        }
    }

    // Entity Collisions
    circleCollision(player, puck);
    circleCollision(ai, puck);
    
    // Clear Mallet velocities so they don't impart force when stationary
    player.vx *= 0.5;
    player.vy *= 0.5;
}

function scoreGoal(scorer) {
    gameState = State.GOAL;
    playScoreSound();
    
    if (scorer === 'player') {
        player.score++;
        spawnParticles(puck.x, 0, '#0ff');
        document.getElementById('goal-text').style.color = 'var(--neon-blue)';
        document.getElementById('goal-text').innerText = 'PLAYER SCORES!';
    } else {
        ai.score++;
        spawnParticles(puck.x, TABLE_H, '#f0f');
        document.getElementById('goal-text').style.color = 'var(--neon-pink)';
        document.getElementById('goal-text').innerText = 'AI SCORES!';
    }
    
    updateScoreboard();
    showScreen('goal-overlay');
    
    // Shake effect
    document.getElementById('game-container').classList.add('shake');
    setTimeout(() => document.getElementById('game-container').classList.remove('shake'), 500);

    setTimeout(() => {
        if (player.score >= MAX_SCORE || ai.score >= MAX_SCORE) {
            endGame();
        } else {
            resetPositions(scorer === 'player' ? 'ai' : 'player');
            gameState = State.PLAYING;
            showScreen('hud');
        }
    }, 2000);
}

function endGame() {
    gameState = State.GAME_OVER;
    document.exitPointerLock();
    
    const win = player.score >= MAX_SCORE;
    playGameOverSound(win);
    
    document.getElementById('winner-text').innerText = win ? 'YOU WIN!' : 'AI WINS!';
    document.getElementById('winner-text').style.color = win ? 'var(--neon-blue)' : 'var(--neon-pink)';
    document.getElementById('final-score').innerText = `${player.score} - ${ai.score}`;
    
    showScreen('game-over');
}

// Rendering
function drawRect(x, y, w, h, color, blurColor) {
    ctx.shadowBlur = 15;
    ctx.shadowColor = blurColor;
    ctx.fillStyle = color;
    ctx.fillRect(x, y, w, h);
    ctx.shadowBlur = 0;
}

function drawCircle(x, y, r, color, blurColor, fill=true) {
    ctx.beginPath();
    ctx.arc(x, y, r, 0, Math.PI*2);
    ctx.shadowBlur = 20;
    ctx.shadowColor = blurColor;
    if (fill) {
        ctx.fillStyle = color;
        ctx.fill();
    } else {
        ctx.strokeStyle = color;
        ctx.lineWidth = 5;
        ctx.stroke();
    }
    ctx.shadowBlur = 0;
}

function render() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    ctx.save();
    
    if (shakeTime > 0) {
        const mag = shakeTime * 50;
        const dx = (Math.random() - 0.5) * mag;
        const dy = (Math.random() - 0.5) * mag;
        ctx.translate(dx, dy);
    }
    
    ctx.scale(scale, scale);

    // Draw Table
    ctx.strokeStyle = '#fff';
    ctx.lineWidth = 4;
    ctx.shadowBlur = 10;
    ctx.shadowColor = '#fff';
    ctx.strokeRect(0, 0, TABLE_W, TABLE_H);
    
    // Center Line
    ctx.beginPath();
    ctx.moveTo(0, TABLE_H/2);
    ctx.lineTo(TABLE_W, TABLE_H/2);
    ctx.setLineDash([10, 15]);
    ctx.stroke();
    ctx.setLineDash([]);
    
    // Center Circle
    drawCircle(TABLE_W/2, TABLE_H/2, 50, '#fff', '#fff', false);

    // Goals
    const goalLeft = TABLE_W/2 - GOAL_WIDTH/2;
    ctx.fillStyle = 'rgba(255, 0, 255, 0.2)';
    ctx.fillRect(goalLeft, 0, GOAL_WIDTH, 10); // Top goal
    ctx.fillStyle = 'rgba(0, 255, 255, 0.2)';
    ctx.fillRect(goalLeft, TABLE_H - 10, GOAL_WIDTH, 10); // Bottom goal

    // Particles
    for (let i = particles.length - 1; i >= 0; i--) {
        const p = particles[i];
        ctx.globalAlpha = p.life;
        drawCircle(p.x, p.y, 4, p.color, p.color, true);
        ctx.globalAlpha = 1.0;
    }

    // Puck
    drawCircle(puck.x, puck.y, puck.r, '#fff', '#fff', true);

    // AI Mallet
    drawCircle(ai.x, ai.y, ai.r, 'var(--bg-color)', '#f0f', true);
    drawCircle(ai.x, ai.y, ai.r, '#f0f', '#f0f', false);
    drawCircle(ai.x, ai.y, ai.r*0.4, '#f0f', '#f0f', true);

    // Player Mallet
    drawCircle(player.x, player.y, player.r, 'var(--bg-color)', '#0ff', true);
    drawCircle(player.x, player.y, player.r, '#0ff', '#0ff', false);
    drawCircle(player.x, player.y, player.r*0.4, '#0ff', '#0ff', true);

    ctx.restore();
}

// Main Loop
let lastTime = 0;
function loop(time) {
    let dt = (time - lastTime) / 1000;
    lastTime = time;
    
    if (dt > 0.1) dt = 0.1; // Cap delta time

    if (shakeTime > 0) {
        shakeTime -= dt;
    }

    updatePhysics(dt);
    
    // Update Particles
    for (let i = particles.length - 1; i >= 0; i--) {
        const p = particles[i];
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
        if (p.life <= 0) {
            particles.splice(i, 1);
        }
    }

    render();
    requestAnimationFrame(loop);
}

requestAnimationFrame(time => {
    lastTime = time;
    loop(time);
});
