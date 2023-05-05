module n_bit_twos_comp #(
	parameter N = 32
)
(
	output [N-1:0] comp,
	input [N-1:0] a
);

logic [N-1:0] temp;

always_comb
begin
	for (int i = 0; i < N; i = i+1)
	begin
		temp[i] = ~a[i];
	end
end

logic cout, ov;

n_bit_adder #(N) D0(comp, cout, ov, temp, 0, 1);

endmodule