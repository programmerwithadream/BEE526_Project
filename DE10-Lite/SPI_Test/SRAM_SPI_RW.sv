//currently only supports read/write, not RDSR, WRSR
module SRAM_SPI_RW(
	output MOSI,
	output cs,
	
	output [7:0] out_reg,
	output output_valid,
	
	input MISO,
	input clk,
	
	input [7:0] inst,
	input [23:0] address,
	input [7:0] in_reg
);

enum {WAIT, READ, READHOLD, WRITE} states = WAIT;
logic [5:0] state_counter;

logic [39:0] shift_reg;

assign out_reg = shift_reg[7:0];

//n_bit_register #8 R0(out_reg, shift_reg[7:0], clk, output_valid, 0);

always_ff @(posedge clk)
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
			if (state_counter == 41)
			begin
				states <= READHOLD;
				state_counter <= 0;
				cs <= 1;
				output_valid <= 1;
				//out_reg <= shift_reg[7:0];
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
					shift_reg <= {shift_reg[38:0], MISO};
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
			if (state_counter == 41)
			begin
				states <= WAIT;
				state_counter <= 0;
				cs <= 1;
				output_valid <= 1;
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