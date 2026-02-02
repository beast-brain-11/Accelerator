`timescale 1ns/1ps

module ConvEngine_tb;

    reg         clk;
    reg         rst;
    reg  [31:0] DMAport;
    reg         acc_enable;
    reg         acc_clear;
    wire [31:0] result;

    ConvEngine uut (
        .clk(clk),
        .rst(rst),
        .DMAport(DMAport),
        .acc_enable(acc_enable),
        .acc_clear(acc_clear),
        .result(result)
    );

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    // Task to build DMA word
    // data[23:0] = 3 bytes, enable = 1 bit, select[2:0] = register select
    task send_dma_word;
        input [23:0] data;
        input        enable;
        input [2:0]  select;
        begin
            // Format: [31:8]=data, [7]=enable, [6:3]=unused, [2:0]=select
            DMAport = {data, enable, 4'b0000, select};
            @(posedge clk);
            @(posedge clk);  // Extra cycle for register to latch
        end
    endtask

    // Test variables
    integer expected_result;
    integer i;

    initial begin
        $display("========================================");
        $display("  ConvEngine Testbench");
        $display("========================================");

        // Initialize
        clk = 0;
        rst = 1;
        DMAport = 32'b0;
        acc_enable = 0;
        acc_clear = 0;

        // Reset
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        $display("\n--- Test 1: Identity kernel at center ---");
        // Pixel window (3x3): all 10s
        // Kernel: identity (only center = 1)
        // Expected: 10 * 1 = 10

        // Load pixels: all 10 (0x0A)
        send_dma_word(24'h0A0A0A, 1, 3'b000);  // Reg0: pixel[0,1,2] = 10,10,10
        send_dma_word(24'h0A0A0A, 1, 3'b001);  // Reg1: pixel[3,4,5] = 10,10,10
        send_dma_word(24'h0A0A0A, 1, 3'b010);  // Reg2: pixel[6,7,8] = 10,10,10

        // Load kernel: identity (center=1, rest=0)
        send_dma_word(24'h000000, 1, 3'b011);  // Reg3: kernel[0,1,2] = 0,0,0
        send_dma_word(24'h000100, 1, 3'b100);  // Reg4: kernel[3,4,5] = 0,1,0
        send_dma_word(24'h000000, 1, 3'b101);  // Reg5: kernel[6,7,8] = 0,0,0

        // Clear accumulator and compute
        acc_clear = 1;
        @(posedge clk);
        acc_clear = 0;
        acc_enable = 1;
        @(posedge clk);
        acc_enable = 0;
        @(posedge clk);

        expected_result = 10;
        if (result == expected_result)
            $display("PASS: Result = %0d (expected %0d)", $signed(result), expected_result);
        else
            $display("FAIL: Result = %0d (expected %0d)", $signed(result), expected_result);

        $display("\n--- Test 2: All ones kernel ---");
        // Pixel window: 1,2,3,4,5,6,7,8,9
        // Kernel: all 1s
        // Expected: 1+2+3+4+5+6+7+8+9 = 45

        send_dma_word(24'h010203, 1, 3'b000);  // pixel[0,1,2] = 1,2,3
        send_dma_word(24'h040506, 1, 3'b001);  // pixel[3,4,5] = 4,5,6
        send_dma_word(24'h070809, 1, 3'b010);  // pixel[6,7,8] = 7,8,9

        send_dma_word(24'h010101, 1, 3'b011);  // kernel[0,1,2] = 1,1,1
        send_dma_word(24'h010101, 1, 3'b100);  // kernel[3,4,5] = 1,1,1
        send_dma_word(24'h010101, 1, 3'b101);  // kernel[6,7,8] = 1,1,1

        acc_clear = 1;
        @(posedge clk);
        acc_clear = 0;
        acc_enable = 1;
        @(posedge clk);
        acc_enable = 0;
        @(posedge clk);

        expected_result = 45;
        if (result == expected_result)
            $display("PASS: Result = %0d (expected %0d)", $signed(result), expected_result);
        else
            $display("FAIL: Result = %0d (expected %0d)", $signed(result), expected_result);

        $display("\n--- Test 3: Signed multiplication ---");
        // Pixel: -1 (0xFF as signed int8)
        // Kernel: -1 (0xFF)
        // Expected: 9 * ((-1)*(-1)) = 9 * 1 = 9

        send_dma_word(24'hFFFFFF, 1, 3'b000);  // pixel = -1,-1,-1
        send_dma_word(24'hFFFFFF, 1, 3'b001);  // pixel = -1,-1,-1
        send_dma_word(24'hFFFFFF, 1, 3'b010);  // pixel = -1,-1,-1

        send_dma_word(24'hFFFFFF, 1, 3'b011);  // kernel = -1,-1,-1
        send_dma_word(24'hFFFFFF, 1, 3'b100);  // kernel = -1,-1,-1
        send_dma_word(24'hFFFFFF, 1, 3'b101);  // kernel = -1,-1,-1

        acc_clear = 1;
        @(posedge clk);
        acc_clear = 0;
        acc_enable = 1;
        @(posedge clk);
        acc_enable = 0;
        @(posedge clk);

        expected_result = 9;
        if (result == expected_result)
            $display("PASS: Result = %0d (expected %0d)", $signed(result), expected_result);
        else
            $display("FAIL: Result = %0d (expected %0d)", $signed(result), expected_result);

        $display("\n--- Test 4: Mixed signed values ---");
        // Pixel: 127 (max positive)
        // Kernel: -1
        // Expected: 9 * (127 * -1) = 9 * -127 = -1143

        send_dma_word(24'h7F7F7F, 1, 3'b000);  // pixel = 127,127,127
        send_dma_word(24'h7F7F7F, 1, 3'b001);
        send_dma_word(24'h7F7F7F, 1, 3'b010);

        send_dma_word(24'hFFFFFF, 1, 3'b011);  // kernel = -1,-1,-1
        send_dma_word(24'hFFFFFF, 1, 3'b100);
        send_dma_word(24'hFFFFFF, 1, 3'b101);

        acc_clear = 1;
        @(posedge clk);
        acc_clear = 0;
        acc_enable = 1;
        @(posedge clk);
        acc_enable = 0;
        @(posedge clk);

        expected_result = -1143;
        if ($signed(result) == expected_result)
            $display("PASS: Result = %0d (expected %0d)", $signed(result), expected_result);
        else
            $display("FAIL: Result = %0d (expected %0d)", $signed(result), expected_result);

        $display("\n--- Test 5: Accumulation test ---");
        // Accumulate two convolutions
        // First: 9 * (10 * 1) = 90
        // Second: 9 * (10 * 1) = 90
        // Total: 180

        send_dma_word(24'h0A0A0A, 1, 3'b000);
        send_dma_word(24'h0A0A0A, 1, 3'b001);
        send_dma_word(24'h0A0A0A, 1, 3'b010);

        send_dma_word(24'h010101, 1, 3'b011);
        send_dma_word(24'h010101, 1, 3'b100);
        send_dma_word(24'h010101, 1, 3'b101);

        acc_clear = 1;
        @(posedge clk);
        acc_clear = 0;
        
        // First accumulation
        acc_enable = 1;
        @(posedge clk);
        // Second accumulation (same data)
        @(posedge clk);
        acc_enable = 0;
        @(posedge clk);

        expected_result = 180;
        if (result == expected_result)
            $display("PASS: Result = %0d (expected %0d)", $signed(result), expected_result);
        else
            $display("FAIL: Result = %0d (expected %0d)", $signed(result), expected_result);

        $display("\n--- Test 6: Edge detection kernel (Sobel-like) ---");
        // Pixel: uniform 100
        // Kernel: [-1, 0, 1, -2, 0, 2, -1, 0, 1] (horizontal edge)
        // Expected: 0 (uniform image has no edges)

        send_dma_word(24'h646464, 1, 3'b000);  // 100,100,100
        send_dma_word(24'h646464, 1, 3'b001);
        send_dma_word(24'h646464, 1, 3'b010);

        send_dma_word(24'hFF00_01, 1, 3'b011);  // -1, 0, 1
        send_dma_word(24'hFE00_02, 1, 3'b100);  // -2, 0, 2
        send_dma_word(24'hFF00_01, 1, 3'b101);  // -1, 0, 1

        acc_clear = 1;
        @(posedge clk);
        acc_clear = 0;
        acc_enable = 1;
        @(posedge clk);
        acc_enable = 0;
        @(posedge clk);

        expected_result = 0;
        if ($signed(result) == expected_result)
            $display("PASS: Result = %0d (expected %0d)", $signed(result), expected_result);
        else
            $display("FAIL: Result = %0d (expected %0d)", $signed(result), expected_result);

        $display("\n========================================");
        $display("  Testbench Complete");
        $display("========================================");
        
        #100;
        $finish;
    end

endmodule
