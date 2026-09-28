# Standalone GPIO output-register test

- DIP switches provide the GPIO `OUT` write value.
- Pin 48 is the manual clock.
- Pin 49 is synchronous reset.
- Pin 31 is write-enable.
- LEDs show `pin_o`.

Reset: hold pin 49 and press pin 48.

Write: set the DIP switches, hold pin 31, and press pin 48.

This test bypasses `pin_oe_o`, so it does not test `DIR` or tri-state behavior.

Build: `just fpga-build gpio_bringup`

Temporary SRAM load: `just fpga-flash gpio_bringup`
