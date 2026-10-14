#include <ShmerV.h>

/* Single producer (RX interrupt), single consumer (main). Holds 255 bytes. */
static volatile uint8_t rx_queue[256];
static volatile uint8_t rx_head;
static volatile uint8_t rx_tail;
static volatile uint32_t rx_queue_overflows;

static void delay(void)
{
    for (volatile uint32_t count = 0; count < 100000u; ++count) {
    }
}

SHMERV_INTERRUPT(SHMERV_IRQ_UART_RX, uart_rx_handler)
void uart_rx_handler(void)
{
    /* Reading RX acknowledges the interrupt. */
    uint8_t value = UART_RX_DATA;
    uint8_t next_head = (uint8_t)(rx_head + 1u);
    if (next_head == rx_tail) {
        /* Keep queued bytes; drop the newest byte if the queue is full. */
        ++rx_queue_overflows;
        return;
    }
    rx_queue[rx_head] = value;
    rx_head = next_head;
}

int main(void)
{
    UART_CTRL = 0u;
    PORTC_SEL = PORTC_UART_TX_PIN | PORTC_UART_RX_PIN;
    UART_CTRL = UART_SPEED_9600 | UART_LSB_FIRST | UART_RX_IE | UART_ENABLE;
    shmerv_interrupt_enable();

    while (1) {
        if (rx_tail == rx_head)
            continue;
        if (UART_CTRL & (UART_START_TX | UART_BUSY_TX))
            continue;

        uint8_t value = rx_queue[rx_tail];
        rx_tail = (uint8_t)(rx_tail + 1u);
        UART_TX_DATA = value;
        UART_CTRL |= UART_START_TX;
    }
}
