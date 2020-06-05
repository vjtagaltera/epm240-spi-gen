
module sample_counter(clock48, rst, counts, inited, reseted);
	input clock48;
	input rst;
	output [31:0] counts;
	output inited;
	output reseted;
	reg [31:0] counts;
	reg [31:0] initcnt;
	reg inited, reseted, reseted_state;
	
	initial begin
		counts = 32'b0;
		initcnt = 32'b0;
		inited = 1'b0;
		reseted = 1'b0;
		reseted_state = 1'b0;
	end
	
	always @(posedge clock48)
	begin
		if ( initcnt < 32'h3000000 ) begin
			inited <= 1'b0;
			initcnt <= initcnt + 1;
		end else if ( initcnt >= 32'h3000000 ) begin
			inited <= 1'b1;
		end
		
		if ( inited == 1'b0 ) begin
			counts <= 32'b0;
		end else if ( rst == 1'b1 ) begin
			counts <= 32'b0;
			reseted_state <= 1'b1;
			reseted <= 1'b0;
		end else begin
			counts <= counts + 1;
			reseted <= reseted_state;
		end
		
	end
endmodule
