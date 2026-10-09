#include "ShmerV.h"

int main(void)
{
    volatile uint8_t *const gpio0_out =
        (volatile uint8_t *)(PORTA_BASE + GPIO_OUT_OFFSET);
    volatile uint8_t *const gpio0_dir =
        (volatile uint8_t *)(PORTA_BASE + GPIO_DIR_OFFSET);
    volatile uint8_t *const gpio1_in =
        (volatile uint8_t *)(PORTB_BASE + GPIO_IN_OFFSET);
    volatile uint8_t *const gpio1_dir =
        (volatile uint8_t *)(PORTB_BASE + GPIO_DIR_OFFSET);

    *gpio0_dir = 0xFFu;
    *gpio1_dir = 0x00u;

    while (1) {
        uint8_t input = (uint8_t)~*gpio1_in;
        uint8_t low_nibble = input & 0x0Fu;
        uint8_t high_nibble = input >> 4;
        *gpio0_out = low_nibble + high_nibble;
    }
}
