#Contents

The hardware implementation is composed from:

1. [PoC/](PoC/): building blocks provided through the [PoC Library](https://github.com/VLSI-EDA/PoC),
2. [queens/](queens/) task-specific circuitry, and
3. [top/](top/) board-specific top-level modules.

Currently, top-level modules are available for several prototyping boards
with Xilinx devices. Depending on the interfaces provided by the board,
the communication with the host PC is conducted via a physical RS232 UART
or a USB UART. This requires a minimal amount of logic for external
communication. GbE or PCIe communication can be made available to make
large devices accessible.

#Requirements

The generation of hardware configuration files, typically known as bitfiles, requires
an appropriate synthesis tool supporting VHDL input. The flow provided through the
included Makefiles assumes the vendor tools that typically ship with the corresponding
board hardware:

1. xflow out of the ISE suite for Xilinx devices up to generation 6.
2. Vivado for Xilinx devices starting at generation 7.
3. Quartus II for Altera devices.
