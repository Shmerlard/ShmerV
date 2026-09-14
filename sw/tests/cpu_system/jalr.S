  .option norvc
  .section .text
  .global _start

_start:
  # Give JALR the odd address 0x25; it must clear bit 0 and jump to 0x24.
  .ifdef SPIKE_REFERENCE
  lui x2, 0x80000
  addi x2, x2, 0x25
  .else
  nop
  addi x2, x0, 0x25
  .endif
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
  .ifdef SPIKE_REFERENCE
  lui x10, 0x80000
  addi x10, x10, 256
  .else
  nop
  addi x10, x0, 256
  .endif
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
