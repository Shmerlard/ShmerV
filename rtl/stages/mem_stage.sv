import core_types::*;

module mem_stage (
    input logic valid_i,
    input logic [31:0] alu_result_i,
    input logic [31:0] pc_plus_4_i,
    input logic [31:0] csr_read_data_i,
    input logic [31:0] csr_write_data_i,  // TODO: better name
    input logic [31:0] rs2_data_i,  // TODO: better name!
    input logic [11:0] csr_address_i,

    input memory_control_t memory_control_i,
    input writeback_control_t writeback_control_i,

    output logic [31:0] memory_address_o,
    output logic [31:0] memory_write_data_o,
    output logic [ 3:0] memory_write_byte_enable_o,

    output logic memory_read_enable_o,
    output logic memory_write_enable_o,

    output logic csr_read_enable_o,
    output logic csr_write_enable_o,
    output logic [11:0] csr_address_o,
    output logic [31:0] csr_write_data_o,

    output logic [31:0] forward_data_o

);
  logic memory_access_aligned;
  logic [1:0] byte_offset;

  assign memory_address_o = alu_result_i;

  assign memory_read_enable_o =
      memory_control_i.memory_read_enable && valid_i && memory_access_aligned;
  assign memory_write_enable_o =
      memory_control_i.memory_write_enable && valid_i && memory_access_aligned;

  assign byte_offset = alu_result_i[1:0];
  assign memory_write_data_o = rs2_data_i << {byte_offset, 3'b000};

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

  always_comb begin
    csr_read_enable_o = memory_control_i.csr_read_enable && valid_i;
    csr_write_enable_o = memory_control_i.csr_write_enable && valid_i;

    csr_address_o = csr_address_i;
    csr_write_data_o = csr_write_data_i;


  end

  always_comb begin
    case (writeback_control_i.writeback_source)
      WRITEBACK_SOURCE_ALU:  forward_data_o = alu_result_i;
      WRITEBACK_SOURCE_PC4:  forward_data_o = pc_plus_4_i;
      WRITEBACK_SOURCE_CSR:  forward_data_o = csr_read_data_i;
      default:               forward_data_o = 32'b0;
    endcase
  end

endmodule
