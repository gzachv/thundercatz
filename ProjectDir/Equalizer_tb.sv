/****************************************************************
 Module to implement a 5 Channel Equalizer testbench.
 Author : Thundercatz			HDL : System Verilog		 
 Student ID: 903 015 5247	
 Date : 11/30/2015 							
****************************************************************/ 
module Equalizer_tb();
////////////////////////////
// Variable Declarations //
//////////////////////////

reg clk, RST_n;

////////// Variable Declaration for Equalizer ///////////////////
logic [7:0] LED;	// The DE0 board's LED array
logic	A2D_SS_n,	// A2D serial select
	A2D_MOSI,	// A2D Master out slave in
	A2D_SCLK,	// A2D serial clk
	MCLK,		
	SCLK,
	LRCLK,
	SDin,		// Serial in for equalizer
	AMP_ON;		// Control of class D amp
logic	A2D_MISO,	// INPUT, A2d master in slave out
	SDout;		// INPUT, Serial data out
	 
////////// Variable Declaration for CODEC ///////////////////////
wire [15:0] aout_lft,	// Left audio data
	    aout_rht;	// Right audio data
logic	RSTn;		// CODEC reset, active low

logic rst_n;
assign rst_n = RST_n;	// rst_n should be a synchronized version of RST_n

integer fptr;		// File handle for writing output
  
//////////////////////
// Instantiate DUT //
////////////////////
Equalizer iDUT (	.clk(clk), .RST_n(RST_n), 
			.LED(LED), .A2D_SS_n(A2D_SS_n), 
			.A2D_MOSI(A2D_MOSI), .A2D_SCLK(A2D_SCLK), .A2D_MISO(A2D_MISO),
			.MCLK(MCLK), .SCL(SCLK), .LRCLK(LRCLK),
			.SDout(SDout), .SDin(SDin), .AMP_ON(AMP_ON), .RSTn(RSTn) );
				 
//////////////////////////////////////////
// Instantiate model of CODEC (CS4271) //
////////////////////////////////////////
CS4272  iModel (	.MCLK(MCLK), .SCLK(SCLK), .LRCLK(LRCLK),
                	.RSTn(RSTn),  .SDout(SDout), .SDin(SDin),
                	.aout_lft(aout_lft), .aout_rht(aout_rht) );
				
///////////////////////////////////////////////////////////////////////
// Instantiate Model of A2D converter modeling slide potentiometers //
/////////////////////////////////////////////////////////////////////
ADC128S iA2D (	.clk(clk), .rst_n(rst_n), .SS_n(A2D_SS_n), .SCLK(A2D_SCLK),
                	.MISO(A2D_MISO), .MOSI(A2D_MOSI) );
				
initial begin
fptr = $fopen("audio_out.csv","w");
clk = 0;
RST_n = 0;
@(posedge clk);
@(negedge clk);
RST_n = 1;

end
  
always
	#10 clk = ~clk;

endmodule
