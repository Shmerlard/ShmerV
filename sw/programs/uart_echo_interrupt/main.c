#include "ShmerV.h"

SHMERV_INTERRUPT(SHMERV_IRQ_UART_RX, uart_rx_handler)
void uart_rx_handler(void)
{
    /* Reading RX acknowledges the interrupt. */
    uint8_t value = UART_RX_DATA;

    while (UART_CTRL & (UART_START_TX | UART_BUSY_TX)) {
    }
    UART_TX_DATA = value;
    UART_CTRL |= UART_START_TX;
}

int main(void)
{
    UART_CTRL = 0u;
    PORTC_SEL = PORTC_UART_TX_PIN | PORTC_UART_RX_PIN;
    UART_CTRL = UART_SPEED_9600 | UART_LSB_FIRST | UART_RX_IE | UART_ENABLE;
    shmerv_interrupt_enable();

    while (1) {
    }
}
