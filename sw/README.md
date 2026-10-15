# Software

This directory contains bare-metal programs and their shared support files.
`runtime/start.S` initializes the stack, clears `.bss`, and calls `main` for C
programs. Linker scripts describe the available memory, while runnable FPGA
programs live under `programs/`. Test-only programs live under `tb/core/programs/`.

Use `ShmerV.h` for shared MMIO definitions rather than duplicating addresses in
programs. Peripheral bases match `rtl/types/soc_address_map.sv`; local register
indices remain in the peripheral packages.

`shmerv_memory_map.h` contains MMIO region bases, address-window sizes, SoC pin
connections, and shared volatile MMIO access macros.
Register offsets, access macros, and bit definitions live in `shmerv_gpio.h`
(shared by ports A/B/C), `shmerv_uart.h`, `shmerv_timer.h`, and `shmerv_hdmi.h`.
`ShmerV.h` includes all of these headers so existing programs retain the same interface.

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
COMPARE1/COMPARE2 generate 75%/25% PWM on GPIO2.7/GPIO2.6; compare interrupts are disabled.
Causes 20/21/22 have weak runtime entries for overflow, COMPARE1, and COMPARE2;
programs can override them with `SHMERV_INTERRUPT(SHMERV_IRQ_TIMER_A_OVERFLOW, handler)`
or `SHMERV_INTERRUPT(SHMERV_IRQ_TIMER_A_COMPARE_1, handler)` /
`SHMERV_INTERRUPT(SHMERV_IRQ_TIMER_A_COMPARE_2, handler)`. Unused entries retain the
default unhandled-interrupt loop.

Timer A capture 1 exposes CTRL/START/END/DELTA at offsets `0x1C`/`0x20`/`0x24`/`0x28`.
`shmerv_timer.h` defines the halfword registers and control fields. External
capture uses synchronized GPIO C.5 when `PORTC_TA_CAPTURE1_PIN` is set in
`PORTC_SEL`; the alternate function keeps that pin as an input. Interval
measurement requires continuous counting without software counter writes.
Reading DELTA acknowledges capture pending. Capture uses cause 23 and
`SHMERV_IRQ_TIMER_A_CAPTURE_1`; it has lower priority than Timer A overflow
and both compare channels, and higher priority than UART RX.

Capture behavior and verification are documented in
[Timer A capture](../rtl/peripherals/timer_a/README.md).
The CPU-only `timer_capture` regression runs with
`CPU_TEST_TIMEOUT_CYCLES=30000 just test soc timer_capture`.

Run the bounded CPU simulation of the same demo:

```sh
CPU_TEST_TIMEOUT_CYCLES=10000 just test soc timer_overflow
```
