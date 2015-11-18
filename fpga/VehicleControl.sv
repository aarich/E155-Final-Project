module VehicleControl(input logic clk,
							 input logic RX,
							 output logic TX,
							 output logic[1:0] HL,HR);
		//top level module
		//TODO: Make PLL for UART
		//TODO: add slowclk here
		logic[7:0] lmotor,rmotor,dur;
		logic loadStart,loadComplete;
		logic executeStart,executeComplete; //executeStart should pulse when starting rather than staying high
		logic ackStart,ackSent;
		
		
		controller control(clk,loadComplete,executeComplete,ackSent,loadStart,executeStart,ackStart);
		
		receiveMSG RXin(clk,RX,loadStart,lmotor,rmotor,dur,loadComplete);
		executeCommand executor(clk,executeStart,lmotor,rmotor,dur,executeComplete,HL,HR);
		sendAck TXout(clk,ackStart,ackSent,TX);
		
endmodule

module controller(input logic clk,
						input logic loadComplete,
						input logic executeComplete,
						input logic ackSent,
						output logic loadStart,
						output logic executeStart,
						output logic ackStart);
	//datapath controller
	reg[2:0] state;
	logic execute,executeDelayed;
	always_ff @(posedge clk)
		begin
			case(state)
				3'b001:	begin
								if(loadComplete) 		state<=3'b010; //state becomes execute
								else						state<=3'b001; //state remains load
							end
				3'b010:	begin
								if(executeComplete) 	state<=3'b100; //state becomes ack
								else						state<=3'b010; //state remains execute
							end
				3'b100:	begin
								if(ackSent) 			state<=3'b001; //state becomes load
								else						state<=3'b100; //state remains ack
							end
				default: 								state<=3'b001; //default to load
			endcase
		end
	assign {ackStart,execute,loadStart}=state; //delegate signals accordingly
	flop executeDelay(clk,execute,executeDelayed);
	assign executeStart = execute & ~ executeDelayed;
endmodule

module receiveMSG(input logic clk,
				  input logic RX,loadStart,
				  output logic[7:0] lmotor,rmotor,dur,
				  output logic loadComplete);
	//top level for message recive subsystem
	//TODO: Pull slowClk out of this module hierarchy and make slowclk an input
	logic[7:0] char;
	logic RXdone;
	UARTRX receiveChar(clk,RX,char,RXdone);
	shift3rst receiveCtr(loadStart,RXdone,loadComplete,loadComplete);
	always_ff @(posedge RXdone)
		begin
			if(loadStart) {lmotor,rmotor,dur}={rmotor,dur,char};
		end
		
endmodule

module executeCommand(input logic clk,
							 input logic resetDur,
							 input logic [7:0]lmotor,rmotor,dur,
							 output logic executeComplete,
							 output logic [1:0] HL,HR);
	//top level for message execute subsystem
	logic LPWM,RPWM;
	
	durcheck duration(dur,clk,resetDur,executeComplete);
	pwm lmotorPWM(lmotor[6:0],clk,resetDur,LPWM);
	pwm rmotorPWM(rmotor[6:0],clk,resetDur,RPWM);
	hBridgeIn LHbridge(LPWM,executeComplete,lmotor[7],HL);
	hBridgeIn RHbridge(RPWM,executeComplete,rmotor[7],HR);
endmodule

module sendAck(input logic clk,
					input logic ackStart,
					output logic ackSent,
					output logic TX);
	//top level for ack send subsystem
	UARTTX sendChar(clk,ackStart,TX,ackSent);
	
endmodule

module UARTTX(input logic clk,
				  input logic ackStart,
				  output logic TX,
				  output logic msgSent);
	//UART TX Pin
	//ACK is "A" (0x41), msg is 11'b0_0100_0001_11 = 11'b001_0000_0111 = 11'h107
	logic valid;
	assign valid =1;
	logic clk2;
	logic[10:0]msg;
	logic[3:0]count; //keeps track of the number of bits sent
	slowclk baudrate(clk,valid,clk2);
	always_ff @(posedge clk2)
		begin
			if(ackStart) {msg[9:0],msg[10]}={msg}; //this is an 11-bit shift register
			else {msg[9:0],msg[10]} = {10'h107,1'h0};	//reset message loop to default position
		end
	assign TX = msg[0];
	timer #(4) bitCount(clk2,0,count);
	assign msgSent = &(count & 4'hB); //message send high after 11th bit sent
	
endmodule

module UARTRX(input logic clk,
			  input logic RX,
			  output logic[7:0] char,
			  output logic done);
	//UART RX Pin
	logic[3:0] validCheck;
	logic valid;
	logic clk2;
	logic[1:0] stopBits;
	
	always_ff @(posedge clk,posedge done)
		begin
			if(done) valid <= 0;
			else valid <= valid | (~|(validCheck));
		end
	shift4 sampler(RX,clk,validCheck);
	slowclk baudrate(clk,valid,clk2);
	always_ff @(posedge clk2)
		begin
			if(valid) {done,char,stopBits}={char,stopBits,RX}; //this is an 11-bit shift register
			else	{done,char,stopBits} = 11'h001;
		end
	
endmodule

module hBridgeIn(input logic pwr,done,direction,
				 output logic[1:0] out);
	//cuts power to H-Bridge when done is asserted
	logic[1:0]sig;
	assign sig[0]=0;
	assign sig[1] = pwr & ~done;
	assign out = direction?{sig[0],sig[1]}:sig; //direction is sign in sign/mag number
endmodule

module pwm(input logic [6:0] power,
		   input logic clk,reset,
		   output logic wave);
	//Takes in an input signal and outputs corresponding PWM signal
	logic [6:0] count;
	timer #(7) pwmTimer(clk,reset,count);
	assign wave = (power > count);
endmodule

module durcheck(input logic[7:0] dur,
				input logic clk,reset,
				output logic done);
	//checks the duration and cuts power to the wheels when done
	logic[29:0] durTime;
	always_ff @(posedge clk,posedge reset)
		begin
			if(reset) durTime <=0;
			else if(done) durTime <= durTime;
			else durTime <= durTime + 1'b1;
		end
	assign done = &(dur & durTime[29:22]);
endmodule

module shift3rst(input logic in,clk,reset,
			  output logic out);
	//3-register shift register with reset
	logic d1,d2;
	always_ff @(posedge clk,posedge reset)
		if(reset)
			begin
				d1 <=0;
				d2 <=0;
				out <=0;
			end
		else
			begin
				d1<=in;
				d2<=d1;
				out<=d2;
			end
endmodule

module shift4(input logic in,clk,
			  output logic[3:0] out);
	//4-register shift register, outputs all shifted bits		  
	always_ff @(posedge clk)
		begin
			out[0]<=in;
			out[1]<=out[0];
			out[2]<=out[1];
			out[3]<=out[2];
		end
endmodule

module slowclk(input logic clk,valid,
			   output logic clk2);
	//creates a second slow timer that is reliant on valid for centering
	logic [3:0]count;
	always_ff  @(posedge clk)
		begin
			if(valid) count <= count + 4'h1; //if the signal is valid, increment the counter normally
			else
				begin  //if the signal is not valid, hold the slow clock right before the transition
					count[3] <= 0;
					count[2] <= 1;
					count[1] <= 1;
					count[0] <= 1;
				end
		end
	assign clk2=count[3];
endmodule

	
module timer #(parameter WIDTH=8)
			  (input logic clk,reset,
			   output logic [WIDTH-1:0] timeout);
	//a WIDTH-bit timer
	always_ff @(posedge clk,posedge reset)
		begin
			if(reset) timeout <= 0;
			else timeout <= timeout + 1'b1;
		end
endmodule

module flop #(parameter WIDTH=1)
				 (input logic clk,
				  input logic [WIDTH-1:0] d,
				  output logic [WIDTH-1:0] q);
	always_ff @(posedge clk)
		begin
			q <= d;
		end
endmodule 