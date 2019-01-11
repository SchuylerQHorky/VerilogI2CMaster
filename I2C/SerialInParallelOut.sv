module SerialInParallelOut(dOut, dIn, clk);
	input dIn;
	input clk;
	output[7:0] dOut;
	
	wire dIn;
	wire clk;
	reg[7:0] dOut;
	
	reg[2:0] index = 3'b111;
	
	always @(posedge clk)
	begin
	   dOut[index] = dIn;
	   index = index - 1;
	end
endmodule
