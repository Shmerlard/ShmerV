#include <stdint.h>

#define GPIO0_BASE_ADDRESS 0x10000000u
#define GPIO2_BASE_ADDRESS 0x10000200u
#define UART_BASE_ADDRESS 0x10000300u

#define GPIO_OUT_OFFSET 0x04u
#define GPIO_DIR_OFFSET 0x08u
#define GPIO_SEL_OFFSET 0x0Cu

#define UART_DATA_OFFSET 0x00u
#define UART_CTRL_OFFSET 0x04u

static void delay(volatile uint32_t iterations)
{
    while (iterations != 0u) {
        --iterations;
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

    // One 9600-baud frame takes 880 CPU clocks.
    delay(256u);
}

int main(void)
{
    static const uint8_t message[] = "Hello\r\n";
    volatile uint8_t *const port_a_out =
        (volatile uint8_t *)(GPIO0_BASE_ADDRESS + GPIO_OUT_OFFSET);
    volatile uint8_t *const port_a_dir =
        (volatile uint8_t *)(GPIO0_BASE_ADDRESS + GPIO_DIR_OFFSET);
    volatile uint8_t *const port_c_sel =
        (volatile uint8_t *)(GPIO2_BASE_ADDRESS + GPIO_SEL_OFFSET);

    *port_a_dir = 0xFFu;

    for (uint32_t count = 0u; count <= 0xFFu; ++count) {
        *port_a_out = (uint8_t)count;
        delay(4000u);
    }

    delay(100000u);
    *port_c_sel = 0x01u;

    while (1) {
        for (uint32_t index = 0u; index < sizeof(message) - 1u; ++index) {
            uart_send(message[index]);
        }
    }
}
