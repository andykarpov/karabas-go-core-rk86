module hvsync_generator(clk, vga_h_sync, vga_v_sync, vga_blank, inDisplayArea, CounterX, CounterY);
input clk;
output vga_h_sync, vga_v_sync, vga_blank;
output inDisplayArea;
output [10:0] CounterX;
output [10:0] CounterY;

//// VGA mode 800x600x60Hz /////
// Modeline " 800x 600@60Hz"  40.00  800  840  968 1056  600  601  605  628 +HSync +VSync

integer width = 11'd800; // screen width (visible)
integer height = 11'd600; // screen heigh (visible)
integer count_dots = 11'd1056; // count of dots in line
integer count_lines = 11'd628; // count of lines

integer h_front_porch = 11'd40; // count of dots before sync pulse
integer h_sync_pulse = 11'd128; // duration of sync pulse
integer h_back_porch = 11'd88; // count of dots after sync pulse

integer v_front_porch = 11'd1; // count of lines before sync pulse
integer v_sync_pulse = 11'd4; // duration of sync pulse
integer v_back_porch = 11'd23; // count of lines after sync pulse

//////////////////////////////////////////////////

reg [10:0] CounterX;
reg [10:0] CounterY;
wire CounterXmaxed = (CounterX==count_dots);
wire CounterYmaxed = (CounterY==count_lines);

always @(posedge clk)
	if(CounterXmaxed)
		CounterX <= 0;
	else
		CounterX <= CounterX + 1;

always @(posedge clk)
	if(CounterXmaxed) 
	begin
		if (CounterYmaxed)
			CounterY <= 0;
		else
			CounterY <= CounterY + 1;
	end

reg	vga_HS, vga_VS, blank;

always @(posedge clk)
begin
	vga_HS <= (CounterX >= (width+h_front_porch) && CounterX < (width+h_front_porch+h_sync_pulse)); 
	vga_VS <= (CounterY >= (height+v_front_porch) && CounterY < (height+v_front_porch+v_sync_pulse)); 
	blank <= CounterX >= width | CounterY >= height;
end

assign inDisplayArea = (CounterX < width && CounterY < height) ? 1'b1: 1'b0;	
assign vga_h_sync = vga_HS; // positive polarization
assign vga_v_sync = vga_VS; // positive polarization
assign vga_blank = blank;

endmodule
