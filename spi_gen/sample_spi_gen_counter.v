
module sample_spi_gen_counter(rsted_in, clk1_in, clk2_in, vd_out, hd_out, pixels_out);
	input rsted_in, clk1_in, clk2_in;
	output vd_out, hd_out, pixels_out;
	/* 
		clk1 is 1/4 period ahead of clk2. everything sync to rising-edge of clk2, 
		except HD sync to rising-edge of clk1. a line will be linelen clock long. 
		the HD-rising is at 1/4 clock before the fist pixel data. and the HD-falling 
		is 1/4 clock before the last pixel trailing edge. 
		before the first pixel in a line, it needs about 3 or 2 more cycles to 
		form the SAV sync code, plus 4 cycles for the sync code. same for the EAV code. 
		for frame/field sync, it requres the same amount of cycles to form the code. 
	 */
	
	reg rstd_state, rstd_last; // used to detect a rstd_in falling-edge
	reg vd_out, hd_out;
	reg [7:0] pixels_out;	// pixel value
	reg [29:0] counts;		// pixel count in a frame
	reg [29:0] counts_copy;
	reg [13:0] pix_count;
	reg [3:0] gap_count;
	reg [9:0] line_count;
	reg [3:0] state;
	
	initial begin
		rstd_state = 1'b0;
		vd_out = 1'b0;
		hd_out = 1'b0;
		pixels_out = 8'h80;
		counts = 30'b0;
		counts_copy = 30'b0;
		pix_count = 14'b0;
		gap_count = 4'b0;
		line_count = 10'b0;
		state = 4'b0;
	end
	
	// current value;   small frame testing;   DC value; small frame DC value
	parameter linelen  = 1280;
	parameter lines = 720;
	parameter gaplen = 4;
	parameter cntsmax = 30'h3fffffff;
	
	always @(posedge clk1_in)
	begin
		if ( rstd_state == 1'b1 )
			counts <= counts + 1;
		else
			counts <= 30'b0;
	end
	
	always @(posedge clk2_in)
	begin
		counts_copy <= counts;
	
		rstd_last <= rstd_state;
		if ( rstd_state == 1'b0 ) begin
			if ( rsted_in == 1'b1 && rstd_last == 1'b0 )
				rstd_state <= 1'b1;
			
			vd_out <= 1'b0;
			hd_out <= 1'b0;
			pixels_out <= 8'h80;
			counts_copy <= 30'b0;
			pix_count <= 14'b0;
			gap_count <= 4'b0;
			line_count <= 10'b0;
			state <= 4'b0;
		end else begin
			
			if ( state == 0 ) begin // begin
				vd_out <= 1'b1;
				state <= 4'b1;
			end else if ( state == 1 ) begin // gap
				pix_count <= pix_count + 1;
				if ( pix_count >= linelen ) begin
					state <= 4'h2;
					gap_count <= 4'b0;
					if (pixels_out == 8'hff) 
						pixels_out <= 8'h4; // avoid 0,1,2,3
					else
						pixels_out <= pixels_out + 1;
				end
			end else if ( state == 2 ) begin // gap
				gap_count <= gap_count + 1;
				if (gap_count >= gaplen) begin
				   line_count <= line_count + 1;
					if (line_count >= lines) begin
					   state <= 4'h3;
					end else begin
						state <= 4'h1;
						pix_count <= 14'b0;
					end
				end
			end else if ( state == 3 ) begin // out
				
				//if (counts_copy >= 30'h1800000) begin
				//	vd_out <= 1'b0;
				//	rstd_state <= 1'b0;
				//end else if (counts_copy >= 30'h0c00000)
				//	vd_out <= 1'b0;
				//else 
				//	vd_out <= 1'b1;
				vd_out <= 1'b0;
				pixels_out <= {1'b1, pixels_out[2:0], state};
				
				if ( rsted_in == 1'b0 && rstd_last == 1'b1 )
					rstd_state <= 1'b0;
			end

			//syncword <= {1'b1, fvh_fvh, fvh_p};
			//fvh_fvh <= {fvh_f, fvh_v, fvh_h};
			
		end // rst
	end
endmodule

