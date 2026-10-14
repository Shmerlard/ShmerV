# Software

This directory contains bare-metal programs and their shared support files.
`runtime/start.S` initializes the stack, clears `.bss`, and calls `main` for C
programs. Linker scripts describe the available memory, while runnable FPGA
programs live under `programs/`. Test-only programs live under `tb/core/programs/`.

Use `ShmerV.h` for shared MMIO definitions rather than duplicating addresses in
programs. Peripheral bases match `rtl/types/soc_address_map.sv`; local register
indices remain in the peripheral packages.

From the repository root, build either source type into an ELF, binary, and
hex memory image:

```sh
# Test-only assembly (.S)
scripts/software/build_program.sh tb/core/programs/basic/basic.S build/soc/basic

# FPGA C program; the startup runtime is linked automatically
scripts/software/build_program.sh sw/programs/gpio_pattern/main.c \
  build/software/gpio_pattern sw/linker/tang_nano_9k_16k.ld
```

Run a test-only program on the simulated CPU and compare it with Spike:

```sh
just test soc basic
just test soc c_basic
```

The resulting `program.elf` keeps symbols, while `program.hex` initializes
the simulated memory.

`timer_overflow` configures Timer A in repeating up mode with divide-by-16.
Its cause-20 interrupt handler toggles GPIO2.2 and clears overflow pending.
At the default 843750 Hz CPU clock, it toggles roughly twice per second.
CCR1/CCR2 generate 75%/25% PWM on GPIO2.7/GPIO2.6; compare interrupts are disabled.
Causes 20/21/22 have weak runtime entries for overflow, CCR1, and CCR2;
programs can override them with `SHMERV_INTERRUPT(SHMERV_IRQ_TIMER_A_OVERFLOW, handler)`
or `SHMERV_INTERRUPT(SHMERV_IRQ_TIMER_A_COMPARE_1, handler)` /
`SHMERV_INTERRUPT(SHMERV_IRQ_TIMER_A_COMPARE_2, handler)`. Unused entries retain the
default unhandled-interrupt loop.

Run the bounded CPU simulation of the same demo:

```sh
CPU_TEST_TIMEOUT_CYCLES=10000 just test soc timer_overflow
```
