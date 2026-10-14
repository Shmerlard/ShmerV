  .option norvc
  .section .text
  .global _start

_start:
  lui x10, 0x80000
  addi x10, x10, 256

  # Start both test words with the same recognizable value.
  lui x1, 0x11223
  addi x1, x1, 0x344
  sw x1, 0(x10)
  sw x1, 4(x10)

  # Replace each byte lane independently.
  addi x2, x0, 0x0aa
  sb x2, 0(x10)
  addi x2, x0, 0x0bb
  sb x2, 1(x10)
  addi x2, x0, 0x0cc
  sb x2, 2(x10)
  addi x2, x0, 0x0dd
  sb x2, 3(x10)

  # Replace the lower and upper halfwords independently.
  lui x3, 0x0000a
  addi x3, x3, 0x1b2
  sh x3, 4(x10)
  lui x4, 0x0000c
  addi x4, x4, 0x3d4
  sh x4, 6(x10)

_test_end:
  j _test_end
