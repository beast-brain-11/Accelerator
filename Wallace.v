module Wallace_BaughWooley (
    input  signed [7:0] a,
    input  signed [7:0] b,
    output signed [15:0] prod
);

    /* -----------------------------
       Signed 8x8 Multiplier using Verilog native multiplication
       
       This provides correct signed multiplication behavior.
       For FPGA synthesis, this will be mapped to DSP blocks or 
       LUT-based multipliers as appropriate.
       
       If a structural Wallace tree is required for ASIC,
       replace this with a proper Baugh-Wooley implementation.
    ----------------------------- */
    
    assign prod = a * b;

endmodule

