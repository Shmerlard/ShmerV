import csr_types::*;
import timer_a_types::*;
import uart_types::*;
import soc_address_map::*;
import gpio_types::*;
import hdmi_types::*;

module peripheral_manager #(
    parameter bit ENABLE_HDMI = 1'b1,
    parameter int unsigned CLOCK_HZ = 843_750,
    parameter int unsigned UART_BAUD_RATE = 9600,
    parameter string HDMI_FONT_FILE = "rtl/peripherals/hdmi/fonts/NICER40C.hex",
    parameter string HDMI_CHAR_INIT_FILE = ""
) (
    input logic clk,
    input logic rst,
    input logic hdmi_pixel_clk_i,
    input logic hdmi_pixel_rst_i,
    input logic hdmi_enable_i,
    output logic [9:0] hdmi_symbols_o[0:2],

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

  typedef enum logic [2:0] {
    READ_NONE,
    READ_GPIO0,
    READ_GPIO1,
    READ_GPIO2,
    READ_TIMER,
    READ_UART,
    READ_HDMI_CHAR
  } read_target_t;

  typedef struct packed {
    logic address_hit;
    logic [31:0] address_offset;
    gpio_register_address_t register_address;
    logic read_enable;
    logic write_enable;
    logic [7:0] read_data;
    logic irq;
  } gpio_bus_t;

  read_target_t read_target;

  // GPIO register buses.
  gpio_bus_t gpio0_bus, gpio1_bus, gpio2_bus;

  // UART register bus and serial output.
  logic uart_address_hit;
  logic [31:0] uart_address_offset;
  uart_registers_address_t uart_register_address;
  logic uart_read_enable, uart_write_enable;
  logic [15:0] uart_read_data;
  logic uart_tx;
  logic uart_rx_irq;
  logic uart_rx;
  logic [7:0] gpio2_alt_sel;
  logic [7:0] gpio2_alt_in;

  // Timer A register bus, PWM outputs, and interrupt sources.
  logic timer_address_hit;
  logic [31:0] timer_address_offset;
  ta_register_address_t timer_register_address;
  logic timer_read_enable, timer_write_enable;
  logic [15:0] timer_read_data;
  logic timer_pwm1, timer_pwm2;
  logic timer_capture1;
  logic [7:0] gpio2_alt_out;
  ta_irq_t timer_irq;

  logic hdmi_address_hit;
  logic [31:0] hdmi_address_offset;
  hdmi_access_target_t hdmi_access_target;
  char_cell_t hdmi_read_data;
  logic hdmi_read_enable, hdmi_write_enable;

  // Forward a byte offset from HDMI_BASE; the controller selects the RAM cell.
  assign hdmi_address_offset = address_i - HDMI_BASE;
  assign hdmi_address_hit = ENABLE_HDMI && address_i >= HDMI_BASE
      && hdmi_address_offset < HDMI_SIZE_BYTES && address_i[1:0] == 2'b00;
  always_comb begin
    hdmi_access_target = HDMI_TARGET_RESERVED;
    if (hdmi_address_hit) begin
      case (hdmi_address_offset)
        32'h00: hdmi_access_target = HDMI_TARGET_CTRL;
        32'h04: hdmi_access_target = HDMI_TARGET_CURSOR_POS;
        32'h08: hdmi_access_target = HDMI_TARGET_START_ROW;
        32'h0C: hdmi_access_target = HDMI_TARGET_CURSOR_DATA;
        default: begin
          if (address_i >= HDMI_CHAR_MEM_BASE && address_i < HDMI_CHAR_MEM_BASE + 32'd4080 * 32'd4)
            hdmi_access_target = HDMI_TARGET_CMEM;
        end
      endcase
    end
  end
  assign hdmi_read_enable = read_enable_i && hdmi_address_hit;
  assign hdmi_write_enable = write_enable_i && hdmi_address_hit && (&write_byte_enable_i[1:0]);

  // GPIO address decoding and byte-wide register access.
  // Reject offsets outside the eight registers before narrowing to three bits.
  assign gpio0_bus.address_hit = address_i >= GPIO_A_BASE
      && address_i < GPIO_A_BASE + GPIO_SIZE_BYTES
      && gpio0_bus.address_offset <= (32'(GPIO_IFG_CLR_ADDRESS) << 2)
      && gpio0_bus.address_offset[1:0] == 2'b00;
  assign gpio1_bus.address_hit = address_i >= GPIO_B_BASE
      && address_i < GPIO_B_BASE + GPIO_SIZE_BYTES
      && gpio1_bus.address_offset <= (32'(GPIO_IFG_CLR_ADDRESS) << 2)
      && gpio1_bus.address_offset[1:0] == 2'b00;
  assign gpio2_bus.address_hit = address_i >= GPIO_C_BASE
      && address_i < GPIO_C_BASE + GPIO_SIZE_BYTES
      && gpio2_bus.address_offset <= (32'(GPIO_IFG_CLR_ADDRESS) << 2)
      && gpio2_bus.address_offset[1:0] == 2'b00;

  assign gpio0_bus.address_offset = address_i - GPIO_A_BASE;
  assign gpio1_bus.address_offset = address_i - GPIO_B_BASE;
  assign gpio2_bus.address_offset = address_i - GPIO_C_BASE;
  assign gpio0_bus.register_address = gpio_register_address_t'(gpio0_bus.address_offset[4:2]);
  assign gpio1_bus.register_address = gpio_register_address_t'(gpio1_bus.address_offset[4:2]);
  assign gpio2_bus.register_address = gpio_register_address_t'(gpio2_bus.address_offset[4:2]);
  assign gpio0_bus.read_enable = read_enable_i && gpio0_bus.address_hit;
  assign gpio1_bus.read_enable = read_enable_i && gpio1_bus.address_hit;
  assign gpio2_bus.read_enable = read_enable_i && gpio2_bus.address_hit;
  assign gpio0_bus.write_enable = write_enable_i && gpio0_bus.address_hit && write_byte_enable_i[0];
  assign gpio1_bus.write_enable = write_enable_i && gpio1_bus.address_hit && write_byte_enable_i[0];
  assign gpio2_bus.write_enable = write_enable_i && gpio2_bus.address_hit && write_byte_enable_i[0];

  // UART control uses full 16-bit writes; data registers remain byte-wide.
  assign uart_address_hit = address_i >= UART_BASE && address_i < UART_BASE + UART_SIZE_BYTES
      && uart_address_offset <= (32'(UART_RX_ADDRESS) << 2)
      && uart_address_offset[1:0] == 2'b00;
  assign uart_address_offset = address_i - UART_BASE;
  assign uart_register_address = uart_registers_address_t'(uart_address_offset[4:2]);
  assign uart_write_enable = write_enable_i && uart_address_hit
      && (uart_register_address == UART_CTRL_REG_ADDRESS
          ? (&write_byte_enable_i[1:0]) : write_byte_enable_i[0]);
  assign uart_read_enable = read_enable_i && uart_address_hit;

  // Timer A accepts aligned base/compare/capture registers and full 16-bit writes.
  assign timer_address_offset = address_i - TIMER_A_BASE;
  assign timer_address_hit = address_i >= TIMER_A_BASE
    && timer_address_offset < TIMER_A_SIZE_BYTES
    && timer_address_offset <= (32'(TA_CAPTURE1_DELTA_ADDRESS) << 2)
    && timer_address_offset[1:0] == 2'b00;
  assign timer_register_address = ta_register_address_t'(timer_address_offset[5:2]);
  assign timer_read_enable = read_enable_i && timer_address_hit;
  assign timer_write_enable = write_enable_i && timer_address_hit && (&write_byte_enable_i[1:0]);

  always_comb begin
    irq_o = 1'b0;
    irq_address_o = IRQ_ADDRESS_GPIO_A;

    // Fixed priority: GPIO A > B > C > timer overflow > timer compare > UART RX.
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
    end else if (timer_irq.ta_irq_compare_1) begin
      irq_o = 1'b1;
      irq_address_o = IRQ_ADDRESS_TIMER_A_COMPARE_1;
    end else if (timer_irq.ta_irq_compare_2) begin
      irq_o = 1'b1;
      irq_address_o = IRQ_ADDRESS_TIMER_A_COMPARE_2;
    end else if (timer_irq.ta_irq_capture_1) begin
      irq_o = 1'b1;
      irq_address_o = IRQ_ADDRESS_TIMER_A_CAPTURE_1;
    end else if (uart_rx_irq) begin
      irq_o = 1'b1;
      irq_address_o = IRQ_ADDRESS_UART_RX;
    end
  end

  // Remember the request destination while peripherals register their read data.
  always_ff @(posedge clk) begin
    if (rst) read_target <= READ_NONE;
    else if (read_enable_i) begin
      if (gpio0_bus.address_hit) read_target <= READ_GPIO0;
      else if (gpio1_bus.address_hit) read_target <= READ_GPIO1;
      else if (gpio2_bus.address_hit) read_target <= READ_GPIO2;
      else if (timer_address_hit) read_target <= READ_TIMER;
      else if (uart_address_hit) read_target <= READ_UART;
      else if (hdmi_address_hit) read_target <= READ_HDMI_CHAR;
      else read_target <= READ_NONE;
    end
  end

  always_comb begin
    case (read_target)
      READ_GPIO0: read_data_o = {24'b0, gpio0_bus.read_data};
      READ_GPIO1: read_data_o = {24'b0, gpio1_bus.read_data};
      READ_GPIO2: read_data_o = {24'b0, gpio2_bus.read_data};
      READ_TIMER: read_data_o = {16'b0, timer_read_data};
      READ_UART: read_data_o = {16'b0, uart_read_data};
      READ_HDMI_CHAR: read_data_o = {16'b0, hdmi_read_data};
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
      .alt_sel_o          (),
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
      .alt_sel_o          (),
      .alt_out_i          (8'b0),
      .alt_oe_i           (8'b0),
      .mmio_write_data_i  (write_data_i[7:0]),
      .mmio_read_data_o   (gpio1_bus.read_data),
      .register_address_i (gpio1_bus.register_address),
      .mmio_write_enable_i(gpio1_bus.write_enable),
      .mmio_read_enable_i (gpio1_bus.read_enable),
      .irq_o              (gpio1_bus.irq)
  );

  always_comb begin
    gpio2_alt_out = '0;
    gpio2_alt_out[GPIO_C_UART_TX_PIN] = uart_tx;
    gpio2_alt_out[GPIO_C_TIMER_A_COMPARE1_PIN] = timer_pwm1;
    gpio2_alt_out[GPIO_C_TIMER_A_COMPARE2_PIN] = timer_pwm2;

    uart_rx = gpio2_alt_sel[GPIO_C_UART_RX_PIN] ? gpio2_alt_in[GPIO_C_UART_RX_PIN] : 1'b1;
    timer_capture1 = gpio2_alt_sel[GPIO_C_TIMER_A_CAPTURE1_PIN]
        && gpio2_alt_in[GPIO_C_TIMER_A_CAPTURE1_PIN];
  end

  gpio_module #(
      .WIDTH   (8),
      .ALT_MASK(GPIO_C_ALT_MASK),
      .IRQ_MASK(8'hFF)
  ) gpio2 (
      .clk                (clk),
      .rst                (rst),
      .pin_i              (gpio2_pin_i),
      .pin_o              (gpio2_pin_o),
      .pin_oe_o           (gpio2_pin_oe_o),
      .alt_in_o           (gpio2_alt_in),
      .alt_sel_o          (gpio2_alt_sel),
      .alt_out_i          (gpio2_alt_out),
      .alt_oe_i           (GPIO_C_ALT_OUTPUT_MASK),
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
      .mmio_write_data_i  (write_data_i[15:0]),
      .register_address_i (uart_register_address),
      .mmio_write_enable_i(uart_write_enable),
      .mmio_read_enable_i (uart_read_enable),
      .mmio_read_data_o   (uart_read_data),
      .tx_o               (uart_tx),
      .rx_i               (uart_rx),
      .rx_irq_o           (uart_rx_irq)
  );

  timer_a_module #(
      .WIDTH(16)
  ) timer_a (
      .clk(clk),
      .rst(rst),
      .capture_1_i(timer_capture1),
      .pwm_1_o(timer_pwm1),
      .pwm_2_o(timer_pwm2),
      .ta_irq_o(timer_irq),
      .register_address_i(timer_register_address),
      .timer_a_data_write_i(write_data_i[15:0]),
      .timer_a_data_read_o(timer_read_data),
      .timer_a_write_enable_i(timer_write_enable),
      .timer_a_read_enable_i(timer_read_enable)
  );

  // CPU and display ports use their respective clock domains.
  if (ENABLE_HDMI) begin : generate_hdmi
    hdmi_module #(
        .FONT_INIT_FILE(HDMI_FONT_FILE),
        .TEXT_INIT_FILE(HDMI_CHAR_INIT_FILE),
        .CPU_CLOCK_HZ(CLOCK_HZ)
    ) hdmi (
        .cpu_clk(clk),
        .pixel_clk(hdmi_pixel_clk_i),
        .rst(rst),
        .pixel_rst(hdmi_pixel_rst_i),
        .access_target_i(hdmi_access_target),
        .hdmi_address_i(hdmi_address_offset[14:0]),
        .hdmi_write_data_i(write_data_i[15:0]),
        .hdmi_read_data_o(hdmi_read_data),
        .hdmi_write_enable_i(hdmi_write_enable),
        .hdmi_read_enable_i(hdmi_read_enable),
        .tmds_symbols_o(hdmi_symbols_o)
    );
  end else begin : generate_no_hdmi
    assign hdmi_read_data = '0;
    assign hdmi_symbols_o = '{default: '0};
  end

endmodule
