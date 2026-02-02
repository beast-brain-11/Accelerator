module MUX(input [31:0] DMAport, output reg [24:0] out [5:0]);
	// DMA Word Format:
	// [31:8]  - 24-bit data (3 bytes)
	// [7]     - Enable bit
	// [6:3]   - Unused (4 bits)
	// [2:0]   - 3 select lines (6 outputs)
	
	always @ (*) begin
		integer i;
		for (i = 0; i < 6; i = i + 1)
			out[i] = 25'b0;
		case(DMAport[2:0])
			3'b000: out[0] = DMAport[31:7];
			3'b001: out[1] = DMAport[31:7];
			3'b010: out[2] = DMAport[31:7];
			3'b011: out[3] = DMAport[31:7];
			3'b100: out[4] = DMAport[31:7];
			3'b101: out[5] = DMAport[31:7];
			default:;
		endcase
	end
endmodule
