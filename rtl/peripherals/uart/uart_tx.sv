import uart_types::*;

module uart_tx #(
    parameter int unsigned CLOCK_HZ = 843_750
) (
    input logic clk,
    input logic rst,
    input logic start_i,
    input uart_speed_t uart_speed_i,
    input logic [7:0] data_i,
    output logic tx_o,
    output logic busy_o,
    output logic idle_o,
    output logic finish_o
);
  uart_tx_state_t tx_state;
  uart_tx_state_t tx_next_state;
  logic [9:0] tx_out_reg;
  logic tx_timer_enable;
  logic tx_timer_tick;
  logic [3:0] tx_bit_index;

  assign idle_o = tx_state == TX_IDLE;
  assign finish_o = tx_state == TX_FINISH;
  assign busy_o = tx_state == TX_INITIALIZE || tx_state == TX_WORK;
  assign tx_timer_enable = busy_o;

  // The timer starts in INITIALIZE, alongside loading the start bit.
  // Its index changes at each full-bit boundary without another register delay.
  assign tx_o = tx_state == TX_WORK && tx_bit_index < 4'd10
      ? tx_out_reg[tx_bit_index] : 1'b1;

  always_ff @(posedge clk) begin
    if (rst) begin
      tx_state <= TX_IDLE;
      tx_out_reg <= '1;
    end else begin
      tx_state <= tx_next_state;
      if (tx_state == TX_INITIALIZE)
        tx_out_reg <= {1'b1, data_i, 1'b0};
    end
  end

  always_comb begin
    tx_next_state = tx_state;
    case (tx_state)
      TX_IDLE: if (start_i) tx_next_state = TX_INITIALIZE;
      TX_INITIALIZE: tx_next_state = TX_WORK;
      TX_WORK: if (tx_timer_tick && tx_bit_index == 4'd10) tx_next_state = TX_FINISH;
      TX_FINISH: tx_next_state = TX_IDLE;
      default: tx_next_state = TX_IDLE;
    endcase
  end

  uart_bit_timer #(
      .CLOCK_HZ(CLOCK_HZ),
      .INITIAL_HALF_BIT(1'b0)
  ) tx_bit_timer (
      .clk(clk),
      .rst(rst),
      .uart_speed(uart_speed_i),
      .enable_i(tx_timer_enable),
      .bit_tick_o(tx_timer_tick),
      .bit_index_o(tx_bit_index)
  );
endmodule
