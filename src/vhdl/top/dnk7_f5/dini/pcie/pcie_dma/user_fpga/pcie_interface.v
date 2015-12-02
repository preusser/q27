// ################################################################
// $Header: /var/lib/cvs/dncvs/FPGA/dini/pcie/pcie_dma/user_fpga/pcie_interface.v,v 1.57 2015/03/17 18:15:46 bpoladian Exp $
// ################################################################
// Description:
//  This module translates between the internal bus for NMB/PCIe Design
//  and an easy-to-understand Target/DMA interface for the user.
// ################################################################
// $Log: pcie_interface.v,v $
// Revision 1.57  2015/03/17 18:15:46  bpoladian
// Added simulation checks for demand-mode DMA byte enables and addressing.
//
// Revision 1.56  2015/03/12 19:37:14  bpoladian
// Use bit 0 of target_read_ctrl for BE logic.
//
// Revision 1.55  2015/03/12 19:35:32  bpoladian
// Use last_be for upper 32 bits of a 64-bit read.
//
// Revision 1.54  2014/09/09 20:15:01  neal
// Removed some debug registers.
//
// Revision 1.53  2014/09/02 23:25:26  neal
// Re-enabled some debug registers.
//
// Revision 1.52  2014/08/27 19:07:31  bpoladian
// Can now use fewer than 3 dma engines without compilation errors.
//
// Revision 1.51  2014/08/24 00:47:42  neal
// Fixed reset resync.
//
// Revision 1.50  2014/07/18 18:11:42  neal
// Adjusted some fifo parameters.
//
// Revision 1.49  2014/07/08 15:20:52  neal
// Used RAM's output register in async fifos.
//
// Revision 1.48  2014/07/01 22:47:42  neal
// Changed async fifo to having an output register.
//
// Revision 1.47  2014/05/01 20:21:00  neal
// Added a port to the fifo.
//
// Revision 1.46  2013/08/12 21:44:15  bpoladian
// Fixed almostfull output for unused DMA engines.
//
// Revision 1.45  2013/05/23 17:49:54  neal
// Really removed the FIFOs when a DMA engine isn't needed.
//
// Revision 1.44  2013/05/21 20:48:15  neal
// Added some parameters to optionally disable DMA engines (both frequency and size optimization).
//
// Revision 1.43  2013/05/16 00:19:08  bpoladian
// Fixed one-transfer-per-cycle for new DMA fifo.
//
// Revision 1.42  2013/05/09 20:34:40  bpoladian
// Fixed byte addressing comment.
//
// Revision 1.41  2013/04/22 22:06:31  bpoladian
// Use async_blk_reg FIFO to improve timing instead of using an extra pipeline stage for fromhost data/ctrl.
//
// Revision 1.40  2013/01/03 19:24:09  neal
// Made all 3 of the DMA engines not transfer data when a target access is in progress.
//
// Revision 1.39  2012/11/30 22:24:26  bpoladian
// Add option for limiting interface to one fromhost transfer per cycle.
//
// Revision 1.38  2012/11/06 00:38:37  bpoladian
// Use synthesis directive instead of define for simulation warning.
//
// Revision 1.37  2012/09/28 21:25:38  bpoladian
// Logicial inversion of logic.  Caused DMA to only advance when there was a target read instead of preventing DMA advance during a target read.
//
// Revision 1.36  2012/09/28 20:42:37  bpoladian
// Moved dma fromhost stall on target access one clock cycle earlier.
//
// Revision 1.35  2012/09/26 19:15:41  bpoladian
// Don't send DMA transactions on same cycle as target to make downstream muxing easier.
//
// Revision 1.34  2012/09/14 16:19:20  neal
// Fixed a vivado warning.
//
// Revision 1.33  2012/08/08 22:13:26  neal
// Registered reset on the correct clock domains.
//
// Revision 1.32  2012/07/25 22:03:48  bpoladian
// Make user_interrupts a single bit.
//
// Revision 1.31  2012/05/06 21:01:33  bpoladian
// Increased depth to fully utilize blockram.
//
// Revision 1.30  2012/03/20 18:36:35  bpoladian
// Reverted to large target fromhost FIFO due to latency of almostfull signal across NMB link.
//
// Revision 1.29  2012/03/19 21:20:36  bpoladian
// Reduced size/type of target fromhost FIFO.
//
// Revision 1.28  2012/03/19 17:45:14  bpoladian
// Change target tohost FIFO to small selectram FIFO.
//
// Revision 1.27  2012/01/19 19:29:29  neal
// Updated to a newer toe tx code base.
// Fixed synthesis warnings.
//
// Revision 1.26  2011/12/09 22:11:21  bpoladian
// Clear the read pending bit on timeout.
//
// Revision 1.25  2011/09/14 02:16:25  bpoladian
// Linted all assignment widths.
// Changed asynchronous always blocks to assign statements.
//
// Revision 1.24  2010/11/23 21:20:21  bpoladian
// Fixed bit width for unused DMA ctrl.
//
// Revision 1.23  2010/11/23 21:18:04  bpoladian
// Fixed bit width on dma_tohost_info.
//
// Revision 1.22  2010/10/14 18:20:29  bpoladian
// Fixed bug w/ multiple DMA streams writing simultaneously.
//
// Revision 1.21  2010/10/05 23:33:27  bpoladian
// Fixed case->casex.
//
// Revision 1.20  2010/10/05 22:20:10  bpoladian
// Cleaned up state transaction logic.
//
// Revision 1.19  2010/10/01 02:10:31  bpoladian
// Bigger FIFOs.
//
// Revision 1.18  2010/09/09 23:07:08  bpoladian
// Target read now prevents all updates on target interface while pending.
//
// Revision 1.17  2010/08/12 03:28:43  bpoladian
// Increase almostfull limit for return data.
//
// Revision 1.16  2010/07/01 02:20:23  bpoladian
// Fixed pipelining problem w/ back to back DMA transactions from separate engines.
//
// Revision 1.15  2010/06/11 17:47:00  jack
// display time in simulation debug messg
//
// Revision 1.14  2010/03/15 23:54:57  bpoladian
// Fixed alignment/handling of valid, transaction_type, and read_en.
//
// Revision 1.13  2010/03/12 00:55:55  bpoladian
// Higher almostfull limits.
//
// Revision 1.12  2010/03/11 04:46:13  bpoladian
// Fixed DMA2 almostfull bug.
//
// Revision 1.11  2010/03/03 03:11:51  bpoladian
// Removed target_bar port.
//
// Revision 1.10  2010/01/22 04:27:59  bpoladian
// pcie_tohost_info now 5 bits.
//
// Revision 1.9  2010/01/20 19:24:08  bpoladian
// Split hiaddr register into bar-specific registers.
//
// Revision 1.8  2010/01/19 01:02:34  bpoladian
// Fixed almost_full dma flags.
//
// Revision 1.7  2010/01/15 07:09:46  bpoladian
// Implemented 64-bit target accesses.
//
// Revision 1.6  2010/01/13 21:10:06  bpoladian
// Fixed info/ctrl signals.
//
// Revision 1.5  2009/11/05 23:52:13  bpoladian
// Separated almostfull flags for each transaction type.
//
// Revision 1.4  2009/11/03 04:23:43  bpoladian
// Fixed range on dma_fromhost_info.
//
// Revision 1.3  2009/10/30 23:34:07  bpoladian
// Fixed byte enables.  Added generate labels.
//
// Revision 1.2  2009/10/28 02:31:20  bpoladian
// Make target_address_valid clear when not in address phase.
//
// Revision 1.1  2009/10/27 21:10:51  bpoladian
// Moved to new folder.
//
// Revision 1.3  2009/10/27 18:31:09  bpoladian
// Lots of syntactic and logical corrections.
//
// Revision 1.2  2009/10/22 04:12:38  bpoladian
// Code overhaul of pcie_x8_user_interface.
//
// Revision 1.1  2009/10/21 22:54:31  bpoladian
// Initial revision.  Port list only.
//
// ################################################################

`include "dini/fifo/fifo_async_blk_reg.v"
`include "dini/fifo/fifo_async_sel.v"
`include "dini/misc/reset_resync.v"
`include "dini/pcie/pcie_dma/user_fpga/pcie_defines.v"

`ifdef INCL_PCIE_INTERFACE
`else
`define INCL_PCIE_INTERFACE

module pcie_interface #(
   parameter NUM_DMA_ENGINES      = 3,
   parameter MAX_DMA_ENGINES      = 3,
   parameter ONE_XFER_PER_CYCLE   = 1, // Only allow one fromhost interface to transfer data per clock cycle - makes muxing easy
   parameter ADD_PIPELINE_OUTPUT  = 0,
   parameter DMA_ENGINE_ENABLES  = 3'b111 // enable all DMA engines
) (
   // clocks, resets
   input                          clk,
   input                          reset,

   input                          user_clk, // clock from user

   // Internal Bus
   input  [63:0]                  pcie_fromhost_data,
   input  [NUM_DMA_ENGINES:0]     pcie_fromhost_transaction_type, // [0] for bar access
   input  [1:0]                   pcie_fromhost_isaddress,
   input  [1:0]                   pcie_fromhost_info,
   input  [1:0]                   pcie_fromhost_valid,
   input  [NUM_DMA_ENGINES:0]     pcie_fromhost_almost_full,

   // Internal Bus
   output reg [63:0]              pcie_tohost_data,
   output reg [NUM_DMA_ENGINES:0] pcie_tohost_transaction_type, // [0] for bar access
   output reg [4:0]               pcie_tohost_info,
   output reg [1:0]               pcie_tohost_valid,
   output reg [NUM_DMA_ENGINES:0] pcie_tohost_almost_full,


   // to user, from_host, target signals
   output reg [63:0]              target_address, // 32-bit-aligned byte address ([1:0]==2'b0)
   output reg [63:0]              target_write_data,
   output reg  [7:0]              target_write_be,
   output reg                     target_address_valid,
   output reg                     target_write_enable,
   output reg                     target_read_enable,
   output reg [3:0]               target_request_tag,
   input                          target_write_accept,

   // debug only
   output reg  [2:0]              debug_target_bar,

   // to user, from_host, DMA0 signals
   output     [63:0]              dma0_from_host_data,
   output      [7:0]              dma0_from_host_ctrl,
   output                         dma0_from_host_valid,
   input                          dma0_from_host_advance,

   // to user, from_host, DMA1 signals
   output     [63:0]              dma1_from_host_data,
   output      [7:0]              dma1_from_host_ctrl,
   output                         dma1_from_host_valid,
   input                          dma1_from_host_advance,

   // to user, from_host, DMA2 signals
   output     [63:0]              dma2_from_host_data,
   output      [7:0]              dma2_from_host_ctrl,
   output                         dma2_from_host_valid,
   input                          dma2_from_host_advance,

   // from user, to_host target signals
   input      [63:0]              target_read_data,
   input                          target_read_accept,
   input      [3:0]               target_read_data_tag,
   input                          target_read_data_valid,
   output reg [7:0]               target_read_ctrl,
   input      [7:0]               target_read_data_ctrl,

   // from user, to_host DMA0 signals
   input [63:0]                   dma0_to_host_data,
   input  [7:0]                   dma0_to_host_ctrl,
   input                          dma0_to_host_valid,
   output                         dma0_to_host_almost_full,

   // from user, to_host DMA1 signals
   input [63:0]                   dma1_to_host_data,
   input  [7:0]                   dma1_to_host_ctrl,
   input                          dma1_to_host_valid,
   output                         dma1_to_host_almost_full,

   // from user, to_host DMA2 signals
   input [63:0]                   dma2_to_host_data,
   input  [7:0]                   dma2_to_host_ctrl,
   input                          dma2_to_host_valid,
   output                         dma2_to_host_almost_full
);
`include "dini/misc/functions.v"

/////////////////////////////////////////////////////////////////
// Target FromHost FIFO
/////////////////////////////////////////////////////////////////
wire [63:0] target_fromhost_data;
wire [1:0]  target_fromhost_info;
wire [1:0]  target_fromhost_isaddress;
wire        target_fromhost_almostfull;
reg         target_fromhost_read_en;
wire        target_fromhost_empty;
reg         target_fromhost_empty_d;
wire [1:0]  target_fromhost_valid;
reg  [3:0]  target_first_be;
reg  [3:0]  target_last_be;
reg  [31:0] bar1_hiaddr;
reg  [31:0] bar2_hiaddr;
reg  [31:0] bar4_hiaddr;
reg         target_read_pending;

reg reset_clk;
wire reset_userclk;

always @(posedge clk or posedge reset) begin
  if (reset) begin
    reset_clk <= 1'b1;
  end else begin
    reset_clk <= 1'b0;
  end
end

	reset_resync i_rst_userclk (
			.clk_in(clk),
			.rst_in(reset),
			.clk_out(user_clk),
			.rst_out(reset_userclk)
	);

fifo_async_blk_reg #(
  .ADDR_W           (9),
  .DATA_W           (2+2+2+64),
  .ALMOSTFULL_LIMIT (128),
  .ONECLOCK         (0),
  .INPUT_REG(0),
  .OUTPUT_REG(3)
) i_fifo_target_fromhost (
  .reset          (reset_clk),

  .wr_clk         (clk),
  .wr_en          ((|pcie_fromhost_valid) & pcie_fromhost_transaction_type[0]),
  .wr_din         ({pcie_fromhost_info, pcie_fromhost_valid, pcie_fromhost_isaddress, pcie_fromhost_data}),
  .wr_full_flaky        (),
  .wr_almostfull  (target_fromhost_almostfull),
  .wr_full_count_flaky  (),

  .rd_clk         (user_clk),
  .rd_en          (target_fromhost_read_en),
  .rd_dout        ({target_fromhost_info, target_fromhost_valid, target_fromhost_isaddress, target_fromhost_data}),
  .rd_empty       (target_fromhost_empty),
  .rd_empty_count (),
  .rd_empty_ff()
);

reg [1:0] target_state;
localparam TARGET_ADDR       = 2'b00;
localparam TARGET_FIRST_DATA = 2'b01;
localparam TARGET_DATA       = 2'b10;
localparam TARGET_INVALID    = 2'b11;

reg [10:0] target_pending_counter;

always @ (posedge user_clk or posedge reset_userclk) begin
  if (reset_userclk) begin
    target_address       <= 'b0;
    target_write_data    <= 'b0;
    target_write_be      <= 'b0;
    debug_target_bar     <= 'b0;
    target_address_valid <= 'b0;
    target_write_enable  <= 'b0;
    target_read_enable   <= 'b0;
    target_read_pending  <= 'b0;
    target_first_be      <= 'b0;
    target_last_be       <= 'b0;
    target_request_tag   <= 'b0;
    target_read_ctrl     <= 'b0;

    target_state         <= TARGET_ADDR;

    target_fromhost_read_en <= 'b0;
    target_fromhost_empty_d <= 'b0;

    bar1_hiaddr          <= 'b0;
    bar2_hiaddr          <= 'b0;
    bar4_hiaddr          <= 'b0;
  end else begin

    target_fromhost_empty_d <= target_fromhost_empty;

    target_fromhost_read_en <= ~(target_fromhost_empty | target_fromhost_read_en | target_write_enable | target_read_enable | target_read_pending);

    if(target_write_enable & target_write_accept)
      target_write_enable   <= 1'b0;

    if(target_read_enable & target_read_accept)
      target_read_enable    <= 1'b0;

    if(target_read_pending)
      target_pending_counter <= target_pending_counter + 1'b1;
    else
      target_pending_counter <= 'b0;

    if(target_read_data_valid | (&target_pending_counter))
      target_read_pending   <= 1'b0;


    target_address_valid    <= 1'b0;

    case(target_state)
      TARGET_INVALID: begin
        target_state <= TARGET_ADDR;
      end
      TARGET_ADDR: begin
        if(target_fromhost_read_en & ~target_fromhost_empty) begin
          if(target_fromhost_isaddress[0]) begin

            // BAR0 never resides in user space, so use this bit to load hiaddr
            if(target_fromhost_data[`FH_ADDR_BAR0_HIT_BIT]) begin
              case(target_fromhost_data[`FH_ADDR_BAR_HIT_RANGE+1])
                3'b001:  bar1_hiaddr <= target_fromhost_data[`FH_ADDR_ADDRESS_RANGE];
                3'b010:  bar2_hiaddr <= target_fromhost_data[`FH_ADDR_ADDRESS_RANGE];
                3'b100:  bar4_hiaddr <= target_fromhost_data[`FH_ADDR_ADDRESS_RANGE];
                default: ;
              endcase
            end else begin

              case(target_fromhost_data[`FH_ADDR_BAR_HIT_RANGE+1])
                3'b001:  target_address[63:32] <= bar1_hiaddr;
                3'b010:  target_address[63:32] <= bar2_hiaddr;
                3'b100:  target_address[63:32] <= bar4_hiaddr;
                default: target_address[63:32] <= 'b0;
              endcase

              target_address[31:0] <= target_fromhost_data[`FH_ADDR_ADDRESS_RANGE];
              target_address_valid <= 1'b1;
              target_first_be      <= target_fromhost_data[`FH_ADDR_FIRST_BE_RANGE];
              target_last_be       <= target_fromhost_data[`FH_ADDR_LAST_BE_RANGE];
              debug_target_bar     <= target_fromhost_data[`FH_ADDR_BAR_HIT_RANGE+1];
              target_request_tag   <= target_fromhost_data[`FH_ADDR_TAG_RANGE];
              target_read_enable   <= target_fromhost_data[`FH_ADDR_RD_NWR_BIT];
              target_read_pending  <= target_fromhost_data[`FH_ADDR_RD_NWR_BIT];
              target_read_ctrl     <= {7'h0, target_fromhost_info[1]};

              if(~target_fromhost_data[`FH_ADDR_RD_NWR_BIT])
               target_state         <= TARGET_FIRST_DATA;
            end

          // synthesis translate_off
          end else begin
            $display("ERROR: pcie_interface.v: Expected Address Phase of User Target Access! %t",$time);
            $stop;
          // synthesis translate_on

          end
        end
      end

      TARGET_FIRST_DATA: begin
        if(target_fromhost_read_en & ~target_fromhost_empty) begin
          target_write_data <= target_fromhost_data;
          target_write_enable  <= 1'b1;

          if(target_fromhost_isaddress[1]) begin
            target_write_be[3:0] <= target_fromhost_valid[0] ? target_first_be : 4'h0;
            target_write_be[7:4] <= target_fromhost_valid[1] ? (target_read_ctrl[0] ? target_last_be : target_first_be) : 4'h0;
            target_state <= TARGET_ADDR;
          end else begin
            target_write_be[3:0] <= target_fromhost_valid[0] ? target_first_be : 4'h0;
            target_write_be[7:4] <= target_fromhost_valid[1] ? 4'hF            : 4'h0;
            target_state <= TARGET_DATA;
          end
        end
      end

      TARGET_DATA: begin
        if(target_fromhost_read_en & ~target_fromhost_empty) begin
          target_write_data <= target_fromhost_data;
          target_write_enable  <= 1'b1;

          if(target_fromhost_isaddress[1]) begin
            target_write_be[3:0] <= target_fromhost_valid[1] ? 4'hF           : target_last_be;
            target_write_be[7:4] <= target_fromhost_valid[1] ? target_last_be : 4'h0;
            target_state <= TARGET_ADDR;
          end else begin
            target_write_be[7:0] <= 8'hFF;
          end
        end
      end
    endcase
  end
end

/////////////////////////////////////////////////////////////////
// DMA FromHost FIFO
/////////////////////////////////////////////////////////////////
wire [63:0]                dma_fromhost_data [MAX_DMA_ENGINES-1:0];
wire [1:0]                 dma_fromhost_info [MAX_DMA_ENGINES-1:0];
wire [1:0]                 dma_fromhost_isaddress [MAX_DMA_ENGINES-1:0];
wire [1:0]                 dma_fromhost_valid [MAX_DMA_ENGINES-1:0];
wire [MAX_DMA_ENGINES-1:0] dma_fromhost_almostfull;
wire [MAX_DMA_ENGINES-1:0] dma_fromhost_read_en;
wire [MAX_DMA_ENGINES-1:0] dma_fromhost_empty;

genvar u;
generate
for(u=0; u<NUM_DMA_ENGINES; u=u+1) begin : dma_fromhost_fifos
if (DMA_ENGINE_ENABLES[u]) begin
  fifo_async_blk_reg #(
    .ADDR_W           (9),
    .DATA_W           (2+2+2+64),
    .ALMOSTFULL_LIMIT (128),
    .ONECLOCK         (0),
	.INPUT_REG(0),
	.OUTPUT_REG(3)
  ) i_fifo_dma_fromhost (
    .reset          (reset_clk),

    .wr_clk         (clk),
    .wr_en          ((|pcie_fromhost_valid) & pcie_fromhost_transaction_type[u+1]),
    .wr_din         ({pcie_fromhost_info, pcie_fromhost_valid, pcie_fromhost_isaddress, pcie_fromhost_data}),
    .wr_full_flaky        (),
    .wr_almostfull  (dma_fromhost_almostfull[u]),
    .wr_full_count_flaky  (),

    .rd_clk         (user_clk),
    .rd_en          (dma_fromhost_read_en[u]),
    .rd_dout        ({dma_fromhost_info[u], dma_fromhost_valid[u], dma_fromhost_isaddress[u], dma_fromhost_data[u]}),
    .rd_empty       (dma_fromhost_empty[u]),
    .rd_empty_count (),
    .rd_empty_ff    ()
  );
  end else begin
    assign {dma_fromhost_info[u], dma_fromhost_valid[u], dma_fromhost_isaddress[u], dma_fromhost_data[u]} = 'b0;
    assign dma_fromhost_empty[u] = 1'b1;
    assign dma_fromhost_almostfull[u] = 1'b0;

  end
end
endgenerate

// keep track of some debug stuff!
`ifdef FPGA0_PCIEDEBUG_ADDRESSMATCH
(* dont_touch="TRUE", keep="TRUE" *) reg [63:0] fromhost_last0_dat;
(* dont_touch="TRUE", keep="TRUE" *) reg [1:0] fromhost_last0_isaddr;
(* dont_touch="TRUE", keep="TRUE" *) reg [1:0] fromhost_last0_valid;
(* dont_touch="TRUE", keep="TRUE" *) reg [1:0] fromhost_last0_info;
(* dont_touch="TRUE", keep="TRUE" *) reg [63:0] fromhost_last1_dat;
(* dont_touch="TRUE", keep="TRUE" *) reg [1:0] fromhost_last1_isaddr;
(* dont_touch="TRUE", keep="TRUE" *) reg [1:0] fromhost_last1_valid;
(* dont_touch="TRUE", keep="TRUE" *) reg [1:0] fromhost_last1_info;
always @(posedge user_clk or posedge reset_userclk) begin
		if (reset_userclk) begin
			fromhost_last0_dat <= 'b0;
			fromhost_last0_isaddr <= 'b0;
			fromhost_last0_valid <= 'b0;
			fromhost_last0_info <= 'b0;
			fromhost_last1_dat <= 'b0;
			fromhost_last1_isaddr <= 'b0;
			fromhost_last1_valid <= 'b0;
			fromhost_last1_info <= 'b0;
		end else begin
			if (dma_fromhost_read_en[1] & (~dma_fromhost_empty[1])) begin
				fromhost_last0_dat <= dma_fromhost_data[1];
				fromhost_last0_isaddr <= dma_fromhost_isaddress[1];
				fromhost_last0_valid <= dma_fromhost_valid[1];
				fromhost_last0_info <= dma_fromhost_info[1];

				fromhost_last1_dat <= fromhost_last0_dat;
				fromhost_last1_isaddr <= fromhost_last0_isaddr;
				fromhost_last1_valid <= fromhost_last0_valid;
				fromhost_last1_info <= fromhost_last0_info;
			end
		end
end
`endif // FPGA0_PCIEDEBUG_ADDRESSMATCH

generate
if(ONE_XFER_PER_CYCLE) begin : gen_easy_muxing
  // Don't send fromhost transactions on the same clock cycle
  // This will make the muxing easier downstream
  assign dma_fromhost_read_en[0] = dma0_from_host_advance & target_fromhost_empty_d;
  assign dma_fromhost_read_en[1] = dma1_from_host_advance & target_fromhost_empty_d & (~(dma_fromhost_read_en[0] & (~dma_fromhost_empty[0])));
  assign dma_fromhost_read_en[2] = dma2_from_host_advance & target_fromhost_empty_d & (~(dma_fromhost_read_en[0] & (~dma_fromhost_empty[0]))) & (~(dma_fromhost_read_en[1] & (~dma_fromhost_empty[1])));

end else begin : gen_best_throughput
  // This will allow for any interface to transfer data independent of the other interfaces
  assign dma_fromhost_read_en[0] = dma0_from_host_advance;
  assign dma_fromhost_read_en[1] = dma1_from_host_advance;
  assign dma_fromhost_read_en[2] = dma2_from_host_advance;
end
endgenerate

// Use async_blk_reg FIFO here to help w/ timing instead of adding extra pipeline flops
assign dma0_from_host_data  = dma_fromhost_data[0];
assign dma0_from_host_ctrl  = {2'h0, dma_fromhost_info[0], dma_fromhost_valid[0], dma_fromhost_isaddress[0]};
assign dma0_from_host_valid = (~dma_fromhost_empty[0]) & dma_fromhost_read_en[0];

assign dma1_from_host_data  = dma_fromhost_data[1];
assign dma1_from_host_ctrl  = {2'h0, dma_fromhost_info[1], dma_fromhost_valid[1], dma_fromhost_isaddress[1]};
assign dma1_from_host_valid = (~dma_fromhost_empty[1]) & dma_fromhost_read_en[1];

assign dma2_from_host_data  = dma_fromhost_data[2];
assign dma2_from_host_ctrl  = {2'h0, dma_fromhost_info[2], dma_fromhost_valid[2], dma_fromhost_isaddress[2]};
assign dma2_from_host_valid = (~dma_fromhost_empty[2]) & dma_fromhost_read_en[2];

/////////////////////////////////////////////////////////////////
// Target ToHost FIFO
/////////////////////////////////////////////////////////////////
wire [63:0] target_tohost_data;
wire [4:0]  target_tohost_info;
wire        target_tohost_empty;
reg         target_tohost_read_en;

wire [6:0]  target_tohost_ctrl_unused;

// This will never overflow because we do at most one read
// at a time to guarantee ordering
fifo_async_sel #(
  .ADDR_W           (3),
  .DATA_W           (8+4+64),
  .ALMOSTFULL_LIMIT (1),
  .ONECLOCK         (0),
  .GEN_WRALMOSTFULL (0)
) i_fifo_target_tohost (
  .reset          (reset_userclk),

  .wr_clk         (user_clk),
  .wr_en          (target_read_data_valid),
  .wr_din         ({target_read_data_ctrl, target_read_data_tag, target_read_data}),
  .wr_full        (),
  .wr_almostfull  (),
  .wr_full_count  (),

  .rd_clk         (clk),
  .rd_en          (target_tohost_read_en),
  .rd_dout        ({target_tohost_ctrl_unused, target_tohost_info[0], target_tohost_info[4:1], target_tohost_data}),
  .rd_empty       (target_tohost_empty),
  .rd_empty_count ()
);


/////////////////////////////////////////////////////////////////
// DMA ToHost FIFO
/////////////////////////////////////////////////////////////////
wire [63:0]                dma_tohost_data_in [MAX_DMA_ENGINES-1:0];
wire [7:0]                 dma_tohost_ctrl_in [MAX_DMA_ENGINES-1:0];
wire [MAX_DMA_ENGINES-1:0] dma_tohost_valid;
wire [MAX_DMA_ENGINES-1:0] dma_tohost_almostfull;

wire [63:0]                dma_tohost_data [MAX_DMA_ENGINES-1:0];
wire [4:0]                 dma_tohost_info [MAX_DMA_ENGINES-1:0];
wire [MAX_DMA_ENGINES-1:0] dma_tohost_empty;
reg  [MAX_DMA_ENGINES-1:0] dma_tohost_read_en;

wire [2:0]                 dma_tohost_ctrl_unused [MAX_DMA_ENGINES-1:0];

assign dma_tohost_data_in[0] = dma0_to_host_data;
assign dma_tohost_data_in[1] = dma1_to_host_data;
assign dma_tohost_data_in[2] = dma2_to_host_data;

assign dma_tohost_ctrl_in[0] = dma0_to_host_ctrl;
assign dma_tohost_ctrl_in[1] = dma1_to_host_ctrl;
assign dma_tohost_ctrl_in[2] = dma2_to_host_ctrl;

assign dma_tohost_valid[0]   = dma0_to_host_valid;
assign dma_tohost_valid[1]   = dma1_to_host_valid;
assign dma_tohost_valid[2]   = dma2_to_host_valid;

assign dma0_to_host_almost_full  = dma_tohost_almostfull[0];
assign dma1_to_host_almost_full  = dma_tohost_almostfull[1];
assign dma2_to_host_almost_full  = dma_tohost_almostfull[2];


genvar t;
generate
for(t=0; t<NUM_DMA_ENGINES; t=t+1) begin : dma_tohost_fifos

if (DMA_ENGINE_ENABLES[t]) begin
fifo_async_blk_reg #(
  .ADDR_W           (9),
  .DATA_W           (8+64),
  .ALMOSTFULL_LIMIT (128),
  .ONECLOCK         (0),
  .INPUT_REG(0),
  .OUTPUT_REG(3)
) i_fifo_dma_tohost (
  .reset          (reset_userclk),

  .wr_clk         (user_clk),
  .wr_en          (dma_tohost_valid[t]),
  .wr_din         ({dma_tohost_ctrl_in[t], dma_tohost_data_in[t]}),
  .wr_full_flaky        (),
  .wr_almostfull  (dma_tohost_almostfull[t]),
  .wr_full_count_flaky  (),

  .rd_clk         (clk),
  .rd_en          (dma_tohost_read_en[t]),
  .rd_dout        ({dma_tohost_ctrl_unused[t], dma_tohost_info[t], dma_tohost_data[t]}),
  .rd_empty       (dma_tohost_empty[t]),
  .rd_empty_count (),
  .rd_empty_ff()
);
end else begin
  assign dma_tohost_ctrl_unused[t] = 'b0;
  assign dma_tohost_info[t]        = 'b0;
  assign dma_tohost_data[t]        = 'b0;
  assign dma_tohost_empty[t]       = 1'b1;
  assign dma_tohost_almostfull[t]  = 1'b0;
end

end
endgenerate


/////////////////////////////////////////////////////////////////
// ToHost Mux
/////////////////////////////////////////////////////////////////
integer i;
reg [log2(NUM_DMA_ENGINES)-1:0] dma_engine_active;
reg [log2(NUM_DMA_ENGINES)-1:0] dma_engine_active_d;
reg [NUM_DMA_ENGINES:0]   pcie_tohost_transaction_state;

always @ (posedge clk or posedge reset_clk) begin
  if (reset_clk) begin
    pcie_tohost_data              <= 'b0;
    pcie_tohost_transaction_state <= 'b0;
    pcie_tohost_transaction_type  <= 'b0;
    pcie_tohost_info              <= 'b0;
    pcie_tohost_valid             <= 'b0;
    pcie_tohost_almost_full       <= 'b0;

    target_tohost_read_en         <= 'b0;
    dma_tohost_read_en            <= 'b0;

    dma_engine_active             <= 'b0;
    dma_engine_active_d           <= 'b0;
  end else begin

    pcie_tohost_almost_full[0]   <= target_fromhost_almostfull;
    for(i=0; i<NUM_DMA_ENGINES; i=i+1)
      pcie_tohost_almost_full[i+1] <= dma_fromhost_almostfull[i];

    pcie_tohost_transaction_state <= {(~dma_tohost_empty), ~target_tohost_empty};


    dma_engine_active <= 'b0;
    for(i=0; i<NUM_DMA_ENGINES; i=i+1) begin
      if(~dma_tohost_empty[i] & ~pcie_fromhost_almost_full[i+1])
        dma_engine_active <= i[log2(NUM_DMA_ENGINES)-1:0];
    end

    dma_engine_active_d <= dma_engine_active;

    /* verilator lint_off CASEX */
    casex (pcie_tohost_transaction_state)
      // No Transaction
      4'b0000: begin
        target_tohost_read_en <= 'b0;
        dma_tohost_read_en    <= 'b0;
      end

      // Target Transaction
      4'bxxx1: begin
        target_tohost_read_en <= ~pcie_fromhost_almost_full[0];
        dma_tohost_read_en    <= 'b0;
      end

      // DMA Transaction
      default: begin
        target_tohost_read_en                 <= 'b0;
        dma_tohost_read_en                    <= 'b0;
        dma_tohost_read_en[dma_engine_active] <= ~pcie_fromhost_almost_full[dma_engine_active+1];
      end

    endcase
    /* verilator lint_on CASEX */

    pcie_tohost_valid <= 2'b00;
    if(target_tohost_read_en) begin
      pcie_tohost_transaction_type <= {{NUM_DMA_ENGINES{1'b0}}, 1'b1} << 0;
      pcie_tohost_data             <= target_tohost_data;
      pcie_tohost_info             <= target_tohost_info;
      pcie_tohost_valid            <= {2{~target_tohost_empty}};
    end else if(dma_tohost_read_en[dma_engine_active_d]) begin
      pcie_tohost_transaction_type <= {{NUM_DMA_ENGINES{1'b0}}, 1'b1} << (dma_engine_active_d+1);
      pcie_tohost_data             <= dma_tohost_data[dma_engine_active_d];
      pcie_tohost_info             <= dma_tohost_info[dma_engine_active_d];
      pcie_tohost_valid            <= {2{~dma_tohost_empty[dma_engine_active_d]}};

      // synthesis translate_off
      // Demand-mode checks
      if(dma_tohost_info[dma_engine_active_d][2] & dma_tohost_info[dma_engine_active_d][4]) begin
        // Check demand-mode length and byte enables
        if(~dma_tohost_info[dma_engine_active_d][3]) begin
          // Byte enables active
          if(~dma_tohost_data[dma_engine_active_d][28] & dma_tohost_data[dma_engine_active_d][26]) begin
            if(dma_tohost_data[dma_engine_active_d][23:20]==0) begin
              $display("%m: ERROR: Demand-mode descriptor byte enables are active, but first dword byte enables are 0!");
              $stop;
            end
            if(dma_tohost_data[dma_engine_active_d][19:16]==0) begin
              $display("%m: ERROR: Demand-mode descriptor byte enables are active, but last dword byte enables are 0!");
              $stop;
            end
            if(dma_tohost_data[dma_engine_active_d][15:0]>1) begin
              casex(dma_tohost_data[dma_engine_active_d][23:20])
                4'bxx01,
                4'bx01x,
                4'b01xx: begin
                  $display("%m: ERROR: Demand-mode descriptor first byte-enable causes discontinuous bytes!");
                  $stop;
                end
                default: ;
              endcase

              casex(dma_tohost_data[dma_engine_active_d][19:16])
                4'b10xx,
                4'bx10x,
                4'bxx10: begin
                  $display("%m: ERROR: Demand-mode descriptor last byte-enable causes discontinuous bytes!");
                  $stop;
                end
                default: ;
              endcase
            end

            if(dma_tohost_data[dma_engine_active_d][15:0]==1) begin
              if(dma_tohost_data[dma_engine_active_d][19:16]!=0)
                $display("%m: WARNING: Demand-mode descriptor last byte-enable will be ignored for packet w/ dword_length==1");
            end
          end
        end

        // Check demand-mode address
        if(dma_tohost_info[dma_engine_active_d][3]) begin
          if(|dma_tohost_data[dma_engine_active_d][1:0]) begin
            $display("%m: ERROR: Demand-mode address is not DWORD aligned! (Bits 1:0 must always be 2'b00)");
            $stop;
          end
        end
      end
      // synthesis translate_on
    end

  end
end

endmodule

`endif // INCL_PCIE_INTERFACE
