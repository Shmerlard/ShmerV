# Physical board oscillator: 27 MHz.
create_clock -name clk -period 37.037 [get_ports {clk}]
# CPU and peripherals run at 6.75 MHz, divided in top.sv.
create_generated_clock -name cpu_clk -source [get_ports {clk}] -divide_by 4 [get_nets {cpu_clk}]

# Match reserved CDC names in all instances; exclude only first-stage D.
set_false_path -to [get_pins {*/cdc_bit_meta_s*/D}]

# Held handshake bus: one extra destination cycle for setup; no same-edge hold.
set_multicycle_path -from [get_pins {*/cdc_hs_hold*_s*/Q}] -to [get_pins {*/cdc_hs_value*_s*/D}] -setup -end 2
set_false_path -hold -from [get_pins {*/cdc_hs_hold*_s*/Q}] -to [get_pins {*/cdc_hs_value*_s*/D}]
