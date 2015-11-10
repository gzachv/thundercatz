/****************************************************************
 Module to implement the SPI master controller.
 Author : Thundercatz		HDL : System Verilog		 
 Student ID: 903 015 5247	
 Date : 11/09/2015 							
****************************************************************/ 

module SPI_mstr(done, rd_data, SCLK, SS_n, MOSI, MISO, wrt, cmd, clk, rst_n);

////////// Variable Declaration for interface ///////////////////
output logic done,		// Indicates the SPI transaction completed
			 SCLK,		// Serial Clock
			 SS_n,		// Active low slave select
			 MOSI;		// Master out slave in

output logic [15:0] rd_data;	// Data SPI mstr read from the slave

input wrt,				// Signal to SPI mstr to start a transaction
	  MISO,				// Master in, slave out
	  clk, rst_n;		// System clock and active low reset
input [15:0] cmd;		// The data the master will send

////////// Intermediate wire Declarations ///////////////////////
logic update,			// Signal to trigger clks to update
	  shift,			// Signal a shift in the master Shft reg 
	  rst_cnt,			// Reset the clk count, done count
	  set_done,			// Set the done signal
	  clr_done;			// Clear the done signal
logic [4:0] sclk_cnt,	// Counter for each posedge clk
			bit_cnt;	// Count each bit of a transaction
logic [15:0] shft_reg;	// Master shift reg

localparam DELAY = 5'h1E; // Clock count to get shift delay of
						  // 2 System cycles after posedge SCLK

/////////////////////// Bits Counter  ///////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		bit_cnt <= 5'b00000;	
	else if (rst_cnt)
		bit_cnt <= 5'b00000;
	else if (shift)
		bit_cnt <= bit_cnt + 1;
	else
		bit_cnt <= bit_cnt;
end

/////////////////////// Clock Counter  //////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		sclk_cnt <= 5'b11000;
	else if (rst_cnt)
		sclk_cnt <= 5'b11000;
	else if (update)
		sclk_cnt <= sclk_cnt - 1;
	else
		sclk_cnt <= sclk_cnt;
end

//////////////////////////// SCLK ///////////////////////////////
assign SCLK = sclk_cnt[4];

////////////////////// Infer Done Flop //////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		done <= 1'b0;
	else if (clr_done)
		done <= 1'b0;
	else if (set_done)
		done <= 1'b1;
	else
		done <= done;
end

////////////////// Infer Slave Select Flop //////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		SS_n <= 1'b1;
	else if (clr_done)
		SS_n <= 1'b0;
	else if (set_done)
		SS_n <= 1'b1;
	else
		SS_n <= SS_n;
end

//////////////////// Infer shfit reg Flop ///////////////////////
always_ff @(posedge clk) begin
	if (wrt)
		shft_reg <= cmd;
	else if (shift)
		shft_reg <= {shft_reg[14:0], MISO};
	else
		shft_reg <= shft_reg;
end

///////////////////////// Assign MOSI ///////////////////////////
assign MOSI = shft_reg[15];

/////////////////////// Assign rd_data //////////////////////////
assign rd_data = shft_reg;

///////////////////// State machine /////////////////////////////
typedef enum reg [1:0] {IDLE, SHIFTING, BACK_PORCH} state_t;
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
	update = 0;
	shift = 0;
	rst_cnt = 0;
	set_done = 0;
	clr_done = 0;
	nxt_state = IDLE;

	case (state)

		IDLE: begin
			rst_cnt = 1;
			if (wrt) begin
				update = 1;
				clr_done = 1;
				nxt_state = SHIFTING;
			end else begin
				nxt_state = IDLE;
			end
			end

		SHIFTING: 
			if (bit_cnt[4]) begin
				update = 1;
				nxt_state = BACK_PORCH;	
			end 
			else if(sclk_cnt == DELAY) begin
				shift = 1;
				update = 1;
				nxt_state = SHIFTING;
			end
			else begin
				update = 1;
				nxt_state = SHIFTING;
			end

		BACK_PORCH: 
			begin
				set_done = 1;
				nxt_state = IDLE;	
			end

		default:
			nxt_state = IDLE;
	endcase
end
endmodule
