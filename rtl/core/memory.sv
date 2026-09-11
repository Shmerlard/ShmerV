module memory #(
    parameter int MEM_WORDS = 1024
) (
    input logic clk,
    input logic [31:0] instruction_read_address_i,
    input logic [31:0] data_read_address_i,
    input logic [31:0] data_write_address_i,
    input logic data_write_enable_i,
    input logic [31:0] data_write_data_i,
    output logic [31:0] instruction_read_data_o,
    output logic [31:0] data_read_data_o
);
  localparam int AddressWidth = $clog2(MEM_WORDS);
  logic [31:0] memory_words[MEM_WORDS];

  always_ff @(posedge clk) begin
    instruction_read_data_o <= memory_words[instruction_read_address_i[AddressWidth+1:2]];
    data_read_data_o <= memory_words[data_read_address_i[AddressWidth+1:2]];

    if (data_write_enable_i) begin
      memory_words[data_write_address_i[AddressWidth+1:2]] <= data_write_data_i;
    end
  end


endmodule
