// **************************************************************************
// $Header: /var/lib/cvs/dncvs/FPGA/dini/pcie/pcie_dma/user_fpga/pcie_ddr_user_io.v,v 1.31 2014/08/25 05:35:18 neal Exp $
// **************************************************************************
// Description:
//
//    Translation from the DDR interface to the parallel PCIe
//    interface.
// **************************************************************************
// $Log: pcie_ddr_user_io.v,v $
// Revision 1.31  2014/08/25 05:35:18  neal
// Fixed some resets so that the mmcm_locked will propagate.
//
// Revision 1.30  2012/12/06 20:53:45  neal
// Added a MMCM locked and reset gating of the output DDR clk.
//
// Revision 1.29  2012/07/05 23:49:31  neal
// Fixed XST issue.
//
// Revision 1.28  2012/07/02 18:46:13  bpoladian
// Fixed split declaration.
//
// Revision 1.27  2012/06/29 17:45:19  bpoladian
// Added retimed resets.
// Cleaner cross-domain debug signal.
//
// Revision 1.26  2012/05/02 22:27:51  bpoladian
// Added better comments to phase shifting ports.
//
// Revision 1.25  2012/02/03 02:16:56  bpoladian
// Now has a variable number of delay stages.
//
// Revision 1.24  2012/01/18 21:23:47  bpoladian
// Enable phase shifting on K7 MMCM.
//
// Revision 1.23  2011/09/13 20:35:01  bpoladian
// Added declarations for implicit wires.
//
// Revision 1.22  2011/08/29 20:10:33  bpoladian
// Added pipeline stages.
//
// Revision 1.21  2011/08/23 23:00:01  bpoladian
// Added MMCM for kintex7.
//
// Revision 1.20  2010/11/16 03:10:58  bpoladian
// Fixed width of dcm_status to avoid warning.
//
// Revision 1.19  2010/11/05 22:15:37  bpoladian
// Don't assert psdone when no ps is performed.
//
// Revision 1.18  2010/10/26 22:12:33  bpoladian
// Added locked signal.
//
// Revision 1.17  2010/10/05 22:20:38  bpoladian
// Made to/from clocking clearer.
//
// Revision 1.16  2010/10/01 02:12:12  bpoladian
// Move phase shift parameter to top level.
// Make sure valid is not asserted on empty FIFO.
//
// Revision 1.15  2010/09/14 18:48:30  bpoladian
// Added phase shift control signals.
//
// Revision 1.14  2010/09/09 23:06:08  bpoladian
// Simplified FIFO logic.
//
// Revision 1.13  2010/08/30 23:15:13  bpoladian
// Fixed DCM reset.
//
// Revision 1.12  2010/08/27 23:59:43  bpoladian
// Added DCM for Spartan.
//
// Revision 1.11  2010/08/05 03:28:59  bpoladian
// Adjusted Virtex clocking structure.
//
// Revision 1.10  2010/02/25 01:07:37  bpoladian
// Went back to single BUFG for clocking.
//
// Revision 1.9  2010/02/22 22:50:58  bpoladian
// Updated clocking.
//
// Revision 1.8  2010/02/17 23:34:22  bpoladian
// Prevented wr_en=x error by waiting for valid data on IDDRs before passing to user.
//
// Revision 1.7  2010/01/25 06:03:50  bpoladian
// Fixed data phase.
//
// Revision 1.6  2010/01/15 22:48:50  subhasri
// Changed SRTYPE of ODDR2 to ASYNC for Spartan
//
// Revision 1.5  2010/01/15 03:00:38  bpoladian
// Fixed alignment.
//
// Revision 1.4  2010/01/15 02:15:57  bpoladian
// Fixed clock polarity.
//
// Revision 1.3  2010/01/14 02:15:48  bpoladian
// Added Spartan6 primitive support.
//
// Revision 1.2  2010/01/11 23:27:35  bpoladian
// Fixed bus widths.
//
// Revision 1.1  2010/01/08 02:08:34  bpoladian
// Initial revision.
//
//
// **************************************************************************

`ifdef INCL_PCIE_DDR_USER_IO
`else
`define INCL_PCIE_DDR_USER_IO

`ifdef SPARTAN_6
  `define SPARTAN
`endif

`ifdef VIRTEX_6
  `define VIRTEX
`endif
`ifdef VIRTEX_7
  `define VIRTEX
`endif
`ifdef KINTEX_7
  `define VIRTEX
`endif

`include "dini/misc/cdc_3ff.v"

module pcie_ddr_user_io #(
  parameter NUM_DMA_ENGINES = 3,
  parameter DCM_PHASE_SHIFT = 30,
  parameter DCM_PERIOD      = 10
) (
  output                          pcie_from_host_clk,
  output                          pcie_from_host_clk_reset,
  input                           pcie_to_host_clk,

  input                           ddr_reset,

  // DCM Control - tie inputs to 0 if unused
  input                           dcm_psen,
  input                           dcm_psincdec,
  // DCM Control - leave outputs floating if unused
  output                          dcm_psdone,
  output reg [16:0]               dcm_psval,
  // PSCLK must always be driven by a clock when USE_FINE_PS is on, even if dynamic shifting is not used
  input                           dcm_psclk,


  // from_host signals
  output reg [63:0]               pcie_fromhost_data,
  output     [NUM_DMA_ENGINES:0]  pcie_fromhost_transaction_type,
  output reg [1:0]                pcie_fromhost_isaddress,
  output reg [1:0]                pcie_fromhost_info,
  output reg [1:0]                pcie_fromhost_valid,
  output reg [NUM_DMA_ENGINES:0]  pcie_fromhost_almost_full,

  // to_host signals
  input      [63:0]               pcie_tohost_data,
  input      [NUM_DMA_ENGINES:0]  pcie_tohost_transaction_type,
  input      [4:0]                pcie_tohost_info,
  input      [1:0]                pcie_tohost_valid,
  input      [NUM_DMA_ENGINES:0]  pcie_tohost_almost_full,
  input                           user_interrupt,

  // Physical interface to/from ConfigFPGA
  output     [38:0]               PCIE_TO_HOST_DDR,
  output                          PCIE_TO_HOST_CLK_P,
  output                          PCIE_TO_HOST_CLK_N,

  input      [37:0]               PCIE_FROM_HOST_DDR,
  input                           PCIE_FROM_HOST_CLK_P,
  input                           PCIE_FROM_HOST_CLK_N,

  output reg [31:0]               pcie_fromhost_counter // debug signal on tohost_clk
);


//////////////////////////////////////////////////////////////
// Wire/Reg Declarations
//////////////////////////////////////////////////////////////
wire              pcie_from_host_clock_locked;

wire [(38*2)-1:0] pcie_from_host_expanded;

reg  [(39*2)-1:0] pcie_to_host_expanded;
reg  [(39*2)-1:0] pcie_to_host_expanded_d;

wire [1:0]        pcie_tohost_transaction_type_encoded;
reg  [1:0]        pcie_fromhost_transaction_type_encoded;

assign pcie_tohost_transaction_type_encoded = pcie_tohost_transaction_type[3] ? 2'b11 :
                                              pcie_tohost_transaction_type[2] ? 2'b10 :
                                              pcie_tohost_transaction_type[1] ? 2'b01 : 2'b00 ;

assign pcie_fromhost_transaction_type = (4'b0001) << pcie_fromhost_transaction_type_encoded;

//////////////////////////////////////////////////////////////
// Pipeline Flops
//////////////////////////////////////////////////////////////
reg pcie_to_host_reset;
always @ (posedge pcie_to_host_clk or posedge ddr_reset) begin
  if (ddr_reset) begin
    pcie_to_host_reset <= 'b1;
  end else begin
    pcie_to_host_reset <= 'b0;
  end
end

always @ (posedge pcie_to_host_clk or posedge pcie_to_host_reset) begin
  if (pcie_to_host_reset) begin
    pcie_to_host_expanded     <= 'b0;
    pcie_to_host_expanded_d   <= 'b0;
  end else begin
    pcie_to_host_expanded <= { pcie_tohost_almost_full,
                               pcie_tohost_valid,
                               user_interrupt, pcie_tohost_info,
                               pcie_tohost_transaction_type_encoded,
                               pcie_tohost_data};

    pcie_to_host_expanded_d <= pcie_to_host_expanded;
  end
end

reg pcie_from_host_reset;
always @ (posedge pcie_from_host_clk or posedge ddr_reset) begin
  if (ddr_reset) begin
    pcie_from_host_reset <= 'b1;
  end else begin
    pcie_from_host_reset <= 'b0;
  end
end

always @ (posedge pcie_from_host_clk or posedge pcie_from_host_reset) begin
  if (pcie_from_host_reset) begin
    pcie_fromhost_almost_full <= 'b0;
    pcie_fromhost_valid       <= 'b0;
    pcie_fromhost_info        <= 'b0;
    pcie_fromhost_isaddress   <= 'b0;
    pcie_fromhost_transaction_type_encoded <= 'b0;
    pcie_fromhost_data        <= 'b0;
  end else begin

    if(pcie_from_host_clock_locked) begin
      { pcie_fromhost_almost_full,
        pcie_fromhost_valid,
        pcie_fromhost_info,
        pcie_fromhost_isaddress,
        pcie_fromhost_transaction_type_encoded,
        pcie_fromhost_data }                      <= pcie_from_host_expanded;
    end
  end
end



//////////////////////////////////////////////////////////////
// Clocking
//////////////////////////////////////////////////////////////
wire pcie_from_host_clk_prebuf;
wire pcie_from_host_clk_bufio;
wire pcie_from_host_clk_io;

IBUFGDS #(.DIFF_TERM("TRUE")) i_ibufds_fromhost_clk ( .I(PCIE_FROM_HOST_CLK_P), .IB(PCIE_FROM_HOST_CLK_N), .O(pcie_from_host_clk_prebuf) );

`ifdef SPARTAN
  wire in_clk_bufio;
  BUFIO2 i_bufio_in_clk (.I(pcie_from_host_clk_prebuf), .DIVCLK(in_clk_bufio), .IOCLK(), .SERDESSTROBE());

  wire       dcm_psdone_port;
  wire [7:0] dcm_status;

  DCM_SP #(
  .CLKIN_PERIOD       (DCM_PERIOD),
  .CLKOUT_PHASE_SHIFT ("VARIABLE"),
  .DESKEW_ADJUST      ("SOURCE_SYNCHRONOUS"),
  .PHASE_SHIFT        (DCM_PHASE_SHIFT)
  )
  i_DCM_SP (
  .CLKIN    (in_clk_bufio),
  .RST      (ddr_reset),

  .CLKFB    (clk_fb_bufio),
  .CLK0     (in_clk_pre_bufg),
  .CLK180   (),
  .CLK270   (),
  .CLK2X    (),
  .CLK2X180 (),
  .CLK90    (),
  .CLKDV    (),
  .CLKFX    (),
  .CLKFX180 (),
  .LOCKED   (pcie_from_host_clock_locked),
  .PSDONE   (dcm_psdone_port),
  .STATUS   (dcm_status),
  .DSSEN    (),
  .PSCLK    (dcm_psclk),
  .PSEN     (dcm_psen),
  .PSINCDEC (dcm_psincdec)
  );
  BUFG     i_bufg_fb  (.I(in_clk_pre_bufg), .O(pcie_from_host_clk));
  BUFIO2FB i_bufio_fb (.I(pcie_from_host_clk), .O(clk_fb_bufio));

  // Don't assert psdone if no phase shift is performed (at end of delay line)
  assign dcm_psdone = dcm_psdone_port & ~dcm_status[0];

  always @ (posedge dcm_psclk or posedge ddr_reset) begin
    if (ddr_reset) begin
      dcm_psval <= DCM_PHASE_SHIFT;
    end else begin
      if(dcm_psen & dcm_psincdec)
        dcm_psval <= dcm_psval + 1;
      else if(dcm_psen)
        dcm_psval <= dcm_psval - 1;
    end
  end

  assign pcie_from_host_clk_io     =  pcie_from_host_clk;
`endif

`ifdef VIRTEX_6
  BUFIO  i_ibufio_fromhost_clk  ( .I(pcie_from_host_clk_prebuf), .O(pcie_from_host_clk_bufio));
  BUFR   i_ibufg_fromhost_clk   ( .I(pcie_from_host_clk_prebuf),  .O(pcie_from_host_clk), .CE(1'b1), .CLR(1'b0));
  assign pcie_from_host_clk_io     =  pcie_from_host_clk_bufio;

  assign dcm_psdone = 'b0;
  assign pcie_from_host_clock_locked = 1'b1;
  always @ (*) begin
    dcm_psval <= 'b0;
  end
`endif

`ifdef KINTEX_7
  wire clkfbout;
  wire clkfbin;
  wire clk_dcm;

  MMCME2_ADV #(
     .CLKFBOUT_MULT_F      (DCM_PERIOD),
     .CLKIN1_PERIOD        (DCM_PERIOD),
     .CLKOUT0_DIVIDE_F     (DCM_PERIOD),
     .CLKOUT0_PHASE        (DCM_PHASE_SHIFT),
     .CLKOUT0_USE_FINE_PS  ("TRUE"),
     .DIVCLK_DIVIDE        (1)
  )
  i_MMCM_K7 (
     .RST              (ddr_reset),
     .CLKINSEL         (1'b1),
     .PWRDWN           (1'b0),

     .CLKIN1           (pcie_from_host_clk_prebuf),

     .CLKFBOUT         (clkfbout),
     .CLKFBIN          (clkfbin),

     .CLKOUT0          (clk_dcm),

     .PSDONE           (dcm_psdone),
     .PSCLK            (dcm_psclk),
     .PSEN             (dcm_psen),
     .PSINCDEC         (dcm_psincdec),

     .LOCKED           (pcie_from_host_clock_locked),

     .CLKIN2           (1'b0),
     .CLKFBOUTB        (),
     .CLKOUT0B         (),
     .CLKOUT1          (),
     .CLKOUT1B         (),
     .CLKOUT2          (),
     .CLKOUT2B         (),
     .CLKOUT3          (),
     .CLKOUT3B         (),
     .CLKOUT4          (),
     .CLKOUT5          (),
     .CLKOUT6          (),
     .DO               (),
     .DRDY             (),

     .CLKFBSTOPPED     (),
     .CLKINSTOPPED     (),
     .DADDR            (7'h0),
     .DCLK             (1'b0),
     .DEN              (1'b0),
     .DI               (16'h0),
     .DWE              (1'b0)
  );

  BUFG     i_bufg_inclk  (.I(clk_dcm), .O(pcie_from_host_clk));
  BUFG     i_bufg_fb     (.I(clkfbout),        .O(clkfbin));

  assign pcie_from_host_clk_io     =  pcie_from_host_clk;

  always @ (posedge dcm_psclk or posedge ddr_reset) begin
    if (ddr_reset) begin
      dcm_psval <= DCM_PHASE_SHIFT;
    end else begin
      if(dcm_psen & dcm_psincdec)
        dcm_psval <= dcm_psval + 1'b1;
      else if(dcm_psen)
        dcm_psval <= dcm_psval - 1'b1;
    end
  end
`endif

  assign pcie_from_host_clk_reset = (~pcie_from_host_clock_locked) | ddr_reset;

wire pcie_to_host_clk_out;
`ifdef VIRTEX

// Keep the ODDR for the to_host_clk in reset until
// the internal MMCM/PLL is locked - to make sure the PCIE side
// never gets a garbage input.
(* KEEP="TRUE" *) reg reset_oddr_clk;
wire reset_output_clk = (~pcie_from_host_clock_locked) | ddr_reset;
always @(posedge pcie_to_host_clk or posedge reset_output_clk) begin
	if (reset_output_clk) begin
		reset_oddr_clk <= 1'b1;
	end else begin
		reset_oddr_clk <= 1'b0;
	end
end

ODDR #(.INIT(1'b0), .SRTYPE("SYNC")) i_oddr_tohost_clk (
  .Q(pcie_to_host_clk_out),
  .C(pcie_to_host_clk),
  .CE(1'b1),
  .D1(1'b0),
  .D2(1'b1),
  .R(reset_oddr_clk),
  //.R(1'b0),
  .S(1'b0)
);
`endif

`ifdef SPARTAN
ODDR2 i_oddr_tohost_clk (
  .Q(pcie_to_host_clk_out),
  .C0(pcie_to_host_clk),
  .C1(~pcie_to_host_clk),
  .CE(1'b1),
  .D0(1'b0),
  .D1(1'b1),
  .R(1'b0),
  .S(1'b0)
);
`endif

OBUFDS i_obufds_tohost_clk ( .I(pcie_to_host_clk_out), .O(PCIE_TO_HOST_CLK_P), .OB(PCIE_TO_HOST_CLK_N));

//////////////////////////////////////////////////////////////
// DDR I/O
//////////////////////////////////////////////////////////////

genvar i;
generate
for(i=0; i<39; i=i+1) begin : gen_oddr
`ifdef VIRTEX
ODDR #( .DDR_CLK_EDGE("SAME_EDGE"), .INIT(1'b0), .SRTYPE("SYNC")) i_oddr_ddr_data (
  .Q(PCIE_TO_HOST_DDR[i]),
  .C(pcie_to_host_clk),
  .CE(1'b1),
  .D1(pcie_to_host_expanded_d[i+39]),
  .D2(pcie_to_host_expanded[i]),
  .R(1'b0),
  .S(1'b0)
);
`endif

`ifdef SPARTAN
ODDR2 #( .DDR_ALIGNMENT("C0"), .INIT(1'b0), .SRTYPE("ASYNC")) i_oddr_ddr_data (
  .Q(PCIE_TO_HOST_DDR[i]),
  .C0(pcie_to_host_clk),
  .C1(~pcie_to_host_clk),
  .CE(1'b1),
  .D0(pcie_to_host_expanded_d[i+39]),
  .D1(pcie_to_host_expanded[i]),
  .R(1'b0),
  .S(1'b0)
);
`endif
end
endgenerate

localparam DELAY_STAGES = 2;
generate
for(i=0; i<38; i=i+1) begin : gen_iddr
  wire [1:0] pcie_from_host_expanded_wire;
  reg  [1:0] pcie_from_host_expanded_reg [DELAY_STAGES-1:0];
  `ifdef VIRTEX
  IDDR #( .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), .INIT_Q1(1'b0), .INIT_Q2(1'b0), .SRTYPE("SYNC")) i_iddr_ddr_data (
      .Q1 (pcie_from_host_expanded_wire[0]),
      .Q2 (pcie_from_host_expanded_wire[1]),
      .C  (pcie_from_host_clk_io),
      .CE (1'b1),
      .D  (PCIE_FROM_HOST_DDR[i]),
      .R  (1'b0),
      .S  (1'b0)
    );
  `endif

  `ifdef SPARTAN
  IDDR2 #(.DDR_ALIGNMENT("C0"), .INIT_Q0(1'b0), .INIT_Q1(1'b0), .SRTYPE("ASYNC")) i_iddr_ddr_data (
      .Q0 (pcie_from_host_expanded_wire[0]),
      .Q1 (pcie_from_host_expanded_wire[1]),
      .C0 (pcie_from_host_clk_io),
      .C1 (~pcie_from_host_clk_io),
      .CE (1'b1),
      .D  (PCIE_FROM_HOST_DDR[i]),
      .R  (1'b0),
      .S  (1'b0)
    );
  `endif

  integer j;
  always @ (posedge pcie_from_host_clk or posedge pcie_from_host_reset) begin
    if(pcie_from_host_reset) begin
      for(j=0; j<DELAY_STAGES; j=j+1)
        pcie_from_host_expanded_reg[j] <= 'b0;
    end else begin
      pcie_from_host_expanded_reg[0]   <= pcie_from_host_expanded_wire;
      for(j=1; j<DELAY_STAGES; j=j+1)
        pcie_from_host_expanded_reg[j] <= pcie_from_host_expanded_reg[j-1];
    end
  end

  `ifdef VIRTEX
    assign pcie_from_host_expanded[i]    = pcie_from_host_expanded_reg[DELAY_STAGES-1][0];
    assign pcie_from_host_expanded[i+38] = pcie_from_host_expanded_reg[DELAY_STAGES-1][1];
  `endif

  `ifdef SPARTAN
    assign pcie_from_host_expanded[i]    = pcie_from_host_expanded_reg[DELAY_STAGES-1][0];
    assign pcie_from_host_expanded[i+38] = pcie_from_host_expanded_reg[DELAY_STAGES-2][1];
  `endif
end
endgenerate

reg pcie_from_host_counter_en;
always @ (posedge pcie_from_host_clk or posedge pcie_from_host_reset) begin
  if(pcie_from_host_reset) begin
    pcie_from_host_counter_en <= 1'b0;
  end else begin
    pcie_from_host_counter_en <= |pcie_from_host_expanded[71:70];
  end
end
cdc_3ff i_cdc_3ff_counter_en (.input_signal(pcie_from_host_counter_en), .output_signal(pcie_fromhost_counter_en_tohostclk), .target_clk(pcie_to_host_clk), .reset(pcie_to_host_reset));

always @ (posedge pcie_to_host_clk or posedge pcie_to_host_reset) begin
  if(pcie_to_host_reset) begin
    pcie_fromhost_counter <= 'b0;
  end else begin
    if(pcie_fromhost_counter_en_tohostclk)
      pcie_fromhost_counter <= pcie_fromhost_counter + 1;
  end
end

endmodule
`endif
