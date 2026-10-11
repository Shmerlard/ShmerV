#ifndef SHMERV_INTERRUPT_H
#define SHMERV_INTERRUPT_H

/* Custom interrupt sources supported by the current SoC and runtime vectors. */
#define SHMERV_IRQ_GPIO_A           "GPIO_A"           /* Cause 17. */
#define SHMERV_IRQ_GPIO_B           "GPIO_B"           /* Cause 18. */
#define SHMERV_IRQ_GPIO_C           "GPIO_C"           /* Cause 19. */
#define SHMERV_IRQ_TIMER_A_OVERFLOW "TIMER_A_OVERFLOW" /* Cause 20. */
#define SHMERV_IRQ_TIMER_A_COMPARE  "TIMER_A_COMPARE"  /* Cause 21; shared by CCR1/CCR2. */

/* Cause 16: UART RX pending. Reading UART_RX_DATA acknowledges it.
   Select PORTC_UART_RX_PIN in PORTC_SEL, and set UART_ENABLE and UART_RX_IE. */
#define SHMERV_IRQ_UART_RX "UART_RX"

#define SHMERV_INTERRUPT(source, handler) \
    void handler(void) __asm__("__irq_" source) \
    __attribute__((interrupt("machine"), used));

static inline void shmerv_interrupt_enable(void)
{
    __asm__ volatile (
        ".option push\n"
        ".option arch, +zicsr\n"
        "csrsi mstatus, 8\n"
        ".option pop\n"
        ::: "memory");
}

#endif
