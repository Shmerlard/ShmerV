package timer_a_types;
  typedef enum logic [3:0] {
    TA_PERIOD_ADDRESS     = 4'd0,
    TA_COMP1_ADDRESS      = 4'd1,
    TA_COMP1_CTRL_ADDRESS = 4'd2,
    TA_COMP2_ADDRESS      = 4'd3,
    TA_COMP2_CTRL_ADDRESS = 4'd4,
    TA_ADDRESS            = 4'd5,
    TA_CTRL_ADDRESS       = 4'd6
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
    TIMER_A_CLK_DIV_16 = 3'd4
  } ta_clock_div_t;

  typedef struct packed {
    logic [6:0]         reserved;
    ta_operation_mode_t operation_mode;
    ta_clock_div_t      clock_div;
    logic               interrupt_enable;
    logic               overflow_ie;
    logic               overflow_ifg;
  } ta_control_t;

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
    // logic           u
    ta_out_mode_t output_mode;
    logic         manual_out_bit;
    logic         interrupt_enable;
    logic         interrupt_pending;
  } ta_compare_control_t;

  typedef struct packed {
    logic ta_irq_overflow;
    logic ta_irq_compare_1;
    logic ta_irq_compare_2;
  } ta_irq_t;

endpackage
