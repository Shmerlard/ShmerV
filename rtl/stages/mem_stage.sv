import core_types::*;
import csr_types::*;

module mem_stage (
    input logic valid_i,
    input memory_control_t memory_control_i,
    input writeback_control_t writeback_control_i,

    input logic [31:0] alu_result_i,
    input logic [31:0] pc_plus_4_i,

    input logic [31:0] store_data_in_mem_i,

    output logic [31:0] memory_address_o,
    output logic [3:0] memory_write_byte_enable_o,
    output logic memory_read_enable_o,
    output logic memory_write_enable_o,
    output logic [31:0] memory_store_data_o,
    input logic [31:0] memory_load_data_i,
    output logic [31:0] memory_load_data_out_mem_o,


    output logic csr_read_enable_o,
    output logic csr_write_enable_o,
    input logic [11:0] csr_address_i,
    output logic [11:0] csr_address_o,
    output logic [31:0] csr_store_data_o,
    input logic [31:0] csr_load_data_i,
    output logic [31:0] csr_load_data_out_mem_o,

    output logic [31:0] forward_data_o

);
  logic memory_access_aligned;
  logic [1:0] byte_offset;

  memory_target_t target;
  assign target = memory_control_i.target;
  assign memory_address_o = alu_result_i;


  // DMemory Control
  always_comb begin
    memory_read_enable_o =
        memory_control_i.read_enable && valid_i && memory_access_aligned && target == MEMORY_TARGET_DMEMORY;
    memory_write_enable_o =
        memory_control_i.write_enable && valid_i && memory_access_aligned && target == MEMORY_TARGET_DMEMORY;

    byte_offset = alu_result_i[1:0];
    memory_store_data_o = store_data_in_mem_i << {byte_offset, 3'b000};
    memory_load_data_out_mem_o = memory_load_data_i;
  end

  // CSR Control
  always_comb begin
    csr_load_data_out_mem_o = csr_load_data_i;
    csr_read_enable_o = memory_control_i.read_enable && valid_i && target == MEMORY_TARGET_CSR;
    csr_write_enable_o = memory_control_i.write_enable && valid_i && target == MEMORY_TARGET_CSR;
    csr_address_o = csr_address_i;

    case (memory_control_i.csr_write_operation)
      CSR_WRITE_REPLACE: csr_store_data_o = store_data_in_mem_i;
      CSR_WRITE_SET: csr_store_data_o = csr_load_data_i | store_data_in_mem_i;
      CSR_WRITE_CLEAR: csr_store_data_o = csr_load_data_i & ~store_data_in_mem_i;
      default: csr_store_data_o = 32'b0;
    endcase
  end

  // Dmemory byte enable
  always_comb begin
    memory_access_aligned = 1'b0;
    memory_write_byte_enable_o = 4'b0000;

    case (memory_control_i.access_size)
      MEMORY_ACCESS_BYTE: begin
        memory_access_aligned = 1'b1;
        memory_write_byte_enable_o = 4'b0001 << byte_offset;
      end
      MEMORY_ACCESS_HALF: begin
        memory_access_aligned = alu_result_i[0] == 1'b0;
        if (memory_access_aligned) memory_write_byte_enable_o = 4'b0011 << byte_offset;
      end
      MEMORY_ACCESS_WORD: begin
        memory_access_aligned = alu_result_i[1:0] == 2'b00;
        if (memory_access_aligned) memory_write_byte_enable_o = 4'b1111;
      end
      MEMORY_ACCESS_INVALID: begin
        memory_access_aligned = 1'b0;
      end
      default: begin
        memory_access_aligned = 1'b0;
      end
    endcase
  end

  // forward data selection
  always_comb begin
    case (writeback_control_i.writeback_source)
      WRITEBACK_SOURCE_ALU: forward_data_o = alu_result_i;
      WRITEBACK_SOURCE_PC4: forward_data_o = pc_plus_4_i;
      WRITEBACK_SOURCE_CSR: forward_data_o = csr_load_data_i;
      default:              forward_data_o = 32'b0;
    endcase
  end

endmodule
