// ################################################################
// $Header: /var/lib/cvs/dncvs/FPGA/dini/misc/cdc_3ff.v,v 1.5 2013/12/19 00:02:49 bpoladian Exp $
// ################################################################
// Description:
//   This file provides a clock-domain-crossing resync for slow
// signals.  3 FFs are used for stability.
// ################################################################
// $Log: cdc_3ff.v,v $
// Revision 1.5  2013/12/19 00:02:49  bpoladian
// Fixed value of syn_preserve.
//
// Revision 1.4  2012/07/24 21:54:24  bpoladian
// Renamed first flop for constraint purposes.
//
// Revision 1.3  2012/06/19 17:13:31  neal
// Fixed vivado warnings.
//
// Revision 1.2  2010/07/06 20:40:23  bpoladian
// Added parameter for init value.
//
// Revision 1.1  2009/10/22 18:25:57  bpoladian
// Initial Revision.
//
// ################################################################

`ifdef INCL_CDC_3FF
`else
`define INCL_CDC_3FF

module cdc_3ff #(
  parameter DATA_WIDTH = 1,
  parameter INIT_VALUE = 0
) (
  input      target_clk,
  input      reset,

  input      [DATA_WIDTH-1:0] input_signal,
  output reg [DATA_WIDTH-1:0] output_signal
);

(* KEEP="TRUE" *) reg [DATA_WIDTH-1:0] signal_meta /* synthesis syn_preserve=true */ /* synthesis syn_keep=1 */;
(* KEEP="TRUE" *) reg [DATA_WIDTH-1:0] signal_d /* synthesis syn_preserve=true */ /* synthesis syn_keep=1 */;

always @ (posedge target_clk or posedge reset) begin
  if (reset) begin
    signal_meta   <= INIT_VALUE;
    signal_d      <= INIT_VALUE;
    output_signal <= INIT_VALUE;
  end else begin
    signal_meta   <= input_signal;
    signal_d      <= signal_meta;
    output_signal <= signal_d;
  end
end

endmodule

`endif //INCL_CDC_3FF
