package uart_types;
  typedef enum logic [2:0] {
    UART_CTRL_REG_ADDRESS = 3'd0,
    UART_TX_ADDRESS = 3'd1,
    UART_RX_ADDRESS = 3'd2
  } uart_registers_address_t;

  typedef enum logic [1:0] {
    TX_IDLE,
    TX_INITIALIZE,
    TX_WORK,
    TX_FINISH
  } uart_tx_state_t;

  typedef enum logic [1:0] {
    RX_IDLE,
    RX_INITIALIZE,
    RX_WORK,
    RX_FINISH
  } uart_rx_state_t;

  typedef enum logic [1:0] {
    UART_SPEED_9600   = 2'd0,
    UART_SPEED_19200  = 2'd1,
    UART_SPEED_57600  = 2'd2,
    UART_SPEED_115200 = 2'd3
  } uart_speed_t;


  typedef struct packed {
    uart_speed_t uart_speed;
    logic        parity_bit_enable;
    // logic        parity_bit_error;
    // logic        framing_error;
    // logic        enable_auto_tx_start;
    logic        lsb_first;
    logic        busy_tx;
    logic        start_tx;           // Bit 0: software sets; hardware clears when TX finishes.
    logic        rx_ifg;
    logic        rx_ie;
  } uart_control_t;
endpackage
