import csr_types::*;
import timer_a_types::*;

module peripheral_manager #(
    parameter logic [31:0] GPIO_BASE_ADDRESS = 32'h1000_0000,
    parameter int unsigned CLOCK_HZ = 843_750,
    parameter int unsigned UART_BAUD_RATE = 9600
) (
    input logic clk,
    input logic rst,

    input  logic [31:0] address_i,
    input  logic [31:0] write_data_i,
    input  logic [ 3:0] write_byte_enable_i,
    input  logic        read_enable_i,
    input  logic        write_enable_i,
    output logic [31:0] read_data_o,

    input  logic [7:0] gpio0_pin_i,
    output logic [7:0] gpio0_pin_o,
    output logic [7:0] gpio0_pin_oe_o,

    input  logic [7:0] gpio1_pin_i,
    output logic [7:0] gpio1_pin_o,
    output logic [7:0] gpio1_pin_oe_o,

    input  logic [7:0] gpio2_pin_i,
    output logic [7:0] gpio2_pin_o,
    output logic [7:0] gpio2_pin_oe_o,

    output logic irq_o,
    output irq_address_t irq_address_o
);
  localparam logic [31:0] GpioAddressSpaceBytes = 32'h0000_0100;
  localparam logic [31:0] Gpio1BaseAddress = GPIO_BASE_ADDRESS + GpioAddressSpaceBytes;
  localparam logic [31:0] Gpio2BaseAddress = GPIO_BASE_ADDRESS + 2 * GpioAddressSpaceBytes;
  localparam logic [31:0] UartBaseAddress = GPIO_BASE_ADDRESS + 3 * GpioAddressSpaceBytes;

  localparam logic [31:0] TimerBaseAddress = GPIO_BASE_ADDRESS + 4 * GpioAddressSpaceBytes;

  typedef enum logic [2:0] {
    READ_GPIO_NONE,
    READ_GPIO0,
    READ_GPIO1,
    READ_GPIO2,
    READ_TIMER
  } gpio_read_target_t;

  typedef struct packed {
    logic address_hit;
    logic [31:0] address_offset;
    logic [4:0] register_address;
    logic read_enable;
    logic write_enable;
    logic [7:0] read_data;
    logic irq;
  } gpio_bank_t;

  gpio_bank_t gpio0_bus, gpio1_bus, gpio2_bus;
  logic uart_address_hit;
  logic [31:0] uart_address_offset;
  logic uart_write_enable;
  gpio_read_target_t gpio_read_target;
  logic uart_tx;
  logic timer_pwm1, timer_pwm2;
  logic timer_address_hit;
  logic [31:0] timer_address_offset;
  ta_register_address_t timer_register_address;
  logic timer_read_enable, timer_write_enable;
  logic [15:0] timer_read_data;
  ta_irq_t timer_irq;

  assign timer_address_offset = address_i - TimerBaseAddress;
  // Seven aligned registers; all other offsets are unmapped.
  assign timer_address_hit = address_i >= TimerBaseAddress
      && timer_address_offset <= 32'h18 && timer_address_offset[1:0] == 2'b00;
  assign timer_register_address = ta_register_address_t'(timer_address_offset[5:2]);
  assign timer_read_enable = read_enable_i && timer_address_hit;
  // Full 16-bit register writes only: lower halfword or full word.
  assign timer_write_enable = write_enable_i && timer_address_hit && (&write_byte_enable_i[1:0]);

  assign gpio0_bus.address_hit = address_i >= GPIO_BASE_ADDRESS
      && address_i < GPIO_BASE_ADDRESS + GpioAddressSpaceBytes;
  assign gpio1_bus.address_hit = address_i >= Gpio1BaseAddress
      && address_i < Gpio1BaseAddress + GpioAddressSpaceBytes;
  assign gpio2_bus.address_hit = address_i >= Gpio2BaseAddress
      && address_i < Gpio2BaseAddress + GpioAddressSpaceBytes;
  assign uart_address_hit = address_i >= UartBaseAddress
      && address_i < UartBaseAddress + GpioAddressSpaceBytes;
  assign gpio0_bus.address_offset = address_i - GPIO_BASE_ADDRESS;
  assign gpio1_bus.address_offset = address_i - Gpio1BaseAddress;
  assign gpio2_bus.address_offset = address_i - Gpio2BaseAddress;
  assign uart_address_offset = address_i - UartBaseAddress;
  assign gpio0_bus.register_address = gpio0_bus.address_offset[6:2];
  assign gpio1_bus.register_address = gpio1_bus.address_offset[6:2];
  assign gpio2_bus.register_address = gpio2_bus.address_offset[6:2];
  assign gpio0_bus.read_enable = read_enable_i && gpio0_bus.address_hit;
  assign gpio1_bus.read_enable = read_enable_i && gpio1_bus.address_hit;
  assign gpio2_bus.read_enable = read_enable_i && gpio2_bus.address_hit;
  assign gpio0_bus.write_enable = write_enable_i && gpio0_bus.address_hit && write_byte_enable_i[0];
  assign gpio1_bus.write_enable = write_enable_i && gpio1_bus.address_hit && write_byte_enable_i[0];
  assign gpio2_bus.write_enable = write_enable_i && gpio2_bus.address_hit && write_byte_enable_i[0];
  assign uart_write_enable = write_enable_i && uart_address_hit && write_byte_enable_i[0];
  always_comb begin
    irq_o = 1'b0;
    irq_address_o = IRQ_ADDRESS_GPIO_A;

    // Fixed priority: GPIO A > B > C > timer overflow > timer compare.
    if (gpio0_bus.irq) begin
      irq_o = 1'b1;
      irq_address_o = IRQ_ADDRESS_GPIO_A;
    end else if (gpio1_bus.irq) begin
      irq_o = 1'b1;
      irq_address_o = IRQ_ADDRESS_GPIO_B;
    end else if (gpio2_bus.irq) begin
      irq_o = 1'b1;
      irq_address_o = IRQ_ADDRESS_GPIO_C;
    end else if (timer_irq.ta_irq_overflow) begin
      irq_o = 1'b1;
      irq_address_o = IRQ_ADDRESS_TIMER_A_OVERFLOW;
    end else if (timer_irq.ta_irq_compare_1 || timer_irq.ta_irq_compare_2) begin
      irq_o = 1'b1;
      irq_address_o = IRQ_ADDRESS_TIMER_A_COMPARE;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      gpio_read_target <= READ_GPIO_NONE;
    end else if (read_enable_i) begin
      if (gpio0_bus.address_hit) begin
        gpio_read_target <= READ_GPIO0;
      end else if (gpio1_bus.address_hit) begin
        gpio_read_target <= READ_GPIO1;
      end else if (gpio2_bus.address_hit) begin
        gpio_read_target <= READ_GPIO2;
      end else if (timer_address_hit) begin
        gpio_read_target <= READ_TIMER;
      end else begin
        gpio_read_target <= READ_GPIO_NONE;
      end
    end
  end

  always_comb begin
    case (gpio_read_target)
      READ_GPIO0: read_data_o = {24'b0, gpio0_bus.read_data};
      READ_GPIO1: read_data_o = {24'b0, gpio1_bus.read_data};
      READ_GPIO2: read_data_o = {24'b0, gpio2_bus.read_data};
      READ_TIMER: read_data_o = {16'b0, timer_read_data};
      default: read_data_o = 32'b0;
    endcase
  end

  gpio_module #(
      .WIDTH   (8),
      .ALT_MASK(8'b0),
      .IRQ_MASK(8'hFF)
  ) gpio0 (
      .clk                (clk),
      .rst                (rst),
      .pin_i              (gpio0_pin_i),
      .pin_o              (gpio0_pin_o),
      .pin_oe_o           (gpio0_pin_oe_o),
      .alt_in_o           (),
      .alt_out_i          (8'b0),
      .alt_oe_i           (8'b0),
      .mmio_write_data_i  (write_data_i[7:0]),
      .mmio_read_data_o   (gpio0_bus.read_data),
      .register_address_i (gpio0_bus.register_address),
      .mmio_write_enable_i(gpio0_bus.write_enable),
      .mmio_read_enable_i (gpio0_bus.read_enable),
      .irq_o              (gpio0_bus.irq)
  );

  gpio_module #(
      .WIDTH   (8),
      .ALT_MASK(8'b0),
      .IRQ_MASK(8'hFF)
  ) gpio1 (
      .clk                (clk),
      .rst                (rst),
      .pin_i              (gpio1_pin_i),
      .pin_o              (gpio1_pin_o),
      .pin_oe_o           (gpio1_pin_oe_o),
      .alt_in_o           (),
      .alt_out_i          (8'b0),
      .alt_oe_i           (8'b0),
      .mmio_write_data_i  (write_data_i[7:0]),
      .mmio_read_data_o   (gpio1_bus.read_data),
      .register_address_i (gpio1_bus.register_address),
      .mmio_write_enable_i(gpio1_bus.write_enable),
      .mmio_read_enable_i (gpio1_bus.read_enable),
      .irq_o              (gpio1_bus.irq)
  );

  gpio_module #(
      .WIDTH   (8),
      .ALT_MASK(8'b1100_0001),
      .IRQ_MASK(8'hFF)
  ) gpio2 (
      .clk                (clk),
      .rst                (rst),
      .pin_i              (gpio2_pin_i),
      .pin_o              (gpio2_pin_o),
      .pin_oe_o           (gpio2_pin_oe_o),
      .alt_in_o           (),
      .alt_out_i          ({timer_pwm1, timer_pwm2, 5'b0, uart_tx}),
      .alt_oe_i           (8'b1100_0001),
      .mmio_write_data_i  (write_data_i[7:0]),
      .mmio_read_data_o   (gpio2_bus.read_data),
      .register_address_i (gpio2_bus.register_address),
      .mmio_write_enable_i(gpio2_bus.write_enable),
      .mmio_read_enable_i (gpio2_bus.read_enable),
      .irq_o              (gpio2_bus.irq)
  );

  uart_module #(
      .CLOCK_HZ (CLOCK_HZ),
      .BAUD_RATE(UART_BAUD_RATE)
  ) uart (
      .clk                (clk),
      .rst                (rst),
      .mmio_write_data_i  (write_data_i[7:0]),
      .register_address_i (uart_address_offset[2]),
      .mmio_write_enable_i(uart_write_enable),
      .tx_o               (uart_tx)
  );

  timer_a_module #(
      .WIDTH(16)
  ) timer_a (
      .clk(clk),
      .rst(rst),
      .pwm_1_o(timer_pwm1),
      .pwm_2_o(timer_pwm2),
      .ta_irq_o(timer_irq),
      .register_address_i(timer_register_address),
      .timer_a_data_write_i(write_data_i[15:0]),
      .timer_a_data_read_o(timer_read_data),
      .timer_a_write_enable_i(timer_write_enable),
      .timer_a_read_enable_i(timer_read_enable)
  );

endmodule
