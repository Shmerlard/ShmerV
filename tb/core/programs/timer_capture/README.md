Exercises manual Timer A capture through CPU MMIO and the cause-23 runtime vector.
Checks DONE interrupts with and without a real counter wrap, START interrupts,
acknowledgement by DELTA read/control write, single-shot completion, and MRET.

Run: `CPU_TEST_TIMEOUT_CYCLES=30000 just test soc timer_capture`.
