module memory #(
    parameter int MEM_WORDS = 1024
) (
    input logic clk,
    input logic [31:0] addr_rd_a,
    input logic [31:0] addr_rd_b,
    input logic [31:0] addr_wr,
    input logic wr_en,
    input logic [31:0] wr_data_i,
    output logic [31:0] data_rd_a,
    output logic [31:0] data_rd_b
);
  localparam int ADDR_WIDTH = $clog2(MEM_WORDS);
  logic [31:0] mem[0:MEM_WORDS-1];

  always_ff @(posedge clk) begin
    data_rd_a <= mem[addr_rd_a[ADDR_WIDTH+1:2]];
    data_rd_b <= mem[addr_rd_b[ADDR_WIDTH+1:2]];

    if (wr_en) begin
      mem[addr_wr[ADDR_WIDTH+1:2]] <= wr_data_i;
    end
  end


endmodule
