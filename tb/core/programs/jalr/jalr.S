  .option norvc
  .section .text
  .global _start

_start:
  # Give JALR the odd address 0x80000035; it must jump to 0x80000034.
  lui x2, 0x80000
  .rept 4
  nop
  .endr
  addi x2, x2, 0x35
  .rept 4
  nop
  .endr

  jalr x5, 0(x2)
  addi x3, x0, 1
  addi x3, x0, 2

target:
  # The link value proves that JALR entered this instruction with an even PC.
  jal x6, aligned_target
  addi x3, x0, 3
  addi x3, x0, 4

aligned_target:
  lui x10, 0x80000
  .rept 4
  nop
  .endr
  addi x10, x10, 256
  .rept 4
  nop
  .endr

  sw x5, 0(x10)
  sw x6, 4(x10)
  .rept 8
  nop
  .endr

_test_end:
  j _test_end
