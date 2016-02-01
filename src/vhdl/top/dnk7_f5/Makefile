.PHONY: default clean clobber


default:
	$(MAKE) dnk7_queens0.bit dnk7_queens1.bit

# Include Dependencies
-include $(basename $(MAKECMDGOALS)).dep

%.dep: %.tcl
	@set -e; \
	sed -ne's/^set \+TOP \+\(.*\)$$/TOP := \1/p' $< >$@; \
	echo -n '$*.bit: ' >>$@; \
	sed -ne's/^read_vhdl \(-library [A-Za-z_]\+ \)\?\(.*\)$$/\2/p' $< | tr '{}\n' '() ' >>$@; \
	echo >>$@

%.bit: %.tcl %.vhdl
	mkdir -p $*.tmp/ && \
	vivado -mode tcl -source $< -nojournal -log $*.log -tempDir $*.tmp/

clean:
	rm -rf .Xil *.dep

clobber: clean
	rm -rf *.twr *.bit fsm_encoding.os *~
