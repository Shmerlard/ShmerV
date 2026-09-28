# CPU system

Runs a program from `sw/programs/` on the complete FPGA system.

```sh
just fpga-build cpu_system PROGRAM
just fpga-flash cpu_system PROGRAM
```

- `gpio_pattern`: alternate the LEDs between `0xAA` and `0x55`.
- `gpio_nibble_sum`: add the DIP-switch nibbles and show the result on the LEDs.

- Reset: pin 49, active-low.
- GPIO0 / Port A: `0x10000000`, pins 25–30, 33, and 34.
- GPIO1 / Port B: `0x10000100`, pins 70–77.
- RAM: 16 KiB.

Both GPIO ports are bidirectional; software controls them through `DIR`.
