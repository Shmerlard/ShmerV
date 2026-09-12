timeunit 1ns / 1ps;

module cpu_tb;
  logic clk = 1'b0;
  logic rst;

  logic [31:0] imem_read_data;
  logic [31:0] dmem_read_data;
  logic dmem_write_enable;
  logic dmem_read_enable;
  logic [31:0] imem_read_address;
  logic [31:0] dmem_read_address;
  logic [31:0] dmem_write_address;
  logic [31:0] dmem_write_data;

  cpu dut (
      .clk                 (clk),
      .rst                 (rst),
      .imem_read_data_i    (imem_read_data),
      .dmem_read_data_i    (dmem_read_data),
      .dmem_write_enable_o (dmem_write_enable),
      .dmem_read_enable_o  (dmem_read_enable),
      .imem_read_address_o (imem_read_address),
      .dmem_read_address_o (dmem_read_address),
      .dmem_write_address_o(dmem_write_address),
      .dmem_write_data_o   (dmem_write_data)
  );

  memory #(
      .MEM_WORDS(1024)
  ) memory (
      .clk                   (clk),
      .port_a_read_address_i (imem_read_address),
      .port_a_read_data_o    (imem_read_data),
      .port_b_read_address_i (dmem_read_address),
      .port_b_write_address_i(dmem_write_address),
      .port_b_write_enable_i (dmem_write_enable),
      .port_b_read_enable_i  (dmem_read_enable),
      .port_b_write_data_i   (dmem_write_data),
      .port_b_read_data_o    (dmem_read_data)
  );

  always #5ns clk = ~clk;

  initial begin
    $dumpfile("build/tests/cpu/waveform.fst");
    $dumpvars(0, cpu_tb);

    // NOP-fill the program area.
    for (int index = 0; index < 32; index++) begin
      memory.memory_words[index] = 32'h0000_0013;
    end

    // Spacing avoids data hazards until forwarding/stalling is implemented.
    memory.memory_words[0] = 32'h1000_0513;  // addi x10, x0, 256
    memory.memory_words[5] = 32'h0050_0093;  // addi x1, x0, 5
    memory.memory_words[10] = 32'h0030_8113;  // addi x2, x1, 3
    memory.memory_words[15] = 32'h0025_2023;  // sw x2, 0(x10)
    memory.memory_words[20] = 32'h0005_2183;  // lw x3, 0(x10)

    rst = 1'b1;
    repeat (2) @(posedge clk);
    rst = 1'b0;

    repeat (32) @(posedge clk);
    #1ns;

    assert (dut.id_stage.register_file.registers[1] == 32'd5);
    assert (dut.id_stage.register_file.registers[2] == 32'd8);
    assert (memory.memory_words[64] == 32'd8);
    assert (dut.id_stage.register_file.registers[3] == 32'd8);

    $display("cpu tests passed");
    $finish;
  end
endmodule
