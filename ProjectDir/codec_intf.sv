/****************************************************************
 Module to implement the clock initializations for the CODEC.
 Author : Thundercatz			HDL : System Verilog		 	
 Date : 10/09/2015 							
****************************************************************/ 

module codec_intf ( lft_in, rht_in, valid, 
		    LRCLK, SCLK, MCLK, RSTn, SDin, 
	            SDout, lft_out, rht_out, clk, rst_n );

////////// Variable Declaration for interface ///////////////////
output logic [15:0] lft_in;
output logic [15:0] rht_in;
output logic 	valid,
		LRCLK,		// CODEC clock signals
		SCLK,
		MCLK,
		RSTn,		// CODEC reset
		SDin;		// Serial data to CODEC, audio data

input SDout;			// Serial data from CODEC
input [15:0] lft_out;
input [15:0] rht_out;
input clk, rst_n;		// System clock and active low reset

////////// Intermediate wire Declarations ///////////////////////
logic ready,			// Signal to the CODEC clocks are ready
      update;			// Signal to trigger clks to update
logic [9:0] clk_cnt;		// Counter for each posedge clk

logic [15:0] out_shft_reg;	// The outgoing shift register
logic [15:0] in_shft_reg;	// The incoming shift register

logic [15:0] lft,rht;		// Left and right channel buffers

logic	LRCLK_rising,	
	LRCLK_falling,
	SCLK_rising,
	SCLK_falling,
	set_valid;		// Signals valid signal assertion

/////////////////////// Clock Counter  //////////////////////////
always @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		clk_cnt <= 10'h200;
	else if (update)
		clk_cnt <= clk_cnt + 1;
	else
		clk_cnt <= clk_cnt;
end

/////////////////////////////////////////////////////////////////
//////////////////////// CODEC Clocks  //////////////////////////
/////////////////////////////////////////////////////////////////
assign 	LRCLK	= clk_cnt[9];
assign 	SCLK	= clk_cnt[4];
assign 	MCLK	= clk_cnt[1];

assign LRCLK_rising  = (clk_cnt == 10'h1ff);
assign LRCLK_falling = (clk_cnt == 10'h3ff);
assign SCLK_rising   = (clk_cnt & 10'h1f) == 5'h0f;
assign SCLK_falling  = (clk_cnt & 10'h1f) == 5'hff;

/////////// Infer CODEC Reset Flop  /////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		RSTn <= 1'b0;
	else if(ready)
		RSTn <= 1'b1;
	else
		RSTn <= RSTn;
end

///////////////////// Infer Valid Flop  /////////////////////////
always @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		valid <= 1'b0;
	else if (set_valid)
		valid <= 1'b1;
	else
		valid <= 1'b0;
end

assign set_valid = ready & (clk_cnt == 10'h1fe);

////////////// Infer lft_out, rht_out Buffers  ////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		lft <= 16'h0000;
		rht <= 16'h0000; 
	end else if (set_valid) begin
		lft <= lft_out;
		rht <= rht_out;
	end
	else begin
		lft <= lft;
		rht <= rht;
	end	
end

///////////////// Infer Outgoing shift reg //////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		out_shft_reg <= 16'h0000;
	else if (LRCLK_rising)
		out_shft_reg <= lft;
	else if (LRCLK_falling)
		out_shft_reg <= rht;
	else if (SCLK_falling)
		out_shft_reg <= {out_shft_reg[14:0], 1'b0};
	else
		out_shft_reg <= out_shft_reg;
end

///////////////////////// Assign SDin ///////////////////////////
assign SDin = out_shft_reg[15];

///////////////// Infer Incoming shift reg //////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		in_shft_reg <= 16'h0000;
	else if (SCLK_rising)
		in_shft_reg <= {in_shft_reg[14:0], SDout};
	else
		in_shft_reg <= in_shft_reg;
end

////////////////// Infer Output flops ///////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		lft_in <= 16'h0000;
	else if (ready && LRCLK)
		lft_in <= in_shft_reg;
	else
		lft_in <= lft_in;
end

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		rht_in <= 16'h0000;
	else if (ready && ~LRCLK)
		rht_in <= in_shft_reg;
	else
		rht_in <= in_shft_reg;
end

///////////////////// State machine /////////////////////////////
typedef enum reg [1:0] {IDLE, START, WARM, RUN} state_t;
state_t state, nxt_state;

////////////////// Infer state flops ////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;
end

always_comb begin
	// Default outputs //
	ready = 0;
	update = 0;
	nxt_state = IDLE;

	case (state)

		IDLE:
			if (rst_n) begin
				update = 1;
				nxt_state = START;
			end else begin
				update = 0;
				nxt_state = IDLE;
			end

		START: 
			if (!rst_n)
				nxt_state = IDLE;
			else if (!LRCLK) begin
				update = 1;
				nxt_state = WARM;	
			end
			else begin
				update = 1;
				nxt_state = START;
			end

		WARM: 
			if (!rst_n)
				nxt_state = IDLE;
			else if (LRCLK) begin
				ready = 1;
				update = 1;
				nxt_state = RUN;	
			end
			else begin
				update = 1;
				nxt_state = WARM;
			end

		RUN: 
			if (!rst_n)
				nxt_state = IDLE;
			else begin
				update = 1;
				ready = 1;
				nxt_state = RUN;
			end

		default:
			nxt_state = IDLE;
	endcase
end
endmodule

