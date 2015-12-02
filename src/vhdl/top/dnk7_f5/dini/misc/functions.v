// ################################################################
// $Header: /var/lib/cvs/dncvs/FPGA/dini/misc/functions.v,v 1.9 2015/03/18 00:23:51 claudiug Exp $
// ################################################################
// Description:
//   This file contains useful functions
// ################################################################
// $Log: functions.v,v $
// Revision 1.9  2015/03/18 00:23:51  claudiug
// added some more pointer comparison fcns
//
// Revision 1.8  2015/03/17 21:38:56  claudiug
// added a pointer ahead function for comparing two chasing pointers
//
// Revision 1.7  2015/01/23 01:06:53  bpoladian
// Added min and max functions.
//
// Revision 1.6  2012/06/19 17:13:31  neal
// Fixed vivado warnings.
//
// Revision 1.5  2012/04/24 00:21:44  neal
// Fixed insert_bit so that it doesn't drop 2 address bits.
//
// Revision 1.4  2012/04/20 00:04:18  neal
// Added a function for inserting a bit into a 32-bit number.
//
// Revision 1.3  2012/04/19 21:27:07  neal
// Added a comment to the log2() functionality.
//
// Revision 1.2  2011/12/05 22:59:06  bpoladian
// Added special case to log2 function.
//
// Revision 1.1  2011/09/14 01:49:37  bpoladian
// Initial revision.
//
// ################################################################


// ********************
// log2(n) = m (rounds up the output value to the next integer, and log2(1)==1 )
// n   m
// 0   0 (should be undefined!)
// 1   1 (we defined it this way!)
// 2   1 (normal)
// 4   2 (normal)
// ...
// 7   3 (round up)
// 8   3 (normal)
// 9   4 (round up)
// ...
// 16  4 (normal)
// ********************
function integer log2;
  input integer value;
  integer tmp;
  begin
    // This is incorrect LOG logic, but the correct functionality when we're
    // defining a bus of size [log2(value)-1:0] - we want [0:0] for value==1
    tmp = value;
    if(tmp==1) begin
      log2=1;
    end else begin
      tmp = tmp-1;
      for (log2=0; tmp>0; log2=log2+1)
        tmp = tmp>>1;
    end
  end
endfunction

function [31:0] insert_bit;
	input [31:0] data;
	input [7:0] insert_loc;
	input bit_to_insert;
begin
	//insert_bit = {data[30:insert_loc],bit_to_insert,data[insert_loc-1:0]};
	insert_bit = ((data << 1) & (32'hfffffffe << insert_loc)) |
	             (bit_to_insert << insert_loc) | 
		     (data & ~(32'hffffffff<<insert_loc));
end
endfunction


function [31:0] min;
	input [31:0] data1;
	input [31:0] data2;
begin
  if(data2 < data1)
    min = data2;
  else
    min = data1;
end
endfunction

function [31:0] max;
	input [31:0] data1;
	input [31:0] data2;
begin
  if(data2 > data1)
    max = data2;
  else
    max = data1;
end
endfunction

function pointer_ahead;
    // return( A > B )
    // return( B-A < 0 )
    // A and B should not be more than half the range of num_bits apart
    input [63:0] A;
    input [63:0] B;
    input [15:0] num_bits;

    reg [63:0] diff;
    begin
        diff = B-A;
        pointer_ahead = diff[num_bits-1];
    end
endfunction

function pointer_ahead_or_eq;
    // return( A >= B )
    // return( A-B >= 0 )
    // A and B should not be more than half the range of num_bits apart
    input [63:0] A;
    input [63:0] B;
    input [15:0] num_bits;
    
    reg [63:0] diff;
    begin
        diff = A-B;
        pointer_ahead_or_eq = ~diff[num_bits-1];
    end
endfunction

function pointer_behind;
    // return( A < B )
    // return( A-B < 0 )
    // A and B should not be more than half the range of num_bits apart
    input [63:0] A;
    input [63:0] B;
    input [15:0] num_bits;

    reg [63:0] diff;
    begin
        diff = A-B;
        pointer_behind = diff[num_bits-1];
    end
endfunction

function pointer_behind_or_eq;
    // return( A <= B )
    // return( B-A >= 0 )
    // A and B should not be more than half the range of num_bits apart
    input [63:0] A;
    input [63:0] B;
    input [15:0] num_bits;
    
    reg [63:0] diff;
    begin
        diff = B-A;
        pointer_behind_or_eq = ~diff[num_bits-1];
    end
endfunction
