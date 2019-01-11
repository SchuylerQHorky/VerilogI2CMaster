module Decode4_16(out, in);
	input[3:0] in;
	output[15:0] out;
	
	wire [3:0] in;
	reg [15:0] out;

	assign out = (1<<in);
endmodule

