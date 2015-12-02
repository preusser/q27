// **********************
// $Header: /var/lib/cvs/dncvs/FPGA/dini/fifo/infer_blkram.v,v 1.14 2014/09/06 02:19:55 bpoladian Exp $
// **********************
// Description:
//
//   This module infers Dual ported Xilinx Block RAM.
// **********************
// $Log: infer_blkram.v,v $
// Revision 1.14  2014/09/06 02:19:55  bpoladian
// Add define to prevent using read enable for better timing.
//
// Revision 1.13  2014/08/24 00:40:37  neal
// Made infer_blkram instances do an extra write and read before the first valid one.
//
// Revision 1.12  2014/07/24 17:54:53  neal
// Added simulation notes about un-registered RAMs.
//
// Revision 1.11  2014/07/08 15:20:02  neal
// Added optional output register with REGCE to rams.
// Added option to use RAM's output register.
// Added checksums to all async fifos (enabled by define).
//
// Revision 1.10  2013/09/25 00:20:06  claudiug
// fixed inference synthesis attributes for altera (assume stratix V)
//
// Revision 1.9  2013/06/29 01:31:58  claudiug
// added registered RAM behavior (disabled by default)
//
// Revision 1.8  2013/02/22 19:55:59  claudiug
// blockrams are not instantiated as fifos if no FIFO parameter is specified
//
// Revision 1.7  2012/05/11 02:34:07  bpoladian
// Force synchronous operation when ONELOCK is active.
//
// Revision 1.6  2011/10/06 17:51:58  bpoladian
// Prevent verilator tracing.
//
// Revision 1.5  2011/09/29 19:53:43  neal
// Fixed XST warnings.
//
// Revision 1.4  2010/11/16 03:12:16  bpoladian
// Added read enable port for blockram.
//
// Revision 1.3  2010/01/07 19:49:10  bpoladian
// Added new XST-style synthesis constraint.
//
// Revision 1.2  2008/04/11 01:38:02  bpoladian
// Ran dos2unix.  Removed comments on `else and `endif lines.
//
// Revision 1.1  2007/06/13 17:54:39  jperry
// copied from timelogic area.  Not sure where this stuff will go in the end.
//
// Revision 1.3  2007/04/24 18:14:55  neal
// Removed the reset from the BlockRAM output of the FIFO.  The data output from the FIFO will now be unknown at the beginning of time, until it has been written to completely.
//
// Revision 1.2  2007/02/15 18:28:08  neal
// Made the parameters UPPER CASE.
//
// Revision 1.1  2007/02/05 17:11:30  jperry
// initial async FIFO files.  Copied, modified from dn_fpgacode/FIFO.  This may be cleaned up later.
//
// Revision 1.3  2006/07/17 20:56:56Z  jthurkettle
// test
// **********************

/*verilator tracing_off*/
`ifdef INCL_INFER_BLKRAM_V
`else
`define INCL_INFER_BLKRAM_V

//This was broken out from fifo_unidir_block.v

// infer a  RAM, registered reads.
module infer_blkram #(
  parameter D_WIDTH    = 32,
  parameter ADDR_WIDTH = 5,
  parameter FIFO       = 1'bx, //not in use in this module but used in infer_blkram_7series instantiation
  parameter ONECLOCK   = 0,
  parameter REGRAM     = 0, // mimic registered RAM behavior 
  parameter MODE       = "READ_FIRST",// only applicable if ONECLOCK==1
`ifdef NO_BRAM_READ_ENABLE
  parameter USE_READ_ENABLE = 0
`else
  parameter USE_READ_ENABLE = 1
`endif
) (
`ifdef ENABLE_ECC_DEBUG
  input                        ecc_rst, // only used for resetting ecc_error (7series).
`endif // ENABLE_ECC_DEBUG
  output reg [D_WIDTH - 1:0]   o,
  input                        we,
  input                        wclk,
  input                        re,
  input                        reg_ce, // register enable when REGRAM==1
  input                        rclk,
  input     [D_WIDTH - 1:0]    d,
  input     [ADDR_WIDTH - 1:0] raddr,
  input     [ADDR_WIDTH - 1:0] waddr
);

`ifdef ALTERA
(* ramstyle = "M20K" *) reg [D_WIDTH - 1:0]  mem [(1 << ADDR_WIDTH) - 1:0];
`else
(* ram_style = "block" *) reg [D_WIDTH - 1:0]  mem [(1 << ADDR_WIDTH) - 1:0] /* synthesis syn_ramstyle = block_ram */;
`endif

initial begin
		if (REGRAM==0) begin
				$display("NOTE: %m using REGRAM=%d",REGRAM);
		end
end

reg [D_WIDTH-1:0] o_nonreg;
reg re_d;

always @(posedge rclk) begin
    re_d <= re;
end

generate
if(ONECLOCK==1) begin : gen_synchronous
  always @(posedge wclk) begin
    if (we)
      mem[waddr] <= d;

	if (REGRAM) begin
    	if (re)
      		o_nonreg <= mem[raddr];
    	if (reg_ce)
      		o <= o_nonreg;
	end else if (USE_READ_ENABLE) begin
    	if (re) begin
      		o <= mem[raddr];
    	end
	end else begin
    o <= mem[raddr];
  end
  end
end else begin : gen_asynchronous
  always @(posedge wclk) begin
    if (we)
      mem[waddr] <= d;
  end

  always @(posedge rclk) begin
	if (REGRAM) begin
    	if (re)
      		o_nonreg <= mem[raddr];
    	if (reg_ce)
      		o <= o_nonreg;
	end else if (USE_READ_ENABLE) begin
    	if (re) begin
      		o <= mem[raddr];
    	end
	end else begin
    o <= mem[raddr];
  end
  end
end
endgenerate

endmodule

`endif
/*verilator tracing_on*/
