// ***************************************************************************
// $Header: /var/lib/cvs/dncvs/FPGA/dini/fifo/fifo_addr.v,v 1.38 2015/04/30 00:38:34 bpoladian Exp $
// ***************************************************************************
// $Log: fifo_addr.v,v $
// Revision 1.38  2015/04/30 00:38:34  bpoladian
// When not generating read or write counts, keep overriding always block hidden from synthesis for ISE compatibility.
//
// Revision 1.37  2015/03/12 00:18:45  bpoladian
// Added define to not include overflow check.
//
// Revision 1.36  2015/03/12 00:13:24  bpoladian
// Drive almostfull to 0 in synthesis when not generating signal.
//
// Revision 1.35  2015/03/11 23:50:21  bpoladian
// Drive counts to 0 in synthesis when not enabling them.
//
// Revision 1.34  2014/12/04 01:17:34  bpoladian
// Commented out assignment of unused register b/c of optimization error in ISE.
//
// Revision 1.33  2014/11/11 05:35:45  bpoladian
// Prevent declaration of registers with async_reg attribute when those registers will not be used.
//
// Revision 1.32  2014/10/29 20:03:15  neal
// Fixed some bit-width issues.
//
// Revision 1.31  2014/09/02 21:51:45  neal
// Added an option to allow selectram FIFOs have quicker data output when empty.
//
// Revision 1.30  2014/08/25 23:59:26  neal
// Reduced simulation collision warnings.
//
// Revision 1.29  2014/08/24 00:42:45  neal
// Made infer_blkram instances do an extra write and read before the first valid one.
//
// Revision 1.28  2014/08/13 15:34:11  neal
// Don't read_en the ram until after the write has been completed.
//
// Revision 1.27  2014/08/07 05:00:40  neal
// Removed a comment.
//
// Revision 1.26  2014/07/18 18:10:58  neal
// Added a check for reasonable almost full limits.
//
// Revision 1.25  2014/07/18 17:08:10  neal
// Added an almostfull check.
//
// Revision 1.24  2014/07/17 22:00:37  neal
// Added Vivado constraints for ASYNC_REG.
//
// Revision 1.23  2014/07/10 03:05:02  claudiug
// added synthesis translate_off/on around simulation block
//
// Revision 1.22  2014/07/02 12:54:39  neal
// Disabled some of the extra checksum checks (to make it smaller).
//
// Revision 1.21  2014/07/01 19:18:45  neal
// Added checksums to wr_din and rd_dout with a sticky error bit that can be read back.
//
// Revision 1.20  2014/05/19 16:56:59  neal
// Added a parameter to remove some safety logic to increase the clock rate.
//
// Revision 1.19  2014/05/09 20:43:10  bpoladian
// Added simulation check for ONECLOCK parameter.
//
// Revision 1.18  2013/12/19 00:05:07  bpoladian
// Updated value of syn_preserve to avoid warning.
//
// Revision 1.17  2013/01/23 21:22:29  claudiug
// removed timescale declaration from all fifo_ files
//
// Revision 1.16  2013/01/07 19:55:57  neal
// Timing closure changes.
// Added a write and read data checksum (for logic analyzer use).
// Added optional clobbering of output data when not reading (simulation only).
//
// Revision 1.15  2012/12/06 20:23:27  claudiug
// added ifndef so that iverilog simulation works
//
// Revision 1.14  2012/10/04 19:57:32  bpoladian
// Added overflow bit that doesn't leave this module - for internal debugger purposes only.
//
// Revision 1.13  2012/06/28 17:44:49  neal
// Added a simulation initial value.
//
// Revision 1.12  2012/06/19 23:30:07  neal
// Resync'd reset to the correct clock domain.
//
// Revision 1.11  2012/04/24 17:36:28  bpoladian
// Changed synthesis ifdefs to translate directives.
//
// Revision 1.10  2011/12/21 19:46:26  bpoladian
// Don't synthesize count assignments to X w/ empty sensitivity lists.
//
// Revision 1.9  2011/12/05 22:16:04  neal
// Fixed toe_interrupt.
// Reduced toe ram utilization.
// Allowed digitfinder to have some constant input ports (selectable by parameter).
// Changed some brams to be single bram with byte write enables.
// Allowed some FIFO ports to not be generated (xst warnings).
//
// Revision 1.8  2011/09/29 20:25:26  neal
// Fixed a synthesis warning.
//
// Revision 1.7  2011/09/29 20:05:01  neal
// Fixed some synthesis warnings.
//
// Revision 1.6  2011/09/14 01:02:08  bpoladian
// Changed asynchronous always blocks into assign statements.
//
// Revision 1.5  2010/11/16 03:12:15  bpoladian
// Added read enable port for blockram.
//
// Revision 1.4  2010/10/05 22:12:51  bpoladian
// Added syn_keep to gray counter registers.
//
// Revision 1.3  2008/04/11 01:38:02  bpoladian
// Ran dos2unix.  Removed comments on `else and `endif lines.
//
// Revision 1.2  2007/08/16 22:45:11  jperry
// Removed #1 to assignments, because it made it a blocking statement and was messing up simulation.
// We may need to add something like this again if we ever use Silos to simulate this file.
//
// Revision 1.1  2007/06/13 17:54:39  jperry
// copied from timelogic area.  Not sure where this stuff will go in the end.
//
// Revision 1.11  2007/04/25 14:15:15  neal
// Removed the ifndef lines because Silos wouldn't accept them.
//
// Revision 1.10  2007/04/24 18:10:22  neal
// ifdef'd out the $display statements during synthesis.
//
// Revision 1.9  2007/04/23 20:37:21  neal
// Removed a "$stop;" because Silos crashes.
//
// Revision 1.8  2007/04/13 22:59:45  neal
// Added simulation error messages for invalid control signals to the FIFO.
//
// Revision 1.7  2007/03/24 01:22:00  neal
// Fixed some infinite loops with Silos simulator.
//
// Revision 1.6  2007/03/06 16:03:59  neal
// Made the fifo able to be synchronous to 1 clock domain to make it smaller and faster.
//
// Revision 1.5  2007/02/20 18:46:49  neal
// Fixed a mistake with the empty flag.
//
// Revision 1.4  2007/02/20 18:25:47  neal
// Fixed the FIFO controls so that it behaves in the proper manner.
// Cleaned up the code, and removed some duplicate registers.
// Decreased the fan-out on rd_en and wr_en.
// Made rd_en only control a single logic delay before any FF to improve timing.
// Fixed the empty_count and full_count outputs so that they are accurate and are relative to the correct empty/full-ness of the FIFO (instead of both being related to empty).
//
// Revision 1.3  2007/02/11 01:06:15  neal
// Made the blast design meet 100 Mhz timing.
//
// Revision 1.2  2007/02/08 18:17:20  neal
// Made the files get through Silos compilation.
//
// Revision 1.1  2007/02/05 17:11:30  jperry
// initial async FIFO files.  Copied, modified from dn_fpgacode/FIFO.  This may be cleaned up later.
//
// ***************************************************************************

`ifdef INCL_FIFO_ADDR
`else
`define INCL_FIFO_ADDR

// DEFINE "BETTER_TIMING" TO MAKE IT 4 CLOCK CYCLES FROM wr_en -> EMPTY_FLAG AND rd_en -> FULL_FLAG
// THIS WILL MAKE THE FIFO RUN AT MUCH HIGHER SPEEDS BY SPLITTING GREY-CODE LOGIC ACROSS 2 CLOCK CYCLES
// IF NOT DEFINED, IT IS 3 CLOCK CYCLES FROM wr_en -> empty FLAG AND rd_en -> FULL_FLAG

`include "dini/misc/reset_resync.v"
`define BETTER_TIMING

module fifo_addr
  (
   wr_clk,
   wr_en,
   wr_addr,
   wr_en_ram,
   wr_full,
   wr_almost_full,
   wr_full_count,  // amount can write until full

   rd_clk,
   rd_en,
   rd_addr,
   rd_en_ram,
   rd_empty,
   rd_empty_count,  // amount can read until empty

   fifo_reset
);
   // removed CNTR_W, because counters will be 1 bit more than addresses
   parameter ADDR_W = 5;           // number of bits wide for address
   parameter ALMOSTFULL_LIMIT = 4; // number of entries left before almost full active
   parameter DELAY_READ = 0; // Set to 1 when using blockram (1 clock delay to
                             // get data back), set to 0 when using selectram
   parameter ONECLOCK = 1'b0; // set to 1 to get rid of resync logic.
   parameter GEN_RDCOUNT = 1;
   parameter GEN_WRCOUNT = 1;
   parameter GEN_WRALMOSTFULL = 1;
   parameter IGNORE_FULL_WR = 1'b0; // set to 1 to allow WR to go through when FULL is asserted (breaks the FIFO, but allows much higher clock rates). WARNING: setting this parameter can make the FIFO misbehave
   parameter IGNORE_EMPTY_RD = 1'b0; // set to 1 to allow RD to go through when EMPTY is asserted (breaks the FIFO, but allows much higher clock rates). WARNING: setting this parameter can make the FIFO misbehave
   parameter FAST_WR_TO_RD = 1'b0; // set to 1 to allow RD the following clk after WR

   input wr_clk;
   input wr_en;
   output [ADDR_W-1:0] wr_addr;
   output wr_en_ram;
   output wr_full;
   output wr_almost_full;
   output [ADDR_W:0] wr_full_count;  // amount can write until full

   input rd_clk;
   input rd_en;
   output [ADDR_W-1:0] rd_addr;
   output rd_empty;
   output [ADDR_W:0] rd_empty_count;  // amount can read until empty
   output rd_en_ram;

   input fifo_reset;

// **********************************************************
// Reg and wire declarations
// **********************************************************

   reg allempty_rdclk;
   reg allfull_wrclk;
   reg wr_almost_full;

   wire read_allow, write_allow;

   reg [ADDR_W:0]    read_address;
   wire [ADDR_W:0]   read_address_plus1 /* synthesis syn_keep=1 */;
   reg [ADDR_W:0]    read_addrgray      /* synthesis syn_keep=1 */;

   reg [ADDR_W:0]    write_address;
   reg [ADDR_W:0]    write_addrgray /* synthesis syn_keep=1 */;

// Calculation of empty count

   reg [ADDR_W:0]    write_address_r;
   wire              write_equals_read_noread   /* synthesis syn_keep=1 */;
   wire              write_equals_read_withread   /* synthesis syn_keep=1 */;
   wire [ADDR_W:0]   write_minus_read_noread   /* synthesis syn_keep=1 */;
   wire [ADDR_W:0]   write_minus_read_withread /* synthesis syn_keep=1 */;
   reg [ADDR_W:0]    rd_empty_count;

   // Calculation of full count

   reg [ADDR_W:0]    read_address_w;
   wire [ADDR_W:0]   read_minus_write;
   reg [ADDR_W:0]    wr_full_count;

   genvar            ra_cnt;

   //reg               wr_en_ram_d;

// **********************************************************
// output assignments
// **********************************************************

	reg pre_first_read;
	wire reset_rdclk;

	always @(posedge rd_clk or posedge reset_rdclk) begin
		if (reset_rdclk) begin
			pre_first_read <= 1'b1;
		end else begin
			//if (read_allow)
				pre_first_read <= 1'b0;
		end
	end 

	assign wr_full        = allfull_wrclk;
	assign rd_empty       = allempty_rdclk;
	assign wr_en_ram      = write_allow | fifo_reset; // 7series rams have reset assertion issues for the first read/write, so do a bunch of extra writes.
	//assign rd_en_ram      = (read_allow ? (~write_equals_read_withread) : (allempty_rdclk & (~write_equals_read_noread) )) | reset_rdclk; // 7series RAMS have reset assertion issues for the first read/write, so do a bunch of extra reads.
	assign rd_en_ram      = (read_allow ? (~write_equals_read_withread) : (allempty_rdclk & (~write_equals_read_noread) )) | ((~reset_rdclk) & pre_first_read) | (wr_en & FAST_WR_TO_RD[0] & ONECLOCK[0]); // 7series RAMS have reset assertion issues for the first read/write, so do a bunch of extra reads.

   //always @ (posedge wr_clk or posedge fifo_reset) begin
     //if (fifo_reset) begin
      //wr_en_ram_d <= 'b0;
     //end else begin
      //wr_en_ram_d <= wr_en_ram;
     //end
   //end

   // when blockram, output next address 1 clock cycle early
   // to compensate for 1 clock cycle out of block ram
   assign read_address_plus1 = read_address + 1'b1;
   assign rd_addr = (DELAY_READ ? (read_allow ? read_address_plus1[ADDR_W-1:0] : read_address[ADDR_W-1:0] ) : read_address[ADDR_W-1:0]);
   assign wr_addr = write_address[ADDR_W-1:0];

/**********************************************************\
*                                                          *
*  Generation of Read address pointers.  Several Gray-     *
*  code addresses are pipelined; each calculates one       *
*  particular level of Almost Full or Almost Empty.  At    *
*  each end of the pipeline is a binary counter from       *
*  which the Gray-code values are calculated.  The Gray-   *
*  code registers' initial values are important, as they   *
*  need to be in proper Gray-code sequence for the Full,   *
*  Empty, et al flags to work properly.                    *
*                                                          *
*  Gray-code addresses are used so that the registered     *
*  Full and Empty flags are always clean, and are never    *
*  in a spurious state brought about by the Read and       *
*  Write clocks' asynchronicity.  In the worst-case        *
*  scenario, Full and Empty would simply stay active one   *
*  cycle longer, and they would not generate an error or   *
*  give false values.                                      *
*                                                          *
\**********************************************************/

  `ifndef NO_OVERFLOW_CHECK
    (* dont_touch = "true", keep = "true" *) reg overflow;
    always @ (posedge wr_clk or posedge fifo_reset) begin 
      if(fifo_reset) begin
        overflow <= 'b0;
      end else begin
        if(wr_en & wr_full) begin
          overflow <= 'b1;
    /* synthesis translate_off*/
      $display("WARNING: %m: writing to a full fifo: time=%t",$time);
      if (IGNORE_FULL_WR) begin
        $display("ERROR: %m: Writing to a FULL FIFO: IGNORE_FULL_WR=1, FULL=1, WR=1, time=%t",$time);
        $stop;
      end
    /* synthesis translate_on*/
        end
      end
    end
  `endif

   integer rg_cnt;
	reset_resync i_rst (
			.clk_in(wr_clk),
			.rst_in(fifo_reset),
			.clk_out(rd_clk),
			.rst_out(reset_rdclk)
	);

	always @(posedge rd_clk or posedge reset_rdclk) begin
		if (reset_rdclk) begin
			read_address <= 0;
			read_addrgray <= 0;
		end else begin

  /* synthesis translate_off*/
			if ( (rd_en!==1'b0) && (rd_en!==1'b1) ) begin
				$display("ERROR: rd_en=%x not valid: %m time=%t",rd_en,$time);
				$stop;
			end
  /* synthesis translate_on*/

			if (read_allow)
				read_address <= read_address_plus1;
			read_addrgray[ADDR_W] <= read_address[ADDR_W];
			for (rg_cnt=0;rg_cnt<ADDR_W;rg_cnt=rg_cnt+1)
				read_addrgray[rg_cnt] <= read_address[rg_cnt+1] ^ read_address[rg_cnt];

  /* synthesis translate_off*/
			if ((IGNORE_EMPTY_RD!=0) && (rd_en==1'b1) && (allempty_rdclk==1'b1)) begin
				$display("ERROR: %m: Reading from an EMPTY FIFO: IGNORE_EMPTY_RD=1, EMPTY=1, RD=1, time=%t",$time);
				$stop;
			end
  /* synthesis translate_on*/
		end
	end

/**********************************************************\
*                                                          *
*  Generation of Write address pointers.  Similar to read  *
*  pointer generation above, except for names.  Also, the  *
*  write counters only advance - there is no "write        *
*  backup" capability.  Because of this, a binary counter  *
*  is only present at one end of the address pipeline.     *
*                                                          *
\**********************************************************/

   integer wg_cnt;

	always @(posedge wr_clk or posedge fifo_reset) begin
		if (fifo_reset) begin
   			write_address <= 'b0;
			write_addrgray <= 0;
		end else begin

  /* synthesis translate_off*/
			if ( ($time>0) && (wr_en!==1'b0) && (wr_en!==1'b1) ) begin
				$display("ERROR: wr_en=%x not valid: %m time=%t",wr_en,$time);
				//$stop;
			end
  /* synthesis translate_on*/

			if (write_allow)
				write_address <= write_address + 1'b1;
			write_addrgray[ADDR_W] <= write_address[ADDR_W];
			for(wg_cnt=0;wg_cnt<ADDR_W;wg_cnt=wg_cnt+1)
				write_addrgray[wg_cnt] <= write_address[wg_cnt+1] ^ write_address[wg_cnt];
		end
	end

/**********************************************************\
*                                                          *
*  Allow flags determine whether FIFO control logic can    *
*  operate.  If read_allow is driven high, and the FIFO    *
*  is not Empty, then Reads are allowed.  Similarly, if    *
*  the write_allow signal is high, and the FIFO is not     *
*  Full, then Writes are allowed.                          *
*                                                          *
\**********************************************************/

   assign read_allow  = rd_en & (IGNORE_EMPTY_RD[0] | (~allempty_rdclk) | (wr_en & FAST_WR_TO_RD[0] & ONECLOCK[0]));
   assign write_allow = wr_en & (IGNORE_FULL_WR[0] | (~allfull_wrclk));

/**********************************************************\
*                                                          *
*  Empty-count generation occurs in four stages.  The      *
*  first two stages use the positive edge  
*  of the read clock to provide metastable recovery of     *
*  the Gray-code write address.  The third stage converts  *
*  this address back to binary, and the final stage does   *
*  the subtraction between the read address and the write  *
*  address.                                                *
*                                                          *
*  In the final stage, read_allow is inverted and used as  *
*  the borrow input into the subtraction carry chain.      *
*  This adjusts the empty count down by 1, to reflect the  *
*  FIFO data about to be read.                             *
*                                                          *
\**********************************************************/

generate
if(ONECLOCK==0) begin : gen_write_address_async
  // We don't want to declare ASYNC_REGs that are unused because they will act as a keep in synthesis and a don't touch in place/route
  (* ASYNC_REG = "TRUE" *) reg [ADDR_W:0]    write_addrgray_m /* synthesis syn_keep=1 */;
  (* ASYNC_REG = "TRUE" *) reg [ADDR_W:0]    write_addrgray_r /* synthesis syn_keep=1 */;

	always @(posedge rd_clk or posedge reset_rdclk) begin
		if (reset_rdclk) begin
			write_addrgray_m <= 'b0;
			write_addrgray_r <= 'b0;
		end else begin
			write_addrgray_m <= write_addrgray;
			write_addrgray_r <= write_addrgray_m;
		end
	end

  // Gray-code conversion to binary

   genvar wa_cnt;

   // ADDS 1 CLOCK CYCLE DELAY THROUGH FIFO TO EMPTY FLAG, SPLITTING LOGIC ACROSS TWO CLOCKS
   wire [ADDR_W:0]   write_address_c;

   assign write_address_c[ADDR_W] = write_addrgray_r[ADDR_W];
   for (wa_cnt=0;wa_cnt <ADDR_W;wa_cnt=wa_cnt+1) begin:gen_wr_addr_c
     assign write_address_c[wa_cnt] = ^(write_addrgray_r[ADDR_W:0] >> wa_cnt);
   end

`ifdef BETTER_TIMING
   always @(posedge rd_clk or posedge reset_rdclk)
     if (reset_rdclk)
       write_address_r <= 0;
	 else begin
`else
   // CUTS OUT 1 CLOCK CYCLE DELAY THROUGH FIFO TO EMPTY FLAG, BUT MORE LOGIC IN THIS CLOCK CYCLE
   always @(*) begin
`endif
      write_address_r <= write_address_c;
   end
//end else begin : gen_write_address_sync
//  // We don't use this register when synchronous
//  always @ (*)
//    write_address_r <= 'bx;
end
endgenerate

	always @(posedge rd_clk or posedge reset_rdclk) begin
		if (reset_rdclk) begin
   			if (GEN_RDCOUNT == 1)
				rd_empty_count <= 0;
			allempty_rdclk <= 1;
		end else begin
   			if (GEN_RDCOUNT == 1)
				rd_empty_count <= (read_allow ? write_minus_read_withread : write_minus_read_noread );
			allempty_rdclk <= (read_allow ? (write_minus_read_withread==0) : write_equals_read_noread) & (~(wr_en & FAST_WR_TO_RD[0] & ONECLOCK[0]));
		end
	end

  /* synthesis translate_off*/
	always @(*) begin
		if (GEN_RDCOUNT == 0) begin
      rd_empty_count <= 'b0;
      `ifndef IVERILOG_SIM
        rd_empty_count <= {ADDR_W+1{1'bx}};
      `endif
    end
  end
  /* synthesis translate_on*/

  // **********************************************************
  // Check that ONECLOCK is set correctly
  // **********************************************************
  // synthesis translate_off
  initial begin
    if (ALMOSTFULL_LIMIT+1 > (1 << ADDR_W)) begin
		$display("ERROR: %m ALMOSTFULL_LIMIT set larger than FIFO");
		$stop;
    end
    if ((ONECLOCK==0) && (GEN_WRALMOSTFULL!=0) && (ALMOSTFULL_LIMIT+12 > (1 << ADDR_W)) && (ALMOSTFULL_LIMIT*2 > (1 << ADDR_W)) ) begin
		$display("WARNING: %m ALMOSTFULL_LIMIT=%d should be at least 12 less than fifo depth=%d for ASYNC FIFOs",ALMOSTFULL_LIMIT,(1<<ADDR_W));
		$stop;
    end
    wait(fifo_reset===1'b0);
    repeat(100) @(posedge rd_clk);
    repeat(100) begin
      @(posedge rd_clk);
      if(ONECLOCK && (rd_clk!=wr_clk)) begin
        $display("%m: ERROR: ONECLOCK parameter is not set correctly; async domains detected!");
        $stop;
      end
      @(posedge wr_clk);
      if(ONECLOCK && (rd_clk!=wr_clk)) begin
        $display("%m: ERROR: ONECLOCK parameter is not set correctly; async domains detected!");
        $stop;
      end
    end
  end
  // synthesis translate_on

		// Pre-calculate the emptiness with and without read, and mux in
		// read as the very last stage.
   assign write_minus_read_noread = ((ONECLOCK ? write_address : write_address_r ) - read_address);
   assign write_equals_read_noread = ((ONECLOCK ? write_address : write_address_r ) == read_address);
   assign write_minus_read_withread = ((ONECLOCK ? write_address : write_address_r ) - read_address - 1'b1);
   assign write_equals_read_withread = (write_minus_read_withread==0);
   	

/**********************************************************\
*                                                          *
*  Full-count generation also occurs in four stages.  The  *
*  subtraction, in this case, is read minus write.         *
*                                                          *
*  In the final stage, write_allow is inverted and used    *
*  as the borrow input into the subtraction carry chain.   *
*  This adjusts the full count down by 1, to reflect the   *
*  FIFO data about to be written.                          *
*                                                          *
\**********************************************************/
generate
if(ONECLOCK==0) begin : gen_read_address_async
  // We don't want to declare ASYNC_REGs that are unused because they will act as a keep in synthesis and a don't touch in place/route
  (* ASYNC_REG = "TRUE" *) reg [ADDR_W:0]    read_addrgray_m  /* synthesis syn_keep=1 */;
  (* ASYNC_REG = "TRUE" *) reg [ADDR_W:0]    read_addrgray_md /* synthesis syn_keep=1 */;
   wire [ADDR_W:0]   read_address_c;

  always @(posedge wr_clk or posedge fifo_reset) begin
    if (fifo_reset) begin
       read_addrgray_m <= 'b0;
       read_addrgray_md <= 'b0;
    end else begin
       read_addrgray_m <= read_addrgray;
       read_addrgray_md <= read_addrgray_m;
    end
  end

  // Gray-code conversion to binary

  // ADDS 1 CLOCK CYCLE DELAY THROUGH FIFO TO FULL FLAG, SPLITTING LOGIC ACROSS TWO CLOCKS
  assign read_address_c[ADDR_W] = read_addrgray_md[ADDR_W];
  for(ra_cnt=0;ra_cnt<ADDR_W;ra_cnt=ra_cnt+1) begin:gen_rd_addr_c
    assign read_address_c[ra_cnt] = (^(read_addrgray_md[ADDR_W:0]>>ra_cnt) );
  end

`ifdef BETTER_TIMING
  always @(posedge wr_clk or posedge fifo_reset)
  if (fifo_reset) begin
    read_address_w <= 0;
  end else begin
`else
  // CUTS OUT 1 CLOCK CYCLE DELAY THROUGH FIFO TO FULL FLAG, BUT MORE LOGIC IN THIS CLOCK CYCLE
  always @(*) begin
`endif
    read_address_w <= read_address_c;
  end
//end else begin : gen_read_address_sync
//  // We don't use this register when synchronous
//  always @(*)
//    read_address_w <= 'bx;
end
endgenerate


   // FULL COUNT
	always @(posedge wr_clk or posedge fifo_reset) begin
		if (fifo_reset) begin
			if (GEN_WRCOUNT==1) begin
				wr_full_count <= 0;
				wr_full_count[ADDR_W] <= 1;
			end
			if (GEN_WRALMOSTFULL==1) begin
				wr_almost_full <= 1'b0;
			end
			allfull_wrclk <= 1'b0;
		end else begin
			if (GEN_WRCOUNT==1) begin
				wr_full_count <= read_minus_write;
			end
			if (GEN_WRALMOSTFULL==1) begin
				wr_almost_full <= (read_minus_write < ALMOSTFULL_LIMIT);
			end
			allfull_wrclk <= (read_minus_write == 0);
		end
	end

  /* synthesis translate_off*/
  always @(*) begin
		if (GEN_WRCOUNT == 0) begin
      wr_full_count <= 'b0;
      `ifndef IVERILOG_SIM
        wr_full_count <= {ADDR_W+1{1'bx}};
      `endif
    end
    if (GEN_WRALMOSTFULL == 0) begin
      wr_almost_full <= 'b0;
      `ifndef IVERILOG_SIM
        wr_almost_full <= 'bx;
      `endif
    end
  end
  /* synthesis translate_on*/


    assign read_minus_write = ((ONECLOCK ? {~read_address[ADDR_W],read_address[ADDR_W-1:0]} : {~read_address_w[ADDR_W],read_address_w[ADDR_W-1:0]}) - write_address - {{(ADDR_W-1){1'b0}}, write_allow});


  /* synthesis translate_off*/
   always @(posedge wr_clk)
	   if (~fifo_reset) begin
		   if ( wr_en & wr_full )
			   $display("Warning: Writing to a full fifo %m: time=%t",$time);
	   end
  /* synthesis translate_on*/

	   /*
   always @(posedge rd_clk)
	   if (~reset_rdclk) begin
		   if ( rd_en & rd_empty )
			   $display("Warning: Reading from an empty fifo %m: time=%t",$time);
	   end
	   */

endmodule

`endif
