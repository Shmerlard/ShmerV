#include <stdint.h>
#include "../../../../sw/include/shmerv_interrupt.h"

#define GPIO_REG(offset) (*(volatile uint8_t *)(0x10000000u + (offset)))

static volatile uint32_t interrupt_count;
static volatile uintptr_t handler_addresses[6];

SHMERV_INTERRUPT("GPIO_A", arbitrary_gpio_handler)
void arbitrary_gpio_handler(void)
{
    ++interrupt_count;
    GPIO_REG(0x04) = (uint8_t)interrupt_count;
    GPIO_REG(0x1c) = 1u;  /* Clear the pending event before MRET. */
}

extern void __irq_GPIO_B(void);
extern void __irq_GPIO_C(void);
extern void __irq_UART_RX(void);
extern void exception_handler(void);
extern void __default_trap_handler(void);
extern void __unhandled_interrupt(void);

int main(void)
{
    /* Volatile addresses prevent C from assuming differently named functions differ.
       The linker resolves these weak aliases; executing the IRQ checks the override. */
    handler_addresses[0] = (uintptr_t)__irq_GPIO_B;
    handler_addresses[1] = (uintptr_t)__irq_GPIO_C;
    handler_addresses[2] = (uintptr_t)__irq_UART_RX;
    handler_addresses[3] = (uintptr_t)__unhandled_interrupt;
    handler_addresses[4] = (uintptr_t)exception_handler;
    handler_addresses[5] = (uintptr_t)__default_trap_handler;
    if (handler_addresses[0] != handler_addresses[3]
        || handler_addresses[1] != handler_addresses[3]
        || handler_addresses[2] != handler_addresses[3]
        || handler_addresses[4] != handler_addresses[5])
        return 2;

    GPIO_REG(0x08) = 0xffu;
    GPIO_REG(0x1c) = 0xffu;
    GPIO_REG(0x10) = 1u;
    GPIO_REG(0x18) = 1u;  /* Software event exercises the complete GPIO-to-CPU path. */
    __asm__ volatile (
        ".option push\n"
        ".option arch, +zicsr\n"
        "csrsi mstatus, 8\n"
        ".option pop\n"
        ::: "memory");

    while (interrupt_count == 0u) {}
    if (interrupt_count != 1u || GPIO_REG(0x18) != 0u || GPIO_REG(0x04) != 1u)
        return 3;
    return 1;
}
