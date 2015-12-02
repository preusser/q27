.PHONY: default clean clobber


default: dnk7_fpga0.bit

%.bit: %.tcl %.vhdl
	vivado -mode tcl -source $< && rm -rf vivado?*.log  vivado?*.jou

clean:
	rm -rf .Xil vivado*.log vivado*.jou

clobber: clean
	rm -rf *.twr *.bit *~
