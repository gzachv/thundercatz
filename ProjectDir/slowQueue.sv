/****************************************************************
 Module to implement the circular queue opperating at 24.424kHz.
 Authors : ThunderCatz 		HDL : System Verilog		 
 Student ID: 903 015 5247	
 Date : 11/13/2015 							
****************************************************************/ 
module slowQueue(sequencing, smpl_out, isFull, wrt_smpl, new_smpl, clk, rst_n);

////////// Variable Declaration for interface ///////////////////
input clk, rst_n;		// system reset and clk
input [15:0] new_smpl;		// The newest sample from CODEC
input wrt_smpl;			// Triggers a new sample into queue and 
				//   reading out of the queue data

output reg [15:0] smpl_out;	// Data being read out
output logic sequencing; 	// High the entire time the 1021 samples
output logic isFull;		// Signal the queue is in a full state

////////// Intermediate wire Declarations ///////////////////////
reg[9:0]new_ptr,	// Pointer to the location new data should be added
	old_ptr,	// Pointer to the last relevant data location
	read_ptr,	// Pointer to loc to be read (starts at old goes old + 1020)
	end_ptr;	// Marks the end point of the valid data in queue
logic	qWr_en;		// Queue write enable, active high
logic	inc_ptr;	// Signal new ptr to increment

/////////////// Instantiate memory module ///////////////////////
dualPort1024x16 queue (	.clk(clk), .we(qWr_en), 
			.waddr(new_ptr), .raddr(read_ptr),
			.wdata(new_smpl), .rdata(smpl_out) );

/////////////////// Infer Queue full signal /////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
	isFull <= 0;
  else if (new_ptr == 1021)
	isFull <= 1;
  else 
	isFull <= isFull;
end

///////////// infer New pointer flop machine ////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
	new_ptr <= 10'h000;
  else if (inc_ptr)
	new_ptr <= new_ptr + 1;
  else 
	new_ptr <= new_ptr;
end

///////////// infer Read pointer flop machine ///////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
	read_ptr <= 10'h000;
  else if (inc_ptr)
	read_ptr <= old_ptr;
  else if (sequencing)
	read_ptr <= read_ptr + 1;
  else
	read_ptr <= read_ptr;
end

///////////// infer old pointer flop machine ////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
	old_ptr <= 10'h000;
  else if (isFull && inc_ptr)
	old_ptr <= old_ptr + 1;
  else
	old_ptr <= old_ptr;
end

assign end_ptr = (old_ptr + 1020) % 1024;

///////////////////// State machine /////////////////////////////
typedef enum reg {IDLE, TRANS} state_t;
state_t state, nxt_state;

///////////////////// State Flop Inference //////////////////////
always_ff @(posedge clk or negedge rst_n)
  if(!rst_n)
    state <= IDLE;
  else
    state <= nxt_state;

always_comb begin
  // Default all outputs //
  qWr_en = 0;
  sequencing = 0;
  inc_ptr = 0;
  nxt_state = IDLE;

  case(state)

    IDLE :
    begin
      if(wrt_smpl) begin
	qWr_en = 1;
	inc_ptr = 1;
        nxt_state = TRANS;
      end
    end

    TRANS : 
    begin
      if (read_ptr == end_ptr)
	nxt_state = IDLE;
      else begin
        sequencing = 1;
	nxt_state = TRANS;
      end
    end

  endcase
end

endmodule

