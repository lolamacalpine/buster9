`timescale 1ns / 1ps 

module IDEX_reg(
    input clock, reset, flush, enable,

    // from register file
    input [8:0] INrA_out, INrB_out,
    input [1:0] INrA, INrB,

    // from control unit
    input INreg_write_src, INreg_write, INstop, INflags_write,
    input [1:0] INmem_access, INalu_src,
    input [2:0] INalu_code,
    input [8:0] INsext_imm,
    input [8:0] INzext_imm,

    output reg [8:0] OUTrA_out, OUTrB_out,
    output reg [1:0] OUTrA, OUTrB,
    
    output reg OUTreg_write_src, OUTreg_write, OUTstop, OUTflags_write,
    output reg [1:0] OUTmem_access, OUTalu_src,
    output reg [2:0] OUTalu_code,
    output reg [8:0] OUTsext_imm,
    output reg [8:0] OUTzext_imm
    );

    always @(posedge clock or posedge reset) begin
        if(reset | flush) begin
            OUTrA_out <= 9'b0;
            OUTrB_out <= 9'b0;
            OUTrA <= 2'b0;
            OUTrB <= 2'b0;
            OUTmem_access <= 2'b00;
            OUTreg_write <= 0;
            OUTstop <= 0;
            OUTflags_write <= 0;
            OUTreg_write_src <= 1'b0;
            OUTalu_src <= 2'b0;
            OUTalu_code <= 3'b0;
            OUTsext_imm <= 9'b0;
            OUTzext_imm <= 9'b0;
        end
        else if (enable) begin
            OUTrA_out <= INrA_out;
            OUTrB_out <= INrB_out;
            OUTrA <= INrA;
            OUTrB <= INrB;
            OUTmem_access <= INmem_access;
            OUTreg_write <= INreg_write;
            OUTstop <= INstop;
            OUTflags_write <= INflags_write;
            OUTreg_write_src <= INreg_write_src;
            OUTalu_src <= INalu_src;
            OUTalu_code <= INalu_code;
            OUTsext_imm <= INsext_imm;
            OUTzext_imm <= INzext_imm;
        end
    end
endmodule