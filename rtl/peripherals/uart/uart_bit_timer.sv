import uart_types::*;

module uart_bit_timer #(
    parameter int unsigned CLOCK_HZ = 843_750,
    parameter bit INITIAL_HALF_BIT = 1'b1
) (
    input logic clk,
    input logic rst,
    input uart_speed_t uart_speed,
    input logic enable_i,
    output logic bit_tick_o,
    output logic [3:0] bit_index_o
);

  localparam int unsigned BitCycles[0:3] = '{
      (CLOCK_HZ + 4_800) / 9_600,
      (CLOCK_HZ + 9_600) / 19_200,
      (CLOCK_HZ + 28_800) / 57_600,
      (CLOCK_HZ + 57_600) / 115_200
  };
  localparam int unsigned CountWidth = BitCycles[0] > 1 ? $clog2(BitCycles[0]) : 1;
  typedef logic [CountWidth-1:0] cycle_count_t;

  typedef enum logic [1:0] {
    IDLE,
    COUNT_HALF_BIT,
    COUNT_FULL_BIT
  } timer_state_t;

  timer_state_t state;
  cycle_count_t cycle_count;
  cycle_count_t half_bit_last_cycle;
  cycle_count_t full_bit_last_cycle;

  assign half_bit_last_cycle = cycle_count_t'((BitCycles[uart_speed] >> 1) - 1);
  assign full_bit_last_cycle = cycle_count_t'(BitCycles[uart_speed] - 1);

  always_ff @(posedge clk) begin
    if (rst || !enable_i) begin
      state <= IDLE;
      cycle_count <= '0;
      bit_index_o <= '0;
      bit_tick_o <= 1'b0;
    end else begin
      bit_tick_o <= 1'b0;

      case (state)
        IDLE: begin
          cycle_count <= '0;
          bit_index_o <= '0;
          state <= INITIAL_HALF_BIT ? COUNT_HALF_BIT : COUNT_FULL_BIT;
        end

        COUNT_HALF_BIT: begin
          if (cycle_count == half_bit_last_cycle) begin
            cycle_count <= '0;
            bit_tick_o <= 1'b1;
            state <= COUNT_FULL_BIT;
          end else begin
            cycle_count <= cycle_count + cycle_count_t'(1);
          end
        end

        COUNT_FULL_BIT: begin
          if (cycle_count == full_bit_last_cycle) begin
            cycle_count <= '0;
            bit_index_o <= bit_index_o + 4'd1;
            bit_tick_o  <= 1'b1;
          end else begin
            cycle_count <= cycle_count + cycle_count_t'(1);
          end
        end

        default: begin
          state <= IDLE;
          cycle_count <= '0;
          bit_index_o <= '0;
        end
      endcase
    end
  end

`ifndef SYNTHESIS
  initial begin
    foreach (BitCycles[i]) begin
      assert (BitCycles[i] >= 4)
      else $fatal(1, "UART requires at least four clocks per bit at every supported speed");
    end
  end

  uart_speed_t uart_speed_prev;
  always_ff @(posedge clk) begin
    if (!rst && enable_i && state != IDLE) begin
      assert (uart_speed == uart_speed_prev)
      else $fatal(1, "Disable the UART timer when changing speed");
    end
    uart_speed_prev <= uart_speed;
  end
`endif

endmodule
