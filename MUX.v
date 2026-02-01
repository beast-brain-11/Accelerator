module MUX(input [31:0] DMAport, output [24:0] out [17:0]);
	always @ (*) begin
		integer i;
		for (i = 0; i < 18; i = i + 1)
			out[i] = 25'b0;
		case(DMAport[4:0])
			5'b00000:out[17] = DMAport[31:7];
			5'b00001:out[16] = DMAport[31:7];
			5'b00010:out[15] = DMAport[31:7];
			5'b00011:out[14] = DMAport[31:7];
			5'b00100:out[13] = DMAport[31:7];
			5'b00101:out[12] = DMAport[31:7];
			5'b00110:out[11] = DMAport[31:7];
			5'b00111:out[10] = DMAport[31:7];
			5'b01000:out[9] = DMAport[31:7];
			5'b01001:out[8] = DMAport[31:7];
			5'b01010:out[7] = DMAport[31:7];
			5'b01011:out[6] = DMAport[31:7];
			5'b01100:out[5] = DMAport[31:7];
			5'b01101:out[4] = DMAport[31:7];
			5'b01110:out[3] = DMAport[31:7];
			5'b01111:out[2] = DMAport[31:7];
			5'b10000:out[1] = DMAport[31:7];
			5'b10001:out[0] = DMAport[31:7];
			default:;
		endcase
	end
endmodule
