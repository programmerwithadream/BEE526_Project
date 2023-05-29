module background_subtraction #(
	parameter IMG_LENGTH = 16384
)
(
	//background subtraction module will
	//write to sram_select + 1 the resulting image, and
	//read sram_select + 2 as current image, and
	//read sram_select + 3 as background image
	input [1:0] sram_select_in,
	input [23:0] inst_address [0:2],
	
	input [3:0] mem_out,
	
	output [7:0] inst [0:3],
	
	output [23:0] address [0:3],
	
	output [3:0] write_in,
	
	output [23:0] byte_length [0:3],
	
	input [3:0] io_valid,
	input [3:0] rw_done,
	
	input clk,
	
	input execute,
	output job_done
);

//have to declare j here because not working inside the always_ff?
//integer j;

localparam int RGB_IMG_LENGTH = 3 * IMG_LENGTH;

localparam int WAIT_TO_WRITE = (2 * IMG_LENGTH - 4) * 8; //<=(49152 - 16384 + 4) * 8//306064;//306096;//38262;

localparam int WRITE_BUFFER_SIZE = IMG_LENGTH + 4;

logic [31:0] state_counter;
logic [2:0] write_counter;
logic prep_counter;

/*
integer SRAM_SELECT_INT;
integer STATE_COUNTER_INT;
integer BUFFER_POINTER_INT;
*/

logic [1:0] sram_select;
//assign SRAM_SELECT_INT = sram_select;
//assign STATE_COUNTER_INT = state_counter;

//logic needed for background subtraction
logic [WRITE_BUFFER_SIZE - 1:0] write_buffer;
logic [31:0] buffer_pointer;
//assign BUFFER_POINTER_INT = buffer_pointer;

//rgb_byte[0] red, rgb_byte[1] green, rgb_byte[2] blue
logic [7:0] current_rgb_bytes [0:2];
logic [7:0] background_rgb_bytes [0:2];
logic is_foreground;

// assignments for inst, address, write, byte_length relative to
// sram
logic [7:0] relative_instructions [0:3];
logic [23:0] relative_addresses [0:3];
logic [23:0] relative_byte_lengths [0:3];

// relative indices with respect to sram
// maps absolute indices to it's relative position
// based on sram_select
logic [1:0] relative_indices [0:3];
logic [1:0] reverse_relative_indices [0:3];

assign relative_instructions[0] = 0;

assign relative_addresses[0] = 0;
assign relative_addresses[1] = inst_address[0];
assign relative_addresses[2] = inst_address[1];
assign relative_addresses[3] = inst_address[2];

assign relative_byte_lengths[0] = 0;
assign relative_byte_lengths[1] = IMG_LENGTH;
assign relative_byte_lengths[2] = RGB_IMG_LENGTH;
assign relative_byte_lengths[3] = RGB_IMG_LENGTH;

assign write_in[0] = write_buffer[WRITE_BUFFER_SIZE - 1];
assign write_in[1] = write_buffer[WRITE_BUFFER_SIZE - 1];
assign write_in[2] = write_buffer[WRITE_BUFFER_SIZE - 1];
assign write_in[3] = write_buffer[WRITE_BUFFER_SIZE - 1];

always_ff @(posedge clk)
begin
	if (execute)
	begin
		sram_select <= sram_select_in;
	end
end

always_comb
begin
	case (sram_select)
		2'b00:
		begin
			relative_indices[0] = 0;
			relative_indices[1] = 1;
			relative_indices[2] = 2;
			relative_indices[3] = 3;
			reverse_relative_indices[0] = 0;
			reverse_relative_indices[1] = 1;
			reverse_relative_indices[2] = 2;
			reverse_relative_indices[3] = 3;
		end
		
		2'b01:
		begin
			relative_indices[0] = 3;
			relative_indices[1] = 0;
			relative_indices[2] = 1;
			relative_indices[3] = 2;
			reverse_relative_indices[0] = 1;
			reverse_relative_indices[1] = 2;
			reverse_relative_indices[2] = 3;
			reverse_relative_indices[3] = 0;
		end
		
		2'b10:
		begin
			relative_indices[0] = 2;
			relative_indices[1] = 3;
			relative_indices[2] = 0;
			relative_indices[3] = 1;
			reverse_relative_indices[0] = 2;
			reverse_relative_indices[1] = 3;
			reverse_relative_indices[2] = 0;
			reverse_relative_indices[3] = 1;
		end
		
		2'b11:
		begin
			relative_indices[0] = 1;
			relative_indices[1] = 2;
			relative_indices[2] = 3;
			relative_indices[3] = 0;
			reverse_relative_indices[0] = 3;
			reverse_relative_indices[1] = 0;
			reverse_relative_indices[2] = 1;
			reverse_relative_indices[3] = 2;
		end
	endcase
end

enum {IDLE, PREP, EXECUTE} states = IDLE;

// this always_ff block is responsible for setting relative_instructions
always_ff @(posedge clk)
begin
	if (states == PREP && ~prep_counter)
	begin
		relative_instructions[1] <= 0;
		relative_instructions[2] <= 3;
		relative_instructions[3] <= 3;
	end
	else if (state_counter == WAIT_TO_WRITE - 1)
	begin
		relative_instructions[1] <= 2;
		relative_instructions[2] <= 0;
		relative_instructions[3] <= 0;
	end
	else
	begin
		relative_instructions[1] <= 0;
		relative_instructions[2] <= 0;
		relative_instructions[3] <= 0;
	end
end

always_ff @(posedge clk)
begin
	case (states)
		IDLE:
		begin
			job_done <= 0;
			
			if (execute)
			begin
				states <= PREP;
				prep_counter <= 0;
				
				/*
				inst[(SRAM_SELECT_INT + 1) % 4] <= 0;
				address[(SRAM_SELECT_INT + 1) % 4] <= inst_address[0];
				byte_length[(SRAM_SELECT_INT + 1) % 4] <= IMG_LENGTH;
				
				inst[(SRAM_SELECT_INT + 2) % 4] <= 3;
				address[(SRAM_SELECT_INT + 2) % 4] <= inst_address[1];
				byte_length[(SRAM_SELECT_INT + 2) % 4] <= RGB_IMG_LENGTH;
				inst[(SRAM_SELECT_INT + 3) % 4] <= 3;
				address[(SRAM_SELECT_INT + 3) % 4] <= inst_address[2];
				byte_length[(SRAM_SELECT_INT + 3) % 4] <= RGB_IMG_LENGTH;
				*/
			end
			else
			begin
				integer i;
				for (i = 0; i < 4; i = i + 1)
				begin
					inst[i] <= 0;
					address[i] <= 0;
					byte_length[i] <= 0;
				end
			end
		end
		
		PREP:
		begin
			if (~prep_counter)
			begin
				address[0] <= relative_addresses[relative_indices[0]];
				address[1] <= relative_addresses[relative_indices[1]];
				address[2] <= relative_addresses[relative_indices[2]];
				address[3] <= relative_addresses[relative_indices[3]];
				byte_length[0] <= relative_byte_lengths[relative_indices[0]];
				byte_length[1] <= relative_byte_lengths[relative_indices[1]];
				byte_length[2] <= relative_byte_lengths[relative_indices[2]];
				byte_length[3] <= relative_byte_lengths[relative_indices[3]];
				
				prep_counter <= 1;
			end
			else
			begin
				states <= EXECUTE;
				
				inst[0] <= relative_instructions[relative_indices[0]];
				inst[1] <= relative_instructions[relative_indices[1]];
				inst[2] <= relative_instructions[relative_indices[2]];
				inst[3] <= relative_instructions[relative_indices[3]];
				
				prep_counter <= 0;
			end
			
			/*
			inst[(SRAM_SELECT_INT + 2) % 4] <= 0;
			address[(SRAM_SELECT_INT + 2) % 4] <= 0;
			byte_length[(SRAM_SELECT_INT + 2) % 4] <= 0;
			inst[(SRAM_SELECT_INT + 3) % 4] <= 0;
			address[(SRAM_SELECT_INT + 3) % 4] <= 0;
			byte_length[(SRAM_SELECT_INT + 3) % 4] <= 0;
			*/	
		end
		
		EXECUTE:
		begin
			job_done <= 0;
						
			if (rw_done[reverse_relative_indices[1]])
			begin
				states <= IDLE;
				job_done <= 1;
				
				/*
				//integer declaration not working here
				//integer j;
				for (j = 0; j < 4; j = j + 1)
				begin
					inst[j] <= 0;
					address[j] <= 0;
					byte_length[j] <= 0;
				end
				*/
			end
			else if (state_counter == WAIT_TO_WRITE)
			begin
				inst[0] <= relative_instructions[relative_indices[0]];
				inst[1] <= relative_instructions[relative_indices[1]];
				inst[2] <= relative_instructions[relative_indices[2]];
				inst[3] <= relative_instructions[relative_indices[3]];
			end
			else if(state_counter > WAIT_TO_WRITE)
			begin
				inst[0] <= 0;
				inst[1] <= 0;
				inst[2] <= 0;
				inst[3] <= 0;
				address[0] <= 0;
				address[1] <= 0;
				address[2] <= 0;
				address[3] <= 0;
				byte_length[0] <= 0;
				byte_length[1] <= 0;
				byte_length[2] <= 0;
				byte_length[3] <= 0;
				/*
				inst[(SRAM_SELECT_INT + 1) % 4] <= 0;
				address[(SRAM_SELECT_INT + 1) % 4] <= 0;
				byte_length[(SRAM_SELECT_INT + 1) % 4] <= 0;
				*/
			end
		end
	endcase
end

logic current_shift_in;
logic background_shift_in;
logic current_input_valid;
logic background_input_valid;
logic current_output_valid;
logic background_output_valid;

four_to_one_mux CURRENT_SHIFT_IN_MUX(current_shift_in, mem_out[0], mem_out[1], mem_out[2], mem_out[3], reverse_relative_indices[2][0], reverse_relative_indices[2][1]);
four_to_one_mux BACKGROUND_SHIFT_IN_MUX(backgroudn_shift_in, mem_out[0], mem_out[1], mem_out[2], mem_out[3], reverse_relative_indices[3][0], reverse_relative_indices[3][1]);
four_to_one_mux CURRENT_INPUT_VALID_MUX(current_input_valid, io_valid[0], io_valid[1], io_valid[2], io_valid[3], reverse_relative_indices[2][0], reverse_relative_indices[2][1]);
four_to_one_mux BACKGROUND_INPUT_VALID_MUX(background_input_valid, io_valid[0], io_valid[1], io_valid[2], io_valid[3], reverse_relative_indices[3][0], reverse_relative_indices[3][1]);

rgb_converter CURRENTCONVERTER(current_rgb_bytes[0], current_rgb_bytes[1], current_rgb_bytes[2], current_shift_in, current_input_valid, clk, current_output_valid);
rgb_converter BACKGROUNDCONVERTER(background_rgb_bytes[0], background_rgb_bytes[1], background_rgb_bytes[2], background_shift_in, background_input_valid, clk, background_output_valid);

always_ff @(posedge clk)
begin
		
	// cases for buffer_pointer update
	if (current_output_valid && write_counter != 7)
	begin
		buffer_pointer <= buffer_pointer - 1;
	end
	else if (~current_output_valid && write_counter == 7)
	begin
		buffer_pointer <= buffer_pointer + 1;
	end
	
	/*
	if (current_output_valid && state_counter < WAIT_TO_WRITE)
	begin
		buffer_pointer <= buffer_pointer + 1;
	end
	else if (io_valid[relative_indices[1]] && ~current_output_valid)
	begin
		buffer_pointer <= buffer_pointer - 1;
	end
	else if (~io_valid[relative_indices[1]] && current_output_valid)
	begin
		buffer_pointer <= buffer_pointer + 1;
	end
	*/
	
	if (io_valid[reverse_relative_indices[2]])
	begin
		state_counter <= state_counter + 1;
	end
	
	if (io_valid[reverse_relative_indices[1]])
	begin
		write_counter <= write_counter + 1;
	end
	
	/*
	if (io_valid[relative_indices[2]])
	begin
		current_rgb_bytes[(STATE_COUNTER_INT / 8) % 3][(STATE_COUNTER_INT % 8)] <= mem_out[relative_indices[2]];
	end
	if (io_valid[relative_indices[3]])
	begin
		background_rgb_bytes[(STATE_COUNTER_INT / 8) % 3][(STATE_COUNTER_INT % 8)] <= mem_out[relative_indices[3]];
		
		// should find a better spot for state_counter increment
		state_counter <= state_counter + 1;
	end
	*/
	
	if (current_output_valid)
	begin
		write_buffer[buffer_pointer] <= is_foreground;
	end
	
	if (write_counter == 7)
	begin
		write_buffer <= write_buffer << 1;
	end
	
	if (rw_done[reverse_relative_indices[1]] || states == IDLE)
	begin
		state_counter <= 0;
		write_counter <= 0;
		buffer_pointer <= WRITE_BUFFER_SIZE - 1;
	end
end

foreground_detector F0(is_foreground, current_rgb_bytes, background_rgb_bytes);

endmodule