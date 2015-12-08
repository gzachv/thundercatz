`include "tb_tasks.sv";
/****************************************************************
 Module to implement a 5 Channel Equalizer testbench.
 Author : Thundercatz			HDL : System Verilog		 	
 Date : 11/30/2015 							
****************************************************************/ 
module Equalizer_tb();
////////////////////////////
// Variable Declarations //
//////////////////////////

localparam EXPECTED_FREQ = 32;
localparam EXPECTED_AMP  = 3200;
// Enter as expected freq, amp from gen_audio script, remember to set analog.dat

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
wire signed [15:0] aout_lft,	// Left audio data
	    aout_rht;		// Right audio data
logic	RSTn;			// CODEC reset, active low

logic rst_n;
assign rst_n = RST_n;		// rst_n should be a synchronized version of RST_n

logic status;

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

runTests(EXPECTED_FREQ, EXPECTED_AMP);

$stop;

end

//////////////////////////////////////////
// Increment Clk		       //
////////////////////////////////////////
always
	#1 clk = ~clk;

///////////////////// Run Tests task ////////////////////////////
//	This task can find the frequency of the signals at     //
// aout_lft and aout_rht. The value given to runTests as       //
// params are the expected values of the frequency and         //
// amplitude. This is expected to be used by running gen_audio //
// to generate an audio input signal, setting analog.dat to    //
// only allow one channel. Then see if the value calculated is //
// equal to the given param.                                   //
/////////////////////////////////////////////////////////////////
task runTests (	input [15:0] expected_freq, input [15:0] expected_amp);

////////// Internal Variable Declarations ///////////////////////
integer fptr;		// File handle for writing output
logic [11:0] x;		// Counter for loops

logic [15:0]	lft_crossing,
		rht_crossing,
		lft_crossing2,
		rht_crossing2;	// Store the indecies of zero crossing
logic [1:0] 	lft_cross_cnt, 
		rht_cross_cnt;	// 
logic signed [15:0] lft_max, rht_max,
			lft_min, rht_min;
logic signed [15:0] lft_prev, rht_prev;
logic [15:0] lft_freq, rht_freq;

/////////////////// Open File for output ////////////////////////
fptr = $fopen("audio_out.csv","w");

/////////////////// Variable Declaration ////////////////////////
clk = 0;
RST_n = 0;
@(posedge clk);
@(negedge clk);
RST_n = 1;
lft_crossing = 0;
rht_crossing = 0;
lft_crossing2 = 0;
rht_crossing2 = 0;
lft_cross_cnt = 0;
rht_cross_cnt = 0;
lft_max = -3000;
rht_max = -3000;
lft_min = 3000;
rht_min = 3000;
lft_prev = 0;
rht_prev = 0;

lft_freq = 0;
rht_freq = 0;

//////////////// Wait for Queue to fill /////////////////////////
for (x = 0; x < 2045; x = x + 1) begin
	@(posedge LRCLK);
end

/////////////////// Read the freq and amp from data /////////////
for (x = 0; x < 2048; x = x + 1) begin
	@(posedge LRCLK);
	$fwrite( fptr,"%f,%f\n", aout_rht, aout_lft );

	if (aout_rht > rht_max) begin
		rht_max = aout_rht;
	end

	if (lft_prev[15] ^ aout_lft[15]) begin

		if (lft_cross_cnt == 0) begin
			lft_cross_cnt = lft_cross_cnt + 1;
			lft_crossing = x;
		end else if (lft_cross_cnt == 1) begin
			lft_cross_cnt = lft_cross_cnt + 1;
			lft_crossing2 = x;
		end
	end

	if (rht_prev[15] ^ aout_rht[15]) begin

		if (rht_cross_cnt == 0) begin
			rht_cross_cnt = rht_cross_cnt + 1;
			rht_crossing = x;
		end else if (rht_cross_cnt == 1) begin
			rht_cross_cnt = rht_cross_cnt + 1;
			rht_crossing2 = x;
		end
	end

	lft_prev = aout_lft;
	rht_prev = aout_rht;
	
end

// LRCLK period = 48.828 KHz
rht_freq = 1/((rht_crossing2 - rht_crossing) * 0.00002048005 * 2);
$display("Rht Freq = %d Hz, EXPECTED FREQ = %d Hz", rht_freq, expected_freq);
$display("Rht Amp  = %d Hz, EXPECTED AMP = %d Hz", rht_max, expected_amp);

//////////////// Test against expected values ///////////////////
testFreq(expected_freq, rht_freq);
testAmp(expected_amp, rht_max);

/////////////////// Close output file ///////////////////////////
$fclose(fptr);

$stop;

endtask

endmodule

