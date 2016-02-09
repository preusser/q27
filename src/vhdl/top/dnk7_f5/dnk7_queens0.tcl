set TOP dnk7_queens0
set PART xc7k325t-1-ffg900
read_verilog dini/pcie/pcie_dma/user_fpga/pcie_ddr_user_interface.v

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
read_vhdl -library PoC ../../PoC/fifo/fifo_cc_got_tempput.vhdl
read_vhdl ../../queens/unframe.vhdl
read_vhdl ../../queens/enframe.vhdl
read_vhdl ../../queens/msg_tap.vhdl
read_vhdl ../../queens/msg_funnel.vhdl
read_vhdl ../../queens/expand_blocking.vhdl
read_vhdl ../../queens/xilinx/arbit_forward.vhdl
read_vhdl ../../queens/queens_slice.vhdl
read_vhdl ../../queens/queens_chain.vhdl
read_vhdl ${TOP}.vhdl

synth_design -top $TOP -part $PART \
  -include_dirs "." \
  -verilog_define KINTEX_7

# Clocks
set PCIECLK_PERIOD      6.000
create_clock -add -name BUS_PCIE_CLK_IN_P -period $PCIECLK_PERIOD [get_ports BUS_PCIE_CLK_IN_P]
set MBCLK_PERIOD       20.000
create_clock -name CLK_MBCLK  -period $MBCLK_PERIOD [get_ports CLK_MBCLK]
set FASTEST_CLK_PERIOD  4.545

# Cross-Clock FIFOs
set_max_delay  -datapath_only -from [get_pins -hier -filter {NAME =~ *IPz_reg*/Q}] -to [get_pins -hier -filter {NAME =~ *IPs_reg*/D}] $FASTEST_CLK_PERIOD
set_false_path -hold          -from [get_pins -hier -filter {NAME =~ *IPz_reg*/Q}] -to [get_pins -hier -filter {NAME =~ *IPs_reg*/D}]
set_max_delay  -datapath_only -from [get_pins -hier -filter {NAME =~ *OP0_reg*/Q}] -to [get_pins -hier -filter {NAME =~ *OPs_reg*/D}] $FASTEST_CLK_PERIOD
set_false_path -hold          -from [get_pins -hier -filter {NAME =~ *OP0_reg*/Q}] -to [get_pins -hier -filter {NAME =~ *OPs_reg*/D}]

# Bank 18 (incoming ring bus)
set_property INTERNAL_VREF 0.75           [get_iobanks 18]
set_property SLEW FAST                    [get_ports {BUS_IN_*}]
set_property IOSTANDARD SSTL15            [get_ports {BUS_IN_*T*}]
set_property IOSTANDARD DIFF_HSTL_I       [get_ports {BUS_IN_CLK*}]

set_property PACKAGE_PIN J11              [get_ports {BUS_IN_PRE_DAT[0]}]
set_property PACKAGE_PIN L16              [get_ports {BUS_IN_PRE_DAT[1]}]
set_property PACKAGE_PIN H11              [get_ports {BUS_IN_PRE_DAT[2]}]
set_property PACKAGE_PIN B13              [get_ports {BUS_IN_PRE_DAT[3]}]
set_property PACKAGE_PIN F12              [get_ports {BUS_IN_PRE_DAT[4]}]
set_property PACKAGE_PIN F16              [get_ports {BUS_IN_PRE_DAT[5]}]
set_property PACKAGE_PIN F11              [get_ports {BUS_IN_PRE_DAT[6]}]
set_property PACKAGE_PIN J14              [get_ports {BUS_IN_PRE_DAT[7]}]
set_property PACKAGE_PIN H16              [get_ports {BUS_IN_PRE_DAT[8]}]
set_property PACKAGE_PIN E14              [get_ports {BUS_IN_PRE_PUT}]
set_property PACKAGE_PIN E13              [get_ports {BUS_IN_PRE_STALL}]

set_property PACKAGE_PIN A15              [get_ports {BUS_IN_SOL_DAT[0]}]
set_property PACKAGE_PIN C15              [get_ports {BUS_IN_SOL_DAT[1]}]
set_property PACKAGE_PIN H14              [get_ports {BUS_IN_SOL_DAT[2]}]
set_property PACKAGE_PIN B12              [get_ports {BUS_IN_SOL_DAT[3]}]
set_property PACKAGE_PIN A11              [get_ports {BUS_IN_SOL_DAT[4]}]
set_property PACKAGE_PIN C12              [get_ports {BUS_IN_SOL_DAT[5]}]
set_property PACKAGE_PIN K15              [get_ports {BUS_IN_SOL_DAT[6]}]
set_property PACKAGE_PIN J16              [get_ports {BUS_IN_SOL_DAT[7]}]
set_property PACKAGE_PIN A12              [get_ports {BUS_IN_SOL_DAT[8]}]
set_property PACKAGE_PIN L15              [get_ports {BUS_IN_SOL_PUT}]
set_property PACKAGE_PIN E15              [get_ports {BUS_IN_SOL_STALL}]

set_property PACKAGE_PIN G13              [get_ports BUS_IN_CLKP]
set_property PACKAGE_PIN F13              [get_ports BUS_IN_CLKN]

# Bank 12 (outgoing ring bus)
set_property INTERNAL_VREF 0.75           [get_iobanks 12]
set_property SLEW FAST                    [get_ports {BUS_OUT_*}]
set_property IOSTANDARD LVCMOS15          [get_ports {BUS_OUT_*T*}]
set_property DRIVE 8                      [get_ports {BUS_OUT_*T*}]
set_property IOSTANDARD DIFF_HSTL_I       [get_ports {BUS_OUT_CLK*}]

set_property PACKAGE_PIN AE23             [get_ports {BUS_OUT_PRE_DAT[0]}]
set_property PACKAGE_PIN Y23              [get_ports {BUS_OUT_PRE_DAT[1]}]
set_property PACKAGE_PIN Y24              [get_ports {BUS_OUT_PRE_DAT[2]}]
set_property PACKAGE_PIN AF21             [get_ports {BUS_OUT_PRE_DAT[3]}]
set_property PACKAGE_PIN AE21             [get_ports {BUS_OUT_PRE_DAT[4]}]
set_property PACKAGE_PIN Y21              [get_ports {BUS_OUT_PRE_DAT[5]}]
set_property PACKAGE_PIN AA22             [get_ports {BUS_OUT_PRE_DAT[6]}]
set_property PACKAGE_PIN AD22             [get_ports {BUS_OUT_PRE_DAT[7]}]
set_property PACKAGE_PIN AA20             [get_ports {BUS_OUT_PRE_DAT[8]}]
set_property PACKAGE_PIN AB24             [get_ports {BUS_OUT_PRE_PUT}]
set_property PACKAGE_PIN Y20              [get_ports {BUS_OUT_PRE_STALL}]

set_property PACKAGE_PIN AF20             [get_ports {BUS_OUT_SOL_DAT[0]}]
set_property PACKAGE_PIN AD21             [get_ports {BUS_OUT_SOL_DAT[1]}]
set_property PACKAGE_PIN AC24             [get_ports {BUS_OUT_SOL_DAT[2]}]
set_property PACKAGE_PIN AB22             [get_ports {BUS_OUT_SOL_DAT[3]}]
set_property PACKAGE_PIN AA21             [get_ports {BUS_OUT_SOL_DAT[4]}]
set_property PACKAGE_PIN AA23             [get_ports {BUS_OUT_SOL_DAT[5]}]
set_property PACKAGE_PIN AJ23             [get_ports {BUS_OUT_SOL_DAT[6]}]
set_property PACKAGE_PIN AJ24             [get_ports {BUS_OUT_SOL_DAT[7]}]
set_property PACKAGE_PIN AC25             [get_ports {BUS_OUT_SOL_DAT[8]}]
set_property PACKAGE_PIN AC22             [get_ports {BUS_OUT_SOL_PUT}]
set_property PACKAGE_PIN AC20             [get_ports {BUS_OUT_SOL_STALL}]

set_property PACKAGE_PIN AF22             [get_ports BUS_OUT_CLKP]
set_property PACKAGE_PIN AG23             [get_ports BUS_OUT_CLKN]

# PCIe Clock Constraints
set_input_delay -clock [get_clocks BUS_PCIE_CLK_IN_P]            -max [expr {-($PCIECLK_PERIOD/2-(-0.05))}] [get_ports BUS_PCIE_FROM_HOST*]
set_input_delay -clock [get_clocks BUS_PCIE_CLK_IN_P] -add_delay -max [expr {-($PCIECLK_PERIOD/2-(-0.05))}] [get_ports BUS_PCIE_FROM_HOST*] -clock_fall
set_input_delay -clock [get_clocks BUS_PCIE_CLK_IN_P] -add_delay -min [expr {-(2.85)}]                      [get_ports BUS_PCIE_FROM_HOST*]
set_input_delay -clock [get_clocks BUS_PCIE_CLK_IN_P] -add_delay -min [expr {-(2.85)}]                      [get_ports BUS_PCIE_FROM_HOST*] -clock_fall
set_property LOC MMCME2_ADV_X0Y5 [get_cells -hier -filter {NAME =~ *pcie/i_pcie_ddr_user_io/i_MMCM_K7}]

set PCIEDDR_RESET_C [get_pins -hier -filter {NAME =~  *pcie*reset*C }]
set PCIEDDR_RESYNCINT_CLR [get_pins -hier -filter {NAME =~ *pcie*i_resync_user_interrupt*CLR}]
if [llength $PCIEDDR_RESYNCINT_CLR] then {
  set_max_delay  -datapath_only -from $PCIEDDR_RESET_C -to $PCIEDDR_RESYNCINT_CLR $FASTEST_CLK_PERIOD
  set_false_path -hold          -from $PCIEDDR_RESET_C -to $PCIEDDR_RESYNCINT_CLR
}
set PCIEDDR_RESYNCRST [get_pins -hier -filter {NAME=~ *pcie/i_pcie_interface/i_rst_userclk/rst_out*PRE}]
if [llength $PCIEDDR_RESYNCRST] then {
  set_max_delay  -datapath_only -from $PCIEDDR_RESET_C -to $PCIEDDR_RESYNCRST $FASTEST_CLK_PERIOD
  set_false_path -hold          -from $PCIEDDR_RESET_C -to $PCIEDDR_RESYNCRST
}
set PCIE_TOASYNC_SRC [get_pins -hier -filter {NAME=~ *pcie/i_pcie_interface/*host*reg*/C}]
set PCIE_TOASYNC_DST [get_pins -hier -filter {NAME=~ *pcie/i_pcie_interface/*/i_fifo/i_fifo_blkram/gen_asynchronous.mem_reg/REGCEB}]
set_max_delay  -datapath_only -from $PCIE_TOASYNC_SRC -to $PCIE_TOASYNC_DST $FASTEST_CLK_PERIOD
set_false_path -hold          -from $PCIE_TOASYNC_SRC -to $PCIE_TOASYNC_DST

# Misc reference design features
set RESYNC_FROM0 [get_pins -hier -filter {NAME =~ *resync*data_wrclk*C}]
set RESYNC_TO0   [get_pins -hier -filter {NAME =~ *resync*rd_data*D}]
set RESYNC_FROM1 [get_pins -hier -filter {NAME =~ *resync*toggle_wr*C}]
set RESYNC_TO1   [get_pins -hier -filter {NAME =~ *resync*toggle_rd_meta*D}]
if {[llength $RESYNC_FROM0]} then {
  set_max_delay  -datapath_only -from $RESYNC_FROM0 -to $RESYNC_TO0 $FASTEST_CLK_PERIOD
  set_false_path -hold          -from $RESYNC_FROM0 -to $RESYNC_TO0
  set_max_delay  -datapath_only -from $RESYNC_FROM1 -to $RESYNC_TO1 $FASTEST_CLK_PERIOD
  set_false_path -hold          -from $RESYNC_FROM1 -to $RESYNC_TO1
}
set CDC_3FF [get_pins -hier -filter {NAME =~ *cdc_3ff*signal_meta*D}]
if {[llength $CDC_3FF]} then {
  set_false_path -through $CDC_3FF
}

set RESET_RESYNC_FROM [get_pins -hier -filter {NAME=~ *rst_in_dly*C}];
if {[llength $RESET_RESYNC_FROM]} then {
  set_max_delay  -datapath_only -from $RESET_RESYNC_FROM -to [get_pins -hier -filter {NAME=~ *rst_out*PRE}] $FASTEST_CLK_PERIOD
  set_false_path -hold          -from $RESET_RESYNC_FROM -to [get_pins -hier -filter {NAME=~ *rst_out*PRE}]
}

# Fix the Dini FIFO async clock domain change.
set read_addrgray_reg    [get_pins -hier -filter {NAME =~ *read_addrgray*C}]
set read_addrgray_m_reg  [get_pins -hier -filter {NAME =~ *read_addrgray_m*D}]
set write_addrgray_reg   [get_pins -hier -filter {NAME =~ *write_addrgray*C}]
set write_addrgray_m_reg [get_pins -hier -filter {NAME =~ *write_addrgray_m*D}]
set_max_delay  -datapath_only -from $read_addrgray_reg -to $read_addrgray_m_reg $FASTEST_CLK_PERIOD
set_false_path -hold          -from $read_addrgray_reg -to $read_addrgray_m_reg
set_max_delay  -datapath_only -from $write_addrgray_reg -to $write_addrgray_m_reg $FASTEST_CLK_PERIOD
set_false_path -hold          -from $write_addrgray_reg -to $write_addrgray_m_reg

if [llength [get_pins -hier -filter {NAME =~ *gen_async*i_fifo_selram*RAM*CLK}]] then {
  set_max_delay  -datapath_only -from [get_pins -hier -filter {NAME =~ *gen_async*i_fifo_selram*RAM*CLK}] $FASTEST_CLK_PERIOD
  set_false_path -hold          -from [get_pins -hier -filter {NAME =~ *gen_async*i_fifo_selram*RAM*CLK}]
}

set PCIEDDR_RESYNCINT_CLR [get_pins -hier -filter {NAME =~ *pcie*i_resync_user_interrupt*CLR}]
if [llength $PCIEDDR_RESYNCINT_CLR] then {
  set_max_delay  -datapath_only -from $PCIEDDR_RESET_C -to $PCIEDDR_RESYNCINT_CLR $FASTEST_CLK_PERIOD
  set_false_path -hold          -from $PCIEDDR_RESET_C -to $PCIEDDR_RESYNCINT_CLR
}
set PCIEDDR_RESYNCRST [get_pins -hier -filter {NAME=~ *pcie/i_pcie_interface/i_rst_userclk/rst_out*PRE}]
if [llength $PCIEDDR_RESYNCRST] then {
  set_max_delay  -datapath_only -from $PCIEDDR_RESET_C -to $PCIEDDR_RESYNCRST $FASTEST_CLK_PERIOD
  set_false_path -hold          -from $PCIEDDR_RESET_C -to $PCIEDDR_RESYNCRST
}

set_property IOSTANDARD LVCMOS18          [get_ports CLK_MBCLK]
set_property PACKAGE_PIN T25              [get_ports CLK_MBCLK]
set_property IOSTANDARD DIFF_HSTL_I_18    [get_ports {BUS_PCIE_CLK_*}]

set_property INTERNAL_VREF 0.9            [get_iobanks 14]
set_property DRIVE 8                      [get_ports {BUS_PCIE_TO_HOST*}]
set_property DRIVE 8                      [get_ports {BUS_PCIE_FROM_HOST*}]
set_property SLEW FAST                    [get_ports {BUS_PCIE_TO_HOST*}]
set_property SLEW FAST                    [get_ports {BUS_PCIE_FROM_HOST*}]
set_property IOSTANDARD LVCMOS18          [get_ports {BUS_PCIE_TO_HOST*}]
set_property IOSTANDARD LVCMOS18          [get_ports {BUS_PCIE_FROM_HOST*}]

set_property PACKAGE_PIN R28              [get_ports {BUS_PCIE_FROM_HOST[39]}]
set_property PACKAGE_PIN T30              [get_ports {BUS_PCIE_FROM_HOST[40]}]
set_property PACKAGE_PIN V30              [get_ports {BUS_PCIE_FROM_HOST[41]}]
set_property PACKAGE_PIN A17              [get_ports {BUS_PCIE_FROM_HOST[42]}]
set_property PACKAGE_PIN A18              [get_ports {BUS_PCIE_FROM_HOST[43]}]
set_property PACKAGE_PIN V27              [get_ports {BUS_PCIE_FROM_HOST[44]}]
set_property PACKAGE_PIN P29              [get_ports {BUS_PCIE_FROM_HOST[45]}]
set_property PACKAGE_PIN U20              [get_ports {BUS_PCIE_FROM_HOST[46]}]
set_property PACKAGE_PIN T28              [get_ports {BUS_PCIE_FROM_HOST[47]}]
set_property PACKAGE_PIN P28              [get_ports {BUS_PCIE_FROM_HOST[48]}]
set_property PACKAGE_PIN V25              [get_ports {BUS_PCIE_FROM_HOST[49]}]
set_property PACKAGE_PIN W23              [get_ports {BUS_PCIE_FROM_HOST[50]}]
set_property PACKAGE_PIN V24              [get_ports {BUS_PCIE_FROM_HOST[51]}]
set_property PACKAGE_PIN W24              [get_ports {BUS_PCIE_FROM_HOST[52]}]
set_property PACKAGE_PIN W22              [get_ports {BUS_PCIE_FROM_HOST[53]}]
set_property PACKAGE_PIN W19              [get_ports {BUS_PCIE_FROM_HOST[54]}]
set_property PACKAGE_PIN U22              [get_ports {BUS_PCIE_FROM_HOST[55]}]
set_property PACKAGE_PIN W26              [get_ports {BUS_PCIE_FROM_HOST[56]}]
set_property PACKAGE_PIN U19              [get_ports {BUS_PCIE_FROM_HOST[57]}]
set_property PACKAGE_PIN R30              [get_ports {BUS_PCIE_FROM_HOST[58]}]
set_property PACKAGE_PIN V29              [get_ports {BUS_PCIE_FROM_HOST[59]}]
set_property PACKAGE_PIN V22              [get_ports {BUS_PCIE_FROM_HOST[60]}]
set_property PACKAGE_PIN W21              [get_ports {BUS_PCIE_FROM_HOST[61]}]
set_property PACKAGE_PIN A16              [get_ports {BUS_PCIE_FROM_HOST[62]}]
set_property PACKAGE_PIN R26              [get_ports {BUS_PCIE_FROM_HOST[63]}]
set_property PACKAGE_PIN V21              [get_ports {BUS_PCIE_FROM_HOST[64]}]
set_property PACKAGE_PIN U23              [get_ports {BUS_PCIE_FROM_HOST[65]}]
set_property PACKAGE_PIN V20              [get_ports {BUS_PCIE_FROM_HOST[66]}]
set_property PACKAGE_PIN F22              [get_ports {BUS_PCIE_FROM_HOST[67]}]
set_property PACKAGE_PIN V19              [get_ports {BUS_PCIE_FROM_HOST[68]}]
set_property PACKAGE_PIN D22              [get_ports {BUS_PCIE_FROM_HOST[69]}]
set_property PACKAGE_PIN B20              [get_ports {BUS_PCIE_FROM_HOST[70]}]
set_property PACKAGE_PIN A20              [get_ports {BUS_PCIE_FROM_HOST[71]}]
set_property PACKAGE_PIN A21              [get_ports {BUS_PCIE_FROM_HOST[72]}]
set_property PACKAGE_PIN C21              [get_ports {BUS_PCIE_FROM_HOST[73]}]
set_property PACKAGE_PIN B19              [get_ports {BUS_PCIE_FROM_HOST[74]}]
set_property PACKAGE_PIN C22              [get_ports {BUS_PCIE_FROM_HOST[75]}]
set_property PACKAGE_PIN B22              [get_ports {BUS_PCIE_FROM_HOST[76]}]
set_property PACKAGE_PIN A22              [get_ports {BUS_PCIE_FROM_HOST[77]}]
set_property PACKAGE_PIN G22              [get_ports {BUS_PCIE_TO_HOST[0]}]
set_property PACKAGE_PIN H20              [get_ports {BUS_PCIE_TO_HOST[1]}]
set_property PACKAGE_PIN H21              [get_ports {BUS_PCIE_TO_HOST[2]}]
set_property PACKAGE_PIN E19              [get_ports {BUS_PCIE_TO_HOST[3]}]
set_property PACKAGE_PIN D19              [get_ports {BUS_PCIE_TO_HOST[4]}]
set_property PACKAGE_PIN D21              [get_ports {BUS_PCIE_TO_HOST[5]}]
set_property PACKAGE_PIN F21              [get_ports {BUS_PCIE_TO_HOST[6]}]
set_property PACKAGE_PIN R24              [get_ports {BUS_PCIE_TO_HOST[7]}]
set_property PACKAGE_PIN C17              [get_ports {BUS_PCIE_TO_HOST[8]}]
set_property PACKAGE_PIN E18              [get_ports {BUS_PCIE_TO_HOST[9]}]
set_property PACKAGE_PIN F18              [get_ports {BUS_PCIE_TO_HOST[10]}]
set_property PACKAGE_PIN J19              [get_ports {BUS_PCIE_TO_HOST[11]}]
set_property PACKAGE_PIN H22              [get_ports {BUS_PCIE_TO_HOST[12]}]
set_property PACKAGE_PIN E21              [get_ports {BUS_PCIE_TO_HOST[13]}]
set_property PACKAGE_PIN B17              [get_ports {BUS_PCIE_TO_HOST[14]}]
set_property PACKAGE_PIN G20              [get_ports {BUS_PCIE_TO_HOST[15]}]
set_property PACKAGE_PIN K19              [get_ports {BUS_PCIE_TO_HOST[16]}]
set_property PACKAGE_PIN U24              [get_ports {BUS_PCIE_TO_HOST[17]}]
set_property PACKAGE_PIN C16              [get_ports {BUS_PCIE_TO_HOST[18]}]
set_property PACKAGE_PIN K20              [get_ports {BUS_PCIE_TO_HOST[19]}]
set_property PACKAGE_PIN J18              [get_ports {BUS_PCIE_TO_HOST[20]}]
set_property PACKAGE_PIN C20              [get_ports {BUS_PCIE_TO_HOST[21]}]
set_property PACKAGE_PIN B18              [get_ports {BUS_PCIE_TO_HOST[22]}]
set_property PACKAGE_PIN U30              [get_ports {BUS_PCIE_TO_HOST[23]}]
set_property PACKAGE_PIN F17              [get_ports {BUS_PCIE_TO_HOST[24]}]
set_property PACKAGE_PIN G18              [get_ports {BUS_PCIE_TO_HOST[25]}]
set_property PACKAGE_PIN G17              [get_ports {BUS_PCIE_TO_HOST[26]}]
set_property PACKAGE_PIN G19              [get_ports {BUS_PCIE_TO_HOST[27]}]
set_property PACKAGE_PIN J17              [get_ports {BUS_PCIE_TO_HOST[28]}]
set_property PACKAGE_PIN L18              [get_ports {BUS_PCIE_TO_HOST[29]}]
set_property PACKAGE_PIN C19              [get_ports {BUS_PCIE_TO_HOST[30]}]
set_property PACKAGE_PIN D16              [get_ports {BUS_PCIE_TO_HOST[31]}]
set_property PACKAGE_PIN H17              [get_ports {BUS_PCIE_TO_HOST[32]}]
set_property PACKAGE_PIN L17              [get_ports {BUS_PCIE_TO_HOST[33]}]
set_property PACKAGE_PIN H19              [get_ports {BUS_PCIE_TO_HOST[34]}]
set_property PACKAGE_PIN K18              [get_ports {BUS_PCIE_TO_HOST[35]}]
set_property PACKAGE_PIN P27              [get_ports {BUS_PCIE_TO_HOST[36]}]
set_property PACKAGE_PIN P26              [get_ports {BUS_PCIE_TO_HOST[37]}]
set_property PACKAGE_PIN R29              [get_ports {BUS_PCIE_TO_HOST[38]}]

set_property PACKAGE_PIN F20              [get_ports BUS_PCIE_CLK_IN_P]
set_property PACKAGE_PIN E20              [get_ports BUS_PCIE_CLK_IN_N]
set_property PACKAGE_PIN D17              [get_ports BUS_PCIE_CLK_OUT_P]
set_property PACKAGE_PIN D18              [get_ports BUS_PCIE_CLK_OUT_N]

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
