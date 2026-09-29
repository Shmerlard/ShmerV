#include <stdint.h>

#define GPIO0_BASE_ADDRESS 0x10000000u
#define GPIO2_BASE_ADDRESS 0x10000200u
#define UART_BASE_ADDRESS 0x10000300u

#define GPIO_OUT_OFFSET 0x04u
#define GPIO_DIR_OFFSET 0x08u
#define GPIO_SEL_OFFSET 0x0Cu

#define UART_DATA_OFFSET 0x00u
#define UART_CTRL_OFFSET 0x04u

static void wait_for_uart(void)
{
    /* Longer than one 10-bit frame: 10 * 234 clocks. */
    for (volatile uint32_t count = 0; count < 3000u; ++count) {
    }
}

static void diagnostic_delay(void)
{
    for (volatile uint32_t count = 0; count < 200000u; ++count) {
    }
}

static void uart_send(uint8_t value)
{
    volatile uint8_t *const uart_data =
        (volatile uint8_t *)(UART_BASE_ADDRESS + UART_DATA_OFFSET);
    volatile uint8_t *const uart_ctrl =
        (volatile uint8_t *)(UART_BASE_ADDRESS + UART_CTRL_OFFSET);

    *uart_data = value;
    *uart_ctrl = 1u;
    wait_for_uart();
}

int main(void)
{
    uint8_t gpio2_level = 0u;
    volatile uint8_t *const gpio0_out =
        (volatile uint8_t *)(GPIO0_BASE_ADDRESS + GPIO_OUT_OFFSET);
    volatile uint8_t *const gpio0_dir =
        (volatile uint8_t *)(GPIO0_BASE_ADDRESS + GPIO_DIR_OFFSET);
    volatile uint8_t *const gpio2_dir =
        (volatile uint8_t *)(GPIO2_BASE_ADDRESS + GPIO_DIR_OFFSET);
    volatile uint8_t *const gpio2_out =
        (volatile uint8_t *)(GPIO2_BASE_ADDRESS + GPIO_OUT_OFFSET);
    volatile uint8_t *const gpio2_sel =
        (volatile uint8_t *)(GPIO2_BASE_ADDRESS + GPIO_SEL_OFFSET);

    *gpio2_out = 0u;
    *gpio2_dir = 1u;

    *gpio0_dir = 1u;
    *gpio0_out = 1u;

    for (uint8_t transition = 0; transition < 100u; ++transition) {
        gpio2_level ^= 1u;
        *gpio2_out = gpio2_level;
        diagnostic_delay();
    }

    *gpio2_out = 1u;
    *gpio2_sel = 1u;

    while (1) {
        uart_send('H');
        uart_send('e');
        uart_send('l');
        uart_send('l');
        uart_send('o');
    }
}
