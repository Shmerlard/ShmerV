#ifndef SHMERV_INTERRUPT_H
#define SHMERV_INTERRUPT_H

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
