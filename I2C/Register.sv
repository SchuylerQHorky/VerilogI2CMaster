module MemBlock(out, in, clk, enable);
	input [7:0] in;
	input clk;
	input enable;
	output [7:0] out;
	
	wire [7:0] in;
	wire clk;
	wire enable;
	reg [7:0] out;
	
	wire [7:0] buffer;
	
	Register byte0(buffer, in, clk);
	
	Tristate1 t0(buffer[0], enable, out[0]);
	Tristate1 t1(buffer[1], enable, out[1]);
	Tristate1 t2(buffer[2], enable, out[2]);
	Tristate1 t3(buffer[3], enable, out[3]);
	Tristate1 t4(buffer[4], enable, out[4]);
	Tristate1 t5(buffer[5], enable, out[5]);
	Tristate1 t6(buffer[6], enable, out[6]);
	Tristate1 t7(buffer[7], enable, out[7]);
endmodule

module Register(out, in, clk);
	input [7:0] in;
	input clk;
	output [7:0] out;
	
	wire [7:0] in;
	wire clk;
	reg [7:0] out;

	reg rst=0;
	
	D_FlipFlop regb0(out[0], clk, in[0], rst);
	D_FlipFlop regb1(out[1], clk, in[1], rst);
	D_FlipFlop regb2(out[2], clk, in[2], rst);
	D_FlipFlop regb3(out[3], clk, in[3], rst);
	D_FlipFlop regb4(out[4], clk, in[4], rst);
	D_FlipFlop regb5(out[5], clk, in[5], rst);
	D_FlipFlop regb6(out[6], clk, in[6], rst);
	D_FlipFlop regb7(out[7], clk, in[7], rst);

endmodule

module D_FlipFlop (Q, clk, D, rst);
	input clk;
	input D;
	input rst;
	output Q;
	
	wire clk;
	wire D;
	wire rst;
	reg Q;
	
	always @(posedge clk or posedge rst)begin
		if(rst == 1) begin
		Q = 0;
		end
		else if(clk == 1) begin
		Q = D;
		end
	end
endmodule

module Tristate1 (in, oe, out);
    input   in, oe;
	 wire in, oe;
	 
    output  out;
    tri     out;

    bufif1  b1(out, in, oe);
endmodule
