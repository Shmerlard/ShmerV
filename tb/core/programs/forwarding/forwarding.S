  .option norvc
  .section .text
  .global _start

_start:
  # Back-to-back ALU dependencies.
  addi x1, x0, 7
  addi x2, x1, 5
  add x3, x2, x1
  sub x4, x3, x2
  xor x5, x4, x3

  # A store that needs its address from WB and its data from MEM.
  lui x10, 0x80000
  addi x10, x10, 256
  addi x11, x0, 0x123
  sw x11, 0(x10)

  # Forward one result to both operands.
  addi x12, x0, 3
  add x13, x12, x12

  # Forward rs1 from WB and rs2 from MEM.
  addi x14, x0, 1
  addi x15, x0, 2
  add x16, x14, x15

  # MEM must win when MEM and WB both target x20.
  addi x20, x0, 1
  addi x20, x20, 2
  add x21, x20, x0

  # Branch comparisons also use forwarded operands.
  addi x22, x0, 5
  addi x23, x0, 5
  beq x22, x23, branch_ok
  addi x24, x0, 99
branch_ok:
  addi x24, x0, 24

  # Reproducible pseudo-random xorshift sequence with dense dependencies.
  addi x25, x0, 1
  addi x26, x0, 32
random_loop:
  slli x27, x25, 13
  xor x25, x25, x27
  srli x27, x25, 17
  xor x25, x25, x27
  slli x27, x25, 5
  xor x25, x25, x27
  addi x26, x26, -1
  bne x26, x0, random_loop

  # The final x25 reaches this store through WB forwarding.
  sw x25, 4(x10)

_test_end:
  j _test_end
