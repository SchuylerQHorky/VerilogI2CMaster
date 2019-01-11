module MemArray(out, in, clk_in, clk_out, length, index_rst);
	input[7:0] in [0:7];
	input clk_in;
	input clk_out;
	input[3:0] length;
	input index_rst;
	output [7:0] out;
	
	wire[7:0] in [0:7];
	wire clk_in;
	wire clk_out;
	wire[3:0] length;
	wire index_rst;
	//reg [7:0] out;//why does out go to hi-Z when this is enabled?
	
	wire [15:0] selector_out;
	
	RingCounter selector(selector_out, clk_out, index_rst, length);
	
	MemBlock b0(out, in[0], clk_in, selector_out[0]);
	MemBlock b1(out, in[1], clk_in, selector_out[1]);
	MemBlock b2(out, in[2], clk_in, selector_out[2]);
	MemBlock b3(out, in[3], clk_in, selector_out[3]);
	MemBlock b4(out, in[4], clk_in, selector_out[4]);
	MemBlock b5(out, in[5], clk_in, selector_out[5]);
	MemBlock b6(out, in[6], clk_in, selector_out[6]);
	MemBlock b7(out, in[7], clk_in, selector_out[7]);

endmodule
