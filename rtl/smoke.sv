// Minimal combinational module used to verify the Phase 0 toolchain.
module smoke (
    input  logic a_i,
    input  logic b_i,
    output logic y_o
);
  assign y_o = a_i & b_i;
endmodule
