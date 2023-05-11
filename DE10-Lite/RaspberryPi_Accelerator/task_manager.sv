module task_manager #(
	parameter N = 80
)
(
	output inst_valid,
	output job_done,
	
	input [N-1:0] RPi_inst,
	input execute_task,
	
	input clk,
	
	//signals for the current sram configuration
	input [1:0] sram_select,
	
	//signals to and from SRAM
	output [7:0] sram_inst [3:0],
	output [23:0] address [3:0],
	output [7:0] in_reg [3:0],
	output [23:0] length [3:0],
	input [3:0] so,
	input [3:0] output_valid
);


//instruction type most be presented in the most significant byte of inst
//can have up to 255 tasks, 8'b00000000 for instruction is reserved for no task
//first task implemented will start at 255
localparam int INST_POINTER = 255;

//maximum address of the sram
localparam int MAX_ADDRESS = 'h1ffff;

//parameters needed for background subtraction
localparam int RGB_IMG = 49152;
localparam int GS_IMG = 16384;

//logic needed for background subtraction
logic [7:0] threshold;
logic [GS_IMG - 1:0] resulting_img;

//counter keeping track of states
logic [32:0] state_counter;

typedef enum logic [7:0] {
	IDLE = 8'b00,
	SET_THRESHOLD = 8'b11111111
} state_t;

state_t states;

logic [7:0] job_type;
//addresses for sram needs to be 24 bits
assign job_type = RPi_inst[N-1:N-8];

//assigning addresses based on current chip_select mode
always_comb
begin
	case (sram_select)
		2'b00:
		begin
			address[1] = RPi_inst[N-9:N-32];
			address[2] = RPi_inst[N-33:N-56];
			address[3] = RPi_inst[N-57:N-80];
		end
		2'b01:
		begin
			address[2] = RPi_inst[N-9:N-32];
			address[3] = RPi_inst[N-33:N-56];
			address[0] = RPi_inst[N-57:N-80];
		end
		2'b10:
		begin
			address[3] = RPi_inst[N-9:N-32];
			address[0] = RPi_inst[N-33:N-56];
			address[1] = RPi_inst[N-57:N-80];
		end
		2'b11:
		begin
			address[0] = RPi_inst[N-9:N-32];
			address[1] = RPi_inst[N-33:N-56];
			address[2] = RPi_inst[N-57:N-80];
		end
	endcase
end

//comparators determining if RPi_inst represents a valid task
logic [3:0] comparator_results;
n_bit_comparator #8 C0(comparator_results[0], job_type, INST_POINTER);
n_bit_comparator #24 C1(comparator_results[1], MAX_ADDRESS, address[0]);
n_bit_comparator #24 C2(comparator_results[2], MAX_ADDRESS, address[1]);
n_bit_comparator #24 C3(comparator_results[3], MAX_ADDRESS, address[2]);
assign inst_valid = &comparator_results;

//signal determining if execution can proceed
logic proceed;
assign proceed = inst_valid & execute_task & job_done;

always_ff @(posedge clk)
begin
	case (states)
		IDLE:
		begin
			if (proceed)
			begin
				states <= state_t'(job_type);
				job_done <= 0;
				state_counter <= 0;
			end
		end
		
		//for setting threshold, job_type must be 255 and threshold must be the 8 lsb
		SET_THRESHOLD:
		begin
			threshold <= address[2][7:0];
			job_done <= 1;
			states <= IDLE;
		end
	endcase	
end

endmodule