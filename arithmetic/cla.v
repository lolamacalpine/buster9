`timescale 1ns / 1ps

module cla(
    output wire [8:0] result,
    output wire cout, vout,
    input wire [8:0] a, b,
    input wire sub_mode //1 for subtraction, 0 for addition
);

    wire [8:0] b_select;
    assign b_select = b ^ {9{sub_mode}}; //inverts b if sub_mode=1
    
    // Individual bit propagate and generate signals
    wire [8:0] P, G;
    assign P = a ^ b_select;
    assign G = a & b_select;
    
    // level 1, 3-bits each
    // block 0: bits [2:0]
    wire BP0, BG0;
    assign BP0 = P[2] & P[1] & P[0];
    assign BG0 = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]);
    
    // block 1: bits [5:3]
    wire BP1, BG1;
    assign BP1 = P[5] & P[4] & P[3];
    assign BG1 = G[5] | (P[5] & G[4]) | (P[5] & P[4] & G[3]);
    
    // block 2: bits [8:6]
    wire BP2, BG2;
    assign BP2 = P[8] & P[7] & P[6];
    assign BG2 = G[8] | (P[8] & G[7]) | (P[8] & P[7] & G[6]);
    
    // level 2
    // Carry input (cin = sub_mode for two's complement)
    wire cin;
    assign cin = sub_mode;
    
    // Big carries between blocks
    wire c3, c6, c9;
    assign c3 = BG0 | (BP0 & cin);
    assign c6 = BG1 | (BP1 & BG0) | (BP1 & BP0 & cin);
    assign c9 = BG2 | (BP2 & BG1) | (BP2 & BP1 & BG0) | (BP2 & BP1 & BP0 & cin);
    
    // 
    // block 0 internal carries
    wire c1, c2;
    assign c1 = G[0] | (P[0] & cin);
    assign c2 = G[1] | (P[1] & G[0]) | (P[1] & P[0] & cin);
    
    // block 1 internal carries
    wire c4, c5;
    assign c4 = G[3] | (P[3] & c3);
    assign c5 = G[4] | (P[4] & G[3]) | (P[4] & P[3] & c3);
    
    // block 2 internal carries
    wire c7, c8;
    assign c7 = G[6] | (P[6] & c6);
    assign c8 = G[7] | (P[7] & G[6]) | (P[7] & P[6] & c6);
    
    // sum
    assign result[0] = P[0] ^ cin;
    assign result[1] = P[1] ^ c1;
    assign result[2] = P[2] ^ c2;
    assign result[3] = P[3] ^ c3;
    assign result[4] = P[4] ^ c4;
    assign result[5] = P[5] ^ c5;
    assign result[6] = P[6] ^ c6;
    assign result[7] = P[7] ^ c7;
    assign result[8] = P[8] ^ c8;
    
    // flags
    assign cout = c9;
    assign vout = c8 ^ c9;  // Overflow uses the carry into and out of the MSB

endmodule
