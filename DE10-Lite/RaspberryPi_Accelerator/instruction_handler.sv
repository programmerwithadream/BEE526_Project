module instruction_handler #(
	parameter N = 80
)
(
	output [N-1:0] RPi_inst,
	
	//signals from raspberry pi
	input MOSI,
	input RPiclk,
	input cs1
);

enum {IDLE, READ} states = IDLE;

always_ff @(posedge RPiclk)
begin
	if (cs1)
	begin
		states <= IDLE;
	end
	else
	begin
		states <= READ;
	end
end

always_ff @(posedge RPiclk)
begin
	case (states)
		IDLE:
		begin
		
		end
		READ:
		begin
			RPi_inst <= {RPi_inst[N-2:0], MOSI};
		end
	endcase
end

endmodule