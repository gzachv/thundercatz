module LED_intf(LEDs, volume);

input [11:0] volume;
output [7:0] LEDs;

logic [7:0] vol_scaled;
// REMEMBER TO WRITE "set_dont_touch [find design LED_intf*]" IN SYNTHESIS SCRIPT!!!
  // synopsys translate_off

assign vol_scaled = volume / 16;

assign LEDs =   ((vol_scaled > 49) && (vol_scaled < 100))  ?    8'b00011000 :
		((vol_scaled > 99) && (vol_scaled < 150))  ?    8'b00111100 :
		((vol_scaled > 149) && (vol_scaled < 200)) ?    8'b01111110 :
		(vol_scaled > 199)  			   ?    8'b11111111 :
								8'b00000000;
  // synopsys translate_on
endmodule
