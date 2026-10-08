package timer_a_types;
  typedef enum logic [3:0] {
    TA_PERIOD_ADDRESS,
    TA_COMP1_ADDRESS,
    TA_COMP1_CTRL_ADDRESS,
    TA_COMP2_ADDRESS,
    TA_COMP2_CTRL_ADDRESS,
    TA_ADDRESS,
    TA_CTRL_ADDRESS
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
    TIMER_A_CLK_DIV_1,
    TIMER_A_CLK_DIV_2,
    TIMER_A_CLK_DIV_4,
    TIMER_A_CLK_DIV_8,
    TIMER_A_CLK_DIV_16
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
    TIMER_A_OUTPUT_MODE_MANUAL,
    TIMER_A_OUTPUT_MODE_SET,
    TIMER_A_OUTPUT_MODE_TOGGLE_RESET,
    TIMER_A_OUTPUT_MODE_SET_RESET,
    TIMER_A_OUTPUT_MODE_TOGGLE,
    TIMER_A_OUTPUT_MODE_RESET,
    TIMER_A_OUTPUT_MODE_TOGGLE_SET
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
