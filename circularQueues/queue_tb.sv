/****************************************************************
 Module to implement the pot sliders interface testbench.
 Authors : ThunderCatz 		HDL : System Verilog		 
 Student ID: 903 015 5247	
 Date : 11/10/2015 							
****************************************************************/ 

module queue_tb();

reg clk, rst_n;
reg [15:0] count;
reg wrt_smpl;

wire w_seq;
wire [15:0] w_smpl_out;

// Instantiate DUT //
slowQueue iDUT (.sequencing(w_seq), .smpl_out(w_smpl_out), 
		.wrt_smpl(wrt_smpl), .new_smpl(count), 
		.clk(clk), .rst_n(rst_n));

initial begin
  clk = 0;
  rst_n = 0;			// assert reset
  wrt_smpl = 0;
  count = 0;

  @(posedge clk);		// wait one clock cycle
  @(negedge clk) rst_n = 1;	// deassert reset on negative edge (typically good practice)
  
  for (count = 0; count < 1021; count = count + 1) begin
	wrt_smpl = 1;
	@(negedge w_seq);
  end

end

always
  #5 clk = ~clk;

endmodule  
