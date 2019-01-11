module ParallelInSerialOut(dOut, dIn, clk);
	input[7:0] dIn;
	input clk;
	output dOut;
	
	wire[7:0] dIn;
	wire clk;
	reg dOut;

	reg[2:0] index = 3'b111;
	
	always @(negedge clk)
	begin
		assign index = index - 1;
	end
	assign dOut = dIn[index];
endmodule
