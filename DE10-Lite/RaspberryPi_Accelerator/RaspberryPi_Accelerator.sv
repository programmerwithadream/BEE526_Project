
//=======================================================
//  This code is generated by Terasic System Builder
//=======================================================

module RaspberryPi_Accelerator(

	//////////// CLOCK //////////
	input 		          		ADC_CLK_10,
	input 		          		MAX10_CLK1_50,
	input 		          		MAX10_CLK2_50,

	//////////// SDRAM //////////
	output		    [12:0]		DRAM_ADDR,
	output		     [1:0]		DRAM_BA,
	output		          		DRAM_CAS_N,
	output		          		DRAM_CKE,
	output		          		DRAM_CLK,
	output		          		DRAM_CS_N,
	inout 		    [15:0]		DRAM_DQ,
	output		          		DRAM_LDQM,
	output		          		DRAM_RAS_N,
	output		          		DRAM_UDQM,
	output		          		DRAM_WE_N,

	//////////// SEG7 //////////
	output		     [7:0]		HEX0,
	output		     [7:0]		HEX1,
	output		     [7:0]		HEX2,
	output		     [7:0]		HEX3,
	output		     [7:0]		HEX4,
	output		     [7:0]		HEX5,

	//////////// KEY //////////
	input 		     [1:0]		KEY,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// SW //////////
	input 		     [9:0]		SW,

	//////////// VGA //////////
	output		     [3:0]		VGA_B,
	output		     [3:0]		VGA_G,
	output		          		VGA_HS,
	output		     [3:0]		VGA_R,
	output		          		VGA_VS,

	//////////// Accelerometer //////////
	output		          		GSENSOR_CS_N,
	input 		     [2:1]		GSENSOR_INT,
	output		          		GSENSOR_SCLK,
	inout 		          		GSENSOR_SDI,
	inout 		          		GSENSOR_SDO,

	//////////// Arduino //////////
	inout 		    [15:0]		ARDUINO_IO,
	inout 		          		ARDUINO_RESET_N,

	//////////// GPIO, GPIO connect to GPIO Default //////////
	inout 		    [35:0]		GPIO
);



//=======================================================
//  parameter declarations
//=======================================================

//frequency the SPI operates on
localparam desiredFrequency = 100.0 / 2.0, divisor = 50_000_000 / desiredFrequency;

//pin numbers for raspberry pi, sram0,1,2,3 signals
localparam int MOSI_PIN = 1;
localparam int MISO_PIN = 3;
localparam int RPICLK_PIN = 5;
localparam int CS0_PIN = 0;
localparam int CS1_PIN = 2;
localparam int SRAM_SELECT0_PIN = 10; //connect to RPI GPIO 24
localparam int SRAM_SELECT1_PIN = 12; //connect to RPI GPIO 23
localparam int INST_VALID_PIN = 14; //connect to RPI GPIO pin 17
localparam int JOB_DONE_PIN = 13; //connect to RPI GPIO pin  27
localparam int EXECUTE_TASK_PIN = 11; //connect to RPI GPIO pin 22

localparam int CE0_PIN = 18;
localparam int CE1_PIN = 22;
localparam int CE2_PIN = 26;
localparam int CE3_PIN = 32;

localparam int SO0_PIN = 20;
localparam int SO1_PIN = 24;
localparam int SO2_PIN = 28;
localparam int SO3_PIN = 34;

localparam int SCLK0_PIN = 19;
localparam int SCLK1_PIN = 23;
localparam int SCLK2_PIN = 27;
localparam int SCLK3_PIN = 33;

localparam int SI0_PIN = 21;
localparam int SI1_PIN = 25;
localparam int SI2_PIN = 29;
localparam int SI3_PIN = 35;

//=======================================================
//  REG/WIRE declarations
//=======================================================

//clock signals
logic [31:0] clkCounter;
logic clk;

//signals for raspberry pi
logic mosi, miso, RPiclk;
logic [1:0] chip_select;
//signals for two-to-four decoder
logic [3:0] decoder_out;
logic [1:0] sram_select;
//status signals between raspberry pi  and fpga
logic inst_valid, job_done, execute_task;

//signals going into srams
//sram chip enables
logic [3:0] chip_enable;
//signals from sram to device
logic [3:0] mem_out;
//sram system clocks
logic [3:0] mem_clk;
//signals from device into sram
logic [3:0] mem_in;

//signals from fpga
logic [3:0] fpga_select;
logic [3:0] fpga_in;

//signals for spi read/write modules
logic [7:0] inst [3:0];
logic [23:0] address [3:0];
logic [3:0] write_in;
logic [23:0] length [3:0];
logic [3:0] io_valid;
logic [3:0] rw_done;

//=======================================================
//  Structural coding
//=======================================================

//constructing slower clk for SPI protocol
always_ff @(posedge MAX10_CLK1_50)
begin
	if (clkCounter == 0)
	begin
		clkCounter <= divisor;
		clk <= ~clk;
	end
	else
	begin
		clkCounter <= clkCounter - 1;
	end
end

//assigning raspberry pi signals to their corresponding GPIO pins
assign mosi = GPIO[MOSI_PIN];
assign GPIO[MISO_PIN] = miso;
assign RPiclk = GPIO[RPICLK_PIN];
assign chip_select[0] = GPIO[CS0_PIN];
assign chip_select[1] = GPIO[CS1_PIN];
assign sram_select[0] = SW[1];//GPIO[SRAM_SELECT0_PIN];
assign sram_select[1] = SW[2];//GPIO[SRAM_SELECT1_PIN];

//signals between RPi and FPGA task_manager
assign GPIO[INST_VALID_PIN] = inst_valid;
assign GPIO[JOB_DONE_PIN] = job_done;
assign execute_task = GPIO[EXECUTE_TASK_PIN];

//assigning chip enable to their corresponding srams
assign GPIO[CE0_PIN] = chip_enable[0];
assign GPIO[CE1_PIN] = chip_enable[1];
assign GPIO[CE2_PIN] = chip_enable[2];
assign GPIO[CE3_PIN] = chip_enable[3];

//assigning output signals to their corresponding srams
assign mem_out[0] = GPIO[SO0_PIN];
assign mem_out[1] = GPIO[SO1_PIN];
assign mem_out[2] = GPIO[SO2_PIN];
assign mem_out[3] = GPIO[SO3_PIN];

//assigning clk signals to their corresponding srams
assign GPIO[SCLK0_PIN] = mem_clk[0];
assign GPIO[SCLK1_PIN] = mem_clk[1];
assign GPIO[SCLK2_PIN] = mem_clk[2];
assign GPIO[SCLK3_PIN] = mem_clk[3];

//assigning input signals to their corresponding srams
assign GPIO[SI0_PIN] = mem_in[0];
assign GPIO[SI1_PIN] = mem_in[1];
assign GPIO[SI2_PIN] = mem_in[2];
assign GPIO[SI3_PIN] = mem_in[3];

//FPGA read/write modules
sram_spi_read_write S0(fpga_select[0], mem_out[0], clk, fpga_in[0], inst[0], address[0], write_in[0], length[0], io_valid[0], rw_done[0]);
sram_spi_read_write S1(fpga_select[1], mem_out[1], clk, fpga_in[1], inst[1], address[1], write_in[1], length[1], io_valid[1], rw_done[1]);
sram_spi_read_write S2(fpga_select[2], mem_out[2], clk, fpga_in[2], inst[2], address[2], write_in[2], length[2], io_valid[2], rw_done[2]);
sram_spi_read_write S3(fpga_select[3], mem_out[3], clk, fpga_in[3], inst[3], address[3], write_in[3], length[3], io_valid[3], rw_done[3]);

mem_connector MC0(decoder_out, sram_select, mem_in, fpga_in, mosi, mem_clk, clk, RPiclk, chip_enable, fpga_select, chip_select[0], miso, mem_out);


//***************
//temporary test
//***************
logic [31:0] temp_inst;
logic [2:0] temp_pins;
assign temp_pins[0] = execute_task;
assign temp_pins[1] = sram_select[0];
assign temp_pins[2] = sram_select[1];
instruction_handler #32 I0(temp_inst, mosi, RPiclk, chip_select[1]);
//task_manager T0(inst_valid, job_done, temp_inst, execute_task, clk, sram_select, inst, address, write_in, length, so, io_valid, rw_done);




//test finite state machine to see if updated sram_SPI_RW works
enum {IDLE, WRITE, HOLD1, READ, HOLD2} states = IDLE;

//add state_counter
logic [15:0] state_counter;
//add address_counter test only
logic [23:0] address_counter;

assign length[0] = 2;

logic [15:0] in_reg;
logic [15:0] out_reg;

assign write_in[0] = in_reg[15];

//write and read 2 bytes at a time to sram0
always_ff @(posedge clk)
begin
	case (states)
		IDLE:
		begin
			if(SW[0])
				begin
				if (state_counter == 0)
				begin
					states <= WRITE;
					inst[0] <= 2;
					address[0] <= address_counter;
					
					in_reg <= address_counter + 1;//65280;//43690;//21845;
					out_reg <= 0;
					
					state_counter <= 25;
				end
				else
				begin
					state_counter <= state_counter - 1;
				end
			end
			else
			begin
				inst[0] <= 0;
			end
		end
		
		WRITE:
		begin
			if (io_valid[0])
			begin
				in_reg <= in_reg << 1;
			end
			else if (rw_done[0])
			begin
				inst[0] <= 0;
				states <= HOLD1;
			end
			else
			begin
				inst[0] <= 0;
			end
		end
		
		HOLD1:
		begin
			states <= READ;
			inst[0] <= 3;
		end
		
		READ:
		begin
			if (rw_done[0])
			begin
				inst[0] <= 0;
				states <= HOLD2;
			end
			else if (io_valid[0]) 
			begin
				out_reg <= {out_reg[14:0], mem_out[0]};
			end
			else
			begin
				inst[0] <= 0;
			end
		end
		
		HOLD2:
		begin
			states <= IDLE;
			inst[0] <= 0;			
			
			address_counter <= address_counter + 2;
		end
	endcase
end



display DI0(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, out_reg);

endmodule
