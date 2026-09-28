#include <stdint.h>

#define GPIO0_BASE_ADDRESS 0x10000000u
#define GPIO1_BASE_ADDRESS 0x10000100u
#define GPIO_IN_OFFSET 0x00u
#define GPIO_OUT_OFFSET 0x04u
#define GPIO_DIR_OFFSET 0x08u

int main(void)
{
    volatile uint8_t *const gpio0_out =
        (volatile uint8_t *)(GPIO0_BASE_ADDRESS + GPIO_OUT_OFFSET);
    volatile uint8_t *const gpio0_dir =
        (volatile uint8_t *)(GPIO0_BASE_ADDRESS + GPIO_DIR_OFFSET);
    volatile uint8_t *const gpio1_in =
        (volatile uint8_t *)(GPIO1_BASE_ADDRESS + GPIO_IN_OFFSET);
    volatile uint8_t *const gpio1_dir =
        (volatile uint8_t *)(GPIO1_BASE_ADDRESS + GPIO_DIR_OFFSET);

    *gpio0_dir = 0xFFu;
    *gpio1_dir = 0x00u;

    while (1) {
        uint8_t input = (uint8_t)~*gpio1_in;
        uint8_t low_nibble = input & 0x0Fu;
        uint8_t high_nibble = input >> 4;
        *gpio0_out = low_nibble + high_nibble;
    }
}
