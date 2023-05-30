module rgb_converter(
	output [7:0] red,
	output [7:0] green,
	output [7:0] blue,
	
	input shift_in,
	input input_valid,
	input clk,
	
	output output_valid
);

logic [23:0] rgb;
logic [4:0] state_counter;

//opencv uses blue/green/red order for some reason
assign blue = rgb[23:16];
assign green = rgb[15:8];
assign red = rgb[7:0];

always_ff @(posedge clk)
begin
	if (input_valid)
	begin
		rgb <= {rgb[22:0], shift_in};
		
		if (state_counter == 24)
		begin
			state_counter <= 1;
		end
		else
		begin
			state_counter <= state_counter + 1;
		end
		
		if(state_counter == 23)
		begin
			output_valid <= 1;
		end
		else
		begin
			output_valid <= 0;
		end
	end
	else
	begin
		state_counter <= 0;
		output_valid <= 0;
	end
end


endmodule