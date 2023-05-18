module n_bit_subtractor #(
	parameter N = 32
)
(
	output [N-1:0] difference,
	output sign, ov,
	input [N-1:0] a, b
);

logic [N-1:0] b_comp;
logic cout;

n_bit_twos_comp #(N) D0(b_comp, b);
n_bit_adder #(N) D1(difference, cout, ov, a, b_comp, 0);

assign sign = difference[N-1];

endmodule