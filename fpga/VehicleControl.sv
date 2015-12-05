module VehicleControl(input logic clk,
							 input logic RX,
							 output logic TX,
							 output logic[1:0] HL,HR);
		//top level module
		logic[7:0] lmotor,rmotor,dur;
		logic loadStart,loadComplete;
		logic executeStart,executeComplete; //executeStart should pulse when starting rather than staying high
		logic ackStart,ackSent;
		logic pllclk;
		logic reset,locked;
		
		PLLclk pll(reset,clk,pllclk,locked);
		
		controller control(clk,loadComplete,executeComplete,ackSent,loadStart,executeStart,ackStart); //datapath controller
		
		receiveMSG RXin(clk,pllclk,RX,loadStart,lmotor,rmotor,dur,loadComplete);
		executeCommand executor(clk,(loadComplete | executeStart),(~executeComplete & loadStart),lmotor,rmotor,dur,executeComplete,HL,HR);
		sendAck TXout(pllclk,ackStart,ackSent,TX);
		
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

module receiveMSG(input logic clk,PLLclk,
				  input logic RX,loadStart,
				  output logic[7:0] lmotor,rmotor,dur,
				  output logic loadComplete);
	//top level for message recive subsystem
	logic[7:0] char;
	logic RXdone;
	logic resetTrigger;
	UARTRX receiveChar(clk,PLLclk,RX,loadStart,char,RXdone);
	shift3rst receiveCtr(loadStart,RXdone,resetTrigger,loadComplete);
	always_ff @(posedge RXdone)
		begin
			if(loadStart) {lmotor,rmotor,dur}={rmotor,dur,char};
		end
	flop #(1) loadCompleteDelay(clk,loadComplete,resetTrigger);
endmodule

module executeCommand(input logic clk,
							 input logic resetDur,presetDur,
							 input logic [7:0]lmotor,rmotor,dur,
							 output logic executeComplete,
							 output logic [1:0] HL,HR);
	//top level for message execute subsystem
	logic LPWM,RPWM;
	
	durcheck #(30) duration(dur,clk,resetDur,presetDur,executeComplete);
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
	//TODO: Change shift register to more directly include TX
	logic resetTrigger;
	logic ackStartPulse;
	logic clk2;
	logic[10:0]msg;
	logic[3:0]count; //keeps track of the number of bits sent
	slowclk baudrate(clk,1'b1,clk2);
	always_ff @(posedge clk2)
		begin
			if(ackStart) {msg[9:0],msg[10]}={msg[10:0]}; //this is an 11-bit shift register
			else {msg[9:0],msg[10]} = {10'h107,1'h0};	//reset message loop to default position
		end
	assign TX = msg[0];
	timeren #(4) bitCount(clk2,resetTrigger,ackStart,count);
	assign msgSent = (count == 11) & ackStart; //message send high after 11th bit sent
	delay #(1) resetSig(clk,(msgSent|ackStartPulse),resetTrigger);
	pulse ackPulse(clk,ackStart,ackStartPulse);
	
endmodule

module UARTRX(input logic clk,PLLclk,
			  input logic RX,
			  input logic loadStart,
			  output logic[7:0] char,
			  output logic done);
	//UART RX Pin
	logic[3:0] validCheck;
	logic valid;
	logic UARTclk;
	logic[1:0] stopBits;
	logic resetTrigger;
	logic startBit;
	logic loadStartDelayed,doneDelayed;
	
	always_ff @(posedge clk,posedge done)
		begin
			if(done) valid <= 0;
			else valid <= valid | (~|(validCheck));
		end
	shift4 sampler(RX,PLLclk,validCheck);
	slowclk baudrate(PLLclk,valid,UARTclk);
	always_ff @(posedge UARTclk,posedge resetTrigger)
		begin
			if(resetTrigger) {done,startBit,char,stopBits} = 12'h001;
			else {done,startBit,char,stopBits}={startBit,char,stopBits,RX}; //this is an 12-bit shift register	
		end
	delay #(1) doneDelay(clk,done,doneDelayed);
	delay #(1) loadStartDelay(clk,loadStart,loadStartDelayed);
	assign resetTrigger = doneDelayed | (~loadStartDelayed & loadStart);
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

module durcheck #(parameter WIDTH=30)
				(input logic[7:0] dur,
				input logic clk,reset,preset,
				output logic done);
	//checks the duration and cuts power to the wheels when done
	logic[WIDTH-1:0] durTime;
	always_ff @(posedge clk,posedge reset)
		begin
			if(reset) durTime <=0;
			else if(preset) durTime <= {dur,{WIDTH-8{1'b0}}};
			else if(done) durTime <= durTime;
			else durTime <= durTime + 1'b1;
		end
	assign done = (dur == durTime[WIDTH-1:WIDTH-8]);
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
	logic [2:0]count;
	always_ff  @(posedge clk)
		begin
			if(valid) count <= count + 3'h1; //if the signal is valid, increment the counter normally
			else
				begin  //if the signal is not valid, hold the slow clock right before the transition
					count[2] <= 0;
					count[1] <= 1;
					count[0] <= 1;
				end
		end
	assign clk2=count[2];
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

module timeren #(parameter WIDTH=8)
			  (input logic clk,reset,enable,
			   output logic [WIDTH-1:0] timeout);
	//a WIDTH-bit timer with enable
	always_ff @(posedge clk,posedge reset)
		begin
			if(reset) timeout <= 0;
			else if(enable) timeout <= timeout + 1'b1;
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

module delay #(parameter WIDTH=1)
				 (input logic clk,
				  input logic [WIDTH-1:0] d,
				  output logic [WIDTH-1:0] q);
				  
	logic[WIDTH-1:0] p;
	always_ff @(posedge clk)
		begin
			p <= d;
			q <= p;
		end
endmodule 

module pulse(input logic clk,in,
				 output logic out);
	//creates a pulse when the input signal goes high
	logic delayed;
	delay inDelay(clk,in,delayed);
	assign out = in & ~ delayed;
endmodule


module Testbench();

	//TEST: sendAck
	//standalone module verified: 12/5 @ 00:53
	//logic needed
	logic pllclk;
	logic ackStart;
	logic ackSent;
	logic TX;
	sendAck dut(pllclk,ackStart,ackSent,TX);
	
	always
		begin
			pllclk <=1; #10; pllclk <=0; #10;
		end
	
	initial
		begin
			assign ackStart = 0;
			#203;
			assign ackStart = 1;
			#2200;
			assign ackStart = 0;
			#200;
		end

endmodule
