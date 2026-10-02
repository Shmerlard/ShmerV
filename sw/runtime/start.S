.option norvc
.option arch, +zicsr
.section .text._start
.global _start
.global _test_end

_start:
    la sp, __stack_top

    la t0, __vector_table
    ori t0, t0, 1
    csrw mtvec, t0

    la t0, __bss_start
    la t1, __bss_end
    beq t0, t1, .Lbss_done

.Lclear_bss:
    sw zero, 0(t0)
    addi t0, t0, 4
    bne t0, t1, .Lclear_bss

.Lbss_done:
    call main

_test_end:
    j _test_end

.global __default_trap_handler
__default_trap_handler:
    j __default_trap_handler

.global __unhandled_interrupt
__unhandled_interrupt:
    j __unhandled_interrupt

.weak exception_handler
.set exception_handler, __default_trap_handler

.weak __irq_UART_RX
.set __irq_UART_RX, __unhandled_interrupt

.weak __irq_GPIO_A
.set __irq_GPIO_A, __unhandled_interrupt

.weak __irq_GPIO_B
.set __irq_GPIO_B, __unhandled_interrupt

.weak __irq_GPIO_C
.set __irq_GPIO_C, __unhandled_interrupt

.section .vectors, "ax"
.balign 4
.global __vector_table
__vector_table:
    j exception_handler
    j exception_handler   # 1
    j exception_handler   # 2
    j exception_handler   # 3
    j exception_handler   # 4
    j exception_handler   # 5
    j exception_handler   # 6
    j exception_handler   # 7
    j exception_handler   # 8
    j exception_handler   # 9
    j exception_handler   # 10
    j exception_handler   # 11
    j exception_handler   # 12
    j exception_handler   # 13
    j exception_handler   # 14
    j exception_handler   # 15
    j __irq_UART_RX       # cause 16
    j __irq_GPIO_A        # cause 17
    j __irq_GPIO_B        # cause 18
    j __irq_GPIO_C        # cause 19
