import uart_types::*;

module uart_module #(
    parameter int unsigned CLOCK_HZ  = 843_750,
    parameter int unsigned BAUD_RATE = 9600
) (
    input logic clk,
    input logic rst,

    input  logic                    [15:0] mmio_write_data_i,
    input  uart_registers_address_t        register_address_i,
    input  logic                           mmio_write_enable_i,
    input  logic                           mmio_read_enable_i,
    output logic                    [15:0] mmio_read_data_o,

    output logic tx_o,
    input  logic rx_i,  // Already synchronized to clk by the GPIO module.

    output logic rx_irq_o
);
  localparam uart_speed_t DefaultSpeed =
      BAUD_RATE == 19_200 ? UART_SPEED_19200 :
      BAUD_RATE == 57_600 ? UART_SPEED_57600 :
      BAUD_RATE == 115_200 ? UART_SPEED_115200 : UART_SPEED_9600;

  // -------------- CTRL ------------------
  uart_control_t uart_ctrl_reg;
  uart_control_t control_write_data;
  logic valid_write;


  // -------------- TX ------------------
  logic [7:0] tx_data_reg;
  logic start_tx_request;
  logic tx_busy;
  logic tx_idle;
  logic tx_finish;


  // -------------- RX ------------------
  logic [7:0] rx_data_reg;
  logic read_from_rx_addr;

  // -------------- ASSIGNMENTS ------------------
  assign control_write_data = uart_control_t'(mmio_write_data_i);
  assign uart_ctrl_reg.busy_tx = tx_busy;
  assign valid_write = mmio_write_enable_i && tx_idle && !uart_ctrl_reg.start_tx;
  assign start_tx_request = uart_ctrl_reg.start_tx && uart_ctrl_reg.uart_enable;
  assign rx_irq_o = uart_ctrl_reg.uart_enable && uart_ctrl_reg.rx_ifg && uart_ctrl_reg.rx_ie;
  assign read_from_rx_addr = mmio_read_enable_i && register_address_i == UART_RX_ADDRESS;

  uart_tx #(
      .CLOCK_HZ(CLOCK_HZ)
  ) tx (
      .clk(clk),
      .rst(rst),
      .enable_i(uart_ctrl_reg.uart_enable),
      .start_i(start_tx_request),
      .uart_speed_i(uart_ctrl_reg.uart_speed),
      .data_i(tx_data_reg),
      .tx_o(tx_o),
      .busy_o(tx_busy),
      .idle_o(tx_idle),
      .finish_o(tx_finish)
  );

  uart_rx #(
      .CLOCK_HZ(CLOCK_HZ)
  ) rx (
      .clk(clk),
      .rst(rst),
      .rx_i(rx_i),
      .uart_speed_i(uart_ctrl_reg.uart_speed),
      .enable_i(uart_ctrl_reg.uart_enable),
      .clear_ifg_i(read_from_rx_addr),
      .rx_data_o(rx_data_reg),
      .rx_ifg_o(uart_ctrl_reg.rx_ifg),
      .framing_error_o(uart_ctrl_reg.framing_error),
      .overrun_o(uart_ctrl_reg.overrun)
  );

  // --------- loading ---------
  always_ff @(posedge clk) begin
    if (rst) begin
      tx_data_reg                     <= 8'b0;
      uart_ctrl_reg.reserved          <= '0;
      uart_ctrl_reg.start_tx          <= 1'b0;
      uart_ctrl_reg.uart_speed        <= DefaultSpeed;
      uart_ctrl_reg.parity_bit_enable <= 1'b0;
      uart_ctrl_reg.parity_bit_error  <= 1'b0;
      // uart_ctrl_reg.framing_error     <= 1'b0;
      uart_ctrl_reg.auto_tx_start     <= 1'b0;
      uart_ctrl_reg.lsb_first         <= 1'b1;
      uart_ctrl_reg.rx_ie             <= 1'b0;
      uart_ctrl_reg.uart_enable       <= 1'b0;
      mmio_read_data_o                <= '0;
    end else begin
      if (tx_finish || !uart_ctrl_reg.uart_enable) begin
        uart_ctrl_reg.start_tx <= 1'b0;
      end

      // Enable and interrupt control remain writable during transmission.
      if (mmio_write_enable_i && register_address_i == UART_CTRL_REG_ADDRESS) begin
        if (!uart_ctrl_reg.uart_enable) begin
          uart_ctrl_reg.uart_speed <= control_write_data.uart_speed;
          uart_ctrl_reg.parity_bit_enable <= control_write_data.parity_bit_enable; // TODO: implement
          uart_ctrl_reg.lsb_first <= control_write_data.lsb_first;  // TODO: implement
        end
        uart_ctrl_reg.rx_ie <= control_write_data.rx_ie;
        uart_ctrl_reg.uart_enable <= control_write_data.uart_enable;
        if (!control_write_data.uart_enable) uart_ctrl_reg.start_tx <= 1'b0;
        else if (valid_write && !tx_finish) uart_ctrl_reg.start_tx <= control_write_data.start_tx;
      end

      if (valid_write && register_address_i == UART_TX_ADDRESS)
        tx_data_reg <= mmio_write_data_i[7:0];

      if (mmio_read_enable_i) begin
        case (register_address_i)
          UART_CTRL_REG_ADDRESS: mmio_read_data_o <= uart_ctrl_reg;
          UART_TX_ADDRESS: mmio_read_data_o <= {8'b0, tx_data_reg};
          UART_RX_ADDRESS: begin
            mmio_read_data_o <= {8'b0, rx_data_reg};

          end
          default: ;
        endcase
      end
    end
  end


endmodule
