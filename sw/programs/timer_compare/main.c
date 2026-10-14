#include <ShmerV.h>

void system_init () {
    PORTC_SEL = 0;
    PORTC_DIR = 0b00000011;
    PORTC_OUT = 0b00000000;
    TA_PERIOD = 1000u;
    TA_CCR1 = 250u;
    TA_CCR2 = 750u;
    TA_COUNTER = 1u;
    TA_CCR1_CTRL = TA_CCR_IE;
    TA_CCR2_CTRL = TA_CCR_IE;
    TA_CTRL = TA_DIV_8 | TA_OVERFLOW_IE | TA_INTERRUPT_ENABLE;
}

void main () {
    system_init();
    shmerv_interrupt_enable();
    TA_CTRL |= TA_MODE_UP;
    
    while(1) {}
}


SHMERV_INTERRUPT(SHMERV_IRQ_TIMER_A_COMPARE_1, compare_1_handler)
void compare_1_handler(void) {

    PORTC_OUT |= 1u;
    TA_CCR1_CTRL &= ~TA_CCR_PENDING;
}

SHMERV_INTERRUPT(SHMERV_IRQ_TIMER_A_COMPARE_2, compare_2_handler)
void compare_2_handler(void) {
    PORTC_OUT |= 2u;
    TA_CCR2_CTRL &= ~TA_CCR_PENDING;

}

SHMERV_INTERRUPT(SHMERV_IRQ_TIMER_A_OVERFLOW, timer_a_overflow_handler)
void timer_a_overflow_handler(void) {
    PORTC_OUT = 0u;

    TA_CTRL &= ~TA_OVERFLOW_PENDING;
}
