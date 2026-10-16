#include "ShmerV.h"

/* Current HDMI map. Keep these local while the shared HDMI API is unfinished. */
#define DISPLAY_BASE 0x10002000u
#define DISPLAY_CMEM_BASE 0x10006000u
#define DISPLAY_CURSOR_POS SHMERV_MMIO16(DISPLAY_BASE + 0x04u)
#define DISPLAY_CURSOR_DATA SHMERV_MMIO16(DISPLAY_BASE + 0x0Cu)
#define DISPLAY_COLUMNS 80u
#define DISPLAY_CELLS 2400u

static void write_direct(uint16_t index, uint16_t cell)
{
    SHMERV_MMIO16(DISPLAY_CMEM_BASE + 4u * index) = cell;
}

static void clear_screen(void)
{
    for (uint16_t index = 0; index < DISPLAY_CELLS; ++index) {
        write_direct(index, 0x2000u); /* Space, black on black. */
    }
    DISPLAY_CURSOR_POS = 0u;
}

int main(void)
{
    /* A software mirror is needed only for terminal control operations.
     * Ordinary glyph writes use the hardware cursor and its auto-increment. */
    uint16_t cursor_index = 0u;
    uint8_t cursor_col = 0u;
    DISPLAY_CURSOR_POS = 0u;
    UART_CTRL = 0u;
    PORTC_DIR &= ~PORTC_UART_RX_PIN;
    PORTC_SEL = PORTC_UART_RX_PIN;
    UART_CTRL = UART_SPEED_9600 | UART_LSB_FIRST | UART_ENABLE;

    while (1) {
        while ((UART_CTRL & UART_RX_PENDING) == 0u) {}
        uint8_t character = UART_RX_DATA;
        if (character == 0x0Du) {
            cursor_index += DISPLAY_COLUMNS - cursor_col;
            cursor_col = 0u;
            if (cursor_index >= DISPLAY_CELLS) cursor_index = 0u;
            DISPLAY_CURSOR_POS = cursor_index;
        } else if (character == 0x03u) {
            clear_screen();
            cursor_index = 0u;
            cursor_col = 0u;
        } else if (character == 0x7Fu) {
            if (cursor_col > 0u) {
                --cursor_col;
                --cursor_index;
                write_direct(cursor_index, 0x2000u);
                DISPLAY_CURSOR_POS = cursor_index;
            }
        } else {
            DISPLAY_CURSOR_DATA = (uint16_t)(((uint16_t)character << 8) | 0xF0u);
            ++cursor_index;
            ++cursor_col;
            if (cursor_col >= DISPLAY_COLUMNS) cursor_col = 0u;
            if (cursor_index >= DISPLAY_CELLS) {
                cursor_index = 0u;
                DISPLAY_CURSOR_POS = 0u;
            }
        }
    }
}
