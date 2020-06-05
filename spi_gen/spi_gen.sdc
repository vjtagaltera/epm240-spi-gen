
#https://coertvonk.com/hw/logic/quartus-cycloneiv-de0nano-15932
#create_clock -period 20.000 -name CLOCK_50
#derive_pll_clocks
#derive_clock_uncertainty

create_clock -period 20.000 -waveform {0.0 10.0} -name clk_main_in [get_ports {pin_name1}]

#Warning (332060): Node: sample_clk12m_counter:inst1|clk2 was determined to be a clock but was found without an associated clock assignment.
#	Info (13166): Register sample_spi_gen_counter:inst|vd_out is being clocked by sample_clk12m_counter:inst1|clk2
create_generated_clock \
		-edges {1 5 9} \
		-source [get_ports {pin_name1}] \
		-name clkdiv_1 [get_registers "sample_clk12m_counter:CLK_INST|clk1"]

create_generated_clock -divide_by 4 \
		-source [get_ports {pin_name1}] \
		-name clkdiv_2 [get_registers {CLK_INST|clk2}]


