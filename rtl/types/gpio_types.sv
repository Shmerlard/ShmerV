package gpio_types;
  // Local word indices. Byte offset = register index * 4.
  typedef enum logic [2:0] {
    GPIO_IN_ADDRESS      = 3'd0,  // 0x00: synchronized input, read-only.
    GPIO_OUT_ADDRESS     = 3'd1,  // 0x04: output data.
    GPIO_DIR_ADDRESS     = 3'd2,  // 0x08: per-pin direction.
    GPIO_SEL_ADDRESS     = 3'd3,  // 0x0C: alternate-function selection; ALT_MASK applies.
    GPIO_IE_ADDRESS      = 3'd4,  // 0x10: interrupt enable; IRQ_MASK applies.
    GPIO_IES_ADDRESS     = 3'd5,  // 0x14: interrupt edge selection; IRQ_MASK applies.
    GPIO_IFG_ADDRESS     = 3'd6,  // 0x18: pending flags; writing ones sets flags.
    GPIO_IFG_CLR_ADDRESS = 3'd7   // 0x1C: write-only; writing ones clears flags.
  } gpio_register_address_t;

  typedef enum logic {
    GPIO_DIRECTION_INPUT  = 1'b0,
    GPIO_DIRECTION_OUTPUT = 1'b1
  } gpio_direction_t;

  typedef enum logic {
    GPIO_FUNCTION_GPIO      = 1'b0,
    GPIO_FUNCTION_ALTERNATE = 1'b1
  } gpio_function_t;

  typedef enum logic {
    GPIO_EDGE_RISING  = 1'b0,
    GPIO_EDGE_FALLING = 1'b1
  } gpio_interrupt_edge_t;

  // IE: 1 enables an interrupt from that pin's pending flag.
  // IFG: hardware edges set flags even when IE is zero. A new edge wins
  // over a simultaneous software clear. IFG_CLR reads return zero.
endpackage
