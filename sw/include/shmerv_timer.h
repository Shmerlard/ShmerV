#ifndef SHMERV_TIMER_H
#define SHMERV_TIMER_H

#include "shmerv_memory_map.h"

/* Timer A registers are 16 bits wide, at four-byte-spaced addresses; use
   halfword accesses (both low byte lanes must be enabled for writes).
   Reset clears writable registers, counter, compare outputs and capture data.
   PERIOD/COUNTER/COMPARE1/COMPARE2 and controls are RW except the RO fields
   documented below. Counter writes suppress that cycle's timer tick events.
   UP counts 0..PERIOD inclusive; CONTINUOUS counts 0..65535.
   Dividers are tick enables: all logic still runs on the system clock. */
#define TA_PERIOD_OFFSET    0x00u
#define TA_COMPARE1_OFFSET      0x04u
#define TA_COMPARE1_CTRL_OFFSET 0x08u
#define TA_COMPARE2_OFFSET      0x0Cu
#define TA_COMPARE2_CTRL_OFFSET 0x10u
#define TA_COUNTER_OFFSET   0x14u
#define TA_CTRL_OFFSET      0x18u
#define TA_CAPTURE1_CTRL_OFFSET  0x1Cu
#define TA_CAPTURE1_START_OFFSET 0x20u
#define TA_CAPTURE1_END_OFFSET   0x24u
#define TA_CAPTURE1_DELTA_OFFSET 0x28u

#define TA_PERIOD    SHMERV_MMIO16(TIMER_A_BASE + TA_PERIOD_OFFSET)
#define TA_COMPARE1      SHMERV_MMIO16(TIMER_A_BASE + TA_COMPARE1_OFFSET)
#define TA_COMPARE1_CTRL SHMERV_MMIO16(TIMER_A_BASE + TA_COMPARE1_CTRL_OFFSET)
#define TA_COMPARE2      SHMERV_MMIO16(TIMER_A_BASE + TA_COMPARE2_OFFSET)
#define TA_COMPARE2_CTRL SHMERV_MMIO16(TIMER_A_BASE + TA_COMPARE2_CTRL_OFFSET)
#define TA_COUNTER   SHMERV_MMIO16(TIMER_A_BASE + TA_COUNTER_OFFSET)
#define TA_CTRL      SHMERV_MMIO16(TIMER_A_BASE + TA_CTRL_OFFSET)
#define TA_CAPTURE1_CTRL  SHMERV_MMIO16(TIMER_A_BASE + TA_CAPTURE1_CTRL_OFFSET)
#define TA_CAPTURE1_START SHMERV_MMIO16(TIMER_A_BASE + TA_CAPTURE1_START_OFFSET)
#define TA_CAPTURE1_END   SHMERV_MMIO16(TIMER_A_BASE + TA_CAPTURE1_END_OFFSET)
#define TA_CAPTURE1_DELTA SHMERV_MMIO16(TIMER_A_BASE + TA_CAPTURE1_DELTA_OFFSET)

/* TA_CAPTURE1_CTRL (reset: 0):
   [15:10] reserved
   [9:8] edges (0: rise/fall, 1: fall/rise, 2: rise/rise, 3: fall/fall)
   [7] source (0: manual CAPTURE_IN, 1: external GPIO C.5)
   [6] manual input level
   [5] capture enable (cleared on single-shot completion)
   [4] overflow (read-only; completed interval does not fit in 16 bits)
   [3] burst enable (automatically rearm after completion)
   [2:1] IRQ mode (0: disabled, 1: START, 2: DONE, 3: reserved)
   [0] pending (write 0 to clear; write 1 preserves)

   Edge/source fields can change only while capture is disabled.
   START/END/DELTA are read-only. Reading DELTA also clears pending;
   a new event wins over simultaneous acknowledgement.
   Measurement is valid only with TA_MODE_CONTINUOUS and no counter writes
   during the interval. DELTA is in timer ticks and wraps modulo 65536.
   External capture requires PORTC_TA_CAPTURE1_PIN in PORTC_SEL; input is
   synchronized by GPIO. Configure source/edges before enabling capture. */
#define TA_CAPTURE_EDGE_MASK    0x0300u
#define TA_CAPTURE_RISE_TO_FALL 0x0000u
#define TA_CAPTURE_FALL_TO_RISE 0x0100u
#define TA_CAPTURE_RISE_TO_RISE 0x0200u
#define TA_CAPTURE_FALL_TO_FALL 0x0300u
#define TA_CAPTURE_EXTERNAL     0x0080u
#define TA_CAPTURE_MANUAL       0x0000u
#define TA_CAPTURE_IN           0x0040u
#define TA_CAPTURE_ENABLE       0x0020u
#define TA_CAPTURE_OVERFLOW     0x0010u
#define TA_CAPTURE_BURST_ENABLE 0x0008u
#define TA_CAPTURE_IRQ_MASK     0x0006u
#define TA_CAPTURE_IRQ_DISABLE  0x0000u
#define TA_CAPTURE_IRQ_START    0x0002u
#define TA_CAPTURE_IRQ_DONE     0x0004u
#define TA_CAPTURE_PENDING      0x0001u

/* TA_CTRL:
   [15:9] reserved
   [8:6] mode (0: halt, 1: up to PERIOD, 3: continuous to 0xFFFF)
   [5:3] divider (0: /1, 1: /2, 2: /4, 3: /8, 4: /16, 5: /1024)
   [2] Timer A global interrupt enable
   [1] overflow interrupt enable
   [0] overflow pending

   Pending clears by writing zero, preserving the other control fields.
   A new wrap wins over a simultaneous clear. Global interrupt enable masks
   outgoing overflow/compare/capture requests without clearing pending. */
#define TA_OVERFLOW_PENDING 0x0001u
#define TA_OVERFLOW_IE      0x0002u
#define TA_INTERRUPT_ENABLE 0x0004u
#define TA_DIV_MASK         0x0038u
#define TA_DIV_1            0x0000u
#define TA_DIV_2            0x0008u
#define TA_DIV_4            0x0010u
#define TA_DIV_8            0x0018u
#define TA_DIV_16           0x0020u
#define TA_DIV_1024         0x0028u
#define TA_MODE_MASK        0x01C0u
#define TA_MODE_HALT        0x0000u
#define TA_MODE_UP          0x0040u
#define TA_MODE_CONTINUOUS  0x00C0u

/* TA_COMPARE1_CTRL / TA_COMPARE2_CTRL:
   [15:6] unused
   [5:3] output mode (0: manual, 1: set, 2: toggle/reset, 3: set/reset,
         4: toggle, 5: reset, 6: toggle/set)
   [2] manual output value
   [1] compare interrupt enable
   [0] compare pending (write zero to clear; preserve other fields)

   Writing one to pending sets it. Matches set pending even with interrupts
   masked; a new match wins over a simultaneous clear. For two-part output
   modes, the first action occurs at compare and the second at PERIOD.
 */
#define TA_COMPARE_PENDING      0x0001u
#define TA_COMPARE_IE           0x0002u
#define TA_COMPARE_MANUAL_OUT   0x0004u
#define TA_COMPARE_OUTPUT_MASK  0x0038u
#define TA_COMPARE_MANUAL       0x0000u
#define TA_COMPARE_SET          0x0008u
#define TA_COMPARE_TOGGLE_RESET 0x0010u
#define TA_COMPARE_SET_RESET    0x0018u
#define TA_COMPARE_TOGGLE       0x0020u
#define TA_COMPARE_RESET        0x0028u
#define TA_COMPARE_TOGGLE_SET   0x0030u

#endif
