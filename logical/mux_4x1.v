`timescale 1ns / 1ps

module mux_4x1 (
    output reg [8:0] out,
    input wire [8:0] in0, in1, in2, in3,
    input wire [1:0] select
    );
    
    always @(select or in0 or in1 or in2 or in3) begin
        case (select)
            2'b00: out = in0;
            2'b01: out = in1;
            2'b10: out = in2;
            default: out = in3;
        endcase  
    end
endmodule
