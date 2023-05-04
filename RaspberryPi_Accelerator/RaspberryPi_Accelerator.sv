
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
localparam desiredFrequency = 10000.0 / 2.0, divisor = 50_000_000 / desiredFrequency;

//pin numbers for raspberry pi, sram0,1,2,3 signals
localparam int MOSI_PIN = 1;
localparam int MISO_PIN = 3;
localparam int RPICLK_PIN = 5;
localparam int CS0_PIN = 0;
localparam int CS1_PIN = 2;

localparam int CE0_PIN = 10;
localparam int SO0_PIN = 12;
localparam int SCLK0_PIN = 11;
localparam int SI0_PIN = 13;

localparam int CE1_PIN = 18;
localparam int SO1_PIN = 20;
localparam int SCLK1_PIN = 19;
localparam int SI1_PIN = 21;

localparam int CE2_PIN = 26;
localparam int SO2_PIN = 28;
localparam int SCLK2_PIN = 27;
localparam int SI2_PIN = 29;

localparam int CE3_PIN = 32;
localparam int SO3_PIN = 34;
localparam int SCLK3_PIN = 33;
localparam int SI3_PIN = 35;

//=======================================================
//  REG/WIRE declarations
//=======================================================

//clock signals
logic [31:0] clkCounter;
logic clk;

//signals for raspberry pi
logic MOSI, MISO, RPiclk, cs0, cs1;

//signals for two-to-four decoder
logic [3:0] d;
logic [1:0] chip_select;

//signals going into srams
logic SI0, SO0, sclk0, ce0;
logic SI1, SO1, sclk1, ce1;
logic SI2, SO2, sclk2, ce2;
logic SI3, SO3, sclk3, ce3;

//signals from fpga
logic [3:0] FI;
logic [3:0] fs;

//signals for spi read/write modules
logic [7:0] out_reg [3:0];
logic [3:0] output_valid;
logic [7:0] inst [3:0];
logic [23:0] address [3:0];
logic [7:0] in_reg [3:0];

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
assign MOSI = GPIO[MOSI_PIN];
assign GPIO[MISO_PIN] = MISO;
assign RPiclk = GPIO[RPICLK_PIN];
assign cs0 = GPIO[CS0_PIN];
assign cs1 = GPIO[CS1_PIN];

//TODO:connect input signals for decoder from raspberry pi
//temporary signals
assign chip_select[0] = SW[0];
assign chip_select[1] = SW[1];

//FPGA read/write modules
SRAM_SPI_RW S0(fs[0], GPIO[SO0_PIN], FI[0], clk, out_reg[0], output_valid[0], inst[0], address[0], in_reg[0]);
SRAM_SPI_RW S1(fs[1], GPIO[SO1_PIN], FI[1], clk, out_reg[1], output_valid[1], inst[1], address[1], in_reg[1]);
SRAM_SPI_RW S2(fs[2], GPIO[SO2_PIN], FI[2], clk, out_reg[2], output_valid[2], inst[2], address[2], in_reg[2]);
SRAM_SPI_RW S3(fs[3], GPIO[SO3_PIN], FI[3], clk, out_reg[3], output_valid[3], inst[3], address[3], in_reg[3]);

//two-to-four decoder used for select signals for muxes
two_to_four_decoder D0(d[0], d[1], d[2], d[3], chip_select[0], chip_select[1]);

//muxes for sram0
two_to_one_mux MI0(SI0, FI0, MOSI, d[0]);
two_to_one_mux MSCLK0(sclk0, clk, RPiclk, d[0]);
two_to_one_mux MCE0(ce0, fs0, cs0, d[0]);

//assign signals for sram0
assign GPIO[CE0_PIN] = ce0;
assign SO0 = GPIO[SO0_PIN];
assign GPIO[SCLK0_PIN] = sclk0;
assign GPIO[SI0_PIN] = SI0;

//muxes for sram1
two_to_one_mux MI1(SI1, FI1, MOSI, d[1]);
two_to_one_mux MSCLK1(sclk1, clk, RPiclk, d[1]);
two_to_one_mux MCE1(ce1, fs1, cs0, d[1]);

//assign signals for sram1
assign GPIO[CE1_PIN] = ce1;
assign SO1 = GPIO[SO1_PIN];
assign GPIO[SCLK1_PIN] = sclk1;
assign GPIO[SI1_PIN] = SI1;

//muxes for sram2
two_to_one_mux MI2(SI2, FI2, MOSI, d[2]);
two_to_one_mux MSCLK2(sclk2, clk, RPiclk, d[2]);
two_to_one_mux MCE2(ce2, fs2, cs0, d[2]);

//assign signals for sram2
assign GPIO[CE2_PIN] = ce2;
assign SO2 = GPIO[SO2_PIN];
assign GPIO[SCLK2_PIN] = sclk2;
assign GPIO[SI2_PIN] = SI2;

//muxes for sram3
two_to_one_mux MI3(SI3, FI3, MOSI, d[3]);
two_to_one_mux MSCLK3(sclk3, clk, RPiclk, d[3]);
two_to_one_mux MCE3(ce3, fs3, cs0, d[3]);

//assign signals for sram3
assign GPIO[CE3_PIN] = ce3;
assign SO3 = GPIO[SO3_PIN];
assign GPIO[SCLK3_PIN] = sclk3;
assign GPIO[SI3_PIN] = SI3;

//mux for MISO signal back to raspberry pi
four_to_one_mux MMISO(MISO, SO0, SO1, SO2, SO3, chip_select[0], chip_select[1]);





//temporary test




endmodule
