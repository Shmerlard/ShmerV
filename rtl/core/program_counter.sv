module program_counter #(
    parameter logic [31:0] RESET_PC = 32'h0000_0000
) (
    input logic clk,
    input logic rst,
    input logic enable_i,
    input logic [31:0] next_pc_i,
    output logic [31:0] pc_o
);
  always_ff @(posedge clk) begin
    if (rst) begin
      pc_o <= RESET_PC;
    end else begin
      if (enable_i) begin
        pc_o <= next_pc_i;
      end
    end
  end
endmodule
