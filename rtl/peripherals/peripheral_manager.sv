module peripheral_manager #(
    parameter logic [31:0] GPIO_BASE_ADDRESS = 32'h1000_0000
) (
    input logic clk,
    input logic rst,

    input  logic [31:0] address_i,
    input  logic [31:0] write_data_i,
    input  logic [ 3:0] write_byte_enable_i,
    input  logic        read_enable_i,
    input  logic        write_enable_i,
    output logic [31:0] read_data_o,

    input  logic [7:0] gpio_pin_i,
    output logic [7:0] gpio_pin_o,
    output logic [7:0] gpio_pin_oe_o,

    output logic irq_o
);
  localparam logic [31:0] GpioAddressSpaceBytes = 32'h0000_0100;

  logic gpio_address_hit;
  logic [31:0] gpio_address_offset;
  logic [4:0] gpio_register_address;
  logic gpio_read_enable;
  logic gpio_write_enable;
  logic gpio_read_selected;
  logic [7:0] gpio_read_data;
  logic [7:0] gpio_alt_input;

  assign gpio_address_hit = address_i >= GPIO_BASE_ADDRESS
      && address_i < GPIO_BASE_ADDRESS + GpioAddressSpaceBytes;
  assign gpio_address_offset = address_i - GPIO_BASE_ADDRESS;
  assign gpio_register_address = gpio_address_offset[6:2];
  assign gpio_read_enable = read_enable_i && gpio_address_hit;
  assign gpio_write_enable = write_enable_i && gpio_address_hit && write_byte_enable_i[0];

  always_ff @(posedge clk) begin
    if (rst) begin
      gpio_read_selected <= 1'b0;
    end else if (read_enable_i) begin
      gpio_read_selected <= gpio_address_hit;
    end
  end

  always_comb begin
    if (gpio_read_selected) begin
      read_data_o = {24'b0, gpio_read_data};
    end else begin
      read_data_o = 32'b0;
    end
  end

  gpio_module #(
      .WIDTH   (8),
      .ALT_MASK(8'b0),
      .IRQ_MASK(8'b0)
  ) gpio (
      .clk                (clk),
      .rst                (rst),
      .pin_i              (gpio_pin_i),
      .pin_o              (gpio_pin_o),
      .pin_oe_o           (gpio_pin_oe_o),
      .alt_in_o           (gpio_alt_input),
      .alt_out_i          (8'b0),
      .alt_oe_i           (8'b0),
      .mmio_write_data_i  (write_data_i[7:0]),
      .mmio_read_data_o   (gpio_read_data),
      .register_address_i (gpio_register_address),
      .mmio_write_enable_i(gpio_write_enable),
      .mmio_read_enable_i (gpio_read_enable),
      .irq_o              (irq_o)
  );

endmodule
