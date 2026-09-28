module address_decoder #(
    parameter logic [31:0] RAM_BASE_ADDRESS = 32'h0000_0000,
    parameter logic [31:0] RAM_SIZE_BYTES = 32'h0000_8000,
    parameter logic [31:0] PERIPHERAL_BASE_ADDRESS = 32'h1000_0000,
    parameter logic [31:0] PERIPHERAL_SIZE_BYTES = 32'h0001_0000
) (
    input logic clk,
    input logic rst,

    input logic [31:0] address_i,
    input logic read_enable_i,
    input logic write_enable_i,

    output logic ram_read_enable_o,
    output logic ram_write_enable_o,
    input logic [31:0] ram_read_data_i,

    output logic peripheral_read_enable_o,
    output logic peripheral_write_enable_o,
    input logic [31:0] peripheral_read_data_i,

    output logic [31:0] read_data_o,
    output logic address_overlap_o
);
  typedef enum logic [1:0] {
    READ_TARGET_NONE,
    READ_TARGET_RAM,
    READ_TARGET_PERIPHERAL
  } read_target_t;

  logic ram_address_hit;
  logic peripheral_address_hit;
  read_target_t read_target;

  assign ram_address_hit = address_i >= RAM_BASE_ADDRESS
      && address_i < RAM_BASE_ADDRESS + RAM_SIZE_BYTES;
  assign peripheral_address_hit = address_i >= PERIPHERAL_BASE_ADDRESS
      && address_i < PERIPHERAL_BASE_ADDRESS + PERIPHERAL_SIZE_BYTES;
  assign address_overlap_o = ram_address_hit && peripheral_address_hit;

  always_comb begin
    ram_read_enable_o = 1'b0;
    ram_write_enable_o = 1'b0;
    peripheral_read_enable_o = 1'b0;
    peripheral_write_enable_o = 1'b0;

    if (!address_overlap_o) begin
      if (ram_address_hit) begin
        ram_read_enable_o  = read_enable_i;
        ram_write_enable_o = write_enable_i;
      end else if (peripheral_address_hit) begin
        peripheral_read_enable_o  = read_enable_i;
        peripheral_write_enable_o = write_enable_i;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      read_target <= READ_TARGET_NONE;
    end else if (read_enable_i) begin
      if (address_overlap_o) begin
        read_target <= READ_TARGET_NONE;
      end else if (ram_address_hit) begin
        read_target <= READ_TARGET_RAM;
      end else if (peripheral_address_hit) begin
        read_target <= READ_TARGET_PERIPHERAL;
      end else begin
        read_target <= READ_TARGET_NONE;
      end
    end
  end

  always_comb begin
    case (read_target)
      READ_TARGET_RAM: read_data_o = ram_read_data_i;
      READ_TARGET_PERIPHERAL: read_data_o = peripheral_read_data_i;
      default: read_data_o = 32'b0;
    endcase
  end

endmodule
