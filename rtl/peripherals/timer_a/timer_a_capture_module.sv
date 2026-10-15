import timer_a_types::*;

module timer_a_capture_module #(
    parameter int WIDTH = 16
) (
    input logic clk,
    input logic rst,
    input logic [WIDTH-1:0] ta_counter_i,
    input logic ta_counter_overflowed_i,
    input logic ext_capture_i,
    output logic irq_o,

    input capture_selected_reg_t selected_reg,
    input logic [WIDTH-1:0] capture_write_data_i,
    input logic capture_write_enable_i,
    input logic capture_read_enable_i,
    output logic [WIDTH-1:0] capture_read_data_o


);

  ta_capture_control_t capture_reg_ctrl;
  ta_capture_control_t capture_control_write;
  logic [WIDTH-1:0] capture_start_reg;
  logic [WIDTH-1:0] capture_end_reg;
  logic [WIDTH-1:0] capture_delta_reg;

  logic capture_source;
  logic capture_source_prev;
  logic capture_first_req;
  logic capture_second_req;

  logic capture_disable_req;

  logic source_rise;
  logic source_fall;

  capture_state_t state;
  capture_state_t next_state;

  logic [1:0] overflow_count;
  logic capture_overflow;
  logic capture_irq_event;

  assign capture_control_write = ta_capture_control_t'(capture_write_data_i);

  assign irq_o = capture_reg_ctrl.interrupt_pending
                 && ((capture_reg_ctrl.irq_mode == CAPTURE_IRQ_CAPTURE_START)
                     || (capture_reg_ctrl.irq_mode == CAPTURE_IRQ_CAPTURE_DONE));

  // -------------- Rise & Fall ----------

  always_comb begin
    source_rise = capture_source && !capture_source_prev;
    source_fall = !capture_source && capture_source_prev;
    capture_first_req = 1'b0;
    capture_second_req = 1'b0;
    // The FSM decides whether a matching edge captures START or END.
    case (capture_reg_ctrl.capture_edge)
      CAPTURE_RISE_TO_FALL: begin
        capture_first_req  = source_rise;
        capture_second_req = source_fall;
      end
      CAPTURE_FALL_TO_RISE: begin
        capture_first_req  = source_fall;
        capture_second_req = source_rise;
      end
      CAPTURE_RISE_TO_RISE: begin
        capture_first_req  = source_rise;
        capture_second_req = source_rise;
      end
      CAPTURE_FALL_TO_FALL: begin
        capture_first_req  = source_fall;
        capture_second_req = source_fall;
      end
      default: ;
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      capture_source_prev <= 0;
    end else begin
      capture_source_prev <= capture_source;
    end
  end
  // ---------------------------------------------


  // --------------- Source Driving --------------
  always_comb begin
    if (capture_reg_ctrl.capture_input_mode == CAPTURE_MODE_MANUAL)
      capture_source = capture_reg_ctrl.capture_in;
    else capture_source = ext_capture_i;
  end
  // ---------------------------------------------


  // --------------- FSM -----------------
  always_ff @(posedge clk) begin
    if (rst) state <= CAPTURE_STATE_IDLE;
    else state <= next_state;
  end

  always_comb begin
    capture_disable_req = 0;
    case (state)
      CAPTURE_STATE_IDLE: begin
        if (capture_reg_ctrl.capture_enable) next_state = CAPTURE_STATE_WAIT_START;
        else next_state = CAPTURE_STATE_IDLE;
      end

      CAPTURE_STATE_WAIT_START: begin
        if (capture_reg_ctrl.capture_enable) begin
          if (capture_first_req) next_state = CAPTURE_STATE_WAIT_END;
          else next_state = CAPTURE_STATE_WAIT_START;
        end else begin
          next_state = CAPTURE_STATE_IDLE;
        end
      end

      CAPTURE_STATE_WAIT_END: begin
        if (capture_reg_ctrl.capture_enable) begin
          if (capture_second_req) next_state = CAPTURE_STATE_DONE;
          else next_state = CAPTURE_STATE_WAIT_END;
        end else begin
          next_state = CAPTURE_STATE_IDLE;
        end
      end

      CAPTURE_STATE_DONE: begin
        if (capture_reg_ctrl.capture_burst_enable) begin
          next_state = CAPTURE_STATE_WAIT_START;
        end else begin
          next_state = CAPTURE_STATE_IDLE;
          capture_disable_req = 1;
        end
      end

      default: next_state = CAPTURE_STATE_IDLE;
    endcase
  end
  // -------------------------------------

  // handling loading, and the ctrl reg
  always_ff @(posedge clk) begin
    if (rst) begin
      capture_reg_ctrl <= 0;
      capture_read_data_o <= '0;
    end else begin
      if (capture_write_enable_i) begin
        if (selected_reg == CAPTURE_SEL_REG_CTRL) begin
          capture_reg_ctrl <= capture_control_write;
          capture_reg_ctrl.interrupt_pending <= capture_reg_ctrl.interrupt_pending
                                                && capture_control_write.interrupt_pending;
          capture_reg_ctrl.capture_overflow <= capture_reg_ctrl.capture_overflow;
          if (capture_reg_ctrl.capture_enable) begin
            capture_reg_ctrl.capture_edge <= capture_reg_ctrl.capture_edge;
            capture_reg_ctrl.capture_input_mode <= capture_reg_ctrl.capture_input_mode;
            if (state == CAPTURE_STATE_DONE) capture_reg_ctrl.capture_overflow <= capture_overflow;
          end
        end
      end

      if (state == CAPTURE_STATE_DONE) begin
        capture_reg_ctrl.capture_overflow <= capture_overflow;
      end
      if (capture_disable_req) capture_reg_ctrl.capture_enable <= 1'b0;

      if (capture_read_enable_i && selected_reg == CAPTURE_SEL_REG_DELTA)
        capture_reg_ctrl.interrupt_pending <= 1'b0;
      // A new event wins over either software acknowledgement in this cycle.
      if (capture_irq_event) capture_reg_ctrl.interrupt_pending <= 1'b1;

      if (capture_read_enable_i) begin
        case (selected_reg)
          CAPTURE_SEL_REG_CTRL: capture_read_data_o <= {6'b0, capture_reg_ctrl};
          CAPTURE_SEL_REG_START: capture_read_data_o <= capture_start_reg;
          CAPTURE_SEL_REG_END: capture_read_data_o <= capture_end_reg;
          CAPTURE_SEL_REG_DELTA: capture_read_data_o <= capture_delta_reg;
          default: ;
        endcase
      end
    end
  end

  // -------------------------------------

  // handling start end and delta
  always_ff @(posedge clk) begin
    if (rst) begin
      capture_start_reg <= 0;
      capture_end_reg   <= 0;
      capture_delta_reg <= 0;
      overflow_count    <= 0;
    end else begin
      case (state)
        CAPTURE_STATE_IDLE: begin
        end

        CAPTURE_STATE_WAIT_START: begin
          if (capture_reg_ctrl.capture_enable) begin
            if (capture_first_req) begin
              capture_start_reg <= ta_counter_i;
              overflow_count    <= 2'b00;
            end
          end
        end

        CAPTURE_STATE_WAIT_END: begin
          if (capture_reg_ctrl.capture_enable) begin
            if (overflow_count != 2'b11 && ta_counter_overflowed_i) begin
              overflow_count <= overflow_count + 1;
            end
            if (capture_second_req) begin
              capture_end_reg <= ta_counter_i;
            end
          end
        end

        CAPTURE_STATE_DONE: begin
          capture_delta_reg <= capture_end_reg - capture_start_reg;
        end
        default: ;
      endcase
    end
  end


  always_comb begin
    capture_overflow = 0;
    if (overflow_count >= 2) capture_overflow = 1;
    if (overflow_count == 1 && (capture_end_reg >= capture_start_reg)) capture_overflow = 1;
  end

  always_comb begin
    capture_irq_event = 1'b0;
    case (capture_reg_ctrl.irq_mode)
      CAPTURE_IRQ_CAPTURE_START: begin
        capture_irq_event = (state == CAPTURE_STATE_WAIT_START)
                          && capture_reg_ctrl.capture_enable && capture_first_req;
      end
      CAPTURE_IRQ_CAPTURE_DONE: capture_irq_event = (state == CAPTURE_STATE_DONE);
      default: ;
    endcase
  end
endmodule
