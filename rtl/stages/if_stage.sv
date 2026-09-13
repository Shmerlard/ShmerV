module if_stage (
    input logic clk,
    input logic rst,
    input logic pc_write_enable_i,
    input logic [31:0] instruction_memory_read_data_i,

    output logic [31:0] instruction_memory_address_o,
    output logic [31:0] instruction_if_o

);
  logic [31:0] pc_next;

  assign instruction_if_o = instruction_memory_read_data_i;


  program_counter pc (
      .clk      (clk),
      .rst      (rst),
      .enable_i (pc_write_enable_i),
      .next_pc_i(pc_next),
      .pc_o     (instruction_memory_address_o)
  );

  assign pc_next = instruction_memory_address_o + 32'd4;
endmodule
