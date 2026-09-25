  .option norvc
  .option arch, +zicsr
  .section .text
  .global _start

_start:
  # Configure the common Machine-mode trap entry point.
  la x5, trap_handler
  csrw mtvec, x5

  # These older instructions must complete before the trap is taken.
  addi x2, x0, 2
  addi x3, x0, 3
  addi x1, x0, 1

illegal_instruction:
  .word 0xffffffff

  # These younger instructions must be flushed.
  addi x2, x0, 99
  addi x3, x0, 99

  .align 2
trap_handler:
  csrr x10, mcause
  csrr x11, mepc
  csrr x12, mtval
  addi x13, x0, 13

_test_end:
  j _test_end
