import hdmi_types::*;
import soc_address_map::*;

module hdmi_controller (
    input cpu_clk,
    input rst,

    input hdmi_access_target_t access_target_i,
    input logic hdmi_write_enable_i,
    input logic hdmi_read_enable_i,
    input logic [14:0] hdmi_address_i,
    input logic [15:0] hdmi_write_data_i,
    output logic [15:0] hdmi_read_data_o,

    // Char memory control
    output logic cmem_write_enable_o,
    output logic cmem_read_enable_o,
    output logic [11:0] cmem_cell_index_o,
    output logic [15:0] cmem_write_data_o,
    input logic [15:0] cmem_read_data_i,

    // Text renderer control
    output logic cursor_enable_o,
    output logic cursor_blink_o,
    output logic [11:0] cursor_index_o
);

  logic direct_write_req;
  logic cursor_write_req;

  localparam logic [14:0] CMEM_OFFSET = 15'(HDMI_CHAR_MEM_BASE - HDMI_BASE);
  logic [14:0] cmem_byte_offset;
  logic [11:0] direct_cell_index;

  hdmi_ctrl_reg_t ctrl_reg;
  // logic [4:0] start_row_reg; // TODO: better name to indicate scroll

  // direct write control
  always_comb begin
    cmem_byte_offset   = hdmi_address_i - CMEM_OFFSET;
    direct_cell_index  = cmem_byte_offset[13:2];
    cmem_read_enable_o = 1'b0;
    direct_write_req   = 1'b0;
    if (access_target_i == HDMI_TARGET_CMEM) begin
      cmem_read_enable_o = hdmi_read_enable_i;
      direct_write_req   = hdmi_write_enable_i;
    end
  end

  always_comb begin
    cursor_write_req = 1'b0;
    if (access_target_i == HDMI_TARGET_CURSOR_DATA) begin
      if (hdmi_write_enable_i) begin
        cursor_write_req = 1'b1;
      end
    end
  end

  always_comb begin
    cmem_write_enable_o = 0;
    if (direct_write_req || cursor_write_req) begin
      cmem_write_enable_o = 1;
    end

    cmem_cell_index_o = direct_cell_index;
    cmem_write_data_o = hdmi_write_data_i;
    if (cursor_write_req) begin
      cmem_cell_index_o = cursor_index_o;
    end
  end

  always_ff @(posedge cpu_clk) begin
    if (rst) begin
      cursor_index_o <= 0;
    end else begin
      if (hdmi_write_enable_i && access_target_i == HDMI_TARGET_CURSOR_POS) begin
        cursor_index_o <= hdmi_write_data_i[11:0];
      end else if (cursor_write_req) begin
        cursor_index_o <= cursor_index_o + 1;
        // TODO: interrupt if there is overflow
      end
    end
  end
endmodule
