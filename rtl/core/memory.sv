module memory #(
    parameter int MEM_WORDS = 1024,
    parameter string INIT_FILE = ""
) (
    input logic clk,
    input logic [31:0] port_a_read_address_i,
    input logic port_a_read_enable_i,
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
  string runtime_init_file;

  initial begin
    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, memory_words);
    end else if ($value$plusargs("memory_init=%s", runtime_init_file)) begin
      $readmemh(runtime_init_file, memory_words);
    end
  end

  always_ff @(posedge clk) begin
    if (port_a_read_enable_i) begin
      port_a_read_data_o <= memory_words[port_a_read_address_i[AddressWidth+1:2]];
    end

    if (port_b_read_enable_i) begin
      port_b_read_data_o <= memory_words[port_b_read_address_i[AddressWidth+1:2]];
    end

    if (port_b_write_enable_i) begin
      memory_words[port_b_write_address_i[AddressWidth+1:2]] <= port_b_write_data_i;
    end
  end


endmodule
