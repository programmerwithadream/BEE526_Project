module task_manager(
	output inst_valid,
	output idle,
	
	input [79:0] RPi_inst,
	input execute_task,
	
	input clk,
	
	//signals for the current sram configuration
	input [1:0] sram_select,
	
	//signals to and from SRAM
	output [7:0] inst [0:3],
	output [23:0] address [0:3],
	output [3:0] write_in,
	output [23:0] byte_length [0:3],
	input [3:0] mem_out,
	input [3:0] io_valid,
	input [3:0] rw_done
);


//instruction type most be presented in the most significant byte of inst
//can have up to 255 tasks, 8'b00000000 for instruction is reserved for no task
//first task implemented will start at 255
logic [7:0] valid_inst_pointer;
assign valid_inst_pointer = 254;

//maximum address of the sram
logic[23:0] max_address;
assign max_address = 'h1ffff;

enum {IDLE, BGS} states = IDLE;

logic [23:0] state_counter;

logic[7:0] logic_states;
logic [23:0] inst_address [0:2];
assign logic_states = RPi_inst[79:72];
//addresses for sram needs to be 24 bits
assign inst_address[0] = RPi_inst[71:48];
assign inst_address[1] = RPi_inst[47:24];
assign inst_address[2] = RPi_inst[23:0];

//comparators determining if RPi_inst represents a valid task
/*
logic [3:0] comparator_results;
n_bit_comparator #9 C0(comparator_results[0], logic_states, valid_inst_pointer);
n_bit_comparator #25 C1(comparator_results[1], max_address, inst_address[0]);
n_bit_comparator #25 C2(comparator_results[2], max_address, inst_address[1]);
n_bit_comparator #25 C3(comparator_results[3], max_address, inst_address[2]);
*/
assign inst_valid = (logic_states >= valid_inst_pointer) & (max_address >= inst_address[0]) & (max_address >= inst_address[1]) & (max_address >= inst_address[2]);

//signal determining if execution can proceed
logic proceed;
assign proceed = inst_valid & execute_task & idle;

//signals for IDLE
logic [7:0] idle_inst [0:3];
logic [23:0] idle_address [0:3];
logic [3:0] idle_write_in;
logic [23:0] idle_byte_length [0:3];

//signals for background subtraction
logic [7:0] bgs_inst [0:3];
logic [23:0] bgs_address [0:3];
logic [3:0] bgs_write_in;
logic [23:0] bgs_byte_length [0:3];
logic bgs_execute, bgs_job_done;
background_subtraction B(sram_select, inst_address, mem_out, bgs_inst, bgs_address, bgs_write_in, bgs_byte_length, io_valid, rw_done, clk, bgs_execute, bgs_job_done);

//**********************
//MUX FOR TASK SELECTION
//**********************
//
logic task_select, job_done, job_incomplete;
assign inst = task_select ? bgs_inst : idle_inst;
assign address = task_select ? bgs_address : idle_address;
assign write_in = task_select ? bgs_write_in : idle_write_in;
assign byte_length = task_select ? bgs_byte_length : idle_byte_length;
assign job_done = bgs_job_done | job_incomplete;


always_ff @(posedge clk)
begin
	if (proceed)
	begin
		case(logic_states)
			0: states <= IDLE;
			255: states <= BGS;
			default: states <= IDLE;
		endcase
	end
	else if(job_done)
	begin
		states <= IDLE;
	end
end

always_ff @(posedge clk)
begin
	case (states)
		IDLE:
		begin
			idle <= 1;
			task_select <= 0;
			state_counter <= 0;
			job_incomplete <= 0;
		end
		
		//background subtraction state
		BGS:
		begin
			if (bgs_job_done)
			begin
				idle <= 1;
				
				task_select <= 0;				
				bgs_execute <= 0;
				
				state_counter <= 0;
			end
			else if (state_counter == 0)
			begin
				idle <= 0;
				task_select <= 1;
				
				bgs_execute <= 1;
				
				state_counter <= state_counter + 1;
			end
			else if (state_counter == 24'hffffff)
			begin
				idle <= 1;
				task_select <= 0;
				bgs_execute <= 0;
				
				job_incomplete <= 1;
								
				state_counter <= 0;
			end
			else
			begin
				idle <= 0;
				task_select <= 1;
				bgs_execute <= 0;
				
				state_counter <= state_counter + 1;
			end
		end
	endcase	
end

endmodule