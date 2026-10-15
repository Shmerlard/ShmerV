import timer_a_types::*;
module timer_a_module #(
    parameter int WIDTH = 16
) (
    input logic clk,
    input logic rst,
    input logic capture_1_i,  // Must already be synchronized to clk.

    output logic pwm_1_o,
    output logic pwm_2_o,

    output ta_irq_t ta_irq_o,

    input  ta_register_address_t             register_address_i,
    input  logic                 [WIDTH-1:0] timer_a_data_write_i,
    output logic                 [WIDTH-1:0] timer_a_data_read_o,
    input  logic                             timer_a_write_enable_i,
    input  logic                             timer_a_read_enable_i
);

  reg [WIDTH-1:0] main_counter;
  logic [WIDTH-1:0] period_register;
  logic tick_enable;
  logic counter_write;
  logic timer_event_enable;
  logic timer_running;
  logic [9:0] divider_counter;
  logic [9:0] divider_limit;

  ta_control_t timer_a_control;
  ta_control_t control_next;
  logic [WIDTH-1:0] period_next, counter_next, selected_read_data;
  logic compare1_write_enable, compare2_write_enable;
  logic compare1_ctrl_sel, compare2_ctrl_sel;
  logic [WIDTH-1:0] compare1_read_data, compare2_read_data;

  logic compare_module_1_irq, compare_module_2_irq;
  // driving the tick enable and divider
  logic overflow_next;
  logic capture_overflow_pulse;
  logic capture1_selected, capture1_irq, capture1_read_selected;
  capture_selected_reg_t capture1_register;
  logic [WIDTH-1:0] capture1_read_data, timer_read_data;

  // Both read paths register their response on the request edge.
  assign timer_a_data_read_o = capture1_read_selected ? capture1_read_data : timer_read_data;
  always_comb begin
    capture1_selected = 1'b1;
    capture1_register = CAPTURE_SEL_REG_CTRL;
    case (register_address_i)
      TA_CAPTURE1_CTRL_ADDRESS: capture1_register = CAPTURE_SEL_REG_CTRL;
      TA_CAPTURE1_START_ADDRESS: capture1_register = CAPTURE_SEL_REG_START;
      TA_CAPTURE1_END_ADDRESS: capture1_register = CAPTURE_SEL_REG_END;
      TA_CAPTURE1_DELTA_ADDRESS: capture1_register = CAPTURE_SEL_REG_DELTA;
      default: capture1_selected = 1'b0;
    endcase
  end
  assign counter_write = timer_a_write_enable_i && (register_address_i == TA_ADDRESS);
  // CPU counter writes cancel this tick's counting, PWM, and interrupt events.
  // The divider keeps its normal cadence.
  assign timer_event_enable = tick_enable && !counter_write;
  // Unsupported mode encodings behave as halt.
  assign timer_running = (timer_a_control.operation_mode == TA_MODE_UP)
                         || (timer_a_control.operation_mode == TA_MODE_CONTINUOUS);
  always_comb begin
    case (timer_a_control.clock_div)
      TIMER_A_CLK_DIV_1:    divider_limit = 10'd0;
      TIMER_A_CLK_DIV_2:    divider_limit = 10'd1;
      TIMER_A_CLK_DIV_4:    divider_limit = 10'd3;
      TIMER_A_CLK_DIV_8:    divider_limit = 10'd7;
      TIMER_A_CLK_DIV_16:   divider_limit = 10'd15;
      TIMER_A_CLK_DIV_1024: divider_limit = 10'd1023;
      default:             divider_limit = 10'd0;
    endcase
    tick_enable = !rst && timer_running && (divider_counter >= divider_limit);
  end

  always_ff @(posedge clk) begin
    if (rst) divider_counter <= '0;
    else if (timer_running) begin
      if (tick_enable) divider_counter <= '0;
      else divider_counter <= divider_counter + 1'b1;
    end
  end

  // Counter advancement and CPU register selection share next-state logic.
  always_comb begin
    counter_next = main_counter;
    period_next = period_register;
    control_next = timer_a_control;
    selected_read_data = '0;
    compare1_write_enable = 1'b0;
    compare2_write_enable = 1'b0;
    compare1_ctrl_sel = 1'b0;
    compare2_ctrl_sel = 1'b0;
    overflow_next = 1'b0;

    if (timer_event_enable) begin
      case (timer_a_control.operation_mode)
        TA_MODE_HALT: ;
        TA_MODE_UP: begin
          if (main_counter >= period_register) begin
            counter_next  = '0;
            overflow_next = 1'b1;
          end else begin
            counter_next = main_counter + 1'b1;
          end
        end
        TA_MODE_CONTINUOUS: begin
          counter_next = main_counter + 1'b1;
          if (counter_next == '0) overflow_next = 1'b1;
        end
        default: ;
      endcase
    end

    case (register_address_i)
      TA_PERIOD_ADDRESS: begin
        selected_read_data = period_register;
        if (timer_a_write_enable_i) period_next = timer_a_data_write_i;
      end
      TA_ADDRESS: begin
        selected_read_data = main_counter;
        if (timer_a_write_enable_i) counter_next = timer_a_data_write_i;
      end
      TA_CTRL_ADDRESS: begin
        selected_read_data = WIDTH'(timer_a_control);
        if (timer_a_write_enable_i) control_next = ta_control_t'(timer_a_data_write_i);
      end
      TA_COMP1_ADDRESS, TA_COMP1_CTRL_ADDRESS: begin
        compare1_ctrl_sel = (register_address_i == TA_COMP1_CTRL_ADDRESS);
        compare1_write_enable = timer_a_write_enable_i;
        selected_read_data = compare1_read_data;
      end
      TA_COMP2_ADDRESS, TA_COMP2_CTRL_ADDRESS: begin
        compare2_ctrl_sel = (register_address_i == TA_COMP2_CTRL_ADDRESS);
        compare2_write_enable = timer_a_write_enable_i;
        selected_read_data = compare2_read_data;
      end
      default: ;
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      main_counter <= '0;
      period_register <= '0;
      timer_a_control <= '0;
      timer_read_data <= '0;
      capture1_read_selected <= 1'b0;
      capture_overflow_pulse <= 1'b0;
    end else begin
      main_counter <= counter_next;
      period_register <= period_next;
      timer_a_control <= control_next;
      // Accompany the already-wrapped main_counter, not its next value.
      capture_overflow_pulse <= overflow_next;
      // A new wrap wins over a simultaneous software clear of pending.
      if (overflow_next) timer_a_control.overflow_ifg <= 1'b1;
      if (timer_a_read_enable_i) begin
        timer_read_data <= selected_read_data;
        capture1_read_selected <= capture1_selected;
      end
    end
  end

  timer_a_compare_module #(
      .WIDTH(WIDTH)
  ) compare_module_1 (
      .clk(clk),
      .rst(rst),
      .tick_enable_i(timer_event_enable),
      .timer_a_counter_i(main_counter),
      .comp_reg_write_enable_i(compare1_write_enable),
      .comp_reg_write_data_i(timer_a_data_write_i),
      .comp_reg_ctrl_sel_i(compare1_ctrl_sel),
      .comp_reg_read_data_o(compare1_read_data),
      .cr0_eq_tar(main_counter == period_register),
      .pwm_o(pwm_1_o),
      .irq_o(compare_module_1_irq)
  );

  timer_a_compare_module #(
      .WIDTH(WIDTH)
  ) compare_module_2 (
      .clk(clk),
      .rst(rst),
      .tick_enable_i(timer_event_enable),
      .timer_a_counter_i(main_counter),
      .comp_reg_write_enable_i(compare2_write_enable),
      .comp_reg_write_data_i(timer_a_data_write_i),
      .comp_reg_ctrl_sel_i(compare2_ctrl_sel),
      .comp_reg_read_data_o(compare2_read_data),
      .cr0_eq_tar(main_counter == period_register),
      .pwm_o(pwm_2_o),
      .irq_o(compare_module_2_irq)
  );

  // Capture interval arithmetic is valid only in CONTINUOUS mode.
  timer_a_capture_module #(
      .WIDTH(WIDTH)
  ) capture_module_1 (
      .clk(clk),
      .rst(rst),
      .ta_counter_i(main_counter),
      .ta_counter_overflowed_i(capture_overflow_pulse),
      .ext_capture_i(capture_1_i),
      .irq_o(capture1_irq),
      .selected_reg(capture1_register),
      .capture_write_data_i(timer_a_data_write_i),
      .capture_write_enable_i(timer_a_write_enable_i && capture1_selected),
      .capture_read_enable_i(timer_a_read_enable_i && capture1_selected),
      .capture_read_data_o(capture1_read_data)
  );

  always_comb begin
    ta_irq_o.ta_irq_overflow  = timer_a_control.overflow_ifg
                                && timer_a_control.interrupt_enable
                                && timer_a_control.overflow_ie;
    ta_irq_o.ta_irq_compare_1 = compare_module_1_irq && timer_a_control.interrupt_enable;
    ta_irq_o.ta_irq_compare_2 = compare_module_2_irq && timer_a_control.interrupt_enable;
    ta_irq_o.ta_irq_capture_1 = capture1_irq && timer_a_control.interrupt_enable;
  end

endmodule
