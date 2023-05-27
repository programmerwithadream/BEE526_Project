module instruction_handler
(
	output [79:0] RPi_inst,
	
	//signals from raspberry pi
	input MOSI,
	input RPiclk,
	input cs1
);

enum {IDLE, READ} states = IDLE;
logic [7:0] state_counter;

always_ff @(posedge RPiclk)
begin
	case (states)
		IDLE:
		begin
			if (cs1)
			begin
				state_counter <= 0;
			end
			else
			begin
				states <= READ;
				RPi_inst <= {RPi_inst[78:0], MOSI};
			end
		end
		READ:
		begin
			if (cs1)
			begin
				states <= IDLE;
			end
			else if (state_counter < 79)
			begin
				RPi_inst <= {RPi_inst[78:0], MOSI};
				state_counter <= state_counter + 1;
			end
			
		end
	endcase
end

endmodule