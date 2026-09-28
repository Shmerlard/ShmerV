#include <stdint.h>

#define GPIO_BASE_ADDRESS 0x10000000u
#define GPIO_OUT_OFFSET 0x04u
#define GPIO_DIR_OFFSET 0x08u

static void delay(void)
{
    for (volatile uint32_t count = 0; count < 1000000u; ++count) {
    }
}

int main(void)
{
    volatile uint8_t *const gpio_out =
        (volatile uint8_t *)(GPIO_BASE_ADDRESS + GPIO_OUT_OFFSET);
    volatile uint8_t *const gpio_dir =
        (volatile uint8_t *)(GPIO_BASE_ADDRESS + GPIO_DIR_OFFSET);

    *gpio_dir = 255u;

    while (1) {
        *gpio_out = 170u;
        delay();
        *gpio_out = 85u;
        delay();
    }
}
