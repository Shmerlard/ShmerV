timeunit 1ns / 1ps;

module cpu_system_tb;
  localparam integer PipelineDrainCycles = 5;

  logic clk = 1'b0;
  logic rst;
  integer timeout_cycles;
  integer elapsed_cycles;
  integer expected_file_handle;
  integer scan_result;
  integer expected_register;
  string check_type;
  string expected_file;
  logic test_completed;
  logic [31:0] test_end_pc;
  logic [31:0] expected_address;
  logic [31:0] expected_value;
  logic [31:0] actual_value;
  string trace_file;

  cpu_system #(
      .RESET_PC(32'h8000_0000)
  ) dut (
      .clk(clk),
      .rst(rst)
  );

  always #5ns clk = ~clk;

  initial begin
    if (!$value$plusargs("test_end_pc=%h", test_end_pc)) $fatal(1, "Missing +test_end_pc");
    if (!$value$plusargs("timeout_cycles=%d", timeout_cycles)) timeout_cycles = 1000;
    if (!$value$plusargs("expected_file=%s", expected_file)) $fatal(1, "Missing +expected_file");
    if (!$value$plusargs("trace_file=%s", trace_file))
      trace_file = "build/tests/cpu_system/waveform.fst";

    $dumpfile(trace_file);
    $dumpvars(0, cpu_system_tb);

    rst = 1'b1;
    repeat (2) @(posedge clk);
    rst = 1'b0;

    test_completed = 1'b0;
    for (elapsed_cycles = 0; elapsed_cycles < timeout_cycles; elapsed_cycles++) begin
      @(posedge clk);
      #1ns;
      if (dut.cpu.valid_ex && (dut.cpu.pc_ex == test_end_pc)) begin
        test_completed = 1'b1;
        break;
      end
    end
    if (!test_completed)
      $fatal(1, "Timed out after %0d cycles waiting for PC %h", timeout_cycles, test_end_pc);

    repeat (PipelineDrainCycles) @(posedge clk);
    #1ns;

    expected_file_handle = $fopen(expected_file, "r");
    if (expected_file_handle == 0) $fatal(1, "Could not open %s", expected_file);

    while (!$feof(
        expected_file_handle
    )) begin
      scan_result = $fscanf(expected_file_handle, "%s", check_type);
      if (scan_result == 1) begin
        case (check_type)
          "memory": begin
            scan_result = $fscanf(expected_file_handle, "%h %h", expected_address, expected_value);
            if (scan_result != 2) $fatal(1, "Invalid memory entry in %s", expected_file);
            actual_value = dut.memory.memory_words[expected_address[11:2]];
            assert (actual_value == expected_value)
            else
              $fatal(
                  1,
                  "Expected memory[%h] = %h, got %h",
                  expected_address,
                  expected_value,
                  actual_value
              );
          end

          "register": begin
            scan_result = $fscanf(expected_file_handle, "%d %h", expected_register, expected_value);
            if (scan_result != 2) $fatal(1, "Invalid register entry in %s", expected_file);
            if (expected_register == 0) actual_value = '0;
            else actual_value = dut.cpu.id_stage.register_file.registers[expected_register];
            assert (actual_value == expected_value)
            else
              $fatal(
                  1, "Expected x%0d = %h, got %h", expected_register, expected_value, actual_value
              );
          end

          default: $fatal(1, "Unknown check type '%s' in %s", check_type, expected_file);
        endcase
      end
    end

    $fclose(expected_file_handle);

    $display("cpu_system tests passed");
    $finish;
  end
endmodule
