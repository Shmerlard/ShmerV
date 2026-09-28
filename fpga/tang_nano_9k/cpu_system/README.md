# CPU system

This target runs a selected program from `sw/programs/` on the complete CPU
system. For example, `gpio_pattern` alternates the LEDs between `0xAA` and
`0x55`.

Build the program and FPGA bitstream together:

```sh
just fpga-build cpu_system gpio_pattern
```

Load it temporarily into SRAM:

```sh
just fpga-flash cpu_system gpio_pattern
```

Pin 49 is the active-low reset input. The LED outputs use the same pins as the
GPIO bring-up target. This system uses 16 KiB of RAM so the inferred dual-port
memory fits the Tang Nano 9K block-RAM capacity.
