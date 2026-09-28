module cpu_system_top (
    input  logic       clk,
    input  logic       reset_button_n_i,
    output logic [7:0] led_o
);
  logic [7:0] gpio_pin_output;

  cpu_system #(
      .MEM_WORDS       (4096),
      .MEMORY_INIT_FILE("build/fpga/tang_nano_9k/cpu_system/software/program.hex"),
      .RESET_PC        (32'h8000_0000),
      .RAM_BASE_ADDRESS(32'h8000_0000)
  ) cpu_system (
      .clk              (clk),
      .rst              (~reset_button_n_i),
      .gpio_pin_i       (8'b0),
      .gpio_pin_o       (gpio_pin_output),
      .gpio_pin_oe_o    (),
      .peripheral_irq_o (),
      .address_overlap_o()
  );

  assign led_o = gpio_pin_output;
endmodule
