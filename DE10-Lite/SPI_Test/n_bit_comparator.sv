//outputs 1 if a >= b, 0 if a < b
module n_bit_comparator #(
	parameter N = 32
)
(
	output c,
	input [N-1:0] a, b
);

logic [N-1:0] b_comp, difference;
logic cout, ov;

n_bit_twos_comp #(N) D0(b_comp, b);
n_bit_adder #(N) D1(difference, cout, ov, a, b_comp, 0);

assign c = ~difference[N-1];

endmodule
