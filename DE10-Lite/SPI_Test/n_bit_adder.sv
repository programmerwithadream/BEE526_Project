module n_bit_adder #(
	parameter N = 32
)
(
	output [N-1:0] sum,
	output cout, ov,
	input [N-1:0] a, b,
	input cin
);

logic [N-1:0] c_out;

genvar i;
generate 
	for(i = 0; i < N; i = i+1)
	begin :F1
		if (i == 0)
		begin
			full_adder D0(sum[0], c_out[0], a[0], b[0], cin);
		end
		else
		begin
			full_adder D1(sum[i], c_out[i], a[i], b[i], c_out[i-1]);
		end
	end
endgenerate

assign cout = c_out[N-1];
assign ov = ~(c_out[N-1]^c_out[N-2]);

endmodule