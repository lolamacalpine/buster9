`timescale 1ns / 1ps

module mux_8x1 (
    output reg [8:0] out,
    input wire [8:0] in0, in1, in2, in3, in4, in5, in6, in7,
    input wire [2:0] select
    );
    
    always @(select or in0 or in1 or in2 or in3 or in4 or in5 or in6 or in7) begin
        case (select)
            3'b000: out = in0;
            3'b001: out = in1;
            3'b010: out = in2;
            3'b011: out = in3;
            3'b100: out = in4;
            3'b101: out = in5;
            3'b110: out = in6;
            default: out = in7;
        endcase  
    end
endmodule
