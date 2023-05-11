//currently only supports read/write, not RDSR, WRSR
//currently only supports reading and writing one byte
module SRAM_SPI_RW(
	output cs,
	output MOSI,
	input sclk,
	
	//inputs into the module specifying instruction,
	//address, and inputs for write
	input [7:0] inst,
	input [23:0] address,
	input [7:0] in_reg,
	input [23:0] length,
	
	//signal showing SO line on SRAM is ongoing
	output output_valid
);

enum {WAIT, READ, READHOLD, WRITE} states = WAIT;
logic [23:0] state_counter;

logic [39:0] shift_reg;

always_ff @(posedge sclk)
begin
	case (states)
		WAIT:
		begin
			state_counter <= 0;
			cs <= 1;
			case (inst)
				3:
				begin
					states <= READ;
					shift_reg <= {inst, address, 8'b00000000};
					output_valid <= 0;
					state_counter <= 0;
				end
				2:
				begin
					states <= WRITE;
					shift_reg <= {inst, address, in_reg};
					output_valid <= 0;
					state_counter <= 0;
				end
				default:
				begin
					MOSI <= 0;
					output_valid <= 0;
					state_counter <= 0;
				end
			endcase
		end
		READ:
		begin
			cs <= 0;
			if (state_counter == 33 + length)
			begin
				states <= READHOLD;
				state_counter <= 0;
				cs <= 1;
				output_valid <= 1;
			end
			else
			begin
				state_counter <= state_counter + 1;
				if (state_counter <= 32)
				begin
					MOSI <= shift_reg[39];
					shift_reg <= shift_reg << 1;
				end
				else
				begin
					output_valid <= 1;
				end
			end
		end
		READHOLD:
		begin
			states <= WAIT;
			output_valid <= 0;
		end
		WRITE:
		begin
			cs <= 0;
			if (state_counter == 33 + length)
			begin
				states <= WAIT;
				state_counter <= 0;
				cs <= 1;
			end
			else
			begin
				state_counter <= state_counter + 1;
				MOSI <= shift_reg[39];
				shift_reg <= shift_reg << 1;
			end
		end
	endcase
end

endmodule