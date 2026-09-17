  .option norvc
  .section .text
  .global _start

_start:
  # Reproduce the original dense setup before the load-use dependency.
  lui x10, 0x80000
  addi x10, x10, 256
  addi x1, x0, 7
  sw x1, 0(x10)
  addi x1, x0, 5
  sw x1, 4(x10)

  # Loaded value consumed as both ALU operands.
  lw x5, 0(x10)
  add x6, x5, x5

  # Loaded value consumed as rs1.
  lw x7, 4(x10)
  addi x8, x7, 3

  # Loaded value consumed as rs2.
  lw x9, 0(x10)
  add x11, x0, x9

  # Store data consumes rs2.
  lw x12, 4(x10)
  sw x12, 8(x10)

  # A store consumes a loaded address through rs1.
  sw x10, 12(x10)
  lw x13, 12(x10)
  sw x1, 16(x13)

  # A branch consumes the loaded value immediately.
  addi x15, x0, 0
  lw x14, 4(x10)
  beq x14, x1, branch_taken
  addi x15, x0, 99
  jal x0, branch_done
branch_taken:
  addi x15, x0, 15
branch_done:

  # JALR consumes a loaded target address through rs1.
  la x16, jalr_target
  sw x16, 20(x10)
  lw x17, 20(x10)
  jalr x0, 0(x17)
  addi x18, x0, 99
jalr_target:
  addi x18, x0, 18

_test_end:
  j _test_end
