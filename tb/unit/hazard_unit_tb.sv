timeunit 1ns / 1ps;

import core_types::*;

module hazard_unit_tb;
  typedef logic [4:0] register_index_t;

  logic [4:0] rs1_ex_i;
  logic [4:0] rs2_ex_i;
  logic [4:0] rs1_id_i;
  logic [4:0] rs2_id_i;
  logic uses_rs1_id_i;
  logic uses_rs2_id_i;
  logic valid_id_i;
  logic valid_ex_i;
  logic [4:0] rd_ex_i;
  logic memory_read_ex_i;
  logic [4:0] rd_mem_i;
  logic [4:0] rd_wb_i;
  logic valid_mem_i;
  logic valid_wb_i;
  logic reg_write_mem_i;
  logic reg_write_wb_i;
  writeback_source_t writeback_source_mem_i;
  logic halt_pc_o;
  logic stall_if_id_o;
  logic bubble_id_ex_o;
  forwarding_source_t rs1_forwarding_source_o;
  forwarding_source_t rs2_forwarding_source_o;
  int unsigned random_seed;

  hazard_unit dut (.*);

  function automatic forwarding_source_t expected_source(input logic [4:0] rs);
    if (valid_mem_i && reg_write_mem_i && (rd_mem_i != 5'b0)
        && (writeback_source_mem_i == WRITEBACK_SOURCE_ALU) && (rd_mem_i == rs))
      return FORWARD_SOURCE_MEM;
    if (valid_wb_i && reg_write_wb_i && (rd_wb_i != 5'b0) && (rd_wb_i == rs))
      return FORWARD_SOURCE_WB;
    return FORWARD_SOURCE_REGISTER;
  endfunction

  function automatic logic expected_load_use_hazard;
    return valid_ex_i && memory_read_ex_i && (rd_ex_i != 5'b0) && valid_id_i
        && ((uses_rs1_id_i && (rs1_id_i == rd_ex_i))
            || (uses_rs2_id_i && (rs2_id_i == rd_ex_i)));
  endfunction

  task automatic check_outputs;
    #1ns;
    assert (halt_pc_o == expected_load_use_hazard());
    assert (stall_if_id_o == expected_load_use_hazard());
    assert (bubble_id_ex_o == expected_load_use_hazard());
    assert (rs1_forwarding_source_o == expected_source(rs1_ex_i));
    assert (rs2_forwarding_source_o == expected_source(rs2_ex_i));
  endtask

  initial begin
    $dumpfile("build/tests/hazard_unit/waveform.fst");
    $dumpvars(0, hazard_unit_tb);

    rs1_ex_i               = 5'd1;
    rs2_ex_i               = 5'd2;
    rs1_id_i               = 5'd1;
    rs2_id_i               = 5'd2;
    uses_rs1_id_i          = 1'b0;
    uses_rs2_id_i          = 1'b0;
    valid_id_i             = 1'b0;
    valid_ex_i             = 1'b0;
    rd_ex_i                = 5'd0;
    memory_read_ex_i       = 1'b0;
    rd_mem_i               = 5'd3;
    rd_wb_i                = 5'd4;
    valid_mem_i            = 1'b1;
    valid_wb_i             = 1'b1;
    reg_write_mem_i        = 1'b1;
    reg_write_wb_i         = 1'b1;
    writeback_source_mem_i = WRITEBACK_SOURCE_ALU;
    check_outputs();

    // rs1 and rs2 can forward from different stages.
    rd_mem_i = rs1_ex_i;
    rd_wb_i  = rs2_ex_i;
    check_outputs();

    // MEM contains the newer value when both stages write the same register.
    rd_wb_i = rs1_ex_i;
    check_outputs();
    assert (rs1_forwarding_source_o == FORWARD_SOURCE_MEM);

    // x0, invalid stages, and disabled register writes cannot forward.
    rs1_ex_i = 5'd0;
    rd_mem_i = 5'd0;
    rd_wb_i  = 5'd0;
    check_outputs();

    rs1_ex_i = 5'd5;
    rs2_ex_i = 5'd6;
    rd_mem_i = 5'd5;
    rd_wb_i = 5'd6;
    valid_mem_i = 1'b0;
    reg_write_wb_i = 1'b0;
    check_outputs();

    // Loads and PC+4 producers cannot forward through the ALU-only MEM path.
    rs1_ex_i = 5'd5;
    rd_mem_i = 5'd5;
    valid_mem_i = 1'b1;
    reg_write_mem_i = 1'b1;
    writeback_source_mem_i = WRITEBACK_SOURCE_MEMORY;
    check_outputs();

    writeback_source_mem_i = WRITEBACK_SOURCE_PC4;
    check_outputs();

    writeback_source_mem_i = WRITEBACK_SOURCE_ALU;

    // A valid load-use dependency on either source stalls the younger instruction.
    valid_id_i             = 1'b1;
    valid_ex_i             = 1'b1;
    memory_read_ex_i       = 1'b1;
    rd_ex_i                = 5'd10;
    rs1_id_i               = 5'd10;
    rs2_id_i               = 5'd11;
    uses_rs1_id_i          = 1'b1;
    uses_rs2_id_i          = 1'b0;
    check_outputs();

    rs1_id_i      = 5'd11;
    rs2_id_i      = 5'd10;
    uses_rs1_id_i = 1'b0;
    uses_rs2_id_i = 1'b1;
    check_outputs();

    // Matching unused instruction fields do not create dependencies.
    uses_rs2_id_i = 1'b0;
    check_outputs();

    rs1_id_i      = 5'd10;
    rs2_id_i      = 5'd11;
    uses_rs1_id_i = 1'b0;
    uses_rs2_id_i = 1'b1;
    check_outputs();

    // x0, invalid stages, non-loads, and different registers do not stall.
    uses_rs1_id_i = 1'b1;
    rd_ex_i       = 5'd0;
    rs1_id_i      = 5'd0;
    check_outputs();

    rd_ex_i    = 5'd10;
    rs1_id_i   = 5'd10;
    valid_ex_i = 1'b0;
    check_outputs();

    valid_ex_i = 1'b1;
    valid_id_i = 1'b0;
    check_outputs();

    valid_id_i       = 1'b1;
    memory_read_ex_i = 1'b0;
    check_outputs();

    memory_read_ex_i = 1'b1;
    rs1_id_i         = 5'd12;
    check_outputs();

    memory_read_ex_i = 1'b0;

    // Deterministic randomized checks, with frequent forced dependencies.
    random_seed = 32'hc001_c0de;
    void'($urandom(random_seed));
    for (int index = 0; index < 500; index++) begin
      rs1_ex_i = register_index_t'($urandom_range(31, 0));
      rs2_ex_i = register_index_t'($urandom_range(31, 0));
      rd_mem_i = register_index_t'($urandom_range(31, 0));
      rd_wb_i = register_index_t'($urandom_range(31, 0));
      valid_mem_i = logic'($urandom_range(1, 0));
      valid_wb_i = logic'($urandom_range(1, 0));
      reg_write_mem_i = logic'($urandom_range(1, 0));
      reg_write_wb_i = logic'($urandom_range(1, 0));

      case (index % 5)
        0: rd_mem_i = rs1_ex_i;
        1: rd_wb_i = rs1_ex_i;
        2: rd_mem_i = rs2_ex_i;
        3: rd_wb_i = rs2_ex_i;
        4: begin
          rd_mem_i = rs1_ex_i;
          rd_wb_i = rs1_ex_i;
          valid_mem_i = 1'b1;
          valid_wb_i = 1'b1;
          reg_write_mem_i = 1'b1;
          reg_write_wb_i = 1'b1;
        end
        default: $fatal(1, "Unexpected random-test case");
      endcase
      check_outputs();
    end

    $display("hazard_unit tests passed");
    $finish;
  end
endmodule
