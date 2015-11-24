/****************************************************************
 Module to implement the FIR engine for Lowpass band.
 Authors : ThunderCatz 		HDL : System Verilog		 
 Student ID: 903 015 5247	
 Date : 11/24/2015 							
****************************************************************/ 
module LP_FIR(smpl_out, sequencing, smpl_in, clk, rst_n);

/********************TODO***********************/
// NOTE: smpl_out will go to zero when sequencing is not true, will this cause
// a noticable 'glitch' in sound?

////////// Variable Declaration for interface ///////////////////
output signed [15:0] smpl_out;	// The FIR scaled sample

input signed [15:0] smpl_in;	// The input audio sample from the queue
input sequencing;		// Signals FIR calculation 
input clk, rst_n;		// System clk and reset

////////// Intermediate wire Declarations ///////////////////////
reg [9:0] index;		// Signal to index into ROM

wire signed [15:0] coeff;	// The FIR coefficient
wire signed [31:0] product;	// Product of the coeff and sample

logic signed [31:0] accum;	// Acumulated FIR results

/////////////////////// ROM instantiation ///////////////////////
ROM_LP iROM (.clk(clk), .addr(index), .dout(coeff));

/////////////////////// product assignment ///////////////////////
assign product = (coeff*smpl_in);

/////////////////////// Infer accum flop ////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		accum <= 32'h0000;
	else if (!sequencing)
		accum <= 32'h0000;
	else
		accum <= accum + product;
end

/////////////////////// Infer index flop ////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		index <= 10'h000;
	else if (!sequencing)
		index <= 10'h000;
	else
		index <= (index + 1) % 1021;
end

/////////////////////// smpl out assignment /////////////////////
assign smpl_out = {accum[30:15]};

endmodule
