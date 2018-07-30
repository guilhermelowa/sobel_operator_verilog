/*
	This module controls the VGA output
	More precisely, it controls the vga memory. 
	Anything to be written to the screen has to be received as input here and 
		the pixels being output do the screen are read from here aswell.
*/

module vga_controller(
	input sys_clock,
	input vga_clock,
	input reset,

	input [31:0] write_reg, // 19:0 address, 23:20 data

	output out_vga_clock,
	output [3:0] pixel,
	output reg h_sync_signal,
	output reg v_sync_signal
);

assign pixel = sending_pixel ? out_pixel : 3'd0;

// Resolution
parameter [9:0] row_size = 10'd640;
parameter [8:0] column_size = 9'd480;

// H_Sync
parameter [5:0] h_front_porch = 6'd32;
parameter [6:0] hsync = 7'd80; // 32(fp) + 48
parameter [7:0] h_back_porch = 8'd192; // 32(fp) + 48(hsnc) + 112 (bp)

// V_Sync
parameter v_front_porch = 1'd1;
parameter [2:0] vsync = 3'd4; // 1(fp) + 3(vsync)
parameter [4:0] v_back_porch = 5'd29; // 1(fp) + 3(vsync) + 25 (bp)

// State machine states
parameter [1:0]
				PIXEL_VALID = 2'd1,
				H_SYNC_STATE = 2'd2,
				V_SYNC_STATE = 2'd3;

reg [1:0] state, next;
reg [9:0] row_counter;
reg [8:0] column_counter;

reg sync_clken;

// Memory Parameters
wire [19:0] wire_read_address;
reg sending_pixel;



// Row Pixels Counter
always @(posedge vga_clock or negedge sending_pixel) begin
	if (sending_pixel == 1'b0) begin
		// reset
		row_counter <= 10'd0;
	end
	else  begin
		row_counter <= row_counter + 1'b1;
	end
end

// Sync_Counter
always @(posedge vga_clock negedge sync_clken) begin
	if (sync_clken == 1'b0;) begin
		// reset
		sync_counter <= 8'd0;
	end
	else begin
		sync_counter <= sync_counter + 1'b1;
	end
end


// State machine
always @(posedge vga_clock or negedge reset) begin
	if (reset == 1'b0) begin
		// reset
		state <= PIXEL_VALID;
	end
	else begin
		state <= next;
	end
end

always @ (*) begin
	h_sync_signal = 1'b1;
	v_sync_signal = 1'b1;
	sync_clken = 1'b0;
	case (state)
		PIXEL_VALID: begin
			sending_pixel = 1'b1;
			sync_clken = 1'b0;
			if (row_counter == row_size -1)begin
				next = H_SYNC_STATE;
				sending_pixel = 1'b0;
			end 
		end
		H_SYNC_STATE: begin
			sending_pixel = 1'b0;
			sync_clken = 1'b1;
			if (sync_counter > h_front_porch -1 && sync_counter < hsync - 1) begin
				h_sync_signal = 1'b0;
			end
			if (sync_counter == h_back_porch - 1) begin
				if (column_counter == column_size - 1) begin
					next = V_SYNC_STATE;
				end
				else begin
					next = PIXEL_VALID;
				end 
			end
		end
		V_SYNC_STATE: begin
			sending_pixel = 1'b0;
			sync_clken = 1'b1;
			if (sync_counter > v_front_porch - 1 && sync_counter < vsync - 1) begin
				v_sync_signal = 1'b0;
			end
			if (sync_counter == v_back_porch - 1) begin
				next = PIXEL_VALID;
			end
		end
	endcase
end

vga_pixel_counter vga_pc(
	.clock(vga_clock),
	.reset(reset),
	.enable(sending_pixel),
	.read_address(wire_read_address)
);


// Instantiate VGA memory here
vga_mem	vga_mem_inst (
	.data ( write_reg[23:20]),
	.rdaddress ( wire_read_address),
	.rdclock ( ~vga_clock ),
	.wraddress ( write_reg[19:0]),
	.wrclock ( vga_clock),
	.wren ( vga_clock),
	.q ( out_pixel)
);


endmodule