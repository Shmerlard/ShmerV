module hdmi_mmio_tb #(
    parameter bit ENABLE_HDMI = 1'b1
);
  import csr_types::*;
  bit clk = 0;
  logic rst = 1;
  wire hdmi_pixel_clk_i = clk;
  wire hdmi_pixel_rst_i = rst;
  logic hdmi_enable_i = 0;
  logic [9:0] hdmi_symbols_o[0:2];
  logic [31:0] address_i = 0, write_data_i = 0, read_data_o;
  logic [3:0] write_byte_enable_i = 0;
  logic read_enable_i = 0, write_enable_i = 0;
  logic [7:0] gpio0_pin_i = 0, gpio1_pin_i = 0, gpio2_pin_i = 0;
  logic [7:0] gpio0_pin_o, gpio1_pin_o, gpio2_pin_o;
  logic [7:0] gpio0_pin_oe_o, gpio1_pin_oe_o, gpio2_pin_oe_o;
  logic irq_o;
  irq_address_t irq_address_o;
  peripheral_manager #(
      .ENABLE_HDMI(ENABLE_HDMI),
      .HDMI_CHAR_INIT_FILE("rtl/peripherals/hdmi/examples/char_demo.hex")
  ) dut (
      .*
  );
  always #5 clk = ~clk;
  task automatic write_cell(input int index, input logic [31:0] value,
                            input logic [3:0] mask = 4'b0011);
    address_i = 32'h10002000 + 32'(index * 4);
    write_data_i = value;
    write_byte_enable_i = mask;
    write_enable_i = 1;
    @(negedge clk);
    write_enable_i = 0;
  endtask
  task automatic read_cell(input int index, input logic [31:0] expected);
    address_i = 32'h10002000 + 32'(index * 4);
    read_enable_i = 1;
    @(negedge clk);
    assert (read_data_o == expected)
    else $fatal(1, "Cell %0d: got %h expected %h", index, read_data_o, expected);
    read_enable_i = 0;
  endtask
  initial begin
    repeat (2) @(negedge clk);
    rst = 0;
    if (!ENABLE_HDMI) begin
      read_cell(0, 0);
      write_cell(0, 32'h4110);
      read_cell(0, 0);
      read_cell(2399, 0);
      foreach (hdmi_symbols_o[channel])
      assert (hdmi_symbols_o[channel] == 0)
      else $fatal(1, "Disabled HDMI produced a symbol");
      $display("PASS: Disabled HDMI has no character MMIO or output symbols");
      $finish;
    end
    read_cell(0, 32'h010F);
    read_cell(255, 32'h000F);
    read_cell(256, 32'h01F0);
    read_cell(511, 32'h00F0);
    write_cell(0, 32'h4110);
    write_cell(79, 32'h4220);
    write_cell(80, 32'h4330);
    write_cell(2399, 32'h4440, 4'b1111);
    read_cell(0, 32'h4110);
    rst = 1;
    @(negedge clk);
    rst = 0;
    read_cell(0, 32'h4110);  // Reset must not reload the initial image.
    read_cell(79, 32'h4220);
    read_cell(80, 32'h4330);
    read_cell(2399, 32'h4440);
    write_cell(0, 32'hFFFF, 4'b0001);
    read_cell(0, 32'h4110);
    read_cell(2400, 0);
    // Accesses to other peripherals must not overwrite character memory.
    address_i = 32'h10000008;
    write_data_i = 32'hFF;
    write_byte_enable_i = 4'b0001;
    write_enable_i = 1;
    @(negedge clk);
    write_enable_i = 0;
    read_cell(0, 32'h4110);
    // The temporary CPU font window was removed; it is now unmapped.
    address_i = 32'h10006000;
    read_enable_i = 1;
    @(negedge clk);
    assert (read_data_o == 0)
    else $fatal(1, "Removed font window still mapped");
    read_enable_i = 0;
    write_enable_i = 1;
    write_data_i = 32'hFFFFFFFF;
    write_byte_enable_i = 4'b1111;
    @(negedge clk);
    write_enable_i = 0;
    read_cell(0, 32'h4110);
    $display("PASS: HDMI character MMIO, initialization, reset retention and removed font window");
    $finish;
  end
endmodule
