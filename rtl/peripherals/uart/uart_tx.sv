import uart_types::*;

module uart_tx #(
    parameter int unsigned CLOCK_HZ  = 843_750,
    parameter int unsigned BAUD_RATE = 9600
) (
    input logic clk,
    input logic rst,
    input logic start_i,
    input logic [7:0] data_i,
    output logic tx_o,
    output logic busy_o,
    output logic idle_o,
    output logic finish_o
);
  // Round to the nearest whole number of clock cycles per bit.
  localparam int unsigned CyclesForBit =
      BAUD_RATE == 0 ? 0 : int'((64'(CLOCK_HZ) + 64'(BAUD_RATE) / 2) / 64'(BAUD_RATE));
  localparam int unsigned CycleCounterWidth = CyclesForBit > 1 ? $clog2(CyclesForBit) : 1;
  localparam logic [CycleCounterWidth-1:0] LastCycle = CycleCounterWidth'(CyclesForBit - 1);

`ifndef SYNTHESIS
  initial begin
    assert (BAUD_RATE > 0 && CLOCK_HZ >= BAUD_RATE)
    else $fatal(1, "UART requires CLOCK_HZ >= BAUD_RATE > 0");
  end
`endif

  uart_tx_state_t tx_state;
  uart_tx_state_t tx_next_state;
  logic [9:0] tx_out_reg;
  logic tx_done;
  logic [CycleCounterWidth-1:0] tx_cycle_counter;  // counts CPU cycles to match baud rate
  logic [3:0] tx_bit_counter;  // inidicates which of the 10bits we send



  assign idle_o   = tx_state == TX_IDLE;
  assign finish_o = tx_state == TX_FINISH;

  always_ff @(posedge clk) begin
    if (rst) begin
      tx_state <= TX_IDLE;
    end else begin
      tx_state <= tx_next_state;
    end
  end

  // ---------- TX FSM ------------

  always_comb begin
    tx_next_state = tx_state;
    case (tx_state)
      TX_IDLE: begin
        if (start_i) tx_next_state = TX_INITIALIZE;
      end
      TX_INITIALIZE: tx_next_state = TX_WORK;
      TX_WORK: if (tx_done) tx_next_state = TX_FINISH;
      TX_FINISH: tx_next_state = TX_IDLE;
      default: tx_next_state = tx_state;
    endcase
  end
  // ---------------------------


  // -------- TX Cycle Count ------
  always_ff @(posedge clk) begin
    if (rst) begin
      tx_cycle_counter <= 0;
      tx_bit_counter <= 4'b0000;
      tx_done <= 1'b0;
    end else begin
      case (tx_state)
        TX_IDLE: begin
        end

        TX_INITIALIZE: begin
          tx_cycle_counter <= 0;
          tx_bit_counter   <= 4'b0000;
          tx_out_reg       <= {1'b1, data_i, 1'b0};
          tx_done          <= 1'b0;
        end

        TX_WORK: begin
          if (tx_cycle_counter != LastCycle) begin
            tx_cycle_counter <= tx_cycle_counter + 1;
          end else begin
            tx_cycle_counter <= 0;
            if (tx_bit_counter == 4'd9) begin
              tx_done <= 1'b1;
            end else begin
              tx_bit_counter <= tx_bit_counter + 1;
            end
          end
        end

        TX_FINISH: begin
          tx_done <= 1'b0;
        end

        default: begin
        end
      endcase
    end
  end

  always_comb begin
    case (tx_state)
      TX_IDLE, TX_FINISH: begin
        tx_o   = 1'b1;
        busy_o = 1'b0;
      end
      TX_INITIALIZE: begin
        tx_o   = 1'b1;
        busy_o = 1'b1;
      end
      TX_WORK: begin
        tx_o   = tx_out_reg[tx_bit_counter];
        busy_o = 1'b1;
      end
      default: begin
        tx_o   = 1'b1;
        busy_o = 1'b0;
      end
    endcase
  end
  // ---------------------------


endmodule
