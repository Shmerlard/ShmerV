#ifndef SHMERV_MEMORY_MAP_H
#define SHMERV_MEMORY_MAP_H

#include <stdint.h>

/* Fixed peripheral addresses in the current SoC. */
#define PORTA_BASE 0x10000000u
#define PORTB_BASE 0x10000100u
#define PORTC_BASE 0x10000200u
#define UART_BASE  0x10000300u

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

#endif
