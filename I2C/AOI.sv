module AOI(output reg Y, input A, input B, input C, input D);
	assign Y = ~((A&B)|(C&D));
endmodule
