module two_to_four_decoder(
	output d0,d1,d2,d3,
	input a0, a1
);

assign d0 = ~a1&~a0;
assign d1 = ~a1&a0;
assign d2 = a1&~a0;
assign d3 = a1&a0;

endmodule