module RingCounter(outs, clk, rst, limit);
	input clk;
	input rst;
	input [3:0] limit;

	output [15:0] outs;
	
	wire clk;
	wire rst;
	wire [3:0] limit;
	
	reg [15:0] outs;
	
	wire[3:0] counter_out;
	
	reg rst_internal;
	wire rst_ctrl;
	
	or rstOr(rst_ctrl, rst_internal, rst);
	
	Counter4B counter(counter_out, clk, rst_ctrl);
	Decode4_16 decoder(outs, counter_out);
	
	assign rst_internal = outs[limit];
	
	//always @(posedge outs[limit]) begin
	//	rst_internal = 1;
	//end
	
	//always @(negedge outs[limit]) begin
	//	rst_internal = 0;
	//end
endmodule
