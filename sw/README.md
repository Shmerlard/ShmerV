# Software

This directory contains the small bare-metal software used to exercise the
ShmerV CPU. `runtime/start.S` initializes the stack, clears `.bss`, and calls
`main` for C programs. CPU-system test programs live in `tests/cpu_system/`.

From the repository root, build either source type into an ELF, binary, and
hex memory image:

```sh
# Assembly (.S)
scripts/build_cpu_system_program.sh sw/tests/cpu_system/basic/basic.S build/cpu_system/basic

# Freestanding C (.c); the startup runtime is linked automatically
scripts/build_cpu_system_program.sh sw/tests/cpu_system/c_basic/c_basic.c build/cpu_system/c_basic
```

Run the compiled program on the simulated CPU (and compare it with Spike):

```sh
just test cpu_system basic
just test cpu_system c_basic
```

The resulting `program.elf` keeps symbols, while `program.hex` initializes
the simulated memory.
