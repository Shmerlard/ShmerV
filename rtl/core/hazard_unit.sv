import core_types::*;
module hazard_unit (
    input logic [4:0] rs1_ex_i,
    input logic [4:0] rs2_ex_i,
    input logic [4:0] rs1_id_i,
    input logic [4:0] rs2_id_i,
    input logic uses_rs1_id_i,
    input logic uses_rs2_id_i,
    input logic [4:0] rd_mem_i,
    input logic [4:0] rd_wb_i,

    input logic valid_mem_i,
    input logic valid_wb_i,
    input logic reg_write_mem_i,
    input logic reg_write_wb_i,

    output logic halt_pc_o,
    output logic stall_if_id_o,
    output logic bubble_id_ex_o,

    output forwarding_source_t rs1_forwarding_source_o,
    output forwarding_source_t rs2_forwarding_source_o
);
  logic mem_can_forward;
  logic wb_can_forward;

  assign mem_can_forward = valid_mem_i && reg_write_mem_i && (rd_mem_i != 5'b0);
  assign wb_can_forward = valid_wb_i && reg_write_wb_i && (rd_wb_i != 5'b0);

  assign halt_pc_o = 1'b0;
  assign stall_if_id_o = 1'b0;
  assign bubble_id_ex_o = 1'b0;

  always_comb begin
    rs1_forwarding_source_o = FORWARD_SOURCE_REGISTER;
    rs2_forwarding_source_o = FORWARD_SOURCE_REGISTER;

    if (mem_can_forward && (rd_mem_i == rs1_ex_i)) rs1_forwarding_source_o = FORWARD_SOURCE_MEM;
    else if (wb_can_forward && (rd_wb_i == rs1_ex_i)) rs1_forwarding_source_o = FORWARD_SOURCE_WB;

    if (mem_can_forward && (rd_mem_i == rs2_ex_i)) rs2_forwarding_source_o = FORWARD_SOURCE_MEM;
    else if (wb_can_forward && (rd_wb_i == rs2_ex_i)) rs2_forwarding_source_o = FORWARD_SOURCE_WB;
  end

endmodule
