#include "ShmerV.h"

#define LED1 GPIO_PIN2
#define LED2 GPIO_PIN3
static volatile uint32_t cycles, phase, errors, compare1_count, compare2_count;

static void check_interrupt(uint32_t cause, uint32_t expected_phase,
                            uint8_t expected_output)
{
    uint32_t actual;
    __asm__ volatile (".option push\n.option arch, +zicsr\n"
                      "csrr %0, mcause\n.option pop" : "=r"(actual));
    if (actual != (0x80000000u | cause) || phase != expected_phase ||
        PORTC_OUT != expected_output)
        ++errors;
}

SHMERV_INTERRUPT(SHMERV_IRQ_TIMER_A_COMPARE_1, compare1_handler)
void compare1_handler(void)
{
    check_interrupt(21u, 0u, 0u);
    PORTC_OUT |= LED1;
    TA_COMPARE1_CTRL = TA_COMPARE_IE;
    phase = 1u;
    ++compare1_count;
}

SHMERV_INTERRUPT(SHMERV_IRQ_TIMER_A_COMPARE_2, compare2_handler)
void compare2_handler(void)
{
    check_interrupt(22u, 1u, LED1);
    PORTC_OUT |= LED2;
    TA_COMPARE2_CTRL = TA_COMPARE_IE;
    phase = 2u;
    ++compare2_count;
}

SHMERV_INTERRUPT(SHMERV_IRQ_TIMER_A_OVERFLOW, overflow_handler)
void overflow_handler(void)
{
    check_interrupt(20u, 2u, LED1 | LED2);
    PORTC_OUT = 0u;
    TA_CTRL = (uint16_t)(TA_CTRL & (uint16_t)~TA_OVERFLOW_PENDING);
    phase = 0u;
    ++cycles;
    if (cycles == 3u)
        TA_CTRL = 0u;
}

int main(void)
{
    TA_CTRL = 0u;
    PORTC_SEL = 0u;
    PORTC_OUT = 0u;
    PORTC_DIR = LED1 | LED2;
    TA_COUNTER = 0u;
    /* UP mode counts 0..999: 1000 ticks per cycle. */
    TA_PERIOD = 999u;
    TA_COMPARE1 = 250u;
    TA_COMPARE2 = 750u;
    TA_COMPARE1_CTRL = TA_COMPARE_IE;
    TA_COMPARE2_CTRL = TA_COMPARE_IE;
    shmerv_interrupt_enable();
    TA_CTRL = TA_MODE_UP | TA_DIV_16 | TA_INTERRUPT_ENABLE | TA_OVERFLOW_IE;

    while (cycles < 3u) {}
    if (errors || compare1_count != 3u || compare2_count != 3u ||
        phase || PORTC_OUT || TA_CTRL ||
        (TA_COMPARE1_CTRL & TA_COMPARE_PENDING) || (TA_COMPARE2_CTRL & TA_COMPARE_PENDING))
        return 2;
    return 1;
}
