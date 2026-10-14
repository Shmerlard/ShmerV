#include "ShmerV.h"

static void write_cell(uint32_t index, uint8_t character)
{
    /* White foreground, black background. */
    SHMERV_MMIO16(HDMI_CHAR_BASE + HDMI_CHAR_STRIDE * index) =
        (uint16_t)(((uint16_t)character << 8) | 0xF0u);
}

int main(void)
{
    uint32_t cursor = 0u;
    UART_CTRL = 0u;
    for (uint32_t index = 0; index < HDMI_CHAR_COUNT; ++index)
        write_cell(index, ' ');

    /* GPIO C.1 is the UART RX input (board pin 37). */
    PORTC_DIR = (uint8_t)(PORTC_DIR & (uint8_t)~PORTC_UART_RX_PIN);
    PORTC_SEL = PORTC_UART_RX_PIN;
    UART_CTRL = UART_SPEED_9600 | UART_LSB_FIRST | UART_ENABLE;

    while (1) {
        while ((UART_CTRL & UART_RX_PENDING) == 0u) {}
        /* Reading RX_DATA acknowledges the byte. Every byte is a glyph code,
         * including Enter and Tab; no terminal control sequences are parsed. */
        uint8_t character = UART_RX_DATA;
        write_cell(cursor, character);
        ++cursor;
        if (cursor == HDMI_CHAR_COUNT) cursor = 0u;
    }
}
