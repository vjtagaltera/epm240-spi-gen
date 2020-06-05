
module sample_backpressure(rsted, clk2, vd_neg, hd, earlyabort, hdgen, clk2gen);
	input rsted, clk2, vd_neg, hd, earlyabort;
	output hdgen, clk2gen;
	
	reg earlyabort_state;
	reg [29:0] clk2counts;
	reg [29:0] hdcounts;
	reg [29:0] vdcounts;
	reg hdgen;
	reg clk2gen;
	
	initial begin
		earlyabort_state = 1'b1; // no abort
		clk2counts = 30'b0;
		hdcounts = 30'b0; 
		vdcounts = 30'b0; // vd at least counts to 1024 
		hdgen = 1'b0;
		clk2gen = 1'b0;
	end
	
	parameter clk2max = 8;  // 8 clk2 to 1 clk2gen
	parameter hdgenmax = 4096; // earlyabort delay by 16384 clk2
	parameter docount = 1; // 1: hold for hdgenmax. other: hold till vd_neg low
	
	always @(posedge clk2)
	begin
		if ( rsted == 1'b1 ) begin
			if ( vd_neg == 1'b0 ) begin
				earlyabort_state <= 1'b1;
				vdcounts <= 30'b0;
				hdgen <= 1'b0;
			end else begin
				vdcounts <= vdcounts + 1;
			   if ( earlyabort == 1'b0 && vdcounts >= 1024 ) begin
				   earlyabort_state <= 1'b0;
				   hdcounts <= 30'b0;
				end else begin
					if ( earlyabort_state == 1'b0 ) begin
						if ( hdcounts >= hdgenmax ) begin
							earlyabort_state <= 1'b1;
						end else if ( docount == 1 ) begin
							hdcounts <= hdcounts + 1;
						end
					end
				end
				hdgen <= (hd && earlyabort_state);
			end 
			// divided c2 clock for debugging
			if ( clk2counts >= clk2max ) begin
				clk2counts <= 30'b0;
				clk2gen <= ! clk2gen;
			end else begin
				clk2counts <= clk2counts + 1;
			end
		end
	end
endmodule
