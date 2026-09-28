#pragma once
#include <stdint.h>
static uint32_t g_sdl_draw_color = 0xFFFFFFFF;
static inline void set_sdl_color_c(uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
    g_sdl_draw_color = ((uint32_t)r) | (((uint32_t)g) << 8) | (((uint32_t)b) << 16) | (((uint32_t)a) << 24);
}
static inline uint32_t get_sdl_color_c(void) {
    return g_sdl_draw_color;
}
