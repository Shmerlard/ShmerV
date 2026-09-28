  .option norvc
  .section .text
  .global _start

_start:
  lui x10, 0x80000
  .rept 4
  nop
  .endr
  addi x10, x10, 256
  .rept 4
  nop
  .endr

  addi x1, x0, 5
  .rept 4
  nop
  .endr

  addi x2, x1, 3
  .rept 4
  nop
  .endr

  sw x2, 0(x10)
  .rept 4
  nop
  .endr

  lw x3, 0(x10)
  .rept 8
  nop
  .endr

_test_end:
  j _test_end
