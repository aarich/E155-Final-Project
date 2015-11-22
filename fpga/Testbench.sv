//Aaron Rosen
//MicroPs Final Project Testbench

module Testbench();

	
	
	//instantiate devices to be tested.  Testcases for:
	/*
		controller
		receiveMSG
		executeCommand
		sendAck
		VehicleControl
	*/
	
	
	/*
	//TEST: Controller
	//standalone module verified 11/21 @16:38
	//logic needed
	logic clk;
	logic loadComplete,loadStart;
	logic executeComplete,executeStart;
	logic ackSent,ackStart;
	controller dut(clk,loadComplete,executeComplete,ackSent,loadStart,executeStart,ackStart);
	initial
		begin
			loadComplete=0;
			executeComplete =1;
			ackSent=0;
		end
	
	always
		begin
			clk <=1; #50; clk <=0; #50;
		end
	
	always
		begin
			#100;
			ackSent<=0;
			#900;
			loadComplete <=1; #100; loadComplete<=0;
			executeComplete <=0;
			#1000;
			executeComplete <=1;
			#1000;
			ackSent<=1;
		end
*/	

	//TEST: receiveMSG
	//standalone module verified: 11/21 @23:07
	//logic needed:
	logic clk,PLLclk;
	logic RX;
	logic loadStart;
	logic[7:0] lmotor,rmotor,dur;
	logic loadComplete;
	receiveMSG dut(clk,PLLclk,RX,loadStart,lmotor,rmotor,dur,loadComplete);
	//chars: 0x95, 0xB6, 0x35
	always
		begin
			clk <=1; #50; clk <=0; #50;
		end

	always
		begin
			PLLclk <=1; #1100; PLLclk <=0; #1100;
		end
				  
	initial
		begin
			RX=1;
		end
		
	always
		begin
			#100;
			loadStart=0;
			#100
			loadStart=1;
			#1000;
			RX=0; //start
			#17600;
			RX=1; //1
			#17600;
			RX=0; //2
			#17600;
			RX=0; //3
			#17600;
			RX=1; //4
			#17600;
			RX=0; //5
			#17600;
			RX=1; //6
			#17600;
			RX=0; //7
			#17600;
			RX=1; //8
			#17600;
			RX=1; //stop
			#17600;
			#17600;
			
			#100000;
			RX=0; //start
			#17600;
			RX=1; //1
			#17600;
			RX=0; //2
			#17600;
			RX=1; //3
			#17600;
			RX=1; //4
			#17600;
			RX=0; //5
			#17600;
			RX=1; //6
			#17600;
			RX=1; //7
			#17600;
			RX=0; //8
			#17600;
			RX=1; //stop
			#17600;
			#17600;
			
			#100000;
			RX=0; //start
			#17600;
			RX=0; //1
			#17600;
			RX=0; //2
			#17600;
			RX=1; //3
			#17600;
			RX=1; //4
			#17600;
			RX=0; //5
			#17600;
			RX=1; //6
			#17600;
			RX=0; //7
			#17600;
			RX=1; //8
			#17600;
			RX=1; //stop
			#17600;
			#17600;
			#100000;
		end
endmodule
