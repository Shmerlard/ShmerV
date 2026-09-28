module if_stage #(
    parameter logic [31:0] RESET_PC = 32'h0000_0000
) (
    input logic clk,
    input logic rst,
    input logic pc_write_enable_i,
    input logic [31:0] imem_read_data_i,

    output logic [31:0] imem_read_address_o,
    output logic [31:0] instruction_o,
    output logic [31:0] pc_o,

    input logic pc_redirect_enable_i,
    input logic [31:0] pc_redirect_address_i

);
  logic [31:0] pc_next;

  assign instruction_o = imem_read_data_i;
  assign imem_read_address_o = pc_o;


  program_counter #(
      .RESET_PC(RESET_PC)
  ) pc (
      .clk      (clk),
      .rst      (rst),
      .enable_i (pc_write_enable_i),
      .next_pc_i(pc_next),
      .pc_o     (pc_o)
  );

  assign pc_next = pc_redirect_enable_i ? pc_redirect_address_i : pc_o + 32'd4;
endmodule
