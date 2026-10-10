#include "ShmerV.h"

#ifndef TIMER_OVERFLOW_PERIOD
#define TIMER_OVERFLOW_PERIOD 26367u
#endif

#define LED_MASK GPIO_PIN2
#define PWM_MASK (PORTC_TA_CCR1_PIN | PORTC_TA_CCR2_PIN)
static volatile uint32_t overflow_count;

SHMERV_INTERRUPT(SHMERV_IRQ_TIMER_A_OVERFLOW, timer_overflow_handler)
void timer_overflow_handler(void)
{
    PORTC_OUT ^= LED_MASK;
    TA_CTRL = (uint16_t)(TA_CTRL & (uint16_t)~TA_OVERFLOW_PENDING);
    ++overflow_count;
#ifdef TIMER_OVERFLOW_TEST
    if (overflow_count == 3u)
        TA_CTRL = 0u;
#endif
}

int main(void)
{
    TA_CTRL = 0u;
    PORTC_SEL = PWM_MASK;
    PORTC_OUT = 0u;
    PORTC_DIR = GPIO_PIN1 | GPIO_PIN3 | LED_MASK;
    TA_COUNTER = 0u;
    TA_PERIOD = TIMER_OVERFLOW_PERIOD;
    /* CCR1: 75% duty; CCR2: 25% duty. */
    TA_CCR1 = (TIMER_OVERFLOW_PERIOD + 1u) / 4u - 1u;
    TA_CCR2 = 3u * ((TIMER_OVERFLOW_PERIOD + 1u) / 4u) - 1u;
    TA_CCR1_CTRL = TA_CCR_SET_RESET;
    TA_CCR2_CTRL = TA_CCR_SET_RESET;

    shmerv_interrupt_enable();
    TA_CTRL = TA_MODE_UP | TA_DIV_16 | TA_INTERRUPT_ENABLE | TA_OVERFLOW_IE;

#ifdef TIMER_OVERFLOW_TEST
    while (overflow_count < 3u) {}
    if (overflow_count != 3u || PORTC_OUT != LED_MASK || TA_CTRL != 0u)
        return 2;
    return 1;
#else
    while (1) {}
#endif
}
