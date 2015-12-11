//Aaron Rosen
//MicroPs Final Project Testbench
/*
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
/*
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
	*/
	/*	
	//TEST: executeCommand
	//standalone module verified: 12/01 @20:33
	//Note: durCheck must be modified to #(15) to simulate in a reasonable timeframe
	//logic needed
	logic clk;
	logic resetDur,presetDur;
	logic [7:0] lmotor,rmotor,dur;
	logic executeComplete;
	logic [1:0] HL,HR;
	executeCommand dut(clk,resetDur,presetDur,lmotor,rmotor,dur,executeComplete,HL,HR);
	
	always
		begin
			clk <=1; #10; clk <=0; #10;
		end
	
	initial
		begin
			assign resetDur = 0;
			assign dur = 8'hAD;
			#23;
			assign presetDur = 1;
			assign lmotor = 8'h7F;
			assign rmotor = 8'h8F;
			#100;
			assign presetDur=0;
			assign resetDur=1;
			#100;
			assign resetDur=0;
			#1000000;
			assign dur = 8'h0E;
			assign lmotor = 8'hB3;
			assign rmotor = 8'h05;
			assign resetDur=1;
			#100;
			assign resetDur=0;
			#100000;
		end
		
		
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
*/