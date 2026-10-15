#ifndef SHMERV_TIMER_H
#define SHMERV_TIMER_H

#include "shmerv_memory_map.h"

/* Timer A registers are 16 bits wide, at four-byte-spaced addresses. */
#define TA_PERIOD_OFFSET    0x00u
#define TA_COMPARE1_OFFSET      0x04u
#define TA_COMPARE1_CTRL_OFFSET 0x08u
#define TA_COMPARE2_OFFSET      0x0Cu
#define TA_COMPARE2_CTRL_OFFSET 0x10u
#define TA_COUNTER_OFFSET   0x14u
#define TA_CTRL_OFFSET      0x18u

#define TA_PERIOD    SHMERV_MMIO16(TIMER_A_BASE + TA_PERIOD_OFFSET)
#define TA_COMPARE1      SHMERV_MMIO16(TIMER_A_BASE + TA_COMPARE1_OFFSET)
#define TA_COMPARE1_CTRL SHMERV_MMIO16(TIMER_A_BASE + TA_COMPARE1_CTRL_OFFSET)
#define TA_COMPARE2      SHMERV_MMIO16(TIMER_A_BASE + TA_COMPARE2_OFFSET)
#define TA_COMPARE2_CTRL SHMERV_MMIO16(TIMER_A_BASE + TA_COMPARE2_CTRL_OFFSET)
#define TA_COUNTER   SHMERV_MMIO16(TIMER_A_BASE + TA_COUNTER_OFFSET)
#define TA_CTRL      SHMERV_MMIO16(TIMER_A_BASE + TA_CTRL_OFFSET)

/* TA_CTRL:
   [15:9] reserved
   [8:6] mode (0: halt, 1: up to PERIOD, 3: continuous to 0xFFFF)
   [5:3] divider (0: /1, 1: /2, 2: /4, 3: /8, 4: /16)
   [2] Timer A global interrupt enable
   [1] overflow interrupt enable
   [0] overflow pending

   Pending clears by writing zero, preserving the other control fields. */
#define TA_OVERFLOW_PENDING 0x0001u
#define TA_OVERFLOW_IE      0x0002u
#define TA_INTERRUPT_ENABLE 0x0004u
#define TA_DIV_MASK         0x0038u
#define TA_DIV_1            0x0000u
#define TA_DIV_2            0x0008u
#define TA_DIV_4            0x0010u
#define TA_DIV_8            0x0018u
#define TA_DIV_16           0x0020u
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
