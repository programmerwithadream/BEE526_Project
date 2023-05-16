//currently only supports read/write, not RDSR, WRSR
module SRAM_SPI_RW(
	output cs,
	input MISO,
	input sclk,
	output MOSI,
	
	//inputs into the module specifying instruction,
	//address, and inputs for write
	input [7:0] inst,
	input [23:0] address,
	input write_in,
	input [23:0] byte_length,
	
	//signal showing module is ready to take write inputs or sram is outputting reads
	output io_valid,
	//signal showing instruction is done
	output rw_done
);

enum {IDLE, READ, WRITE} states = IDLE;
logic [23:0] state_counter;

logic [31:0] shift_reg;

logic [26:0] bit_length;
assign bit_length = byte_length * 8;

logic write_buff;

always_ff @(posedge sclk)
begin
	case (states)
		IDLE:
		begin
			shift_reg <= {inst, address};
			state_counter <= 0;
			cs <= 1;
			io_valid <= 0;
			rw_done <= 0;
			case (inst)
				3:
				begin
					states <= READ;
				end
				2:
				begin
					states <= WRITE;
					io_valid <= 1;
				end
				default:
				begin
					MOSI <= 0;
				end
			endcase
		end
		
		//TODO: bug, last bit is always 1
		READ:
		begin
			if (state_counter == 32 + bit_length)
			begin
				states <= IDLE;
				state_counter <= 0;
				cs <= 0;
				io_valid <= 0;
				rw_done <= 1;
			end
			if (state_counter == 31 + bit_length)
			begin
				state_counter <= state_counter + 1;
				cs <= 0;
				io_valid <= 0;
			end
			else if (state_counter < 31)
			begin
				state_counter <= state_counter + 1;
				cs <= 0;
				MOSI <= shift_reg[31];
				shift_reg <= shift_reg << 1;
				io_valid <= 0;
			end
			else if (state_counter == 31)
			begin
				state_counter <= state_counter + 1;
				cs <= 0;
				MOSI <= shift_reg[31];
				shift_reg <= shift_reg << 1;
				io_valid <= 1;
			end
			else
			begin
				MOSI <= 0;
				state_counter <= state_counter + 1;
				cs <= 0;
				io_valid <= 1;
			end
		end
		
		WRITE:
		begin
			if (state_counter == 34 + bit_length)
			begin
				states <= IDLE;
				state_counter <= 0;
				cs <= 1;
				
				io_valid <= 0;
				rw_done <= 1;
			end
			else if (state_counter == 0)
			begin			
				state_counter <= state_counter + 1;
				cs <= 1;
				io_valid <= 1;
				write_buff <= write_in;
			end
			else if (state_counter <= bit_length)
			begin
				state_counter <= state_counter + 1;
				cs <= 0;
				MOSI <= shift_reg[31];
				io_valid <= 1;
				shift_reg <= {shift_reg[30:0], write_buff};
				write_buff <= write_in;
			end
			else
			begin
				state_counter <= state_counter + 1;
				cs <= 0;
				MOSI <= shift_reg[31];
				io_valid <= 0;
				shift_reg <= shift_reg << 1;
			end
		end
	endcase
end

endmodule