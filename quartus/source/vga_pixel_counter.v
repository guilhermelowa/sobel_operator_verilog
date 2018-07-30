module vga_pixel_counter(
	input clock,
	input reset,
	input enable,

	output reg [19:0] read_address
);

parameter [19:0] max_pixels = 19'd307200;

always @ (posedge clock or negedge reset) begin
	if (reset == 1'b0) begin
		read_address <= 19'd0;		
	end else if (enable == 1'b1) begin
		read_address <= read_address + 1'b1;
		if (read_address == max_pixels - 1) begin
			read_address <= 19'd0;
		end
	end
end