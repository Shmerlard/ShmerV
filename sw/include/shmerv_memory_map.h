#ifndef SHMERV_MEMORY_MAP_H
#define SHMERV_MEMORY_MAP_H

#include <stdint.h>

/* Match rtl/types/soc_address_map.sv. */
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

#define UART_CTRL_OFFSET 0x00u
#define UART_TX_DATA_OFFSET 0x04u
#define UART_RX_DATA_OFFSET 0x08u

/* GPIO masks apply to OUT, DIR, SEL, IE, IES, IFG, and IFG_CLR. */
#define GPIO_PIN0 0x01u
#define GPIO_PIN1 0x02u
#define GPIO_PIN2 0x04u
#define GPIO_PIN3 0x08u
#define GPIO_PIN4 0x10u
#define GPIO_PIN5 0x20u
#define GPIO_PIN6 0x40u
#define GPIO_PIN7 0x80u

#define PORTC_UART_TX_PIN GPIO_PIN0
#define PORTC_UART_RX_PIN GPIO_PIN1
#define PORTC_TA_CCR1_PIN GPIO_PIN7
#define PORTC_TA_CCR2_PIN GPIO_PIN6

/* Dereferencing these volatile pointers performs byte or halfword MMIO access. */
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

/* UART_CTRL matches uart_control_t: [15:12] reserved, [11:10] speed,
   [9] parity enable, [8] parity error, [7] framing error, [6] LSB first,
   [5] auto start, [4] busy, [3] start, [2] RX pending, [1] RX IE, [0] enable.
   Error, busy, and pending bits are read-only. Reading RX_DATA clears pending.
   Configure speed/parity/bit order while disabled; preserve settings on START.
   Parity, error reporting, bit order selection, and auto start are unfinished. */
#define UART_ENABLE           0x0001u
#define UART_RX_IE            0x0002u
#define UART_RX_PENDING       0x0004u
#define UART_START_TX         0x0008u
#define UART_BUSY_TX          0x0010u
#define UART_AUTO_TX_START    0x0020u
#define UART_LSB_FIRST        0x0040u
#define UART_FRAMING_ERROR    0x0080u
#define UART_PARITY_ERROR     0x0100u
#define UART_PARITY_ENABLE    0x0200u
#define UART_SPEED_MASK       0x0C00u
#define UART_SPEED_9600       0x0000u
#define UART_SPEED_19200      0x0400u
#define UART_SPEED_57600      0x0800u
#define UART_SPEED_115200     0x0C00u
#define UART_CTRL SHMERV_MMIO16(UART_BASE + UART_CTRL_OFFSET)
#define UART_TX_DATA SHMERV_MMIO8(UART_BASE + UART_TX_DATA_OFFSET)
#define UART_RX_DATA SHMERV_MMIO8(UART_BASE + UART_RX_DATA_OFFSET)

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

/* TA_CTRL: [15:9] reserved, [8:6] mode, [5:3] divider,
   [2] global interrupt enable, [1] overflow enable, [0] overflow pending.
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

/* TA_CCR1_CTRL / TA_CCR2_CTRL: [15:6] unused, [5:3] output mode,
   [2] manual output, [1] compare interrupt enable, [0] compare pending. */
#define TA_CCR_PENDING      0x0001u
#define TA_CCR_IE           0x0002u
#define TA_CCR_MANUAL_OUT   0x0004u
#define TA_CCR_OUTPUT_MASK  0x0038u
#define TA_CCR_MANUAL       0x0000u
#define TA_CCR_SET          0x0008u
#define TA_CCR_TOGGLE_RESET 0x0010u
#define TA_CCR_SET_RESET    0x0018u
#define TA_CCR_TOGGLE       0x0020u
#define TA_CCR_RESET        0x0028u
#define TA_CCR_TOGGLE_SET   0x0030u

#endif
