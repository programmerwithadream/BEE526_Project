module task_manager #(
	parameter N = 80
)
(
	output inst_valid,
	output idle,
	
	input [N-1:0] RPi_inst,
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
localparam int VALID_INST_POINTER = 254;

//maximum address of the sram
localparam int MAX_ADDRESS = 'h1ffff;

typedef enum logic [7:0] {
	IDLE = 8'b00,
	BGS = 8'b11111111
} state_t;

state_t states = IDLE;

logic [23:0] state_counter;

logic [7:0] job_type;
logic [23:0] inst_address [0:2];
//addresses for sram needs to be 24 bits
assign job_type = RPi_inst[N-1:N-8];
assign inst_address[0] = RPi_inst[N-9:N-32];
assign inst_address[1] = RPi_inst[N-33:N-56];
assign inst_address[2] = RPi_inst[N-57:0];

//comparators determining if RPi_inst represents a valid task
logic [3:0] comparator_results;
n_bit_comparator #8 C0(comparator_results[0], job_type, VALID_INST_POINTER);
n_bit_comparator #24 C1(comparator_results[1], MAX_ADDRESS, inst_address[0]);
n_bit_comparator #24 C2(comparator_results[2], MAX_ADDRESS, inst_address[1]);
n_bit_comparator #24 C3(comparator_results[3], MAX_ADDRESS, inst_address[2]);
assign inst_valid = &comparator_results;

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
logic task_select;
assign inst = task_select ? bgs_inst : idle_inst;
assign address = task_select ? bgs_address : idle_address;
assign write_in = task_select ? bgs_write_in : idle_write_in;
assign byte_length = task_select ? bgs_byte_length : idle_byte_length;

always_ff @(posedge clk)
begin
	case (states)
		IDLE:
		begin
			if (proceed)
			begin
				states <= state_t'(job_type);
				idle <= 0;
				state_counter <= 0;
			end
			else
			begin
				idle <= 1;
			end
		end
		
		//background subtraction state
		BGS:
		begin
			if (bgs_job_done)
			begin
				states <= IDLE;
				idle <= 1;
				task_select <= 0;
				state_counter <= state_counter + 1;
			end
			if (state_counter == 0)
			begin
				idle <= 0;
				task_select <= 1;
				
				bgs_execute <= 1;
				
				state_counter <= state_counter + 1;
			end
			else if (state_counter == 24'hffffff)
			begin
				states <= IDLE;
				idle <= 1;
				task_select <= 0;
				
				state_counter <= 0;
			end
			else
			begin
				idle <= 0;
				task_select <= 1;
				
				state_counter <= state_counter + 1;
			end
		end
	endcase	
end

endmodule