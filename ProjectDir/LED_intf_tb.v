module LED_intf_tb();

reg [11:0] volume;

wire [7:0] LEDs;

LED_intf iLED(.LEDs(LEDs), .volume(volume));

initial begin
  volume = 12'h000;

  #10;
  volume = 12'h333;

  #10;
  volume = 12'h666;
  #10;
  volume = 12'h999;
  #10;
  volume = 12'hccc;
  #10;
  volume = 12'hfff;
  #10;
  $stop;
end

endmodule
  
