import uart_types::*;

module uart_module #(
    parameter int unsigned CLOCK_HZ  = 843_750,
    parameter int unsigned BAUD_RATE = 9600
) (
    input logic clk,
    input logic rst,

    input  logic                    [7:0] mmio_write_data_i,
    input  uart_registers_address_t       register_address_i,
    input  logic                          mmio_write_enable_i,
    input  logic                          mmio_read_enable_i,
    output logic                    [7:0] mmio_read_data_o,

    output logic tx_o
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


  state_t state;
  state_t next_state;

  logic [7:0] tx_data_reg;
  uart_control_t tx_ctrl_reg;

  logic start_tx_request;
  logic busy_tx;
  logic tx_done;
  logic [9:0] tx_out_reg;
  logic [CycleCounterWidth-1:0] cycle_counter;  // counts CPU cycles to match baud rate
  logic [3:0] bit_counter;  // inidicates which of the 10bits we send

  assign start_tx_request = tx_ctrl_reg.start_tx;
  assign tx_ctrl_reg.busy_tx = busy_tx;
  assign tx_ctrl_reg.reserved = '0;


  // ---------- FSM ------------
  always_ff @(posedge clk) begin
    if (rst) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  always_comb begin
    next_state = state;
    case (state)
      IDLE: begin
        if (start_tx_request) next_state = INITIALIZE;
      end
      INITIALIZE: next_state = WORK;
      WORK: if (tx_done) next_state = FINISH;
      FINISH: next_state = IDLE;
      default: next_state = state;
    endcase
  end
  // ---------------------------


  // -------- Cycle Count ------
  always_ff @(posedge clk) begin
    if (rst) begin
      cycle_counter <= 0;
      bit_counter <= 4'b0000;
      tx_done <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
        end

        INITIALIZE: begin
          cycle_counter <= 0;
          bit_counter   <= 4'b0000;
          tx_out_reg    <= {1'b1, tx_data_reg, 1'b0};
          tx_done       <= 1'b0;
        end

        WORK: begin
          if (cycle_counter != LastCycle) begin
            cycle_counter <= cycle_counter + 1;
          end else begin
            cycle_counter <= 0;
            if (bit_counter == 4'd9) begin
              tx_done <= 1'b1;
            end else begin
              bit_counter <= bit_counter + 1;
            end
          end
        end

        FINISH: begin
          tx_done <= 1'b0;
        end

        default: begin
        end
      endcase
    end
  end

  always_comb begin
    case (state)
      IDLE, FINISH: begin
        tx_o = 1'b1;
        busy_tx = 1'b0;
      end
      INITIALIZE: begin
        tx_o = 1'b1;
        busy_tx = 1'b1;
      end
      WORK: begin
        tx_o = tx_out_reg[bit_counter];
        busy_tx = 1'b1;
      end
      default: begin
        tx_o = 1'b1;
        busy_tx = 1'b0;
      end
    endcase
  end
  // ---------------------------

  // --------- loading ---------
  always_ff @(posedge clk) begin
    if (rst) begin
      tx_data_reg <= 8'b0;
      tx_ctrl_reg.start_tx <= 1'b0;
      mmio_read_data_o <= 8'b0;
    end else begin
      if (state == FINISH) begin
        tx_ctrl_reg.start_tx <= 1'b0;
      end else if (mmio_write_enable_i) begin
        case (register_address_i)
          UART_CTRL_REG_ADDRESS: tx_ctrl_reg.start_tx <= mmio_write_data_i[0];
          UART_TX_ADDRESS: tx_data_reg <= mmio_write_data_i;
          default: begin
          end
        endcase
      end

      if (mmio_read_enable_i) begin
        case (register_address_i)
          UART_TX_ADDRESS: mmio_read_data_o <= tx_data_reg;
          UART_CTRL_REG_ADDRESS: mmio_read_data_o <= tx_ctrl_reg;
          default: begin
          end
        endcase
      end

    end

  end

endmodule
