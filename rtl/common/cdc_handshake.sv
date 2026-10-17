// Transfers the latest value; intermediate updates may be skipped.
// Reset both domains together, synchronously to their local clocks.
// SDC depends on the cdc_hs_hold/cdc_hs_value names.
module cdc_handshake #(
    parameter int unsigned WIDTH = 12
) (
    input  logic             src_clk,
    input  logic             src_rst,
    input  logic             dst_clk,
    input  logic             dst_rst,
    input  logic [WIDTH-1:0] data_i,
    output logic [WIDTH-1:0] data_o
);
  // Preserve SDC target nets.
  logic [WIDTH-1:0] cdc_hs_hold /* synthesis syn_keep = 1 */;
  logic [WIDTH-1:0] cdc_hs_value /* synthesis syn_keep = 1 */;
  logic req, ack;
  logic req_sync, ack_sync;

  typedef enum logic [1:0] {
    IDLE,
    WAIT_ACK_HIGH,
    WAIT_ACK_LOW
  } state_t;
  state_t state;

  cdc_bit_sync req_sync_inst (
      .dst_clk(dst_clk),
      .dst_rst(dst_rst),
      .data_i (req),
      .data_o (req_sync)
  );
  cdc_bit_sync ack_sync_inst (
      .dst_clk(src_clk),
      .dst_rst(src_rst),
      .data_i (ack),
      .data_o (ack_sync)
  );

  always_ff @(posedge src_clk) begin
    if (src_rst) begin
      state       <= IDLE;
      cdc_hs_hold <= '0;
      req         <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          cdc_hs_hold <= data_i;
          req         <= 1'b1;
          state       <= WAIT_ACK_HIGH;
        end
        WAIT_ACK_HIGH:
        if (ack_sync) begin
          req   <= 1'b0;
          state <= WAIT_ACK_LOW;
        end
        WAIT_ACK_LOW: if (!ack_sync) state <= IDLE;
        default: begin
          state <= IDLE;
          req   <= 1'b0;
        end
      endcase
    end
  end

  always_ff @(posedge dst_clk) begin
    if (dst_rst) begin
      ack          <= 1'b0;
      cdc_hs_value <= '0;
    end else if (!ack && req_sync) begin
      cdc_hs_value <= cdc_hs_hold;
      ack          <= 1'b1;
    end else if (!req_sync) begin
      ack <= 1'b0;
    end
  end

  assign data_o = cdc_hs_value;
endmodule
