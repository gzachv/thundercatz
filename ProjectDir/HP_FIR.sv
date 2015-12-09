/****************************************************************
 Module to implement the FIR engine for HP band.
 Authors : ThunderCatz 		HDL : System Verilog		 
 Date : 11/24/2015 							
****************************************************************/ 
module HP_FIR(lft_smpl_out, rht_smpl_out, sequencing, lft_smpl_in, rht_smpl_in, clk, rst_n);

////////// Variable Declaration for interface ///////////////////
output signed [15:0] lft_smpl_out;	// The FIR scaled sample (left)
output signed [15:0] rht_smpl_out;	// The FIR scaled sample (right)

input signed [15:0] lft_smpl_in;	// The input audio sample from the queue (left)
input signed [15:0] rht_smpl_in;	// The input audio sample from the queue (right)

input sequencing;			// Signals FIR calculation 
input clk, rst_n;			// System clk and reset

////////// Intermediate wire Declarations ///////////////////////
reg [9:0] index;			// Signal to index into ROM

wire signed [15:0] coeff;		// The FIR coefficient
wire signed [31:0] lft_product;		// Product of the coeff and sample (left)
wire signed [31:0] rht_product;		// Product of the coeff and sample (right)

logic signed [31:0] lft_accum;		// Acumulated FIR results (left)
logic signed [31:0] rht_accum;		// Acumulated FIR results (right)
logic delayed_seq;			// Sequencing signal delayed by one clk

/////////////////////// ROM instantiation ///////////////////////
ROM_HP iROM (.clk(clk), .addr(index), .dout(coeff));

/////////////////////// product assignment ///////////////////////
assign lft_product = (coeff*lft_smpl_in);
assign rht_product = (coeff*rht_smpl_in);

/////////////////////// Infer left accum flop ////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		lft_accum <= 32'h0000;
	else if (delayed_seq)
		lft_accum <= lft_accum + lft_product;
	else if (sequencing)
		lft_accum <= 32'h0000;
	else
		lft_accum <= lft_accum;
end

/////////////////////// Infer left accum flop ////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		rht_accum <= 32'h0000;
	else if (delayed_seq)
		rht_accum <= rht_accum + rht_product;
	else if (sequencing)
		rht_accum <= 32'h0000;
	else
		rht_accum <= rht_accum;
end

/////////////////////// Infer index flop ////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		index <= 10'h000;
	else if (delayed_seq)
		index <= (index + 1) % 1021;
	else if (sequencing)
		index <= 10'h000;
	else
		index <= index;
end

/////////////////////// smpl out assignment /////////////////////
assign lft_smpl_out = {lft_accum[30:15]};
assign rht_smpl_out = {rht_accum[30:15]};

//////////// State Machine for edge detection ///////////////////
// used two states to handle holding RSTn high for one cycle of LRCLK
typedef enum reg {RESET, EDGE} state_t;
state_t state, nxt_state;

// next state logic
always_ff@(posedge clk, negedge rst_n) begin
  if(!rst_n)
    state <= RESET;
  else
    state <= nxt_state;
end

// State machine output combinational logic
always_comb begin
  delayed_seq = 0;
  nxt_state = RESET;

  case(state)

    RESET: begin
      if(!rst_n)
	nxt_state = RESET;
      else if(sequencing) begin
	nxt_state = EDGE;
      end
    end

    EDGE: begin
      if(!rst_n)
	nxt_state = RESET;
      else if (!sequencing) begin
 	delayed_seq = 1;
	nxt_state = RESET;
      end else begin
	delayed_seq = 1;
	nxt_state = EDGE;
      end
    end

  endcase
end

endmodule
