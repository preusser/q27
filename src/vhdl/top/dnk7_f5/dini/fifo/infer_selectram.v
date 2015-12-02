// **************************************************************************
// $Header: /var/lib/cvs/dncvs/FPGA/dini/fifo/infer_selectram.v,v 1.7 2014/10/14 23:21:25 neal Exp $
// **************************************************************************
// Description:
// 	This module describes an inference of a Xilinx selectram.
// **************************************************************************
// $Log: infer_selectram.v,v $
// Revision 1.7  2014/10/14 23:21:25  neal
// Added a memory initialization option.
//
// Revision 1.6  2013/09/25 00:20:06  claudiug
// fixed inference synthesis attributes for altera (assume stratix V)
//
// Revision 1.5  2013/03/12 17:55:58  neal
// Vivado issues with hierarchy fixed.
//
// Revision 1.4  2011/11/15 23:06:44  neal
// Fixed synthesis warning.
//
// Revision 1.3  2011/09/29 19:53:43  neal
// Fixed XST warnings.
//
// Revision 1.2  2010/09/04 01:22:05  bpoladian
// Added new Xilinx-style ram_style attribute.
//
// Revision 1.1  2007/08/01 22:19:42  jperry
// initial, copied from another place in cvs.
//
// Revision 1.2  2007/02/08 18:17:20  neal
// Made the files get through Silos compilation.
//
// Revision 1.1  2007/02/05 17:11:30  jperry
// initial async FIFO files.  Copied, modified from dn_fpgacode/FIFO.  This may be cleaned up later.
//
// Revision 1.3  2006/07/17 20:56:56Z  jthurkettle
// test
// **************************************************************************

`ifdef INCL_INFER_SELECTRAM
`else // INCL_INFER_SELECTRAM
`define INCL_INFER_SELECTRAM

//This was broken out from fifo_unidir_sel.v

// infer an SRL RAM, non-registered reads.
`ifdef ALTERA
(* keep = 1 *) module infer_selectram #(parameter 
`else
(* keep_hierarchy = "yes" *) module infer_selectram #(parameter 
`endif
	d_width=32,
	addr_width=5,
	initialized=-1 // -1='x', 0=cleared to '0', 1=set to '1', 2=random
) (
   output [d_width - 1:0]   o,
   input                    we,
   input                    clk,
   input [d_width - 1:0]    d,
   input [addr_width - 1:0] raddr,
   input [addr_width - 1:0] waddr
   );

`ifdef ALTERA
   (* ramstyle = "MLAB" *) reg [d_width - 1:0]  mem [(1 << addr_width) - 1:0];
`else
   (* ram_style = "distributed" *) reg [d_width - 1:0]  mem [(1 << addr_width) - 1:0] /* synthesis syn_ramstyle = select_ram */;
`endif

   always @(posedge clk)
     if (we)
       mem[waddr] <= d;

   assign o = mem[raddr];

// synthesis translate_off
integer clear_addr;
initial begin
	for (clear_addr=0;clear_addr< (1 << addr_width);clear_addr=clear_addr+1) begin
		case (initialized)
			//-1: mem[clear_addr] = 'bx;
			 0: mem[clear_addr] = 'b0;
			 1: mem[clear_addr] = -1;
			 2: mem[clear_addr] = $random;
		endcase
	end
end
// synthesis translate_on

endmodule

`endif // INCL_INFER_SELECTRAM
