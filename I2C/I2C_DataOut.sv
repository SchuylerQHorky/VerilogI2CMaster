module I2C_DataOut(Data, Length, DOut, Done, ClockD, ClockB, ClockInData);
	input [7:0] Data [0:7];
	input [3:0] Length;
	output DOut;
	output Done;//todo: connect this
	input ClockD;
	input ClockB;
	input ClockInData;
	
	
	wire [7:0] Data [0:7];
	wire [3:0] Length;
	reg DOut;
	reg Done;
	wire ClockD;
	wire ClockB;
	wire ClockInData;
	
	//todo: use Ack
	reg reset;
	
	wire[7:0] dataBus;
	
	//reg[7:0] regData [0:7];

	
	//integer i;
	//integer j;
	
	//always @(negedge Clock) begin
	//	for(i =0;i<=7;i++)begin
	//		regData[i][0] = Addr[i];
	//	end
	//	for(j = 0;j<=6;j++)begin
	//		for(i = 0;i<=7;i++)begin
	//			regData[i][j+1] <= Data[i][j]; 
	//		end
	//	end
	//end
	
	MemArray outArray(dataBus, Data, ClockInData, ClockB, Length, reset);
	ParallelInSerialOut outShiftReg(DOut, dataBus, ClockD);
	
	
endmodule
