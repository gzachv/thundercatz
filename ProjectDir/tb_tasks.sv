/****************************************************************
 Module to implement tasks used in testbench.
 Author : Thundercatz			HDL : System Verilog		 
 Date : 11/30/2015 							
****************************************************************/ 

///////////////////// Find Freq task ////////////////////////////
//	This task can find the frequency of the signals at     //
// aout_lft and aout_rht. The value given to findFreq as a     //
// param is the expected value of the freq. This is expected   //
// to be used by running gen_audio to generate an audio input  //
// signal, setting analog.dat to only allow one channel. Then, //
// see if the value calculated is equal to the given param.    //
/////////////////////////////////////////////////////////////////
task findFreq (	input expected_freq, input reg clk, RST_n, LRCLK,
		input [15:0] aout_lft, aout_rht);

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
logic [15:0] freq_diff;

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

/////////////////// Read the freq from data ////////////////////////
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

// 1024 samples per LRCLK period, 2ns per clk cycle, 
// taken from consequtive cross so calculating 1/2 period (Hence 2 at end)
rht_freq = 1/((rht_crossing2 - rht_crossing) * 1024 * 0.000000002 * 2);
$display("Rht Freq = %dHz, EXPECTED FREQ = %d", rht_freq, expected_freq);

freq_diff = (expected_freq - rht_freq);
if (freq_diff < 0) 
	freq_diff = -freq_diff;

if (freq_diff < 0.1*expected_freq)
	$display("************PASS*************");
else
	$display("*****FAIL*******FAIL*******FAIL******");

/////////////////// Close output file ///////////////////////////
$fclose(fptr);

$stop;

endtask
