module n_bit_register #(
	parameter N = 32
)
(
	output [N-1:0] stored_bits,
	input [N-1:0] input_bits,
	input write_enable, clk, reset
);

always_ff @(posedge clk)
begin
	if (reset)
	begin
		stored_bits <= 0;
	end
	else if (write_enable)
	begin
		stored_bits <= input_bits;
	end
end

endmodule