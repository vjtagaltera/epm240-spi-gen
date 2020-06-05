
module sample_vh9x6_counter(rsted, clk1, clk2, vd, hd, pixels);
	input rsted, clk1, clk2;
	output vd, hd, pixels;
	/* 
		clk1 is 1/4 period ahead of clk2. everything sync to rising-edge of clk2, 
		except HD sync to rising-edge of clk1. a line will be linelen clock long. 
		the HD-rising is at 1/4 clock before the fist pixel data. and the HD-falling 
		is 1/4 clock before the last pixel trailing edge. 
		before the first pixel in a line, it needs about 3 or 2 more cycles to 
		form the SAV sync code, plus 4 cycles for the sync code. same for the EAV code. 
		for frame/field sync, it requres the same amount of cycles to form the code. 
	 */
	
	reg rstd_state, rstd_last; // used to detect a rstd falling-edge
	reg vd, hd;
	reg [7:0] pixels;	// pixel value
	reg [29:0] counts;	// pixel count in a frame
	reg [0:0]  fieldcnt;
	reg [29:0] linecnt;
	reg [29:0] pixcnt;
	reg linestart_detected;
	reg fieldstart_detected;
	reg [7:0]  syncword;
	reg fvh_f, fvh_v, fvh_h;
	reg [3:0] fvh_p;
	reg [2:0] fvh_fvh;
	
	initial begin
		rstd_state = 1'b0;
		vd = 1'b0;
		hd = 1'b0;
		pixels = 8'h80;
		counts = 30'b0;
		fieldcnt = 1'b0;
		linecnt = 30'b0;
		pixcnt = 30'b0; // pixcnt 3ff signals a start of line
		linestart_detected = 1'b0;  // rising of clk2
		fieldstart_detected = 1'b0; // rising of clk2
		syncword = 8'b0;
		fvh_f = 1'b0;
		fvh_v = 1'b0; // 1:vblanking, 0:normal
		fvh_h = 1'b0; // 0:sav, 1:eav
		fvh_p = 4'b0;
		fvh_fvh = 3'b0;
	end
	
	// current value;   small frame testing;   DC value; small frame DC value
	parameter linelen  = 1280; //8; //1280. 9 pixels per line
	parameter linehead = 140;  //7; //20.   3 pixels for line sync at the beginning
	parameter linetail = 140;  //7; //660.  3 pixels for line sync at the end
	parameter linetotal = linehead + linelen + linetail;
	parameter vlen  = 243;  //6; //240.    6 lines per frame
	parameter vhead = 10;   //3; //20.     2 lines for vertical sync at the top
	parameter vtail = 10;   //3; //249100. 2 lines for vertical sync at the end
	parameter vtotal = vhead + vlen + vtail;
	parameter cntsmax = 30'h3fffffff;
	
	always @(posedge clk1)
	begin
		if ( rstd_state == 1'b1 ) begin
			if (pixcnt >= (linehead - 5) && pixcnt <= (linehead + linelen + 2) )
				hd <= 1'b1;
			else
				hd <= 1'b0;
		end
	end
	
	always @(posedge clk2)
	begin
		rstd_last <= rsted;
		if ( rstd_state == 1'b0 ) begin
			if ( rsted == 1'b1 && rstd_last == 1'b0 )
				rstd_state <= 1'b1;
			else 
				rstd_state <= 1'b0;
			vd <= 1'b1;
			pixels <= 8'h40;
			counts <= 30'b1;
			linecnt <= 30'b0;
			pixcnt <= cntsmax;
			fieldcnt <= 1'b0;
			linestart_detected <= 1'b0;
		end else begin
			// linestart and fieldstart detect
			if ( pixcnt == (linetotal - 2) )
				linestart_detected <= 1'b1;

			if ( linestart_detected ) begin
				linestart_detected <= 1'b0;
				pixcnt <= cntsmax;
			end else 
				pixcnt <= pixcnt + 1;

			if ( linestart_detected ) begin
				if ( linecnt == (vtotal - 2) ) begin
					fieldstart_detected <= 1'b1;
					linecnt <= cntsmax;
				end else
					linecnt <= linecnt + 1;
					
				if ( fieldstart_detected ) begin
					fieldstart_detected <= 1'b0;
					fieldcnt <= ~fieldcnt;
				end
			end

			// reset count
			if ( linestart_detected && fieldstart_detected ) // last clock in a frame
				counts <= 1'b1;
			else
				counts <= counts + 1;
				
			if ( pixcnt >= linehead-1 && pixcnt < (linehead + linelen -1) ) begin
				if ( counts[7:0] == 8'hff ) begin
					pixels[7:0] <= 8'hfe;
				end else if ( counts[7:0] == 8'b0 ) begin
					pixels[7:0] <= 8'b1;
				end else
					pixels[7:0] <= counts[7:0];
				if (pixcnt >= (linehead + linelen/2))
					fvh_h <= 1'b1;
			end else if (pixcnt < linehead -1) begin
				if ( pixcnt == linehead - 5 ) begin
					pixels <= 8'hff;
				end else if (pixcnt == linehead -4 || pixcnt == linehead -3 ) begin
					pixels <= 8'b0;
				end else if (pixcnt == linehead -2 ) begin
					pixels <= syncword;
				end else begin
					if (pixcnt == cntsmax) begin
						pixels <= 8'h80;
					end else if (pixels != 8'h80) begin
						pixels <= 8'h80;
					end else begin
						pixels <= 8'h30; //fixme: should be 8'h10;
					end
				end
				fvh_h <= 1'b0;
			end else begin
				if ( pixcnt == linehead + linelen - 1 ) begin
					pixels <= 8'hff;
				end else if ( pixcnt == linehead + linelen || pixcnt == linehead + linelen + 1) begin
					pixels <= 8'b0;
				end else if (pixcnt == linehead + linelen + 2) begin
					pixels <= syncword;
				end else begin
					if (pixcnt == linehead + linelen + 3) begin
						pixels <= 8'h80;
					end else if (pixels != 8'h80) begin
						pixels <= 8'h80;
					end else begin
						pixels <= 8'h30; //fixme: should be 8'h10;
					end
				end
			end

			fvh_f <= fieldcnt;
			if ( linecnt < vhead || linecnt >= vhead + vlen ) begin
				fvh_v <= 1'b1;
				vd <= 1'b1;
			end else begin
				fvh_v <= 1'b0;
				vd <= 1'b0;
			end
				
			syncword <= {1'b1, fvh_fvh, fvh_p};
			fvh_fvh <= {fvh_f, fvh_v, fvh_h};
			
			if (         fvh_fvh == 3'b000) begin
				fvh_p = 4'b0000;
			end else if (fvh_fvh == 3'b001) begin
				fvh_p = 4'b1101;
			end else if (fvh_fvh == 3'b010) begin
				fvh_p = 4'b1011;
			end else if (fvh_fvh == 3'b011) begin
				fvh_p = 4'b0110;
			end else if (fvh_fvh == 3'b100) begin
				fvh_p = 4'b0111;
			end else if (fvh_fvh == 3'b101) begin
				fvh_p = 4'b1010;
			end else if (fvh_fvh == 3'b110) begin
				fvh_p = 4'b1100;
			end else if (fvh_fvh == 3'b111) begin
				fvh_p = 4'b0001;
			end
		end // rst
	end
endmodule
