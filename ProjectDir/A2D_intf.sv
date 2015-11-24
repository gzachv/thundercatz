/****************************************************************
 Module to implement the A2D interface.
 Authors : ThunderCatz 		HDL : System Verilog		 
 Student ID: 903 015 5247	
 Date : 11/10/2015 							
****************************************************************/ 

module A2D_intf(clk, rst_n, strt_cnv, chnnl, cnv_cmplt, 
				res, a2d_SS_n, SCLK, MOSI, MISO);

////////// Variable Declaration for interface ///////////////////
input clk, rst_n, 		// System clock and reset
	  strt_cnv,			// Signal conversion to start
	  MISO;				// Master in, slave out
input [2:0] chnnl;		// A2D channel 
output reg cnv_cmplt;	// Signal that conversion has completed
output [11:0] res;		// The resultant reading from the A2D
output a2d_SS_n,		// A2D serial select, active low 
	   SCLK, 			// Serial clock
	   MOSI;			// Master out, slave in


wire [15:0] cmd;		// Command signal to A2D
wire [15:0] rd_data;	// Read buffer
wire done;				// Signal done
logic wrt, set_cc;		// Sigal write and trigger conv_complt assert

///////////////////// SPI_mstr machine //////////////////////////
SPI_mstr iSPI(.clk(clk), .rst_n(rst_n), .wrt(wrt), .cmd(cmd),
	          .done(done), .rd_data(rd_data), .SS_n(a2d_SS_n), 
			  .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI));

///////////////////// State machine /////////////////////////////
typedef enum reg [1:0] {IDLE, TRANS, WAIT, READ} state_t;
state_t state, nxt_state;

///////////////////// State Flop Inference //////////////////////
always_ff @(posedge clk or negedge rst_n)
  if(!rst_n)
    state <= IDLE;
  else
    state <= nxt_state;

/////////////// Infer conv complete flop ////////////////////////
always_ff @(posedge clk or negedge rst_n)
    if(!rst_n)
		cnv_cmplt <= 1'b0;
   else if (strt_cnv)
		cnv_cmplt <= 1'b0;
   else if (set_cc)
    	cnv_cmplt <= 1'b1;

/////////////// Assign command and result ///////////////////////
assign cmd = {2'b00, chnnl, 11'h000};
assign res = {rd_data[11:0]};

always_comb begin
  // Default all outputs //
  wrt = 0;
  set_cc = 0;
  nxt_state = IDLE;

  case(state)

    IDLE : begin
      if(strt_cnv) begin
        wrt = 1;
        nxt_state = TRANS;
      end
    end

    TRANS : begin
      if(done)
			nxt_state = WAIT;
      else if (!done)
			nxt_state = TRANS;
    end

    WAIT : begin
      nxt_state = READ;
      wrt = 1;
    end

    READ : begin
      if(done) begin
        nxt_state = IDLE;
        set_cc = 1;
      end
      else if (!done)
			nxt_state = READ;
    end

  endcase
end

endmodule
