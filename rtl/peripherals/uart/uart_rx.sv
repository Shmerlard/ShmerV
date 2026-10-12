import uart_types::*;

module uart_rx #(
    parameter int unsigned CLOCK_HZ = 843_750
) (
    input logic clk,
    input logic rst,
    input logic rx_i,  // Already synchronized to clk by the GPIO module.
    input uart_speed_t uart_speed_i,
    input logic enable_i,
    input logic clear_ifg_i,
    output logic [7:0] rx_data_o,
    output logic rx_ifg_o,
    output logic framing_error_o,
    output logic overrun_o
);

  logic [9:0] rx_in_reg;
  uart_rx_state_t rx_state;
  uart_rx_state_t rx_next_state;
  logic rx_done;
  logic rx_timer_enable;
  logic rx_timer_tick;
  logic [3:0] rx_bit_index;

  always_ff @(posedge clk) begin
    if (rst || !enable_i) rx_state <= RX_IDLE;
    else rx_state <= rx_next_state;
  end

  // --------- RX FSM ---------
  // assign next state rx and the control bits
  always_comb begin
    rx_next_state   = rx_state;
    rx_timer_enable = 0;
    case (rx_state)
      RX_IDLE: begin
        if (rx_i == 1'b0) rx_next_state = RX_INITIALIZE;
      end
      RX_INITIALIZE: begin
        rx_next_state   = RX_WORK;
        rx_timer_enable = 1'b1;
      end
      RX_WORK: begin
        rx_timer_enable = 1'b1;
        if (rx_done) rx_next_state = RX_FINISH;
      end
      RX_FINISH: begin
        rx_next_state = RX_IDLE;
      end
      default: rx_next_state = rx_state;

    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      rx_done <= 0;
      rx_data_o <= 0;
      rx_in_reg <= 0;
      rx_ifg_o <= 1'b0;
      framing_error_o <= 1'b0;
      overrun_o <= 1'b0;
    end else begin
      if (clear_ifg_i) begin
        rx_ifg_o  <= 1'b0;
        overrun_o <= 1'b0;
      end

      if (!enable_i) begin
        rx_done   <= 1'b0;
        rx_in_reg <= '0;
      end else begin
        case (rx_state)
          RX_IDLE: ;
          RX_INITIALIZE: begin
            rx_done <= 1'b0;
          end

          RX_WORK: begin
            if (rx_timer_tick) begin
              rx_in_reg[rx_bit_index] <= rx_i;
              if (rx_bit_index == 9) rx_done <= 1;
            end
          end
          RX_FINISH: begin
            // TODO: implement here the parity check
            rx_data_o <= rx_in_reg[8:1];
            rx_ifg_o <= 1'b1;
            framing_error_o <= !rx_in_reg[9];
            if (rx_ifg_o && !clear_ifg_i) overrun_o <= 1'b1;

          end
          default: ;
        endcase
      end
    end
  end

  uart_bit_timer #(
      .CLOCK_HZ(CLOCK_HZ)
  ) rx_bit_timer (
      .clk        (clk),
      .rst        (rst),
      .uart_speed (uart_speed_i),
      .enable_i   (rx_timer_enable && enable_i),
      .bit_tick_o (rx_timer_tick),
      .bit_index_o(rx_bit_index)
  );
  // ---------------------------

endmodule
