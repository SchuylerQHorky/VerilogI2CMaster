module Counter(output reg Y, input[3:0] A, input[3:0] B);
	wire d0,d1,d2,d3,d01,d23;
	
	xnor D0(d0, A[0], B[0]);
	xnor D1(d1, A[1], B[1]);
	xnor D2(d2, A[2], B[2]);
	xnor D3(d3, A[3], B[3]);
	
	and A01(d01,d0,d1);
	and A23(d23,d2,d3);
	and y(Y, d01,d23);
endmodule
