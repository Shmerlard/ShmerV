module memory #(
    parameter int MEM_WORDS = 1024
) (
    input logic clk,
    input logic [31:0] port_a_read_address_i,
    output logic [31:0] port_a_read_data_o,

    input logic [31:0] port_b_read_address_i,
    input logic [31:0] port_b_write_address_i,
    input logic port_b_write_enable_i,
    input logic port_b_read_enable_i,
    input logic [31:0] port_b_write_data_i,
    output logic [31:0] port_b_read_data_o
);
  localparam int AddressWidth = $clog2(MEM_WORDS);
  logic [31:0] memory_words[MEM_WORDS];

  always_ff @(posedge clk) begin
    port_a_read_data_o <= memory_words[port_a_read_address_i[AddressWidth+1:2]];

    if (port_b_read_enable_i) begin
      port_b_read_data_o <= memory_words[port_b_read_address_i[AddressWidth+1:2]];
    end

    if (port_b_write_enable_i) begin
      memory_words[port_b_write_address_i[AddressWidth+1:2]] <= port_b_write_data_i;
    end
  end


endmodule
