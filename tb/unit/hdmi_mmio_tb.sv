module hdmi_mmio_tb #(
    parameter bit ENABLE_HDMI = 1'b1
);
  import csr_types::*;
  bit clk = 0;
  logic rst = 1;
  wire hdmi_pixel_clk_i = clk;
  wire hdmi_pixel_rst_i = rst;
  logic hdmi_enable_i = 1;
  logic [9:0] hdmi_symbols_o[0:2];
  logic [31:0] address_i = 0, write_data_i = 0, read_data_o;
  logic [3:0] write_byte_enable_i = 0;
  logic read_enable_i = 0, write_enable_i = 0;
  logic [7:0] gpio0_pin_i = 0, gpio1_pin_i = 0, gpio2_pin_i = 0;
  logic [7:0] gpio0_pin_o, gpio1_pin_o, gpio2_pin_o;
  logic [7:0] gpio0_pin_oe_o, gpio1_pin_oe_o, gpio2_pin_oe_o;
  logic irq_o;
  irq_address_t irq_address_o;
  // Literal bus addresses intentionally check the public map independently.
  localparam logic [31:0] CURSOR_POS = 32'h10002004;
  localparam logic [31:0] CURSOR_DATA = 32'h1000200C;
  localparam logic [31:0] CMEM_BASE = 32'h10006000;

  peripheral_manager #(
      .ENABLE_HDMI(ENABLE_HDMI),
      .HDMI_CHAR_INIT_FILE("rtl/peripherals/hdmi/examples/char_demo.hex")
  ) dut (
      .*
  );
  always #5 clk = ~clk;

  task automatic write_bus(input logic [31:0] address, input logic [31:0] value,
                           input logic [3:0] mask = 4'b0011);
    address_i = address;
    write_data_i = value;
    write_byte_enable_i = mask;
    write_enable_i = 1;
    @(negedge clk);
    write_enable_i = 0;
  endtask

  task automatic read_bus(input logic [31:0] address, input logic [31:0] expected);
    address_i = address;
    read_enable_i = 1;
    @(negedge clk);
    assert (read_data_o == expected)
    else $fatal(1, "Read %h: got %h expected %h", address, read_data_o, expected);
    read_enable_i = 0;
  endtask

  if (ENABLE_HDMI) begin : enabled
    // Also observe storage to detect unintended write side effects.
    task automatic check_cell(input int index, input logic [15:0] expected);
      assert (dut.generate_hdmi.hdmi.char_memory.char_memory[index] == expected)
      else
        $fatal(
            1,
            "Cell %0d: got %h expected %h",
            index,
            dut.generate_hdmi.hdmi.char_memory.char_memory[index],
            expected
        );
    endtask
    task automatic check_cursor(input int expected);
      assert (int'(dut.generate_hdmi.hdmi.cursor_index) == expected)
      else $fatal(1, "Cursor: got %0d expected %0d", dut.generate_hdmi.hdmi.cursor_index, expected);
    endtask

    initial begin
      repeat (2) @(negedge clk);
      rst = 0;
      read_bus(32'h10002000, 32'h1C);  // Reset: display/cursor/blink, no flag/IRQ.
      write_bus(32'h10002000, 32'h10);
      read_bus(32'h10002000, 32'h10);
      assert (!dut.generate_hdmi.hdmi.cursor_enable && !dut.generate_hdmi.hdmi.cursor_blink)
      else $fatal(1, "CTRL cursor settings not forwarded");
      write_bus(32'h10002000, 32'h1C);
      write_bus(32'h10002000, 32'h00);
      repeat (2) @(negedge clk);  // Display control crosses two pixel registers.
      assert (dut.generate_hdmi.hdmi.rgb == 0 && !dut.generate_hdmi.hdmi.renderer_read)
      else $fatal(1, "Display disable did not blank output and stop reads");
      begin
        logic [9:0] previous_x;
        previous_x = dut.generate_hdmi.hdmi.scan_pixel_x;
        @(negedge clk);
        assert (dut.generate_hdmi.hdmi.scan_pixel_x != previous_x)
        else $fatal(1, "Display disable stopped video timing");
      end
      write_bus(32'h10002000, 32'h1C);
      while (dut.generate_hdmi.hdmi.scan_pixel_x[2:0] != 0) @(negedge clk);
      assert (dut.generate_hdmi.hdmi.renderer_read)
      else $fatal(1, "Display enable did not resume reads");
      read_bus(CURSOR_POS, 0);
      read_bus(32'h10002008, 0);  // Fixed start row.
      read_bus(CURSOR_DATA, 0);  // Write-only, no cursor movement.
      read_bus(CMEM_BASE, 32'h010F);
      read_bus(CMEM_BASE + 255 * 4, 32'h000F);
      check_cell(0, 16'h010F);
      check_cell(255, 16'h000F);
      check_cell(256, 16'h01F0);
      check_cell(511, 16'h00F0);

      write_bus(CMEM_BASE, 32'hDEAD4110);
      write_bus(CMEM_BASE + 79 * 4, 32'h4220);
      write_bus(CMEM_BASE + 80 * 4, 32'h4330);
      write_bus(CMEM_BASE + 2399 * 4, 32'h4440, 4'b1111);
      write_bus(CMEM_BASE + 2560 * 4, 32'h4550);  // First row beyond old five-bit Y.
      write_bus(CMEM_BASE + 4079 * 4, 32'h4660);
      check_cell(0, 16'h4110);
      check_cell(79, 16'h4220);
      check_cell(80, 16'h4330);
      check_cell(2399, 16'h4440);
      check_cell(2560, 16'h4550);
      check_cell(4079, 16'h4660);
      check_cursor(0);
      read_bus(CMEM_BASE, 32'h4110);
      read_bus(CMEM_BASE + 4079 * 4, 32'h4660);
      read_bus(CURSOR_POS, 0);
      read_bus(CMEM_BASE + 2560 * 4, 32'h4550);
      read_bus(32'h10002008, 0);
      read_bus(CMEM_BASE + 4080 * 4, 0);
      read_bus(32'h10002100, 0);
      read_bus(32'h10002010, 0);
      read_bus(CMEM_BASE + 2, 0);
      read_bus(32'h1000A000, 0);
      read_bus(CMEM_BASE + 80 * 4, 32'h4330);
      // The response belongs to the sampled read, not the live address.
      address_i = CURSOR_POS;
      @(negedge clk);
      assert (read_data_o == 32'h4330)
      else $fatal(1, "Read response not held");

      // Rejected widths, unaligned addresses, reserved slots, and other devices.
      write_bus(CMEM_BASE, 32'hFFFF, 4'b0001);
      write_bus(CMEM_BASE, 32'hFFFF, 4'b0010);
      write_bus(CMEM_BASE, 32'hFFFF, 4'b1100);
      write_bus(CMEM_BASE + 1, 32'hFFFF);
      write_bus(CMEM_BASE + 2, 32'hFFFF);
      write_bus(32'h10002100, 32'hFFFF);
      write_bus(32'h10002010, 32'hFFFF);
      write_bus(CMEM_BASE + 4080 * 4, 32'hFFFF);
      write_bus(32'h1000A000, 32'hFFFF);
      write_bus(32'h10000008, 32'hFF, 4'b0001);
      check_cell(0, 16'h4110);
      check_cell(4079, 16'h4660);
      check_cursor(0);

      // Writes through the cursor use its OLD index, then advance exactly once.
      write_bus(CURSOR_POS, 32'd79);
      check_cursor(79);
      read_bus(CURSOR_POS, 79);
      write_bus(CURSOR_POS, 32'd4080);
      check_cursor(79);
      write_bus(CURSOR_POS, 32'hFFFF);
      check_cursor(79);
      write_bus(CURSOR_POS, 32'h104F);  // High bits must not silently truncate to 79.
      check_cursor(79);
      check_cell(79, 16'h4220);  // Setting the cursor does not write RAM.
      write_bus(CURSOR_DATA, 32'hABCD41F0);
      check_cell(79, 16'h41F0);
      check_cursor(80);  // Automatic row crossing.
      read_bus(CURSOR_POS, 80);
      read_bus(CMEM_BASE + 79 * 4, 32'h41F0);
      write_bus(CURSOR_DATA, 32'h42E0);
      check_cell(80, 16'h42E0);
      check_cursor(81);
      read_bus(CURSOR_POS, 81);
      read_bus(CURSOR_DATA, 81);  // Unsupported read retains prior register response.
      read_bus(CURSOR_POS, 81);
      address_i = CURSOR_DATA;
      repeat (3) @(negedge clk);  // CURSOR_DATA selected without a write.
      check_cursor(81);
      read_enable_i = 1;
      @(negedge clk);
      read_enable_i = 0;
      check_cursor(81);
      write_bus(CURSOR_DATA, 32'hFFFF, 4'b0001);
      write_bus(CURSOR_POS, 32'd0, 4'b0001);
      check_cursor(81);
      check_cell(80, 16'h42E0);

      write_bus(CMEM_BASE, 32'h43D0);  // Direct writes preserve hardware position.
      check_cursor(81);
      write_bus(CURSOR_POS, 32'd2560);
      write_bus(CURSOR_DATA, 32'h44C0);
      check_cell(2560, 16'h44C0);
      check_cursor(2561);
      write_bus(CURSOR_POS, 32'd4079);
      write_bus(CURSOR_DATA, 32'h45B0);
      check_cell(4079, 16'h45B0);
      check_cursor(0);
      // Overflow becomes sticky on the cycle following the last-cell write.
      @(negedge clk);
      read_bus(32'h10002000, 32'h1E);
      assert (!dut.generate_hdmi.hdmi.irq_o)
      else $fatal(1, "Masked IRQ asserted");
      write_bus(32'h10002000, 32'h1F);
      assert (dut.generate_hdmi.hdmi.irq_o)
      else $fatal(1, "Pending IRQ not exported");
      assert (irq_o && irq_address_o == IRQ_ADDRESS_HDMI_OVERFLOW)
      else $fatal(1, "HDMI IRQ not routed to manager");
      write_bus(32'h10000010, 32'd1, 4'b0001);  // GPIO A interrupt enable.
      write_bus(32'h10000018, 32'd1, 4'b0001);  // GPIO A software pending.
      assert (irq_o && irq_address_o == IRQ_ADDRESS_GPIO_A)
      else $fatal(1, "HDMI incorrectly preempted GPIO A");
      write_bus(32'h1000001C, 32'd1, 4'b0001);
      assert (irq_o && irq_address_o == IRQ_ADDRESS_HDMI_OVERFLOW)
      else $fatal(1, "Pending HDMI IRQ lost after higher-priority source");
      write_bus(32'h10000010, 32'd0, 4'b0001);
      write_bus(32'h10002000, 32'h1D);  // Current CTRL semantics: write flag zero to clear.
      assert (!dut.generate_hdmi.hdmi.irq_o)
      else $fatal(1, "IRQ did not clear");
      assert (!irq_o)
      else $fatal(1, "Manager IRQ remained asserted");

      rst = 1;
      @(negedge clk);
      rst = 0;
      check_cursor(0);
      check_cell(0, 16'h43D0);  // Reset preserves RAM.
      read_bus(CURSOR_POS, 0);
      read_bus(CMEM_BASE, 32'h43D0);
      check_cell(4079, 16'h45B0);
      write_bus(CURSOR_DATA, 32'h46A0);
      check_cell(0, 16'h46A0);
      check_cursor(1);
      $display("PASS: HDMI MMIO direct/cursor writes, masks, position, full RAM, reset");
      $finish;
    end
  end else begin : disabled
    initial begin
      repeat (2) @(negedge clk);
      rst = 0;
      write_bus(CMEM_BASE, 32'h41F0);
      write_bus(CURSOR_POS, 32'd80);
      write_bus(CURSOR_DATA, 32'h42F0);
      address_i = CMEM_BASE;
      read_enable_i = 1;
      @(negedge clk);
      assert (read_data_o == 0)
      else $fatal(1, "Disabled HDMI read was nonzero");
      foreach (hdmi_symbols_o[channel])
      assert (hdmi_symbols_o[channel] == 0)
      else $fatal(1, "Disabled HDMI produced a symbol");
      $display("PASS: disabled HDMI MMIO and output");
      $finish;
    end
  end
endmodule
