`timescale 1ns / 1ps

module decoder_2x4(
    output reg [3:0] out,
    input wire [1:0] in,
    input wire enable
    );

    always @(in or enable) begin
        if (enable)
            case (in)
                2'b00: out = 4'b0001;
                2'b01: out = 4'b0010;
                2'b10: out = 4'b0100;
                default: out = 4'b1000;
            endcase
        else
            out = 4'b0000;
    end

endmodule
