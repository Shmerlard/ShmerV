import gpio_types::*;

module gpio_module #(
    parameter int WIDTH = 8,
    parameter logic [WIDTH-1:0] ALT_MASK = '0,
    parameter logic [WIDTH-1:0] IRQ_MASK = '0
) (
    input logic clk,
    input logic rst,

    input  logic [WIDTH-1:0] pin_i,
    output logic [WIDTH-1:0] pin_o,
    output logic [WIDTH-1:0] pin_oe_o,

    output logic [WIDTH-1:0] alt_in_o,
    input  logic [WIDTH-1:0] alt_out_i,
    input  logic [WIDTH-1:0] alt_oe_i,

    input  logic                   [WIDTH-1:0] mmio_write_data_i,
    output logic                   [WIDTH-1:0] mmio_read_data_o,
    input  gpio_register_address_t             register_address_i,
    input  logic                               mmio_write_enable_i,
    input  logic                               mmio_read_enable_i,

    output logic irq_o
);
  logic [WIDTH-1:0] in_reg;
  logic [WIDTH-1:0] out_reg;
  logic [WIDTH-1:0] dir_reg;
  logic [WIDTH-1:0] sel_reg;
  logic [WIDTH-1:0] ie_reg;
  logic [WIDTH-1:0] ies_reg;
  logic [WIDTH-1:0] ifg_reg;

  logic [WIDTH-1:0] sync_ff1;
  logic [WIDTH-1:0] sync_ff2;

  logic [WIDTH-1:0] selected_output;
  logic [WIDTH-1:0] effective_sel;

  logic [WIDTH-1:0] prev_input;
  logic [WIDTH-1:0] rising_edge_input;
  logic [WIDTH-1:0] falling_edge_input;
  logic [WIDTH-1:0] selected_edge;

  assign effective_sel = ALT_MASK & sel_reg;
  assign in_reg = sync_ff2;
  assign alt_in_o = sync_ff2;
  assign irq_o = |(ifg_reg & ie_reg & IRQ_MASK);

  // Synchronizer
  always_ff @(posedge clk) begin
    if (rst) begin
      sync_ff1   <= '0;
      sync_ff2   <= '0;
      prev_input <= '0;
    end else begin
      sync_ff1   <= pin_i;
      sync_ff2   <= sync_ff1;
      prev_input <= sync_ff2;
    end
  end

  // IFG handling
  always_comb begin
    rising_edge_input = ~prev_input & sync_ff2 & IRQ_MASK;
    falling_edge_input = prev_input & ~sync_ff2 & IRQ_MASK;
    selected_edge = ~dir_reg & ~effective_sel
        & ((rising_edge_input & ~ies_reg) | (falling_edge_input & ies_reg));
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      ifg_reg <= '0;
    end else if (mmio_write_enable_i && register_address_i == GPIO_IFG_ADDRESS) begin
      ifg_reg <= ifg_reg | (mmio_write_data_i & IRQ_MASK) | selected_edge;
    end else if (mmio_write_enable_i && register_address_i == GPIO_IFG_CLR_ADDRESS) begin
      ifg_reg <= (ifg_reg & ~mmio_write_data_i) | selected_edge;
    end else begin
      ifg_reg <= ifg_reg | selected_edge;
    end
  end

  always_comb begin
    selected_output = (out_reg & ~effective_sel) | (alt_out_i & effective_sel);
    pin_o = selected_output;
    pin_oe_o = (alt_oe_i & effective_sel) | (dir_reg & ~effective_sel);
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      out_reg <= '0;
      dir_reg <= '0;
      sel_reg <= '0;
      ie_reg <= '0;
      ies_reg <= '0;
      mmio_read_data_o <= '0;
    end else begin
      if (mmio_write_enable_i) begin
        case (register_address_i)
          GPIO_OUT_ADDRESS: out_reg <= mmio_write_data_i;
          GPIO_DIR_ADDRESS: dir_reg <= mmio_write_data_i;
          GPIO_SEL_ADDRESS: sel_reg <= mmio_write_data_i & ALT_MASK;
          GPIO_IE_ADDRESS:  ie_reg <= mmio_write_data_i & IRQ_MASK;
          GPIO_IES_ADDRESS: ies_reg <= mmio_write_data_i & IRQ_MASK;
          default: begin
          end
        endcase
      end

      if (mmio_read_enable_i) begin
        case (register_address_i)
          GPIO_IN_ADDRESS:  mmio_read_data_o <= in_reg;
          GPIO_OUT_ADDRESS: mmio_read_data_o <= out_reg;
          GPIO_DIR_ADDRESS: mmio_read_data_o <= dir_reg;
          GPIO_SEL_ADDRESS: mmio_read_data_o <= sel_reg & ALT_MASK;
          GPIO_IE_ADDRESS:  mmio_read_data_o <= ie_reg;
          GPIO_IES_ADDRESS: mmio_read_data_o <= ies_reg;
          GPIO_IFG_ADDRESS: mmio_read_data_o <= ifg_reg;
          default: begin
            mmio_read_data_o <= '0;
          end
        endcase
      end
    end
  end



endmodule
