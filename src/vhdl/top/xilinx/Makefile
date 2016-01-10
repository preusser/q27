XFLOW     ?= xflow      # Provide path manually if not in your $PATH
MAKEFLAGS += --silent

.PHONY: default

# Default Target
default:
	echo Available Targets:; \
	for i in *.prj; do echo -e "\t$$(basename $$i .prj).bit"; done; \
	for i in *.tcl; do echo -e "\t$$(basename $$i .tcl).bit"; done; echo

# Include Dependencies
-include $(basename $(MAKECMDGOALS)).dep

#############################################################################
# Vivado flow for Gen-7 (is triggered by presence of TCL file)

%.dep: %.tcl
	@set -e; \
	sed -ne's/^set \+TOP \+\(.*\)$$/TOP := \1/p' $< >$@; \
	echo -n '$*.bit: ' >>$@; \
	sed -ne's/^read_vhdl \(-library [A-Za-z_]\+ \)\?\(.*\)$$/\2/p' $< | tr '{}\n' '() ' >>$@; \
	echo >>$@

%.bit: %.tcl %.vhdl
	mkdir -p $*.tmp/ && \
	vivado -mode tcl -source $< -nojournal -log $*.log -tempDir $*.tmp/

#############################################################################
# xflow for Gen-6 and older

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
