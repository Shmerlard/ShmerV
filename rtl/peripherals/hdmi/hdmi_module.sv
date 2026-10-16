import hdmi_types::*;

module hdmi_module #(
    parameter string FONT_INIT_FILE = "rtl/peripherals/hdmi/fonts/NICER40C.hex",
    parameter string TEXT_INIT_FILE = "",
    parameter logic [2:0] VIDEO_X_OFFSET_PIXELS = 3'd5,
    parameter int unsigned CPU_CLOCK_HZ = 843_750,
    parameter int TEXT_COLUMNS = 80,
    parameter int TEXT_BUFFER_ROWS = 51,
    parameter int unsigned BLINK_INTERVAL_MS = 500
) (
    input logic cpu_clk,
    input logic pixel_clk,
    input logic rst,
    // Pixel-domain reset and enable, independent of the CPU interface.
    input logic pixel_rst,

    input  hdmi_access_target_t        access_target_i,
    input  logic                [15:0] hdmi_write_data_i,
    input  logic                [14:0] hdmi_address_i,
    input  logic                       hdmi_write_enable_i,
    input  logic                       hdmi_read_enable_i,
    output logic                [15:0] hdmi_read_data_o,
    output logic irq_o,

    // Parallel TMDS symbols for the FPGA serializer: 0=blue, 1=green, 2=red.
    output logic [9:0] tmds_symbols_o[0:2]
);

  logic [11:0] renderer_index;
  char_cell_t renderer_data;
  logic renderer_read;
  logic [9:0] scan_pixel_x, scan_pixel_y;
  logic              active_video;
  pixel_rgb_t        rgb;

  logic              cmem_write_enable_controller;
  logic              cmem_read_enable_controller;
  logic       [11:0] cmem_cell_index_controller;
  logic       [15:0] cmem_write_data_controller;
  logic       [15:0] cmem_read_data_controller;

  logic       [11:0] cursor_index;
  logic              hdmi_enable;
  logic              cursor_enable;
  logic              cursor_blink;

  // -----------------------------

  // ----------------- INSTANTIATIONS -----------------------
  hdmi_controller #(
      .TEXT_COLUMNS(TEXT_COLUMNS),
      .TEXT_BUFFER_ROWS(TEXT_BUFFER_ROWS)
  ) hdmi_controller (
      .cpu_clk(cpu_clk),
      .rst    (rst),

      .access_target_i    (access_target_i),
      .hdmi_write_enable_i(hdmi_write_enable_i),
      .hdmi_read_enable_i (hdmi_read_enable_i),
      .hdmi_address_i     (hdmi_address_i),
      .hdmi_write_data_i  (hdmi_write_data_i),
      .hdmi_read_data_o   (hdmi_read_data_o),

      .cmem_write_enable_o(cmem_write_enable_controller),
      .cmem_read_enable_o (cmem_read_enable_controller),
      .cmem_cell_index_o  (cmem_cell_index_controller),
      .cmem_write_data_o  (cmem_write_data_controller),
      .cmem_read_data_i   (cmem_read_data_controller),

      .hdmi_enable_o(hdmi_enable),
      .cursor_enable_o(cursor_enable),
      .cursor_blink_o (cursor_blink),
      .cursor_index_o (cursor_index),
      .irq_o(irq_o)
  );


  hdmi_char_memory #(
      .TEXT_INIT_FILE(TEXT_INIT_FILE),
      .TEXT_COLUMNS(TEXT_COLUMNS),
      .TEXT_BUFFER_ROWS(TEXT_BUFFER_ROWS)
  ) char_memory (
      .cpu_clk  (cpu_clk),
      .pixel_clk(pixel_clk),

      .char_index_controller_i       (cmem_cell_index_controller),
      .char_write_data_controller_i  (cmem_write_data_controller),
      .char_read_data_controller_o   (cmem_read_data_controller),
      .char_write_enable_controller_i(cmem_write_enable_controller),
      .char_read_enable_controller_i (cmem_read_enable_controller),

      .char_index_renderer_i(renderer_index),
      .char_read_data_renderer_o(renderer_data),
      .char_read_enable_renderer_i(renderer_read)
  );

  hdmi_text_renderer #(
      .FONT_INIT_FILE(FONT_INIT_FILE),
      .VIDEO_X_OFFSET_PIXELS(VIDEO_X_OFFSET_PIXELS),
      .CPU_CLOCK_HZ(CPU_CLOCK_HZ),
      .TEXT_COLUMNS(TEXT_COLUMNS),
      .TEXT_BUFFER_ROWS(TEXT_BUFFER_ROWS),
      .BLINK_INTERVAL_MS(BLINK_INTERVAL_MS)
  ) renderer (
      .cpu_clk  (cpu_clk),
      .pixel_clk(pixel_clk),

      .rst(rst),
      .pixel_rst(pixel_rst),

      .enable_i(hdmi_enable),
      .cursor_enable_i(cursor_enable),
      .cursor_blink_i(cursor_blink),
      .cursor_index_i(cursor_index),
      .start_row_i(6'd0),

      .scan_pixel_x_i(scan_pixel_x),
      .scan_pixel_y_i(scan_pixel_y),
      .active_video_i(active_video),
      .char_index_o(renderer_index),
      .char_data_i(renderer_data),
      .char_read_o(renderer_read),
      .rgb_o(rgb)
  );

  hdmi_video_output #(
      .VIDEO_X_OFFSET_PIXELS(VIDEO_X_OFFSET_PIXELS)
  ) video_output (
      .pixel_clk(pixel_clk),
      .pixel_rst(pixel_rst),
      .rgb_i(rgb),
      .scan_pixel_x_o(scan_pixel_x),
      .scan_pixel_y_o(scan_pixel_y),
      .active_video_o(active_video),
      .tmds_symbols_o(tmds_symbols_o)
  );
endmodule
