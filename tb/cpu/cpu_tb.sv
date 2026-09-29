timeunit 1ns / 1ps;

module cpu_tb;
  logic clk = 1'b0;
  logic rst;

  logic [31:0] imem_load_data;
  logic [31:0] dmem_load_data;
  logic dmem_write_enable;
  logic [3:0] dmem_write_byte_enable;
  logic dmem_read_enable;
  logic imem_read_enable;
  logic [31:0] imem_read_address;
  logic [31:0] dmem_address;
  logic [31:0] dmem_store_data;

  cpu dut (
      .clk                     (clk),
      .rst                     (rst),
      .imem_load_data_i        (imem_load_data),
      .dmem_load_data_i        (dmem_load_data),
      .dmem_store_data_o       (dmem_store_data),
      .dmem_write_enable_o     (dmem_write_enable),
      .dmem_write_byte_enable_o(dmem_write_byte_enable),
      .dmem_read_enable_o      (dmem_read_enable),
      .imem_read_enable_o      (imem_read_enable),
      .imem_read_address_o     (imem_read_address),
      .dmem_address_o          (dmem_address)
  );

  memory #(
      .MEM_WORDS(1024)
  ) memory (
      .clk                       (clk),
      .port_a_read_address_i     (imem_read_address),
      .port_a_read_enable_i      (imem_read_enable),
      .port_a_read_data_o        (imem_load_data),
      .port_b_address_i          (dmem_address),
      .port_b_write_enable_i     (dmem_write_enable),
      .port_b_write_byte_enable_i(dmem_write_byte_enable),
      .port_b_enable_i           (dmem_read_enable || dmem_write_enable),
      .port_b_write_data_i       (dmem_store_data),
      .port_b_read_data_o        (dmem_load_data)
  );

  always #5ns clk = ~clk;

  task automatic set_memory_word(input int index, input logic [31:0] value);
    memory.memory_lane0[index] = value[7:0];
    memory.memory_lane1[index] = value[15:8];
    memory.memory_lane2[index] = value[23:16];
    memory.memory_lane3[index] = value[31:24];
  endtask

  function automatic logic [31:0] get_memory_word(input int index);
    return {
      memory.memory_lane3[index],
      memory.memory_lane2[index],
      memory.memory_lane1[index],
      memory.memory_lane0[index]
    };
  endfunction

  initial begin
    $dumpfile("build/tests/cpu/waveform.fst");
    $dumpvars(0, cpu_tb);

    // NOP-fill the program area.
    for (int index = 0; index < 32; index++) begin
      set_memory_word(index, 32'h0000_0013);
    end

    // Keep the smoke program spread out so each pipeline result is easy to inspect.
    set_memory_word(0, 32'h1000_0513);  // addi x10, x0, 256
    set_memory_word(5, 32'h0050_0093);  // addi x1, x0, 5
    set_memory_word(10, 32'h0030_8113);  // addi x2, x1, 3
    set_memory_word(15, 32'h0025_2023);  // sw x2, 0(x10)
    set_memory_word(20, 32'h0005_2183);  // lw x3, 0(x10)

    rst = 1'b1;
    repeat (2) @(posedge clk);
    rst = 1'b0;

    repeat (32) @(posedge clk);
    #1ns;

    assert (dut.id_stage.register_file.registers[1] == 32'd5);
    assert (dut.id_stage.register_file.registers[2] == 32'd8);
    assert (get_memory_word(64) == 32'd8);
    assert (dut.id_stage.register_file.registers[3] == 32'd8);

    $display("cpu tests passed");
    $finish;
  end
endmodule
