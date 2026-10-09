#include "ShmerV.h"

static void delay(void)
{
    for (volatile uint32_t count = 0; count < 1000000u; ++count) {
    }
}

int main(void)
{
    volatile uint8_t *const gpio_out =
        (volatile uint8_t *)(PORTA_BASE + GPIO_OUT_OFFSET);
    volatile uint8_t *const gpio_dir =
        (volatile uint8_t *)(PORTA_BASE + GPIO_DIR_OFFSET);

    *gpio_dir = 255u;

    while (1) {
        *gpio_out = 170u;
        delay();
        *gpio_out = 85u;
        delay();
    }
}
