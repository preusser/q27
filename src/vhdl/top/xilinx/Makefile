XFLOW     ?= xflow      # Provide path manually if not in your $PATH
DEFAULT   := queens_loop
MAKEFLAGS += --silent

.PHONY: default sim

# Default Target
default:
	$(MAKE) $(DEFAULT).bit

# Include Dependencies
-include $(basename $(MAKECMDGOALS)).dep

# Generation of Dependencies
%.dep: %.prj
	@set -e; \
        sed -ne's/^\# Device: \(.*\)$$/DEVICE := \1/p' $< > $@; \
        sed -ne's/^\# Top: \(.*\)$$/TOPLEVEL := \1/p' $< >> $@; \
        echo -n '$*.ngc: ' >>$@; \
        sed -ne's/^vhdl \w\+ "\(.*\)"$$/\1/p' $< | tr '\n' ' ' >>$@; \
        echo >>$@

# Bitfile from a placed and routed Netlist
%.bit: %.ncd bitgen.opt fpga.flw
	$(XFLOW) -config bitgen.opt $<

# Place and route Netlist
%.ncd: %.ngc %.ucf high_effort.opt fpga.flw
	$(XFLOW) -p $(DEVICE) -g ucf:$*.ucf -implement high_effort.opt $<

# Generate Netlist from Project
%.ngc: %.prj xst.opt fpga.flw
	$(XFLOW) -p $(DEVICE) -g toplevel:$(TOPLEVEL) -synth xst.opt $<

# Missing flow files
%.flw %.opt:
	if [ ! -f "$@" ]; then echo "Missing flow file: '$@'."; exit 1; fi

stty:
	stty -F /dev/ttyUSB0 115200 raw -cstopb -parenb -crtscts -echo -ixon -ixoff

sim:
	ghdl -a --work=PoC common/my_config_S3SK1000.vhdl common/utils.vhdl common/strings.vhdl \
			   common/vectors.vhdl common/board.vhdl common/config.vhdl \
			   ocram/ocram.pkg.vhdl ocram/ocram_sdp.vhdl \
			   fifo/fifo.pkg.vhdl fifo/fifo_glue.vhdl fifo/fifo_cc_got_tempput.vhdl \
			   uart/uart.pkg.vhdl uart/uart_bclk.vhdl uart/uart_[rt]x.vhdl
	ghdl -a -P. enframe.vhdl unframe.vhdl eunframe_tb.vhdl
	ghdl -e -P. --syn-binding eunframe_tb
	ghdl -a -P. frame_loop.vhdl
