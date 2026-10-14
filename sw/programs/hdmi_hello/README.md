# HDMI hello

Clear the screen, then write `hello world!` at the top-left, white on black.
The first character appears immediately; each following character, including
the space, arrives about one second later. The message stays until reset.

Timer A polls ten 100 ms periods with no interrupts. Timing assumes the
6.75 MHz CPU clock; `HDMI_HELLO_CPU_HZ` can override it.
