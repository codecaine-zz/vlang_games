#pragma once
#include <stdint.h>
#include <math.h>
#include <stdlib.h>

// -------------------------------------------------------------
// Shockwaves
// -------------------------------------------------------------
typedef struct {
    float x;
    float y;
    float radius;
    float max_radius;
    float life; // 1.0 down to 0.0
    uint8_t r, g, b;
    int active;
} Shockwave;

static Shockwave g_shockwaves[8];

static inline void trigger_shockwave_c(float x, float y, float max_r, uint8_t r, uint8_t g, uint8_t b) {
    int slot = -1;
    for (int i = 0; i < 8; i++) {
        if (!g_shockwaves[i].active) {
            slot = i;
            break;
        }
    }
    if (slot == -1) slot = 0;
    g_shockwaves[slot].x = x;
    g_shockwaves[slot].y = y;
    g_shockwaves[slot].radius = 4.0f;
    g_shockwaves[slot].max_radius = max_r > 10.0f ? max_r : 120.0f;
    g_shockwaves[slot].life = 1.0f;
    g_shockwaves[slot].r = r;
    g_shockwaves[slot].g = g;
    g_shockwaves[slot].b = b;
    g_shockwaves[slot].active = 1;
}

static inline int get_active_shockwaves_c(float* out_data, int max_count) {
    int count = 0;
    for (int i = 0; i < 8 && count < max_count; i++) {
        if (g_shockwaves[i].active) {
            out_data[count * 7 + 0] = g_shockwaves[i].x;
            out_data[count * 7 + 1] = g_shockwaves[i].y;
            out_data[count * 7 + 2] = g_shockwaves[i].radius;
            out_data[count * 7 + 3] = g_shockwaves[i].life;
            out_data[count * 7 + 4] = (float)g_shockwaves[i].r;
            out_data[count * 7 + 5] = (float)g_shockwaves[i].g;
            out_data[count * 7 + 6] = (float)g_shockwaves[i].b;
            count++;
        }
    }
    return count;
}

static inline void update_shockwaves_c(float dt) {
    for (int i = 0; i < 8; i++) {
        if (g_shockwaves[i].active) {
            g_shockwaves[i].life -= dt * 2.2f;
            g_shockwaves[i].radius += (g_shockwaves[i].max_radius - g_shockwaves[i].radius) * (dt * 9.0f);
            if (g_shockwaves[i].life <= 0.0f || g_shockwaves[i].radius >= g_shockwaves[i].max_radius) {
                g_shockwaves[i].active = 0;
            }
        }
    }
}

// -------------------------------------------------------------
// Interactive Display Profiles (F10)
// -------------------------------------------------------------
static int g_fx_mode = 0; // 0: CRT Pro, 1: Cyber Bloom, 2: Clean HD, 3: Vintage Amber
static double g_fx_toast_until = 0.0;

static inline int get_fx_mode_c(void) { return g_fx_mode; }
static inline void set_fx_mode_c(int mode) { g_fx_mode = ((mode % 4) + 4) % 4; }

static inline int cycle_fx_mode_c(double now) {
    g_fx_mode = (g_fx_mode + 1) % 4;
    g_fx_toast_until = now + 1.8;
    return g_fx_mode;
}

static inline double get_fx_toast_until_c(void) { return g_fx_toast_until; }

// -------------------------------------------------------------
// Real-Time Audio Energy & RMS Coupling
// -------------------------------------------------------------
static float g_audio_rms = 0.05f;
static float g_audio_peak = 0.05f;
static float g_audio_bass = 0.05f;

static inline void set_audio_levels_c(float rms, float peak, float bass) {
    if (rms > g_audio_rms) g_audio_rms = rms;
    else g_audio_rms += (rms - g_audio_rms) * 0.12f;

    if (peak > g_audio_peak) g_audio_peak = peak;
    else g_audio_peak += (peak - g_audio_peak) * 0.08f;

    if (bass > g_audio_bass) g_audio_bass = bass;
    else g_audio_bass += (bass - g_audio_bass) * 0.15f;
}

static inline float get_audio_rms_c(void) { return g_audio_rms; }
static inline float get_audio_peak_c(void) { return g_audio_peak; }
static inline float get_audio_bass_c(void) { return g_audio_bass; }

// -------------------------------------------------------------
// Analog Soft-Saturator Limiter (Zero Digital Audio Clipping)
// -------------------------------------------------------------
static inline float soft_limit_sample_c(float x) {
    if (x > 1.35f) return 0.999f;
    if (x < -1.35f) return -0.999f;
    // Rational analog soft clipping curve
    float sign = (x >= 0.0f) ? 1.0f : -1.0f;
    float ax = (x >= 0.0f) ? x : -x;
    return sign * (ax / (1.0f + 0.45f * ax));
}

// -------------------------------------------------------------
// Low-Pass Filter on Pause
// -------------------------------------------------------------
static float g_lpf_state = 0.0f;
static int g_is_paused = 0;

static inline void set_game_paused_c(int paused) { g_is_paused = paused; }
static inline int get_game_paused_c(void) { return g_is_paused; }

static inline float apply_lowpass_c(float sample) {
    if (!g_is_paused) {
        g_lpf_state = sample;
        return sample;
    }
    // Muffled single-pole IIR lowpass
    g_lpf_state += 0.14f * (sample - g_lpf_state);
    return g_lpf_state;
}

// -------------------------------------------------------------
// Universal Screen Camera Trauma & Shake Engine
// -------------------------------------------------------------
static float g_shake_trauma = 0.0f;
static float g_shake_offset_x = 0.0f;
static float g_shake_offset_y = 0.0f;
static uint32_t g_shake_seed = 1234567u;

static inline void trigger_shake_c(float trauma) {
    g_shake_trauma += trauma;
    if (g_shake_trauma > 1.0f) g_shake_trauma = 1.0f;
}

static inline void update_shake_c(float dt) {
    if (g_shake_trauma > 0.0f) {
        g_shake_trauma -= dt * 1.8f;
        if (g_shake_trauma < 0.0f) g_shake_trauma = 0.0f;
        float mag = g_shake_trauma * g_shake_trauma * 20.0f;
        g_shake_seed = g_shake_seed * 1664525u + 1013904223u;
        float rx = ((float)(g_shake_seed & 0xFFFF) / 32768.0f) - 1.0f;
        g_shake_seed = g_shake_seed * 1664525u + 1013904223u;
        float ry = ((float)(g_shake_seed & 0xFFFF) / 32768.0f) - 1.0f;
        g_shake_offset_x = rx * mag;
        g_shake_offset_y = ry * mag;
    } else {
        g_shake_offset_x = 0.0f;
        g_shake_offset_y = 0.0f;
    }
}

static inline float get_shake_x_c(void) { return g_shake_offset_x; }
static inline float get_shake_y_c(void) { return g_shake_offset_y; }
static inline float get_shake_trauma_c(void) { return g_shake_trauma; }

// -------------------------------------------------------------
// Directional Kinetic Spark Particles
// -------------------------------------------------------------
typedef struct {
    float x;
    float y;
    float vx;
    float vy;
    float life; // 1.0 down to 0.0
    uint8_t r, g, b;
    int active;
} SparkParticle;

static SparkParticle g_sparks[32];

static inline void trigger_sparks_c(float x, float y, float base_vx, float base_vy, int count, uint8_t r, uint8_t g, uint8_t b) {
    for (int k = 0; k < count; k++) {
        int slot = -1;
        for (int i = 0; i < 32; i++) {
            if (!g_sparks[i].active) {
                slot = i;
                break;
            }
        }
        if (slot == -1) slot = k % 32;

        g_shake_seed = g_shake_seed * 1664525u + 1013904223u;
        float ang = ((float)(g_shake_seed & 0xFFFF) / 65535.0f) * 6.283185f;
        g_shake_seed = g_shake_seed * 1664525u + 1013904223u;
        float spd = 50.0f + ((float)(g_shake_seed & 0xFFFF) / 65535.0f) * 160.0f;

        g_sparks[slot].x = x;
        g_sparks[slot].y = y;
        g_sparks[slot].vx = base_vx + cosf(ang) * spd;
        g_sparks[slot].vy = base_vy + sinf(ang) * spd - 35.0f;
        g_sparks[slot].life = 0.7f + ((float)(g_shake_seed & 0x7F) / 128.0f) * 0.4f;
        g_sparks[slot].r = r;
        g_sparks[slot].g = g;
        g_sparks[slot].b = b;
        g_sparks[slot].active = 1;
    }
}

static inline void update_sparks_c(float dt) {
    for (int i = 0; i < 32; i++) {
        if (g_sparks[i].active) {
            g_sparks[i].x += g_sparks[i].vx * dt;
            g_sparks[i].y += g_sparks[i].vy * dt;
            g_sparks[i].vy += 160.0f * dt; // gravity
            g_sparks[i].vx *= (1.0f - dt * 2.5f); // drag
            g_sparks[i].life -= dt * 2.2f;
            if (g_sparks[i].life <= 0.0f) {
                g_sparks[i].active = 0;
            }
        }
    }
}

static inline int get_active_sparks_c(float* out_data, int max_count) {
    int count = 0;
    for (int i = 0; i < 32 && count < max_count; i++) {
        if (g_sparks[i].active) {
            out_data[count * 6 + 0] = g_sparks[i].x;
            out_data[count * 6 + 1] = g_sparks[i].y;
            out_data[count * 6 + 2] = g_sparks[i].life;
            out_data[count * 6 + 3] = (float)g_sparks[i].r;
            out_data[count * 6 + 4] = (float)g_sparks[i].g;
            out_data[count * 6 + 5] = (float)g_sparks[i].b;
            count++;
        }
    }
    return count;
}

// -------------------------------------------------------------
// Floating Score & Combo Text
// -------------------------------------------------------------
typedef struct {
    float x;
    float y;
    int score;
    float life; // 1.0 down to 0.0
    uint8_t r, g, b;
    int active;
} FloatingScore;

static FloatingScore g_floating_scores[8];

static inline void trigger_floating_score_c(float x, float y, int score, uint8_t r, uint8_t g, uint8_t b) {
    int slot = -1;
    for (int i = 0; i < 8; i++) {
        if (!g_floating_scores[i].active) {
            slot = i;
            break;
        }
    }
    if (slot == -1) slot = 0;
    g_floating_scores[slot].x = x;
    g_floating_scores[slot].y = y;
    g_floating_scores[slot].score = score;
    g_floating_scores[slot].life = 1.0f;
    g_floating_scores[slot].r = r;
    g_floating_scores[slot].g = g;
    g_floating_scores[slot].b = b;
    g_floating_scores[slot].active = 1;
}

static inline void update_floating_scores_c(float dt) {
    for (int i = 0; i < 8; i++) {
        if (g_floating_scores[i].active) {
            g_floating_scores[i].y -= 42.0f * dt;
            g_floating_scores[i].life -= dt * 1.5f;
            if (g_floating_scores[i].life <= 0.0f) {
                g_floating_scores[i].active = 0;
            }
        }
    }
}

static inline int get_active_floating_scores_c(float* out_data, int max_count) {
    int count = 0;
    for (int i = 0; i < 8 && count < max_count; i++) {
        if (g_floating_scores[i].active) {
            out_data[count * 7 + 0] = g_floating_scores[i].x;
            out_data[count * 7 + 1] = g_floating_scores[i].y;
            out_data[count * 7 + 2] = (float)g_floating_scores[i].score;
            out_data[count * 7 + 3] = g_floating_scores[i].life;
            out_data[count * 7 + 4] = (float)g_floating_scores[i].r;
            out_data[count * 7 + 5] = (float)g_floating_scores[i].g;
            out_data[count * 7 + 6] = (float)g_floating_scores[i].b;
            count++;
        }
    }
    return count;
}
