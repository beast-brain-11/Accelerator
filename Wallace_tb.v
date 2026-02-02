`timescale 1ns/1ps

module Wallace_tb;
    reg signed [7:0] a, b;
    wire signed [15:0] prod;

    Wallace_BaughWooley uut (.a(a), .b(b), .prod(prod));

    initial begin
        $display("Wallace Multiplier Test");
        
        // Test 1: 10 * 1 = 10
        a = 8'd10; b = 8'd1;
        #10;
        $display("10 * 1 = %0d (expected 10)", prod);

        // Test 2: -1 * -1 = 1
        a = -8'd1; b = -8'd1;
        #10;
        $display("-1 * -1 = %0d (expected 1)", prod);

        // Test 3: 127 * -1 = -127
        a = 8'd127; b = -8'd1;
        #10;
        $display("127 * -1 = %0d (expected -127)", prod);

        // Test 4: -128 * 1 = -128
        a = -8'd128; b = 8'd1;
        #10;
        $display("-128 * 1 = %0d (expected -128)", prod);

        // Test 5: 5 * 5 = 25
        a = 8'd5; b = 8'd5;
        #10;
        $display("5 * 5 = %0d (expected 25)", prod);

        $finish;
    end
endmodule
