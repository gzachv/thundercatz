/****************************************************************
 Module to implement the Digital Core.
 Authors : ThunderCatz 		HDL : System Verilog		 
 Student ID: 903 015 5247	
 Date : 11/24/2015 							
****************************************************************/ 
module digitalCore( lft_out, rht_out, lftQ_full, rhtQ_full,
		    POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME,
		    lft_in, rht_in, valid, clk, rst_n );

////////// Variable Declaration for interface ///////////////////
output signed [15:0]	lft_out,
			rht_out;	// The equalized audio sample

output lftQ_full, rhtQ_full;		// Signal the queue is full	

input [11:0] 	POT_LP, POT_B1, POT_B2,
		POT_B3, POT_HP, VOLUME; // Pot Values

input signed [15:0]	lft_in,
			rht_in;		// Raw Aduio input

input valid;				// Valid signal from CODEC intf

input clk, rst_n;			// System clk and reset

////////// Intermediate wire Declarations ///////////////////////
wire	lft_slow_seq, lft_fast_seq,
	rht_slow_seq, rht_fast_seq;	// Sequencing signals from queues

wire signed [15:0]	lft_slow_smpl_out, lft_fast_smpl_out,
			rht_slow_smpl_out, rht_fast_smpl_out;	// Queue sample outs

logic signed [15:0] lft_LP_smpl_out, lft_B1_smpl_out,
		    lft_B2_smpl_out, lft_B3_smpl_out, lft_HP_smpl_out,
		    rht_LP_smpl_out, rht_B1_smpl_out,
		    rht_B2_smpl_out, rht_B3_smpl_out, rht_HP_smpl_out;	// FIR sample outs

logic signed [15:0] lft_LP_scaled, lft_B1_scaled,
		    lft_B2_scaled, lft_B3_scaled, lft_HP_scaled,
		    rht_LP_scaled, rht_B1_scaled,
		    rht_B2_scaled, rht_B3_scaled, rht_HP_scaled;	// Scaled samples

logic signed [28:0] lft_sum_vol, rht_sum_vol;	// Sum of scaled bands, scaled by volume
logic signed [12:0] sign_vol;			// A signed version of the volume pot val

/////////////////////// Queue instantiation /////////////////////
slowQueue iLftSlowQ (	.sequencing(lft_slow_seq), .smpl_out(lft_slow_smpl_out), .isFull(lftQ_full), 
			.wrt_smpl(valid), .new_smpl(lft_in), 
			.clk(clk), .rst_n(rst_n) );

fastQueue iLftFastQ (	.sequencing(lft_fast_seq), .smpl_out(lft_fast_smpl_out), 
			.wrt_smpl(valid), .new_smpl(lft_in), 
			.clk(clk), .rst_n(rst_n) );

slowQueue iRhtSlowQ (	.sequencing(rht_slow_seq), .smpl_out(rht_slow_smpl_out), .isFull(rhtQ_full),
			.wrt_smpl(valid), .new_smpl(rht_in), 
			.clk(clk), .rst_n(rst_n) );

fastQueue iRhtFastQ (	.sequencing(rht_fast_seq), .smpl_out(rht_fast_smpl_out), 
			.wrt_smpl(valid), .new_smpl(rht_in), 
			.clk(clk), .rst_n(rst_n) );

/////////////////////// FIR instantiation ///////////////////////
LP_FIR iLP_FIR (.lft_smpl_out(lft_LP_smpl_out), .rht_smpl_out(rht_LP_smpl_out), .sequencing(lft_slow_seq | rht_slow_seq), .lft_smpl_in(lft_slow_smpl_out), .rht_smpl_in(rht_slow_smpl_out), .clk(clk), .rst_n(rst_n));
B1_FIR iB1_FIR (.lft_smpl_out(lft_B1_smpl_out), .rht_smpl_out(rht_B1_smpl_out), .sequencing(lft_slow_seq | rht_slow_seq), .lft_smpl_in(lft_slow_smpl_out), .rht_smpl_in(rht_slow_smpl_out), .clk(clk), .rst_n(rst_n));
B2_FIR iB2_FIR (.lft_smpl_out(lft_B2_smpl_out), .rht_smpl_out(rht_B2_smpl_out), .sequencing(lft_slow_seq | rht_slow_seq), .lft_smpl_in(lft_slow_smpl_out), .rht_smpl_in(rht_slow_smpl_out), .clk(clk), .rst_n(rst_n));
B3_FIR iB3_FIR (.lft_smpl_out(lft_B3_smpl_out), .rht_smpl_out(rht_B3_smpl_out), .sequencing(lft_fast_seq | rht_fast_seq), .lft_smpl_in(lft_fast_smpl_out), .rht_smpl_in(rht_fast_smpl_out), .clk(clk), .rst_n(rst_n));
HP_FIR iHP_FIR (.lft_smpl_out(lft_HP_smpl_out), .rht_smpl_out(rht_HP_smpl_out), .sequencing(lft_fast_seq | rht_fast_seq), .lft_smpl_in(lft_fast_smpl_out), .rht_smpl_in(rht_fast_smpl_out), .clk(clk), .rst_n(rst_n));

////////////////// Band Scale instantiation /////////////////////
band_scale lft_LP_BS (.scaled(lft_LP_scaled), .POT(POT_LP), .audio(lft_LP_smpl_out));
band_scale lft_B1_BS (.scaled(lft_B1_scaled), .POT(POT_B1), .audio(lft_B1_smpl_out));
band_scale lft_B2_BS (.scaled(lft_B2_scaled), .POT(POT_B2), .audio(lft_B2_smpl_out));
band_scale lft_B3_BS (.scaled(lft_B3_scaled), .POT(POT_B3), .audio(lft_B3_smpl_out));
band_scale lft_HP_BS (.scaled(lft_HP_scaled), .POT(POT_HP), .audio(lft_HP_smpl_out));

band_scale rht_LP_BS (.scaled(rht_LP_scaled), .POT(POT_LP), .audio(rht_LP_smpl_out));
band_scale rht_B1_BS (.scaled(rht_B1_scaled), .POT(POT_B1), .audio(rht_B1_smpl_out));
band_scale rht_B2_BS (.scaled(rht_B2_scaled), .POT(POT_B2), .audio(rht_B2_smpl_out));
band_scale rht_B3_BS (.scaled(rht_B3_scaled), .POT(POT_B3), .audio(rht_B3_smpl_out));
band_scale rht_HP_BS (.scaled(rht_HP_scaled), .POT(POT_HP), .audio(rht_HP_smpl_out));

//////////// Sum bands and scale by Volume //////////////////////
assign sign_vol = {1'b0, VOLUME};
assign lft_sum_vol = sign_vol * (lft_LP_scaled + lft_B1_scaled + lft_B2_scaled + 
			lft_B3_scaled + lft_HP_scaled);
assign rht_sum_vol = sign_vol * (rht_LP_scaled + rht_B1_scaled + rht_B2_scaled +
			rht_B3_scaled + rht_HP_scaled);

assign lft_out = {lft_sum_vol[27:12]};
assign rht_out = {rht_sum_vol[27:12]};

endmodule

