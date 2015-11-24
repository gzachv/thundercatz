/****************************************************************
 Module to implement the Digital Core.
 Authors : ThunderCatz 		HDL : System Verilog		 
 Student ID: 903 015 5247	
 Date : 11/24/2015 							
****************************************************************/ 
module digitalCore(lft_out, rht_out,
		   POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME
		   lft_in, rht_in, valid, clk, rst_n);

////////// Variable Declaration for interface ///////////////////
output signed [15:0]	lft_out,
			rht_out;	// The equalized audio sample

input [11:0] 	POT_LP, POT_B1, POT_B2,
		POT_B3, POT_HP, VOLUME; // Pot Values

input signed [15:0]	lft_in,
			rht_in;		// Raw Aduio input

input valid;				// Valid signal from CODEC intf

input clk, rst_n;			// System clk and reset

////////// Intermediate wire Declarations ///////////////////////
wire	lft_slow_seq, lft_fast_seq,
	rht_slow_seq, rht_fast_seq;	// Sequencing signals from queues

wire [15:0] smplt_out

logic signed	lft_sum,
		rht_sum;		// Sum of scaled bands

/////////////////////// Queue instantiation /////////////////////
slowQueue iLftSlowQ (	.sequencing(lft_slow_seq), .smpl_out(), 
			.wrt_smpl(), .new_smpl(), 
			.clk(clk), .rst_n(rst_n));

fastQueue iLftFastQ (	.sequencing(lft_fast_seq), .smpl_out(), 
			.wrt_smpl(), .new_smpl(), 
			.clk(clk), .rst_n(rst_n));

slowQueue iRhtSlowQ (	.sequencing(rht_slow_seq), .smpl_out(), 
			.wrt_smpl(), .new_smpl(), 
			.clk(clk), .rst_n(rst_n));

fastQueue iRhtFastQ (	.sequencing(rht_fast_seq), .smpl_out(), 
			.wrt_smpl(), .new_smpl(), 
			.clk(clk), .rst_n(rst_n));

/////////////////////// FIR instantiation ///////////////////////
LP_FIR iLft_LP_FIR (.smpl_out(), .sequencing(lft_slow_seq), .smpl_in(), .clk(clk), .rst_n(rst_n));
B1_FIR iLft_B1_FIR (.smpl_out(), .sequencing(lft_slow_seq), .smpl_in(), .clk(clk), .rst_n(rst_n));
B2_FIR iLft_B2_FIR (.smpl_out(), .sequencing(lft_slow_seq), .smpl_in(), .clk(clk), .rst_n(rst_n));
B3_FIR iLft_B3_FIR (.smpl_out(), .sequencing(lft_fast_seq), .smpl_in(), .clk(clk), .rst_n(rst_n));
HP_FIR iLft_HP_FIR (.smpl_out(), .sequencing(lft_fast_seq), .smpl_in(), .clk(clk), .rst_n(rst_n));

LP_FIR iRht_LP_FIR (.smpl_out(), .sequencing(rht_slow_seq), .smpl_in(), .clk(clk), .rst_n(rst_n));
B1_FIR iRht_B1_FIR (.smpl_out(), .sequencing(rht_slow_seq), .smpl_in(), .clk(clk), .rst_n(rst_n));
B2_FIR iRht_B2_FIR (.smpl_out(), .sequencing(rht_slow_seq), .smpl_in(), .clk(clk), .rst_n(rst_n));
B3_FIR iRht_B3_FIR (.smpl_out(), .sequencing(rht_fast_seq), .smpl_in(), .clk(clk), .rst_n(rst_n));
HP_FIR iRht_HP_FIR (.smpl_out(), .sequencing(rht_fast_seq), .smpl_in(), .clk(clk), .rst_n(rst_n));

////////////////// Band Scale instantiation /////////////////////


endmodule
