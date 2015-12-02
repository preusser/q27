// ################################################################
// $Header: /var/lib/cvs/dncvs/FPGA/dini/pcie/pcie_dma/user_fpga/pcie_defines.v,v 1.1 2009/10/27 21:10:51 bpoladian Exp $
// ################################################################
// Description:
//  This includes defines needed for the pcie_user_interface.
// ################################################################
// $Log: pcie_defines.v,v $
// Revision 1.1  2009/10/27 21:10:51  bpoladian
// Moved to new folder.
//
// Revision 1.1  2009/10/22 18:26:46  bpoladian
// Initial Revision
//
// ################################################################


// ################################################################
// Users:  DO NOT CHANGE THESE VALUES.  THESE VALUES ARE USED IN THE PCI-E FPGA DESIGN.
// THESE VALUES MUST ONLY BE CHANGED BY THE DINI GROUP.
// ################################################################

`ifdef INCL_PCIE_X8_DEFINES_V
`else
`define INCL_PCIE_X8_DEFINES_V


`define FH_ADDR_ADDRESS_RANGE   31:0
// tag instead of address when completion:
`define FH_ADDR_HEADER_TAG_RANGE 15:8
`define FH_ADDR_FIRST_BE_RANGE  35:32
`define FH_ADDR_LAST_BE_RANGE   39:36
`define FH_ADDR_LENGTH_RANGE    49:40
`define FH_ADDR_EP_BIT          50
`define FH_ADDR_TD_BIT          51
`define FH_ADDR_BAR_HIT_RANGE   55:52
`define FH_ADDR_BAR0_HIT_BIT    52
`define FH_ADDR_TAG_RANGE       59:56
`define FH_ADDR_RD_NWR_BIT      60
`define FH_ADDR_MEM_ACCESS_BIT  61
`define FH_ADDR_CMPL_ACCESS_BIT 62
`define FH_ADDR_BAR_HIT_ROM_BIT 63

`define REG_DEMANDMODE_DMA0_ADDR        'h0
`define REG_DEMANDMODE_DMA0_CONTROL     'h1
`define REG_DEMANDMODE_DMA0_TESTSIZE    'h3
`define REG_DEMANDMODE_DMA0_DEBUGSTATUS 'h5
`define REG_DEMANDMODE_ID               'h4

`define REG_DEMANDMODE_DMA1_ADDR        'h6
`define REG_DEMANDMODE_DMA1_CONTROL     'h7
`define REG_DEMANDMODE_DMA1_TESTSIZE    'h8
`define REG_DEMANDMODE_DMA1_DEBUGSTATUS 'h9

`define REG_DEMANDMODE_DMA2_ADDR        'hA
`define REG_DEMANDMODE_DMA2_CONTROL     'hB
`define REG_DEMANDMODE_DMA2_TESTSIZE    'hC
`define REG_DEMANDMODE_DMA2_DEBUGSTATUS 'hD


`endif // INCL_PCIE_X8_DEFINES_V
