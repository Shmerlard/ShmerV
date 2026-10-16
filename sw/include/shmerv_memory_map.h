#ifndef SHMERV_MEMORY_MAP_H
#define SHMERV_MEMORY_MAP_H
#include <stdint.h>

/* Decoded MMIO regions; match rtl/types/soc_address_map.sv.
 * Sizes describe address windows, not the number of implemented registers.
 * HDMI allocates 32 KiB; its 4080 cells use 16320 bus-address bytes
 * for 8160 bytes of cell data (four-byte stride). */
#define PORTA_BASE 0x10000000u
#define PORTB_BASE 0x10000100u
#define PORTC_BASE 0x10000200u
#define GPIO_SIZE_BYTES 0x100u
#define UART_BASE 0x10000300u
#define UART_SIZE_BYTES 0x100u
#define TIMER_A_BASE 0x10000400u
#define TIMER_A_SIZE_BYTES 0x100u
#define HDMI_BASE 0x10002000u
#define HDMI_SIZE_BYTES 0x8000u
#define HDMI_CHAR_BASE 0x10006000u
#define HDMI_CHAR_SIZE_BYTES 16320u /* Implemented cell slots; 64 bytes remain reserved. */

/* SoC connections: PORTC_SEL selects these alternate pin functions. */
#define PORTC_UART_TX_PIN 0x01u /* C.0 */
#define PORTC_UART_RX_PIN 0x02u /* C.1 */
#define PORTC_TA_COMPARE1_PIN 0x80u /* C.7 */
#define PORTC_TA_COMPARE2_PIN 0x40u /* C.6 */
#define PORTC_TA_CAPTURE1_PIN 0x20u /* C.5, synchronized input */

/* Volatile byte/halfword MMIO access at a mapped address. */
#define SHMERV_MMIO8(address) (*(volatile uint8_t *)(uintptr_t)(address))
#define SHMERV_MMIO16(address) (*(volatile uint16_t *)(uintptr_t)(address))

#endif
