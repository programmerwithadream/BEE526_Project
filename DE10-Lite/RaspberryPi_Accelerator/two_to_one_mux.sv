module two_to_one_mux(
	output sig_out,
	input sig0,
	input sig1,
	input select
);

assign sig_out = ~select&sig0 | select&sig1;

endmodule