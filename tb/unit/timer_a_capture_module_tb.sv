timeunit 1ns / 1ps;
import timer_a_types::*;

module timer_a_capture_module_tb;
  logic clk = 0;
  logic rst;
  logic [15:0] ta_counter_i, capture_write_data_i, capture_read_data_o;
  logic ta_counter_overflowed_i, ext_capture_i, irq_o;
  logic capture_write_enable_i, capture_read_enable_i;
  capture_selected_reg_t selected_reg;
  ta_capture_control_t control, status;

  timer_a_capture_module dut (.*);
  always #5 clk = ~clk;

  // Drive at falling edges and inspect registered outputs after rising edges.
  task automatic tick;
    @(posedge clk);
    #1ns;
    @(negedge clk);
  endtask

  task automatic reset_dut;
    rst = 1;
    ta_counter_i = 0;
    ta_counter_overflowed_i = 0;
    ext_capture_i = 0;
    capture_write_data_i = 0;
    capture_write_enable_i = 0;
    capture_read_enable_i = 0;
    selected_reg = CAPTURE_SEL_REG_CTRL;
    control = '0;
    repeat (2) tick();
    rst = 0;
    tick();
    assert (!irq_o)
    else $fatal(1, "IRQ after reset");
  endtask

  task automatic write_control;
    selected_reg = CAPTURE_SEL_REG_CTRL;
    capture_write_data_i = {6'b0, control};
    capture_write_enable_i = 1;
    tick();
    capture_write_enable_i = 0;
    tick();
  endtask

  task automatic read_status;
    selected_reg = CAPTURE_SEL_REG_CTRL;
    capture_read_enable_i = 1;
    tick();
    capture_read_enable_i = 0;
    status = ta_capture_control_t'(capture_read_data_o);
  endtask

  task automatic expect_register(input capture_selected_reg_t reg_sel, input logic [15:0] expected);
    selected_reg = reg_sel;
    capture_read_enable_i = 1;
    tick();
    capture_read_enable_i = 0;
    assert (capture_read_data_o == expected)
    else $fatal(1, "Register %0d: expected %h, got %h", reg_sel, expected, capture_read_data_o);
  endtask

  task automatic source_level(input logic level, input logic [15:0] counter);
    ta_counter_i = counter;
    if (control.capture_input_mode == CAPTURE_MODE_MANUAL) begin
      control.capture_in = level;
      write_control();
    end else begin
      ext_capture_i = level;
      tick();
    end
  endtask

  task automatic arm(input capture_edge_mode_t edges, input capture_input_mode_t source_mode,
                     input capture_irq_mode_t irq_mode, input logic burst = 0);
    control = '0;
    control.capture_edge = edges;
    control.capture_input_mode = source_mode;
    control.irq_mode = irq_mode;
    control.capture_burst_enable = burst;
    control.interrupt_pending = 1;  // Preserve pending on control writes.
    control.capture_in = (edges == CAPTURE_FALL_TO_RISE || edges == CAPTURE_FALL_TO_FALL);
    ext_capture_i = control.capture_in;
    write_control();
    control.capture_enable = 1;
    write_control();
  endtask

  task automatic wrap;
    // Contract: wrap pulse accompanies the already-wrapped counter value.
    ta_counter_i = 0;
    ta_counter_overflowed_i = 1;
    tick();
    ta_counter_overflowed_i = 0;
    tick();
  endtask

  task automatic check_measurement(input logic [15:0] start_value, input logic [15:0] end_value,
                                   input logic overflow_expected);
    tick();  // DONE commits delta and status.
    read_status();
    assert (status.capture_overflow == overflow_expected)
    else $fatal(1, "Wrong overflow status");
    assert (!status.capture_enable)
    else $fatal(1, "Single shot rearmed");
    expect_register(CAPTURE_SEL_REG_START, start_value);
    expect_register(CAPTURE_SEL_REG_END, end_value);
    expect_register(CAPTURE_SEL_REG_DELTA, 16'(end_value - start_value));
    assert (!irq_o)
    else $fatal(1, "DELTA read did not acknowledge IRQ");
  endtask

  initial begin
    @(negedge clk);
    // Both input sources, all four edge modes, including opposite-edge rejection.
    for (int source_mode = 0; source_mode < 2; source_mode++) begin
      for (int edges = 0; edges < 4; edges++) begin
        reset_dut();
        arm(capture_edge_mode_t'(edges), capture_input_mode_t'(source_mode),
            CAPTURE_IRQ_CAPTURE_DONE);
        source_level(edges == 0 || edges == 2, 100);
        assert (!irq_o)
        else $fatal(1, "DONE IRQ at START");
        if (edges >= 2) source_level(edges == 3, 150);
        source_level(edges == 1 || edges == 2, 300);
        tick();
        assert (irq_o)
        else $fatal(1, "Missing DONE IRQ");
        // Merely selecting DELTA without a read must not acknowledge pending.
        selected_reg = CAPTURE_SEL_REG_DELTA;
        tick();
        assert (irq_o)
        else $fatal(1, "Address selection cleared pending");
        check_measurement(100, 300, 0);
      end
    end

    // Full-period boundaries, multiple wraps, and saturation beyond three wraps.
    for (int wraps = 0; wraps <= 5; wraps++) begin
      for (int end_case = 0; end_case < 3; end_case++) begin
        // A monotonically increasing counter cannot end below START without wrapping.
        if (wraps == 0 && end_case == 0) continue;
        reset_dut();
        arm(CAPTURE_RISE_TO_FALL, CAPTURE_MODE_EXTERNAL, CAPTURE_IRQ_CAPTURE_DONE);
        source_level(1, 60000);
        repeat (wraps) wrap();
        source_level(0, 16'(end_case == 0 ? 2000 : end_case == 1 ? 60000 : 61000));
        check_measurement(60000, 16'(end_case == 0 ? 2000 : end_case == 1 ? 60000 : 61000),
                          wraps >= 2 || (wraps == 1 && end_case != 0));
      end
    end

    // START pulse coincides with wrap: excluded. END coincides with wrap: included.
    reset_dut();
    arm(CAPTURE_RISE_TO_FALL, CAPTURE_MODE_EXTERNAL, CAPTURE_IRQ_CAPTURE_DONE);
    ta_counter_overflowed_i = 1;
    source_level(1, 0);
    ta_counter_overflowed_i = 0;
    source_level(0, 10);
    check_measurement(0, 10, 0);
    reset_dut();
    arm(CAPTURE_RISE_TO_FALL, CAPTURE_MODE_EXTERNAL, CAPTURE_IRQ_CAPTURE_DONE);
    source_level(1, 0);
    ta_counter_overflowed_i = 1;
    source_level(0, 0);
    ta_counter_overflowed_i = 0;
    check_measurement(0, 0, 1);

    // START pending: sticky, write-one preserves, write-zero clears.
    reset_dut();
    arm(CAPTURE_RISE_TO_FALL, CAPTURE_MODE_EXTERNAL, CAPTURE_IRQ_CAPTURE_START);
    source_level(1, 100);
    assert (irq_o)
    else $fatal(1, "Missing START IRQ");
    write_control();
    assert (irq_o)
    else $fatal(1, "Write one cleared pending");
    control.interrupt_pending = 0;
    write_control();
    assert (!irq_o)
    else $fatal(1, "Write zero did not clear pending");

    // New START wins over a simultaneous DELTA read acknowledgement.
    reset_dut();
    arm(CAPTURE_RISE_TO_FALL, CAPTURE_MODE_EXTERNAL, CAPTURE_IRQ_CAPTURE_START);
    selected_reg = CAPTURE_SEL_REG_DELTA;
    capture_read_enable_i = 1;
    source_level(1, 100);
    capture_read_enable_i = 0;
    assert (irq_o)
    else $fatal(1, "Read acknowledgement lost new event");

    // New START also wins over a simultaneous control write clearing pending.
    reset_dut();
    arm(CAPTURE_RISE_TO_FALL, CAPTURE_MODE_EXTERNAL, CAPTURE_IRQ_CAPTURE_START);
    control.interrupt_pending = 0;
    selected_reg = CAPTURE_SEL_REG_CTRL;
    capture_write_data_i = {6'b0, control};
    capture_write_enable_i = 1;
    source_level(1, 100);
    capture_write_enable_i = 0;
    assert (irq_o)
    else $fatal(1, "Control acknowledgement lost new event");

    // DONE wins over acknowledgement and remains visible after auto-disable.
    reset_dut();
    arm(CAPTURE_RISE_TO_FALL, CAPTURE_MODE_EXTERNAL, CAPTURE_IRQ_CAPTURE_DONE);
    source_level(1, 100);
    source_level(0, 300);
    selected_reg = CAPTURE_SEL_REG_DELTA;
    capture_read_enable_i = 1;
    tick();
    capture_read_enable_i = 0;
    assert (irq_o)
    else $fatal(1, "DONE event lost to DELTA read");
    read_status();
    assert (!status.capture_enable && status.interrupt_pending)
    else $fatal(1, "Single-shot completion lost pending");

    // Edge/source configuration is locked while enabled; overflow is always RO.
    reset_dut();
    arm(CAPTURE_RISE_TO_FALL, CAPTURE_MODE_EXTERNAL, CAPTURE_IRQ_DISABLE);
    control.capture_edge = CAPTURE_FALL_TO_FALL;
    control.capture_input_mode = CAPTURE_MODE_MANUAL;
    control.capture_overflow = 1;
    write_control();
    read_status();
    assert (status.capture_edge == CAPTURE_RISE_TO_FALL
            && status.capture_input_mode == CAPTURE_MODE_EXTERNAL && !status.capture_overflow)
    else $fatal(1, "Protected control fields changed");
    control.capture_enable = 0;
    write_control();
    // The disabling write itself must still preserve the old edge/source.
    read_status();
    assert (status.capture_edge == CAPTURE_RISE_TO_FALL
            && status.capture_input_mode == CAPTURE_MODE_EXTERNAL)
    else $fatal(1, "Disabling write changed locked fields");
    write_control();
    read_status();
    assert (status.capture_edge == CAPTURE_FALL_TO_FALL
            && status.capture_input_mode == CAPTURE_MODE_MANUAL && !status.capture_overflow)
    else $fatal(1, "Disabled configuration write failed");

    // Abort before START or between START and END; subsequent edges cannot capture.
    for (int started = 0; started < 2; started++) begin
      reset_dut();
      arm(CAPTURE_RISE_TO_FALL, CAPTURE_MODE_EXTERNAL, CAPTURE_IRQ_CAPTURE_DONE);
      if (started != 0) source_level(1, 100);
      control.capture_enable = 0;
      write_control();
      source_level(0, 300);
      source_level(1, 400);
      source_level(0, 500);
      expect_register(CAPTURE_SEL_REG_START, 16'(started != 0 ? 100 : 0));
      expect_register(CAPTURE_SEL_REG_END, 0);
      expect_register(CAPTURE_SEL_REG_DELTA, 0);
      assert (!irq_o)
      else $fatal(1, "IRQ after aborted measurement");
    end

    // Continuous operation retains enable and replaces completed measurements.
    reset_dut();
    arm(CAPTURE_RISE_TO_FALL, CAPTURE_MODE_EXTERNAL, CAPTURE_IRQ_CAPTURE_DONE, 1);
    repeat (3) begin
      source_level(1, 100);
      source_level(0, 300);
      repeat (2) tick();
      read_status();
      assert (status.capture_enable && status.interrupt_pending && irq_o)
      else $fatal(1, "Burst did not remain armed");
      expect_register(CAPTURE_SEL_REG_DELTA, 200);
    end

    // Overflow status belongs to the completed result and is replaced next time.
    reset_dut();
    arm(CAPTURE_RISE_TO_FALL, CAPTURE_MODE_EXTERNAL, CAPTURE_IRQ_CAPTURE_DONE, 1);
    source_level(1, 100);
    repeat (2) wrap();
    source_level(0, 300);
    repeat (2) tick();
    read_status();
    assert (status.capture_overflow)
    else $fatal(1, "Missing burst overflow");
    control.capture_overflow = 0;
    write_control();
    read_status();
    assert (status.capture_overflow)
    else $fatal(1, "Software cleared RO overflow");
    source_level(1, 400);
    source_level(0, 500);
    repeat (2) tick();
    read_status();
    assert (!status.capture_overflow)
    else $fatal(1, "Old overflow leaked into new result");
    expect_register(CAPTURE_SEL_REG_DELTA, 100);

    // Disabled and reserved IRQ modes never latch pending.
    for (int mode = 0; mode < 4; mode += 3) begin
      reset_dut();
      arm(CAPTURE_RISE_TO_FALL, CAPTURE_MODE_EXTERNAL, capture_irq_mode_t'(mode));
      source_level(1, 100);
      source_level(0, 300);
      tick();
      read_status();
      assert (!status.interrupt_pending && !irq_o)
      else $fatal(1, "Masked IRQ event");
    end
    $display("timer capture tests passed");
    $finish;
  end

  initial begin
    #100us;
    $fatal(1, "Capture test watchdog");
  end
endmodule
