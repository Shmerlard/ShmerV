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

_test_end:
  j _test_end
