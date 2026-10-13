# Physical board oscillator: 27 MHz.
create_clock -name clk -period 37.037 [get_ports {clk}]
# CPU and peripherals run at 6.75 MHz, divided in top.sv.
create_generated_clock -name cpu_clk -source [get_ports {clk}] -divide_by 4 [get_nets {cpu_clk}]
