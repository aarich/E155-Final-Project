module UARTtxrx(input  logic clk, 
                input  logic sdi,
                output logic sdo,
                input  logic done,
                output logic [7:0] cmd1,cmd2,cmd3);

    logic         sdodelayed, wasdone;
    logic [7:0] ack;
               
    // assert load
    // apply 24 clks to shift in the three commands, starting with cmd1[0]
    // then deassert load, wait until done
    // then apply 128 clks to shift out cyphertext, starting with cyphertext[0]
    always_ff @(posedge clk)
        if (!wasdone)  {ack[7:0],cmd1[7:0],cmd2[7:0],cmd3[7:0]} = {ack[7:0],cmd1[7:0],cmd2[7:0],cmd3[6:0],sdi};
        else           {cyphertextcaptured, plaintext, key} = {cyphertextcaptured[126:0], plaintext, key, sdi}; 
    
    // sdo should change on the negative edge of clk
    always_ff @(negedge clk) begin
        wasdone = done;
        sdodelayed = cyphertextcaptured[126];
    end
    
    // when done is first asserted, shift out msb before clock edge
    assign sdo = (done & !wasdone) ? cyphertext[127] : sdodelayed;
endmodule


module pwm(input logic [6:0] power,
		   input logic clk,
		   output logic wave);
	//Takes in an input signal and outputs corresponding PWM signal
	logic [6:0] count;
	always_ff @(posedge clk)
		begin
			count <= count + 1'b1;
		end
	assign wave = (power < count);

module durcheck(input logic[7:0] dur,
				input logic clk,
				output logic done);
	//checks the duration and cuts power to the wheels when done
	logic[7:0] durTime;
	timer #(8) durTimer(clk,durTime);
	assign done = ~|(dur ^ durTime);
endmodule


module timer #(parameter WIDTH=8)
			  (input logic clk,
			   output logic [WIDTH-1:0] timeout);
	//a WIDTH-bit timer
	always_ff @(posedge clk)
		begin
			timeout <= timeout + 1'b1;
		end
endmodule