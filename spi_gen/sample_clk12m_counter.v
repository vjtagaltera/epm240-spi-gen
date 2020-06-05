
module sample_clk12m_counter(clock48, rsted, clk1, clk2);
	input clock48, rsted;
	output clk1, clk2;
	
	reg clk1, clk2;
	reg [1:0] counts;
	reg rstd_state;
	
	initial begin
		clk1 = 1'b0;
		clk2 = 1'b0;
		counts = 2'b0;
		rstd_state = 1'b0;
	end
	
	always @(posedge clock48)
	begin
		if ( rstd_state == 1'b0 ) begin
			if ( rsted == 1'b1 )
				rstd_state <= 1'b1;
			else 
				rstd_state <= 1'b0;
			clk1 <= 1'b0;
			clk2 <= 1'b0;
			counts <= 2'b00;
		end else begin
			if ( rsted == 1'b1 ) begin
				if ( counts == 2'b00 ) begin
					clk1 <= 1'b1;
					clk2 <= 1'b0;
				end else if ( counts == 2'b01 ) begin
					clk1 <= 1'b1;
					clk2 <= 1'b1;
				end else if ( counts == 2'b10 ) begin
					clk1 <= 1'b0;
					clk2 <= 1'b1;
				end else begin
					clk1 <= 1'b0;
					clk2 <= 1'b0;
				end
				counts <= counts + 1;
			end else begin
				rstd_state <= 1'b0;
				clk1 <= 1'b0;
				clk2 <= 1'b0;
				counts <= 2'b00;
			end
		end
		
		
	end
endmodule
