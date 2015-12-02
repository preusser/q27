// **************************************************************************
// $Header: /var/lib/cvs/dncvs/FPGA/dini/misc/resync.v,v 1.7 2015/04/07 22:03:42 bpoladian Exp $
// **************************************************************************
// $Log: resync.v,v $
// Revision 1.7  2015/04/07 22:03:42  bpoladian
// Only stop simulation on first warning.
//
// Revision 1.6  2015/04/06 23:58:10  bpoladian
// Resync reset to read clock domain.
//
// Revision 1.5  2013/05/20 17:39:36  claudiug
// added ALLOW_FAST_WRITE_PULSE parameter, disabled by default. Should not change old behavior.
//
// Revision 1.4  2013/03/07 23:10:37  bpoladian
// Fixed typo.
//
// Revision 1.3  2013/03/07 23:07:10  bpoladian
// Added simulation error about asserting wr_pulse too often.
//
// Revision 1.2  2010/11/17 20:41:05  bpoladian
// Syntax fix.
//
// Revision 1.1  2010/11/17 20:03:42  bpoladian
// Initial revision.
//
//
// Description:
// Transfers a group of signals from one clock domain into another.
// The transfer operation is triggered by a "wr_pulse", and data is
// valid on the other side when "rd_pulse" goes active.
// **************************************************************************

`ifdef INCL_RESYNC
`else
`define INCL_RESYNC

module resync #(
  parameter DATA_SIZE = 32,
  parameter ALLOW_FAST_WRITE_PULSE = 0
)(
  input                      rst,

  input                      wr_clk,
  input                      wr_pulse,
  input      [DATA_SIZE-1:0] wr_data,

  input                      rd_clk,
  output reg                 rd_pulse,
  output reg [DATA_SIZE-1:0] rd_data
);


// **********************************************************************
// REG AND WIRE DECLARATIONS
// **********************************************************************
reg [DATA_SIZE-1:0] data_wrclk;

reg toggle_wr;
reg toggle_return_wr_meta;
reg toggle_return_wr0;

reg toggle_rd_meta;
reg toggle_rd0;
reg toggle_rd1;


// **********************************************************************
// WRITE CLOCK DOMAIN DATA CAPTURE
// **********************************************************************
// synthesis translate_off
reg stop_once;
initial begin
  stop_once = 0;
end
// synthesis translate_on

always @(posedge wr_clk or posedge rst) begin
  if (rst) begin
    toggle_wr                 <= 1'b0;
    toggle_return_wr_meta     <= 1'b0;
    toggle_return_wr0         <= 1'b0;
    data_wrclk[DATA_SIZE-1:0] <= 'h0;
  end else begin
    toggle_wr <= ALLOW_FAST_WRITE_PULSE ? toggle_wr ^ (wr_pulse & (toggle_wr ^ ~toggle_return_wr0)) : toggle_wr ^ wr_pulse;
    toggle_return_wr_meta <= toggle_rd0;
    toggle_return_wr0 <= toggle_return_wr_meta;

    if (wr_pulse) begin
      data_wrclk[DATA_SIZE-1:0] <= wr_data[DATA_SIZE-1:0];
    end

    // synthesis translate_off
    if(wr_pulse & (ALLOW_FAST_WRITE_PULSE ? (toggle_wr ^ ~toggle_return_wr0) : 1'b1) & (toggle_wr ^ toggle_rd1)) begin
      $display("%t: %m: ERROR: wr_pulse too early to guarantee safe clock domain crossing!", $realtime);
      if(!stop_once) begin
        stop_once = 1;
        $stop;
      end
    end
    // synthesis translate_on
  end
end


// **********************************************************************
// READ CLOCK DOMAIN DATA TRANSFER
// **********************************************************************
wire rd_rst;
reset_resync i_reset_resync (
  .rst_in   (rst),
  .clk_in   (wr_clk),
  .clk_out  (rd_clk),
  .rst_out  (rd_rst)
);

always @(posedge rd_clk or posedge rd_rst) begin
  if (rd_rst) begin
    toggle_rd_meta <= 1'b0;
    toggle_rd0     <= 1'b0;
    toggle_rd1     <= 1'b0;
    rd_pulse       <= 1'b0;
    rd_data        <= {DATA_SIZE{1'b0}};
  end else begin
    toggle_rd_meta <= toggle_wr;
    toggle_rd0     <= toggle_rd_meta;
    toggle_rd1     <= toggle_rd0;
    rd_pulse       <= toggle_rd0 ^ toggle_rd1;

    if (toggle_rd0 ^ toggle_rd1) begin
      rd_data[DATA_SIZE-1:0] <= data_wrclk[DATA_SIZE-1:0];
    end
  end
end

endmodule

`endif

