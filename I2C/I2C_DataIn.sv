module I2C_DataIn(Data, Length, DIn, Done, ClockD, ClockB);
	input [7:0] Data [0:7];
	input [3:0] Length;
	input DIn;
	output Done;
	input ClockD;
	input ClockB;
	
	wire [7:0] Data [0:7];
	wire [3:0] Length;
	wire DIn;
	reg Done;
	wire ClockD;
	wire ClockB;
	
	wire[7:0] dataBus;
	
	//MemArray inArray(dataBus, Data, ClockInData???, ClockB, Length, reset??);
	//SerialInParallelOut inShiftReg(dataBus, DIn, ClockD);
	

endmodule
