module bcd_to_segment(
	output[7:0] segment,
	input[3:0] b
);

//displays hexadecimal
assign segment[0] = (b[3]&b[2]&~b[1]&b[0]) | (b[3]&~b[2]&b[1]&b[0]) | (~b[3]&~b[2]&~b[1]&b[0]) | (~b[3]&b[2]&~b[1]&~b[0]);
assign segment[1] = (~b[3]&b[2]&~b[1]&b[0]) | (b[2]&b[1]&~b[0]) | (b[3]&b[2]&~b[0]) | (b[3]&b[1]&b[0]);
assign segment[2] = (b[3]&b[2]&b[1]) | (b[3]&b[2]&~b[0]) | (~b[3]&~b[2]&b[1]&~b[0]);
assign segment[3] = (~b[3]&~b[2]&~b[1]&b[0]) | (~b[3]&b[2]&~b[1]&~b[0]) | (b[2]&b[1]&b[0]) | (b[3]&~b[2]&b[1]&~b[0]);
assign segment[4] = (~b[3]&b[0]) | (~b[3]&b[2]&~b[1]) | (~b[2]&~b[1]&b[0]);
assign segment[5] = (~b[3]&~b[2]&b[0]) | (~b[3]&~b[2]&b[1]) | (~b[3]&b[1]&b[0]) | (b[3]&b[2]&~b[1]&b[0]);
assign segment[6] = (~b[3]&~b[2]&~b[1]) | (~b[3]&b[2]&b[1]&b[0]) | (b[3]&b[2]&~b[1]&~b[0]);
assign segment[7] = 1;

endmodule