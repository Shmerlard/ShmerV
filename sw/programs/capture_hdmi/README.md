# Button capture to HDMI

Displays `hello, press the button at C.5`, then prints each captured pulse width
on a new line. Timer A runs continuously with divide-by-1024; results are timer
ticks, not raw CPU cycles. The cause-23 handler reads DELTA to acknowledge the
interrupt; single-shot capture is rearmed by main after displaying the result.
Rows 1–29 are reused when full; the prompt remains on row 0.

Connect the button to C.5 with a shared ground and an external pull-down so the
input is low when released and high when pressed. For active-low wiring, change
`CAPTURE_BUTTON_ACTIVE_LOW` to 1 and provide a pull-up instead. GPIO synchronizes
the input, but this demo does not debounce mechanical contacts: the first
matching pair of edges determines the result.
Keep the pull-down connected directly between C.5 and ground, with the button
connecting C.5 to 3.3 V. Disconnecting that bias leaves a floating input and
can produce spurious 0/1-tick readings; these do not validate a button pulse.

At the default board clock of 27 MHz / 4 = 6.75 MHz, one tick is about 151.7 us
and the measurement range is about 9.94 s. An interval of 65536 ticks or more
prints an overflow message instead of a misleading wrapped duration.

Build/program using the existing FPGA workflow with program `capture_hdmi`.
The hardware image must include the new capture logic, C.5 routing, and /1024
divider; a firmware-only repack of an older hardware image is insufficient.

Hardware validation: the user confirmed working button measurements and HDMI
output on Tang Nano 9K. Floating-input 0/1-tick readings were also observed.
