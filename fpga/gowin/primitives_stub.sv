// Declarations for code diagnostics only; exclude from synthesis and simulation.
module OSER10 (
    output wire Q,
    input wire D0, D1, D2, D3, D4, D5, D6, D7, D8, D9,
    input wire PCLK,
    input wire FCLK,
    input wire RESET
);
endmodule

module ELVDS_OBUF (
    input wire I,
    output wire O,
    output wire OB
);
endmodule

module rPLL #(
    parameter FCLKIN = "27",
    parameter IDIV_SEL = 2,
    parameter FBDIV_SEL = 13,
    parameter ODIV_SEL = 8,
    parameter DYN_IDIV_SEL = "false",
    parameter DYN_FBDIV_SEL = "false",
    parameter DYN_ODIV_SEL = "false",
    parameter DYN_DA_EN = "false",
    parameter PSDA_SEL = "0000",
    parameter DUTYDA_SEL = "1000",
    parameter CLKFB_SEL = "internal",
    parameter DEVICE = "GW1NR-9C"
) (
    input wire CLKIN, RESET, RESET_P, CLKFB,
    input wire [5:0] FBDSEL, IDSEL, ODSEL,
    input wire [3:0] PSDA, DUTYDA, FDLY,
    output wire CLKOUT, LOCK, CLKOUTP, CLKOUTD, CLKOUTD3
);
endmodule

module CLKDIV #(
    parameter DIV_MODE = "5",
    parameter GSREN = "false"
) (
    input wire HCLKIN, RESETN, CALIB,
    output wire CLKOUT
);
endmodule
