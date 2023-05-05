module four_to_one_mux(
	output sig_out,
	input sig0,
	input sig1,
	input sig2,
	input sig3,
	input select0,
	input select1
);

assign sig_out = ~select1&~select0&sig0 | ~select1&select0&sig1 | select1&~select0&sig2 | select1&select0&sig3;

endmodule