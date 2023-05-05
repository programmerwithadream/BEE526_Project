module display(
	output [7:0] segment0,
	output [7:0] segment1,
	output [7:0] segment2,
	output [7:0] segment3,
	output [7:0] segment4,
	output [7:0] segment5,
	input [20:0] num
);

logic [23:0] bcds;

//converts num from binary into binary coded decimals
//each binary coded decimal is four bits
//6 decimals are created for a total of 24 bits
BCD_converter(bcds, num);

//converts each binary coded decimal to 7segment output
bcd_to_segment(segment0, bcds[3:0]);
bcd_to_segment(segment1, bcds[7:4]);
bcd_to_segment(segment2, bcds[11:8]);
bcd_to_segment(segment3, bcds[15:12]);
bcd_to_segment(segment4, bcds[19:16]);
bcd_to_segment(segment5, bcds[23:20]);

endmodule
