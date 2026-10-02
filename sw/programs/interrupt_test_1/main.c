#include "ShmerV.h"

static volatile uint8_t interrupt_count;
static volatile uint8_t button_waiting_for_release;

static void delay_one_millisecond(void)
{
    /* Approximate delay at the current 843.75 kHz CPU clock. */
    uint32_t remaining = 211u;
    __asm__ volatile (
        "1: addi %0, %0, -1\n"
        "bnez %0, 1b\n"
        : "+r" (remaining)
        :
        : "memory");
}

SHMERV_INTERRUPT("GPIO_A", button_handler)
void button_handler(void)
{
    PORTA_IE = 0x00u;
    button_waiting_for_release = 1u;
    ++interrupt_count;
    /* Display the binary count on all eight LEDs; wrap after 255. */
    PORTC_OUT = interrupt_count;
    PORTA_IFG_CLR = 0x01u;
}

int main(void)
{
    PORTC_SEL = 0x00u;
    PORTC_OUT = 0x00u;
    PORTC_DIR = 0xFFu;

    PORTA_IE = 0x00u;
    PORTA_SEL = 0x00u;
    PORTA_DIR = 0x00u;
    PORTA_IES = 0x01u; /* A.0: falling edge when the button connects to GND. */
    PORTA_IFG_CLR = 0xFFu;
    PORTA_IE = 0x01u;

    __asm__ volatile (
        ".option push\n"
        ".option arch, +zicsr\n"
        "csrsi mstatus, 8\n"
        ".option pop\n"
        ::: "memory");

    while (1) {
        if (button_waiting_for_release) {
            uint8_t stable_release_samples = 0;
            /* Re-arm only after approximately 20 ms of continuous release. */
            while (stable_release_samples < 20u) {
                delay_one_millisecond();
                if (PORTA_IN & 0x01u)
                    ++stable_release_samples;
                else
                    stable_release_samples = 0;
            }
            /* GPIO records edges even while its interrupt is masked. */
            PORTA_IFG_CLR = 0x01u;
            button_waiting_for_release = 0u;
            PORTA_IE = 0x01u;
        }
    }
}
