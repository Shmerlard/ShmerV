#include "ShmerV.h"

static void uart_send(uint8_t value)
{
    while (UART_CTRL & (UART_START_TX | UART_BUSY_TX)) {
    }
    UART_TX_DATA = value;
    UART_CTRL |= UART_START_TX;
    while (UART_CTRL & (UART_START_TX | UART_BUSY_TX)) {
    }
}

int main(void)
{
    UART_CTRL = 0u;
    PORTC_SEL = PORTC_UART_TX_PIN | PORTC_UART_RX_PIN;
    UART_CTRL = UART_SPEED_9600 | UART_LSB_FIRST | UART_ENABLE;

    while (1) {
        while (!(UART_CTRL & UART_RX_PENDING)) {
        }
        /* Reading RX acknowledges the received byte. */
        uint8_t value = UART_RX_DATA;
        uart_send(value);
    }
}
