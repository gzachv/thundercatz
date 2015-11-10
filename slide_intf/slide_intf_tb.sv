/****************************************************************
 Module to implement the pot sliders interface testbench.
 Authors : ThunderCatz 		HDL : System Verilog		 
 Student ID: 903 015 5247	
 Date : 11/10/2015 							
****************************************************************/ 


module A2D_intf_tb();

reg clk, rst_n, strt_cnv;
reg [2:0] chnnl;

wire MISO, MOSI, SCLK, SS_n, cnv_cmplt;
wire[11:0] res;

// Instantiate DUT //
A2D_intf iDUTA2DIntf(.clk(clk), .rst_n(rst_n), .strt_cnv(strt_cnv), .chnnl(chnnl), .cnv_cmplt(cnv_cmplt), .res(res), .a2d_SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI));
ADC128S iDUTADC(.clk(clk),.rst_n(rst_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI));

initial begin
  clk = 0;
  rst_n = 0;				// assert reset
  strt_cnv = 0;			
  chnnl = 3'b000;


  @(posedge clk);			// wait one clock cycle
  @(negedge clk) rst_n = 1;	        // deassert reset on negative edge (typically good practice)
  repeat (2)@(posedge clk); 
  strt_cnv = 1;	
  repeat (2)@(posedge clk); 
  strt_cnv = 0;

  #12000;

  chnnl = 3'b001;
  strt_cnv = 1;	
  repeat (2)@(posedge clk); 
  strt_cnv = 0;
end

always
  #5 clk = ~clk;

endmodule  

