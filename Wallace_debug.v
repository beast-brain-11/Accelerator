`timescale 1ns/1ps

module Wallace_debug;
    reg signed [7:0] a, b;
    wire signed [15:0] prod;
    wire signed [15:0] expected;
    
    assign expected = a * b;

    Wallace_BaughWooley uut (.a(a), .b(b), .prod(prod));

    initial begin
        $display("Wallace Multiplier Debug Test");
        $display("a       | b       | prod     | expected | match");
        $display("--------|---------|----------|----------|------");
        
        // Simple positive tests
        a = 8'd2; b = 8'd3;
        #10;
        $display("%8d | %7d | %8d | %8d | %s", a, b, prod, expected, (prod==expected)?"PASS":"FAIL");

        a = 8'd10; b = 8'd1;
        #10;
        $display("%8d | %7d | %8d | %8d | %s", a, b, prod, expected, (prod==expected)?"PASS":"FAIL");

        a = 8'd1; b = 8'd1;
        #10;
        $display("%8d | %7d | %8d | %8d | %s", a, b, prod, expected, (prod==expected)?"PASS":"FAIL");

        a = 8'd0; b = 8'd0;
        #10;
        $display("%8d | %7d | %8d | %8d | %s", a, b, prod, expected, (prod==expected)?"PASS":"FAIL");

        // Negative tests
        a = -8'd1; b = -8'd1;
        #10;
        $display("%8d | %7d | %8d | %8d | %s", a, b, prod, expected, (prod==expected)?"PASS":"FAIL");

        a = 8'd127; b = -8'd1;
        #10;
        $display("%8d | %7d | %8d | %8d | %s", a, b, prod, expected, (prod==expected)?"PASS":"FAIL");

        a = -8'd128; b = 8'd1;
        #10;
        $display("%8d | %7d | %8d | %8d | %s", a, b, prod, expected, (prod==expected)?"PASS":"FAIL");

        a = -8'd128; b = -8'd1;
        #10;
        $display("%8d | %7d | %8d | %8d | %s", a, b, prod, expected, (prod==expected)?"PASS":"FAIL");

        $finish;
    end
endmodule
