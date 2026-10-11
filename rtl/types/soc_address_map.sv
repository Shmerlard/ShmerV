package soc_address_map;
  localparam logic [31:0] PERIPHERAL_BASE_ADDRESS = 32'h1000_0000;
  localparam logic [31:0] PERIPHERAL_SIZE_BYTES = 32'h0001_0000;
  localparam logic [31:0] GPIO_A_BASE = 32'h1000_0000;
  localparam logic [31:0] GPIO_B_BASE = 32'h1000_0100;
  localparam logic [31:0] GPIO_C_BASE = 32'h1000_0200;
  localparam logic [31:0] UART_BASE = 32'h1000_0300;
  localparam logic [31:0] TIMER_A_BASE = 32'h1000_0400;
  localparam logic [31:0] GPIO_SIZE_BYTES = 32'h0000_0100;
  localparam logic [31:0] UART_SIZE_BYTES = 32'h0000_0100;
  localparam logic [31:0] TIMER_A_SIZE_BYTES = 32'h0000_0100;

  localparam int GPIO_C_UART_TX_PIN = 0;
  localparam int GPIO_C_TIMER_A_COMPARE1_PIN = 7;
  localparam int GPIO_C_TIMER_A_COMPARE2_PIN = 6;

  localparam logic [7:0] GPIO_C_ALT_MASK =
      (8'b1 << GPIO_C_UART_TX_PIN)
      | (8'b1 << GPIO_C_TIMER_A_COMPARE1_PIN)
      | (8'b1 << GPIO_C_TIMER_A_COMPARE2_PIN);
endpackage
