set TOP  kc705_queens_uart
set PART xc7k325t-2-ffg900

read_vhdl -library PoC ../../PoC/common/my_config_KC705.vhdl
read_vhdl -library PoC ../../PoC/common/my_project.vhdl
read_vhdl -library PoC ../../PoC/common/utils.vhdl
read_vhdl -library PoC ../../PoC/common/strings.vhdl
read_vhdl -library PoC ../../PoC/common/vectors.vhdl
read_vhdl -library PoC ../../PoC/common/config.vhdl
read_vhdl -library PoC ../../PoC/common/physical.vhdl
read_vhdl -library PoC ../../PoC/common/components.vhdl
read_vhdl -library PoC ../../PoC/arith/arith_counter_free.vhdl
read_vhdl -library PoC ../../PoC/ocram/ocram.pkg.vhdl
read_vhdl -library PoC ../../PoC/ocram/ocram_sdp.vhdl
read_vhdl -library PoC ../../PoC/fifo/fifo.pkg.vhdl
read_vhdl -library PoC ../../PoC/fifo/fifo_glue.vhdl
read_vhdl -library PoC ../../PoC/fifo/fifo_cc_got.vhdl
read_vhdl -library PoC ../../PoC/fifo/fifo_cc_got_tempput.vhdl
read_vhdl -library PoC ../../PoC/uart/uart.pkg.vhdl
read_vhdl -library PoC ../../PoC/uart/uart_rx.vhdl
read_vhdl -library PoC ../../PoC/uart/uart_tx.vhdl
read_vhdl -library PoC ../../PoC/xilinx/xil.pkg.vhdl
read_vhdl -library PoC ../../PoC/xilinx/xil_SystemMonitor_Series7.vhdl
read_vhdl -library PoC ../../PoC/sync/sync.pkg.vhdl
read_vhdl -library PoC ../../PoC/sync/sync_Bits.vhdl
read_vhdl -library PoC ../../PoC/sync/sync_Bits_Xilinx.vhdl
read_vhdl -library PoC ../../PoC/io/io_TimingCounter.vhdl
read_vhdl -library PoC ../../PoC/io/io_PulseWidthModulation.vhdl
read_vhdl -library PoC ../../PoC/io/io_FrequencyCounter.vhdl
read_vhdl -library PoC ../../PoC/io/io_FanControl.vhdl
read_vhdl ../../queens/unframe.vhdl
read_vhdl ../../queens/enframe.vhdl
read_vhdl ../../queens/msg_tap.vhdl
read_vhdl ../../queens/msg_funnel.vhdl
read_vhdl ../../queens/expand_blocking.vhdl
read_vhdl ../../queens/xilinx/arbit_forward.vhdl
read_vhdl ../../queens/queens_slice.vhdl
read_vhdl ../../queens/queens_chain.vhdl
read_vhdl ../../queens/queens_uart.vhdl
read_vhdl ${TOP}.vhdl

synth_design -top $TOP -part $PART

# External Clock
create_clock -name CLK200 -period 5.0 [get_ports clk_p]
set_property IOSTANDARD  LVDS [get_ports {clk_?}]
set_property PACKAGE_PIN AD12 [get_ports clk_p]
set_property PACKAGE_PIN AD11 [get_ports clk_n]

# UART
set_property IOSTANDARD  LVCMOS25 [get_ports rx]
set_property PACKAGE_PIN M19      [get_ports rx]
set_property IOSTANDARD  LVCMOS25 [get_ports tx]
set_property PACKAGE_PIN K24      [get_ports tx]

set_property IOSTANDARD  LVCMOS25 [get_ports rts]
set_property PACKAGE_PIN K23      [get_ports rts]
set_property IOSTANDARD  LVCMOS25 [get_ports cts]
set_property PACKAGE_PIN L27      [get_ports cts]

# Fan
set_property IOSTANDARD  LVCMOS25 [get_ports FanControl_PWM]
set_property PACKAGE_PIN L26      [get_ports FanControl_PWM]

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
