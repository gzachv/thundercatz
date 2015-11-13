/****************************************************************
 Module to implement the pot sliders interface testbench.
 Authors : ThunderCatz 		HDL : System Verilog		 
 Student ID: 903 015 5247	
 Date : 11/10/2015 							
****************************************************************/ 

module A2D_intf_tb();

reg clk, rst_n;
reg [11:0] POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME;

reg  MISO;
wire MOSI, SCLK, SS_n;

// Instantiate DUT //
slide_intf iDUTSlideIntf( .POT_LP(POT_LP), .POT_B1(POT_B1), .POT_B2(POT_B2), 
			  .POT_B3(POT_B3), .POT_HP(POT_HP), .VOLUME(VOLUME),
		    	  .a2d_SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI),
		    	  .MISO(MISO), .clk(clk), .rst_n(rst_n) );

initial begin
  clk = 0;
  rst_n = 0;			// assert reset

  @(posedge clk);		// wait one clock cycle
  @(negedge clk) rst_n = 1;	// deassert reset on negative edge (typically good practice)
  MISO = 1;

end

always
  #5 clk = ~clk;

endmodule  

