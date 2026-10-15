package timer_a_types;
  typedef enum logic [3:0] {  // TODO: more consistent locations and naminmg
    TA_PERIOD_ADDRESS         = 4'd0,
    TA_COMP1_ADDRESS          = 4'd1,
    TA_COMP1_CTRL_ADDRESS     = 4'd2,
    TA_COMP2_ADDRESS          = 4'd3,
    TA_COMP2_CTRL_ADDRESS     = 4'd4,
    TA_ADDRESS                = 4'd5,
    TA_CTRL_ADDRESS           = 4'd6,
    TA_CAPTURE1_CTRL_ADDRESS  = 4'd7,
    TA_CAPTURE1_START_ADDRESS = 4'd8,
    TA_CAPTURE1_END_ADDRESS   = 4'd9,
    TA_CAPTURE1_DELTA_ADDRESS = 4'd10

    // TA_CTRL_ADDRESS_SET,
    // TA_CTRL_ADDRESS_RESET
  } ta_register_address_t;


  //------------- Timer A Controls ----------------

  typedef enum logic [2:0] {
    TA_MODE_HALT       = 3'd0,
    TA_MODE_UP         = 3'd1,
    TA_MODE_CONTINUOUS = 3'd3
  } ta_operation_mode_t;

  typedef enum logic [2:0] {
    TIMER_A_CLK_DIV_1  = 3'd0,
    TIMER_A_CLK_DIV_2  = 3'd1,
    TIMER_A_CLK_DIV_4  = 3'd2,
    TIMER_A_CLK_DIV_8  = 3'd3,
    TIMER_A_CLK_DIV_16 = 3'd4,
    TIMER_A_CLK_DIV_1024 = 3'd5
  } ta_clock_div_t;

  typedef struct packed {
    logic [6:0]         reserved;
    ta_operation_mode_t operation_mode;
    ta_clock_div_t      clock_div;
    logic               interrupt_enable;
    logic               overflow_ie;
    logic               overflow_ifg;
  } ta_control_t;

  //--------- TImer A Capture module control -----------
  typedef enum logic {
    CAPTURE_MODE_MANUAL,
    CAPTURE_MODE_EXTERNAL
  } capture_input_mode_t;

  typedef enum logic [1:0] {
    CAPTURE_RISE_TO_FALL,
    CAPTURE_FALL_TO_RISE,
    CAPTURE_RISE_TO_RISE,
    CAPTURE_FALL_TO_FALL
  } capture_edge_mode_t;

  typedef enum logic [1:0] {
    CAPTURE_IRQ_DISABLE,
    CAPTURE_IRQ_CAPTURE_START,
    CAPTURE_IRQ_CAPTURE_DONE,
    CAPTURE_IRQ_CAPTURE_RESERVED
  } capture_irq_mode_t;

  typedef enum logic [1:0] {
    CAPTURE_SEL_REG_CTRL,
    CAPTURE_SEL_REG_START,
    CAPTURE_SEL_REG_END,
    CAPTURE_SEL_REG_DELTA
  } capture_selected_reg_t;

  typedef struct packed {
    capture_edge_mode_t capture_edge;
    capture_input_mode_t capture_input_mode;
    logic capture_in;
    logic capture_enable;
    logic capture_overflow;  // Read-only hardware status.
    logic capture_burst_enable;
    capture_irq_mode_t irq_mode;
    logic interrupt_pending;
  } ta_capture_control_t;

  typedef enum logic [1:0] {
    CAPTURE_STATE_IDLE,
    CAPTURE_STATE_WAIT_START,
    CAPTURE_STATE_WAIT_END,
    CAPTURE_STATE_DONE
  } capture_state_t;

  //--------- TImer A Compare module control -----------
  typedef enum logic [2:0] {
    TIMER_A_OUTPUT_MODE_MANUAL       = 3'd0,
    TIMER_A_OUTPUT_MODE_SET          = 3'd1,
    TIMER_A_OUTPUT_MODE_TOGGLE_RESET = 3'd2,
    TIMER_A_OUTPUT_MODE_SET_RESET    = 3'd3,
    TIMER_A_OUTPUT_MODE_TOGGLE       = 3'd4,
    TIMER_A_OUTPUT_MODE_RESET        = 3'd5,
    TIMER_A_OUTPUT_MODE_TOGGLE_SET   = 3'd6
  } ta_out_mode_t;

  typedef struct packed {
    ta_out_mode_t output_mode;
    logic         manual_out_bit;
    logic         interrupt_enable;
    logic         interrupt_pending;
  } ta_compare_control_t;

  typedef struct packed {
    logic ta_irq_overflow;
    logic ta_irq_compare_1;
    logic ta_irq_compare_2;
    logic ta_irq_capture_1;
  } ta_irq_t;

endpackage
