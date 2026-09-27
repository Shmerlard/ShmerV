timeunit 1ns / 1ps;

module gpio_module_tb;
  localparam int WIDTH = 8;
  localparam logic [WIDTH-1:0] ALT_MASK = 8'b0000_0011;

  logic clk = 1'b0;
  logic rst;

  logic [WIDTH-1:0] pin_i;
  logic [WIDTH-1:0] pin_o;
  logic [WIDTH-1:0] pin_oe_o;

  logic [WIDTH-1:0] alt_in_o;
  logic [WIDTH-1:0] alt_out_i;
  logic [WIDTH-1:0] alt_oe_i;

  logic [7:0] mmio_write_data_i;
  logic [7:0] mmio_read_data_o;
  logic [4:0] register_address_i;
  logic mmio_write_enable_i;
  logic mmio_read_enable_i;
  logic irq_o;

  gpio #(
      .WIDTH(WIDTH),
      .ALT_MASK(ALT_MASK),
      .IRQ_MASK('0)
  ) dut (.*);

  always #5ns clk = ~clk;

  task automatic write_register(input logic [4:0] address, input logic [7:0] data);
    register_address_i = address;
    mmio_write_data_i = data;
    mmio_write_enable_i = 1'b1;
    @(posedge clk);
    #1ns;
    mmio_write_enable_i = 1'b0;
  endtask

  task automatic read_register(input logic [4:0] address, output logic [7:0] data);
    register_address_i = address;
    mmio_read_enable_i = 1'b1;
    @(posedge clk);
    #1ns;
    data = mmio_read_data_o;
    mmio_read_enable_i = 1'b0;
  endtask

  logic [7:0] read_data;

  initial begin
    $dumpfile("build/tests/gpio/waveform.fst");
    $dumpvars(0, gpio_module_tb);

    rst = 1'b1;
    pin_i = '0;
    alt_out_i = '0;
    alt_oe_i = '0;
    mmio_write_data_i = '0;
    register_address_i = '0;
    mmio_write_enable_i = 1'b0;
    mmio_read_enable_i = 1'b0;

    @(posedge clk);
    #1ns;
    rst = 1'b0;

    assert (pin_o == '0)
    else $fatal(1, "reset pin output was %b", pin_o);
    assert (pin_oe_o == '0)
    else $fatal(1, "reset output enable was %b", pin_oe_o);

    // In GPIO mode, OUT supplies the pin value and DIR supplies output-enable.
    write_register(5'h01, 8'b1010_1010);
    write_register(5'h02, 8'b1100_1100);
    assert (pin_o == 8'b1010_1010)
    else $fatal(1, "GPIO output was %b", pin_o);
    assert (pin_oe_o == 8'b1100_1100)
    else $fatal(1, "GPIO output-enable was %b", pin_oe_o);

    // Only ALT_MASK pins 1:0 may select the alternate peripheral.
    alt_out_i = 8'b0101_0101;
    alt_oe_i = 8'b0000_0011;
    write_register(5'h03, 8'hFF);
    assert (pin_o == 8'b1010_1001)
    else $fatal(1, "selected alternate output was %b", pin_o);
    assert (pin_oe_o == 8'b1100_1111)
    else $fatal(1, "selected alternate output-enable was %b", pin_oe_o);

    // A physical input reaches both IN and the alternate peripheral after two clocks.
    pin_i = 8'b0110_1001;
    repeat (2) @(posedge clk);
    #1ns;
    assert (alt_in_o == 8'b0110_1001)
    else $fatal(1, "synchronized alternate input was %b", alt_in_o);

    read_register(5'h00, read_data);
    assert (read_data == 8'b0110_1001)
    else $fatal(1, "IN register read returned %b", read_data);

    assert (!irq_o)
    else $fatal(1, "IRQ asserted with IRQ_MASK disabled");

    $display("gpio tests passed");
    $finish;
  end
endmodule
