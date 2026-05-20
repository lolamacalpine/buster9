`timescale 1ns / 1ps 

module MEMWB_reg (
    input clock, reset,

    // control signals
    input INreg_write, INflags_write,
    input INreg_write_src,

    // data signals
    input [8:0] INmem_out, INalu_result, INalu_flags_out,
    input [1:0] INrA,

    output reg OUTreg_write, OUTflags_write,
    output reg OUTreg_write_src,

    output reg [8:0] OUTmem_out, OUTalu_result, OUTalu_flags_out,
    output reg [1:0] OUTrA
    );
    
    always @(posedge clock or posedge reset) begin
        if(reset) begin
            OUTreg_write <= 0;
            OUTflags_write <= 0;
            OUTmem_out <= 9'b0;
            OUTalu_result <= 9'b0;
            OUTalu_flags_out <= 9'b0;
            OUTreg_write_src <= 1'b0;
            OUTrA <= 2'b0;
        end
        else begin
            OUTreg_write <= INreg_write;
            OUTflags_write <= INflags_write;
            OUTmem_out <= INmem_out;
            OUTalu_result <= INalu_result;
            OUTalu_flags_out <= INalu_flags_out;
            OUTreg_write_src <= INreg_write_src;
            OUTrA <= INrA;
        end
    end
endmodule