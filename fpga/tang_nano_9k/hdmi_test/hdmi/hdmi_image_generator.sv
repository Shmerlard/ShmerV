module hdmi_image_generator #(
    parameter PIXEL_INIT_FILE = "images/shmerv_pixels.hex",
    parameter HUE_PALETTE_PREFIX = "images/shmerv"
) (
    input logic clk,
    input logic rst,
    input logic [9:0] x,
    input logic [9:0] y,
    input logic active_video,
    input logic hsync,
    input logic vsync,
    input logic [7:0] hue,
    output logic [7:0] red,
    output logic [7:0] green,
    output logic [7:0] blue,
    output logic active_video_o,
    output logic hsync_o,
    output logic vsync_o
);
  // 320x240 indices, four bits each: 37.5 KiB, enlarged 2x in both axes.
  logic [3:0] image_rom [0:76799];
  // Separate synchronous 8-bit banks encourage compact block-RAM packing.
  logic [7:0] hue_red_rom [0:4095];
  logic [7:0] hue_green_rom [0:4095];
  logic [7:0] hue_blue_rom [0:4095];
  logic [3:0] pixel_index;
  logic [16:0] address;
  logic [23:0] rgb;
  logic [7:0] hue_d;
  logic active_d, hsync_d, vsync_d;
  wire [11:0] palette_address = {hue_d, pixel_index};

  initial begin
    $readmemh(PIXEL_INIT_FILE, image_rom);
    $readmemh({HUE_PALETTE_PREFIX, "_hue_red.hex"}, hue_red_rom);
    $readmemh({HUE_PALETTE_PREFIX, "_hue_green.hex"}, hue_green_rom);
    $readmemh({HUE_PALETTE_PREFIX, "_hue_blue.hex"}, hue_blue_rom);
  end

  // y/2 * 320 + x/2. Dropping bit zero duplicates each pixel/row.
  assign address = 17'(y[9:1]) * 17'd320 + 17'(x[9:1]);

  // Unreset synchronous ROM output permits block RAM inference.
  always_ff @(posedge clk) begin
    if (active_video && !rst) pixel_index <= image_rom[address];
    rgb <= {hue_red_rom[palette_address], hue_green_rom[palette_address],
            hue_blue_rom[palette_address]};
  end

  // Index ROM and palette ROM each add one cycle; align every control signal.
  always_ff @(posedge clk) begin
    if (rst) begin
      active_video_o <= 1'b0;
      hsync_o <= 1'b1;
      vsync_o <= 1'b1;
      hue_d <= 8'd0;
      active_d <= 1'b0;
      hsync_d <= 1'b1;
      vsync_d <= 1'b1;
    end else begin
      active_d <= active_video;
      hsync_d <= hsync;
      vsync_d <= vsync;
      hue_d <= hue;
      active_video_o <= active_d;
      hsync_o <= hsync_d;
      vsync_o <= vsync_d;
    end
  end

  assign {red, green, blue} = active_video_o ? rgb : 24'd0;
endmodule
