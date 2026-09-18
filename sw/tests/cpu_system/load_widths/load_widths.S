  .option norvc
  .section .text
  .global _start

_start:
  lui x10, 0x80000
  addi x10, x10, 256

  # Little-endian bytes at offsets 0..3: FF, 01, 7F, 80.
  lui x20, 0x807f0
  addi x20, x20, 0x1ff
  sw x20, 0(x10)

  # Signed byte loads from every byte lane.
  lb x1, 0(x10)
  lb x2, 1(x10)
  lb x3, 2(x10)
  lb x4, 3(x10)

  # Unsigned byte loads from every byte lane.
  lbu x5, 0(x10)
  lbu x6, 1(x10)
  lbu x7, 2(x10)
  lbu x8, 3(x10)

  # Both aligned halfword positions, signed and unsigned.
  lh x11, 0(x10)
  lh x12, 2(x10)
  lhu x13, 0(x10)
  lhu x14, 2(x10)

  # A word load must remain unchanged.
  lw x15, 0(x10)

_test_end:
  j _test_end
