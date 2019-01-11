//I2C master state machine
module I2CStateMachine(SDA, SCL, Clock, WriteBytes, ReadBytes, WriteLength, ReadLength, StartReq, Rdy);
	
	//Serial Data; connect to SDA IO port, must support tristate for receiving data from slaves
	inout SDA;
	tri SDA;
	
	//Serial Clock; connect to SCL IO port
	output SCL;
	reg SCL;
	
	//Bytes to send
	//Elements 1-7 reserved for slave address [7:1] and element 0 for read/~write operation
	input[7:0] WriteBytes[0:7];
	wire[7:0] WriteBytes [0:7];
	
	//Bytes received from slave
	output[7:0] ReadBytes[0:7];
	reg[7:0] ReadBytes [0:7];
	
	//Number of bytes in write buffer to send to slave
	//Should always be 1 or more since address is always sent
	input[7:0] WriteLength;
	wire[7:0] WriteLength;
	
	//Number of bytes to read from slave before sending NACK signal
	input[7:0] ReadLength;
	wire[7:0] ReadLength;

	//Counts from 0 to WriteLength + ReadLength (i.e. the total number of bytes sent and received during a state machine cycle)
	reg[7:0] ByteIndex=8'b0;
	
	//Counts from 0 to 7, indexing the bit to send to or read from SDA
	reg[3:0] BitIndex=4'b0;

	//Input clock signal for state machine. SCL is driven at .5*Clock
	input Clock;
	wire Clock;
	
	//Read/~Write mode. Always starts at write, switches to read when (ByteIndex == WritLength) after ACK is set false
	reg RW = 0;
	
	//Acknowledge is true from 9th to 10th negedge of SCL and re-routes SDA
	reg Ack=0;
	
	//StartReq is set true (when Rdy is true) to start data transmission
	input StartReq;
	wire StartReq;
	
	//Stores ack value from slave device during write operations.
	//No error handling is implemented for slave ack failures.
	reg SlaveAck = 0;
	
	//State machine status bits.
	//State machine is ready when Start,Send,Stop are all false.
	//When Start == 1, state machine is in startup phase.
	//When Send == 1, state machine is in send/receive phase (RW can be 1 or 0).
	//When Stop == 1, state machine is in shutdown phase.
	reg Start=0;
	reg Send=0;
	reg Stop=0;
	
	//When Rdy is true, StartReq can be clocked in to start state machine.
	output Rdy;
	reg Rdy;
	
	//Sets up combo logic for Rdy; Rdy is true when Start,Send,and Stop are all 0.
	assign Rdy = ~Start & ~Send & ~Stop;
	
	//Overrides to pull SDA and SCL low or high, used in start and stop conditions.
	reg PullSDALow=0;
	reg PullSDAHigh=1;//set high initially, since SDA should be pulled high when not in use
	reg PullSCLLow=0;
	reg PullSCLHigh=1;//set high initially, since SCL should be pulled high when not in use
	
	//Extra reg values to which SDA can be routed via tri-state buffers.
	reg low = 0;
	reg high = 1;
	
	//used for ACK logic. Stop condition when (RW == 1) requires Ack value from master to remain high (Nack) instead of low (Ack).
	//ackValue is set to 1 in such a case.
	reg ackValue = 0;

	//Routes ack, override on low and high, and data out (WriteBytes[][]) to SDA
	Tristate t1(low, PullSDALow, SDA);
	Tristate t2(high, PullSDAHigh, SDA);
	//Ack ANDed with RW because slave sends ack when RW == 0 instead of master sending ack.
	Tristate t3(ackValue, Ack & RW, SDA);
	//7 subtracted from BitIndex so that BitIndex reflects # of bits sent and state machine sends MSB to SDA first.
	Tristate t4(WriteBytes[ByteIndex][4'b0111 - BitIndex], ~RW&~Ack&(~PullSDAHigh & ~PullSDALow), SDA);
	
	//Frequency divider reg; gets toggled every posedge of clock and drives SCL
	reg SCLValue = 0;
	
	//Main event in state machine
	always @(posedge Clock) begin
		
		//when SCLValue == 1, it's the pseudo negedge of SCL
		//Can't separate into two separate always blocks because
		//1) can't have dual-edge triggered flip flops and 
		//2) can't have multiply driven reg's
		if(SCLValue) begin
			
			//check for start request to start I2C transmission.
			//also, a transmission cannot already be in progress
			if(StartReq & Rdy)begin//#1
				//set start condition high
				Start = 1;
				//immediately pull SDA low (first part of start condition)
				PullSDALow = 1;
				//clear any pre-condition to pull SDA high
				PullSDAHigh = 0;
				
				//reset counters
				ByteIndex = 8'b0;
				BitIndex = 4'b0;
				
				//reset ackValue for Ack (instead of Nack)
				ackValue = 0;
				
				//reset RW to write mode
				RW = 0;
			end
			//if still in Start phase and start condition is completed(SDA is no longer pulled low)
			else if (Start & ~PullSDALow)begin//#3
				//release SCL from any pulls high or low; it will now be .5*input Clock
				PullSCLLow = 0;
				PullSCLHigh = 0;
				
				//state machine has completed start condition; now ready to send data on 
				Start = 0;
				//commence data transmission on next posedge of Clock
				Send = 1;
			end
			else if (Send & PullSCLLow) begin//NOT IN USE
				PullSCLLow = 0;
				PullSDALow = 0;
			end
			else if(Stop & Send) begin//#15
				Send = 0;	
				if(PullSDAHigh)begin
					PullSDALow = 1;
					PullSDAHigh = 0;
					PullSCLLow = 1;
				end
			end
			else if (Stop & ~Send) begin//#17
				Stop = 0;	
				PullSDALow = 0;
				PullSDAHigh = 1;
			end	
		end
		//when SCLValue == 0, it's the pseudo posedge of SCL
		else begin
			//When in start mode and second part of start condition has not occured (~PullSCLLow)
			if(Start & ~PullSCLLow)begin//#2
				//Pull SCL low (second part of start condition)
				PullSCLLow = 1;
				//clear any pre-condition to pull SCL high 
				PullSCLHigh = 0;
			end
			else if (Start & PullSDALow) begin//NOT IN USE
				PullSDALow = 0;
			end
			//
			else if (Stop & ~Send) begin//#16
				PullSCLHigh = 1;
				PullSCLLow = 0;
			end
			
			//A pull high or low overrides all other states for SCL
			if(PullSCLLow | PullSCLHigh) begin//#-oo-#0
				//do nothing
			end
			//If the last bit in a byte has been sent/read
			else if(BitIndex == 4'b0111)begin//ack,#13
				//Set Ack high
				Ack = 1;
				//reset bit counter
				BitIndex=0;
				
				//if state machine is in read mode and transmission is complete
				if(RW & ByteIndex+1 == ReadLength + WriteLength) begin
					//send NACK instead of Ack, as per the stop condition of a read command
					ackValue = 1;//normally 0 for Ack
				end
			end		
			//else if Ack has already been set high
			else if(Ack) begin//ack has been high for 1 clock pulse,#14
				//reset ack
				Ack = 0;
				
				//Increment the byte index to write/read next byte in sequence
				ByteIndex = ByteIndex + 1;

				//if state machine is in write mode and all bytes to write have been written
				if(~RW & ByteIndex == WriteLength)begin
					//if no read bytes exist
					if(ReadLength == 8'b0)begin
						//I2C transmission is complete
						//set stop bit (Stop = 1, Send is still 1)
						Stop = 1;
						//first part of stop condition
						PullSDALow = 1;
					end
					//else, there's data to read from slave
					else begin
						//change mode to read data
						RW=1;
					end
				end
				//else if state machine is in read mode and all read bytes have been read in from slave
				else if(RW & ByteIndex == ReadLength + WriteLength)begin
					//I2C transmission is complete
					//continues stop condition that was started during last Ack bit (actually a Nack bit)
					//keep SDA high from when Nack pulled it high
					PullSDAHigh = 1;
					//sets stop = 1 (Stop = 1, Send is still 1)
					Stop = 1;
				end
			end
			//else, state machine is in the middle of sending/receiving a byte
			else begin//#4-12
				//make bit counter count up (counts from 0 to 7, then Ack, then counts from 0 to 7...)
				BitIndex= BitIndex + 1;
			end
		end

		
		//Serial Data (SDA) assignments
		if(PullSDALow) begin
			//SDA is set low by tristate buffer
		end
		else if(PullSDAHigh)begin
			//SDA is set high by tristate buffer
		end
		//else state machine is not in a start/stop/Rdy transition
		else begin
			//when Ack is high for 1 SCL clock pulse (negedge to negedge) (Ack is set high after sending/receiving each byte)
			if(Ack) begin
				if(RW) begin
					//SDA is set to appropriate ack value by tristate buffer
					//equivalent to: SDA = 0;
				end
				else begin
					//tie slave ack register to SDA, to record if slave received data (low) or not (high)
					SlaveAck = SDA;
				end		
			end
			//no ack
			else begin
				//when reading
				if(RW) begin
					//put data from slave into slave read register
					ReadBytes[ByteIndex-WriteLength][4'b0111 - BitIndex] = SDA;
					//BitIndex is flipped so that bits are sent and received MSB first (bit 7->0)
					//while BitIndex is the number of bits sent during a byte send (bit 0->7).
				end
				else begin
					//SDA is tied to selected data bit via a tristate buffer
					//equivalent to: SDA = MemoryBlock[ByteIndex][BitIndex];
				end
			end
		end

		//Serial Clock (SCL) assignments
		if(PullSCLLow) begin
			//Pull SCL low
			SCL = 0;
		end
		else if(PullSCLHigh) begin
			//Pull SCL High
			SCL = 1;	
		end
		else begin
			//Set SCL to .5*Input clock
			SCL = SCLValue;
		end
		
		//flip SCLValue
		SCLValue = ~SCLValue;
	end
	
endmodule



module I2C_StateMachine_testbench();

	
	//Serial Data; connect to SDA IO port, must support tristate for receiving data from slaves
	//inout SDA;
	tri SDA;
	
	//Serial Clock; connect to SCL IO port
	//output SCL;
	reg SCL;
	
	//Bytes to send
	//Elements 1-7 reserved for slave address [7:1] and element 0 for read/~write operation
	reg[7:0] WriteBytes[0:7] = '{8'b01110000, 8'b01101100, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0};
	//wire[7:0] WriteBytes [0:7];
	
	//Bytes received from slave
	//output[7:0] ReadBytes[0:7];
	reg[7:0] ReadBytes [0:7]= '{8'b0, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0};
	
	//Number of bytes in write buffer to send to slave
	//Should always be 1 or more since address is always sent
	//input[7:0] WriteLength;
	reg[7:0] WriteLength = 8'b00000010;
	
	//Number of bytes to read from slave before sending NACK signal
	//input[7:0] ReadLength;
	reg[7:0] ReadLength = 8'b00000001;

	//Counts from 0 to WriteLength + ReadLength (i.e. the total number of bytes sent and received during a state machine cycle)
	reg[7:0] ByteIndex=8'b0;
	
	//Counts from 0 to 7, indexing the bit to send to or read from SDA
	reg[3:0] BitIndex=4'b0;

	//Input clock signal for state machine. SCL is driven at .5*Clock
	//input Clock;
	reg Clock;
	
	//Read/~Write mode. Always starts at write, switches to read when (ByteIndex == WritLength) after ACK is set false
	reg RW = 0;
	
	//Acknowledge is true from 9th to 10th negedge of SCL and re-routes SDA
	reg Ack=0;
	
	//StartReq is set true (when Rdy is true) to start data transmission
	//input StartReq;
	reg StartReq;
	
	//Stores ack value from slave device during write operations.
	//No error handling is implemented for slave ack failures.
	reg SlaveAck = 0;
	
	//State machine status bits.
	//State machine is ready when Start,Send,Stop are all false.
	//When Start == 1, state machine is in startup phase.
	//When Send == 1, state machine is in send/receive phase (RW can be 1 or 0).
	//When Stop == 1, state machine is in shutdown phase.
	reg Start=0;
	reg Send=0;
	reg Stop=0;
	
	//When Rdy is true, StartReq can be clocked in to start state machine.
	//output Rdy;
	reg Rdy;
	
	//Sets up combo logic for Rdy; Rdy is true when Start,Send,and Stop are all 0.
	assign Rdy = ~Start & ~Send & ~Stop;
	
	//Overrides to pull SDA and SCL low or high, used in start and stop conditions.
	reg PullSDALow=0;
	reg PullSDAHigh=1;//set high initially, since SDA should be pulled high when not in use
	reg PullSCLLow=0;
	reg PullSCLHigh=1;//set high initially, since SCL should be pulled high when not in use
	
	//Extra reg values to which SDA can be routed via tri-state buffers.
	reg low = 0;
	reg high = 1;
	
	//used for ACK logic. Stop condition when (RW == 1) requires Ack value from master to remain high (Nack) instead of low (Ack).
	//ackValue is set to 1 in such a case.
	reg ackValue = 0;

	//Routes ack, override on low and high, and data out (WriteBytes[][]) to SDA
	Tristate t1(low, PullSDALow, SDA);
	Tristate t2(high, PullSDAHigh, SDA);
	//Ack ANDed with RW because slave sends ack when RW == 0 instead of master sending ack.
	Tristate t3(ackValue, Ack & RW, SDA);
	//7 subtracted from BitIndex so that BitIndex reflects # of bits sent and state machine sends MSB to SDA first.
	Tristate t4(WriteBytes[ByteIndex][4'b0111 - BitIndex], ~RW&~Ack&(~PullSDAHigh & ~PullSDALow), SDA);
	
	//Frequency divider reg; gets toggled every posedge of clock and drives SCL
	reg SCLValue = 0;
	
	//Main event in state machine
	always @(posedge Clock) begin
		
		//when SCLValue == 1, it's the pseudo negedge of SCL
		//Can't separate into two separate always blocks because
		//1) can't have dual-edge triggered flip flops and 
		//2) can't have multiply driven reg's
		if(SCLValue) begin
			
			//check for start request to start I2C transmission.
			//also, a transmission cannot already be in progress
			if(StartReq & Rdy)begin//#1
				//set start condition high
				Start = 1;
				//immediately pull SDA low (first part of start condition)
				PullSDALow = 1;
				//clear any pre-condition to pull SDA high
				PullSDAHigh = 0;
				
				//reset counters
				ByteIndex = 8'b0;
				BitIndex = 4'b0;
				
				//reset ackValue for Ack (instead of Nack)
				ackValue = 0;
				
				//reset RW to write mode
				RW = 0;
			end
			//if still in Start phase and start condition is completed(SDA is no longer pulled low)
			else if (Start & ~PullSDALow)begin//#3
				//release SCL from any pulls high or low; it will now be .5*input Clock
				PullSCLLow = 0;
				PullSCLHigh = 0;
				
				//state machine has completed start condition; now ready to send data on 
				Start = 0;
				//commence data transmission on next posedge of Clock
				Send = 1;
			end
			else if (Send & PullSCLLow) begin//NOT IN USE
				PullSCLLow = 0;
				PullSDALow = 0;
			end
			else if(Stop & Send) begin//#15
				Send = 0;	
				if(PullSDAHigh)begin
					PullSDALow = 1;
					PullSDAHigh = 0;
					PullSCLLow = 1;
				end
			end
			else if (Stop & ~Send) begin//#17
				Stop = 0;	
				PullSDALow = 0;
				PullSDAHigh = 1;
			end	
		end
		//when SCLValue == 0, it's the pseudo posedge of SCL
		else begin
			//When in start mode and second part of start condition has not occured (~PullSCLLow)
			if(Start & ~PullSCLLow)begin//#2
				//Pull SCL low (second part of start condition)
				PullSCLLow = 1;
				//clear any pre-condition to pull SCL high 
				PullSCLHigh = 0;
			end
			else if (Start & PullSDALow) begin//NOT IN USE
				PullSDALow = 0;
			end
			//
			else if (Stop & ~Send) begin//#16
				PullSCLHigh = 1;
				PullSCLLow = 0;
			end
			
			//A pull high or low overrides all other states for SCL
			if(PullSCLLow | PullSCLHigh) begin//#-oo-#0
				//do nothing
			end
			//If the last bit in a byte has been sent/read
			else if(BitIndex == 4'b0111)begin//ack,#13
				//Set Ack high
				Ack = 1;
				//reset bit counter
				BitIndex=0;
				
				//if state machine is in read mode and transmission is complete
				if(RW & ByteIndex+1 == ReadLength + WriteLength) begin
					//send NACK instead of Ack, as per the stop condition of a read command
					ackValue = 1;//normally 0 for Ack
				end
			end		
			//else if Ack has already been set high
			else if(Ack) begin//ack has been high for 1 clock pulse,#14
				//reset ack
				Ack = 0;
				
				//Increment the byte index to write/read next byte in sequence
				ByteIndex = ByteIndex + 1;

				//if state machine is in write mode and all bytes to write have been written
				if(~RW & ByteIndex == WriteLength)begin
					//if no read bytes exist
					if(ReadLength == 8'b0)begin
						//I2C transmission is complete
						//set stop bit (Stop = 1, Send is still 1)
						Stop = 1;
						//first part of stop condition
						PullSDALow = 1;
					end
					//else, there's data to read from slave
					else begin
						//change mode to read data
						RW=1;
					end
				end
				//else if state machine is in read mode and all read bytes have been read in from slave
				else if(RW & ByteIndex == ReadLength + WriteLength)begin
					//I2C transmission is complete
					//continues stop condition that was started during last Ack bit (actually a Nack bit)
					//keep SDA high from when Nack pulled it high
					PullSDAHigh = 1;
					//sets stop = 1 (Stop = 1, Send is still 1)
					Stop = 1;
				end
			end
			//else, state machine is in the middle of sending/receiving a byte
			else begin//#4-12
				//make bit counter count up (counts from 0 to 7, then Ack, then counts from 0 to 7...)
				BitIndex= BitIndex + 1;
			end
		end

		
		//Serial Data (SDA) assignments
		if(PullSDALow) begin
			//SDA is set low by tristate buffer
		end
		else if(PullSDAHigh)begin
			//SDA is set high by tristate buffer
		end
		//else state machine is not in a start/stop/Rdy transition
		else begin
			//when Ack is high for 1 SCL clock pulse (negedge to negedge) (Ack is set high after sending/receiving each byte)
			if(Ack) begin
				if(RW) begin
					//SDA is set to appropriate ack value by tristate buffer
					//equivalent to: SDA = 0;
				end
				else begin
					//tie slave ack register to SDA, to record if slave received data (low) or not (high)
					SlaveAck = SDA;
				end		
			end
			//no ack
			else begin
				//when reading
				if(RW) begin
					//put data from slave into slave read register
					ReadBytes[ByteIndex-WriteLength][4'b0111 - BitIndex] = SDA;
					//BitIndex is flipped so that bits are sent and received MSB first (bit 7->0)
					//while BitIndex is the number of bits sent during a byte send (bit 0->7).
				end
				else begin
					//SDA is tied to selected data bit via a tristate buffer
					//equivalent to: SDA = MemoryBlock[ByteIndex][BitIndex];
				end
			end
		end

		//Serial Clock (SCL) assignments
		if(PullSCLLow) begin
			//Pull SCL low
			SCL = 0;
		end
		else if(PullSCLHigh) begin
			//Pull SCL High
			SCL = 1;	
		end
		else begin
			//Set SCL to .5*Input clock
			SCL = SCLValue;
		end
		
		//flip SCLValue
		SCLValue = ~SCLValue;
	end

	initial begin
		Clock = 0;
		StartReq = 0;

		#15
		StartReq = 1;
		#20
		StartReq = 0;
		#80

		
		#1700 $finish;
	end
	
	always begin
		Clock = ~Clock;
		#5;
	end
	
	

endmodule

module Tristate (in, oe, out);
    input   in, oe;
	 wire in, oe;
	 
    output  out;
    tri     out;

	 assign out = oe ? (in) : 1'bz;
endmodule
