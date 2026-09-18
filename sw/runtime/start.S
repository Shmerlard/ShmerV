.option norvc
.section .text._start
.global _start
.global _test_end

_start:
    la sp, __stack_top

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
