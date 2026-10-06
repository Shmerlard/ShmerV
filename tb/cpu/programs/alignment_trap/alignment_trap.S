  .option norvc
  .option arch, +zicsr
  .section .text
  .global _start

  # Handler expectations: x20 = fault PC, x21 = address, x22 = cause,
  # x23 = resume PC. x10 counts traps; x11 is the failure flag.
  .macro check_fault operation, offset, cause
    la x20, fault_\@
    addi x21, x5, \offset
    li x22, \cause
    la x23, resume_\@
fault_\@:
    \operation x18, \offset(x5)
    # Both younger side effects must be flushed, rather than executed.
    addi x19, x19, 1
    sw x0, 8(x5)
    # Reaching here without a trap is also a failure.
    j failed
resume_\@:
  .endm

_start:
  la x5, trap_handler
  csrw mtvec, x5
  li x5, 0x80001000
  li x10, 0
  li x11, 0
  li x18, 0x12345678
  li x19, 0

  # Aligned stores initialize neighboring words and a younger-store marker.
  sw x18, 0(x5)
  li x6, 0x76543210
  sw x6, 4(x5)
  sw x18, 8(x5)

  # All nonzero word offsets, and both odd halfword offsets.
  check_fault lh,  1, 4
  check_fault lh,  3, 4
  check_fault lhu, 1, 4
  check_fault lhu, 3, 4
  check_fault lw,  1, 4
  check_fault lw,  2, 4
  check_fault lw,  3, 4
  check_fault sh,  1, 6
  check_fault sh,  3, 6
  check_fault sw,  1, 6
  check_fault sw,  2, 6
  check_fault sw,  3, 6

  # Positive controls: aligned halfwords/words and odd-address byte accesses.
  lw x12, 0(x5)
  lw x13, 4(x5)
  lw x14, 8(x5)
  lh x15, 2(x5)
  lbu x16, 1(x5)
  sb x16, 13(x5)
  lbu x17, 13(x5)
  sh x15, 14(x5)
  lhu x24, 14(x5)
  j _test_end

  .align 2
trap_handler:
  csrr x6, mcause
  bne x6, x22, failed
  csrr x6, mepc
  bne x6, x20, failed
  csrr x6, mtval
  bne x6, x21, failed
  addi x10, x10, 1
  csrw mepc, x23
  mret

failed:
  li x11, 1
_test_end:
  j _test_end
