  .option norvc
  .option arch, +zicsr
  .section .text
  .global _start

_start:
  # Use supported Vectored mode explicitly rather than relying on reset values.
  csrrwi x0, mtvec, 1
  # CSRRW returns the old CSR value and writes rs1 into the CSR.
  addi x1, x0, 65
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
  addi x5, x0, 64
  csrrc x7, mtvec, x5

  # rs1=x0 performs a read without modifying the CSR.
  csrrs x8, mtvec, x0
  csrrc x9, mtvec, x0

  # rd=x0 still modifies the CSR.
  addi x10, x0, 256
  csrrs x0, mtvec, x10
  csrrs x11, mtvec, x0

  # CSRRWI writes the immediate and returns the old CSR value.
  csrrwi x12, mtvec, 21
  csrrwi x13, mtvec, 5

  # rd=x0 still writes the immediate.
  csrrwi x0, mtvec, 17

  # CSRRSI sets immediate-selected bits and returns the old value.
  csrrsi x14, mtvec, 8

  # CSRRCI clears immediate-selected bits and returns the old value.
  csrrci x15, mtvec, 8

  # zimm=0 reads without modifying the CSR.
  csrrsi x16, mtvec, 0
  csrrci x17, mtvec, 0

  # rd=x0 still modifies the CSR for nonzero immediate masks.
  csrrsi x0, mtvec, 4
  csrrsi x18, mtvec, 0
  csrrci x0, mtvec, 12
  csrrci x19, mtvec, 0

_test_end:
  j _test_end
