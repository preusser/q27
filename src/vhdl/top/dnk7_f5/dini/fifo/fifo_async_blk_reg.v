// **********************************************************************
// $Header: /var/lib/cvs/dncvs/FPGA/dini/fifo/fifo_async_blk_reg.v,v 1.23 2014/08/08 18:23:41 neal Exp $
// **********************************************************************
// Description:
//
//   A modification to the BLKRAM FIFO so that the input data/control, and
// output data/control are registered before going to the BLKRAM.  This is
// to make timing closure easier.
//
//   This module should NOT be used in places where latency is important.
//
//   INPUT_REG==1 adds a FF to wr_en and wr_din[].
//
//   OUTPUT_REG==1 adds 2 FFs to rd_en and rd_dout[].
//   OUTPUT_REG==2 adds 1 FFs to rd_dout[] (rd_en has large fanouts/luts).
//   OUTPUT_REG==3 uses BRAM output FFs (rd_en has large fanouts/luts).
//
// **********************************************************************
// $Log: fifo_async_blk_reg.v,v $
// Revision 1.23  2014/08/08 18:23:41  neal
// Fixed the selram pre-fifo pair's depth so that it isn't larger than the original fifo was asked to be.
//
// Revision 1.22  2014/08/06 20:44:09  bpoladian
// Use a parameter to enable FIFO checksum.
//
// Revision 1.21  2014/07/30 22:43:10  neal
// Added a parameter.
//
// Revision 1.20  2014/07/24 17:54:52  neal
// Added simulation notes about un-registered RAMs.
//
// Revision 1.19  2014/07/21 18:21:41  neal
// Shrank the checksum logic.
//
// Revision 1.18  2014/07/18 17:22:34  neal
// Fixed ONECLOCK with the selram is added.
//
// Revision 1.17  2014/07/18 16:59:55  neal
// Added an option to control the checksum delay from write to read.
// Added an optional selram fifo for the clock domain change.
//
// Revision 1.16  2014/07/17 22:01:07  neal
// Added parameters to include data checksums in the FIFO.
//
// Revision 1.15  2014/07/08 20:42:32  neal
// Didn't pass the simulation data clobbering to the non-registered fifo.
//
// Revision 1.14  2014/07/08 15:20:02  neal
// Added optional output register with REGCE to rams.
// Added option to use RAM's output register.
// Added checksums to all async fifos (enabled by define).
//
// Revision 1.13  2014/07/02 12:54:39  neal
// Disabled some of the extra checksum checks (to make it smaller).
//
// Revision 1.12  2014/07/01 23:03:50  neal
// Fixed an unregistered reset that changes clock domains.
//
// Revision 1.11  2014/07/01 19:18:45  neal
// Added checksums to wr_din and rd_dout with a sticky error bit that can be read back.
//
// Revision 1.10  2014/06/12 18:19:16  neal
// Removed reset from more datapath.
//
// Revision 1.9  2014/06/12 18:14:42  neal
// Removed reset from datapath.
//
// Revision 1.8  2014/05/13 20:25:49  neal
// Added a registered selectram FIFO.
// Fixed the optional reset FF on the rd_clk domain.
//
// Revision 1.7  2014/05/01 20:19:35  neal
// Added 2 output status signals for having data in the output FFs.
//
// Revision 1.6  2014/04/14 17:52:51  neal
// Added a second output register mode (single output FF).
//
// Revision 1.5  2014/03/06 21:43:46  neal
// Resync'd reset to the correct clock domain.
//
// Revision 1.4  2013/01/23 21:22:29  claudiug
// removed timescale declaration from all fifo_ files
//
// Revision 1.3  2013/01/07 19:55:57  neal
// Timing closure changes.
// Added a write and read data checksum (for logic analyzer use).
// Added optional clobbering of output data when not reading (simulation only).
//
// Revision 1.2  2012/11/26 16:54:21  neal
// Fixed up some status output ports to make them more usable in some conditions.
//
// Revision 1.1  2012/06/05 02:59:29  neal
// Added a pipelined FIFO.
//
// **********************************************************************

/*verilator tracing_off*/
`ifdef INC_FIFO_ASYNC_BLK_REG_V
`else
`define INC_FIFO_ASYNC_BLK_REG_V

`include "dini/fifo/fifo_async_blk_ramreg.v"
`include "dini/fifo/fifo_checksum.v"

module fifo_async_blk_reg #(
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
  parameter INPUT_REG        = 1,
  parameter OUTPUT_REG       = 1, // 0==rd_dout from BRAM, 1==fast setup(rd_en) AND fast clk_out(rd_dout), 2==fast(rd_dout) & slow(rd_en)
  parameter EXTRA_CHECKSUM_ENABLE = 0,
  parameter EXTRA_CHECKSUM_DATA_BITS = 8,
  parameter ADD_SELRAM_CDC_FIFO_INPUT = 0,
  parameter ADD_SELRAM_CDC_FIFO_OUTPUT = 0,
  `ifdef USE_FIFO_CHECKSUM
    parameter USE_FIFO_CHECKSUM = 1
  `else
    parameter USE_FIFO_CHECKSUM = 0
  `endif
) (
  input               reset,

  input               wr_clk,
  input               wr_en,
  input  [DATA_W-1:0] wr_din,
  output              wr_full_flaky, // not available if INPUT_REG==1
  output              wr_almostfull,
  output [ADDR_W:0]   wr_full_count_flaky, // not available if INPUT_REG==1

  input               rd_clk,
  input               rd_en,
  output [DATA_W-1:0] rd_dout,
  output              rd_empty,
  output [ADDR_W:0]   rd_empty_count,
  output [1:0]        rd_empty_ff
);

localparam TOTAL_DATA_W = DATA_W + EXTRA_CHECKSUM_DATA_BITS*EXTRA_CHECKSUM_ENABLE;

reg wr_en_d;
reg [DATA_W-1:0] wr_din_d;
wire [DATA_W-1:0] fifo_rd_dout;

always @(posedge wr_clk or posedge reset) begin
	if (reset) begin
		wr_en_d <= 'b0;
	end else begin
		wr_en_d <= wr_en;
	end
end

always @(posedge wr_clk) begin
		wr_din_d <= wr_din;
end

wire [ADDR_W:0]   wr_full_count_preclobber; // not available if INPUT_REG==1
wire [ADDR_W:0]   wr_full_count_blkram;
wire [5:0]   wr_full_count_selram;
reg reg_rd_empty;

reg [EXTRA_CHECKSUM_DATA_BITS-1:0] write_checksum_data;
reg [EXTRA_CHECKSUM_DATA_BITS-1:0] read_checksum_data;
`DEBUG_KEEP reg checksum_error;
wire [DATA_W-1:0] wr_din_optdelay = (INPUT_REG ? wr_din_d : wr_din);
wire wr_full_preclobber;

always @(posedge wr_clk) begin
	if (EXTRA_CHECKSUM_ENABLE != 0) begin
		if (reset) begin
			write_checksum_data <= 'b0;
		end else begin
			if ( ((INPUT_REG ? wr_en_d : wr_en)==1'b1) && (wr_full_preclobber==1'b0) ) begin
				write_checksum_data <= write_checksum_data
					^ (wr_din_optdelay >> 0*EXTRA_CHECKSUM_DATA_BITS)
					^ (wr_din_optdelay >> 1*EXTRA_CHECKSUM_DATA_BITS)
					^ (wr_din_optdelay >> 2*EXTRA_CHECKSUM_DATA_BITS)
					^ (wr_din_optdelay >> 3*EXTRA_CHECKSUM_DATA_BITS)
					^ (wr_din_optdelay >> 4*EXTRA_CHECKSUM_DATA_BITS)
					^ (wr_din_optdelay >> 5*EXTRA_CHECKSUM_DATA_BITS)
					^ (wr_din_optdelay >> 6*EXTRA_CHECKSUM_DATA_BITS)
					^ (wr_din_optdelay >> 7*EXTRA_CHECKSUM_DATA_BITS); // limit the FF to having 11 inputs (2 LUTs)
			end
		end
	end
end

wire [TOTAL_DATA_W - 1:0] wr_din_checksum = {write_checksum_data,wr_din_optdelay};
wire [TOTAL_DATA_W - 1:0] fifo_rd_dout_checksum;

initial begin
	if (OUTPUT_REG!=3)
		$display("NOTE: %m using OUTPUT_REG=%d",OUTPUT_REG);
	if ((ADD_SELRAM_CDC_FIFO_INPUT!=0) && (ADD_SELRAM_CDC_FIFO_OUTPUT!=0)) begin
		$display("ERROR: can't have both input and output SELRAM CDC FIFOS: %m");
		$stop;
	end
	if (((ADD_SELRAM_CDC_FIFO_INPUT!=0) || (ADD_SELRAM_CDC_FIFO_OUTPUT!=0)) && (ONECLOCK==1)) begin
		$display("ERROR: can't have SELRAM CDC FIFOS with ONECLOCK==1: %m");
		$stop;
	end
end

wire reset_rdclk;

wire wr_full_blkram;
wire wr_en_blkram;
wire [TOTAL_DATA_W-1:0] wr_din_blkram;
wire wr_almostfull_blkram;

generate
	if (ADD_SELRAM_CDC_FIFO_INPUT) begin
		fifo_async_sel #(
  		.ADDR_W(5),
  		.DATA_W(TOTAL_DATA_W),
  		.ALMOSTFULL_LIMIT(ALMOSTFULL_LIMIT + INPUT_REG),
  		.ONECLOCK(0),
  		.GEN_RDCOUNT(0),
  		.IGNORE_FULL_WR(IGNORE_FULL_WR),
  		.GEN_WRCOUNT(GEN_WRCOUNT),
  		.GEN_WRALMOSTFULL(GEN_WRALMOSTFULL)
		) i_sel_fifo (
  		.reset(reset),

  		.wr_clk(wr_clk),
  		.wr_en(INPUT_REG ? wr_en_d : wr_en),
  		.wr_din(wr_din_checksum), //.wr_din(INPUT_REG ? wr_din_d : wr_din),
  		.wr_full(wr_full_preclobber),
  		.wr_almostfull(wr_almostfull),
  		.wr_full_count(wr_full_count_selram),

  		.rd_clk(rd_clk),
  		.rd_en(wr_en_blkram),
  		.rd_dout(wr_din_blkram),
  		.rd_empty(fifo_rd_empty_selram),
  		.rd_empty_count()
		);
		assign wr_en_blkram = (~wr_almostfull_blkram) & (~fifo_rd_empty_selram);
		assign wr_full_count_preclobber = wr_full_count_selram;
	end else begin
		assign wr_full_preclobber = wr_full_blkram;
		assign wr_en_blkram = (INPUT_REG ? wr_en_d : wr_en);
		assign wr_din_blkram = wr_din_checksum;
		assign wr_almostfull = wr_almostfull_blkram;
		assign wr_full_count_preclobber = wr_full_count_blkram;
	end
endgenerate

fifo_async_blk_ramreg #(
  .ADDR_W(ADDR_W),
  .DATA_W(TOTAL_DATA_W),
  .ALMOSTFULL_LIMIT(ADD_SELRAM_CDC_FIFO_INPUT ? 33 : ALMOSTFULL_LIMIT + INPUT_REG), // use the depth of the selram FIFO when it is enabled (to make this FIFO not seem bigger than it should have been)
  .ONECLOCK(ONECLOCK | ADD_SELRAM_CDC_FIFO_INPUT | ADD_SELRAM_CDC_FIFO_OUTPUT),
  .GEN_RDCOUNT(GEN_RDCOUNT),
  .GEN_WRCOUNT(GEN_WRCOUNT),
  .IGNORE_FULL_WR(IGNORE_FULL_WR),
  .GEN_WRALMOSTFULL(GEN_WRALMOSTFULL),
  .SIM_EMPTY_X(1'b0),
  .SIM_NOTRD_X(1'b0),
  .EXTERNALLY_OUTPUT_REGISTERED(OUTPUT_REG),
  .REGRAM(OUTPUT_REG==3)
) i_fifo (
  .reset(ADD_SELRAM_CDC_FIFO_INPUT ? reset_rdclk : reset),

  .wr_clk(ADD_SELRAM_CDC_FIFO_INPUT ? rd_clk : wr_clk),
  .wr_en(wr_en_blkram),
  .wr_din(wr_din_blkram), //.wr_din(INPUT_REG ? wr_din_d : wr_din),
  .wr_full(wr_full_blkram),
  .wr_almostfull(wr_almostfull_blkram),
  .wr_full_count(wr_full_count_blkram),

  .rd_clk(ADD_SELRAM_CDC_FIFO_OUTPUT ? wr_clk : rd_clk),
  .rd_en(OUTPUT_REG ? fifo_rd_en : rd_en),
  .ram_reg_ce(reg_rd_empty | rd_en),
  //.rd_dout(fifo_rd_dout),
  .rd_dout(fifo_rd_dout_checksum),
  .rd_empty(fifo_rd_empty),
  .rd_empty_count(rd_empty_count)
);

assign fifo_rd_dout = fifo_rd_dout_checksum; // take the lower bits
wire [EXTRA_CHECKSUM_DATA_BITS-1:0] fifo_rd_checksum = (fifo_rd_dout_checksum>>DATA_W); // take the upper bits

assign wr_full_flaky       = (INPUT_REG ? 'bx : wr_full_preclobber);
assign wr_full_count_flaky = (INPUT_REG ? 'bx : wr_full_count_preclobber);

reg ff_rd_empty;
reg [DATA_W-1:0] ff_rd_dout;
reg [DATA_W-1:0] reg_rd_dout;

// ****************************************
// A 2 clock cycle deep FIFO, optimized for
// rd_dout[] and rd_en timing.  Should
// mainly be used when rd_en depends on rd_dout[].
// ****************************************

reset_resync i_rst (
	.clk_in(wr_clk),
	.rst_in(reset),
	.clk_out(rd_clk),
	.rst_out(reset_rdclk_ff)
);

assign reset_rdclk = (ONECLOCK ? reset : reset_rdclk_ff);

always @(posedge rd_clk) begin
	if (EXTRA_CHECKSUM_ENABLE != 0) begin
		if (reset_rdclk) begin
			read_checksum_data <= 'b0;
			checksum_error <= 'b0;
		end else begin
			if ( (rd_en==1'b1) && (rd_empty==1'b0) ) begin
				read_checksum_data <= read_checksum_data
					^ (fifo_rd_dout >> 0*EXTRA_CHECKSUM_DATA_BITS)
					^ (fifo_rd_dout >> 1*EXTRA_CHECKSUM_DATA_BITS)
					^ (fifo_rd_dout >> 2*EXTRA_CHECKSUM_DATA_BITS)
					^ (fifo_rd_dout >> 3*EXTRA_CHECKSUM_DATA_BITS)
					^ (fifo_rd_dout >> 4*EXTRA_CHECKSUM_DATA_BITS)
					^ (fifo_rd_dout >> 5*EXTRA_CHECKSUM_DATA_BITS)
					^ (fifo_rd_dout >> 6*EXTRA_CHECKSUM_DATA_BITS)
					^ (fifo_rd_dout >> 7*EXTRA_CHECKSUM_DATA_BITS); // limit the FF to having 11 inputs (2 LUTs)

				if (read_checksum_data != fifo_rd_checksum) begin
					checksum_error <= 'b1;
					$display("ERROR: FIFO data checksum error %x!=%x: %m %t",read_checksum_data, fifo_rd_checksum, $time);
					$stop;
				end
			end
		end
	end
end

always @(posedge rd_clk /*or posedge reset_rdclk*/) begin
		/*
	if (reset_rdclk) begin
		reg_rd_empty <= 1'b1; // output empty from registered FIFO
		ff_rd_empty <= 1'b1;
		reg_rd_dout <= 'b0; // output FF from registered FIFO
		ff_rd_dout <= 'b0; // secondary FF between FIFO and output FF
	end else
			*/
	begin
		if ((ff_rd_empty==1'b1) && (OUTPUT_REG==1)) begin
			ff_rd_dout <= fifo_rd_dout;
			ff_rd_empty <= fifo_rd_empty;
		end
		if (reg_rd_empty | rd_en) begin
			if (ff_rd_empty) begin
				reg_rd_dout <= fifo_rd_dout;
				reg_rd_empty <= fifo_rd_empty;
			end else begin
				reg_rd_dout <= ff_rd_dout;
				reg_rd_empty <= ff_rd_empty;
			end
			ff_rd_empty <= 1'b1;
		end
	end

	if (OUTPUT_REG==0) begin
			// output FFs aren't used.
		ff_rd_dout <= 'b0;
		ff_rd_empty <= 'b1;
		reg_rd_dout <= 'b0;
		reg_rd_empty <= 'b1;
	end
	if (OUTPUT_REG!=1) begin
			// second output FF isn't used.
		ff_rd_dout <= 'b0;
		ff_rd_empty <= 'b1;
	end

	if (reset_rdclk) begin
		reg_rd_empty <= 1'b1; // output empty from registered FIFO
		ff_rd_empty <= 1'b1;
	end
end
  assign rd_empty_ff[0] = reg_rd_empty | (OUTPUT_REG==0);
  assign rd_empty_ff[1] = ff_rd_empty | (OUTPUT_REG!=1);


generate
	if (OUTPUT_REG==1) begin
		assign fifo_rd_en = ff_rd_empty | reg_rd_empty; // don't use rd_en in this equation.  That would violate the purpose of this module!
	end else begin
		assign fifo_rd_en = reg_rd_empty | rd_en; // use rd_en in this equation.
	end
endgenerate

assign rd_empty = (OUTPUT_REG ? reg_rd_empty : fifo_rd_empty);
assign rd_dout = (((OUTPUT_REG!=0) && (OUTPUT_REG!=3)) ? reg_rd_dout : fifo_rd_dout);

// synthesis translate_off
assign rd_dout = (SIM_EMPTY_X & rd_empty ? {DATA_W{1'bx}} : {DATA_W{1'bz}} ); // Drive 'x' on read data bus when empty in simulation.
assign rd_dout = (SIM_NOTRD_X & (~rd_en) ? {DATA_W{1'bx}} : {DATA_W{1'bz}} ); // Drive 'x' on read data bus when empty in simulation.
// synthesis translate_on

generate
if(USE_FIFO_CHECKSUM!=0) begin: gen_fifo_checksum
  fifo_checksum #(
    .DATA_W(DATA_W),
    .ONECLOCK(ONECLOCK),
    .ERROR_SHIFT_BITS(4 + 2 * (ADD_SELRAM_CDC_FIFO_INPUT + ADD_SELRAM_CDC_FIFO_OUTPUT))
  ) i_fifo_checksum (
    .wr_reset (reset),
    .rd_reset (reset_rdclk),

    .wr_clk   (wr_clk),
    .wr_en    (wr_en),
    .wr_full  (wr_full_preclobber),
    .wr_data  (wr_din),

    .rd_clk   (rd_clk),
    .rd_en    (rd_en),
    .rd_empty (rd_empty),
    .rd_data  (rd_dout),

    .checksum_error() // not connected...
  );
end
endgenerate

endmodule // fifo_async_blk_reg

`endif
/*verilator tracing_on*/
