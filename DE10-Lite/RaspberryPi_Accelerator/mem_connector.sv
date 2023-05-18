module mem_connector(
	output [3:0] decoder_out,
	input [1:0] sram_select,
	
	output [3:0] mem_in,
	input mosi,
	
	output [3:0] mem_clk,
	input clk,
	input RPiclk,
	
	output [3:0] chip_enable,
	input chip_select,
	
	output miso,
	input [3:0] mem_out,
	
	input [7:0] inst [0:3],
	input [23:0] address [0:3],
	input [3:0] write_in,
	input [23:0] byte_length [0:3],
	output [3:0] io_valid,
	output [3:0] rw_done
	
);

//signals from fpga
logic [3:0] fpga_select;
logic [3:0] fpga_in;

//two-to-four decoder used for select signals for muxes
two_to_four_decoder D0(decoder_out[0], decoder_out[1], decoder_out[2], decoder_out[3], sram_select[0], sram_select[1]);

//muxes for sram0 muxes
two_to_one_mux MI0(mem_in[0], fpga_in[0], mosi, decoder_out[0]);
two_to_one_mux MSCLK0(mem_clk[0], clk, RPiclk, decoder_out[0]);
two_to_one_mux MCE0(chip_enable[0], fpga_select[0], chip_select, decoder_out[0]);

//muxes for sram1 muxes
two_to_one_mux MI1(mem_in[1], fpga_in[1], mosi, decoder_out[1]);
two_to_one_mux MSCLK1(mem_clk[1], clk, RPiclk, decoder_out[1]);
two_to_one_mux MCE1(chip_enable[1], fpga_select[1], chip_select, decoder_out[1]);

//muxes for sram2 muxes
two_to_one_mux MI2(mem_in[2], fpga_in[2], mosi, decoder_out[2]);
two_to_one_mux MSCLK2(mem_clk[2], clk, RPiclk, decoder_out[2]);
two_to_one_mux MCE2(chip_enable[2], fpga_select[2], chip_select, decoder_out[2]);

//muxes for sram3 muxes
two_to_one_mux MI3(mem_in[3], fpga_in[3], mosi, decoder_out[3]);
two_to_one_mux MSCLK3(mem_clk[3], clk, RPiclk, decoder_out[3]);
two_to_one_mux MCE3(chip_enable[3], fpga_select[3], chip_select, decoder_out[3]);

//mux for MISO signal back to raspberry pi
four_to_one_mux MMISO(miso, mem_out[0], mem_out[1], mem_out[2], mem_out[3], sram_select[0], sram_select[1]);

//FPGA read/write modules
sram_spi_read_write S0(fpga_select[0], clk, fpga_in[0], inst[0], address[0], write_in[0], byte_length[0], io_valid[0], rw_done[0]);
sram_spi_read_write S1(fpga_select[1], clk, fpga_in[1], inst[1], address[1], write_in[1], byte_length[1], io_valid[1], rw_done[1]);
sram_spi_read_write S2(fpga_select[2], clk, fpga_in[2], inst[2], address[2], write_in[2], byte_length[2], io_valid[2], rw_done[2]);
sram_spi_read_write S3(fpga_select[3], clk, fpga_in[3], inst[3], address[3], write_in[3], byte_length[3], io_valid[3], rw_done[3]);

endmodule