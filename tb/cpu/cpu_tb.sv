timeunit 1ns / 1ps;
import csr_types::*;

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
  logic ext_irq;
  int target_reads, target_writes;

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
      .dmem_address_o          (dmem_address),
      .ext_irq_i               (ext_irq),
      .ext_irq_address_i       (IRQ_ADDRESS_UART_RX)
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

  always @(posedge clk) begin
    if (!rst && dut.valid_mem && dut.pc_mem == 32'd36) begin
      if (dmem_read_enable) target_reads++;
      if (dmem_write_enable) target_writes++;
    end
  end

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

  function automatic logic [31:0] jump_instruction(input int offset);
    logic [20:0] displacement;
    displacement = 21'(offset);
    return {
      displacement[20], displacement[10:1], displacement[11], displacement[19:12], 5'b0, 7'b1101111
    };
  endfunction

  task automatic check_interrupt_replay(input int operation);
    bit reached;
    @(negedge clk);
    rst = 1'b1;
    ext_irq = 1'b0;
    target_reads = 0;
    target_writes = 0;
    for (int index = 0; index < 128; index++) set_memory_word(index, 32'h0000_0013);
    set_memory_word(0, 32'h3000_0513);  // addi x10, x0, 0x300
    set_memory_word(1, 32'h1000_0293);  // addi x5, x0, 0x100
    set_memory_word(2, 32'h3052_9073);  // csrw mtvec, x5
    set_memory_word(3, 32'h0080_0293);  // addi x5, x0, 8
    set_memory_word(4, 32'h3002_9073);  // csrw mstatus, x5
    set_memory_word(5, 32'h0000_0A13);  // addi x20, x0, 0 (handler count)
    set_memory_word(6, 32'h0050_0093);  // addi x1, x0, 5
    set_memory_word(7, 32'h0090_0113);  // addi x2, x0, 9
    set_memory_word(8, 32'h0000_0A93);  // addi x21, x0, 0 (younger count)
    case (operation)
      0: set_memory_word(9, 32'h0010_8193);  // addi x3, x1, 1
      1: set_memory_word(9, 32'h0025_2023);  // sw x2, 0(x10)
      2: set_memory_word(9, 32'h0005_2183);  // lw x3, 0(x10)
      3: set_memory_word(9, 32'h3431_11F3);  // csrrw x3, mtval, x2
      4: set_memory_word(9, 32'h0080_01EF);  // jal x3, +8
      5: set_memory_word(9, 32'h0010_8463);  // beq x1, x1, +8
      6: set_memory_word(9, 32'h0010_8193);  // addi x3, x1, 1; younger jump in EX
      default: $fatal(1, "Unknown replay case");
    endcase
    set_memory_word(10, 32'h001A_8A93);  // addi x21, x21, 1
    if (operation == 6) set_memory_word(10, jump_instruction(4));
    set_memory_word(11, 32'h0070_0213);  // addi x4, x0, 7
    set_memory_word(12, 32'h0000_006F);  // j .
    // UART_RX vector (cause 16) jumps to a handler which preserves the test registers.
    set_memory_word(80, jump_instruction(32'h180 - 32'h140));
    set_memory_word(96, 32'h001A_0A13);  // addi x20, x20, 1
    set_memory_word(97, 32'h3020_0073);  // mret
    set_memory_word(192, 32'h1234_5678);
    repeat (2) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;

    reached = 1'b0;
    repeat (80) begin
      @(negedge clk);
      if (dut.valid_mem && dut.pc_mem == 32'd36) begin
        reached = 1'b1;
        break;
      end
    end
    assert (reached)
    else $fatal(1, "Replay case %0d never reached MEM", operation);
    ext_irq = 1'b1;
    #1ns;
    assert (dut.trap_taken && dut.trap_type == TRAP_TYPE_INTERRUPT);
    assert (!dmem_read_enable && !dmem_write_enable)
    else $fatal(1, "Canceled operation issued a memory access");
    @(posedge clk);
    #1ns;
    assert (dut.csr.mepc == 32'd36 && dut.csr.mcause == 32'h8000_0010);
    assert (!dut.valid_wb && !dut.valid_mem && !dut.valid_ex && !dut.valid_id);
    assert (dut.id_stage.register_file.registers[21] == 0)
    else $fatal(1, "Older WB instruction did not complete");
    assert (get_memory_word(192) == 32'h1234_5678 && dut.csr.mtval == 0);
    ext_irq = 1'b0;

    reached = 1'b0;
    repeat (100) begin
      @(negedge clk);
      if (dut.valid_mem && dut.pc_mem == 32'd48) begin
        reached = 1'b1;
        break;
      end
    end
    assert (reached)
    else $fatal(1, "Replay case %0d failed to return", operation);
    repeat (3) @(posedge clk);
    #1ns;
    assert (dut.id_stage.register_file.registers[20] == 1);
    assert (dut.id_stage.register_file.registers[4] == 7);
    assert (dut.id_stage.register_file.registers[21] == ((operation >= 4) ? 0 : 1));
    assert (dut.interrupts_enabled);
    assert (target_reads == ((operation == 2) ? 1 : 0));
    assert (target_writes == ((operation == 1) ? 1 : 0));
    case (operation)
      0, 6: assert (dut.id_stage.register_file.registers[3] == 6);
      1: assert (get_memory_word(192) == 9);
      2: assert (dut.id_stage.register_file.registers[3] == 32'h1234_5678);
      3: begin
        assert (dut.id_stage.register_file.registers[3] == 0);
        assert (dut.csr.mtval == 9);
      end
      4: assert (dut.id_stage.register_file.registers[3] == 40);
      default: begin
      end
    endcase
  endtask

  initial begin
    $dumpfile("build/tests/cpu/waveform.fst");
    $dumpvars(0, cpu_tb);
    ext_irq = 1'b0;
    target_reads = 0;
    target_writes = 0;

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

    for (int operation = 0; operation < 7; operation++) check_interrupt_replay(operation);

    $display("cpu tests passed (smoke and seven interrupt replay cases)");
    $finish;
  end
endmodule
