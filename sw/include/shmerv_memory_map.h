#ifndef SHMERV_MEMORY_MAP_H
#define SHMERV_MEMORY_MAP_H

#include <stdint.h>

/* Fixed peripheral addresses in the current SoC. */
#define PORTA_BASE 0x10000000u
#define PORTB_BASE 0x10000100u
#define PORTC_BASE 0x10000200u
#define UART_BASE  0x10000300u
#define TIMER_A_BASE 0x10000400u

/* Byte offsets shared by all three GPIO ports. Registers are eight bits wide. */
#define GPIO_IN_OFFSET      0x00u
#define GPIO_OUT_OFFSET     0x04u
#define GPIO_DIR_OFFSET     0x08u
#define GPIO_SEL_OFFSET     0x0Cu
#define GPIO_IE_OFFSET      0x10u
#define GPIO_IES_OFFSET     0x14u
#define GPIO_IFG_OFFSET     0x18u
#define GPIO_IFG_CLR_OFFSET 0x1Cu

#define UART_DATA_OFFSET 0x00u
#define UART_CTRL_OFFSET 0x04u

/* Dereferencing a volatile pointer performs an eight-bit MMIO access. */
#define SHMERV_MMIO8(address) (*(volatile uint8_t *)(uintptr_t)(address))
#define SHMERV_MMIO16(address) (*(volatile uint16_t *)(uintptr_t)(address))

/* IN is read-only. IFG_CLR is write-only: write ones to clear selected flags.
   Writing ones to IFG sets flags. IES: zero selects rising, one selects falling.
   SEL bits take effect only on pins with an implemented alternate function. */
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

/* The current UART exposes only write-only DATA and CTRL registers. */
#define UART_DATA SHMERV_MMIO8(UART_BASE + UART_DATA_OFFSET)
#define UART_CTRL SHMERV_MMIO8(UART_BASE + UART_CTRL_OFFSET)

/* Timer A registers are 16 bits wide, at four-byte-spaced addresses. */
#define TA_PERIOD_OFFSET    0x00u
#define TA_CCR1_OFFSET      0x04u
#define TA_CCR1_CTRL_OFFSET 0x08u
#define TA_CCR2_OFFSET      0x0Cu
#define TA_CCR2_CTRL_OFFSET 0x10u
#define TA_COUNTER_OFFSET   0x14u
#define TA_CTRL_OFFSET      0x18u

#define TA_PERIOD    SHMERV_MMIO16(TIMER_A_BASE + TA_PERIOD_OFFSET)
#define TA_CCR1      SHMERV_MMIO16(TIMER_A_BASE + TA_CCR1_OFFSET)
#define TA_CCR1_CTRL SHMERV_MMIO16(TIMER_A_BASE + TA_CCR1_CTRL_OFFSET)
#define TA_CCR2      SHMERV_MMIO16(TIMER_A_BASE + TA_CCR2_OFFSET)
#define TA_CCR2_CTRL SHMERV_MMIO16(TIMER_A_BASE + TA_CCR2_CTRL_OFFSET)
#define TA_COUNTER   SHMERV_MMIO16(TIMER_A_BASE + TA_COUNTER_OFFSET)
#define TA_CTRL      SHMERV_MMIO16(TIMER_A_BASE + TA_CTRL_OFFSET)

/* Pending bits clear by writing zero, preserving the other control fields. */
#define TA_OVERFLOW_PENDING (1u << 0)
#define TA_OVERFLOW_IE      (1u << 1)
#define TA_INTERRUPT_ENABLE (1u << 2)
#define TA_DIV_MASK         (7u << 3)
#define TA_DIV_1            (0u << 3)
#define TA_DIV_2            (1u << 3)
#define TA_DIV_4            (2u << 3)
#define TA_DIV_8            (3u << 3)
#define TA_DIV_16           (4u << 3)
#define TA_MODE_MASK        (7u << 6)
#define TA_MODE_HALT        (0u << 6)
#define TA_MODE_UP          (1u << 6)
#define TA_MODE_CONTINUOUS  (3u << 6)

#define TA_CCR_PENDING       (1u << 0)
#define TA_CCR_IE            (1u << 1)
#define TA_CCR_MANUAL_OUT    (1u << 2)
#define TA_CCR_OUTPUT_MASK   (7u << 3)
#define TA_CCR_MANUAL        (0u << 3)
#define TA_CCR_SET           (1u << 3)
#define TA_CCR_TOGGLE_RESET  (2u << 3)
#define TA_CCR_SET_RESET     (3u << 3)
#define TA_CCR_TOGGLE        (4u << 3)
#define TA_CCR_RESET         (5u << 3)
#define TA_CCR_TOGGLE_SET    (6u << 3)

#endif
