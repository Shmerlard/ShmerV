# Timer A capture

Timer A contains two compare/PWM channels and one capture channel. The timer
and capture use the system clock; a tick enable advances the main counter at
/1, /2, /4, /8, /16, or /1024. Capture detects edges every system-clock cycle
and records the current main counter, so its time unit is the divided timer
tick. Pulses shorter than one tick can produce a zero delta.

## Capture registers

All registers are 16 bits wide at aligned byte offsets from TIMER_A_BASE
(`0x10000400`). Control bit definitions are in `sw/include/shmerv_timer.h`.

| Register | Offset | Access | Purpose |
| --- | --- | --- | --- |
| CAPTURE1_CTRL | 0x1C | Mixed RW/RO | Source, edge pair, enable, rearm, IRQ mode, overflow and pending |
| CAPTURE1_START | 0x20 | RO | Counter sampled on the first selected edge |
| CAPTURE1_END | 0x24 | RO | Counter sampled on the second selected edge |
| CAPTURE1_DELTA | 0x28 | RO, read clears pending | END minus START, modulo 65536 |

Reset clears control, results, and pending. Source and edge selection can
change only while capture enable is zero; disabling and reconfiguring require
separate writes. Manual mode takes edges from the writable capture input bit.
External mode uses GPIO C.5 with `PORTC_TA_CAPTURE1_PIN` selected in PORTC_SEL.
The GPIO two-flop synchronizer provides the input; the alternate function
disables output drive on C.5.

Edge pairs are rise/fall, fall/rise, rise/rise, and fall/fall. The FSM waits for
START, then END, then commits DELTA and overflow one system-clock cycle after
END. Single-shot completion clears capture enable; automatic rearm returns to
waiting for another START. Same-edge modes measure disjoint pairs (1->2,
3->4), and edges during the completion state are not captured. Automatic
measurements replace previous results; there is no unread-result overrun flag.

## Overflow and interrupts

Interval arithmetic is valid only in CONTINUOUS mode, with no counter writes
during a measurement. For the 16-bit timer, intervals of 65536 ticks or more
set overflow; DELTA still contains the low 16 bits. A saturating wrap count
tracks zero, one, or at least two wraps. With one wrap, END >= START indicates
overflow. A registered wrap pulse accompanies the already-wrapped counter:
a wrap coincident with START is excluded, and one coincident with END is
included. Overflow is RO and is replaced with each completed result.

IRQ mode selects disabled, START, or DONE (fourth encoding reserved). Only
the selected event sets the single sticky pending bit. Writing zero clears
pending; writing one preserves it. Reading DELTA also clears it; a simultaneous
new event wins over acknowledgement. Single-shot auto-disable does not clear
pending. The timer global interrupt enable masks the outgoing request without
clearing pending. Capture uses custom cause 23, after both compare channels
and before UART RX in peripheral-manager priority.

## Verification and hardware demo

- `just test timer_a_capture_module`: sources, edge modes, one-shot/rearm,
  wrap boundaries/saturation, protected fields, aborts and IRQ collisions.
- `just test timer_a_module`: timer integration across a real wrap, read
  latency, global interrupt masking and DELTA acknowledgement.
- `just test peripheral_manager`: capture MMIO, synchronized C.5 routing,
  byte-write rejection and interrupt priority.
- `CPU_TEST_TIMEOUT_CYCLES=30000 just test soc timer_capture`: START/DONE
  handlers through cause 23, wrap arithmetic, acknowledgement and MRET.

The user validated `sw/programs/capture_hdmi` on Tang Nano 9K using a button
on C.5 and HDMI output. Input bias and mechanical debounce are external to
Capture: disconnected/floating wiring can generate spurious 0/1-tick results.
