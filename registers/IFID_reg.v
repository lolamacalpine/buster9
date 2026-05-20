`timescale 1ns / 1ps 

module IFID_reg(
    input clock, reset, enable, flush,
    input [8:0] INinstruction,
    output reg [8:0] OUTinstruction
    );

    always @(posedge clock or posedge reset) begin
        if(reset | flush)
            OUTinstruction <= 9'b000000001; //noop instruction
        else if (enable)
            OUTinstruction <= INinstruction;
    end
endmodule