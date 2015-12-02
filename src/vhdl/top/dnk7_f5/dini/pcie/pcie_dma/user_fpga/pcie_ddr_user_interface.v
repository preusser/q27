// **************************************************************************
// $Header: /var/lib/cvs/dncvs/FPGA/dini/pcie/pcie_dma/user_fpga/pcie_ddr_user_interface.v,v 1.23 2014/08/24 00:45:13 neal Exp $
// **************************************************************************
// Description:
//
//    Translation from the DDR interface to the parallel PCIe
//    interface.
// **************************************************************************
// $Log: pcie_ddr_user_interface.v,v $
// Revision 1.23  2014/08/24 00:45:13  neal
// Fixed some resets so that the mmcm_locked will propagate.
//
// Revision 1.22  2013/05/21 20:48:15  neal
// Added some parameters to optionally disable DMA engines (both frequency and size optimization).
//
// Revision 1.21  2013/05/09 20:34:40  bpoladian
// Fixed byte addressing comment.
//
// Revision 1.20  2012/08/08 22:13:26  neal
// Registered reset on the correct clock domains.
//
// Revision 1.19  2012/07/25 22:03:48  bpoladian
// Make user_interrupts a single bit.
//
// Revision 1.18  2012/07/23 22:43:20  bpoladian
// Added include.
//
// Revision 1.17  2012/07/23 20:42:05  bpoladian
// Add resync logic for user_interrupt.
//
// Revision 1.16  2012/07/20 01:43:44  bpoladian
// Pipelined user_interrupt.
//
// Revision 1.15  2011/08/23 22:59:19  bpoladian
// Added period parameter.
//
// Revision 1.14  2011/08/23 21:05:59  bpoladian
// Added reset_out port to match NMB module.
//
// Revision 1.13  2010/10/05 22:22:48  bpoladian
// Removed unused inverted clock ports.
//
// Revision 1.12  2010/10/05 22:20:38  bpoladian
// Made to/from clocking clearer.
//
// Revision 1.11  2010/10/01 02:12:12  bpoladian
// Move phase shift parameter to top level.
// Make sure valid is not asserted on empty FIFO.
//
// Revision 1.10  2010/09/14 18:48:30  bpoladian
// Added phase shift control signals.
//
// Revision 1.9  2010/05/18 21:05:26  bpoladian
// Made NUM_DMA_ENGINES constant to avoid confusion.
//
// Revision 1.8  2010/03/03 03:11:51  bpoladian
// Removed target_bar port.
//
// Revision 1.7  2010/02/22 19:00:54  bpoladian
// Updated ports.
//
// Revision 1.6  2010/01/28 23:24:54  bpoladian
// Brought out user clock.
//
// Revision 1.5  2010/01/22 04:27:59  bpoladian
// pcie_tohost_info now 5 bits.
//
// Revision 1.4  2010/01/20 19:23:02  bpoladian
// Removed second instantiation of user_interrupts.
//
// Revision 1.3  2010/01/15 22:50:50  subhasri
// fixed user_interrupts net connection
//
// Revision 1.2  2010/01/15 07:09:46  bpoladian
// Implemented 64-bit target accesses.
//
// Revision 1.1  2010/01/08 02:08:34  bpoladian
// Initial revision.
//
//
//
// **************************************************************************

`ifdef INCL_PCIE_DDR_USER_INTERFACE
`else
`define INCL_PCIE_DDR_USER_INTERFACE

`include "dini/pcie/pcie_dma/user_fpga/pcie_interface.v"
`include "dini/pcie/pcie_dma/user_fpga/pcie_ddr_user_io.v"
`include "dini/misc/resync.v"

module pcie_ddr_user_interface #(
  parameter DCM_PHASE_SHIFT     = 30,
  parameter DCM_PERIOD          = 10,
  parameter DMA_ENGINE_ENABLES  = 3'b111 // enable all DMA engines
) (
 // clocks, resets
   input         reset,
   output        reset_out,
   input         user_clk,     // user clock
   output        clk_out,      // main clock

   // DCM Control - tie inputs to 0 if unused
   output        dcm_psdone,
   output [16:0] dcm_psval,
   input         dcm_psclk,
   input         dcm_psen,
   input         dcm_psincdec,

   // to user, from_host, target signals
   output [63:0] target_address, // 32-bit-aligned byte address ([1:0]==2'b0)
   output [63:0] target_write_data,
   output [7:0]  target_write_be,
   output        target_address_valid,
   output        target_write_enable,
   input         target_write_accept,

   // to user, from_host, DMA0 signals
   output [63:0] dma0_from_host_data,
   output [7:0]  dma0_from_host_ctrl,
   output        dma0_from_host_valid,
   input         dma0_from_host_advance,

   // to user, from_host, DMA1 signals
   output [63:0] dma1_from_host_data,
   output [7:0]  dma1_from_host_ctrl,
   output        dma1_from_host_valid,
   input         dma1_from_host_advance,

   // to user, from_host, DMA2 signals
   output [63:0] dma2_from_host_data,
   output [7:0]  dma2_from_host_ctrl,
   output        dma2_from_host_valid,
   input         dma2_from_host_advance,

   // from user, to_host target signals
   output        target_read_enable,
   output [3:0]  target_request_tag,
   input  [63:0] target_read_data,
   input         target_read_accept,
   input  [3:0]  target_read_data_tag,
   input         target_read_data_valid,
   output [7:0]  target_read_ctrl,
   input  [7:0]  target_read_data_ctrl,

   // from user, to_host DMA0 signals
   input [63:0]  dma0_to_host_data,
   input  [7:0]  dma0_to_host_ctrl,
   input         dma0_to_host_valid,
   output        dma0_to_host_almost_full,

   // from user, to_host DMA1 signals
   input [63:0]  dma1_to_host_data,
   input  [7:0]  dma1_to_host_ctrl,
   input         dma1_to_host_valid,
   output        dma1_to_host_almost_full,

   // from user, to_host DMA2 signals
   input [63:0]  dma2_to_host_data,
   input  [7:0]  dma2_to_host_ctrl,
   input         dma2_to_host_valid,
   output        dma2_to_host_almost_full,

   input         user_interrupts,
   output [31:0] pcie_fromhost_counter,

  // Physical interface to/from ConfigFPGA
  output [38:0] PCIE_TO_HOST_DDR,
  output        PCIE_TO_HOST_CLK_P,
  output        PCIE_TO_HOST_CLK_N,

  input  [37:0] PCIE_FROM_HOST_DDR,
  input         PCIE_FROM_HOST_CLK_P,
  input         PCIE_FROM_HOST_CLK_N
);

reg reset_clkout;
wire reset_clk_out;
assign reset_out = reset | reset_clkout;


wire [63:0]               pcie_fromhost_data;
wire [3:0]                pcie_fromhost_transaction_type;
wire [1:0]                pcie_fromhost_isaddress;
wire [1:0]                pcie_fromhost_info;
wire [1:0]                pcie_fromhost_valid;
wire [3:0]                pcie_fromhost_almost_full;

wire [63:0]               pcie_tohost_data;
wire [3:0]                pcie_tohost_transaction_type;
wire [4:0]                pcie_tohost_info;
wire [1:0]                pcie_tohost_valid;
wire [3:0]                pcie_tohost_almost_full;

reg  user_interrupt;
reg  user_interrupt_d;
wire user_interrupt_resync;


reg reset_userclk;

always @(posedge user_clk or posedge reset) begin
	if (reset) begin
		reset_userclk <= 1'b1;
	end else begin
		reset_userclk <= 1'b0;
	end
end

always @(posedge clk_out or posedge reset_clk_out) begin
	if (reset_clk_out) begin
		reset_clkout <= 1'b1;
	end else begin
		reset_clkout <= 1'b0;
	end
end

always @ (posedge user_clk or posedge reset_userclk) begin
  if (reset_userclk) begin
    user_interrupt   <= 'b0;
    user_interrupt_d <= 'b0;
  end else begin
    user_interrupt   <= |user_interrupts;
    user_interrupt_d <= user_interrupt;
  end
end
resync #(
  .DATA_SIZE(1)
) i_resync_user_interrupt (
  .rst       (reset_userclk),

  .wr_clk    (user_clk),
  .wr_pulse  (user_interrupt ^ user_interrupt_d),
  .wr_data   (user_interrupt),

  .rd_clk    (clk_out),
  .rd_pulse  (),
  .rd_data   (user_interrupt_resync)
);

pcie_interface #(
  .NUM_DMA_ENGINES(3),
  .DMA_ENGINE_ENABLES(DMA_ENGINE_ENABLES)
) i_pcie_interface (
   .clk                            (clk_out),
   .reset                          (reset_clkout),

   .user_clk                       (user_clk),

   .pcie_fromhost_data             (pcie_fromhost_data),
   .pcie_fromhost_transaction_type (pcie_fromhost_transaction_type),
   .pcie_fromhost_isaddress        (pcie_fromhost_isaddress),
   .pcie_fromhost_info             (pcie_fromhost_info),
   .pcie_fromhost_valid            (pcie_fromhost_valid),
   .pcie_fromhost_almost_full      (pcie_fromhost_almost_full),

   .pcie_tohost_data               (pcie_tohost_data),
   .pcie_tohost_transaction_type   (pcie_tohost_transaction_type),
   .pcie_tohost_info               (pcie_tohost_info),
   .pcie_tohost_valid              (pcie_tohost_valid),
   .pcie_tohost_almost_full        (pcie_tohost_almost_full),

   .target_address                 (target_address),
   .target_write_data              (target_write_data),
   .target_write_be                (target_write_be),
   .target_address_valid           (target_address_valid),
   .target_write_enable            (target_write_enable),
   .target_write_accept            (target_write_accept),

   .debug_target_bar               (),

   .dma0_from_host_data            (dma0_from_host_data),
   .dma0_from_host_ctrl            (dma0_from_host_ctrl),
   .dma0_from_host_valid           (dma0_from_host_valid),
   .dma0_from_host_advance         (dma0_from_host_advance),

   .dma1_from_host_data            (dma1_from_host_data),
   .dma1_from_host_ctrl            (dma1_from_host_ctrl),
   .dma1_from_host_valid           (dma1_from_host_valid),
   .dma1_from_host_advance         (dma1_from_host_advance),

   .dma2_from_host_data            (dma2_from_host_data),
   .dma2_from_host_ctrl            (dma2_from_host_ctrl),
   .dma2_from_host_valid           (dma2_from_host_valid),
   .dma2_from_host_advance         (dma2_from_host_advance),

   .target_read_enable             (target_read_enable),
   .target_request_tag             (target_request_tag),
   .target_read_data               (target_read_data),
   .target_read_accept             (target_read_accept),
   .target_read_data_tag           (target_read_data_tag),
   .target_read_data_valid         (target_read_data_valid),
   .target_read_ctrl               (target_read_ctrl),
   .target_read_data_ctrl          (target_read_data_ctrl),

   .dma0_to_host_data              (dma0_to_host_data),
   .dma0_to_host_ctrl              (dma0_to_host_ctrl),
   .dma0_to_host_valid             (dma0_to_host_valid),
   .dma0_to_host_almost_full       (dma0_to_host_almost_full),

   .dma1_to_host_data              (dma1_to_host_data),
   .dma1_to_host_ctrl              (dma1_to_host_ctrl),
   .dma1_to_host_valid             (dma1_to_host_valid),
   .dma1_to_host_almost_full       (dma1_to_host_almost_full),

   .dma2_to_host_data              (dma2_to_host_data),
   .dma2_to_host_ctrl              (dma2_to_host_ctrl),
   .dma2_to_host_valid             (dma2_to_host_valid),
   .dma2_to_host_almost_full       (dma2_to_host_almost_full)
);


pcie_ddr_user_io #(
  .NUM_DMA_ENGINES                (3),
  .DCM_PHASE_SHIFT                (DCM_PHASE_SHIFT),
  .DCM_PERIOD                     (DCM_PERIOD)
) i_pcie_ddr_user_io (
  .pcie_from_host_clk             (clk_out),
  .pcie_from_host_clk_reset       (reset_clk_out),
  .pcie_to_host_clk               (clk_out),

  .ddr_reset                      (reset),

  .dcm_psdone                     (dcm_psdone),
  .dcm_psval                      (dcm_psval),
  .dcm_psclk                      (dcm_psclk),
  .dcm_psen                       (dcm_psen),
  .dcm_psincdec                   (dcm_psincdec),

  .pcie_fromhost_data             (pcie_fromhost_data),
  .pcie_fromhost_transaction_type (pcie_fromhost_transaction_type),
  .pcie_fromhost_isaddress        (pcie_fromhost_isaddress),
  .pcie_fromhost_info             (pcie_fromhost_info),
  .pcie_fromhost_valid            (pcie_fromhost_valid),
  .pcie_fromhost_almost_full      (pcie_fromhost_almost_full),


  .pcie_tohost_data               (pcie_tohost_data),
  .pcie_tohost_transaction_type   (pcie_tohost_transaction_type),
  .pcie_tohost_info               (pcie_tohost_info),
  .pcie_tohost_valid              (pcie_tohost_valid),
  .pcie_tohost_almost_full        (pcie_tohost_almost_full),
  .user_interrupt                 (user_interrupt_resync),
  .pcie_fromhost_counter          (pcie_fromhost_counter),

  .PCIE_TO_HOST_DDR               (PCIE_TO_HOST_DDR),
  .PCIE_TO_HOST_CLK_P             (PCIE_TO_HOST_CLK_P),
  .PCIE_TO_HOST_CLK_N             (PCIE_TO_HOST_CLK_N),

  .PCIE_FROM_HOST_DDR             (PCIE_FROM_HOST_DDR),
  .PCIE_FROM_HOST_CLK_P           (PCIE_FROM_HOST_CLK_P),
  .PCIE_FROM_HOST_CLK_N           (PCIE_FROM_HOST_CLK_N)
);

endmodule

`endif // INCL_PCIE_DDR_USER_INTERFACE
