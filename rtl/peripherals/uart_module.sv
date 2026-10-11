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

    output logic tx_o,
    input  logic rx_i,

    output logic rx_irq_o
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

  // -------------- CTRL ------------------
  uart_control_t uart_ctrl_reg;
  uart_control_t control_write_data;
  logic valid_write;


  // -------------- TX ------------------
  uart_tx_state_t tx_state;
  uart_tx_state_t tx_next_state;
  logic [7:0] tx_data_reg;
  logic [9:0] tx_out_reg;
  logic start_tx_request;
  logic tx_busy;
  logic tx_done;
  logic [CycleCounterWidth-1:0] tx_cycle_counter;  // counts CPU cycles to match baud rate
  logic [3:0] tx_bit_counter;  // inidicates which of the 10bits we send


  // -------------- RX ------------------
  logic [7:0] rx_data_reg;
  logic [9:0] rx_in_reg;
  uart_rx_state_t rx_state;
  uart_rx_state_t rx_next_state;
  logic rx_done;
  logic [CycleCounterWidth-1:0] rx_cycle_counter;  // counts CPU cycles to match baud rate
  logic [3:0] rx_bit_counter;  // inidicates which of the 10bits we send
  logic rx_cycle_counter_rst;
  logic rx_cycle_counter_enable;
  logic rx_cycle_counter_enable_prev;
  logic rx_cycle_counter_advanded;  // a pulse for indicating we are in the next bit
  logic rx_cycle_counter_enabled_rise;
  logic rx_i_sync_1;
  logic rx_i_sync_2;




  // -------------- ASSIGNMENTS ------------------
  assign control_write_data = uart_control_t'(mmio_write_data_i);
  assign uart_ctrl_reg.busy_tx = tx_busy;
  assign valid_write = mmio_write_enable_i && tx_state == TX_IDLE && !uart_ctrl_reg.start_tx;
  assign start_tx_request = uart_ctrl_reg.start_tx;

  assign rx_cycle_counter_enabled_rise = rx_cycle_counter_enable && !rx_cycle_counter_enable_prev;

  always_ff @(posedge clk) begin
    if (rst) begin
      tx_state <= TX_IDLE;
      rx_state <= RX_IDLE;
    end else begin
      tx_state <= tx_next_state;
      rx_state <= rx_next_state;
    end
  end

  // Synchronization
  always_ff @(posedge clk) begin
    if (rst) begin
      rx_i_sync_1 <= 1'b1;
      rx_i_sync_2 <= 1'b1;
    end else begin
      rx_i_sync_1 <= rx_i;
      rx_i_sync_2 <= rx_i_sync_1;
    end
  end

  // ---------- TX FSM ------------

  always_comb begin
    tx_next_state = tx_state;
    case (tx_state)
      TX_IDLE: begin
        if (start_tx_request) tx_next_state = TX_INITIALIZE;
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
          tx_out_reg       <= {1'b1, tx_data_reg, 1'b0};
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
        tx_o = 1'b1;
        tx_busy = 1'b0;
      end
      TX_INITIALIZE: begin
        tx_o = 1'b1;
        tx_busy = 1'b1;
      end
      TX_WORK: begin
        tx_o = tx_out_reg[tx_bit_counter];
        tx_busy = 1'b1;
      end
      default: begin
        tx_o = 1'b1;
        tx_busy = 1'b0;
      end
    endcase
  end
  // ---------------------------

  // --------- loading ---------
  always_ff @(posedge clk) begin
    if (rst) begin
      tx_data_reg <= 8'b0;
      uart_ctrl_reg.start_tx <= 1'b0;
      mmio_read_data_o <= 8'b0;
    end else begin
      if (tx_state == TX_FINISH) begin
        uart_ctrl_reg.start_tx <= 1'b0;
      end else if (valid_write) begin
        case (register_address_i)
          UART_CTRL_REG_ADDRESS: uart_ctrl_reg.start_tx <= control_write_data.start_tx;
          UART_TX_ADDRESS: tx_data_reg <= mmio_write_data_i;
          UART_RX_ADDRESS: ;
          default: ;
        endcase
      end

      if (mmio_read_enable_i) begin
        case (register_address_i)
          UART_CTRL_REG_ADDRESS: mmio_read_data_o <= uart_ctrl_reg;
          UART_TX_ADDRESS: mmio_read_data_o <= tx_data_reg;
          UART_RX_ADDRESS: mmio_read_data_o <= rx_data_reg;
          default: ;
        endcase
      end
    end
  end



  // --------- RX FSM ---------
  // assign next state rx and the control bits
  always_comb begin
    rx_next_state = rx_state;
    rx_cycle_counter_rst = 0;
    rx_cycle_counter_enable = 0;
    case (rx_state)
      RX_IDLE: begin
        if (rx_i_sync_2 == 1'b0) rx_next_state = RX_INITIALIZE;
      end
      RX_INITIALIZE: begin
        rx_next_state = RX_WORK;
        rx_cycle_counter_rst = 1;
      end
      RX_WORK: begin
        if (rx_done) rx_next_state = RX_FINISH;
        rx_cycle_counter_rst = 0;
        rx_cycle_counter_enable = 1;
      end
      RX_FINISH: begin
        rx_next_state = RX_IDLE;
        rx_cycle_counter_enable = 0;
      end
      default: rx_next_state = rx_state;

    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      rx_done     <= 0;
      rx_data_reg <= 0;
      rx_in_reg   <= 0;
    end else begin
      case (rx_state)
        RX_IDLE: ;
        RX_INITIALIZE: begin
          rx_done <= 0;
        end

        RX_WORK: begin
          if (rx_cycle_counter_advanded || rx_cycle_counter_enabled_rise) begin
            rx_in_reg[rx_bit_counter] <= rx_i_sync_2;
          end
          if (rx_bit_counter == 9) rx_done <= 1;
        end
        RX_FINISH: begin
          // TODO: implement here the parity check
          // TODO: implement the ifg here
          rx_data_reg <= rx_in_reg[8:1];
        end
        default: ;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (rst || |rx_cycle_counter_rst) begin
      rx_cycle_counter <= 0;
      rx_bit_counter <= 0;
      rx_cycle_counter_advanded <= 0;
    end else begin
      rx_cycle_counter_advanded <= 0;
      if (rx_cycle_counter_enable) begin
        if (rx_cycle_counter != LastCycle) begin
          rx_cycle_counter <= rx_cycle_counter + 1;
        end else begin
          rx_cycle_counter <= 0;
          rx_bit_counter <= rx_bit_counter + 1;
          rx_cycle_counter_advanded <= 1;
        end
      end
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      rx_cycle_counter_enable_prev <= 0;
    end else begin
      rx_cycle_counter_enable_prev <= rx_cycle_counter_enable;
    end
  end
  // ---------------------------

endmodule
