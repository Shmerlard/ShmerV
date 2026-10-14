import hdmi_types::*;
module hdmi_char_memory #(
    parameter int CHAR_WIDTH = 8,
    parameter int CHAR_HEIGHT = 16,
    parameter int HORIZONTAL_CHAR = 80,
    parameter int VERTICAL_CHAR = 30,
    parameter string INIT_FILE = ""
) (
    input logic cpu_clk,
    input logic pixel_clk,
    input logic rst,

    input char_pos_t pixel_address_cpu_i,
    input char_cell_t pixel_write_data_cpu_i,
    output char_cell_t pixel_read_data_cpu_o,
    input logic pixel_write_enable_cpu_i,
    input logic pixel_read_enable_cpu_i,

    input char_pos_t pixel_address_generator_i,
    output char_cell_t pixel_read_data_generator_o,
    input logic pixel_read_enable_generator_i

);

  logic [15:0]
      char_memory[0:HORIZONTAL_CHAR * VERTICAL_CHAR - 1]
/* synthesis syn_ramstyle = "block_ram" */;

  logic [11:0] cpu_address;
  // Configuration-time initialization only; reset does not reload the RAM.
  initial begin
    if (INIT_FILE != "") $readmemh(INIT_FILE, char_memory);
  end
  logic [11:0] generator_address;

  logic [6:0] x_pos_cpu;
  logic [4:0] y_pos_cpu;
  logic [6:0] x_pos_generator;
  logic [4:0] y_pos_generator;

  always_comb begin
    x_pos_cpu = pixel_address_cpu_i.x_pos;
    y_pos_cpu = pixel_address_cpu_i.y_pos;
    x_pos_generator = pixel_address_generator_i.x_pos;
    y_pos_generator = pixel_address_generator_i.y_pos;
  end

  assign cpu_address = 12'(32'(x_pos_cpu) + HORIZONTAL_CHAR * 32'(y_pos_cpu));
  assign generator_address = 12'(32'(x_pos_generator) + HORIZONTAL_CHAR * 32'(y_pos_generator));

  always_ff @(posedge cpu_clk) begin
    if (pixel_write_enable_cpu_i) begin
      char_memory[cpu_address] <= pixel_write_data_cpu_i;
    end
    if (pixel_read_enable_cpu_i) begin
      pixel_read_data_cpu_o <= char_cell_t'(char_memory[cpu_address]);
    end
  end

  always_ff @(posedge pixel_clk) begin
    if (pixel_read_enable_generator_i) begin
      pixel_read_data_generator_o <= char_cell_t'(char_memory[generator_address]);
    end
  end
endmodule
