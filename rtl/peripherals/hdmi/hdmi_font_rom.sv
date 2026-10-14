module hdmi_font_rom #(
    parameter string FONT_FILE = "rtl/peripherals/hdmi/fonts/NICER40C.hex"
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
    $readmemh(FONT_FILE, font_memory);
  end

  always_ff @(posedge clk) begin
    if (read_enable_i) row_bitmap_o <= font_memory[{char_code_i, row_i}];
  end

  // Fixed VGA text palette. RGB byte order: red, green, blue.
  // Palette lookup is combinational; it adds no clock-cycle latency.
  always_comb begin
    case (color_index_i)
      4'h0: color_rgb_o = 24'h000000;  // Black
      4'h1: color_rgb_o = 24'h0000AA;  // Blue
      4'h2: color_rgb_o = 24'h00AA00;  // Green
      4'h3: color_rgb_o = 24'h00AAAA;  // Cyan
      4'h4: color_rgb_o = 24'hAA0000;  // Red
      4'h5: color_rgb_o = 24'hAA00AA;  // Magenta
      4'h6: color_rgb_o = 24'hAA5500;  // Brown
      4'h7: color_rgb_o = 24'hAAAAAA;  // Light gray
      4'h8: color_rgb_o = 24'h555555;  // Dark gray
      4'h9: color_rgb_o = 24'h5555FF;  // Light blue
      4'hA: color_rgb_o = 24'h55FF55;  // Light green
      4'hB: color_rgb_o = 24'h55FFFF;  // Light cyan
      4'hC: color_rgb_o = 24'hFF5555;  // Light red
      4'hD: color_rgb_o = 24'hFF55FF;  // Light magenta
      4'hE: color_rgb_o = 24'hFFFF55;  // Yellow
      4'hF: color_rgb_o = 24'hFFFFFF;  // White
      default: color_rgb_o = 24'h000000;
    endcase
  end
endmodule
