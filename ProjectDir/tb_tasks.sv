///////////////////// Test Freq task ////////////////////////////
//	This takes the actual and expected values of frequency //
// and checks if they are within 5 percent of eachother, while //
// printing relevant information about the test. The values    //
// given to testFreq as params are the expected and actual     //
// values of the frequency.                                    //
/////////////////////////////////////////////////////////////////
task testFreq(input signed [15:0] expected_freq, actual_freq);

////////// Internal Variable Declarations ///////////////////////
logic signed [15:0] freq_diff;

freq_diff = (expected_freq - actual_freq);
if (freq_diff < 0) 
	freq_diff = -freq_diff;

if (freq_diff < 0.05*expected_freq) begin
	$display("************PASSSING FREQUENCY*************");
        $display("Percent Error Frequency = %f percent", (100*freq_diff)/expected_freq);
end
else begin
	$display("*****FAIL*******FREQUENCYFAIL*******FAIL******");
	$display("Percent Error Frequency = %f percent", (100*freq_diff)/expected_freq);
end
endtask


///////////////////// Test Amp task /////////////////////////////
//	This takes the actual and expected values of amplitude //
// and checks if they are within 5 percent of eachother, while //
// printing relevant information about the test. The values    //
// given to testAmp as params are the expected and actual      //
// values of the amplitude.                                    //
/////////////////////////////////////////////////////////////////
task testAmp(input signed [15:0] expected_amp, actual_amp);

////////// Internal Variable Declarations ///////////////////////
logic signed [15:0] amp_diff;

amp_diff = (expected_amp - actual_amp);
if (amp_diff < 0)
	amp_diff = -amp_diff;

if (amp_diff < 0.05*expected_amp) begin
	$display("************PASSSING AMPLITUDE*************");
	$display("Percent Error Amplitude = %f percent ", (100*amp_diff)/expected_amp);

end
else begin
	$display("*****FAIL*******AMPLITUDEFAIL*******FAIL******");
	$display("Percent Error Amplitude = %f percent ", (100*amp_diff)/expected_amp);

end
endtask
