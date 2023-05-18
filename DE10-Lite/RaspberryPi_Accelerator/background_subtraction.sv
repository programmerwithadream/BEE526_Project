module background_subtraction(
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
integer j;

//parameters needed for background subtraction
localparam int RGB_IMG_BYTE_LENGTH = 49152;
localparam int GS_IMG_BYTE_LENGTH = 16384;

localparam int WAIT_TO_WRITE = 306064;//306096;//38262;//test

integer SRAM_SELECT_INT;

integer STATE_COUNTER_MOD_24;
integer STATE_COUNTER_MOD_24_DIVIDE_8;



logic [1:0] sram_select;
assign SRAM_SELECT_INT = sram_select;

//logic needed for background subtraction
logic [7:0] threshold;
logic [10922:0] write_buffer;
logic [13:0] buffer_pointer;

logic [31:0] state_counter;
assign STATE_COUNTER_MOD_24 = state_counter % 24;
assign STATE_COUNTER_MOD_24_DIVIDE_8 = STATE_COUNTER_MOD_24 / 8;

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

assign threshold = 25;

always_ff @(posedge execute)
begin
	sram_select <= sram_select_in;
end



enum {IDLE, PREP, EXECUTE} states = IDLE;

always_ff @(posedge clk)
begin
	case (states)
		IDLE:
		begin
			job_done <= 0;
			
			if (execute)
			begin
				states <= PREP;
				
				address[SRAM_SELECT_INT + 1] <= inst_address[0];
				byte_length[SRAM_SELECT_INT + 1] <= GS_IMG_BYTE_LENGTH;
				
				inst[SRAM_SELECT_INT + 2] <= 3;
				address[SRAM_SELECT_INT + 2] <= inst_address[1];
				byte_length[SRAM_SELECT_INT + 2] <= RGB_IMG_BYTE_LENGTH;
				inst[SRAM_SELECT_INT + 3] <= 3;
				address[SRAM_SELECT_INT + 3] <= inst_address[2];
				byte_length[SRAM_SELECT_INT + 3] <= RGB_IMG_BYTE_LENGTH;
				
				state_counter <= 0;
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
				write_in <= 4'b0000;
				
				state_counter <= 0;
			end
		end
		
		PREP:
		begin
			inst[SRAM_SELECT_INT + 2] <= 0;
			address[SRAM_SELECT_INT + 2] <= 0;
			byte_length[SRAM_SELECT_INT + 2] <= 0;
			inst[SRAM_SELECT_INT + 3] <= 0;
			address[SRAM_SELECT_INT + 3] <= 0;
			byte_length[SRAM_SELECT_INT + 3] <= 0;
			
			if (state_counter == 32)
			begin
				states <= EXECUTE;
				state_counter <= 0;
			end
			else
			begin				
				state_counter <= state_counter + 1;
			end
		end
		
		EXECUTE:
		begin
			job_done <= 0;
						
			if (rw_done[SRAM_SELECT_INT + 1])
			begin
				states <= IDLE;
				job_done <= 1;
				
				//integer declaration not working here
				//integer j;
				for (j = 0; j < 4; j = j + 1)
				begin
					inst[j] <= 0;
					address[j] <= 0;
					byte_length[j] <= 0;
				end
				write_in <= 4'b0000;
				
				state_counter <= 0;
			end
			else if (state_counter == WAIT_TO_WRITE)
			begin
				inst[SRAM_SELECT_INT + 1] <= 2;
				
				state_counter <= state_counter + 1;
			end
			else if(state_counter < WAIT_TO_WRITE)
			begin
				state_counter <= state_counter + 1;
			end
			else
			begin
				inst[SRAM_SELECT_INT + 1] <= 0;
				address[SRAM_SELECT_INT + 1] <= 0;
				byte_length[SRAM_SELECT_INT + 1] <= 0;
				
				state_counter <= state_counter + 1;
			end
		end
	endcase
end


always_ff @(posedge clk)
begin
	if (states == EXECUTE)
	begin
		if (STATE_COUNTER_MOD_24 == 0 && state_counter != 0 && state_counter < WAIT_TO_WRITE + 32)
		begin
			write_buffer <= {write_buffer[10921:0], is_foreground};
			buffer_pointer <= buffer_pointer + 1;
		end
		else if (STATE_COUNTER_MOD_24 == 0 && state_counter > WAIT_TO_WRITE + 32)
		begin
			write_buffer <= {write_buffer[10921:0], is_foreground};
		end
		//WRITE IS WRONG write 1 byte needs 8 cycles
		else if (state_counter > WAIT_TO_WRITE + 32)
		begin
			//check this code
			write_in[SRAM_SELECT_INT + 1] <= write_buffer[buffer_pointer - 1] ? 255 : 0;
			buffer_pointer <= buffer_pointer - 1;
		end
		
		if (io_valid[SRAM_SELECT_INT + 2])
		begin
			current_rgb_bytes[STATE_COUNTER_MOD_24][STATE_COUNTER_MOD_24_DIVIDE_8] <= mem_out[SRAM_SELECT_INT + 2];
		end
		if (io_valid[SRAM_SELECT_INT + 3])
		begin
			background_rgb_bytes[STATE_COUNTER_MOD_24][STATE_COUNTER_MOD_24_DIVIDE_8] <= mem_out[SRAM_SELECT_INT + 3];
		end
	end
end

genvar k;
generate
	for (k = 0; k < 3; k = k + 1)
	begin :F1
		n_bit_subtractor #9 SCMB(current_minus_background_rgb_bytes[k], current_minus_background_signs[k], current_rgb_bytes[k], background_rgb_bytes[k]);
		n_bit_subtractor #9 SBMC(background_minus_current_rgb_bytes[k], background_minus_current_signs[k], background_rgb_bytes[k], current_rgb_bytes[k]);
		
		assign absolute_difference_rgb_bytes[k] = current_minus_background_signs[k] ? background_minus_current_rgb_bytes[k] : current_minus_background_rgb_bytes[k];
		n_bit_comparator #9 (comparator_results[k], absolute_difference_rgb_bytes[k], threshold);
	end
endgenerate

assign is_foreground = comparator_results[0] | comparator_results[1] | comparator_results[2];

endmodule