import hdmi_types::*;

module hdmi_module #(
    parameter string FONT_FILE = "rtl/peripherals/hdmi/fonts/NICER40C.hex",
    parameter string CHAR_INIT_FILE = "",
    parameter logic [2:0] WINDOW_OFFSET = 3'd5,
    parameter int unsigned CPU_CLOCK_HZ = 843_750
) (
    input logic cpu_clk,
    input logic pixel_clk,
    input logic rst,
    // Pixel-domain reset and enable, independent of the CPU interface.
    input logic pixel_rst,
    input logic enable_i,

    input  logic          [15:0] hdmi_write_data_i,
    input  hdmi_address_t        hdmi_address_i,
    input  logic                 hdmi_write_data_enable_i,
    input  logic                 hdmi_read_data_enable_i,
    output logic          [15:0] hdmi_read_data_o,

    // TODO: remove the pixel_address signals with regular address and data
    input  char_pos_t  pixel_address_cpu_i,
    input  char_cell_t pixel_write_data_cpu_i,
    output char_cell_t pixel_read_data_cpu_o,
    input  logic       pixel_write_enable_cpu_i,
    input  logic       pixel_read_enable_cpu_i,

    // Parallel TMDS symbols for the FPGA serializer: 0=blue, 1=green, 2=red.
    output logic [9:0] tmds_symbols_o[0:2]
);
  hdmi_ctrl_reg_t ctrl_reg;
  logic [4:0] start_row_reg;
  char_pos_t cursor_pos;
  logic [15:0] write_char;

  char_pos_t generator_address;
  char_cell_t generator_data;
  logic generator_read;
  logic [9:0] x, y;
  logic active_video;
  pixel_rgb_t rgb;


  always_ff @(posedge cpu_clk) begin
    if (rst) begin
      ctrl_reg <= 0;
      start_row_reg <= 0;
      cursor_pos <= 0;
      write_char <= 0;
    end else begin
      if (hdmi_write_data_enable_i) begin
        case (hdmi_address_i)
          HDMI_ADDRESS_CTRL: begin
            ctrl_reg <= hdmi_ctrl_reg_t'(hdmi_write_data_i);
          end

          default: ;
        endcase
      end
    end
  end



  // ----------------- INSTANTIATIONS -----------------------
  hdmi_char_memory #(
      .INIT_FILE(CHAR_INIT_FILE)
  ) char_memory (
      .cpu_clk(cpu_clk),
      .pixel_clk(pixel_clk),
      .pixel_address_cpu_i(pixel_address_cpu_i),
      .pixel_write_data_cpu_i(pixel_write_data_cpu_i),
      .pixel_read_data_cpu_o(pixel_read_data_cpu_o),
      .pixel_write_enable_cpu_i(pixel_write_enable_cpu_i),
      .pixel_read_enable_cpu_i(pixel_read_enable_cpu_i),
      .pixel_address_generator_i(generator_address),
      .pixel_read_data_generator_o(generator_data),
      .pixel_read_enable_generator_i(generator_read)
  );

  hdmi_text_renderer #(
      .FONT_FILE(FONT_FILE),
      .WINDOW_OFFSET(WINDOW_OFFSET),
      .CPU_CLOCK_HZ(CPU_CLOCK_HZ)
  ) renderer (
      .cpu_clk(cpu_clk),
      .pixel_clk(pixel_clk),
      .rst(rst),
      .pixel_rst(pixel_rst),
      .enable_i(enable_i),
      // Temporary cursor bring-up: blink at the first cell.
      .cursor_enable(1'b1),
      .cursor_blink(1'b1),
      .cursor_pos(char_pos_t'('0)),
      .x(x),
      .y(y),
      .active_video(active_video),
      .char_address_o(generator_address),
      .char_data_i(generator_data),
      .char_read_o(generator_read),
      .rgb_o(rgb)
  );

  hdmi_video_output #(
      .WINDOW_OFFSET(WINDOW_OFFSET)
  ) video_output (
      .pixel_clk(pixel_clk),
      .pixel_rst(pixel_rst),
      .rgb_i(rgb),
      .x(x),
      .y(y),
      .active_video(active_video),
      .tmds_symbols_o(tmds_symbols_o)
  );
endmodule
