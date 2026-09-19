import core_types::*;
module csr (
    input logic clk,
    input logic rst,

    input logic csr_read_enable_i,
    input logic csr_write_enable_i,
    input logic trap_taken_i,
    input logic [31:0] trap_pc_ex_i,
    input trap_type_t trap_type_i,
    input trap_cause_exception_t trap_cause_exception_i,
    input logic [31:0] trap_instruction_ex_i,
    input logic [11:0] csr_address_i,
    input logic [31:0] csr_write_data_i,

    output logic [31:0] csr_read_data_o
);

  logic [31:0] mstatus;
  logic [31:0] mtvec;

  logic [31:0] mepc;
  logic [31:0] mcause;
  logic [31:0] mtval;

  logic [ 4:0] trap_cause;
  logic [31:0] mtval_new;

  always_ff @(posedge clk) begin
    if (rst == 1'b1) begin
      mstatus <= 32'h0000_1800;
      mtvec <= 32'b0;
      mepc <= 32'b0;
      mcause <= 32'b0;
      mtval <= 32'b0;
    end else begin
      if (trap_taken_i == 1'b1) begin
        mepc[31:2] <= trap_pc_ex_i[31:2];
        mcause <= {trap_type_i, {26{1'b0}}, trap_cause};
        mtval <= mtval_new;
      end
    end
  end

  always_comb begin
    case (trap_type_i)
      TRAP_TYPE_EXCEPTION: begin
        case (trap_cause_exception_i)
          TRAP_CAUSE_ILLEGAL_INSTRUCTION: mtval_new = trap_instruction_ex_i;
          default: begin
            mtval_new = 32'b0;
          end
        endcase
      end
      TRAP_TYPE_INTERRUPT: begin
      end
      default: begin
      end
    endcase
  end

  always_comb begin
    trap_cause = trap_cause_exception_i;
    case (trap_type_i)
      TRAP_TYPE_EXCEPTION: trap_cause = trap_cause_exception_i;
      default: trap_cause = trap_cause_exception_i;
    endcase
  end
endmodule
