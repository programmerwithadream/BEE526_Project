//this bcd converter will use the double dabble algorithm
module BCD_converter(
	output [23:0] bcds,
	input [20:0] bNum
);

logic [23:0] temp [19:0];
logic [5:0] compResult [16:0];
logic [3:0] addResult [16:0][5:0];

//placeholder wires
logic [5:0] tempCout [16:0] ;
logic [5:0] tempOv [16:0];

assign temp[0][2] = bNum[19];
assign temp[0][1] = bNum[18];
assign temp[0][0] = bNum[17];


genvar i;
genvar j;
generate
	for (i = 0; i < 17; i = i + 1)
	begin: FI 
	
		for (j = 0; j < 6; j = j + 1)
		begin: FJ 
			n_bit_comparator #5 (compResult[i][j], {1'b0, temp[i][4*(j+1)-1:4*j]}, 5'b00101);
			n_bit_adder #4 (addResult[i][j], tempCout[i][j], tempOv[i][j], temp[i][4*(j+1)-1:4*j], 4'b0011, 0);

			always_comb
			begin
				
				if (j == 0)
				begin
					if (~compResult[i][0])
					begin
						temp[i+1][3:0] = {temp[i][2:0], bNum[16-i]};
					end
					else
					begin
						temp[i+1][3:0] = {addResult[i][0][2:0], bNum[16-i]};
					end
				end
				else
				begin
					if (~compResult[i][j])
					begin
						if (~compResult[i][j-1])
						begin
							temp[i+1][4*(j+1)-1:4*j] = temp[i][4*(j+1)-2:4*j-1];
						end
						else
						begin
							temp[i+1][4*(j+1)-1:4*j] = {temp[i][4*(j+1)-2:4*j], addResult[i][j-1][3]};
						end
					end
					else
					begin
						if (~compResult[i][j-1])
						begin
							temp[i+1][4*(j+1)-1:4*j] = {addResult[i][j][2:0], temp[i][4*j-1]};
						end
						else
						begin
							temp[i+1][4*(j+1)-1:4*j] = {addResult[i][j][2:0], addResult[i][j-1][3]};
						end
					end
				end
				
			end
			
		end
	
	end

endgenerate

assign bcds = temp[17];

endmodule