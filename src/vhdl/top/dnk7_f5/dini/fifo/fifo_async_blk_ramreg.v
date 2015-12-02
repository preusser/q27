// **********************************************************************
// $Header: /var/lib/cvs/dncvs/FPGA/dini/fifo/fifo_async_blk_ramreg.v,v 1.6 2015/03/11 23:54:08 bpoladian Exp $
// **********************************************************************
// $Log: fifo_async_blk_ramreg.v,v $
// Revision 1.6  2015/03/11 23:54:08  bpoladian
// Removed unused fifo_checksum.
//
// Revision 1.5  2014/09/09 03:05:37  bpoladian
// Removed simulation warning about externally registered FIFO.
//
// Revision 1.4  2014/08/25 17:25:03  bpoladian
// Only connect ecc_rst when define is active.
//
// Revision 1.3  2014/08/24 00:40:37  neal
// Made infer_blkram instances do an extra write and read before the first valid one.
//
// Revision 1.2  2014/07/30 22:43:10  neal
// Added a parameter.
//
// Revision 1.1  2014/07/08 15:20:02  neal
// Added optional output register with REGCE to rams.
// Added option to use RAM's output register.
// Added checksums to all async fifos (enabled by define).
//
// Revision 1.17  2014/07/02 12:54:39  neal
// Disabled some of the extra checksum checks (to make it smaller).
//
// Revision 1.16  2014/07/01 23:03:49  neal
// Fixed an unregistered reset that changes clock domains.
//
// Revision 1.15  2014/07/01 19:18:45  neal
// Added checksums to wr_din and rd_dout with a sticky error bit that can be read back.
//
// Revision 1.14  2013/02/22 19:55:59  claudiug
// blockrams are not instantiated as fifos if no FIFO parameter is specified
//
// Revision 1.13  2013/01/23 21:22:29  claudiug
// removed timescale declaration from all fifo_ files
//
// Revision 1.12  2013/01/07 19:55:57  neal
// Timing closure changes.
// Added a write and read data checksum (for logic analyzer use).
// Added optional clobbering of output data when not reading (simulation only).
//
// Revision 1.11  2012/05/25 23:57:04  neal
// Added an option to output unknown when empty.
//
// Revision 1.10  2012/05/11 02:35:46  bpoladian
// Pass ONECLOCK parameter to infer_blkram.
// Formatting cleanup.
//
// Revision 1.9  2012/04/24 17:36:51  bpoladian
// Changed synthesis ifdefs to translate directives.
//
// Revision 1.8  2011/12/05 22:16:04  neal
// Fixed toe_interrupt.
// Reduced toe ram utilization.
// Allowed digitfinder to have some constant input ports (selectable by parameter).
// Changed some brams to be single bram with byte write enables.
// Allowed some FIFO ports to not be generated (xst warnings).
//
// Revision 1.7  2011/10/06 01:49:41  bpoladian
// Disable verilator tracing.
//
// Revision 1.6  2010/12/21 03:08:40  bpoladian
// Added wire declaration to avoid implicit wire warning.
//
// Revision 1.5  2010/11/16 03:12:16  bpoladian
// Added read enable port for blockram.
//
// Revision 1.4  2010/04/16 01:57:11  bpoladian
// Updated path and added parameter warning.
//
// Revision 1.3  2008/04/11 01:38:02  bpoladian
// Ran dos2unix.  Removed comments on `else and `endif lines.
//
// Revision 1.2  2008/04/01 23:27:48  bpoladian
// Updated include paths to reflect change in directory structure.
//
// Revision 1.1  2007/06/13 17:54:39  jperry
// copied from timelogic area.  Not sure where this stuff will go in the end.
//
// Revision 1.6  2007/04/24 18:14:54  neal
// Removed the reset from the BlockRAM output of the FIFO.  The data output from the FIFO will now be unknown at the beginning of time, until it has been written to completely.
//
// Revision 1.5  2007/03/06 16:03:59  neal
// Made the fifo able to be synchronous to 1 clock domain to make it smaller and faster.
//
// Revision 1.4  2007/02/15 18:28:08  neal
// Made the parameters UPPER CASE.
//
// Revision 1.3  2007/02/10 05:23:14  neal
// Changed the RAM functionality so that data is available at the same time as read/empty.
//
// Revision 1.2  2007/02/05 17:23:46  jperry
// changed module name to match file name.
//
// Revision 1.1  2007/02/05 17:11:30  jperry
// initial async FIFO files.  Copied, modified from dn_fpgacode/FIFO.  This may be cleaned up later.
//
// **********************************************************************

/*verilator tracing_off*/
`ifdef INC_FIFO_ASYNC_BLK_RAMREG_V
`else
`define INC_FIFO_ASYNC_BLK_RAMREG_V

`include "dini/fifo/fifo_addr.v"
`include "dini/fifo/infer_blkram.v"

module fifo_async_blk_ramreg #(
  parameter ADDR_W           = 5, // number of  bits wide for address, depth of the fifo is pow(2,ADDR_W)
  parameter DATA_W           = 32, // number of bits wide for data
  parameter ALMOSTFULL_LIMIT = 4, // number of entries left before almost full goes active
  parameter ONECLOCK         = 0, // set to 1 to get rid of resync logic.
  parameter GEN_RDCOUNT      = 1,
  parameter GEN_WRCOUNT      = 1,
  parameter IGNORE_FULL_WR   = 0,
  parameter GEN_WRALMOSTFULL = 1,
  parameter SIM_EMPTY_X      = 0, // simulate with 'bx for read data path when empty
  parameter SIM_NOTRD_X      = 0, // simulate with 'bx for read data path when not reading
  parameter EXTERNALLY_OUTPUT_REGISTERED = 0, // external output FF
  parameter REGRAM = 0
) (
  input               reset,

  input               wr_clk,
  input               wr_en,
  input  [DATA_W-1:0] wr_din,
  output              wr_full,
  output              wr_almostfull,
  output [ADDR_W:0]   wr_full_count,

  input               rd_clk,
  input               rd_en,
  input               ram_reg_ce, // output register enable for BRAM
  output [DATA_W-1:0] rd_dout,
  output              rd_empty,
  output [ADDR_W:0]   rd_empty_count
);

// synthesis translate_off
 initial begin
   if(ALMOSTFULL_LIMIT>=(2**ADDR_W)) begin
     $display("ERROR: %m: ADDR_W size too small for ALMOSTFULL_LIMIT!  ADDR_W: %d, ALMOSTFULL_LIMIT: %d",ADDR_W,ALMOSTFULL_LIMIT);
     $stop;
   end
 end

 assign rd_dout = (SIM_EMPTY_X & rd_empty ? {DATA_W{1'bx}} : {DATA_W{1'bz}} ); // Drive 'x' on read data bus when empty in simulation.
 assign rd_dout = (SIM_NOTRD_X & (~rd_en) ? {DATA_W{1'bx}} : {DATA_W{1'bz}} ); // Drive 'x' on read data bus when empty in simulation.
// synthesis translate_on


/**********************************************************************\
 *                                                                      *
 *  Address selection                                                   *
 *                                                                      *
 \**********************************************************************/

wire [ADDR_W-1:0] rd_addr;
wire [ADDR_W-1:0] wr_addr;
wire              rd_en_ram;
wire              wr_en_ram;

/**********************************************************************\
 *                                                                      *
 *  Instantiation of the address registers                              *
 *                                                                      *
 \**********************************************************************/
fifo_addr #(
  .ADDR_W           (ADDR_W),
  .ALMOSTFULL_LIMIT (ALMOSTFULL_LIMIT),
  .DELAY_READ       (1),
  .ONECLOCK         (ONECLOCK),
  .GEN_RDCOUNT      (GEN_RDCOUNT),
  .GEN_WRCOUNT      (GEN_WRCOUNT),
  .IGNORE_FULL_WR   (IGNORE_FULL_WR),
  .GEN_WRALMOSTFULL (GEN_WRALMOSTFULL)
) i_fifo_addr (
   .wr_clk          (wr_clk),
   .wr_en           (wr_en),
   .wr_addr         (wr_addr),
   .wr_en_ram       (wr_en_ram),
   .wr_full         (wr_full),
   .wr_almost_full  (wr_almostfull),
   .wr_full_count   (wr_full_count),

   .rd_clk          (rd_clk),
   .rd_en           (rd_en),
   .rd_en_ram       (rd_en_ram),
   .rd_addr         (rd_addr),
   .rd_empty        (rd_empty),
   .rd_empty_count  (rd_empty_count),

   //// Do we want separate resets for read/write clock domains?
   .fifo_reset      (reset)
);

/**********************************************************************\
*                                                                      *
*  Block RAM instantiation for FIFO.  One address location per queue   *
*  is sacrificed from each channel for the overall speed of the        *
*  design.                                                             *
*                                                                      *
\**********************************************************************/

infer_blkram #(
 .D_WIDTH    (DATA_W),
 .ADDR_WIDTH (ADDR_W),
 .FIFO       (1),
 .ONECLOCK   (ONECLOCK),
 .MODE("READ_FIRST"),
 .REGRAM(REGRAM)
) i_fifo_blkram (
  .wclk      (wr_clk),
  .we        (wr_en_ram),
  .d         (wr_din[DATA_W-1:0]),
  .waddr     (wr_addr[ADDR_W-1:0]),

`ifdef ENABLE_ECC_DEBUG
  .ecc_rst       (rd_reset),
`endif
  .rclk      (rd_clk),
  .re        (rd_en_ram),
  .reg_ce(ram_reg_ce),
  .o         (rd_dout[DATA_W-1:0]),
  .raddr     (rd_addr[ADDR_W-1:0])
);

`ifdef USE_FIFO_DATA_CHECKSUMS
// **********************************************************************
// Data verification through the FIFO (can attach chipscope here).
// It should automatically get optimized out of a netlist when not used - but
// it was kept with Vivado.
// **********************************************************************

reg reset_rd_check;
reg [DATA_W-1:0] wr_checksum;
reg [DATA_W-1:0] wr_din_d;
reg wr_en_d;
reg [DATA_W-1:0] rd_checksum;
reg fifo_checksum_error;
reg [9:0] ignore_checksum_wr;
reg [2:0] ignore_checksum_rd;
reg [7:0] error;

always @(posedge wr_clk or posedge reset) begin
	if (reset) begin
		reset_rd_check <= 1'b1;
		wr_checksum <= 'b0;
		ignore_checksum_wr <= -1;
		wr_din_d <= 'b0;
		wr_en_d <= 'b0;
	end else begin
		reset_rd_check <= 1'b0;
		wr_din_d <= wr_din;
		wr_en_d <= wr_en;
		if (wr_en)
			wr_checksum <= wr_checksum ^ wr_din;
		ignore_checksum_wr <= {ignore_checksum_wr,wr_en};
	end
end

always @(posedge rd_clk or posedge reset_rd_check) begin
	if (reset_rd_check) begin
		rd_checksum <= 'b0;
		fifo_checksum_error <= 'b0;
		ignore_checksum_rd <= -1;
		error <= 'b0;
	end else begin
		if (rd_en & (~rd_empty))
			rd_checksum <= rd_checksum ^ rd_dout;
		ignore_checksum_rd <= {ignore_checksum_rd,|ignore_checksum_wr};
		error[0] <= (rd_checksum!=wr_checksum) && (rd_empty==1'b1) && (ignore_checksum_rd==0) && (ignore_checksum_wr==0);
		error[7:1] <= error[6:0];
		fifo_checksum_error <= &error;
		if (fifo_checksum_error)
			$display("Warning: FIFO %m has checksum error: time=%t",$time);
	end
end
`endif // USE_FIFO_DATA_CHECKSUMS


reset_resync i_rst (
	.clk_in(wr_clk),
	.rst_in(reset),
	.clk_out(rd_clk),
	.rst_out(rd_reset)
);

endmodule // fifo_async_blk

`endif
/*verilator tracing_on*/
