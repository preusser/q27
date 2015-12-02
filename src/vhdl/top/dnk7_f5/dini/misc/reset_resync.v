// **************************************************************************
// $Header: /var/lib/cvs/dncvs/FPGA/dini/misc/reset_resync.v,v 1.3 2014/09/12 05:26:45 neal Exp $
// **************************************************************************
// Description:
// Transfers a reset signal from one clock domain into another.
// **************************************************************************
// $Log: reset_resync.v,v $
// Revision 1.3  2014/09/12 05:26:45  neal
// Added an option to control the output polarity of the reset signal.
//
// Revision 1.2  2014/08/28 20:07:13  neal
// Added a property to help the vivado tools.
//
// Revision 1.1  2014/07/02 12:55:11  neal
// Added a resync module specifically for reset resynchronization to make timing constraint exclusions simpler.
//
// **************************************************************************

`ifdef INCL_RESET_RESYNC
`else
`define INCL_RESET_RESYNC

module reset_resync #(
		parameter VALUE_DURING_RESET = 1
) (
  input       rst_in,
  input       clk_in,

  input       clk_out,
  (* ASYNC_REG = "TRUE" *) (* keep="true" *) output reg  rst_out
);

// **********************************************************************
// WRITE CLOCK DOMAIN
// **********************************************************************

(* keep="true" *) reg rst_in_dly;

always @(posedge clk_in or posedge rst_in) begin
  if (rst_in) begin
    rst_in_dly <= 1'b1;
  end else begin
    rst_in_dly <= 1'b0;
  end
end


// **********************************************************************
// READ CLOCK DOMAIN DATA TRANSFER
// **********************************************************************

initial begin
	rst_out = VALUE_DURING_RESET;
end

always @(posedge clk_out or posedge rst_in_dly) begin
  if (rst_in_dly) begin
    rst_out <= VALUE_DURING_RESET;
  end else begin
    rst_out <= ~VALUE_DURING_RESET;
  end
end

endmodule

`endif // INCL_RESET_RESYNC
