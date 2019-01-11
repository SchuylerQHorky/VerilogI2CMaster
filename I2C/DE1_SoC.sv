// Top-level module that defines the I/Os for the DE-1 SoC board

module DE1_SoC (CLOCK_50, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY, LEDR, SW, GPIO_0);
	input CLOCK_50;
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output [9:0] LEDR;
	input [3:0] KEY;
	input [9:0] SW;
 
 
	inout [34:0] GPIO_0;

	//GPIO_0[28]->SDA
	//GPIO_0[29]->SCL
 
	//Default values, turns off the HEX displays
	assign HEX0 = 7'b1111111;
	assign HEX1 = 7'b1111111;
	assign HEX2 = 7'b1111111;
	assign HEX3 = 7'b1111111;
	assign HEX4 = 7'b1111111;
	assign HEX5 = 7'b1111111;
 
	wire [3:0]Q;
	E15Counter1HzB myCounter(CLOCK_50, 4'd15, Q);
 
	wire Rdy;
	reg Clock;
	reg StartReq=0;

	reg [7:0] LEDBuffer = 8'b11111111;
	reg [7:0] WriteLength = 8'b00000010;
	reg [7:0] ReadLength = 8'b00000000;
	
	reg [7:0] WriteBytes [0:7] = '{8'b01110000, 8'b00000000,8'b11110001,8'b11111111,8'b11111111,8'b11111111,8'b11111111,8'b11111111};
	wire [7:0] ReadBytes [0:7];
	
	
	
	
	//assign LEDR[7:0] = ~LEDBuffer;
	assign LEDR[9] = Rdy;

	I2CStateMachine machine(GPIO_0[28], GPIO_0[29], Q[0], WriteBytes, ReadBytes, WriteLength, ReadLength, StartReq, Rdy);

	reg [7:0] SetPotReadAddrWriteBytes [0:7] = '{8'b10010000, 8'b00000000,8'b0,8'b0,8'b0,8'b0,8'b0,8'b0};
	reg [7:0] GetPotWriteBytes [0:7] = '{8'b10010001, 8'b0,8'b0,8'b0,8'b0,8'b0,8'b0,8'b0};
	reg [7:0] SetLEDsWriteBytes [0:7] = '{8'b01110000, 8'b0,8'b0,8'b0,8'b0,8'b0,8'b0,8'b0};//needs LED values in [1]
	reg [7:0] SetRecordBtnReadAddrWriteBytes [0:7] = '{8'b10010000, 8'b00000001,8'b0,8'b0,8'b0,8'b0,8'b0,8'b0};
	reg [7:0] GetRecordBtnWriteBytes [0:7] = '{8'b10010001, 8'b0,8'b0,8'b0,8'b0,8'b0,8'b0,8'b0};
	reg [7:0] GetBtnsWriteBytes [0:7] = '{8'b01110001, 8'b0,8'b0,8'b0,8'b0,8'b0,8'b0,8'b0};
	reg [7:0] SetMemWriteBytes [0:7] = '{8'b10100000, 8'b00000000,8'b0,8'b0,8'b0,8'b0,8'b0,8'b0};//needs Addr values in [2] and data value in [3]
	reg [7:0] SetMemReadAddrWriteBytes [0:7] = '{8'b10100000, 8'b00000000,8'b0,8'b0,8'b0,8'b0,8'b0,8'b0};//needs Addr values in [2]
	reg [7:0] GetMemWriteBytes [0:7] = '{8'b10100001, 8'b0,8'b0,8'b0,8'b0,8'b0,8'b0,8'b0};
	

	reg[7:0] I2CButtons=8'b0;
	reg[7:0] PotValue=8'b0;
	reg[7:0] EEPROMByte=8'b0;
	reg[7:0] RecordBtnValue=8'b0;
	reg prevRecordState = 0;
	
	reg dumbTest = 1;
	reg SetPotAddr = 0;
	reg GetPot = 0;//get value from potentiometer
	reg SetLEDs = 0;//set value of I2C LEDs (to show potentiometer value)
	reg SetRecordBtnAddr = 0;
	reg GetRecordBtn = 0;//get value of record button
	reg GetBtns = 0;//get I2C buttons
	reg SetMem = 0;//if record button is true (and was false before), set mem
	reg SetMemReadAddr = 0;//use I2C buttons for 8 bits in EEPROM address and set address for read
	reg GetMem = 0;//read EEPROM byte and drive on-shield LEDs
	
	reg HasSetMem = 0;
	
	reg dontStartReq = 0;
	
	always @(negedge Q[0]) begin
		if(Rdy & ~StartReq) begin
			if(dumbTest)begin
				dumbTest = 0;
				SetPotAddr = 1;
				dontStartReq = 1;
			end
			else if(SetPotAddr) begin
				EEPROMByte = ReadBytes[0];
				LEDR[7:0] = ReadBytes[0];
				WriteBytes = SetPotReadAddrWriteBytes;
				WriteLength = 2;
				ReadLength = 0;
				
				SetPotAddr=0;
				GetPot=1;
			end
			else if(GetPot)begin
				WriteBytes = GetPotWriteBytes;
				WriteLength = 1;
				ReadLength = 2;
				
				GetPot = 0;
				SetLEDs = 1;
			end
			else if(SetLEDs)begin
				PotValue = ReadBytes[1];//update pot value
			
				WriteBytes = SetLEDsWriteBytes;
				WriteBytes[1] = ReadBytes[1];//set LED output to pot input
				WriteLength = 2;
				ReadLength = 0;
				
				SetLEDs = 0;
				SetRecordBtnAddr = 1;
			end
			else if(SetRecordBtnAddr)begin
				WriteBytes = SetRecordBtnReadAddrWriteBytes;
				WriteLength = 2;
				ReadLength = 0;
				
				SetRecordBtnAddr = 0;
				GetRecordBtn = 1;
			end
			else if(GetRecordBtn)begin
				WriteBytes = GetRecordBtnWriteBytes;
				WriteLength = 1;
				ReadLength = 2;
				
				GetRecordBtn = 0;
				GetBtns = 1;
			end
			else if(GetBtns)begin
				RecordBtnValue = ReadBytes[1];
				if(~prevRecordState)begin
					HasSetMem = 0;
				end
				
				
				WriteBytes = GetBtnsWriteBytes;
				WriteLength = 1;
				ReadLength = 1;
				
				GetBtns = 0;
				SetMem = 1;
			end
			else if(SetMem)begin
			
				I2CButtons = ReadBytes[0];
				//LEDR[7:0] = ReadBytes[0];
				if(RecordBtnValue < 128 | HasSetMem)begin
					dontStartReq = 1;
					LEDR[8] = 0;
				end
				else begin
					LEDR[8] = 1;
					HasSetMem = 1;
				end
			
				WriteBytes = SetMemWriteBytes;
				WriteBytes[2] = ReadBytes[0];
				WriteBytes[3] = PotValue;
				WriteLength = 4;
				ReadLength = 0;
					
				SetMem = 0;
				SetMemReadAddr = 1;
			end
			else if(SetMemReadAddr)begin
				WriteBytes = SetMemReadAddrWriteBytes;
				WriteBytes[2] = I2CButtons;
				WriteLength = 3;
				ReadLength = 0;
				
				SetMemReadAddr = 0;
				GetMem = 1;
			end
			else if(GetMem)begin
				WriteBytes = GetMemWriteBytes;
				WriteLength = 1;
				ReadLength = 1;
				
				GetMem = 0;
				//SetPotAddr = 1;
				dumbTest = 1;
			end
		
			if(~dontStartReq)begin
				StartReq = 1;
			end
			dontStartReq = 0;
		end
		else if(~Rdy)begin
			StartReq = 0;
		end
	end
 
endmodule


module E15Counter1HzB(Clk, D, Q);
input Clk;
input [3:0] D;
output [3:0] Q;

reg [25:0] R;
reg [3:0] CntOut;
assign Q=CntOut;

always @(posedge Clk)
begin
	if (R<250)//if (R<50000000)//500
		R <= R+26'b1;
	else
		begin
			R <= 26'b0;
			CntOut <= ((CntOut<D) ? CntOut+4'b1 : 4'b0);
		end
end

endmodule
