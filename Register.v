module Register(input clk, input enable, input [23:0] datain, output reg [23:0] dataout);
	always @ (posedge clk) begin
		if(enable)
			dataout <= datain;
	end
endmodule
