/****************************************************************
 Module to implement the band scaling for an equilizer.
 Author : Gustavo Zach Vargas 		HDL : System Verilog		 
 Student ID: 903 015 5247	
 Date : 9/24/2015 							
****************************************************************/ 

module band_scale(scaled, POT, audio);

////////// Variable Declaration for interface ///////////////////
input [11:0] POT;		// A2D reading from slide pot
input signed [15:0] audio;	// Audio signal from FIR

output signed [15:0] scaled;	// Result of audio scaled by POT

////////// Intermediate wire Declarations //////////////////////
wire [23:0] POT_squared; 		// will hold POT^2
wire signed [12:0] FIR_scale;	// Signed 13 bit FIR scale 
wire signed [28:0] scale_audio;	// Scale audio by POT value
wire signed [3:0] sat;		// Top 4 bits detect saturation
wire signed [15:0] result;	// Result if not in saturation
wire sat_neg;			// Set iff in neg saturation
wire sat_pos;			// Set iff in pos saturation

///////////// unsigned 12x12 multiplier ////////////////////////
// Square the value of POT
assign POT_squared = POT*POT;

// Peel off first 12 bits to scale FIR, make signed (0 to MSB)
assign FIR_scale = {1'b0,{POT_squared[23:12]}};

////////////// signed 13x16 multiplier /////////////////////////
assign scale_audio = FIR_scale*audio;

// Throw out 10 LSB, loss of precision
assign result = {scale_audio[25:10]};

// Get top four MSB for satuation detection
assign sat = {scale_audio[28:25]};

////////////// Saturation detection ////////////////////////////
assign sat_neg = sat[3] & ~&sat[2:0];
assign sat_pos = ~sat[3] &  |sat[2:0];

////////////// Select correct output ///////////////////////////
assign scaled =	sat_neg ? 16'h8000		// set to most neg value
			  : sat_pos ? 16'h7FFF	// Set to most pos value
			  : result;		// Set to result (in bounds)

endmodule 
