// ***********************************************************
// $Header: /var/lib/cvs/dncvs/FPGA/dini/fifo/fifo_checksum.v,v 1.8 2014/08/28 22:04:32 neal Exp $
// ***********************************************************
// Description:
//
//   Calculates checksums on FIFO wr/rd data.
// ***********************************************************
// $Log: fifo_checksum.v,v $
// Revision 1.8  2014/08/28 22:04:32  neal
// Fixed bus indexes.
//
// Revision 1.7  2014/07/21 18:21:18  neal
// Shrank the checksum logic.
//
// Revision 1.6  2014/07/18 16:59:56  neal
// Added an option to control the checksum delay from write to read.
// Added an optional selram fifo for the clock domain change.
//
// Revision 1.5  2014/07/10 18:20:05  neal
// Increased the size of the shift, to account for different clock rates.
//
// Revision 1.4  2014/07/08 15:20:02  neal
// Added optional output register with REGCE to rams.
// Added option to use RAM's output register.
// Added checksums to all async fifos (enabled by define).
//
// Revision 1.3  2014/07/02 12:54:39  neal
// Disabled some of the extra checksum checks (to make it smaller).
//
// Revision 1.2  2014/07/01 23:03:50  neal
// Fixed an unregistered reset that changes clock domains.
//
// Revision 1.1  2014/07/01 19:18:46  neal
// Added checksums to wr_din and rd_dout with a sticky error bit that can be read back.
//
// ***********************************************************

`ifdef INCL_FIFO_CHECKSUM_V
`else
`define INCL_FIFO_CHECKSUM_V

`ifndef DEBUG_KEEP
`define DEBUG_KEEP (* dont_touch="TRUE", keep="TRUE" *)
`endif // DEBUG_KEEP


(* keep_hierarchy = "yes" *) module fifo_checksum #(
	parameter DATA_W = 1,
	parameter ONECLOCK = 1,
  	parameter EXTERNALLY_OUTPUT_REGISTERED = 0,
	parameter ERROR_SHIFT_BITS = 4
) (
	input wr_reset,
	input rd_reset,

	input wr_clk,
	input wr_en,
	input wr_full,
	input [DATA_W-1:0] wr_data,

	input rd_clk,
	input rd_en,
	input rd_empty,
	input [DATA_W-1:0] rd_data,

	`DEBUG_KEEP output reg checksum_error
);


// ******************************************
// Generate running checksum on wr_data.
// Only pay attention to the first 8-bits of the data for the checksum.
// ******************************************

localparam CHECKSUM_W = (DATA_W<16) ? (DATA_W+1)/2 : 4;

reg [CHECKSUM_W-1:0] wr_checksum;
always @(posedge wr_clk) begin
	if ((wr_en==1'b1) && (wr_full==1'b0)) begin
		wr_checksum <= wr_checksum ^ wr_data ^ (wr_data >> CHECKSUM_W);
	end
	if (wr_reset ) begin
		wr_checksum <= 'b0;
	end
end

// ******************************************
// Generate running checksum on rd_data.
// ******************************************

reg [CHECKSUM_W-1:0] rd_checksum;
always @(posedge rd_clk) begin
	if ((rd_en==1'b1) && (rd_empty==1'b0)) begin
		rd_checksum <= rd_checksum ^ rd_data ^ (rd_data >> CHECKSUM_W);
	end
	if (rd_reset) begin
		rd_checksum <= 'b0;
	end
end

// ******************************************
// Compare wr_checksum to rd_checksum when the FIFO is really empty.
// ******************************************

reg error_shift;
reg [ERROR_SHIFT_BITS-1:0] error_counter;

always @(posedge rd_clk) begin
	if (
`ifdef USE_SYNC_FIFO_CHECKSUM
`else
			ONECLOCK |
`endif
			EXTERNALLY_OUTPUT_REGISTERED) begin
		// do nothing (i.e. don't create the FFs)
	end else begin
		error_shift <= 1'b0;
		if (rd_empty==1'b1) begin
			if (rd_checksum != wr_checksum) begin
				error_shift <= 1'b1;
			end
		end
		if (error_shift==1'b1)
				error_counter <= error_counter+1'b1;
		else
				error_counter <= 1'b0;

		if (&error_counter) begin
			$display("ERROR: %m fifo checksums don't match: %x != %x\n",wr_checksum, rd_checksum);
			$stop;
			checksum_error <= 1'b1;
		end

		if (rd_reset) begin
			checksum_error <= 1'b0;
			error_shift <= 'b0;
			error_counter <= 'b0;
		end
	end
end

endmodule // fifo_checksum

`endif // INCL_FIFO_CHECKSUM_V
