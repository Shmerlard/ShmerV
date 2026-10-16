import hdmi_types::*;
module hdmi_char_memory #(
    parameter int TEXT_COLUMNS = 80,
    parameter int TEXT_BUFFER_ROWS = 51,
    parameter string TEXT_INIT_FILE = ""
) (
    input logic cpu_clk,
    input logic pixel_clk,

    // Controller Interface
    input logic [11:0] char_index_controller_i,
    input char_cell_t char_write_data_controller_i,
    output char_cell_t char_read_data_controller_o,
    input logic char_write_enable_controller_i,
    input logic char_read_enable_controller_i,

    // Renderer Interface
    input logic [11:0] char_index_renderer_i,
    output char_cell_t char_read_data_renderer_o,
    input logic char_read_enable_renderer_i

);

  logic [15:0] char_memory[0:TEXT_COLUMNS * TEXT_BUFFER_ROWS - 1] /* synthesis syn_ramstyle = "block_ram" */;

  //------------------------

  initial begin
    if (TEXT_INIT_FILE != "") $readmemh(TEXT_INIT_FILE, char_memory);
  end

  always_ff @(posedge cpu_clk) begin
    if (char_write_enable_controller_i) begin
      char_memory[char_index_controller_i] <= char_write_data_controller_i;
    end
    if (char_read_enable_controller_i) begin
      char_read_data_controller_o <= char_cell_t'(char_memory[char_index_controller_i]);
    end
  end

  always_ff @(posedge pixel_clk) begin
    if (char_read_enable_renderer_i) begin
      char_read_data_renderer_o <= char_cell_t'(char_memory[char_index_renderer_i]);
    end
  end

endmodule
