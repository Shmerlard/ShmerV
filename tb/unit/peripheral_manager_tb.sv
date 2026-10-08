timeunit 1ns / 1ps;
import csr_types::*;

module peripheral_manager_tb;
  localparam logic [31:0] GpioBaseAddress = 32'h1000_0000;
  localparam logic [31:0] Gpio1BaseAddress = GpioBaseAddress + 32'h100;
  localparam logic [31:0] Gpio2BaseAddress = GpioBaseAddress + 32'h200;
  localparam logic [31:0] UartBaseAddress = GpioBaseAddress + 32'h300;

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
  logic [7:0] gpio2_pin_i;
  logic [7:0] gpio2_pin_o;
  logic [7:0] gpio2_pin_oe_o;
  logic irq_o;
  irq_address_t irq_address_o;

  peripheral_manager #(
      .GPIO_BASE_ADDRESS(GpioBaseAddress),
      .CLOCK_HZ(38_400)
  ) dut (
      .*
  );

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
    gpio2_pin_i = '0;

    @(posedge clk);
    #1ns;
    rst = 1'b0;

    // All banks reset to inputs; software controls their direction registers.
    assert (gpio0_pin_oe_o == 8'h00);
    assert (gpio1_pin_oe_o == 8'h00);
    assert (gpio2_pin_oe_o == 8'h00);

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

    // GPIO2.0 selects the UART transmitter as an alternate output.
    write_register(Gpio2BaseAddress, 5'h03, 32'h0000_0001, 4'b0001);
    assert (gpio2_pin_oe_o == 8'h01);
    assert (gpio2_pin_o[0] == 1'b1);
    write_register(UartBaseAddress, 5'h00, 32'h0000_0053, 4'b0001);
    write_register(UartBaseAddress, 5'h01, 32'h0000_0001, 4'b0001);
    repeat (2) @(posedge clk);
    #1ns;
    assert (gpio2_pin_o[0] == 1'b0);

    // A read outside all peripheral slots returns zero.
    address_i = GpioBaseAddress + 32'h400;
    read_enable_i = 1'b1;
    @(posedge clk);
    #1ns;
    read_enable_i = 1'b0;
    assert (read_data_o == 32'b0);
    assert (!irq_o);

    // Timer registers occupy 0x400 through 0x418, with 16-bit data.
    for (int index = 0; index < 7; index++) begin
      logic [31:0] expected;
      expected = (index == 6) ? 32'h6 : ((index == 2 || index == 4) ? 32'h2 : 32'h1234);
      write_register(GpioBaseAddress + 32'h400, 5'(index), expected, 4'b0011);
      address_i = GpioBaseAddress + 32'h400 + 32'(index * 4);
      read_enable_i = 1;
      @(posedge clk);
      #1ns;
      read_enable_i = 0;
      assert (read_data_o == expected)
      else $fatal(1, "Timer register %0d readback failed: %h", index, read_data_o);
    end
    // Byte writes and unmapped offsets must not alter the timer period.
    write_register(GpioBaseAddress + 32'h400, 0, 32'hffff, 4'b0001);
    write_register(GpioBaseAddress + 32'h400, 0, 32'hffff, 4'b0010);
    write_register(GpioBaseAddress + 32'h400, 5'h10, 32'hffff, 4'b1111);
    address_i = GpioBaseAddress + 32'h400;
    read_enable_i = 1;
    @(posedge clk);
    #1ns;
    assert (read_data_o == 32'h1234)
    else $fatal(1, "Timer invalid write modified period");
    address_i = GpioBaseAddress + 32'h440;
    @(posedge clk);
    #1ns;
    assert (read_data_o == 0)
    else $fatal(1, "Timer unmapped offset aliased a register");
    read_enable_i = 0;
    assert (!irq_o)
    else $fatal(1, "Timer IRQ unexpectedly routed to CPU");

    // GPIO2.7 = CCR1 output, GPIO2.6 = CCR2 output; GPIO2.0 remains UART.
    write_register(Gpio2BaseAddress, 5'h03, 32'hC1, 4'b0001);
    write_register(GpioBaseAddress + 32'h400, 5'h02, 32'h4, 4'b0011);
    write_register(GpioBaseAddress + 32'h400, 5'h04, 32'h0, 4'b0011);
    assert (gpio2_pin_oe_o == 8'hC1);
    assert (gpio2_pin_o[7:6] == 2'b10)
    else $fatal(1, "CCR1 output did not reach GPIO2.7");
    write_register(GpioBaseAddress + 32'h400, 5'h02, 32'h0, 4'b0011);
    write_register(GpioBaseAddress + 32'h400, 5'h04, 32'h4, 4'b0011);
    @(posedge clk);
    #1ns;
    assert (gpio2_pin_o[7:6] == 2'b01)
    else $fatal(1, "CCR2 output did not reach GPIO2.6");
    write_register(Gpio2BaseAddress, 5'h03, 32'h01, 4'b0001);
    assert (gpio2_pin_oe_o == 8'h01);

    // Set software flags while masked, then enable all banks. Priority is A > B > C.
    write_register(GpioBaseAddress, 5'h06, 32'h1, 4'b0001);
    write_register(Gpio1BaseAddress, 5'h06, 32'h1, 4'b0001);
    write_register(Gpio2BaseAddress, 5'h06, 32'h2, 4'b0001);
    assert (!irq_o);
    write_register(Gpio2BaseAddress, 5'h04, 32'h2, 4'b0001);
    assert (irq_o && irq_address_o == IRQ_ADDRESS_GPIO_C);
    write_register(Gpio1BaseAddress, 5'h04, 32'h1, 4'b0001);
    assert (irq_o && irq_address_o == IRQ_ADDRESS_GPIO_B);
    write_register(GpioBaseAddress, 5'h04, 32'h1, 4'b0001);
    assert (irq_o && irq_address_o == IRQ_ADDRESS_GPIO_A);
    write_register(GpioBaseAddress, 5'h07, 32'h1, 4'b0001);
    assert (irq_o && irq_address_o == IRQ_ADDRESS_GPIO_B);
    write_register(Gpio1BaseAddress, 5'h07, 32'hFF, 4'b0001);
    assert (irq_o && irq_address_o == IRQ_ADDRESS_GPIO_C);
    write_register(Gpio2BaseAddress, 5'h07, 32'hFF, 4'b0001);
    assert (!irq_o);

    // Both compare channels share a cause; overflow has higher priority.
    write_register(GpioBaseAddress + 32'h400, 5'h02, 32'h3, 4'b0011);
    write_register(GpioBaseAddress + 32'h400, 5'h04, 32'h3, 4'b0011);
    assert (irq_o && irq_address_o == IRQ_ADDRESS_TIMER_A_COMPARE);
    write_register(GpioBaseAddress + 32'h400, 5'h06, 32'h7, 4'b0011);
    assert (irq_o && irq_address_o == IRQ_ADDRESS_TIMER_A_OVERFLOW);
    // GPIO interrupts still win while both timer sources are pending.
    write_register(Gpio2BaseAddress, 5'h06, 32'h2, 4'b0001);
    assert (irq_o && irq_address_o == IRQ_ADDRESS_GPIO_C);
    write_register(Gpio1BaseAddress, 5'h06, 32'h1, 4'b0001);
    assert (irq_o && irq_address_o == IRQ_ADDRESS_GPIO_B);
    write_register(GpioBaseAddress, 5'h06, 32'h1, 4'b0001);
    assert (irq_o && irq_address_o == IRQ_ADDRESS_GPIO_A);
    write_register(GpioBaseAddress, 5'h07, 32'h1, 4'b0001);
    assert (irq_o && irq_address_o == IRQ_ADDRESS_GPIO_B);
    write_register(Gpio1BaseAddress, 5'h07, 32'h1, 4'b0001);
    assert (irq_o && irq_address_o == IRQ_ADDRESS_GPIO_C);
    write_register(Gpio2BaseAddress, 5'h07, 32'h2, 4'b0001);
    assert (irq_o && irq_address_o == IRQ_ADDRESS_TIMER_A_OVERFLOW);
    write_register(GpioBaseAddress + 32'h400, 5'h06, 32'h6, 4'b0011);
    assert (irq_o && irq_address_o == IRQ_ADDRESS_TIMER_A_COMPARE);
    write_register(GpioBaseAddress + 32'h400, 5'h02, 32'h2, 4'b0011);
    assert (irq_o && irq_address_o == IRQ_ADDRESS_TIMER_A_COMPARE);
    write_register(GpioBaseAddress + 32'h400, 5'h04, 32'h2, 4'b0011);
    assert (!irq_o);

    $display("peripheral manager tests passed");
    $finish;
  end
endmodule
