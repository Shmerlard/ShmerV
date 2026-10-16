#ifndef SHMERV_HDMI_H
#define SHMERV_HDMI_H

#include "shmerv_memory_map.h"

#define HDMI_TEXT_COLUMNS 80u
#define HDMI_VISIBLE_ROWS 30u
#define HDMI_BUFFER_ROWS 51u
#define HDMI_VISIBLE_CHAR_COUNT (HDMI_TEXT_COLUMNS * HDMI_VISIBLE_ROWS)
#define HDMI_CHAR_COUNT (HDMI_TEXT_COLUMNS * HDMI_BUFFER_ROWS)
#define HDMI_CHAR_STRIDE 4u

#define HDMI_CTRL_OFFSET        0x00u
#define HDMI_CURSOR_POS_OFFSET  0x04u
#define HDMI_START_ROW_OFFSET   0x08u
#define HDMI_CURSOR_DATA_OFFSET 0x0Cu

/* CTRL bits match hdmi_ctrl_reg_t. Reset enables display, cursor and blink.
 * OVERFLOW_IFG is sticky on cursor wrap; writing zero clears it, writing one
 * sets/preserves it. A simultaneous new overflow wins over a software clear.
 * INTERRUPT_ENABLE gates the IRQ, not the flag. */
#define HDMI_ENABLE           0x0010u
#define HDMI_CURSOR_ENABLE    0x0008u
#define HDMI_CURSOR_BLINK     0x0004u
#define HDMI_OVERFLOW_IFG     0x0002u
#define HDMI_INTERRUPT_ENABLE 0x0001u
#define HDMI_CTRL_RESET (HDMI_ENABLE | HDMI_CURSOR_ENABLE | HDMI_CURSOR_BLINK)

#define HDMI_CURSOR_INDEX_MASK 0x0FFFu
#define HDMI_CHAR_CODE_SHIFT   8u
#define HDMI_CHAR_CODE_MASK    0xFF00u
#define HDMI_FOREGROUND_SHIFT  4u
#define HDMI_FOREGROUND_MASK   0x00F0u
#define HDMI_BACKGROUND_MASK   0x000Fu

#define HDMI_CTRL        SHMERV_MMIO16(HDMI_BASE + HDMI_CTRL_OFFSET)
#define HDMI_CURSOR_POS  SHMERV_MMIO16(HDMI_BASE + HDMI_CURSOR_POS_OFFSET)
#define HDMI_START_ROW   SHMERV_MMIO16(HDMI_BASE + HDMI_START_ROW_OFFSET)
#define HDMI_CURSOR_DATA SHMERV_MMIO16(HDMI_BASE + HDMI_CURSOR_DATA_OFFSET)

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

/* One cell in bits 15:0 per aligned 32-bit slot.
 * Bits 15:8: character, 7:4: foreground index, 3:0: background index.
 * Cells are read/write using halfword accesses; writes must enable both low
 * bytes, and upper bytes are ignored. Index = row * 80 + column (row 0..50,
 * column 0..79). Reads return the cell zero-extended to the bus width.
 * Character RAM initializes from the board's configuration-time image, if
 * provided; CPU reset does not clear/reload it.
 * CURSOR_POS reads the next cell index; writes outside 0..4079 are ignored
 * after checking all 16 input bits. CURSOR_DATA writes a cell and advances
 * the cursor, wrapping at HDMI_CHAR_COUNT and setting OVERFLOW_IFG.
 * Direct cell writes do not move the cursor. START_ROW reads zero and is not
 * writable yet. CURSOR_DATA/reserved register reads retain the previous
 * register response and are not intended for reading.
 * Reads respond after one CPU clock. Clearing HDMI_ENABLE blanks rendering
 * while retaining RAM contents and valid video timing. */

#endif
