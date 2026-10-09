package uart_types;
  typedef enum logic [2:0] {
    UART_CTRL_REG_ADDRESS = 3'd1,
    UART_TX_ADDRESS = 3'd0
  } uart_registers_address_t;

  typedef enum logic [1:0] {
    IDLE,
    INITIALIZE,
    WORK,
    FINISH
  } state_t;

  typedef struct packed {
    logic [5:0] reserved;  // Bits 7:2: read as zero.
    logic       busy_tx;
    logic       start_tx;  // Bit 0: software sets; hardware clears when TX finishes.
  } uart_control_t;
endpackage
