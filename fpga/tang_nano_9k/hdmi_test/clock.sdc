# Physical board oscillator: 27 MHz.
create_clock -name clk -period 37.037 [get_ports {clk}]
# rPLL: 27 MHz * 14 / 3 = 126 MHz; CLKDIV: /5 = 25.2 MHz.
# Target primitive output pins to preserve source-clock latency.
create_generated_clock -name serializer_clk -source [get_ports {clk}] -multiply_by 14 -divide_by 3 [get_pins {clocks/pll/CLKOUT}]
create_generated_clock -name pixel_clk -source [get_pins {clocks/pll/CLKOUT}] -divide_by 5 [get_pins {clocks/pixel_divider/CLKOUT}]
