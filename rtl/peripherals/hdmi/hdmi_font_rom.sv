import hdmi_types::*;

module hdmi_font_rom #(
    parameter string FONT_INIT_FILE = "rtl/peripherals/hdmi/fonts/NICER40C.hex"
) (
    input logic clk,
    input logic read_enable_i,
    input logic [7:0] char_code_i,
    input logic [3:0] row_i,
    output logic [7:0] row_bitmap_o,
    input logic [3:0] color_index_i,
    output logic [23:0] color_rgb_o
);
  logic [7:0] font_memory[0:4095]  /* synthesis syn_ramstyle = "block_ram" */;

  initial begin
    $readmemh(FONT_INIT_FILE, font_memory);
  end

  always_ff @(posedge clk) begin
    if (read_enable_i) row_bitmap_o <= font_memory[{char_code_i, row_i}];
  end

  // Fixed VGA text palette. RGB byte order: red, green, blue.
  // Palette lookup is combinational; it adds no clock-cycle latency.
  always_comb begin
    case (hdmi_color_t'(color_index_i))
      HDMI_COLOR_BLACK: color_rgb_o = 24'h000000;  // Black
      HDMI_COLOR_BLUE: color_rgb_o = 24'h0000AA;  // Blue
      HDMI_COLOR_GREEN: color_rgb_o = 24'h00AA00;  // Green
      HDMI_COLOR_CYAN: color_rgb_o = 24'h00AAAA;  // Cyan
      HDMI_COLOR_RED: color_rgb_o = 24'hAA0000;  // Red
      HDMI_COLOR_MAGENTA: color_rgb_o = 24'hAA00AA;  // Magenta
      HDMI_COLOR_BROWN: color_rgb_o = 24'hAA5500;  // Brown
      HDMI_COLOR_LIGHT_GRAY: color_rgb_o = 24'hAAAAAA;  // Light gray
      HDMI_COLOR_DARK_GRAY: color_rgb_o = 24'h555555;  // Dark gray
      HDMI_COLOR_LIGHT_BLUE: color_rgb_o = 24'h5555FF;  // Light blue
      HDMI_COLOR_LIGHT_GREEN: color_rgb_o = 24'h55FF55;  // Light green
      HDMI_COLOR_LIGHT_CYAN: color_rgb_o = 24'h55FFFF;  // Light cyan
      HDMI_COLOR_LIGHT_RED: color_rgb_o = 24'hFF5555;  // Light red
      HDMI_COLOR_LIGHT_MAGENTA: color_rgb_o = 24'hFF55FF;  // Light magenta
      HDMI_COLOR_YELLOW: color_rgb_o = 24'hFFFF55;  // Yellow
      HDMI_COLOR_WHITE: color_rgb_o = 24'hFFFFFF;  // White
      default: color_rgb_o = 24'h000000;
    endcase
  end
endmodule
