QCMD      ?= qcmd      # Provide path manually if not in your $PATH
MAKEFLAGS += --silent

.PHONY: default

# Default Target
default:
	echo Available Targets:; \
	for i in *.qpf; do echo -e "\t$$(basename $$i .qpf).sof"; done; echo

%.sof: %.qpf %.qsf %.vhdl %.sdc
	$(QCMD) $<
