module foreground_detector #(
	parameter THRESHOLD = 25
)
(
	output is_foreground,
	
	input [7:0] current_rgb_bytes [0:2],
	input [7:0] background_rgb_bytes [0:2]
);

logic [7:0] absolute_difference_rgb_bytes [0:2];
logic [7:0] current_minus_background_rgb_bytes [0:2];
logic [2:0] current_minus_background_signs;
logic [7:0] background_minus_current_rgb_bytes [0:2];
logic [2:0] background_minus_current_signs;
logic [2:0] comparator_results;

genvar k;
generate
	for (k = 0; k < 3; k = k + 1)
	begin :F1
		n_bit_subtractor #9 SCMB(current_minus_background_rgb_bytes[k], current_minus_background_signs[k], current_rgb_bytes[k], background_rgb_bytes[k]);
		n_bit_subtractor #9 SBMC(background_minus_current_rgb_bytes[k], background_minus_current_signs[k], background_rgb_bytes[k], current_rgb_bytes[k]);
		
		assign absolute_difference_rgb_bytes[k] = current_minus_background_signs[k] ? background_minus_current_rgb_bytes[k] : current_minus_background_rgb_bytes[k];
		//n_bit_comparator #9 THRESHOLDCOMP(comparator_results[k], absolute_difference_rgb_bytes[k], THRESHOLD);
		assign comparator_results[k] = absolute_difference_rgb_bytes[k] >= THRESHOLD;
	end
endgenerate

assign is_foreground = comparator_results[0] | comparator_results[1] | comparator_results[2];

endmodule