module receiveMSG(input logic clk,
				  input logic RX,
				  output logic[7:0] lmotor,rmotor,dur,
				  output logic loadComplete);
	//top level for message recive subsystem
	//TODO: Make PLL for UART
	logic[7:0] char;
	logic RXdone;
	UARTRX(clk,RX,char,RXdone)
	always_ff @(posedge RXdone)
		begin
			{lmotor,rmotor,dur}={rmotor,dur,char};
		end
		
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

module hBridgeIn(input logic pwr,done,
				 output logic out);
	//cuts power to H-Bridge when done is asserted
	assign out = power & ~done;
endmodule

module pwm(input logic [6:0] power,
		   input logic clk,
		   output logic wave);
	//Takes in an input signal and outputs corresponding PWM signal
	logic [6:0] count;
	timer #(7) pwmTimer(clk,reset,count);
	assign wave = (power > count);

module durcheck(input logic[7:0] dur,
				input logic clk,reset,
				output logic done);
	//checks the duration and cuts power to the wheels when done
	logic[7:0] durTime;
	timer #(30) durTimer(clk,reset,durTime);
	assign done = ~|(dur ^ durTime[29:21]);
endmodule

module shift4(input logic in,clk,
			  output logic[3:0] out);
	//4-register shift register, outputs all shifted bits		  
	always_ff @(posedge clk)
		begin
			out[0]<=in;
			out[1]=out[0];
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
			if(valid) count <= count + 4'b0001; //if the signal is valid, increment the counter normally
			else count <= 4'b0111; //if the signal is not valid, hold the slow clock right before the transition
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