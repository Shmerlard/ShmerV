package csr_types;
  localparam int MSTATUS_MIE_BIT = 3;
  localparam int MSTATUS_MPIE_BIT = 7;
  localparam int MSTATUS_MPP_LSB = 11;
  localparam int MSTATUS_MPP_MSB = 12;
  localparam logic [1:0] MSTATUS_MPP_MACHINE = 2'b11;

  typedef enum logic {
    TRAP_TYPE_EXCEPTION,
    TRAP_TYPE_INTERRUPT
  } trap_type_t;

  typedef enum logic [4:0] {
    TRAP_CAUSE_ILLEGAL_INSTRUCTION = 5'h02,
    TRAP_CAUSE_BREAKPOINT          = 5'h03,
    TRAP_CAUSE_MACHINE_ECALL       = 5'h0b
  } trap_cause_exception_t;

  typedef enum logic [4:0] {
    TRAP_CAUSE_MACHINE_SOFTWARE_INTERRUPT = 5'h03,
    TRAP_CAUSE_MACHINE_EXTERNAL_INTERRUPT = 5'h0b
  } trap_cause_interrupt_t;

  typedef enum logic [2:0] {
    CSR_INSTRUCTION_CSRRW  = 3'b001,
    CSR_INSTRUCTION_CSRRS  = 3'b010,
    CSR_INSTRUCTION_CSRRC  = 3'b011,
    CSR_INSTRUCTION_CSRRWI = 3'b101,
    CSR_INSTRUCTION_CSRRSI = 3'b110,
    CSR_INSTRUCTION_CSRRCI = 3'b111
  } csr_instruction_t;

  typedef enum logic [1:0] {
    CSR_WRITE_REPLACE,
    CSR_WRITE_SET,
    CSR_WRITE_CLEAR
  } csr_write_operation_t;

  typedef enum logic [11:0] {
    CSR_ADDRESS_MSTATUS = 12'h300,
    CSR_ADDRESS_MTVEC   = 12'h305,
    CSR_ADDRESS_MEPC    = 12'h341,
    CSR_ADDRESS_MCAUSE  = 12'h342,
    CSR_ADDRESS_MTVAL   = 12'h343
  } csr_address_t;

  function automatic logic csr_address_supported(input logic [11:0] address);
    case (csr_address_t'(address))
      CSR_ADDRESS_MSTATUS,
      CSR_ADDRESS_MTVEC,
      CSR_ADDRESS_MEPC,
      CSR_ADDRESS_MCAUSE,
      CSR_ADDRESS_MTVAL:
      csr_address_supported = 1'b1;
      default: csr_address_supported = 1'b0;
    endcase
  endfunction

  function automatic logic csr_address_read_only(input logic [11:0] address);
    csr_address_read_only = address[11:10] == 2'b11;
  endfunction

endpackage
