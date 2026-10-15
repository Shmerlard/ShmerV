#ifndef SHMERV_MEMORY_MAP_H
#define SHMERV_MEMORY_MAP_H
#include <stdint.h>

/* Decoded MMIO regions; match rtl/types/soc_address_map.sv.
 * Sizes describe address windows, not the number of implemented registers.
 * HDMI uses 9600 bus-address bytes for 4800 bytes of cell data. */
#define PORTA_BASE 0x10000000u
#define PORTB_BASE 0x10000100u
#define PORTC_BASE 0x10000200u
#define GPIO_SIZE_BYTES 0x100u
#define UART_BASE 0x10000300u
#define UART_SIZE_BYTES 0x100u
#define TIMER_A_BASE 0x10000400u
#define TIMER_A_SIZE_BYTES 0x100u
#define HDMI_CHAR_BASE 0x10002000u
#define HDMI_CHAR_SIZE_BYTES 9600u

/* SoC connections: PORTC_SEL selects these alternate pin functions. */
#define PORTC_UART_TX_PIN 0x01u /* C.0 */
#define PORTC_UART_RX_PIN 0x02u /* C.1 */
#define PORTC_TA_CCR1_PIN 0x80u /* C.7 */
#define PORTC_TA_CCR2_PIN 0x40u /* C.6 */

/* Volatile byte/halfword MMIO access at a mapped address. */
#define SHMERV_MMIO8(address) (*(volatile uint8_t *)(uintptr_t)(address))
#define SHMERV_MMIO16(address) (*(volatile uint16_t *)(uintptr_t)(address))

#endif
