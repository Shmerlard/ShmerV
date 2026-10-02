import core_types::*;
import csr_types::*;
module csr (
    input logic clk,
    input logic rst,

    input logic csr_read_enable_i,
    input logic csr_write_enable_i,
    input logic trap_taken_i,
    input logic mret_taken_i,
    input logic [31:0] trap_pc_ex_i,
    input trap_type_t trap_type_i,
    input logic [4:0] trap_cause_i,
    input logic [31:0] trap_instruction_ex_i,
    input logic [11:0] csr_address_i,
    input logic [31:0] csr_write_data_i,

    output logic [31:0] csr_load_data_o,
    output logic csr_access_illegal_o,
    output logic [31:0] csr_pc_redirect_address_o,
    output logic interrupts_enabled_o
);

  // CSR registers
  logic [31:0] mstatus;
  logic [31:0] mtvec;

  logic [31:0] mepc;
  logic [31:0] mcause;
  logic [31:0] mtval;

  logic [31:0] mtval_new;
  logic [31:0] mstatus_write_value;

  logic [31:0] vector_base_address;
  logic [31:0] vector_offset;

  assign interrupts_enabled_o = mstatus[MSTATUS_MIE_BIT];

  always_comb begin
    mstatus_write_value = csr_write_data_i;
    mstatus_write_value[MSTATUS_MPP_MSB:MSTATUS_MPP_LSB] = MSTATUS_MPP_MACHINE;
  end

  logic csr_write_access_illegal;
  logic csr_read_access_illegal;
  assign csr_access_illegal_o = csr_write_access_illegal || csr_read_access_illegal;

  logic write_to_read_only;
  assign write_to_read_only = csr_write_enable_i && csr_address_read_only(csr_address_i);
  logic unsupported_address;
  assign unsupported_address = !csr_address_supported(csr_address_i);
  assign csr_write_access_illegal = csr_write_enable_i && (unsupported_address || csr_address_read_only(
      csr_address_i
  ));


  // Main sequential logic
  always_ff @(posedge clk) begin
    if (rst == 1'b1) begin
      mstatus <= 32'h0000_1800;
      mtvec <= 32'h0000_0001;
      mepc <= 32'b0;
      mcause <= 32'b0;
      mtval <= 32'b0;
    end else begin
      if (trap_taken_i == 1'b1) begin
        mepc <= {trap_pc_ex_i[31:2], 2'b00};
        mcause <= {trap_type_i, {26{1'b0}}, trap_cause_i};
        mtval <= mtval_new;
        mstatus[MSTATUS_MPIE_BIT] <= mstatus[MSTATUS_MIE_BIT];
        mstatus[MSTATUS_MIE_BIT] <= 1'b0;
        mstatus[MSTATUS_MPP_MSB:MSTATUS_MPP_LSB] <= MSTATUS_MPP_MACHINE;
      end else if (mret_taken_i) begin
        mstatus[MSTATUS_MIE_BIT]  <= mstatus[MSTATUS_MPIE_BIT];
        mstatus[MSTATUS_MPIE_BIT] <= 1'b1;
      end else begin
        if (csr_write_enable_i) begin
          if (unsupported_address) begin
          end else
          if (write_to_read_only) begin
          end else
            case (csr_address_t'(csr_address_i))
              CSR_ADDRESS_MSTATUS: mstatus <= mstatus_write_value;
              CSR_ADDRESS_MTVEC:   mtvec <= {csr_write_data_i[31:2], 2'b01};
              CSR_ADDRESS_MEPC:    mepc <= {csr_write_data_i[31:2], 2'b00};
              CSR_ADDRESS_MCAUSE:  mcause <= csr_write_data_i;
              CSR_ADDRESS_MTVAL:   mtval <= csr_write_data_i;

              default: begin
              end
            endcase
        end
      end
    end
  end

  // Exceptions use BASE; interrupts use BASE + 4*cause.
  always_comb begin
    vector_base_address = {mtvec[31:2], 2'b00};
    vector_offset = {25'b0, trap_cause_i, 2'b00};

    if (mret_taken_i) begin
      csr_pc_redirect_address_o = mepc;
    end else begin
      if (trap_type_i == TRAP_TYPE_EXCEPTION) begin
        csr_pc_redirect_address_o = vector_base_address;
      end else begin
        csr_pc_redirect_address_o = vector_base_address + vector_offset;
      end
    end
  end

  // Loading data
  always_comb begin
    csr_load_data_o = 32'b0;
    csr_read_access_illegal = 1'b0;
    if (csr_read_enable_i) begin
      if (unsupported_address) begin
        csr_read_access_illegal = 1'b1;
      end else
        case (csr_address_t'(csr_address_i))
          CSR_ADDRESS_MSTATUS: csr_load_data_o = mstatus;
          CSR_ADDRESS_MTVEC:   csr_load_data_o = mtvec;
          CSR_ADDRESS_MEPC:    csr_load_data_o = mepc;
          CSR_ADDRESS_MCAUSE:  csr_load_data_o = mcause;
          CSR_ADDRESS_MTVAL:   csr_load_data_o = mtval;
          default: csr_load_data_o = 32'b0;
        endcase
    end
  end

  // calculating new mtval
  always_comb begin
    mtval_new = 32'b0;
    case (trap_type_i)
      TRAP_TYPE_EXCEPTION: begin
        case (trap_cause_exception_t'(trap_cause_i))
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

endmodule
