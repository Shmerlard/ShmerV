#include "ShmerV.h"

static void write_cell(uint8_t row, uint8_t col, uint8_t character, uint8_t color)
{
    uint32_t index = row * 80 + col;
    SHMERV_MMIO16(HDMI_CHAR_BASE + HDMI_CHAR_STRIDE * index) =
        (uint16_t)(((uint16_t)character << 8) | color);
}

void clear_screen(uint8_t *cursor_row, uint8_t *cursor_col){
    for (uint8_t row = 0; row < 30 ; ++row){
        for (uint8_t col = 0; col < 80; ++col) {
            write_cell(row, col, ' ', 0x00);
        }
    }

    *cursor_col = 0;
    *cursor_row = 0;

}
int main(void)
{
    uint8_t cursor_row = 0u;
    uint8_t cursor_col = 0u;
    uint8_t color = 0x10;
    UART_CTRL = 0u;

    PORTC_DIR &= ~PORTC_UART_RX_PIN;
    PORTC_SEL = PORTC_UART_RX_PIN;
    UART_CTRL = UART_SPEED_9600 | UART_LSB_FIRST | UART_ENABLE;

    while (1) {
        while ((UART_CTRL & UART_RX_PENDING) == 0u) {}
        /* Reading RX_DATA acknowledges the byte. Every byte is a glyph code,
         * including Enter and Tab; no terminal control sequences are parsed. */
        uint8_t character = UART_RX_DATA;
        if (character == 0x0D) {
            cursor_row++;
            cursor_col = 0;
        } else if (character == 0x03) {
            clear_screen(&cursor_row, &cursor_col);
        } else if (character == 0x7F) {
            if (cursor_col > 0) {
                cursor_col--;
                write_cell(cursor_row, cursor_col, ' ', 0x00);
            }
        } else {
            write_cell(cursor_row,cursor_col, character, color);
            ++cursor_col;
            if (cursor_col >= 80) {
                cursor_col = 0;
                cursor_row++;
                if (cursor_row >= 30) cursor_row = 0;
            }
            color += (1 << 4);
        }
    }
}
