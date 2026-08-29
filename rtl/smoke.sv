// Minimal combinational module used to verify the Phase 0 toolchain.
module smoke (
    input  logic a,
    input  logic b,
    output logic y
);
  assign y = a & b;
endmodule

