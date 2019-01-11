 module Counter4B(out, clk, rst);
	input clk;
	input rst;
	
	output [3:0] out;
	
	wire clk;
	wire rst;
	
	reg [3:0] out = 4'b0000;
	
	always @(posedge clk or posedge rst)
	begin
		if(rst == 1)begin
			out = 4'b0000;//assign
		end
		else if(clk == 1) begin
		 out = out + 1;//assign
		end
	end
endmodule
