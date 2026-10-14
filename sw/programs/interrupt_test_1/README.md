# GPIO interrupt counter

Active-low A.0 / pin 51 adds 1; A.1 / pin 53 adds 2. C.1–C.7 display the
low seven counter bits. C.0 / pin 38 sends A through Z over UART, one letter
per accepted button press, at 9600 baud, 8N1. Reset restarts at A.
Simultaneous button flags perform both increments and transmissions.

Interrupts resume after 20 consecutive samples with both buttons released.
A.1 needs an external pull-up; A.0 uses the configured internal pull-up.
Software debounce delays depend on CPU frequency. TX waits poll START/BUSY.
