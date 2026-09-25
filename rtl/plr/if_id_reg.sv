module if_id_reg (
    input logic clk,
    input logic rst,
    input logic [31:0] instruction_memory_read_data_i,
    input logic [31:0] pc_if_i,
    input logic flush_if_id_i,
    input logic stall_if_id_i,

    output logic valid_id_o,
    output logic [31:0] instruction_id_o,
    output logic [31:0] pc_id_o

);

  assign instruction_id_o = instruction_memory_read_data_i;
  always_ff @(posedge clk) begin
    if (rst) begin
      pc_id_o    <= '0;
      valid_id_o <= 1'b0;
    end else if (flush_if_id_i) begin
      valid_id_o <= 1'b0;
    end else if (!stall_if_id_i) begin
      pc_id_o    <= pc_if_i;
      valid_id_o <= 1'b1;
    end
  end
endmodule
