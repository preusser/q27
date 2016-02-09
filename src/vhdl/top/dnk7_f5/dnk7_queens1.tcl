set TOP dnk7_queens1
set PART xc7k325t-1-ffg676

read_vhdl -library PoC ../../PoC/common/my_config_KC705.vhdl
read_vhdl -library PoC ../../PoC/common/my_project.vhdl
read_vhdl -library PoC ../../PoC/common/utils.vhdl
read_vhdl -library PoC ../../PoC/common/strings.vhdl
read_vhdl -library PoC ../../PoC/common/vectors.vhdl
read_vhdl -library PoC ../../PoC/common/config.vhdl
read_vhdl -library PoC ../../PoC/common/physical.vhdl
read_vhdl -library PoC ../../PoC/ocram/ocram.pkg.vhdl
read_vhdl -library PoC ../../PoC/ocram/ocram_sdp.vhdl
read_vhdl -library PoC ../../PoC/fifo/fifo.pkg.vhdl
read_vhdl -library PoC ../../PoC/fifo/fifo_glue.vhdl
read_vhdl -library PoC ../../PoC/fifo/fifo_cc_got.vhdl
read_vhdl -library PoC ../../PoC/fifo/fifo_ic_got.vhdl
read_vhdl ../../queens/msg_tap.vhdl
read_vhdl ../../queens/msg_funnel.vhdl
read_vhdl ../../queens/expand_blocking.vhdl
read_vhdl ../../queens/xilinx/arbit_forward.vhdl
read_vhdl ../../queens/queens_slice.vhdl
read_vhdl ../../queens/queens_chain.vhdl
read_vhdl ${TOP}.vhdl

synth_design -top $TOP -part $PART

# Clocks
set MBCLK_PERIOD       20.000
create_clock -name CLK_MBCLK  -period $MBCLK_PERIOD [get_ports CLK_MBCLK]
set FASTEST_CLK_PERIOD 4.545

# Cross-Clock FIFOs
set_max_delay  -datapath_only -from [get_pins -hier -filter {NAME =~ *IPz_reg*/Q}] -to [get_pins -hier -filter {NAME =~ *IPs_reg*/D}] $FASTEST_CLK_PERIOD
set_false_path -hold          -from [get_pins -hier -filter {NAME =~ *IPz_reg*/Q}] -to [get_pins -hier -filter {NAME =~ *IPs_reg*/D}]
set_max_delay  -datapath_only -from [get_pins -hier -filter {NAME =~ *OP0_reg*/Q}] -to [get_pins -hier -filter {NAME =~ *OPs_reg*/D}] $FASTEST_CLK_PERIOD
set_false_path -hold          -from [get_pins -hier -filter {NAME =~ *OP0_reg*/Q}] -to [get_pins -hier -filter {NAME =~ *OPs_reg*/D}]

# Chip ID
#set_false_path -through                   [get_nets  {CHIPID[*]}]
#set_property IOSTANDARD LVCMOS18          [get_ports {CHIPID[*]}]
#set_property PACKAGE_PIN C24              [get_ports {CHIPID[0]}]
#set_property PACKAGE_PIN D21              [get_ports {CHIPID[1]}]
#set_property PACKAGE_PIN C22              [get_ports {CHIPID[2]}]

# Bank 13 (incoming ring bus)
set_property INTERNAL_VREF 0.75           [get_iobanks 13]
set_property SLEW FAST                    [get_ports {BUS_IN_*}]
set_property IOSTANDARD SSTL15            [get_ports {BUS_IN_*T*}]
set_property IOSTANDARD DIFF_HSTL_I       [get_ports {BUS_IN_CLK*}]

set_property PACKAGE_PIN N16              [get_ports {BUS_IN_PRE_DAT[0]}]
set_property PACKAGE_PIN K25              [get_ports {BUS_IN_PRE_DAT[1]}]
set_property PACKAGE_PIN K26              [get_ports {BUS_IN_PRE_DAT[2]}]
set_property PACKAGE_PIN R26              [get_ports {BUS_IN_PRE_DAT[3]}]
set_property PACKAGE_PIN P26              [get_ports {BUS_IN_PRE_DAT[4]}]
set_property PACKAGE_PIN M25              [get_ports {BUS_IN_PRE_DAT[5]}]
set_property PACKAGE_PIN L25              [get_ports {BUS_IN_PRE_DAT[6]}]
set_property PACKAGE_PIN P24              [get_ports {BUS_IN_PRE_DAT[7]}]
set_property PACKAGE_PIN N24              [get_ports {BUS_IN_PRE_DAT[8]}]
set_property PACKAGE_PIN N26              [get_ports {BUS_IN_PRE_PUT}]
set_property PACKAGE_PIN M26              [get_ports {BUS_IN_PRE_STALL}]

set_property PACKAGE_PIN R25              [get_ports {BUS_IN_SOL_DAT[0]}]
set_property PACKAGE_PIN P25              [get_ports {BUS_IN_SOL_DAT[1]}]
set_property PACKAGE_PIN N19              [get_ports {BUS_IN_SOL_DAT[2]}]
set_property PACKAGE_PIN M20              [get_ports {BUS_IN_SOL_DAT[3]}]
set_property PACKAGE_PIN M24              [get_ports {BUS_IN_SOL_DAT[4]}]
set_property PACKAGE_PIN L24              [get_ports {BUS_IN_SOL_DAT[5]}]
set_property PACKAGE_PIN P19              [get_ports {BUS_IN_SOL_DAT[6]}]
set_property PACKAGE_PIN P20              [get_ports {BUS_IN_SOL_DAT[7]}]
set_property PACKAGE_PIN M21              [get_ports {BUS_IN_SOL_DAT[8]}]
set_property PACKAGE_PIN M22              [get_ports {BUS_IN_SOL_PUT}]
set_property PACKAGE_PIN P23              [get_ports {BUS_IN_SOL_STALL}]

set_property PACKAGE_PIN N21              [get_ports BUS_IN_CLKP]
set_property PACKAGE_PIN N22              [get_ports BUS_IN_CLKN]

# Bank 16 (outgoing ring bus)
set_property INTERNAL_VREF 0.75           [get_iobanks 16]
set_property SLEW FAST                    [get_ports {BUS_OUT_*}]
set_property IOSTANDARD LVCMOS15          [get_ports {BUS_OUT_*T*}]
set_property DRIVE 8                      [get_ports {BUS_OUT_*T*}]
set_property IOSTANDARD DIFF_HSTL_I       [get_ports {BUS_OUT_CLK*}]

set_property PACKAGE_PIN B9               [get_ports {BUS_OUT_PRE_DAT[0]}]
set_property PACKAGE_PIN D9               [get_ports {BUS_OUT_PRE_DAT[1]}]
set_property PACKAGE_PIN C9               [get_ports {BUS_OUT_PRE_DAT[2]}]
set_property PACKAGE_PIN J14              [get_ports {BUS_OUT_PRE_DAT[3]}]
set_property PACKAGE_PIN F12              [get_ports {BUS_OUT_PRE_DAT[4]}]
set_property PACKAGE_PIN G10              [get_ports {BUS_OUT_PRE_DAT[5]}]
set_property PACKAGE_PIN E13              [get_ports {BUS_OUT_PRE_DAT[6]}]
set_property PACKAGE_PIN D13              [get_ports {BUS_OUT_PRE_DAT[7]}]
set_property PACKAGE_PIN J8               [get_ports {BUS_OUT_PRE_DAT[8]}]
set_property PACKAGE_PIN H11              [get_ports {BUS_OUT_PRE_PUT}]
set_property PACKAGE_PIN F13              [get_ports {BUS_OUT_PRE_STALL}]

set_property PACKAGE_PIN J13              [get_ports {BUS_OUT_SOL_DAT[0]}]
set_property PACKAGE_PIN G12              [get_ports {BUS_OUT_SOL_DAT[1]}]
set_property PACKAGE_PIN D11              [get_ports {BUS_OUT_SOL_DAT[2]}]
set_property PACKAGE_PIN B15              [get_ports {BUS_OUT_SOL_DAT[3]}]
set_property PACKAGE_PIN D14              [get_ports {BUS_OUT_SOL_DAT[4]}]
set_property PACKAGE_PIN B14              [get_ports {BUS_OUT_SOL_DAT[5]}]
set_property PACKAGE_PIN F8               [get_ports {BUS_OUT_SOL_DAT[6]}]
set_property PACKAGE_PIN G9               [get_ports {BUS_OUT_SOL_DAT[7]}]
set_property PACKAGE_PIN C14              [get_ports {BUS_OUT_SOL_DAT[8]}]
set_property PACKAGE_PIN A13              [get_ports {BUS_OUT_SOL_PUT}]
set_property PACKAGE_PIN J11              [get_ports {BUS_OUT_SOL_STALL}]

set_property PACKAGE_PIN C12              [get_ports BUS_OUT_CLKP]
set_property PACKAGE_PIN C11              [get_ports BUS_OUT_CLKN]


set_property IOSTANDARD LVCMOS18          [get_ports CLK_MBCLK]
set_property PACKAGE_PIN G24              [get_ports CLK_MBCLK]

# Platform
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]

opt_design -retarget -propconst -sweep
place_design -directive Explore
report_utilization
route_design -directive Explore
report_drc
report_utilization
report_timing -setup -hold -max_paths 3 -nworst 3 -input_pins -sort_by group -file  $TOP.twr
report_timing_summary -delay_type min_max -path_type full_clock_expanded -report_unconstrained -check_timing_verbose -max_paths 3 -nworst 3 -significant_digits 3 -input_pins -file $TOP.twr

if {! [string match -nocase {*timing constraints are met*} [report_timing_summary -no_header -no_detailed_paths -return_string]] } {
  puts  {Timing was NOT met!}
  exit 2
}

set_property BITSTREAM.GENERAL.COMPRESS true [current_design]
write_bitstream -force $TOP.bit

quit
