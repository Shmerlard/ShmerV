  .option norvc
  .section .text
  .global _start

_start:
  addi x10, x0, 256
  .rept 4
  nop
  .endr

  addi x2, x0, 42
  .rept 4
  nop
  .endr

  jal x0, target
  addi x2, x0, 1
  addi x2, x0, 2

target:
  sw x2, 0(x10)
  .rept 8
  nop
  .endr
