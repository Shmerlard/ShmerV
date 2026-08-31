module if_id_reg (
    input logic clk,
    input logic rst,
    input logic [31:0] imem_rdata,
    input logic [31:0] pc_if,

    output logic valid_id,
    output logic [31:0] instr_id,
    output logic [31:0] pc_id

);

  assign instr_id = imem_rdata;
  always_ff @(posedge clk) begin
    if (rst) begin
      pc_id    <= '0;
      valid_id <= 1'b0;
    end else begin
      pc_id    <= pc_if;
      valid_id <= 1'b1;
    end
  end
endmodule
