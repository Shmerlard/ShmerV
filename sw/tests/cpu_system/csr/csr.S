  .option norvc
  .option arch, +zicsr
  .section .text
  .global _start

_start:
  # CSRRW returns the old CSR value and writes rs1 into the CSR.
  addi x1, x0, 64
  csrrw x2, mtvec, x1
  csrrw x3, mtvec, x0

  # rd=x0 suppresses the read but must still write the CSR.
  csrrw x0, mtvec, x1
  csrrw x4, mtvec, x0

  # CSRRS sets masked bits and returns the old CSR value.
  csrrw x0, mtvec, x1
  addi x5, x0, 128
  csrrs x6, mtvec, x5

  # CSRRC clears masked bits and returns the old CSR value.
  csrrc x7, mtvec, x1

  # rs1=x0 performs a read without modifying the CSR.
  csrrs x8, mtvec, x0
  csrrc x9, mtvec, x0

  # rd=x0 still modifies the CSR.
  addi x10, x0, 256
  csrrs x0, mtvec, x10
  csrrs x11, mtvec, x0

_test_end:
  j _test_end
