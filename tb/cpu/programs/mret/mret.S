  .option norvc
  .option arch, +zicsr
  .section .text
  .global _start

_start:
  la x5, trap_handler
  csrw mtvec, x5

  # MRET should later restore this interrupt-enable state.
  addi x6, x0, 8
  csrw mstatus, x6

  addi x1, x0, 1
  addi x2, x0, 2
  addi x3, x0, 3

  # Enter the handler through an illegal-instruction exception.
  .word 0xffffffff

  # This instruction is younger than the fault and must be flushed.
  addi x2, x0, 99

  .align 2
trap_handler:
  # Observe trap-entry status before returning.
  csrr x10, mstatus

  # Skip the illegal instruction by choosing an explicit return address.
  la x7, return_from_trap
  csrw mepc, x7
  mret

  # This instruction is younger than MRET and must be flushed.
  addi x3, x0, 99

return_from_trap:
  csrr x11, mstatus
  andi x11, x11, 0x88
  addi x12, x0, 12

_test_end:
  j _test_end
