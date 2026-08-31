module memory #(
    parameter int MEM_WORDS = 1024
) (
    input logic clk,
    input logic [31:0] addr_rd_a,
    input logic [31:0] addr_rd_b,
    input logic [31:0] addr_wr,
    output logic [31:0] data_rd_a,
    output logic [31:0] data_rd_b
);
  localparam int ADDR_WIDTH = $clog2(MEM_WORDS);
  logic [31:0] mem[0:MEM_WORDS-1];

  always_ff @(posedge clk) begin
    data_rd_a <= mem[addr_rd_a[ADDR_WIDTH+1:2]];
  end

  // NO HANDLING OF PORT B YET
  assign data_rd_b = '0;
endmodule
