
module sample_spi_gen_counter(rsted_in, clk1_in, sel_in, clk2_in, ss_out, sc_out, sd_out, done_out);
	input rsted_in, clk1_in, clk2_in, sel_in;
	output ss_out, sc_out, sd_out, done_out;
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
	reg ss_out, sd_out;
	wire sc_out;
	reg done_out;
	reg [7:0] pixels_out;	// pixel value
	reg [29:0] counts;		// pixel count in a frame
	reg [29:0] counts_copy;
	reg [13:0] pix_count;
	reg [3:0] gap_count;
	reg [9:0] line_count;
	reg [3:0] state;
	reg [15:0] pixel_word;
	reg [15:0] pixel_word_shift;
	reg sc_mask;
	reg sel_short;
	
	initial begin
		rstd_state = 1'b0;
		ss_out = 1'b1;
		sd_out = 1'b0;
		counts = 30'b0;
		counts_copy = 30'b0;
		pix_count = 14'b0;
		gap_count = 4'b0;
		line_count = 10'b0;
		state = 4'b0;
		pixel_word = 16'b0;
		pixel_word_shift = 16'b0;
		sc_mask = 1'b0;
		sel_short = 1'b0;
		done_out = 1'b1;
	end
	
	// linelen 1280 by lines 720 is 921600 pixels. will do 720 * 2 lines or 1.8432M bits. 
	parameter linelen  = 16; // word size 16 bits
	parameter lines = 512;   // 512 words, or 1024 bytes
	parameter gaplen = 4;
	
	always @(posedge clk1_in)
	begin
		if ( rstd_state == 1'b1 )
			counts <= counts + 1;
		else
			counts <= 30'b0;
	end
	
	assign sc_out = (~clk2_in & sc_mask);
	
	always @(posedge clk2_in)
	begin
		counts_copy <= counts;
		if (sel_in == 1'b0 )
			sel_short = 1'b1;
	
		rstd_last <= rstd_state;
		if ( rstd_state == 1'b0 ) begin
			if ( rsted_in == 1'b1 && rstd_last == 1'b0 )
				rstd_state <= 1'b1;
			
			ss_out <= 1'b1;
			sd_out <= 1'b0;
			counts_copy <= 30'b0;
			pix_count <= 14'b0;
			gap_count <= 4'b0;
			line_count <= 10'b0;
			state <= 4'b0;
			pixel_word <= 16'b0;
			pixel_word_shift <= 16'b0;
			sc_mask = 1'b0;
			
		end else begin
			
			if ( state == 0 ) begin // begin
				ss_out <= 1'b1;
				state <= 4'h8; 
				pixel_word <= 16'b1; // data init to 1
				sc_mask <= 1'b0;
				done_out <= 1'b0;
			end else if ( state == 8 ) begin // pre-1 1/2
				pixel_word_shift <= pixel_word;
				state <= 4'h9;
			end else if ( state == 9 ) begin // pre-1 2/2
				pixel_word_shift <= (pixel_word_shift << 1);
				//sd_out <= pixel_word_shift[15];
				sd_out <= 1'b1; // send first bit 1
				ss_out <= 1'b0;
				sc_mask <= 1'b1;
				state <= 4'h1;
				
			end else if ( state == 1 ) begin // line
				pix_count <= pix_count + 1;
				
				pixel_word_shift <= (pixel_word_shift << 1);
				sd_out <= pixel_word_shift[15];
				
				if ( pix_count == linelen - 1 ) begin // last bit in a word
					pixel_word <= pixel_word + 1; // new data
					sc_mask <= 1'b0;
				end else if ( pix_count >= linelen ) begin // extend 1 bit time
					pixel_word_shift <= pixel_word; // load new data to shifter
					state <= 4'h2;
					gap_count <= 4'b0;
					ss_out <= 1'b1;
					sc_mask <= 1'b0;
				end
			end else if ( state == 2 ) begin // gap
				gap_count <= gap_count + 1;
				if (gaplen < 1 || gap_count >= gaplen - 1) begin
				   line_count <= line_count + 1;
					if ( sel_short == 1'b1 && line_count >= lines/2 ) begin
						sel_short <= 1'b0;
						state <= 4'h3;
					end else if (lines < 1 || line_count >= lines - 1) begin // finished the last line
					   state <= 4'h3;
					end else begin // next line
						pixel_word_shift <= (pixel_word_shift << 1);
						sd_out <= pixel_word_shift[15];
						ss_out <= 1'b0;
						state <= 4'h1;
						pix_count <= 14'b0;
						sc_mask <= 1'b1;
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
				ss_out <= 1'b1;
				sc_mask <= 1'b0;
				pixels_out <= {1'b1, pixels_out[2:0], state};
				done_out <= 1'b1;
				
				if ( rsted_in == 1'b0 && rstd_last == 1'b1 )
					rstd_state <= 1'b0;
			end

			//syncword <= {1'b1, fvh_fvh, fvh_p};
			//fvh_fvh <= {fvh_f, fvh_v, fvh_h};
			
		end // rst
	end
endmodule

