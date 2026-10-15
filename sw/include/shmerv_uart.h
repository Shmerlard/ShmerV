#ifndef SHMERV_UART_H
#define SHMERV_UART_H

#include "shmerv_memory_map.h"

/* CTRL: 16-bit RW with RO status fields. TX_DATA: 8-bit RW holding register.
   RX_DATA: 8-bit RO, read acknowledges pending/overrun. Four-byte spacing.
   Reset: disabled, RX IE/start/errors/pending clear, TX data zero, LSB-first
   set, speed from the RTL BAUD_RATE parameter (default 9600).
   TX_DATA writes are accepted only while TX is idle with no start pending.
   START clears after completion; disable aborts active frames while preserving
   unread RX data/pending. There is no receive FIFO. */
#define UART_CTRL_OFFSET 0x00u
#define UART_TX_DATA_OFFSET 0x04u
#define UART_RX_DATA_OFFSET 0x08u

/* UART_CTRL matches uart_control_t:
   [15:13] reserved
   [12] RX overrun (read-only; cleared by reading RX_DATA)
   [11:10] speed (0: 9600, 1: 19200, 2: 57600, 3: 115200 baud)
   [9] parity enable (unfinished)
   [8] parity error (read-only; unfinished)
   [7] framing error (read-only)
   [6] LSB first (selection unfinished)
   [5] auto start (unfinished)
   [4] TX busy (read-only)
   [3] TX start
   [2] RX pending (read-only; cleared by reading RX_DATA)
   [1] RX interrupt enable
   [0] UART enable

   Error, busy, and pending bits are read-only. Reading RX_DATA clears pending.
   Framing error describes the last completed byte's stop bit.
   Overrun means an unread byte was replaced; reading RX_DATA clears overrun.
   Read CTRL before RX_DATA to inspect status before acknowledging the byte.
   Configure speed/parity/bit order while disabled; preserve RX IE/enable on START.
   Parity, bit order selection, and auto start are unfinished. */
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
#define UART_RX_OVERRUN       0x1000u
#define UART_CTRL SHMERV_MMIO16(UART_BASE + UART_CTRL_OFFSET)
#define UART_TX_DATA SHMERV_MMIO8(UART_BASE + UART_TX_DATA_OFFSET)
#define UART_RX_DATA SHMERV_MMIO8(UART_BASE + UART_RX_DATA_OFFSET)

#endif
