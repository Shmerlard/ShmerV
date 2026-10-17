// Two-stage level synchronizer; register the source input. Not for pulses/buses.
// SDC depends on the cdc_bit_meta name.
module cdc_bit_sync (
    input  logic dst_clk,
    input  logic dst_rst,
    input  logic data_i,
    output logic data_o
);
  logic cdc_bit_meta /* synthesis syn_preserve = 1 */;
  logic synced /* synthesis syn_preserve = 1 */;

  always_ff @(posedge dst_clk) begin
    if (dst_rst) begin
      cdc_bit_meta <= 1'b0;
      synced       <= 1'b0;
    end else begin
      cdc_bit_meta <= data_i;
      synced       <= cdc_bit_meta;
    end
  end

  assign data_o = synced;
endmodule
