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

  jal x5, target
  addi x6, x0, 1
  addi x6, x0, 2

target:
  .rept 4
  nop
  .endr

  sw x5, 0(x10)
  .rept 8
  nop
  .endr

_test_end:
  j _test_end
