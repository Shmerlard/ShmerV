timeunit 1ns / 1ps;

module if_stage (
    input logic clk,
    input logic rst,
    input logic pc_wr_en,
    input logic [31:0] imem_data,

    output logic [31:0] imem_addr,
    output logic [31:0] inst_if

);
  logic [31:0] next_pc;

  assign inst_if = imem_data;


  program_counter pc (
      .clk    (clk),
      .rst    (rst),
      .enable (pc_wr_en),
      .next_pc(next_pc),
      .pc_out (imem_addr)
  );

  assign next_pc = imem_addr + 32'd4;
endmodule
