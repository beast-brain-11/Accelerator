module Wallace_BaughWooley (
    input  signed [7:0] a,
    input  signed [7:0] b,
    output signed [15:0] prod
);

    /* -----------------------------
       Baugh–Wooley Partial Products
    ----------------------------- */
    wire [7:0] pp [7:0];

    genvar i;
    generate
        for (i = 0; i < 7; i = i + 1) begin
            assign pp[i][6:0] =  a[6:0] & {7{b[i]}};
            assign pp[i][7]   = ~(a[7]   & b[i]);   // invert sign column
        end
    endgenerate

    assign pp[7][6:0] = ~(a[6:0] & {7{b[7]}});     // invert sign row
    assign pp[7][7]   =  (a[7]   & b[7]);          // sign × sign (no invert)

    /* -----------------------------
       Align Partial Products
    ----------------------------- */
    wire [15:0] P [7:0];

    assign P[0] = {8'b0, pp[0]};
    assign P[1] = {7'b0, pp[1], 1'b0};
    assign P[2] = {6'b0, pp[2], 2'b0};
    assign P[3] = {5'b0, pp[3], 3'b0};
    assign P[4] = {4'b0, pp[4], 4'b0};
    assign P[5] = {3'b0, pp[5], 5'b0};
    assign P[6] = {2'b0, pp[6], 6'b0};
    assign P[7] = {1'b0, pp[7], 7'b0};

    /* -----------------------------
       Baugh–Wooley Bias Correction
       (add 1 at bit 7 and bit 15)
    ----------------------------- */
    wire [15:0] bias;
    assign bias = 16'b1000_0000_0000_0000 | 16'b0000_0000_1000_0000;

    /* -----------------------------
       Wallace Tree – CSA Stages
    ----------------------------- */
    wire [15:0] s1_0, c1_0;
    wire [15:0] s1_1, c1_1;

    assign s1_0 = P[0] ^ P[1] ^ P[2];
    assign c1_0 = ((P[0] & P[1]) | (P[1] & P[2]) | (P[0] & P[2])) << 1;

    assign s1_1 = P[3] ^ P[4] ^ P[5];
    assign c1_1 = ((P[3] & P[4]) | (P[4] & P[5]) | (P[3] & P[5])) << 1;

    wire [15:0] s2_0, c2_0;

    assign s2_0 = s1_0 ^ c1_0 ^ s1_1;
    assign c2_0 = ((s1_0 & c1_0) | (c1_0 & s1_1) | (s1_0 & s1_1)) << 1;

    wire [15:0] s3_0, c3_0;

    assign s3_0 = s2_0 ^ c2_0 ^ P[6];
    assign c3_0 = ((s2_0 & c2_0) | (c2_0 & P[6]) | (s2_0 & P[6])) << 1;

    wire [15:0] final_sum, final_carry;

    assign final_sum   = s3_0 ^ c3_0 ^ P[7] ^ bias;
    assign final_carry = ((s3_0 & c3_0) | (c3_0 & P[7]) | (s3_0 & P[7])) << 1;

    /* -----------------------------
       Final Carry Propagate Adder
    ----------------------------- */
    assign prod = final_sum + final_carry;

endmodule

