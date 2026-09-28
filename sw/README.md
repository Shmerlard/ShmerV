# Software

This directory contains bare-metal programs and their shared support files.
`runtime/start.S` initializes the stack, clears `.bss`, and calls `main` for C
programs. Linker scripts describe the available memory, while runnable FPGA
programs live under `programs/`. Test-only programs live under `tb/cpu/programs/`.

From the repository root, build either source type into an ELF, binary, and
hex memory image:

```sh
# Test-only assembly (.S)
scripts/software/build_program.sh tb/cpu/programs/basic/basic.S build/cpu_system/basic

# FPGA C program; the startup runtime is linked automatically
scripts/software/build_program.sh sw/programs/gpio_pattern/main.c \
  build/software/gpio_pattern sw/linker/tang_nano_9k_16k.ld
```

Run a test-only program on the simulated CPU and compare it with Spike:

```sh
just test cpu_system basic
just test cpu_system c_basic
```

The resulting `program.elf` keeps symbols, while `program.hex` initializes
the simulated memory.
