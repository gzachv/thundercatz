/****************************************************************
 Module to implement the pot sliders interface.
 Authors : ThunderCatz 		HDL : System Verilog		 
 Student ID: 903 015 5247	
 Date : 11/10/2015 							
****************************************************************/ 

module slide_intf ( POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME,
		    a2d_SS_n, SCLK, MOSI,
		    MISO, clk, rst_n );

////////// Variable Declaration for interface ///////////////////
output logic [11:0] POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME;
output logic a2d_SS_n, SCLK, MOSI;
input MISO, clk, rst_n;

////////// Intermediate wire Declarations ///////////////////////
logic strt_cnv, inc_chnnl;
logic [2:0] chnnl;
wire cnv_cmplt;
wire [11:0] res;
logic potLP_en, potB1_en, potB2_en, potB3_en, potHP_en, volume_en;  

/////////////////////////// A2D Instantiation ///////////////////
A2D_intf iA2D_intf ( .clk(clk), .rst_n(rst_n), 
		     .strt_cnv(strt_cnv), .chnnl(chnnl), 
		     .cnv_cmplt(cnv_cmplt), .res(res), 
		     .a2d_SS_n(a2d_SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));

///////////////////// Channel Counter ///////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		chnnl <= 3'b111;
	else if (chnnl == 3'b100 && inc_chnnl)
		chnnl <= 3'b111;
	else if (inc_chnnl)
		chnnl <= chnnl + 1;
	else
		chnnl <= chnnl;
end

////////////////// Infer Output flops ///////////////////////////
////////////////// POT_LP flop //////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		POT_LP <= 12'h000;
	else if (potLP_en)
		POT_LP <= res;
	else
		POT_LP <= POT_LP;
end

////////////////// POT_B1 flop //////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		POT_B1 <= 12'h000;
	else if (potB1_en)
		POT_B1 <= res;
	else
		POT_B1 <= POT_B1;
end

////////////////// POT_B2 flop //////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		POT_B2 <= 12'h000;
	else if (potB2_en)
		POT_B2 <= res;
	else
		POT_B2 <= POT_B2;
end

////////////////// POT_B3 flop //////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		POT_B3 <= 12'h000;
	else if (potB3_en)
		POT_B3 <= res;
	else
		POT_B3 <= POT_B3;
end

////////////////// POT_HP flop //////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		POT_HP <= 12'h000;
	else if (potHP_en)
		POT_HP <= res;
	else
		POT_HP <= POT_HP;
end

////////////////// Volume flop //////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		VOLUME <= 12'h000;
	else if (volume_en)
		VOLUME <= res;
	else
		VOLUME <= VOLUME;
end

///////////////////// band local params //////////////////////////////
localparam LP  = 3'b001;
localparam B1  = 3'b010;
localparam B2  = 3'b011;
localparam B3  = 3'b100;
localparam HP  = 3'b111;
localparam VOL = 3'b000;

///////////////////// State machine /////////////////////////////
typedef enum reg {IDLE, SAMPLE} state_t;
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
	potLP_en = 0;
	potB1_en = 0;
	potB2_en = 0;
	potB3_en = 0;
	potHP_en = 0;
	volume_en = 0;
	strt_cnv = 0;
	inc_chnnl = 0;
	nxt_state = IDLE;

	case (state)

		IDLE:
			if (!rst_n) begin
				nxt_state = IDLE;
			end else begin
				strt_cnv = 1;
				inc_chnnl = 1;
				nxt_state = SAMPLE;
			end

		SAMPLE:
			if (!rst_n)
				nxt_state = IDLE;
			else if (cnv_cmplt) begin
				case (chnnl)
					LP:  potLP_en = 1;
					B1:  potB1_en = 1;
					B2:  potB2_en = 1;
					B3:  potB3_en = 1;
					HP:  potHP_en = 1;
					VOL: volume_en = 1;
				endcase

				nxt_state = IDLE;
			end else
				nxt_state = SAMPLE;

		default:
			nxt_state = IDLE;
	endcase
end

endmodule
