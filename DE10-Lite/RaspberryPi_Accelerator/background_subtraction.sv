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

localparam int WRITE_BUFFER_SIZE = 2 * IMG_LENGTH + 4;

logic [31:0] state_counter;
logic [7:0] write_counter;

integer SRAM_SELECT_INT;
integer STATE_COUNTER_INT;
integer BUFFER_POINTER_INT;

logic [1:0] sram_select;
assign SRAM_SELECT_INT = sram_select;
assign STATE_COUNTER_INT = state_counter;

//logic needed for background subtraction
logic [7:0] threshold;
logic [WRITE_BUFFER_SIZE - 1:0] write_buffer;
logic [13:0] buffer_pointer;
assign BUFFER_POINTER_INT = buffer_pointer;

//rgb_byte[0] red, rgb_byte[1] green, rgb_byte[2] blue
logic [7:0] current_rgb_bytes [0:2];
logic [7:0] background_rgb_bytes [0:2];
logic [7:0] absolute_difference_rgb_bytes [0:2];
logic [7:0] current_minus_background_rgb_bytes [0:2];
logic [2:0] current_minus_background_signs;
logic [7:0] background_minus_current_rgb_bytes [0:2];
logic [2:0] background_minus_current_signs;
logic [2:0] comparator_results;
logic is_foreground;

//threshold for background subtraction
assign threshold = 25;

// assignments for inst, address, write, byte_length relative to
// sram
logic [7:0] inst_relative [0:3];
logic [23:0] address_relative [0:3];
logic [3:0] write_in_relative;
logic [23:0] byte_length_relative [0:3];

// relative indices with respect to sram
// maps absolute indices to it's relative position
// based on sram_select
logic [1:0] relative_indices [0:3];

assign inst_relative[0] = 0;

assign address_relative[0] = 0;
assign address_relative[1] = inst_address[0];
assign address_relative[2] = inst_address[1];
assign address_relative[3] = inst_address[2];

assign byte_length_relative[0] = 0;
assign byte_length_relative[1] = IMG_LENGTH;
assign byte_length_relative[2] = RGB_IMG_LENGTH;
assign byte_length_relative[3] = RGB_IMG_LENGTH;

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
	begin
		2'b00:
		begin
			relative_indices[0] = 0;
			relative_indices[1] = 3;
			relative_indices[2] = 2;
			relative_indices[3] = 1;
		end
		
		2'b01:
		begin
			relative_indices[0] = 1;
			relative_indices[1] = 0;
			relative_indices[2] = 3;
			relative_indices[3] = 2;
		end
		
		2'b10:
		begin
			relative_indices[0] = 2;
			relative_indices[1] = 1;
			relative_indices[2] = 0;
			relative_indices[3] = 3;
		end
		
		2'b10:
		begin
			relative_indices[0] = 3;
			relative_indices[1] = 2;
			relative_indices[2] = 1;
			relative_indices[3] = 0;
		end
	end
end

assign inst[0] = 

enum {IDLE, PREP, EXECUTE} states = IDLE;

always_ff @(posedge clk)
begin
	if (execute)
	begin
		inst_relative[2] = 3;
		inst_relative[3] = 3;
	end
	else if (state_counter == WAIT_TO_WRITE)
	begin
		inst_relative[1] = 2;
	end
	else
	begin
		inst_relative[1] = 0;
		inst_relative[2] = 0;
		inst_relative[3] = 0;
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
				
				
				
				
				
				
				inst[(SRAM_SELECT_INT + 1) % 4] <= 0;
				address[(SRAM_SELECT_INT + 1) % 4] <= inst_address[0];
				byte_length[(SRAM_SELECT_INT + 1) % 4] <= IMG_LENGTH;
				
				inst[(SRAM_SELECT_INT + 2) % 4] <= 3;
				address[(SRAM_SELECT_INT + 2) % 4] <= inst_address[1];
				byte_length[(SRAM_SELECT_INT + 2) % 4] <= RGB_IMG_LENGTH;
				inst[(SRAM_SELECT_INT + 3) % 4] <= 3;
				address[(SRAM_SELECT_INT + 3) % 4] <= inst_address[2];
				byte_length[(SRAM_SELECT_INT + 3) % 4] <= RGB_IMG_LENGTH;
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
			inst[(SRAM_SELECT_INT + 2) % 4] <= 0;
			address[(SRAM_SELECT_INT + 2) % 4] <= 0;
			byte_length[(SRAM_SELECT_INT + 2) % 4] <= 0;
			inst[(SRAM_SELECT_INT + 3) % 4] <= 0;
			address[(SRAM_SELECT_INT + 3) % 4] <= 0;
			byte_length[(SRAM_SELECT_INT + 3) % 4] <= 0;
						
			states <= EXECUTE;
		end
		
		EXECUTE:
		begin
			job_done <= 0;
						
			if (rw_done[(SRAM_SELECT_INT + 1) % 4])
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
				inst[(SRAM_SELECT_INT + 1) % 4] <= 2;
			end
			else if(state_counter > WAIT_TO_WRITE)
			begin
				inst[(SRAM_SELECT_INT + 1) % 4] <= 0;
				address[(SRAM_SELECT_INT + 1) % 4] <= 0;
				byte_length[(SRAM_SELECT_INT + 1) % 4] <= 0;
			end
		end
	endcase
end


always_ff @(posedge clk)
begin
	write_in[(SRAM_SELECT_INT + 1) % 4] <= write_buffer[BUFFER_POINTER_INT];
		
	// cases for buffer_pointer update
	if (state_counter % 24 == 23 && state_counter < WAIT_TO_WRITE)
	begin
		buffer_pointer <= buffer_pointer + 1;
	end
	else if (io_valid[(SRAM_SELECT_INT + 1) % 4] && state_counter % 24 != 23 && write_counter == 7)
	begin
		buffer_pointer <= buffer_pointer - 1;
	end
	else if (io_valid[(SRAM_SELECT_INT + 1) % 4] && state_counter % 24 == 23 && write_counter != 7)
	begin
		buffer_pointer <= buffer_pointer + 1;
	end
	
	if (io_valid[(SRAM_SELECT_INT + 2) % 4])
	begin
		current_rgb_bytes[(STATE_COUNTER_INT / 8) % 3][(STATE_COUNTER_INT % 8)] <= mem_out[(SRAM_SELECT_INT + 2) % 4];
	end
	if (io_valid[(SRAM_SELECT_INT + 3) % 4])
	begin
		background_rgb_bytes[(STATE_COUNTER_INT / 8) % 3][(STATE_COUNTER_INT % 8)] <= mem_out[(SRAM_SELECT_INT + 3) % 4];
		
		// should find a better spot for state_counter increment
		state_counter <= state_counter + 1;
	end

	if (state_counter % 24 == 23)
	begin
		write_buffer <= {write_buffer[WRITE_BUFFER_SIZE - 2:0], is_foreground};
	end
	
	if (io_valid[(SRAM_SELECT_INT + 1) % 4])
	begin
		write_counter <= write_counter + 1;
	end
	
	if (rw_done[(SRAM_SELECT_INT + 1) % 4])
	begin
		state_counter <= 0;
		buffer_pointer <= 0;
	end
end

genvar k;
generate
	for (k = 0; k < 3; k = k + 1)
	begin :F1
		n_bit_subtractor #9 SCMB(current_minus_background_rgb_bytes[k], current_minus_background_signs[k], current_rgb_bytes[k], background_rgb_bytes[k]);
		n_bit_subtractor #9 SBMC(background_minus_current_rgb_bytes[k], background_minus_current_signs[k], background_rgb_bytes[k], current_rgb_bytes[k]);
		
		assign absolute_difference_rgb_bytes[k] = current_minus_background_signs[k] ? background_minus_current_rgb_bytes[k] : current_minus_background_rgb_bytes[k];
		n_bit_comparator #9 THRESHOLDCOMP(comparator_results[k], absolute_difference_rgb_bytes[k], threshold);
	end
endgenerate

assign is_foreground = comparator_results[0] | comparator_results[1] | comparator_results[2];

endmodule