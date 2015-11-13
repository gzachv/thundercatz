//////////////////////////////////////////////////////////////////////
// CODEC interface written by Viswesh Periyasamy for ECE 551
//////////////////////////////////////////////////////////////////////

module codec_intf(clk, rst_n, LRCLK, SCLK, MCLK, RSTn, SDout, SDin, valid, lft_in, rht_in, lft_out, rht_out);

input  clk, rst_n, SDout;
input [15:0] lft_out, rht_out;

output LRCLK, SCLK, MCLK, RSTn, valid, SDin;
output [15:0] lft_in, rht_in;

reg    LRCLK, SCLK, MCLK, RSTn, SDin, valid;

// lrclk_cnt is used to scale the system clock to the desired frequency
reg [9:0] lrclk_cnt;
reg [10:0] rst_cnt; // handles holding RSTn high for one cycle of LRCLK

reg [15:0] lft_in, rht_in, lft_out, rht_out, shift_out, shift_in, lft_buff, rht_buff, hold_lft, hold_rht;

logic assert_reset, LRCLK_rise, SCLK_rise, LRCLK_fall, SCLK_fall, set_valid;

//////////////////////////////////////////////////////////////////////
// Following section used to handle different clock signals and RSTn
//////////////////////////////////////////////////////////////////////

// used two states to handle holding RSTn high for one cycle of LRCLK
typedef enum reg {RESET, CLOCK} state_t;
state_t state, nxt_state;

// next state logic
always_ff@(posedge clk, negedge rst_n) begin
  if(!rst_n)
    state <= RESET;
  else
    state <= nxt_state;
end

// LRCLK is used for all clocks, starts with all 1's except SCLK bit
// starts low and decrements so that LRCLK starts high 
always_ff@(posedge clk, negedge rst_n) begin
  if(!rst_n)
    lrclk_cnt <= 10'h200;
  else
    lrclk_cnt <= lrclk_cnt + 1;
end

// RSTn held during asynch reset as well as full LRCLK cycle
always_ff@(posedge clk, negedge rst_n) begin
  if(!rst_n)
    RSTn <= 0;
  else if(assert_reset)
    RSTn <= 0;
  else
    RSTn <= 1;
end

//////////////////////////////////////////////////////////////////////
// END SECTION
//////////////////////////////////////////////////////////////////////



//////////////////////////////////////////////////////////////////////
// Following section used to handle outgoing and incoming signals
// as well as shift registers and other signals
//////////////////////////////////////////////////////////////////////

// when valid is asserted, put all of lft_out into the left buffer
always_ff@(posedge clk, negedge rst_n) begin
  if(!rst_n)
    lft_buff <= 16'h0000;
  else if(set_valid)
    lft_buff <= lft_out;
end

// when valid is asserted, put all of rht_out into the right buffer
always_ff@(posedge clk, negedge rst_n) begin
  if(!rst_n)
    rht_buff <= 16'h0000;
  else if(set_valid)
    rht_buff <= rht_out;
end

// valid should be 1 as soon as set_valid is true and stay 1
// until SCLK falls again
always_ff@(posedge clk, negedge rst_n) begin
  if(!rst_n)
    valid <= 0;
  else if(set_valid)
    valid <= 1;
  else if(SCLK_fall)
    valid <= 0;
end

// on LRCLK rise, fill shift out reg with lft_buff
// on LRCLK fall, fill shift out reg with rht_buff
// otherwise, on each SCLK fall shift one bit at a time
always_ff@(posedge clk, negedge rst_n) begin
  if(!rst_n)
    shift_out <= 16'h0000;
  else if(LRCLK_rise)
    shift_out <= lft_buff;
  else if(LRCLK_fall) 
    shift_out <= rht_buff;
  else if(SCLK_fall)
    shift_out <= {shift_out[14:0], 1'b0};
end

// always shift in on rise of SCLK
// capturing full right input will happen automatically
always_ff@(posedge clk, negedge rst_n) begin
  if(!rst_n)
    shift_in <= 16'h0000;
  else if(SCLK_rise)
    shift_in <= {shift_in[14:0], SDout};
end
 
// capture full left input into a holding register
always_ff@(posedge clk, negedge rst_n) begin
  if(!rst_n)
    hold_lft <= 16'h0000;
  else if(LRCLK_fall)
    hold_lft <= shift_in;
end

// capture full left input into a holding register
always_ff@(posedge clk, negedge rst_n) begin
  if(!rst_n)
    hold_rht <= 16'h0000;
  else if(LRCLK_rise)
    hold_rht <= shift_in;
end
//////////////////////////////////////////////////////////////////////
// END SECTION
//////////////////////////////////////////////////////////////////////




//////////////////////////////////////////////////////////////////////
// Assign statements to decide when LRCLK/SCLK is rising falling
// as well as deciding what all clocks are
// as well as deciding when to set valid to true
// as well as assigning the outputs lft_in and rht_in
//////////////////////////////////////////////////////////////////////
assign LRCLK = lrclk_cnt[9]; // LRCLK gets MSB (clk / 2^10)
assign SCLK = lrclk_cnt[4]; // SCLK (clk / 2^5)
assign MCLK = lrclk_cnt[1]; // MCLK (clk / 2^2)
assign LRCLK_rise = (lrclk_cnt == 10'h1ff); // LRCLK is rising when lrclk_cnt goes from 0x1ff to 0x200
assign LRCLK_fall = (lrclk_cnt == 10'h3ff); // LRCLK is falling when lrclk_cnt goes from 0x3ff to 0x000
assign SCLK_rise = (lrclk_cnt[4:0] == 5'h0f); // SCLK is rising when lower 5 bits go from 0x0f to 0x10
assign SCLK_fall = (lrclk_cnt[4:0] == 5'h1f); // SCLK is falling when lower 5 bits go from 0x1f yo 0x00
assign set_valid = (lrclk_cnt == 10'h1ef); // set valid happens on rising of SCLK right before rising of LRCLK
assign SDin = shift_out[15]; // SDin always MSB of shift out register
assign lft_in = hold_lft; // lft_in gets the left holding register (only valid when valid is true)
assign rht_in = hold_rht; // rht_in gets the shift in register (only valid when valid is true)
//////////////////////////////////////////////////////////////////////
// END SECTION
//////////////////////////////////////////////////////////////////////




//////////////////////////////////////////////////////////////////////
// State machine used to hold RSTn for one clock cycle of LRCLK
//////////////////////////////////////////////////////////////////////
always_comb begin
  assert_reset = 1;
  nxt_state = RESET;
  case(state)

    RESET: begin
      if(!rst_n)
	nxt_state = RESET;
      else if(lrclk_cnt == 10'h1ff) 
	nxt_state = CLOCK;
    end

    CLOCK: begin
      assert_reset = 0;
      if(!rst_n)
	nxt_state = RESET;
      else
	nxt_state = CLOCK;
    end

  endcase
end
//////////////////////////////////////////////////////////////////////
// END SECTION
//////////////////////////////////////////////////////////////////////


endmodule

