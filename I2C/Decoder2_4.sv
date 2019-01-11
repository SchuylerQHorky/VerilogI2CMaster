module Decoder2_4(out, sel0, sel1);
	input sel0;
	input sel1;
	
	output[3:0] out;
	
	wire sel0;
	wire sel1;
	
	reg[3:0] out;
	
	assign out[0] = ~sel1 & ~sel0;
	assign out[1] = ~sel1 & sel0;
	assign out[2] = sel1 & ~sel0;
	assign out[3] = sel1 & sel0;
endmodule
