/****************************************************************
 Module to implement syncing a pushbutton reset on the DE0-nano.
 Author : Gustavo Zach Vargas 		HDL : Verilog		 	
 Date : 9/24/2015 							
****************************************************************/ 

module reset_synch(rst_n, RST_n, clk);

////////// Variable Declaration for interface ///////////////////
input RST_n;	// The raw input from push button
input clk;		// system clock, use negedge

output rst_n;	// syncronized reset

////////// Intermediate wire Declarations //////////////////////
reg FF1;	// First flop used for synching rst_n
reg FF2;	// Second flop for meta stability

always @(negedge clk, negedge RST_n) begin
	if (!RST_n)
		begin
			FF1 <= 1'b0;
			FF2 <= 1'b0;
		end
	else
		begin
			FF1 <= 1'b1;
			FF2 <= FF1;	
		end
end

////////////////////////// assign rst_n /////////////////////////
assign rst_n = FF2;

endmodule 
