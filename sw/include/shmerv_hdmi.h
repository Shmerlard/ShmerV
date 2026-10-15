#ifndef SHMERV_HDMI_H
#define SHMERV_HDMI_H

#include "shmerv_memory_map.h"

#define HDMI_CHAR_COUNT 2400u
#define HDMI_CHAR_STRIDE 4u

/* Palette indices: foreground in cell bits [7:4], background in [3:0].
 * Match hdmi_color_t in rtl/types/hdmi_types.sv. */
#define HDMI_COLOR_BLACK 0x0u
#define HDMI_COLOR_BLUE 0x1u
#define HDMI_COLOR_GREEN 0x2u
#define HDMI_COLOR_CYAN 0x3u
#define HDMI_COLOR_RED 0x4u
#define HDMI_COLOR_MAGENTA 0x5u
#define HDMI_COLOR_BROWN 0x6u
#define HDMI_COLOR_LIGHT_GRAY 0x7u
#define HDMI_COLOR_DARK_GRAY 0x8u
#define HDMI_COLOR_LIGHT_BLUE 0x9u
#define HDMI_COLOR_LIGHT_GREEN 0xAu
#define HDMI_COLOR_LIGHT_CYAN 0xBu
#define HDMI_COLOR_LIGHT_RED 0xCu
#define HDMI_COLOR_LIGHT_MAGENTA 0xDu
#define HDMI_COLOR_YELLOW 0xEu
#define HDMI_COLOR_WHITE 0xFu

/* Temporary map: one cell in bits 15:0 per aligned 32-bit slot.
 * Bits 15:8: character, 7:4: foreground index, 3:0: background index.
 * Writes must enable both low bytes; upper bytes are ignored. */

#endif
