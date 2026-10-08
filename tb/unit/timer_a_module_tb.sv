timeunit 1ns / 1ps;
import timer_a_types::*;

module timer_a_module_tb;
  logic clk = 0;
  logic rst;
  logic pwm_1_o, pwm_2_o;
  ta_irq_t ta_irq_o;
  ta_register_address_t register_address_i;
  logic [15:0] timer_a_data_write_i, timer_a_data_read_o;
  logic timer_a_write_enable_i, timer_a_read_enable_i;
  timer_a_module dut (.*);
  always #5ns clk = ~clk;

  task automatic cycle;
    @(posedge clk);
    #1ns;
  endtask

  task automatic reset_timer;
    rst = 1;
    timer_a_write_enable_i = 0;
    timer_a_read_enable_i = 0;
    register_address_i = TA_ADDRESS;
    timer_a_data_write_i = 0;
    cycle();
    rst = 0;
    assert (ta_irq_o == '0 && !pwm_1_o && !pwm_2_o)
    else $fatal(1, "Reset did not clear IRQ/PWM");
  endtask

  task automatic write_reg(input ta_register_address_t address, input logic [15:0] data);
    register_address_i = address;
    timer_a_data_write_i = data;
    timer_a_write_enable_i = 1;
    cycle();
    timer_a_write_enable_i = 0;
  endtask

  task automatic read_check(input ta_register_address_t address, input logic [15:0] expected);
    register_address_i = address;
    timer_a_read_enable_i = 1;
    cycle();
    timer_a_read_enable_i = 0;
    assert (timer_a_data_read_o == expected)
    else $fatal(1, "Register %0d: expected %h, got %h", address, expected, timer_a_data_read_o);
  endtask

  function automatic logic [15:0] control(input ta_operation_mode_t mode,
                                          input ta_clock_div_t divider, input bit global_enable = 1,
                                          input bit overflow_enable = 1);
    ta_control_t value;
    value = '0;
    value.operation_mode = mode;
    value.clock_div = divider;
    value.interrupt_enable = global_enable;
    value.overflow_ie = overflow_enable;
    return value;
  endfunction

  function automatic logic [15:0] compare_control(
      input ta_out_mode_t mode, input bit enable_irq = 1, input bit manual_value = 0);
    ta_compare_control_t value;
    value = '0;
    value.output_mode = mode;
    value.interrupt_enable = enable_irq;
    value.manual_out_bit = manual_value;
    return 16'(value);
  endfunction

  initial begin
    // Watchdog catches accidental test hangs.
    #100000ns;
    $fatal(1, "Timer test timeout");
  end

  initial begin
    rst = 1;
    reset_timer();
    read_check(TA_ADDRESS, 0);
    read_check(TA_PERIOD_ADDRESS, 0);
    read_check(TA_CTRL_ADDRESS, 0);
    write_reg(TA_PERIOD_ADDRESS, 9);
    write_reg(TA_ADDRESS, 4);
    write_reg(TA_COMP1_ADDRESS, 2);
    write_reg(TA_COMP2_ADDRESS, 7);
    read_check(TA_PERIOD_ADDRESS, 9);
    read_check(TA_ADDRESS, 4);
    read_check(TA_COMP1_ADDRESS, 2);
    read_check(TA_COMP2_ADDRESS, 7);

    // All divider ratios, including preservation of divider phase at halt.
    for (int div_index = 0; div_index < 5; div_index++) begin
      reset_timer();
      write_reg(TA_PERIOD_ADDRESS, 100);
      write_reg(TA_CTRL_ADDRESS, control(TA_MODE_UP, ta_clock_div_t'(div_index)));
      for (int n = 1; n <= 32; n++) begin
        read_check(TA_ADDRESS, 16'((n - 1) / (1 << div_index)));
      end
    end
    reset_timer();
    write_reg(TA_PERIOD_ADDRESS, 100);
    write_reg(TA_CTRL_ADDRESS, control(TA_MODE_UP, TIMER_A_CLK_DIV_4));
    cycle();
    write_reg(TA_CTRL_ADDRESS, control(TA_MODE_HALT, TIMER_A_CLK_DIV_4));
    repeat (5) cycle();
    read_check(TA_ADDRESS, 0);
    write_reg(TA_CTRL_ADDRESS, control(TA_MODE_UP, TIMER_A_CLK_DIV_4));
    cycle();
    cycle();
    read_check(TA_ADDRESS, 1);

    // Period=1, compare=period, both channels and wrap on the same edge.
    reset_timer();
    write_reg(TA_PERIOD_ADDRESS, 1);
    write_reg(TA_COMP1_ADDRESS, 1);
    write_reg(TA_COMP2_ADDRESS, 1);
    write_reg(TA_COMP1_CTRL_ADDRESS, compare_control(TIMER_A_OUTPUT_MODE_SET_RESET));
    write_reg(TA_COMP2_CTRL_ADDRESS, compare_control(TIMER_A_OUTPUT_MODE_TOGGLE_SET));
    write_reg(TA_CTRL_ADDRESS, control(TA_MODE_UP, TIMER_A_CLK_DIV_1));
    cycle();
    assert (ta_irq_o == '0)
    else $fatal(1, "Event fired on arrival instead of departure");
    cycle();
    assert (ta_irq_o == 3'b111 && !pwm_1_o && pwm_2_o)
    else $fatal(1, "Simultaneous wrap/compare or PWM priority failed");
    // Halt preserves flags; disabling the global gate suppresses all outputs.
    write_reg(TA_CTRL_ADDRESS, control(TA_MODE_HALT, TIMER_A_CLK_DIV_1, 0) | 16'd1);
    assert (ta_irq_o == '0)
    else $fatal(1, "Global disable failed");
    repeat (3) cycle();
    write_reg(TA_CTRL_ADDRESS, control(TA_MODE_HALT, TIMER_A_CLK_DIV_1) | 16'd1);
    assert (ta_irq_o == 3'b111)
    else $fatal(1, "Pending was lost while halted/disabled");
    write_reg(TA_COMP1_CTRL_ADDRESS, compare_control(TIMER_A_OUTPUT_MODE_SET_RESET));
    write_reg(TA_COMP2_CTRL_ADDRESS, compare_control(TIMER_A_OUTPUT_MODE_TOGGLE_SET));
    write_reg(TA_CTRL_ADDRESS, control(TA_MODE_HALT, TIMER_A_CLK_DIV_1));
    assert (ta_irq_o == '0)
    else $fatal(1, "Software clear failed");

    // Counter write cancels wrap, compare, and automatic PWM on that edge.
    reset_timer();
    write_reg(TA_PERIOD_ADDRESS, 1);
    write_reg(TA_COMP1_ADDRESS, 1);
    write_reg(TA_COMP1_CTRL_ADDRESS, compare_control(TIMER_A_OUTPUT_MODE_TOGGLE));
    write_reg(TA_CTRL_ADDRESS, control(TA_MODE_UP, TIMER_A_CLK_DIV_1));
    cycle();
    write_reg(TA_ADDRESS, 0);
    assert (ta_irq_o == '0 && !pwm_1_o)
    else $fatal(1, "Counter write did not cancel events");

    // Continuous wrap; an event wins over a simultaneous pending clear.
    reset_timer();
    write_reg(TA_ADDRESS, 16'hffff);
    write_reg(TA_COMP1_ADDRESS, 16'hffff);
    write_reg(TA_COMP1_CTRL_ADDRESS, compare_control(TIMER_A_OUTPUT_MODE_SET));
    write_reg(TA_CTRL_ADDRESS, control(TA_MODE_CONTINUOUS, TIMER_A_CLK_DIV_1));
    write_reg(TA_COMP1_CTRL_ADDRESS, compare_control(TIMER_A_OUTPUT_MODE_SET));
    assert (ta_irq_o.ta_irq_overflow && ta_irq_o.ta_irq_compare_1 && pwm_1_o)
    else $fatal(1, "Continuous wrap or event/clear priority failed");
    read_check(TA_ADDRESS, 0);

    // Disabled events are recorded and exposed when enabled later.
    reset_timer();
    write_reg(TA_PERIOD_ADDRESS, 0);
    write_reg(TA_COMP1_CTRL_ADDRESS, compare_control(TIMER_A_OUTPUT_MODE_SET, 0));
    write_reg(TA_CTRL_ADDRESS, control(TA_MODE_UP, TIMER_A_CLK_DIV_1, 0, 0));
    cycle();
    assert (ta_irq_o == '0)
    else $fatal(1, "Disabled IRQ asserted");
    write_reg(TA_COMP1_CTRL_ADDRESS, compare_control(TIMER_A_OUTPUT_MODE_SET));
    write_reg(TA_CTRL_ADDRESS, control(TA_MODE_UP, TIMER_A_CLK_DIV_1));
    assert (ta_irq_o.ta_irq_overflow && ta_irq_o.ta_irq_compare_1)
    else $fatal(1, "Disabled event was not recorded");

    // Manual output is independent of ticks and halt.
    reset_timer();
    write_reg(TA_COMP1_CTRL_ADDRESS, compare_control(TIMER_A_OUTPUT_MODE_MANUAL, 0, 1));
    cycle();
    assert (pwm_1_o)
    else $fatal(1, "Manual output failed while halted");
    write_reg(TA_COMP1_CTRL_ADDRESS, compare_control(TIMER_A_OUTPUT_MODE_MANUAL, 0, 0));
    cycle();
    assert (!pwm_1_o)
    else $fatal(1, "Manual output clear failed");

    // Every automatic PWM mode: match at 1, period action at 3.
    for (int mode_index = 1; mode_index <= 6; mode_index++) begin
      reset_timer();
      write_reg(TA_PERIOD_ADDRESS, 3);
      write_reg(TA_COMP1_ADDRESS, 1);
      if (mode_index == 5) begin
        write_reg(TA_COMP1_CTRL_ADDRESS, compare_control(TIMER_A_OUTPUT_MODE_MANUAL, 0, 1));
        cycle();
      end
      write_reg(TA_COMP1_CTRL_ADDRESS, compare_control(ta_out_mode_t'(mode_index)));
      write_reg(TA_CTRL_ADDRESS, control(TA_MODE_UP, TIMER_A_CLK_DIV_1));
      cycle();  // 0 -> 1: no match yet.
      cycle();  // 1 -> 2: match.
      assert (pwm_1_o == (mode_index != 5))
      else $fatal(1, "PWM mode %0d compare action failed", mode_index);
      cycle();
      cycle();  // 3 -> 0: period action.
      assert (pwm_1_o == (mode_index == 1 || mode_index == 4 || mode_index == 6))
      else $fatal(1, "PWM mode %0d period action failed", mode_index);
    end

    // A compare beyond the period cannot match in normal up counting.
    reset_timer();
    write_reg(TA_PERIOD_ADDRESS, 1);
    write_reg(TA_COMP1_ADDRESS, 2);
    write_reg(TA_COMP2_ADDRESS, 2);
    write_reg(TA_COMP1_CTRL_ADDRESS, compare_control(TIMER_A_OUTPUT_MODE_SET));
    write_reg(TA_CTRL_ADDRESS, control(TA_MODE_UP, TIMER_A_CLK_DIV_1));
    repeat (6) cycle();
    assert (!ta_irq_o.ta_irq_compare_1 && !pwm_1_o && ta_irq_o.ta_irq_overflow)
    else $fatal(1, "Compare beyond period matched");

    // Lowering period applies on the following tick; wrap wins over clear.
    reset_timer();
    write_reg(TA_PERIOD_ADDRESS, 10);
    write_reg(TA_ADDRESS, 5);
    write_reg(TA_CTRL_ADDRESS, control(TA_MODE_UP, TIMER_A_CLK_DIV_1));
    write_reg(TA_PERIOD_ADDRESS, 2);
    assert (!ta_irq_o.ta_irq_overflow)
    else $fatal(1, "Period write wrapped too early");
    write_reg(TA_CTRL_ADDRESS, control(TA_MODE_UP, TIMER_A_CLK_DIV_1));
    assert (ta_irq_o.ta_irq_overflow)
    else $fatal(1, "Wrap lost to simultaneous clear");
    read_check(TA_ADDRESS, 0);

    // Changing compare while halted does not itself create a match event.
    reset_timer();
    write_reg(TA_ADDRESS, 3);
    write_reg(TA_COMP1_ADDRESS, 3);
    write_reg(TA_COMP1_CTRL_ADDRESS, compare_control(TIMER_A_OUTPUT_MODE_TOGGLE));
    repeat (3) cycle();
    assert (!ta_irq_o.ta_irq_compare_1 && !pwm_1_o)
    else $fatal(1, "Compare write generated an event without a tick");
    write_reg(TA_CTRL_ADDRESS, control(TA_MODE_UP, TIMER_A_CLK_DIV_1));
    cycle();
    assert (ta_irq_o.ta_irq_compare_1 && pwm_1_o)
    else $fatal(1, "Updated compare did not apply");

    // Divider changes preserve progress, allowing a shorter first interval.
    reset_timer();
    write_reg(TA_PERIOD_ADDRESS, 100);
    write_reg(TA_CTRL_ADDRESS, control(TA_MODE_UP, TIMER_A_CLK_DIV_16));
    repeat (5) cycle();
    write_reg(TA_CTRL_ADDRESS, control(TA_MODE_UP, TIMER_A_CLK_DIV_2));
    read_check(TA_ADDRESS, 0);
    read_check(TA_ADDRESS, 1);
    reset_timer();

    // Unsupported mode must not count or produce events.
    write_reg(TA_CTRL_ADDRESS, 16'h0086);  // Mode 2, global/overflow enables.
    repeat (4) cycle();
    read_check(TA_ADDRESS, 0);
    assert (ta_irq_o == '0)
    else $fatal(1, "Unsupported mode produced an event");
    reset_timer();
    $display("Timer A unit tests passed");
    $finish;
  end
endmodule
