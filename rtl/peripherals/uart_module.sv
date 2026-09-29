module uart_module #(
    // 843.75 kHz / 9600 baud rounds to 88 clocks per transmitted bit.
    parameter int unsigned CYCLES_FOR_BIT = 88
) (
    input logic clk,
    input logic rst,

    input logic [7:0] mmio_write_data_i,
    input logic       register_address_i,
    input logic       mmio_write_enable_i,

    output logic tx_o
);
  localparam int unsigned CycleCounterWidth = $clog2(CYCLES_FOR_BIT);
  localparam logic [CycleCounterWidth-1:0] LastCycle = CycleCounterWidth'(CYCLES_FOR_BIT - 1);


  typedef enum logic [1:0] {
    IDLE,
    INITIALIZE,
    WORK,
    FINISH
  } state_t;

  state_t state;
  state_t next_state;

  logic [7:0] tx_data_reg;
  logic [7:0] tx_ctrl_reg;

  logic start_tx_request;
  logic tx_done;
  logic [9:0] tx_out_reg;
  logic [CycleCounterWidth-1:0] cycle_counter;  // counts CPU cycles to match baud rate
  logic [3:0] bit_counter;  // inidicates which of the 10bits we send

  assign start_tx_request = tx_ctrl_reg[0];

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
      IDLE, FINISH: tx_o = 1'b1;
      INITIALIZE:   tx_o = 1'b1;
      WORK:         tx_o = tx_out_reg[bit_counter];
      default:      tx_o = 1'b1;
    endcase
  end
  // ---------------------------

  // --------- loading ---------
  always_ff @(posedge clk) begin
    if (rst) begin
      tx_data_reg <= 8'b0;
      tx_ctrl_reg[0] <= 1'b0;
    end else begin
      if (state == FINISH) begin
        tx_ctrl_reg[0] <= 1'b0;
      end else if (mmio_write_enable_i) begin
        case (register_address_i)
          1'b0: tx_data_reg <= mmio_write_data_i;
          1'b1: tx_ctrl_reg <= mmio_write_data_i;
          default: begin
          end
        endcase
      end
    end

  end

endmodule
