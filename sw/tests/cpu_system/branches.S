  .option norvc
  .section .text
  .global _start

_start:
  addi x1, x0, 5
  addi x2, x0, 5
  addi x3, x0, -1
  addi x4, x0, 1
  .rept 4
  nop
  .endr

  addi x11, x0, 11
  beq x1, x2, beq_taken
  addi x11, x0, 99
  addi x11, x0, 98
beq_taken:

  addi x12, x0, 12
  bne x1, x4, bne_taken
  addi x12, x0, 99
  addi x12, x0, 98
bne_taken:

  addi x13, x0, 13
  blt x3, x4, blt_taken
  addi x13, x0, 99
  addi x13, x0, 98
blt_taken:

  addi x14, x0, 14
  bge x1, x4, bge_taken
  addi x14, x0, 99
  addi x14, x0, 98
bge_taken:

  addi x15, x0, 15
  bltu x4, x3, bltu_taken
  addi x15, x0, 99
  addi x15, x0, 98
bltu_taken:

  addi x16, x0, 16
  bgeu x3, x4, bgeu_taken
  addi x16, x0, 99
  addi x16, x0, 98
bgeu_taken:

  # This branch must not be taken, so the fall-through value must survive.
  bne x1, x2, bne_unexpected
  addi x17, x0, 17
  jal x0, branches_done
bne_unexpected:
  addi x17, x0, 99

branches_done:
  .rept 8
  nop
  .endr

_test_end:
  j _test_end
