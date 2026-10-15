import timer_a_types::*;
module timer_a_compare_module #(
    parameter int WIDTH = 16
) (
    input  logic             clk,
    input  logic             rst,
    input  logic             tick_enable_i,
    input  logic [WIDTH-1:0] timer_a_counter_i,
    input  logic             comp_reg_write_enable_i,
    input  logic [WIDTH-1:0] comp_reg_write_data_i,
    input  logic             comp_reg_ctrl_sel_i,
    output logic [WIDTH-1:0] comp_reg_read_data_o,
    input  logic             cr0_eq_tar,
    output logic             pwm_o,
    output logic             irq_o
);
  logic                [WIDTH-1:0] compare_reg;
  ta_compare_control_t             compare_reg_ctrl;

  logic                            cr_eq_tar;
  logic                            enter_interupt;

  // Writing data from registers
  always_ff @(posedge clk) begin
    if (rst) begin
      compare_reg <= 0;
      compare_reg_ctrl <= 0;
    end else begin
      if (comp_reg_write_enable_i) begin
        if (comp_reg_ctrl_sel_i) begin
          compare_reg_ctrl <= ta_compare_control_t'(comp_reg_write_data_i);
        end else begin
          compare_reg <= comp_reg_write_data_i;
        end
      end
      // A new match wins over a simultaneous software clear of pending.
      if (enter_interupt) compare_reg_ctrl.interrupt_pending <= 1'b1;
    end
  end


  // Reading data from registers
  always_comb begin
    if (comp_reg_ctrl_sel_i) comp_reg_read_data_o = WIDTH'(compare_reg_ctrl);
    else comp_reg_read_data_o = compare_reg;
  end

  always_comb begin
    cr_eq_tar = (compare_reg == timer_a_counter_i);
    enter_interupt = tick_enable_i && cr_eq_tar;
    irq_o = compare_reg_ctrl.interrupt_pending && compare_reg_ctrl.interrupt_enable;
  end

  // Setting the pwm
  always_ff @(posedge clk) begin
    if (rst) begin
      pwm_o <= 0;
    end else if (compare_reg_ctrl.output_mode == TIMER_A_OUTPUT_MODE_MANUAL) begin
      pwm_o <= compare_reg_ctrl.manual_out_bit;
    end else if (tick_enable_i) begin
      case (compare_reg_ctrl.output_mode)
        TIMER_A_OUTPUT_MODE_MANUAL: begin
          pwm_o <= compare_reg_ctrl.manual_out_bit;
        end
        TIMER_A_OUTPUT_MODE_SET: begin
          if (cr_eq_tar) pwm_o <= 1'b1;
        end
        TIMER_A_OUTPUT_MODE_TOGGLE_RESET: begin
          if (cr_eq_tar) pwm_o <= ~pwm_o;
          if (cr0_eq_tar) pwm_o <= 1'b0;
        end
        TIMER_A_OUTPUT_MODE_SET_RESET: begin
          if (cr_eq_tar) pwm_o <= 1'b1;
          if (cr0_eq_tar) pwm_o <= 1'b0;
        end
        TIMER_A_OUTPUT_MODE_TOGGLE: begin
          if (cr_eq_tar) pwm_o <= ~pwm_o;
        end
        TIMER_A_OUTPUT_MODE_RESET: begin
          if (cr_eq_tar) pwm_o <= 0;
        end
        TIMER_A_OUTPUT_MODE_TOGGLE_SET: begin
          if (cr_eq_tar) pwm_o <= ~pwm_o;
          if (cr0_eq_tar) pwm_o <= 1'b1;
        end
        default: ;
      endcase
    end
  end

endmodule
