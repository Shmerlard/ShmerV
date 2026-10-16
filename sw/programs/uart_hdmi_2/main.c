#include "ShmerV.h"

static void write_direct(uint16_t index, uint16_t cell)
{
    SHMERV_MMIO16(HDMI_CHAR_BASE + HDMI_CHAR_STRIDE * index) = cell;
}

static void clear_screen(void)
{
    for (uint16_t index = 0; index < HDMI_VISIBLE_CHAR_COUNT; ++index) {
        write_direct(index, 0x2000u); /* Space, black on black. */
    }
    HDMI_CURSOR_POS = 0u;
}

int main(void)
{
    /* A software mirror is needed only for terminal control operations.
     * Ordinary glyph writes use the hardware cursor and its auto-increment. */
    uint16_t cursor_index = 0u;
    uint8_t cursor_col = 0u;
    HDMI_CURSOR_POS = 0u;
    UART_CTRL = 0u;
    PORTC_DIR &= ~PORTC_UART_RX_PIN;
    PORTC_SEL = PORTC_UART_RX_PIN;
    UART_CTRL = UART_SPEED_9600 | UART_LSB_FIRST | UART_ENABLE;

    while (1) {
        while ((UART_CTRL & UART_RX_PENDING) == 0u) {}
        uint8_t character = UART_RX_DATA;
        if (character == 0x0Du) {
            cursor_index += HDMI_TEXT_COLUMNS - cursor_col;
            cursor_col = 0u;
            if (cursor_index >= HDMI_VISIBLE_CHAR_COUNT) cursor_index = 0u;
            HDMI_CURSOR_POS = cursor_index;
        } else if (character == 0x03u) {
            clear_screen();
            cursor_index = 0u;
            cursor_col = 0u;
        } else if (character == 0x7Fu) {
            if (cursor_col > 0u) {
                --cursor_col;
                --cursor_index;
                write_direct(cursor_index, 0x2000u);
                HDMI_CURSOR_POS = cursor_index;
            }
        } else {
            HDMI_CURSOR_DATA = (uint16_t)(((uint16_t)character << HDMI_CHAR_CODE_SHIFT) | 0xF0u);
            ++cursor_index;
            ++cursor_col;
            if (cursor_col >= HDMI_TEXT_COLUMNS) cursor_col = 0u;
            if (cursor_index >= HDMI_VISIBLE_CHAR_COUNT) {
                cursor_index = 0u;
                HDMI_CURSOR_POS = 0u;
            }
        }
    }
}
