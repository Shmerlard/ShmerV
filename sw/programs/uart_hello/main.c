#include "ShmerV.h"

static void delay(volatile uint32_t iterations)
{
    while (iterations != 0u) {
        --iterations;
    }
}

static void uart_send(uint8_t value)
{
    /* START also covers the request and completion cycles when BUSY is zero. */
    while (UART_CTRL & (UART_START_TX | UART_BUSY_TX)) {
    }
    UART_DATA = value;
    UART_CTRL = UART_START_TX;
    while (UART_CTRL & (UART_START_TX | UART_BUSY_TX)) {
    }
}

int main(void)
{
    static const uint8_t message[] = "Hello\r\n";
    volatile uint8_t *const port_a_out =
        (volatile uint8_t *)(PORTA_BASE + GPIO_OUT_OFFSET);
    volatile uint8_t *const port_a_dir =
        (volatile uint8_t *)(PORTA_BASE + GPIO_DIR_OFFSET);
    volatile uint8_t *const port_c_sel =
        (volatile uint8_t *)(PORTC_BASE + GPIO_SEL_OFFSET);

    *port_a_dir = 0xFFu;

    for (uint32_t count = 0u; count <= 0xFFu; ++count) {
        *port_a_out = (uint8_t)count;
        delay(4000u);
    }

    delay(100000u);
    *port_c_sel = PORTC_UART_TX_PIN;

    while (1) {
        for (uint32_t index = 0u; index < sizeof(message) - 1u; ++index) {
            uart_send(message[index]);
        }
    }
}
