#==============================================================================
# ZCU102 user I/O constraints
# Port mapping:
#   rst  -> GPIO switch 0 (N)
#   gen  -> GPIO switch 1 (C)
#   read -> GPIO switch 2 (S)
#   tx   -> USB UART FPGA transmit
#   clk  -> 125 MHz differential clock, positive pin
#==============================================================================

set_property PACKAGE_PIN AG15 [get_ports rst_in]               
set_property IOSTANDARD LVCMOS33 [get_ports rst_in]

set_property PACKAGE_PIN AG13 [get_ports gen]               
set_property IOSTANDARD LVCMOS33 [get_ports gen]

set_property PACKAGE_PIN AE15 [get_ports read]              
set_property IOSTANDARD LVCMOS33 [get_ports read]

# UART2_RXD_I_FPGA_TXD is an input to the USB-UART bridge and therefore the
# FPGA's transmit output.
set_property PACKAGE_PIN F13 [get_ports tx]
set_property IOSTANDARD LVCMOS33 [get_ports tx]

# CLK_125 is supplied as an LVDS pair: P = G21, N = F21. This constraint uses
# only the P pin to match the requested single-ended top-level port "clk".
#set_property PACKAGE_PIN G21 [get_ports clk]
#set_property IOSTANDARD LVDS_25 [get_ports clk]

## clk_125.xdc — ZCU102 on-board 125 MHz clock (CLK_125, from SI5341B U69)

set_property PACKAGE_PIN G21 [get_ports clk_125mhz_p]
set_property PACKAGE_PIN F21 [get_ports clk_125mhz_n]
set_property IOSTANDARD LVDS_25 [get_ports clk_125mhz_p]
set_property IOSTANDARD LVDS_25 [get_ports clk_125mhz_n]

## Only the P side gets constrained
create_clock -name clk_125 -period 8.000 [get_ports clk_125mhz_p]
#create_clock -name clk_125mhz -period 8.000 [get_ports clk]

