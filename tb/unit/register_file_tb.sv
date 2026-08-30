module register_file_tb;
  timeunit 1ns; timeprecision 1ps;

  logic        clk = 1'b0;
  logic [ 4:0] read_addr_1;
  logic [ 4:0] read_addr_2;
  logic        write_enable;
  logic [ 4:0] write_addr;
  logic [31:0] write_data;
  logic [31:0] read_data_1;
  logic [31:0] read_data_2;

  register_file dut (.*);

  always #5ns clk = ~clk;

  task automatic write_register(input logic [4:0] addr, input logic [31:0] data);
    @(negedge clk);
    write_enable = 1'b1;
    write_addr   = addr;
    write_data   = data;
    @(posedge clk);
    #1ns;
    write_enable = 1'b0;
  endtask

  initial begin
    $dumpfile("build/register_file.fst");
    $dumpvars(0, register_file_tb);

    read_addr_1  = 5'd0;
    read_addr_2  = 5'd0;
    write_enable = 1'b0;
    write_addr   = 5'd0;
    write_data   = 32'd0;
    #1ns;

    assert (read_data_1 == 32'd0)
    else $fatal(1, "read port 1: x0 was not zero");
    assert (read_data_2 == 32'd0)
    else $fatal(1, "read port 2: x0 was not zero");

    write_register(5'd1, 32'h1234_5678);
    write_register(5'd2, 32'hdead_beef);

    read_addr_1 = 5'd1;
    read_addr_2 = 5'd2;
    #1ns;
    assert (read_data_1 == 32'h1234_5678)
    else $fatal(1, "read port 1 returned wrong data");
    assert (read_data_2 == 32'hdead_beef)
    else $fatal(1, "read port 2 returned wrong data");

    write_register(5'd0, 32'hffff_ffff);
    read_addr_1 = 5'd0;
    #1ns;
    assert (read_data_1 == 32'd0)
    else $fatal(1, "write to x0 was not ignored");

    @(negedge clk);
    write_enable = 1'b0;
    write_addr   = 5'd2;
    write_data   = 32'h1111_1111;
    @(posedge clk);
    #1ns;
    read_addr_1 = 5'd2;
    #1ns;
    assert (read_data_1 == 32'hdead_beef)
    else $fatal(1, "disabled write changed a register");

    read_addr_1 = 5'd1;
    @(negedge clk);
    write_enable = 1'b1;
    write_addr   = 5'd1;
    write_data   = 32'ha5a5_5a5a;
    #1ns;
    assert (read_data_1 == 32'h1234_5678)
    else $fatal(1, "register changed before clock edge");
    @(posedge clk);
    #1ns;
    write_enable = 1'b0;
    assert (read_data_1 == 32'ha5a5_5a5a)
    else $fatal(1, "register was not overwritten");

    $display("register file test passed");
    $finish;
  end
endmodule

