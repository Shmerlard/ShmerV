module cpu_synthesis_top (
    input  logic clk,
    input  logic rst,
    output logic activity_o
);

  logic [31:0] stimulus;
  logic [31:0] imem_load_data;
  logic [31:0] dmem_load_data;
  logic [31:0] dmem_store_data;
  logic [31:0] imem_read_address;
  logic [31:0] dmem_address;
  logic [3:0] dmem_write_byte_enable;
  logic dmem_write_enable;
  logic dmem_read_enable;
  logic imem_read_enable;

  always_ff @(posedge clk) begin
    if (rst) begin
      stimulus       <= 32'h1;
      imem_load_data <= '0;
      dmem_load_data <= '0;
    end else begin
      stimulus <= {stimulus[30:0], stimulus[31] ^ stimulus[21] ^ stimulus[1] ^ stimulus[0]};

      if (imem_read_enable) imem_load_data <= stimulus ^ imem_read_address;
      if (dmem_read_enable) dmem_load_data <= stimulus ^ dmem_address;
    end
  end

  assign activity_o = ^{dmem_store_data, dmem_write_enable, dmem_write_byte_enable};

  cpu cpu (
      .clk                     (clk),
      .rst                     (rst),
      .imem_load_data_i        (imem_load_data),
      .dmem_load_data_i        (dmem_load_data),
      .dmem_store_data_o       (dmem_store_data),
      .dmem_write_enable_o     (dmem_write_enable),
      .dmem_write_byte_enable_o(dmem_write_byte_enable),
      .dmem_read_enable_o      (dmem_read_enable),
      .imem_read_enable_o      (imem_read_enable),
      .imem_read_address_o     (imem_read_address),
      .dmem_address_o          (dmem_address),
      .ext_irq_i               (1'b0),
      .ext_irq_address_i       (csr_types::IRQ_ADDRESS_GPIO_A)
  );

endmodule
