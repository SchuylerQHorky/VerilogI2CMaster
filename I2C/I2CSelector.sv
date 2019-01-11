module I2CSelector(SDA, DOut, DIn, MasterAck, SlaveAck, RW, Ack, outputs);
	inout SDA;
	
	input DOut;
	wire DOut;
	
	input DIn;
	wire DIn;
	

	input MasterAck;
	wire MasterAck;
	
	output SlaveAck;
	reg SlaveAck;
	
	input RW;
	wire RW;
	
	input Ack;
	wire Ack;
	
	output[3:0] outputs;
	reg[3:0] outputs;
	reg high = 1;

	
	Decoder2_4 decoder(outputs, Ack, RW);
	
	Tristate o0(DOut, outputs[0], SDA);
	Tristate o1(SDA, outputs[1], DIn);
	Tristate o2(MasterAck, outputs[2], SDA);
	Tristate o3(SDA, outputs[3], SlaveAck);
	
endmodule
