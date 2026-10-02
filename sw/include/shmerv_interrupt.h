#ifndef SHMERV_INTERRUPT_H
#define SHMERV_INTERRUPT_H

#define SHMERV_INTERRUPT(source, handler) \
    void handler(void) __asm__("__irq_" source) \
    __attribute__((interrupt("machine"), used));

#endif
