timeunit 1ns / 1ps;

module peripheral_manager_tb;
  localparam logic [31:0] GpioBaseAddress = 32'h1000_0000;
  localparam logic [31:0] Gpio1BaseAddress = GpioBaseAddress + 32'h100;

  logic clk = 1'b0;
  logic rst;
  logic [31:0] address_i;
  logic [31:0] write_data_i;
  logic [3:0] write_byte_enable_i;
  logic read_enable_i;
  logic write_enable_i;
  logic [31:0] read_data_o;
  logic [7:0] gpio0_pin_i;
  logic [7:0] gpio0_pin_o;
  logic [7:0] gpio0_pin_oe_o;
  logic [7:0] gpio1_pin_i;
  logic [7:0] gpio1_pin_o;
  logic [7:0] gpio1_pin_oe_o;
  logic irq_o;

  peripheral_manager #(.GPIO_BASE_ADDRESS(GpioBaseAddress)) dut (.*);

  always #5ns clk = ~clk;

  task automatic write_register(input logic [31:0] gpio_base_address,
                                input logic [4:0] register_address, input logic [31:0] data,
                                input logic [3:0] byte_enable);
    address_i = gpio_base_address + {25'b0, register_address, 2'b0};
    write_data_i = data;
    write_byte_enable_i = byte_enable;
    write_enable_i = 1'b1;
    @(posedge clk);
    #1ns;
    write_enable_i = 1'b0;
  endtask

  initial begin
    $dumpfile("build/tests/peripheral_manager/waveform.fst");
    $dumpvars(0, peripheral_manager_tb);

    rst = 1'b1;
    address_i = '0;
    write_data_i = '0;
    write_byte_enable_i = '0;
    read_enable_i = 1'b0;
    write_enable_i = 1'b0;
    gpio0_pin_i = '0;
    gpio1_pin_i = '0;

    @(posedge clk);
    #1ns;
    rst = 1'b0;

    // Both banks reset to inputs; software controls both direction registers.
    assert (gpio0_pin_oe_o == 8'h00);
    assert (gpio1_pin_oe_o == 8'h00);

    // Configure GPIO0 as outputs and drive a visible pattern.
    write_register(GpioBaseAddress, 5'h02, 32'h0000_00FF, 4'b0001);
    write_register(GpioBaseAddress, 5'h01, 32'h0000_00A5, 4'b0001);
    assert (gpio0_pin_oe_o == 8'hFF);
    assert (gpio0_pin_o == 8'hA5);
    assert (gpio1_pin_oe_o == 8'h00);

    // Upper byte lanes do not modify an eight-bit GPIO register.
    write_register(GpioBaseAddress, 5'h01, 32'h0000_0000, 4'b0010);
    assert (gpio0_pin_o == 8'hA5);

    // GPIO reads are returned in the low byte of the MMIO response.
    address_i = GpioBaseAddress + 32'h4;
    read_enable_i = 1'b1;
    @(posedge clk);
    #1ns;
    read_enable_i = 1'b0;
    assert (read_data_o == 32'h0000_00A5);

    // GPIO1 can remain an input and return its synchronized pins.
    gpio1_pin_i = 8'h3C;
    repeat (2) @(posedge clk);
    #1ns;
    address_i = Gpio1BaseAddress;
    read_enable_i = 1'b1;
    @(posedge clk);
    #1ns;
    read_enable_i = 1'b0;
    assert (read_data_o == 32'h0000_003C);

    // GPIO1 direction is also writable rather than fixed as input.
    write_register(Gpio1BaseAddress, 5'h02, 32'h0000_000F, 4'b0001);
    assert (gpio1_pin_oe_o == 8'h0F);

    // A read outside both GPIO slots returns zero.
    address_i = GpioBaseAddress + 32'h200;
    read_enable_i = 1'b1;
    @(posedge clk);
    #1ns;
    read_enable_i = 1'b0;
    assert (read_data_o == 32'b0);
    assert (!irq_o);

    $display("peripheral manager tests passed");
    $finish;
  end
endmodule
