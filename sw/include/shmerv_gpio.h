#ifndef SHMERV_GPIO_H
#define SHMERV_GPIO_H

#include "shmerv_memory_map.h"

/* Byte offsets shared by all three GPIO ports. Registers are eight bits wide
   at four-byte-spaced addresses; use byte accesses. Reset clears writable
   registers; IN follows the synchronized external pin levels. */
#define GPIO_IN_OFFSET      0x00u
#define GPIO_OUT_OFFSET     0x04u
#define GPIO_DIR_OFFSET     0x08u
#define GPIO_SEL_OFFSET     0x0Cu
#define GPIO_IE_OFFSET      0x10u
#define GPIO_IES_OFFSET     0x14u
#define GPIO_IFG_OFFSET     0x18u
#define GPIO_IFG_CLR_OFFSET 0x1Cu

/* GPIO masks apply to OUT, DIR, SEL, IE, IES, IFG, and IFG_CLR. */
#define GPIO_PIN0 0x01u
#define GPIO_PIN1 0x02u
#define GPIO_PIN2 0x04u
#define GPIO_PIN3 0x08u
#define GPIO_PIN4 0x10u
#define GPIO_PIN5 0x20u
#define GPIO_PIN6 0x40u
#define GPIO_PIN7 0x80u

/* Each register uses one bit per pin:
   IN      [7:0] synchronized pin levels (read-only)
   OUT     [7:0] GPIO output values (0: low, 1: high)
   DIR     [7:0] GPIO direction (0: input, 1: output)
   SEL     [7:0] function (0: GPIO, 1: implemented alternate function)
   IE      [7:0] per-pin interrupt enable (0: masked, 1: enabled)
   IES     [7:0] interrupt edge (0: rising, 1: falling)
   IFG     [7:0] pending flags (read/write-one-to-set; zero preserves)
   IFG_CLR [7:0] write-one-to-clear pending flags (reads return zero)

   ALT_MASK/IRQ_MASK in the SoC restrict implemented functions/interrupt pins.
   Alternate selection overrides DIR with the peripheral's output enable.
   Only GPIO inputs generate edge flags; flags latch even with IE masked.
   A new edge wins over a simultaneous clear. GPIO synchronizes inputs but
   provides neither debounce nor pull-up/pull-down bias. */
#define PORTA_IN      SHMERV_MMIO8(PORTA_BASE + GPIO_IN_OFFSET)
#define PORTA_OUT     SHMERV_MMIO8(PORTA_BASE + GPIO_OUT_OFFSET)
#define PORTA_DIR     SHMERV_MMIO8(PORTA_BASE + GPIO_DIR_OFFSET)
#define PORTA_SEL     SHMERV_MMIO8(PORTA_BASE + GPIO_SEL_OFFSET)
#define PORTA_IE      SHMERV_MMIO8(PORTA_BASE + GPIO_IE_OFFSET)
#define PORTA_IES     SHMERV_MMIO8(PORTA_BASE + GPIO_IES_OFFSET)
#define PORTA_IFG     SHMERV_MMIO8(PORTA_BASE + GPIO_IFG_OFFSET)
#define PORTA_IFG_CLR SHMERV_MMIO8(PORTA_BASE + GPIO_IFG_CLR_OFFSET)

#define PORTB_IN      SHMERV_MMIO8(PORTB_BASE + GPIO_IN_OFFSET)
#define PORTB_OUT     SHMERV_MMIO8(PORTB_BASE + GPIO_OUT_OFFSET)
#define PORTB_DIR     SHMERV_MMIO8(PORTB_BASE + GPIO_DIR_OFFSET)
#define PORTB_SEL     SHMERV_MMIO8(PORTB_BASE + GPIO_SEL_OFFSET)
#define PORTB_IE      SHMERV_MMIO8(PORTB_BASE + GPIO_IE_OFFSET)
#define PORTB_IES     SHMERV_MMIO8(PORTB_BASE + GPIO_IES_OFFSET)
#define PORTB_IFG     SHMERV_MMIO8(PORTB_BASE + GPIO_IFG_OFFSET)
#define PORTB_IFG_CLR SHMERV_MMIO8(PORTB_BASE + GPIO_IFG_CLR_OFFSET)

#define PORTC_IN      SHMERV_MMIO8(PORTC_BASE + GPIO_IN_OFFSET)
#define PORTC_OUT     SHMERV_MMIO8(PORTC_BASE + GPIO_OUT_OFFSET)
#define PORTC_DIR     SHMERV_MMIO8(PORTC_BASE + GPIO_DIR_OFFSET)
#define PORTC_SEL     SHMERV_MMIO8(PORTC_BASE + GPIO_SEL_OFFSET)
#define PORTC_IE      SHMERV_MMIO8(PORTC_BASE + GPIO_IE_OFFSET)
#define PORTC_IES     SHMERV_MMIO8(PORTC_BASE + GPIO_IES_OFFSET)
#define PORTC_IFG     SHMERV_MMIO8(PORTC_BASE + GPIO_IFG_OFFSET)
#define PORTC_IFG_CLR SHMERV_MMIO8(PORTC_BASE + GPIO_IFG_CLR_OFFSET)

#endif
