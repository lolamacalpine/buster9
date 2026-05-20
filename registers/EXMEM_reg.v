`timescale 1ns / 1ps 

module EXMEM_reg(
    input clock, reset, enable,

    // from register file
    input [8:0] INrA_out, INrB_out,
    input [1:0] INrA,

    // from control unit
    input INreg_write_src, INstop, INreg_write, INflags_write,
    input [1:0] INmem_access,

    // from alu
    input [8:0] INalu_result, INalu_flags,

    // outputs
    output reg [8:0] OUTrA_out, OUTrB_out,
    output reg [1:0] OUTrA,
    
    output reg OUTreg_write_src, OUTstop, OUTreg_write, OUTflags_write,
    output reg [1:0] OUTmem_access,

    output reg [8:0] OUTalu_result, OUTalu_flags
    );

    always @(posedge clock or posedge reset) begin
        if(reset) begin
            OUTrA_out <= 9'b0;
            OUTrB_out <= 9'b0;
            OUTrA <= 2'b0;
            OUTalu_result <= 9'b0;
            OUTalu_flags <= 9'b0;
            OUTmem_access <= 2'b00;
            OUTstop <= 0;
            OUTreg_write <= 0;
            OUTflags_write <= 0;
            OUTreg_write_src <= 1'b0;
        end
        else if (enable) begin
            OUTrA_out <= INrA_out;
            OUTrB_out <= INrB_out;
            OUTrA <= INrA;
            OUTalu_result <= INalu_result;
            OUTalu_flags <= INalu_flags;
            OUTmem_access <= INmem_access;
            OUTstop <= INstop;
            OUTreg_write <= INreg_write;
            OUTflags_write <= INflags_write;
            OUTreg_write_src <= INreg_write_src;
        end
    end

endmodule