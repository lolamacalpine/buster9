`timescale 1ns / 1ps

module mux_2x1 (
    output reg [8:0] out,
    input wire [8:0] in0, in1,
    input wire select
    );

    always @(select or in0 or in1) begin
        case (select)
            1'b0: out = in0;
            default: out = in1;
        endcase
    end
endmodule
